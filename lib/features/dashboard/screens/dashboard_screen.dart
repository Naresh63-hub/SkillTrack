import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skilltrack_logo.dart';
import '../../../core/utils/progress_calculator.dart';
import '../../../models/student_profile.dart';
import '../../../models/skill.dart';
import '../../../models/project.dart';
import '../../../models/task_model.dart';
import '../../../models/certificate.dart';
import '../../../repositories/profile_repository.dart';
import '../../../repositories/skills_repository.dart';
import '../../../repositories/projects_repository.dart';
import '../../../repositories/tasks_repository.dart';
import '../../../repositories/certificates_repository.dart';
import '../../../repositories/placement_repository.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/metric_summary_grid.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/upcoming_deadlines_list.dart';
import '../widgets/recent_projects_list.dart';

import '../../skills/screens/add_edit_skill_dialog.dart';
import '../../certificates/screens/add_edit_certificate_dialog.dart';
import '../../certificates/screens/certificates_screen.dart';
import '../../projects/screens/add_edit_project_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../tasks/screens/add_edit_task_dialog.dart';
import '../../resume/screens/resume_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  final SkillsRepository _skillsRepo = SkillsRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();
  final TasksRepository _tasksRepo = TasksRepository();
  final CertificatesRepository _certsRepo = CertificatesRepository();
  final PlacementRepository _placementRepo = PlacementRepository();

  StudentProfile? _profile;
  ProgressMetrics _metrics = const ProgressMetrics();
  int _skillsCount = 0;
  int _certsCount = 0;
  int _projectsCount = 0;
  int _pendingTasksCount = 0;
  int _completedTasksCount = 0;
  List<TaskModel> _upcomingDeadlines = [];
  List<Project> _recentProjects = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final profile = await _profileRepo.getProfile();
    final skills = await _skillsRepo.getAllSkills();
    final projects = await _projectsRepo.getAllProjects();
    final tasks = await _tasksRepo.getAllTasks();
    final certsCount = await _certsRepo.getCertificatesCount();

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

    final taskCounts = await _tasksRepo.getTaskCounts();
    final upcomingDeadlines = await _tasksRepo.getUpcomingDeadlines(limit: 3);
    final recentProjects = await _projectsRepo.getRecentProjects(limit: 3);

    if (mounted) {
      setState(() {
        _profile = profile;
        _metrics = metrics;
        _skillsCount = skills.length;
        _certsCount = certsCount;
        _projectsCount = projects.length;
        _pendingTasksCount = taskCounts['pending'] ?? 0;
        _completedTasksCount = taskCounts['completed'] ?? 0;
        _upcomingDeadlines = upcomingDeadlines;
        _recentProjects = recentProjects;
        _isLoading = false;
      });
    }
  }

  // Quick Action handlers
  Future<void> _quickAddSkill() async {
    final newSkill = await showDialog<Skill>(
      context: context,
      builder: (ctx) => const AddEditSkillDialog(),
    );
    if (newSkill != null) {
      await _skillsRepo.addSkill(newSkill);
      _loadDashboardData();
    }
  }

  Future<void> _quickAddCert() async {
    final newCert = await showDialog<Certificate>(
      context: context,
      builder: (ctx) => const AddEditCertificateDialog(),
    );
    if (newCert != null) {
      await _certsRepo.addCertificate(newCert);
      _loadDashboardData();
    }
  }

  Future<void> _quickAddProject() async {
    final newProj = await Navigator.of(context).push<Project>(
      MaterialPageRoute(builder: (ctx) => const AddEditProjectScreen()),
    );
    if (newProj != null) {
      await _projectsRepo.addProject(newProj);
      _loadDashboardData();
    }
  }

  Future<void> _quickAddTask() async {
    final newTask = await showDialog<TaskModel>(
      context: context,
      builder: (ctx) => const AddEditTaskDialog(),
    );
    if (newTask != null) {
      await _tasksRepo.addTask(newTask);
      _loadDashboardData();
    }
  }

  void _quickPlacementPrep() {
    widget.onNavigateTab?.call(4); // Placement Tab
  }

  void _quickGenerateResume() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const ResumeScreen()),
    );
  }

  void _openCertificatesScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (ctx) => const CertificatesScreen()),
        )
        .then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SkillTrack')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.brightAccent)),
      );
    }

    final p = _profile!;

    final quickActions = [
      QuickActionItem(
          label: 'Add Skill',
          icon: Icons.code,
          color: AppColors.primaryAccent,
          onTap: _quickAddSkill),
      QuickActionItem(
          label: 'Add Certificate',
          icon: Icons.verified,
          color: AppColors.brightAccent,
          onTap: _quickAddCert),
      QuickActionItem(
          label: 'Add Project',
          icon: Icons.folder,
          color: AppColors.secondaryAccent,
          onTap: _quickAddProject),
      QuickActionItem(
          label: 'Add Task',
          icon: Icons.task_alt,
          color: AppColors.warning,
          onTap: _quickAddTask),
      QuickActionItem(
          label: 'Placement Prep',
          icon: Icons.school,
          color: const Color(0xFFC084FC),
          onTap: _quickPlacementPrep),
      QuickActionItem(
          label: 'Build Resume',
          icon: Icons.picture_as_pdf,
          color: AppColors.info,
          onTap: _quickGenerateResume),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            SkillTrackLogo(size: 32),
            SizedBox(width: 10),
            Text('SkillTrack'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 22),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            tooltip: 'Profile',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              );
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brightAccent,
        backgroundColor: AppColors.cardBackground,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Target Role (matching design mockup Screen 4)
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (ctx) => const ProfileScreen()),
                      );
                      _loadDashboardData();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryBackground,
                        border: Border.all(
                          color: AppColors.primaryAccent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: p.name.trim().isNotEmpty
                            ? Text(
                                p.name.trim()[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAccent,
                                ),
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primaryAccent,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.trim().isNotEmpty
                              ? 'Hello, ${p.name.trim().split(" ").first} 👋'
                              : 'Hello there! 👋',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.targetJobRole.trim().isNotEmpty
                              ? p.targetJobRole
                              : 'Tap your profile to get started',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Overall Progress Card
              OverallProgressCard(metrics: _metrics),
              const SizedBox(height: 16),

              // Quick Actions Horizontal Bar
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              QuickActionsBar(actions: quickActions),
              const SizedBox(height: 16),

              // Metrics Summary Grid (2x3 or 3x2 responsive)
              const Text(
                'Preparation Metrics',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              MetricSummaryGrid(
                skillsCount: _skillsCount,
                certsCount: _certsCount,
                projectsCount: _projectsCount,
                pendingTasksCount: _pendingTasksCount,
                completedTasksCount: _completedTasksCount,
                placementProgress: _metrics.placementPercentage,
                onNavigateTab: widget.onNavigateTab,
                onCertificatesTap: _openCertificatesScreen,
              ),
              const SizedBox(height: 16),

              // Upcoming Deadlines
              SectionHeader(
                title: 'Upcoming Deadlines',
                actionText: 'View All Tasks',
                onAction: () => widget.onNavigateTab?.call(3), // Tasks tab
              ),
              UpcomingDeadlinesList(
                tasks: _upcomingDeadlines,
                onTaskTap: (task) => widget.onNavigateTab?.call(3),
              ),
              const SizedBox(height: 16),

              // Recent Projects
              SectionHeader(
                title: 'Recent Projects',
                actionText: 'View Portfolio',
                onAction: () => widget.onNavigateTab?.call(2), // Portfolio tab
              ),
              RecentProjectsList(
                projects: _recentProjects,
                onProjectTap: (project) {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (ctx) =>
                              ProjectDetailScreen(initialProject: project),
                        ),
                      )
                      .then((_) => _loadDashboardData());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}
