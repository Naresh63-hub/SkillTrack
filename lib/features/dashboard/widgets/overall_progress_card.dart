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
        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Career Preparation Score',
                    style: TextStyle(
                      color: Colors.white,
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
                  color: Colors.white,
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
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${metrics.overallPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
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
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Project Portfolio',
                      metrics.projectsPercentage,
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Tasks Execution',
                      metrics.tasksPercentage,
                    ),
                    const SizedBox(height: 7),
                    _buildMiniRow(
                      'Placement Prep',
                      metrics.placementPercentage,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (skillsCompleted != null) ...[
                    const Icon(Icons.check_circle_outline,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '$skillsCompleted Skills',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (skillsCompleted != null && projectsCompleted != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6))),
                    ),
                  if (projectsCompleted != null) ...[
                    const Icon(Icons.folder_outlined,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '$projectsCompleted Projects',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              // View Details White Pill Button matching Screen 3
              InkWell(
                onTap: () {
                  if (onFormulaTap != null) {
                    onFormulaTap!();
                  } else {
                    _showFormulaDialog(context);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: Color(0xFF6D28D9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, double percentage) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
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
              color: Colors.white.withValues(alpha: 0.2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage / 100.0).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    gradient: LinearGradient(
                      colors: [Color(0xFFA78BFA), Colors.white],
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
            style: const TextStyle(
              color: Colors.white,
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
            Icon(Icons.calculate_outlined, color: AppColors.primaryPurple),
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
