import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/task_model.dart';

class UpcomingDeadlinesList extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel task)? onTaskTap;

  const UpcomingDeadlinesList({
    super.key,
    required this.tasks,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        borderRadius: 20,
        child: const Center(
          child: Text(
            'No upcoming deadlines right now. You are all caught up!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: tasks.map((task) {
        final isOverdue = task.isOverdue;
        final isToday = task.isToday;
        final badgeColor = isOverdue
            ? AppColors.error
            : (isToday ? AppColors.warning : AppColors.lightPurple);

        return CustomCard(
          onTap: () => onTaskTap?.call(task),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: 18,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.category,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  DateFormatter.relativeDueString(task.dueDate),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
