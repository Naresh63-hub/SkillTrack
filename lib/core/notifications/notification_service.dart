import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize timezone database and set tz.local to device timezone offset
    try {
      tz_data.initializeTimeZones();
      final now = DateTime.now();
      bool setLocation = false;
      try {
        final loc = tz.getLocation(now.timeZoneName);
        tz.setLocalLocation(loc);
        setLocation = true;
      } catch (_) {}

      if (!setLocation) {
        // Fallback: match by current device timezone offset
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset == now.timeZoneOffset.inMilliseconds) {
            tz.setLocalLocation(loc);
            setLocation = true;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization notice: $e');
    }

    // 2. Platform initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 3. Explicitly create notification channels for Android 8.0+
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminders_channel',
            'Task & Call Reminders',
            description:
                'Scheduled reminders for student tasks, mentor calls, and study sessions',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'event_reminders_channel',
            'Planner & Meeting Reminders',
            description:
                'Advance reminders for campus drives, tests, and meetings',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification initialization notice: $e');
      _isInitialized = false;
    }
  }

  /// Requests notification and alarm permissions across Android & iOS
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final notifGranted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
        return notifGranted;
      }

      final iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// Show an immediate notification (e.g. for instant alert)
  Future<void> showTaskNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task & Call Reminders',
      channelDescription:
          'Reminders for student tasks, deadlines, and study goals',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Could not show task notification: $e');
    }
  }

  /// Sends an immediate test notification to verify sounds, banners, and permissions
  Future<bool> sendTestNotification() async {
    await requestPermissions();
    await showTaskNotification(
      id: 999999,
      title: '🔔 SkillTrack Notification Active',
      body: 'Your task and study reminders are ready to alert you on time!',
    );
    return true;
  }

  /// Schedules a task or call reminder ahead of time
  Future<bool> scheduleTaskReminder({
    required int id,
    required String title,
    String? description,
    required DateTime dueDateTime,
    int? earlyMinutes,
    String? category,
  }) async {
    if (kIsWeb) return false;
    if (!_isInitialized) await init();

    final early = earlyMinutes ?? 0;
    final reminderTime = dueDateTime.subtract(Duration(minutes: early));
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Reminder time is in the past: $reminderTime');
      return false; // Cannot schedule in the past
    }

    final notifId = 100000 + (id % 100000);
    final isCall = category == 'Call / Meeting';
    final earlyText = early == 0
        ? 'Due now!'
        : early < 60
            ? 'Starting in $early minutes'
            : early == 60
                ? 'Starting in 1 hour'
                : early < 1440
                    ? 'Starting in ${early ~/ 60} hours'
                    : 'Starting tomorrow';

    final notifTitle =
        isCall ? '📞 Call/Meeting: $title' : '⏰ Task Reminder: $title';
    final notifBody = description != null && description.isNotEmpty
        ? '$earlyText • $description'
        : earlyText;

    final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task & Call Reminders',
      channelDescription:
          'Scheduled reminders for student tasks, mentor calls, and study sessions',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notifId,
        notifTitle,
        notifBody,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      // Fallback if exact alarms are restricted
      try {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          notifTitle,
          notifBody,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return true;
      } catch (e2) {
        debugPrint('Could not schedule task reminder: $e2');
        return false;
      }
    }
  }

  /// Cancels a scheduled task notification
  Future<void> cancelTaskReminder(int id) async {
    try {
      final notifId = 100000 + (id % 100000);
      await _notificationsPlugin.cancel(notifId);
    } catch (_) {}
  }

  /// Schedules a planner/calendar event reminder ahead of time
  Future<bool> scheduleEventReminder({
    required int id,
    required String title,
    String? description,
    required DateTime eventDateTime,
    int? reminderMinutesBefore,
    String? eventType,
  }) async {
    if (kIsWeb) return false;
    if (!_isInitialized) await init();

    final mins = reminderMinutesBefore ?? 0;
    final reminderTime = eventDateTime.subtract(Duration(minutes: mins));
    if (reminderTime.isBefore(DateTime.now())) return false;

    final notifId = 200000 + (id % 100000);
    final isCall = eventType == 'Call / Meeting';
    final earlyText = mins == 0
        ? 'Happening now!'
        : mins < 60
            ? 'Starting in $mins minutes'
            : mins == 60
                ? 'Starting in 1 hour'
                : mins < 1440
                    ? 'Starting in ${mins ~/ 60} hours'
                    : 'Starting in 1 day';

    final icon = isCall ? '📞' : '📅';
    final notifTitle = '$icon $eventType: $title';
    final notifBody = description != null && description.isNotEmpty
        ? '$earlyText • $description'
        : earlyText;

    final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'event_reminders_channel',
      'Planner & Meeting Reminders',
      channelDescription:
          'Advance reminders for campus drives, tests, and meetings',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notifId,
        notifTitle,
        notifBody,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return true;
    } catch (e) {
      // Fallback if exact alarms are restricted
      try {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          notifTitle,
          notifBody,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        return true;
      } catch (e2) {
        debugPrint('Could not schedule event reminder: $e2');
        return false;
      }
    }
  }

  /// Cancels a scheduled event notification
  Future<void> cancelEventReminder(int id) async {
    try {
      final notifId = 200000 + (id % 100000);
      await _notificationsPlugin.cancel(notifId);
    } catch (_) {}
  }
}
