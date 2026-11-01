import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/task_model.dart';
import '../../../models/skill.dart';

class WeeklyActivityCard extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<Skill> skills;

  const WeeklyActivityCard({
    super.key,
    required this.tasks,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekday - 1));

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Compute activity count per day for current week
    final weekActivity = List<int>.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayStart = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final dayEnd =
          DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59);

      int count = 0;
      // Check tasks completed or created on that day
      for (final t in tasks) {
        if (t.completedAt != null) {
          try {
            final comp = DateTime.parse(t.completedAt!);
            if (comp.isAfter(dayStart) && comp.isBefore(dayEnd)) {
              count++;
            }
          } catch (_) {}
        }
        if (t.isCompleted && count == 0) {
          try {
            final due = DateTime.parse(t.dueDate);
            if (due.isAfter(dayStart) && due.isBefore(dayEnd)) {
              count++;
            }
          } catch (_) {}
        }
      }

      // Check skills updated on that day
      for (final s in skills) {
        try {
          final up = DateTime.parse(s.updatedAt);
          if (up.isAfter(dayStart) && up.isBefore(dayEnd)) {
            count++;
          }
        } catch (_) {}
      }

      weekActivity[i] = count;
    }

    final totalWeekActivity =
        weekActivity.fold<int>(0, (sum, count) => sum + count);
    final maxActivity =
        weekActivity.fold<int>(1, (max, c) => c > max ? c : max);

    return CustomCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.lightPurple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Weekly Learning Activity',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  totalWeekActivity > 0
                      ? '$totalWeekActivity completed'
                      : 'This Week',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Days Mon to Sun columns / indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isToday = index == (currentWeekday - 1);
              final isPastOrToday = index <= (currentWeekday - 1);
              final activityCount = weekActivity[index];
              final hasActivity = activityCount > 0;
              final heightRatio = hasActivity
                  ? (activityCount / maxActivity).clamp(0.3, 1.0)
                  : 0.1;

              return Column(
                children: [
                  // Bar / indicator column
                  Container(
                    width: 32,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isToday
                            ? AppColors.primaryPurple
                            : (hasActivity
                                ? AppColors.border
                                : Colors.transparent),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasActivity)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$activityCount',
                              style: const TextStyle(
                                color: AppColors.gradientHighlight,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          width: 24,
                          height: (52 * heightRatio).clamp(10.0, 50.0),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: hasActivity
                                ? AppColors.purpleProgressGradient
                                : null,
                            color: hasActivity
                                ? null
                                : (isPastOrToday
                                    ? AppColors.progressTrack
                                    : AppColors.progressTrack
                                        .withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: hasActivity
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: isToday
                          ? AppColors.primaryText
                          : (hasActivity
                              ? AppColors.lightPurple
                              : AppColors.mutedText),
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      color:
                          isToday ? AppColors.lightPurple : AppColors.mutedText,
                      fontSize: 9.5,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),

          if (totalWeekActivity == 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.mutedText),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No learning activity recorded yet this week. Complete tasks or update skills to build your streak!',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
