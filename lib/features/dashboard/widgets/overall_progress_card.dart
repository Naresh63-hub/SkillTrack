import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/progress_calculator.dart';

class OverallProgressCard extends StatelessWidget {
  final ProgressMetrics metrics;
  final VoidCallback? onFormulaTap;

  const OverallProgressCard({
    super.key,
    required this.metrics,
    this.onFormulaTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      gradient: AppColors.elevatedGradient,
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.3), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Career Preparation Score',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline,
                    color: AppColors.secondaryAccent, size: 20),
                tooltip: 'Calculation Formula',
                onPressed: () => _showFormulaDialog(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular score indicator
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: metrics.overallPercentage / 100.0,
                      strokeWidth: 8,
                      backgroundColor: AppColors.cardBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brightAccent),
                    ),
                    Center(
                      child: Text(
                        '${metrics.overallPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Sub-breakdowns
              Expanded(
                child: Column(
                  children: [
                    _buildMiniRow('Technical Skills', metrics.skillsPercentage,
                        AppColors.primaryAccent),
                    const SizedBox(height: 6),
                    _buildMiniRow('Project Portfolio',
                        metrics.projectsPercentage, AppColors.brightAccent),
                    const SizedBox(height: 6),
                    _buildMiniRow('Tasks Execution', metrics.tasksPercentage,
                        AppColors.secondaryAccent),
                    const SizedBox(height: 6),
                    _buildMiniRow('Placement Prep', metrics.placementPercentage,
                        const Color(0xFFC084FC)),
                  ],
                ),
              ),
            ],
          ),
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
            style:
                const TextStyle(color: AppColors.secondaryText, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showFormulaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preparation Progress Formula'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Career Preparation Score is an objective, weighted average calculated from your actual database records across four key pillars:\n',
              style: TextStyle(
                  color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            Text(
                '• Skills (25%): Average completion % across all tracked technical skills.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 4),
            Text(
                '• Projects (25%): Status-weighted portfolio completion (Completed: 100%, In Progress: 50%, Planned: 10%).',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 4),
            Text('• Tasks (25%): Ratio of completed to total assigned tasks.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 4),
            Text(
                '• Placement Prep (25%): Average readiness across Coding (DSA), Core CS, Aptitude, and Interview QA.',
                style: TextStyle(color: AppColors.primaryText, fontSize: 12.5)),
            SizedBox(height: 12),
            Text(
              'No sample or fabricated statistics are used. The score reflects only what you record.',
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
