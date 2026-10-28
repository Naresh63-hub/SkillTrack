import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/models/task_model.dart';

void main() {
  group('Task Filtering & Deadline Logic Tests', () {
    final now = DateTime.now();

    test('Today task detection', () {
      final todayTask = TaskModel(
        title: 'Revise notes',
        category: 'Placement',
        dueDate:
            DateTime(now.year, now.month, now.day, 18, 0).toIso8601String(),
      );

      expect(todayTask.isToday, isTrue);
      expect(todayTask.isOverdue, isFalse);
    });

    test('Overdue task detection', () {
      final overdueTask = TaskModel(
        title: 'Submit assignment',
        category: 'College',
        dueDate: now.subtract(const Duration(days: 3)).toIso8601String(),
        isCompleted: false,
      );

      expect(overdueTask.isOverdue, isTrue);

      // Completed tasks should never be flagged as overdue
      final completedOverdueTask = overdueTask.copyWith(isCompleted: true);
      expect(completedOverdueTask.isOverdue, isFalse);
    });

    test('Upcoming task detection', () {
      final upcomingTask = TaskModel(
        title: 'Campus interview',
        category: 'Placement',
        dueDate: now.add(const Duration(days: 4)).toIso8601String(),
        isCompleted: false,
      );

      expect(upcomingTask.isUpcoming, isTrue);
      expect(upcomingTask.isToday, isFalse);
      expect(upcomingTask.isOverdue, isFalse);
    });
  });
}
