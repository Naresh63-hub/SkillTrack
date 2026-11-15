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

    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization notice: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // Handle tap on notification
        },
      );
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback if notification subsystem is restricted
      _isInitialized = false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
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
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Schedules a task or call reminder ahead of time
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    String? description,
    required DateTime dueDateTime,
    int? earlyMinutes,
    String? category,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    final early = earlyMinutes ?? 0;
    final reminderTime = dueDateTime.subtract(Duration(minutes: early));
    if (reminderTime.isBefore(DateTime.now())) {
      return; // Cannot schedule in the past
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

    try {
      final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
      await _notificationsPlugin.zonedSchedule(
        notifId,
        notifTitle,
        notifBody,
        scheduledTz,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders_channel',
            'Task & Call Reminders',
            channelDescription:
                'Scheduled reminders for student tasks, mentor calls, and study sessions',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule task reminder: $e');
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
  Future<void> scheduleEventReminder({
    required int id,
    required String title,
    String? description,
    required DateTime eventDateTime,
    int? reminderMinutesBefore,
    String? eventType,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    final mins = reminderMinutesBefore ?? 0;
    final reminderTime = eventDateTime.subtract(Duration(minutes: mins));
    if (reminderTime.isBefore(DateTime.now())) return;

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

    try {
      final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
      await _notificationsPlugin.zonedSchedule(
        notifId,
        notifTitle,
        notifBody,
        scheduledTz,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders_channel',
            'Planner & Meeting Reminders',
            channelDescription:
                'Advance reminders for campus drives, tests, and meetings',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule event reminder: $e');
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
