import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/mock_interview.dart';

class MockInterviewReportScreen extends StatelessWidget {
  final MockInterview interview;

  const MockInterviewReportScreen({super.key, required this.interview});

  @override
  Widget build(BuildContext context) {
    final score = interview.overallScore.clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Interview Performance Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Hero Card
            CustomCard(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(22),
              borderRadius: 22,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            interview.jobRole,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${interview.category} • ${interview.difficulty}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${interview.completedQuestions}/${interview.totalQuestions} Questions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Score Gauge
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: score / 100.0,
                              strokeWidth: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            Center(
                              child: Text(
                                '${score.toInt()}%',
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
                      Expanded(
                        child: Text(
                          interview.feedbackSummary ??
                              'Interview evaluation complete based on your technical responses.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Evaluation Engine Verification Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: interview.isAiEvaluated
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                    : const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: interview.isAiEvaluated
                      ? AppColors.primaryPurple.withValues(alpha: 0.4)
                      : const Color(0xFFD97706).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    interview.isAiEvaluated
                        ? Icons.auto_awesome
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: interview.isAiEvaluated
                        ? AppColors.primaryPurple
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      interview.isAiEvaluated
                          ? 'Evaluated via Live Google Gemini AI based on your technical responses.'
                          : 'Evaluated via SkillTrack Intelligent Heuristic Engine (Offline Fallback). Add your Gemini key in Settings for live cloud model grading.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: interview.isAiEvaluated
                            ? AppColors.primaryPurple
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Strengths & Weaknesses
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 6),
                            Text(
                              'Key Strengths',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...interview.strengths.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(color: Color(0xFF059669))),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates_outlined,
                                size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 6),
                            Text(
                              'Improvement Areas',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...interview.weaknesses.map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(color: Color(0xFFD97706))),
                                Expanded(
                                  child: Text(
                                    w,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question-by-Question Detailed Review
            const Text(
              'Detailed Responses & AI Evaluation',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ...interview.answers.map((ans) {
              final ansScore = ans.score.clamp(0.0, 100.0);
              final isHigh = ansScore >= 70;

              return CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${ans.questionIndex + 1}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isHigh
                                ? const Color(0xFF059669)
                                    .withValues(alpha: 0.12)
                                : const Color(0xFFD97706)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${ansScore.toInt()}% Score',
                            style: TextStyle(
                              color: isHigh
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ans.question,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Answer:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ans.userAnswer?.isNotEmpty == true
                                ? ans.userAnswer!
                                : 'No response provided.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ans.feedback != null && ans.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        ans.feedback!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (ans.improvementTips != null &&
                        ans.improvementTips!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Tip: ${ans.improvementTips!}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Return to Interview Hub'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
