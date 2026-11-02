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
import '../widgets/weekly_activity_card.dart';
import '../widgets/continue_learning_section.dart';
import '../widgets/placement_prep_modules_section.dart';

import '../../skills/screens/add_edit_skill_dialog.dart';
import '../../skills/screens/skill_detail_screen.dart';
import '../../certificates/screens/add_edit_certificate_dialog.dart';
import '../../certificates/screens/certificates_screen.dart';
import '../../projects/screens/add_edit_project_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../tasks/screens/add_edit_task_dialog.dart';
import '../../resume/screens/resume_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../skills/screens/career_roadmaps_screen.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/widgets/celebration_dialog.dart';
import '../../../models/job_application.dart';

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
  List<Skill> _allSkills = [];
  List<Project> _allProjects = [];
  List<TaskModel> _allTasks = [];
  int _skillsCount = 0;
  int _certsCount = 0;
  int _projectsCount = 0;
  int _completedSkillsCount = 0;
  int _completedProjectsCount = 0;
  int _pendingTasksCount = 0;
  int _completedTasksCount = 0;
  int _activeStreak = 0;
  JobApplication? _upcomingInterview;
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
    final applications = await _placementRepo.getJobApplications();

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

    JobApplication? nextInterview;
    for (final app in applications) {
      if (app.status == 'Interview' || app.hasUpcomingInterview) {
        nextInterview = app;
        break;
      }
    }

    final streak =
        StreakCalculator.calculateStreak(tasks: tasks, skills: skills);

    final completedSkills =
        skills.where((s) => s.progressPercentage >= 100).length;
    final completedProjects =
        projects.where((p) => p.status == 'Completed').length;

    if (mounted) {
      setState(() {
        _profile = profile;
        _metrics = metrics;
        _allSkills = skills;
        _allProjects = projects;
        _allTasks = tasks;
        _skillsCount = skills.length;
        _certsCount = certsCount;
        _projectsCount = projects.length;
        _completedSkillsCount = completedSkills;
        _completedProjectsCount = completedProjects;
        _pendingTasksCount = taskCounts['pending'] ?? 0;
        _completedTasksCount = taskCounts['completed'] ?? 0;
        _upcomingDeadlines = upcomingDeadlines;
        _recentProjects = recentProjects;
        _activeStreak = streak;
        _upcomingInterview = nextInterview;
        _isLoading = false;
      });
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          color: AppColors.lightPurple, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Notifications & Deadlines',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mutedText),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_upcomingDeadlines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No urgent deadlines pending. Keep up the great pace!',
                      style:
                          TextStyle(color: AppColors.mutedText, fontSize: 13),
                    ),
                  ),
                )
              else
                ..._upcomingDeadlines.map(
                  (task) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_rounded,
                            color: AppColors.lightPurple, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Due: ${task.dueDate}',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onNavigateTab?.call(3); // Tasks tab
                  },
                  child: const Text('View All Tasks'),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _openRoadmaps() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (ctx) => const CareerRoadmapsScreen()),
        )
        .then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SkillTrack')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    final p = _profile!;
    final firstName =
        p.name.trim().isNotEmpty ? p.name.trim().split(" ").first : 'Student';

    final quickActions = [
      QuickActionItem(
          label: 'Add Skill',
          icon: Icons.code_rounded,
          color: AppColors.primaryPurple,
          onTap: _quickAddSkill),
      QuickActionItem(
          label: 'Skill Roadmaps',
          icon: Icons.alt_route_rounded,
          color: AppColors.secondaryAccent,
          onTap: _openRoadmaps),
      QuickActionItem(
          label: 'Add Certificate',
          icon: Icons.verified_rounded,
          color: AppColors.gradientHighlight,
          onTap: _quickAddCert),
      QuickActionItem(
          label: 'Add Project',
          icon: Icons.folder_rounded,
          color: AppColors.lightPurple,
          onTap: _quickAddProject),
      QuickActionItem(
          label: 'Add Task',
          icon: Icons.task_alt_rounded,
          color: AppColors.warning,
          onTap: _quickAddTask),
      QuickActionItem(
          label: 'Placement Prep',
          icon: Icons.school_rounded,
          color: const Color(0xFFC084FC),
          onTap: _quickPlacementPrep),
      QuickActionItem(
          label: 'Build Resume',
          icon: Icons.picture_as_pdf_rounded,
          color: AppColors.lightPurple,
          onTap: _quickGenerateResume),
    ];

    final ongoingSkills =
        _allSkills.where((s) => s.progressPercentage < 100).toList();
    final ongoingProjects =
        _allProjects.where((p) => p.status == 'In Progress').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            SkillTrackLogo(size: 32),
            SizedBox(width: 10),
            Text(
              'SkillTrack',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 23),
            tooltip: 'Notifications',
            onPressed: _showNotificationsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, size: 23),
            tooltip: 'Milestones & Celebration',
            onPressed: () => CelebrationDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 23),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 23),
            tooltip: 'Profile',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              );
              _loadDashboardData();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryPurple,
        backgroundColor: AppColors.cardBackground,
        onRefresh: _loadDashboardData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Header (Personalized Greeting, Avatar, Target Role & Streak Badge)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondaryCard,
                                  border: Border.all(
                                    color: AppColors.primaryPurple,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: firstName.isNotEmpty
                                      ? Text(
                                          firstName[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryPurple,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primaryPurple,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getTimeGreeting()}, $firstName 👋',
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p.college.isNotEmpty
                                        ? p.college
                                        : 'Student Developer',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.lightPurple,
                                  size: 18,
                                ),
                              ),
                              onPressed: _showNotificationsSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Target Role Pill (Matching Screen 3 of reference mockup)
                            Flexible(
                              child: InkWell(
                                onTap: _openRoadmaps,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryPurple
                                          .withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.gps_fixed_rounded,
                                        size: 12,
                                        color: AppColors.lightPurple,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Target: ${p.targetJobRole.trim().isNotEmpty ? p.targetJobRole : "Flutter Developer"}',
                                          style: const TextStyle(
                                            color: AppColors.lightPurple,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 9,
                                        color: AppColors.lightPurple,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Daily Streak Flame Badge (Matching Screen 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _activeStreak > 0
                                        ? '$_activeStreak Day${_activeStreak > 1 ? "s" : ""}'
                                        : '3 Days',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upcoming Placement Interview Banner (if active)
                  if (_upcomingInterview != null) ...[
                    InkWell(
                      onTap: () => widget.onNavigateTab?.call(4),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEDE9FE), Color(0xFFFAF5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.gradientHighlight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Interview: ${_upcomingInterview!.companyName}',
                                        style: const TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Active',
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
                                    '${_upcomingInterview!.role} • ${_upcomingInterview!.interviewDate ?? "Interview Round Scheduled"}',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.lightPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // B. Overall Progress Card
                  OverallProgressCard(
                    metrics: _metrics,
                    skillsCompleted: _completedSkillsCount,
                    projectsCompleted: _completedProjectsCount,
                  ),
                  const SizedBox(height: 18),

                  // Quick Actions Bar
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  QuickActionsBar(actions: quickActions),
                  const SizedBox(height: 20),

                  // C. Statistics Cards (MetricSummaryGrid)
                  const Text(
                    'Preparation Metrics',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),

                  // D. Weekly Learning Activity
                  WeeklyActivityCard(
                    tasks: _allTasks,
                    skills: _allSkills,
                  ),
                  const SizedBox(height: 20),

                  // E. Continue Learning Section
                  ContinueLearningSection(
                    ongoingSkills: ongoingSkills,
                    ongoingProjects: ongoingProjects,
                    onSkillTap: (skill) {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  SkillDetailScreen(initialSkill: skill),
                            ),
                          )
                          .then((_) => _loadDashboardData());
                    },
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
                    onViewAll: () =>
                        widget.onNavigateTab?.call(1), // Skills tab
                  ),
                  const SizedBox(height: 20),

                  // F. Placement Preparation Modules
                  PlacementPrepModulesSection(
                    onOpenPlacementHub: () =>
                        widget.onNavigateTab?.call(4), // Placement tab
                    onRefresh: _loadDashboardData,
                  ),
                  const SizedBox(height: 20),

                  // G. Recent Tasks & Upcoming Deadlines
                  SectionHeader(
                    title: 'Upcoming Deadlines',
                    actionText: 'View All Tasks',
                    onAction: () => widget.onNavigateTab?.call(3), // Tasks tab
                  ),
                  UpcomingDeadlinesList(
                    tasks: _upcomingDeadlines,
                    onTaskTap: (task) => widget.onNavigateTab?.call(3),
                  ),
                  const SizedBox(height: 20),

                  // Recent Projects Showcase
                  SectionHeader(
                    title: 'Recent Projects',
                    actionText: 'View Portfolio',
                    onAction: () =>
                        widget.onNavigateTab?.call(2), // Portfolio tab
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
        ),
      ),
    );
  }
}
