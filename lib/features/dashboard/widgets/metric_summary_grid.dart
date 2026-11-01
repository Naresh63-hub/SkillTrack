import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stat_card.dart';

class MetricSummaryGrid extends StatelessWidget {
  final int skillsCount;
  final int certsCount;
  final int projectsCount;
  final int pendingTasksCount;
  final int completedTasksCount;
  final double placementProgress;
  final Function(int tabIndex)? onNavigateTab;
  final VoidCallback? onCertificatesTap;

  const MetricSummaryGrid({
    super.key,
    required this.skillsCount,
    required this.certsCount,
    required this.projectsCount,
    required this.pendingTasksCount,
    required this.completedTasksCount,
    required this.placementProgress,
    this.onNavigateTab,
    this.onCertificatesTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
        final aspectRatio = constraints.maxWidth > 550 ? 1.6 : 1.35;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            StatCard(
              title: 'Technical Skills',
              value: '$skillsCount',
              subtitle: 'Active skills',
              icon: Icons.code_rounded,
              iconColor: AppColors.primaryPurple,
              onTap: () => onNavigateTab?.call(1), // Skills tab
            ),
            StatCard(
              title: 'Certificates',
              value: '$certsCount',
              subtitle: 'Earned credentials',
              icon: Icons.verified_rounded,
              iconColor: AppColors.gradientHighlight,
              onTap: onCertificatesTap,
            ),
            StatCard(
              title: 'Projects',
              value: '$projectsCount',
              subtitle: 'Portfolio items',
              icon: Icons.folder_special_rounded,
              iconColor: AppColors.lightPurple,
              onTap: () => onNavigateTab?.call(2), // Portfolio tab
            ),
            StatCard(
              title: 'Pending Tasks',
              value: '$pendingTasksCount',
              subtitle: 'To accomplish',
              icon: Icons.pending_actions_rounded,
              iconColor: AppColors.warning,
              onTap: () => onNavigateTab?.call(3), // Tasks tab
            ),
            StatCard(
              title: 'Completed Tasks',
              value: '$completedTasksCount',
              subtitle: 'Done',
              icon: Icons.task_alt_rounded,
              iconColor: AppColors.success,
              onTap: () => onNavigateTab?.call(3), // Tasks tab
            ),
            StatCard(
              title: 'Placement Prep',
              value: '${placementProgress.toStringAsFixed(0)}%',
              subtitle: 'Readiness rate',
              icon: Icons.school_rounded,
              iconColor: const Color(0xFFC084FC),
              onTap: () => onNavigateTab?.call(4), // Placement tab
            ),
          ],
        );
      },
    );
  }
}
