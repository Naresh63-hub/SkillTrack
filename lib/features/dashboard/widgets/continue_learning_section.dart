import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/skill.dart';
import '../../../models/project.dart';

class ContinueLearningSection extends StatelessWidget {
  final List<Skill> ongoingSkills;
  final List<Project> ongoingProjects;
  final Function(Skill skill) onSkillTap;
  final Function(Project project) onProjectTap;
  final VoidCallback onViewAll;

  const ContinueLearningSection({
    super.key,
    required this.ongoingSkills,
    required this.ongoingProjects,
    required this.onSkillTap,
    required this.onProjectTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = ongoingSkills.isNotEmpty || ongoingProjects.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Continue Learning',
          actionText: 'View All',
          onAction: onViewAll,
        ),
        if (!hasItems)
          CustomCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: const Row(
              children: [
                Icon(Icons.school_outlined,
                    color: AppColors.lightPurple, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No ongoing courses or skills in progress right now. Add or update a skill to start!',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Show top ongoing skills
          ...ongoingSkills.take(2).map((skill) {
            return CustomCard(
              onTap: () => onSkillTap(skill),
              borderRadius: 20,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill.name,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${skill.proficiencyLevel} • ${skill.category}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: AppColors.lightPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.lightPurple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomProgressBar(
                    percentage: skill.progressPercentage,
                    height: 6,
                    showLabel: true,
                    labelText: 'Progress',
                  ),
                ],
              ),
            );
          }),

          // Show top ongoing project if exists
          ...ongoingProjects.take(1).map((project) {
            return CustomCard(
              onTap: () => onProjectTap(project),
              borderRadius: 20,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.folder_special_rounded,
                          color: AppColors.gradientHighlight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Project • ${project.category}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const CustomProgressBar(
                    percentage: 50.0,
                    height: 6,
                    showLabel: true,
                    labelText: 'Milestone Progress',
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
