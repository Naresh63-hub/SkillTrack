import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../../models/skill.dart';
import '../../models/project.dart';
import '../../models/certificate.dart';

class StreakCalculator {
  static const String _activeDatesKey = 'skilltrack_student_active_dates';

  /// Records today as an active learning day in persistent storage.
  static Future<void> recordTodayActive() async {
    try {
      final now = DateTime.now();
      await recordActiveDate(now);
    } catch (_) {}
  }

  /// Records a specific date as an active learning day in persistent storage.
  static Future<void> recordActiveDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_activeDatesKey) ?? [];
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!savedList.contains(dateStr)) {
        savedList.add(dateStr);
        await prefs.setStringList(_activeDatesKey, savedList);
      }
    } catch (_) {}
  }

  /// Retrieves all recorded active dates from persistent storage.
  static Future<Set<DateTime>> getSavedActiveDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_activeDatesKey) ?? [];
      final dates = <DateTime>{};
      for (final s in savedList) {
        try {
          final parts = s.split('-');
          if (parts.length == 3) {
            dates.add(DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ));
          }
        } catch (_) {}
      }
      return dates;
    } catch (_) {
      return {};
    }
  }

  /// Calculates consecutive active days based on student task completions, skill updates,
  /// project milestones, certifications, and daily learning sessions.
  static int calculateStreak({
    required List<TaskModel> tasks,
    required List<Skill> skills,
    List<Project>? projects,
    List<Certificate>? certificates,
    Set<DateTime>? additionalDates,
  }) {
    final activeDates = <DateTime>{};

    if (additionalDates != null) {
      for (final d in additionalDates) {
        activeDates.add(DateTime(d.year, d.month, d.day));
      }
    }

    for (final t in tasks) {
      if (t.isCompleted && t.completedAt != null) {
        try {
          final dt = DateTime.parse(t.completedAt!);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      } else if (t.isCompleted) {
        try {
          final dt = DateTime.parse(t.dueDate);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
      try {
        final dt = DateTime.parse(t.creationDate);
        activeDates.add(DateTime(dt.year, dt.month, dt.day));
      } catch (_) {}
    }

    for (final s in skills) {
      try {
        final dt = DateTime.parse(s.updatedAt);
        activeDates.add(DateTime(dt.year, dt.month, dt.day));
      } catch (_) {}
      try {
        final dt = DateTime.parse(s.createdAt);
        activeDates.add(DateTime(dt.year, dt.month, dt.day));
      } catch (_) {}
      if (s.dateStarted != null && s.dateStarted!.isNotEmpty) {
        try {
          final dt = DateTime.parse(s.dateStarted!);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
    }

    if (projects != null) {
      for (final p in projects) {
        try {
          final dt = DateTime.parse(p.updatedAt);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
        try {
          final dt = DateTime.parse(p.createdAt);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
        if (p.completionDate != null && p.completionDate!.isNotEmpty) {
          try {
            final dt = DateTime.parse(p.completionDate!);
            activeDates.add(DateTime(dt.year, dt.month, dt.day));
          } catch (_) {}
        }
        if (p.startDate != null && p.startDate!.isNotEmpty) {
          try {
            final dt = DateTime.parse(p.startDate!);
            activeDates.add(DateTime(dt.year, dt.month, dt.day));
          } catch (_) {}
        }
      }
    }

    if (certificates != null) {
      for (final c in certificates) {
        try {
          final dt = DateTime.parse(c.createdAt);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
        try {
          final dt = DateTime.parse(c.completionDate);
          activeDates.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
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
