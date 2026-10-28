import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/progress_calculator.dart';
import '../../../models/skill.dart';
import '../../../repositories/skills_repository.dart';
import '../../../repositories/projects_repository.dart';
import '../../../repositories/tasks_repository.dart';
import '../../../repositories/certificates_repository.dart';
import '../../../repositories/placement_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SkillsRepository _skillsRepo = SkillsRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();
  final TasksRepository _tasksRepo = TasksRepository();
  final CertificatesRepository _certsRepo = CertificatesRepository();
  final PlacementRepository _placementRepo = PlacementRepository();

  bool _isLoading = true;
  ProgressMetrics _metrics = const ProgressMetrics();
  List<Skill> _skills = [];
  Map<String, int> _projectStatuses = {};
  Map<String, int> _taskCounts = {};
  Map<String, int> _certCategories = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final skills = await _skillsRepo.getAllSkills();
    final projects = await _projectsRepo.getAllProjects();
    final tasks = await _tasksRepo.getAllTasks();
    final codingTopics = await _placementRepo.getTopicsByTrack('Coding');
    final coreCsTopics = await _placementRepo.getTopicsByTrack('CoreCS');
    final aptitudeTopics = await _placementRepo.getTopicsByTrack('Aptitude');
    final interviewQuestions = await _placementRepo.getInterviewQuestions();

    final allTopics = [...codingTopics, ...coreCsTopics, ...aptitudeTopics];

    final metrics = ProgressCalculator.calculateAll(
      skills: skills,
      projects: projects,
      tasks: tasks,
      placementTopics: allTopics,
      interviewQuestions: interviewQuestions,
    );

    final projectStatuses = await _projectsRepo.getStatusCounts();
    final taskCounts = await _tasksRepo.getTaskCounts();
    final certCategories = await _certsRepo.getCategoryCounts();

    if (mounted) {
      setState(() {
        _skills = skills;
        _metrics = metrics;
        _projectStatuses = projectStatuses;
        _taskCounts = taskCounts;
        _certCategories = certCategories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Performance & Analytics')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.brightAccent)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Career Score
            CustomCard(
              gradient: AppColors.elevatedGradient,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: _metrics.overallPercentage / 100.0,
                          strokeWidth: 7,
                          backgroundColor: AppColors.cardBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brightAccent),
                        ),
                        Center(
                          child: Text(
                            '${_metrics.overallPercentage.toStringAsFixed(0)}%',
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
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Career Readiness Score',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Equally calculated from technical skills, project portfolio, task execution, and placement tracks.',
                          style: TextStyle(
                              color: AppColors.secondaryText, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tasks Donut Chart (Completed vs Pending)
            _buildTasksChart(),
            const SizedBox(height: 16),

            // Placement Domain Readiness (BarChart)
            _buildPlacementDomainsChart(),
            const SizedBox(height: 16),

            // Projects Status Distribution (BarChart)
            _buildProjectsStatusChart(),
            const SizedBox(height: 16),

            // Skills Progress Overview (Top Skills BarChart)
            _buildTopSkillsChart(),
            const SizedBox(height: 16),

            // Certificate Distribution (Categories)
            if (_certCategories.isNotEmpty) ...[
              _buildCertCategoriesCard(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksChart() {
    final completed = _taskCounts['completed'] ?? 0;
    final pending = _taskCounts['pending'] ?? 0;
    final total = completed + pending;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks: Completed vs Pending',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No task records yet to display distribution.',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          color: AppColors.success,
                          title: '$completed',
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          radius: 28,
                        ),
                        PieChartSectionData(
                          value: pending.toDouble(),
                          color: AppColors.warning,
                          title: '$pending',
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          radius: 28,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                          'Completed Tasks',
                          '$completed (${total > 0 ? (completed * 100 / total).toStringAsFixed(0) : 0}%)',
                          AppColors.success),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                          'Pending Tasks',
                          '$pending (${total > 0 ? (pending * 100 / total).toStringAsFixed(0) : 0}%)',
                          AppColors.warning),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                          'Total Logged', '$total', AppColors.secondaryAccent),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlacementDomainsChart() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Placement Preparation by Pillar',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: const TextStyle(
                            color: AppColors.mutedText, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        String text = '';
                        switch (val.toInt()) {
                          case 0:
                            text = 'Coding';
                            break;
                          case 1:
                            text = 'Core CS';
                            break;
                          case 2:
                            text = 'Aptitude';
                            break;
                          case 3:
                            text = 'Interview';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(text,
                              style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 10.5)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(
                      0, _metrics.codingPercentage, AppColors.primaryAccent),
                  _buildBarGroup(
                      1, _metrics.coreCsPercentage, AppColors.brightAccent),
                  _buildBarGroup(2, _metrics.aptitudePercentage,
                      AppColors.secondaryAccent),
                  _buildBarGroup(
                      3, _metrics.interviewPercentage, const Color(0xFFC084FC)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.clamp(0.0, 100.0),
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildProjectsStatusChart() {
    final planned = _projectStatuses['Planned'] ?? 0;
    final inProgress = _projectStatuses['In Progress'] ?? 0;
    final completed = _projectStatuses['Completed'] ?? 0;
    final onHold = _projectStatuses['On Hold'] ?? 0;

    final maxVal = [planned, inProgress, completed, onHold]
        .reduce((curr, next) => curr > next ? curr : next);
    final chartMax = maxVal < 5 ? 5.0 : (maxVal + 2).toDouble();

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projects Portfolio by Status',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                            color: AppColors.mutedText, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        String text = '';
                        switch (val.toInt()) {
                          case 0:
                            text = 'Planned';
                            break;
                          case 1:
                            text = 'Active';
                            break;
                          case 2:
                            text = 'Done';
                            break;
                          case 3:
                            text = 'On Hold';
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(text,
                              style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(0, planned.toDouble(), AppColors.info),
                  _buildBarGroup(
                      1, inProgress.toDouble(), AppColors.brightAccent),
                  _buildBarGroup(2, completed.toDouble(), AppColors.success),
                  _buildBarGroup(3, onHold.toDouble(), AppColors.warning),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSkillsChart() {
    if (_skills.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No technical skills recorded yet for analytics.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
        ),
      );
    }

    final topSkills = _skills.take(5).toList();

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Tracked Technical Skills',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...topSkills.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.name,
                          style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '${s.progressPercentage.toInt()}% (${s.proficiencyLevel})',
                          style: const TextStyle(
                              color: AppColors.brightAccent, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.progressPercentage / 100.0,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brightAccent),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCertCategoriesCard() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certifications by Domain',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _certCategories.entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            color: AppColors.secondaryText, fontSize: 11.5)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.brightAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.secondaryText, fontSize: 11)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
