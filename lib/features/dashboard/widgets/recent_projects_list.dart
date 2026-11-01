import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/project.dart';

class RecentProjectsList extends StatelessWidget {
  final List<Project> projects;
  final Function(Project project)? onProjectTap;

  const RecentProjectsList({
    super.key,
    required this.projects,
    this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        borderRadius: 20,
        child: const Center(
          child: Text(
            'No projects added yet. Add your college or portfolio projects to track them!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: projects.map((project) {
        Color statusColor;
        switch (project.status) {
          case 'Completed':
            statusColor = AppColors.success;
            break;
          case 'In Progress':
            statusColor = AppColors.gradientHighlight;
            break;
          case 'On Hold':
            statusColor = AppColors.warning;
            break;
          case 'Planned':
          default:
            statusColor = AppColors.lightPurple;
            break;
        }

        return CustomCard(
          onTap: () => onProjectTap?.call(project),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      project.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                project.shortDescription,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: project.technologies.take(3).map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Text(
                        tech,
                        style: const TextStyle(
                          color: AppColors.lightPurple,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
