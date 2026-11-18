import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/planner_event.dart';
import '../../../models/project.dart';
import '../../../models/skill.dart';
import '../../../models/task_model.dart';
import '../../../repositories/planner_repository.dart';
import '../../../repositories/skills_repository.dart';
import '../../../repositories/tasks_repository.dart';
import '../../notes_planner/widgets/add_edit_event_dialog.dart';
import '../../skills/screens/skill_detail_screen.dart';
import '../../tasks/screens/add_edit_task_dialog.dart';
import '../../../core/notifications/notification_service.dart';

class WeeklyPlansScreen extends StatefulWidget {
  final List<TaskModel>? initialTasks;
  final List<Skill>? initialSkills;
  final List<Project>? initialProjects;
  final Set<DateTime>? activeDates;
  final int initialDayIndex; // -1 for All, 0 for Mon, 6 for Sun
  final Function(int tabIndex)? onNavigateTab;

  const WeeklyPlansScreen({
    super.key,
    this.initialTasks,
    this.initialSkills,
    this.initialProjects,
    this.activeDates,
    this.initialDayIndex = -1,
    this.onNavigateTab,
  });

  @override
  State<WeeklyPlansScreen> createState() => _WeeklyPlansScreenState();
}

class _WeeklyPlansScreenState extends State<WeeklyPlansScreen> {
  final TasksRepository _tasksRepo = TasksRepository();
  final PlannerRepository _plannerRepo = PlannerRepository();
  final SkillsRepository _skillsRepo = SkillsRepository();

  late int _selectedDayIndex; // -1 = All Week, 0..6 = Mon..Sun
  bool _isLoading = true;

  List<TaskModel> _tasks = [];
  List<PlannerEvent> _events = [];
  List<Skill> _skills = [];
  List<Project> get _projects => widget.initialProjects ?? [];
  Set<DateTime> get _activeDates => widget.activeDates ?? {};

