import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/progress_calculator.dart';

class OverallProgressCard extends StatelessWidget {
  final ProgressMetrics metrics;
  final VoidCallback? onFormulaTap;
  final int? skillsCompleted;
  final int? projectsCompleted;

  const OverallProgressCard({
    super.key,
    required this.metrics,
    this.onFormulaTap,
    this.skillsCompleted,
    this.projectsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF261B32), Color(0xFF1C1722)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      border: Border.all(
        color: AppColors.border,
        width: 1.2,
      ),
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
                      Icons.auto_graph_rounded,
                      color: AppColors.gradientHighlight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Career Preparation Score',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.lightPurple,
                  size: 16,
                ),
                tooltip: 'Calculation Details',
                onPressed: () {
                  if (onFormulaTap != null) {
                    onFormulaTap!();
                  } else {
                    _showFormulaDialog(context);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Score & Progress Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress badge
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value:
                          (metrics.overallPercentage / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: AppColors.progressTrack,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gradientHighlight,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${metrics.overallPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Sub-breakdowns
              Expanded(
                child: Column(
                  children: [
                    _buildMiniRow(
                      'Technical Skills',
                      metrics.skillsPercentage,
                      AppColors.primaryPurple,
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Project Portfolio',
                      metrics.projectsPercentage,
                      AppColors.gradientHighlight,
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Tasks Execution',
                      metrics.tasksPercentage,
                      AppColors.lightPurple,
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Placement Prep',
                      metrics.placementPercentage,
                      const Color(0xFFC084FC),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (skillsCompleted != null || projectsCompleted != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (skillsCompleted != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 15, color: AppColors.lightPurple),
                        const SizedBox(width: 6),
                        Text(
                          '$skillsCompleted Skills Completed',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (projectsCompleted != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 15, color: AppColors.gradientHighlight),
                        const SizedBox(width: 6),
                        Text(
                          '$projectsCompleted Projects Done',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, double percentage, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: AppColors.progressTrack,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage / 100.0).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.gradientHighlight
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showFormulaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.insights, color: AppColors.gradientHighlight, size: 22),
            SizedBox(width: 10),
            Text('Career Score Breakdown'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Career Preparation Score is an objective, weighted average calculated from your actual records across four key pillars:\n',
              style: TextStyle(
                  color: AppColors.secondaryText, fontSize: 13, height: 1.45),
            ),
            Text(
                '• Skills (25%): Average progress across all tracked technical skills.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 6),
            Text(
                '• Projects (25%): Status-weighted portfolio completion (Completed: 100%, In Progress: 50%, Planned: 10%).',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 6),
            Text('• Tasks (25%): Ratio of completed to total assigned tasks.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 6),
            Text(
                '• Placement Prep (25%): Average readiness across Coding (DSA), Core CS, Aptitude, and Interview QA.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 12),
            Text(
              'No sample or fabricated statistics are used. The score reflects only what you record in your database.',
              style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
