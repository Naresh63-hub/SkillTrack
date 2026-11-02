import '../../models/task_model.dart';
import '../../models/skill.dart';

class StreakCalculator {
  /// Calculates consecutive active days based on student task completions and skill updates.
  static int calculateStreak({
    required List<TaskModel> tasks,
    required List<Skill> skills,
  }) {
    final activeDates = <DateTime>{};

    for (final t in tasks) {
      if (t.isCompleted && t.completedAt != null) {
        try {
          final dt = DateTime.parse(t.completedAt!);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
    }

    for (final s in skills) {
      try {
        final dt = DateTime.parse(s.updatedAt);
        activeDates.add(DateTime(dt.year, dt.month, dt.day));
      } catch (_) {}
    }

    if (activeDates.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate;
    if (activeDates.contains(today)) {
      checkDate = today;
    } else if (activeDates.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (activeDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