  late DateTime _monday;
  late DateTime _sunday;
  final List<DateTime> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.initialDayIndex;

    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    _monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: currentWeekday - 1));
    _sunday = _monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    for (int i = 0; i < 7; i++) {
      _weekDays.add(_monday.add(Duration(days: i)));
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _tasksRepo.getAllTasks(),
        _plannerRepo.getAllEvents(),
        _skillsRepo.getAllSkills(),
      ]);

      if (mounted) {
        setState(() {
          _tasks = results[0] as List<TaskModel>;
          _events = results[1] as List<PlannerEvent>;
          _skills = results[2] as List<Skill>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tasks = widget.initialTasks ?? [];
          _skills = widget.initialSkills ?? [];
          _isLoading = false;
        });
      }
    }
  }

  // Filter tasks based on selected day or all week
  List<TaskModel> get _filteredTasks {
    if (_selectedDayIndex == -1) {
      // All week: tasks due this week or overdue
      return _tasks.where((t) {
        try {
          final due = DateTime.parse(t.dueDate);
          return due.isAfter(_monday.subtract(const Duration(days: 14))) &&
              due.isBefore(_sunday.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();
    } else {
      final targetDay = _weekDays[_selectedDayIndex];
      return _tasks.where((t) {
        try {
          final due = DateTime.parse(t.dueDate);
          return due.year == targetDay.year &&
              due.month == targetDay.month &&
              due.day == targetDay.day;
        } catch (_) {
          return false;
        }
      }).toList();
    }
  }

  // Filter planner events based on selected day or all week
  List<PlannerEvent> get _filteredEvents {
    if (_selectedDayIndex == -1) {
      return _events.where((e) {
        try {
          final dt = DateTime.parse(e.targetDate);
          return dt.isAfter(_monday.subtract(const Duration(days: 1))) &&
              dt.isBefore(_sunday.add(const Duration(days: 14)));
        } catch (_) {
          return true;
        }
      }).toList();
    } else {
      final targetDay = _weekDays[_selectedDayIndex];
      final targetDayStr =
          "${targetDay.year}-${targetDay.month.toString().padLeft(2, '0')}-${targetDay.day.toString().padLeft(2, '0')}";
      return _events.where((e) => e.targetDate == targetDayStr).toList();
    }
  }

  // Activities completed this week
  List<TaskModel> get _completedThisWeek {
    return _tasks.where((t) {
      if (!t.isCompleted) return false;
      if (t.completedAt != null) {
        try {
          final comp = DateTime.parse(t.completedAt!);
          return comp.isAfter(_monday) && comp.isBefore(_sunday);
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  Future<void> _toggleTask(TaskModel task) async {
    final newStatus = !task.isCompleted;
    if (task.id != null) {
      if (newStatus) {
        await NotificationService.instance.cancelTaskReminder(task.id!);
      }
    }
    await _tasksRepo.toggleTaskComplete(task.id!, task.isCompleted);
    _loadData();
  }

  Future<void> _toggleEvent(PlannerEvent event) async {
    await _plannerRepo.toggleEventCompleted(event.id!, event.isCompleted);
    _loadData();
  }

  Future<void> _addNewTask() async {
    final result = await showDialog<TaskModel>(
      context: context,
      builder: (ctx) => const AddEditTaskDialog(),
    );
    if (result != null) {
      final id = await _tasksRepo.addTask(result);
      if (result.reminderDateTime != null) {
        try {
          final due = DateTime.parse(result.dueDate);
          await NotificationService.instance.scheduleTaskReminder(
            id: id,
            title: result.title,
            description: result.description,
            dueDateTime: due,
            earlyMinutes: result.earlyReminderMinutes,
            category: result.category,
          );
        } catch (_) {}
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added to this week’s plan')),
        );
      }
    }
  }

  Future<void> _addNewEvent() async {
    String? initialDate;
    if (_selectedDayIndex >= 0 && _selectedDayIndex < 7) {
      final d = _weekDays[_selectedDayIndex];
      initialDate =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    final result = await showDialog<PlannerEvent>(
      context: context,
      builder: (ctx) => AddEditEventDialog(initialDate: initialDate),
    );
    if (result != null) {
      await _plannerRepo.addEvent(result);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event scheduled successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStartStr = DateFormat('MMM d').format(_monday);
    final weekEndStr = DateFormat('MMM d, yyyy').format(_sunday);

    final pendingTasks = _filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _filteredTasks.where((t) => t.isCompleted).toList();
    final upcomingEvents = _filteredEvents.where((e) => !e.isCompleted).toList();
    final completedEvents = _filteredEvents.where((e) => e.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        title: const Text(
          'Weekly Plans & Schedule',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.secondaryText),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Summary Header Card
                    _buildSummaryHeader(weekStartStr, weekEndStr),
                    const SizedBox(height: 16),

                    // B. Interactive 7-Day Week Selector
                    _buildDaySelector(),
                    const SizedBox(height: 20),

                    // C. Section: Tasks for This Week
                    _buildTasksSection(pendingTasks, completedTasks),
                    const SizedBox(height: 24),

                    // D. Section: Future Plans & Scheduled Events
                    _buildEventsSection(upcomingEvents, completedEvents),
                    const SizedBox(height: 24),

                    // E. Section: Skills Targeted This Week
                    _buildSkillsSection(),
                    const SizedBox(height: 24),

                    // F. Section: Completed Activity Log
                    if (_completedThisWeek.isNotEmpty) ...[
                      _buildCompletedLogSection(),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSummaryHeader(String startStr, String endStr) {
    final totalCompleted = _completedThisWeek.length;
    final totalPendingTasks = _tasks.where((t) => !t.isCompleted).length;
    final totalEvents = _events.where((e) => !e.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.lightPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Roadmap',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$startStr – $endStr',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleProgressGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCompleted Done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatBadge(
                icon: Icons.checklist_rounded,
                label: '$totalPendingTasks Pending',
                color: AppColors.brightAccent,
              ),
              _buildStatBadge(
                icon: Icons.event_available_rounded,
                label: '$totalEvents Scheduled',
                color: AppColors.lightPurple,
              ),
              _buildStatBadge(
                icon: Icons.trending_up_rounded,
                label: '${_skills.length} Skills',
                color: Colors.amberAccent,
              ),
              if (_projects.isNotEmpty)
                _buildStatBadge(
                  icon: Icons.folder_outlined,
                  label: '${_projects.length} Projects',
                  color: AppColors.lightPurple,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final now = DateTime.now();
    final todayWeekday = now.weekday - 1; // 0 = Mon
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Week Pill
          GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = -1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _selectedDayIndex == -1
                    ? AppColors.primaryPurple
                    : AppColors.secondaryCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedDayIndex == -1
                      ? AppColors.brightAccent
                      : AppColors.border,
                ),
              ),
              child: Text(
                'All Week',
                style: TextStyle(
                  color: _selectedDayIndex == -1
                      ? Colors.white
                      : AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 7 Day Pills
          ...List.generate(7, (index) {
            final isSelected = _selectedDayIndex == index;
            final isToday = index == todayWeekday;
            final dayDate = _weekDays[index];

            final hasActivity = _activeDates.contains(
                DateTime(dayDate.year, dayDate.month, dayDate.day));

            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : AppColors.secondaryCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brightAccent
                        : (isToday
                            ? AppColors.primaryPurple.withValues(alpha: 0.6)
                            : AppColors.border),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayNames[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? AppColors.lightPurple
                                : AppColors.mutedText),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${dayDate.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? AppColors.primaryText
                                : AppColors.secondaryText),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isToday || hasActivity) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : (hasActivity
                                  ? AppColors.success
                                  : AppColors.brightAccent),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTasksSection(
      List<TaskModel> pendingTasks, List<TaskModel> completedTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: AppColors.lightPurple),
                const SizedBox(width: 8),
                Text(
                  _selectedDayIndex == -1
                      ? 'Tasks This Week (${pendingTasks.length})'
                      : 'Tasks for Selected Day (${pendingTasks.length})',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _addNewTask,
              icon: const Icon(Icons.add, size: 16, color: AppColors.lightPurple),
              label: const Text(
                'Add Task',
                style: TextStyle(
                  color: AppColors.lightPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendingTasks.isEmpty && completedTasks.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.task_alt,
                      size: 36, color: AppColors.mutedText),
                  const SizedBox(height: 8),
                  const Text(
                    'No tasks scheduled for this period',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addNewTask,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Task Now'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...pendingTasks.map((t) => _buildTaskItem(t)),
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Completed (${completedTasks.length})',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: completedTasks.map((t) => _buildTaskItem(t)).toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    Color pColor;
    switch (task.priority) {
      case 'High':
        pColor = AppColors.priorityHigh;
        break;
      case 'Medium':
        pColor = AppColors.priorityMedium;
        break;
      default:
        pColor = AppColors.priorityLow;
    }

    final isCall = task.category == 'Call / Meeting';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.success,
            onChanged: (_) => _toggleTask(task),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: task.isCompleted
                        ? AppColors.mutedText
                        : AppColors.primaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description!,
                    style: const TextStyle(
                        color: AppColors.secondaryText, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: pColor.withValues(alpha: 0.4), width: 0.7),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                            color: pColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.border, width: 0.7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCall) ...[
                            const Icon(Icons.phone_in_talk,
                                size: 10, color: AppColors.brightAccent),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            task.category,
                            style: TextStyle(
                              color: isCall
                                  ? AppColors.brightAccent
                                  : AppColors.secondaryText,
                              fontSize: 10.5,
                              fontWeight: isCall
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (task.earlyReminderLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.primaryPurple.withValues(alpha: 0.4),
                              width: 0.7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active,
                                size: 10, color: AppColors.lightPurple),
                            const SizedBox(width: 3),
                            Text(
                              task.earlyReminderLabel!,
                              style: const TextStyle(
                                  color: AppColors.lightPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 10, color: AppColors.mutedText),
                          const SizedBox(width: 3),
                          Text(
                            DateFormatter.relativeDueString(task.dueDate),
                            style: TextStyle(
                              color: task.isOverdue
                                  ? AppColors.error
                                  : AppColors.secondaryText,
                              fontSize: 10.5,
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
        ],
      ),
    );
  }

  Widget _buildEventsSection(
      List<PlannerEvent> upcomingEvents, List<PlannerEvent> completedEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded,
                    size: 18, color: AppColors.brightAccent),
                const SizedBox(width: 8),
                Text(
                  _selectedDayIndex == -1
                      ? 'Future Plans & Events (${upcomingEvents.length})'
                      : 'Events on Selected Day (${upcomingEvents.length})',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _addNewEvent,
              icon: const Icon(Icons.add, size: 16, color: AppColors.brightAccent),
              label: const Text(
                'Schedule',
                style: TextStyle(
                  color: AppColors.brightAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upcomingEvents.isEmpty && completedEvents.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.event_available,
                      size: 32, color: AppColors.mutedText),
                  const SizedBox(height: 6),
                  const Text(
                    'No calls or events scheduled yet',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addNewEvent,
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Schedule Call or Meeting'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...upcomingEvents.map((e) => _buildEventItem(e)),
          if (completedEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Past / Completed Events (${completedEvents.length})',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: completedEvents.map((e) => _buildEventItem(e)).toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEventItem(PlannerEvent event) {
    final isCall = event.eventType == 'Call / Meeting';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: event.isCompleted,
            activeColor: AppColors.success,
            onChanged: (_) => _toggleEvent(event),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isCall
                            ? AppColors.brightAccent.withValues(alpha: 0.15)
                            : AppColors.primaryPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCall
                              ? AppColors.brightAccent.withValues(alpha: 0.4)
                              : AppColors.primaryPurple.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCall
                                ? Icons.phone_in_talk
                                : Icons.bookmark_border_rounded,
                            size: 11,
                            color: isCall
                                ? AppColors.brightAccent
                                : AppColors.lightPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.eventType,
                            style: TextStyle(
                              color: isCall
                                  ? AppColors.brightAccent
                                  : AppColors.lightPurple,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.countdownLabel,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: TextStyle(
                    color: event.isCompleted
                        ? AppColors.mutedText
                        : AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration:
                        event.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.description!,
                    style: const TextStyle(
                        color: AppColors.secondaryText, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          event.targetDate,
                          style: const TextStyle(
                              color: AppColors.secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                    if (event.startTime != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.lightPurple),
                          const SizedBox(width: 4),
                          Text(
                            event.endTime != null
                                ? '${event.startTime} - ${event.endTime}'
                                : event.startTime!,
                            style: const TextStyle(
                                color: AppColors.lightPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    if (event.reminderLabel != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active,
                              size: 12, color: AppColors.brightAccent),
                          const SizedBox(width: 4),
                          Text(
                            event.reminderLabel!,
                            style: const TextStyle(
                                color: AppColors.brightAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final activeSkills = _skills.where((s) => s.progressPercentage < 100).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.code_rounded,
                    size: 18, color: AppColors.lightPurple),
                const SizedBox(width: 8),
                Text(
                  'Skills In Progress (${activeSkills.length})',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.onNavigateTab != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onNavigateTab!(1); // Navigate to Skills Tab
                },
                child: const Text('View All Skills >',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (activeSkills.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'All skills completed! Add new skills to keep leveling up.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
            ),
          )
        else
          ...activeSkills.take(3).map((s) {
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (ctx) => SkillDetailScreen(initialSkill: s),
                        ),
                      )
                      .then((_) => _loadData());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${s.progressPercentage.toInt()}%',
                          style: const TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.progressPercentage / 100,
                        backgroundColor: AppColors.progressTrack,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCompletedLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.celebration_rounded,
                size: 18, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Text(
              'Completed This Week (${_completedThisWeek.length})',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._completedThisWeek.map((t) {
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.title,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12.5,
                      decoration: TextDecoration.lineThrough,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  t.completedAt != null
                      ? DateFormat('EEE, h:mm a')
                          .format(DateTime.parse(t.completedAt!))
                      : 'Completed',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Add Task'),
                onPressed: _addNewTask,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_alert_rounded, size: 16),
                label: const Text('Schedule Plan'),
                onPressed: _addNewEvent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
