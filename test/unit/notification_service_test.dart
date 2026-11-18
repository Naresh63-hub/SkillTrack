import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/notifications/notification_service.dart';
import 'package:skilltrack/models/task_model.dart';
import 'package:skilltrack/models/planner_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService & Reminder System Tests', () {
    test('NotificationService singleton initializes safely without crashing', () async {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      await service.init();
    });

    test('scheduleTaskReminder rejects past reminder times gracefully', () async {
      final service = NotificationService.instance;
      await service.init();

      final pastDate = DateTime.now().subtract(const Duration(hours: 2));
      final scheduled = await service.scheduleTaskReminder(
        id: 1,
        title: 'Past Task',
        dueDateTime: pastDate,
        earlyMinutes: 15,
      );

      expect(scheduled, isFalse);
    });

    test('scheduleEventReminder rejects past event times gracefully', () async {
      final service = NotificationService.instance;
      await service.init();

      final pastDate = DateTime.now().subtract(const Duration(minutes: 30));
      final scheduled = await service.scheduleEventReminder(
        id: 2,
        title: 'Past Campus Drive',
        eventDateTime: pastDate,
        reminderMinutesBefore: 15,
        eventType: 'Campus Drive',
      );

      expect(scheduled, isFalse);
    });

    test('cancelTaskReminder and cancelEventReminder run safely without error', () async {
      final service = NotificationService.instance;
      await service.init();

      expect(() async => await service.cancelTaskReminder(123), returnsNormally);
      expect(() async => await service.cancelEventReminder(456), returnsNormally);
    });

    test('TaskModel early reminder labels format accurately', () {
      final t1 = TaskModel(
        title: 'Task 1',
        category: 'Study',
        dueDate: DateTime.now().toIso8601String(),
        earlyReminderMinutes: 0,
      );
      expect(t1.earlyReminderLabel, 'At due time');

      final t2 = TaskModel(
        title: 'Task 2',
        category: 'Assignment',
        dueDate: DateTime.now().toIso8601String(),
        earlyReminderMinutes: 15,
      );
      expect(t2.earlyReminderLabel, '15 mins early');

      final t3 = TaskModel(
        title: 'Task 3',
        category: 'Project Work',
        dueDate: DateTime.now().toIso8601String(),
        earlyReminderMinutes: 60,
      );
      expect(t3.earlyReminderLabel, '1 hour early');

      final t4 = TaskModel(
        title: 'Task 4',
        category: 'Call / Meeting',
        dueDate: DateTime.now().toIso8601String(),
        earlyReminderMinutes: 1440,
      );
      expect(t4.earlyReminderLabel, '1 day early');
    });

    test('PlannerEvent early reminder labels format accurately', () {
      final e1 = PlannerEvent(
        title: 'Interview Call',
        eventType: 'Call / Meeting',
        targetDate: '2026-11-20',
        reminderMinutesBefore: 15,
      );
      expect(e1.reminderLabel, '15 mins early');

      final e2 = PlannerEvent(
        title: 'Semester Exam',
        eventType: 'Exam / Test',
        targetDate: '2026-11-25',
        reminderMinutesBefore: 1440,
      );
      expect(e2.reminderLabel, '1 day early');
    });
  });
}
