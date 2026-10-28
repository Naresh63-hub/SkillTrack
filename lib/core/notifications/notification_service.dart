import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

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

  Future<void> showTaskNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
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
}
