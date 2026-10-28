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
            statusColor = AppColors.brightAccent;
            break;
          case 'On Hold':
            statusColor = AppColors.warning;
            break;
          case 'Planned':
          default:
            statusColor = AppColors.info;
            break;
        }

        return CustomCard(
          onTap: () => onProjectTap?.call(project),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                          width: 0.8),
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
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: project.technologies.take(3).map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border, width: 0.7),
                      ),
                      child: Text(
                        tech,
                        style: const TextStyle(
                          color: AppColors.secondaryAccent,
                          fontSize: 10,
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
