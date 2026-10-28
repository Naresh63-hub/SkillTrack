import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/progress_calculator.dart';
import '../../../models/job_application.dart';
import '../../../repositories/placement_repository.dart';
import 'coding_prep_screen.dart';
import 'core_cs_screen.dart';
import 'aptitude_prep_screen.dart';
import 'interview_prep_screen.dart';
import 'job_applications_screen.dart';

class PlacementScreen extends StatefulWidget {
  final int initialTabIndex;

  const PlacementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlacementRepository _repository = PlacementRepository();

  double _codingPct = 0.0;
  double _aptitudePct = 0.0;
  double _overallPlacementPct = 0.0;

  int _codingCompleted = 0;
  int _codingTotal = 0;
  int _aptitudeCompleted = 0;
  int _aptitudeTotal = 0;
  JobApplication? _upcomingInterview;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    final codingTopics = await _repository.getTopicsByTrack('Coding');
    final coreCsTopics = await _repository.getTopicsByTrack('CoreCS');
    final aptitudeTopics = await _repository.getTopicsByTrack('Aptitude');
    final interviewQuestions = await _repository.getInterviewQuestions();
    final applications = await _repository.getJobApplications();

    final cScore = ProgressCalculator.calculateTopicTrackProgress(codingTopics);
    final csScore =
        ProgressCalculator.calculateTopicTrackProgress(coreCsTopics);
    final aScore =
        ProgressCalculator.calculateTopicTrackProgress(aptitudeTopics);
    final iScore =
        ProgressCalculator.calculateInterviewProgress(interviewQuestions);

    final overall = (cScore + csScore + aScore + iScore) / 4.0;

    final codingDone = codingTopics.where((t) => t.isCompleted).length;
    final aptitudeDone = aptitudeTopics.where((t) => t.isCompleted).length;

    JobApplication? nextInterview;
    for (final app in applications) {
      if (app.status == 'Interview' || app.hasUpcomingInterview) {
        nextInterview = app;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _codingPct = cScore;
        _aptitudePct = aScore;
        _overallPlacementPct = overall;

        _codingCompleted = codingDone;
        _codingTotal = codingTopics.length;
        _aptitudeCompleted = aptitudeDone;
        _aptitudeTotal = aptitudeTopics.length;
        _upcomingInterview = nextInterview;

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Preparation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.brightAccent,
          labelColor: AppColors.brightAccent,
          unselectedLabelColor: AppColors.mutedText,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.code, size: 18), text: 'Coding DSA'),
            Tab(icon: Icon(Icons.memory, size: 18), text: 'Core CS'),
            Tab(icon: Icon(Icons.calculate, size: 18), text: 'Aptitude'),
            Tab(
                icon: Icon(Icons.question_answer, size: 18),
                text: 'Interview QA'),
            Tab(
                icon: Icon(Icons.business_center, size: 18),
                text: 'Applications'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Placement Preparation Hero Card & Upcoming Interview (Screen 11 in design mockup)
          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Column(
                children: [
                  CustomCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.secondaryBackground,
                    child: Row(
                      children: [
                        // Circular Progress Gauge
                        SizedBox(
                          width: 82,
                          height: 82,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent.withValues(alpha: 0.15),
                                ),
                              ),
                              CircularProgressIndicator(
                                value: (_overallPlacementPct / 100.0).clamp(0.0, 1.0),
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.brightAccent,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_overallPlacementPct.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Overall',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Mini Track Breakdown (Coding DSA & Aptitude Practice)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniTrackRow(
                                title: 'Coding DSA',
                                completed: _codingCompleted,
                                total: _codingTotal,
                                pct: _codingPct,
                                icon: Icons.code,
                              ),
                              const SizedBox(height: 10),
                              _buildMiniTrackRow(
                                title: 'Aptitude Practice',
                                completed: _aptitudeCompleted,
                                total: _aptitudeTotal,
                                pct: _aptitudePct,
                                icon: Icons.calculate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Upcoming Interview Card (matching design mockup Screen 11: TCS May 30)
                  if (_upcomingInterview != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        // Switch to Applications tab (index 4)
                        _tabController.animateTo(4);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cardBackground,
                              AppColors.elevatedSurface.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryAccent
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_available,
                                  color: AppColors.brightAccent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Upcoming Interview: ${_upcomingInterview!.companyName}',
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: const Text(
                                          'Scheduled',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_upcomingInterview!.role} • ${_upcomingInterview!.interviewDate ?? "May 30, 2026"}',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Sub-screens
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CodingPrepScreen(),
                CoreCsScreen(),
                AptitudePrepScreen(),
                InterviewPrepScreen(),
                JobApplicationsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrackRow({
    required String title,
    required int completed,
    required int total,
    required double pct,
    required IconData icon,
  }) {
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.secondaryAccent),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$completed / $total (${pct.toStringAsFixed(0)}%)',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.15),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.secondaryAccent),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
