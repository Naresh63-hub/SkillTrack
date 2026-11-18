import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/task_model.dart';
import '../../../models/skill.dart';
import '../../../models/project.dart';
import '../screens/weekly_plans_screen.dart';

class WeeklyActivityCard extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<Skill> skills;
  final List<Project>? projects;
  final Set<DateTime>? activeDates;
  final Function(int dayIndex)? onDayTap;
  final VoidCallback? onTap;
  final Function(int tabIndex)? onNavigateTab;

  const WeeklyActivityCard({
    super.key,
    required this.tasks,
    required this.skills,
    this.projects,
    this.activeDates,
    this.onDayTap,
    this.onTap,
    this.onNavigateTab,
  });

  void _openPlans(BuildContext context, int dayIndex) {
    if (dayIndex >= 0 && onDayTap != null) {
      onDayTap!(dayIndex);
      return;
    }
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WeeklyPlansScreen(
          initialTasks: tasks,
          initialSkills: skills,
          initialProjects: projects,
          activeDates: activeDates,
          initialDayIndex: dayIndex,
          onNavigateTab: onNavigateTab,
        ),
      ),
    );
  }

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

      // Check projects updated or created on that day
      if (projects != null) {
        for (final p in projects!) {
          try {
            final up = DateTime.parse(p.updatedAt);
            if (up.isAfter(dayStart) && up.isBefore(dayEnd)) {
              count++;
            }
          } catch (_) {}
          try {
            final cr = DateTime.parse(p.createdAt);
            if (cr.isAfter(dayStart) && cr.isBefore(dayEnd)) {
              count++;
            }
          } catch (_) {}
        }
      }

      // Check recorded active dates
      if (activeDates != null &&
          count == 0 &&
          activeDates!.contains(DateTime(dayDate.year, dayDate.month, dayDate.day))) {
        count++;
      }

      weekActivity[i] = count;
    }

    final totalWeekActivity =
        weekActivity.fold<int>(0, (sum, count) => sum + count);
    final maxActivity =
        weekActivity.fold<int>(1, (max, c) => c > max ? c : max);

    return InkWell(
      onTap: () => _openPlans(context, -1),
      borderRadius: BorderRadius.circular(22),
      child: CustomCard(
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
                Row(
                  children: [
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
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.lightPurple,
                    ),
                  ],
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

                return GestureDetector(
                  onTap: () => _openPlans(context, index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
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
                  ),
                );
              }),
            ),

            const SizedBox(height: 14),

            // Tap hint container to see future plans & tasks
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryCard.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 13, color: AppColors.lightPurple),
                  SizedBox(width: 6),
                  Text(
                    'Tap to view this week\'s plans, tasks & schedule',
                    style: TextStyle(
                      color: AppColors.lightPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: AppColors.lightPurple),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
