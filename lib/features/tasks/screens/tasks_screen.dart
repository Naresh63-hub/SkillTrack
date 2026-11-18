import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/spring_checkbox.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../models/task_model.dart';
import '../../../models/learning_goal.dart';
import '../../../repositories/tasks_repository.dart';
import 'add_edit_task_dialog.dart';
import 'add_edit_goal_dialog.dart';
import '../../notes_planner/screens/notes_planner_hub_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final TasksRepository _repository = TasksRepository();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<TaskModel> _allTasks = [];
  List<LearningGoal> _learningGoals = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  void reload() {
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tasks = await _repository.getAllTasks(
      category: _selectedCategory,
      searchQuery: _searchController.text,
    );
    final goals = await _repository.getLearningGoals();
    setState(() {
      _allTasks = tasks;
      _learningGoals = goals;
      _isLoading = false;
    });
  }

  List<TaskModel> _getFilteredTasksForTab(int tabIndex) {
    switch (tabIndex) {
      case 1: // Today
        return _allTasks.where((t) => t.isToday && !t.isCompleted).toList();
      case 2: // Upcoming
        return _allTasks.where((t) => t.isUpcoming).toList();
      case 3: // Overdue
        return _allTasks.where((t) => t.isOverdue).toList();
      case 4: // Completed
        return _allTasks.where((t) => t.isCompleted).toList();
      case 0: // All
      default:
        return _allTasks;
    }
  }

  Future<void> _addTask() async {
    final newTask = await showDialog<TaskModel>(
      context: context,
      builder: (context) => const AddEditTaskDialog(),
    );

    if (newTask != null) {
      final id = await _repository.addTask(newTask);
      if (newTask.reminderDateTime != null) {
        try {
          final due = DateTime.parse(newTask.dueDate);
          final scheduled = await NotificationService.instance.scheduleTaskReminder(
            id: id,
            title: newTask.title,
            description: newTask.description,
            dueDateTime: due,
            earlyMinutes: newTask.earlyReminderMinutes,
            category: newTask.category,
          );
          _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(scheduled
                    ? 'Task added! Reminder scheduled ⏰'
                    : 'Task added successfully'),
              ),
            );
          }
          return;
        } catch (_) {}
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      }
    }
  }

  Future<void> _editTask(TaskModel task) async {
    final updated = await showDialog<TaskModel>(
      context: context,
      builder: (context) => AddEditTaskDialog(task: task),
    );

    if (updated != null) {
      await _repository.updateTask(updated);
      if (updated.id != null) {
        if (updated.reminderDateTime != null && !updated.isCompleted) {
          try {
            final due = DateTime.parse(updated.dueDate);
            final scheduled = await NotificationService.instance.scheduleTaskReminder(
              id: updated.id!,
              title: updated.title,
              description: updated.description,
              dueDateTime: due,
              earlyMinutes: updated.earlyReminderMinutes,
              category: updated.category,
            );
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(scheduled
                      ? 'Task updated! Reminder scheduled ⏰'
                      : 'Task updated'),
                ),
              );
            }
            return;
          } catch (_) {}
        } else {
          await NotificationService.instance.cancelTaskReminder(updated.id!);
        }
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated')),
        );
      }
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Task',
      content: 'Are you sure you want to delete "${task.title}"?',
    );

    if (confirmed) {
      if (task.id != null) {
        await NotificationService.instance.cancelTaskReminder(task.id!);
      }
      await _repository.deleteTask(task.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    }
  }

  Future<void> _toggleComplete(TaskModel task) async {
    HapticFeedback.mediumImpact();
    final newStatus = !task.isCompleted;
    if (task.id != null) {
      if (newStatus) {
        // Marked completed -> cancel scheduled reminder
        await NotificationService.instance.cancelTaskReminder(task.id!);
      } else if (task.reminderDateTime != null) {
        // Un-marked -> reschedule reminder
        try {
          final due = DateTime.parse(task.dueDate);
          await NotificationService.instance.scheduleTaskReminder(
            id: task.id!,
            title: task.title,
            description: task.description,
            dueDateTime: due,
            earlyMinutes: task.earlyReminderMinutes,
            category: task.category,
          );
        } catch (_) {}
      }
    }
    await _repository.toggleTaskComplete(task.id!, task.isCompleted);
    _loadData();

    if (mounted) {
      if (newStatus) {
        final remainingPending =
            _allTasks.where((t) => !t.isCompleted && t.id != task.id).length;
        if (remainingPending == 0 && _allTasks.isNotEmpty) {
          ConfettiOverlay.show(context);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus
              ? 'Task marked completed 🎉'
              : 'Task marked as pending'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _toggleComplete(task.copyWith(isCompleted: newStatus)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    final granted = await NotificationService.instance.requestPermissions();
    await NotificationService.instance.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Test notification sent! Check your notification tray 🔔'
              : 'Alert sent. If not visible, please enable notifications in phone Settings.'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  // --- Goal Actions ---
  Future<void> _addGoal() async {
    final newGoal = await showDialog<LearningGoal>(
      context: context,
      builder: (context) => const AddEditGoalDialog(),
    );

    if (newGoal != null) {
      await _repository.addLearningGoal(newGoal);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning goal added')),
        );
      }
    }
  }

  Future<void> _incrementGoal(LearningGoal goal) async {
    HapticFeedback.lightImpact();
    await _repository.incrementGoal(goal.id!);
    if (goal.currentCount + 1 >= goal.targetCount) {
      if (mounted) {
        ConfettiOverlay.show(context);
      }
    }
    _loadData();
  }

  Future<void> _deleteGoal(LearningGoal goal) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Goal',
      content: 'Are you sure you want to delete "${goal.title}"?',
    );
    if (confirmed) {
      await _repository.deleteLearningGoal(goal.id!);
      _loadData();
    }
  }

  void _openPlanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotesPlannerHubScreen(initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTasks = _getFilteredTasksForTab(_tabController.index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, size: 21),
            tooltip: 'Test Reminder Notification',
            onPressed: _testNotification,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 21),
            tooltip: 'Future Study Planner',
            onPressed: _openPlanner,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.brightAccent,
          labelColor: AppColors.brightAccent,
          unselectedLabelColor: AppColors.mutedText,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'All (${_allTasks.length})'),
            Tab(
                text:
                    'Today (${_allTasks.where((t) => t.isToday && !t.isCompleted).length})'),
            Tab(
                text:
                    'Upcoming (${_allTasks.where((t) => t.isUpcoming).length})'),
            Tab(
                text:
                    'Overdue (${_allTasks.where((t) => t.isOverdue).length})'),
            Tab(
                text:
                    'Completed (${_allTasks.where((t) => t.isCompleted).length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        onPressed: _addTask,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brightAccent))
          : RefreshIndicator(
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.cardBackground,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Learning Goals Section (Collapsible / Carousel style)
                  if (_learningGoals.isNotEmpty ||
                      _tabController.index == 0) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily & Weekly Targets',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            icon: const Icon(Icons.add_task, size: 15),
                            label: const Text('Add Target',
                                style: TextStyle(fontSize: 12)),
                            onPressed: _addGoal,
                          ),
                        ],
                      ),
                    ),
                    if (_learningGoals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: AppColors.secondaryAccent, size: 22),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Set targets like "Solve 5 DSA problems" or "Study OS for 1 hour".',
                                  style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12.5),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _addGoal,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                child: const Text('Set Goal',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _learningGoals.length,
                          itemBuilder: (context, index) {
                            final goal = _learningGoals[index];
                            return _buildGoalCard(goal);
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: SearchFilterBar(
                      controller: _searchController,
                      hintText: 'Search tasks...',
                      onChanged: (_) => _loadData(),
                    ),
                  ),

                  // Categories filter
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryChip('All'),
                        ...AppStrings.taskCategories
                            .map((c) => _buildCategoryChip(c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Task Items List
                  currentTasks.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.checklist,
                          title: 'No Tasks in this Tab',
                          description:
                              'Add daily study sessions, assignment deadlines, or interview practice to keep progressing.',
                          actionLabel: 'Add Task',
                          onAction: _addTask,
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentTasks.length,
                          itemBuilder: (context, index) {
                            final task = currentTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGoalCard(LearningGoal goal) {
    final isDone = goal.isCompleted || goal.currentCount >= goal.targetCount;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 205,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDone ? AppColors.success : AppColors.primaryPurple)
                  .withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success.withValues(alpha: 0.12)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    goal.goalType,
                    style: TextStyle(
                      color: isDone ? AppColors.success : AppColors.primaryPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 14, color: AppColors.mutedText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteGoal(goal),
                ),
              ],
            ),
            Text(
              goal.title,
              style: TextStyle(
                color: isDone ? AppColors.mutedText : AppColors.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                // Duolingo-style mini Activity Ring
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (goal.progressPercentage / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 3.5,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? AppColors.success : const Color(0xFF7C3AED),
                        ),
                      ),
                      if (isDone)
                        const Icon(Icons.check, size: 14, color: AppColors.success)
                      else
                        Text(
                          '${goal.currentCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${goal.currentCount}/${goal.targetCount} target',
                    style: TextStyle(
                      color: isDone ? AppColors.success : AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: isDone ? null : () => _incrementGoal(goal),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.surfaceVariant
                          : AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDone ? 'Done' : '+1',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.mutedText : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        selectedColor: AppColors.elevatedSurface,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.brightAccent : AppColors.secondaryText,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.brightAccent : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
          _loadData();
        },
      ),
    );
  }

  Widget _buildVisualPriorityBadge(String priority) {
    Color bg;
    Color text;
    Color border;
    String label;

    switch (priority) {
      case 'High':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        border = const Color(0xFFFCA5A5);
        label = '🔥 High';
        break;
      case 'Medium':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        label = '⚡ Med';
        break;
      case 'Low':
      default:
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF059669);
        border = const Color(0xFFA7F3D0);
        label = '☕ Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final isOverdue = task.isOverdue;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      onTap: () => _editTask(task),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spring-Animated Circular Completion Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 6),
            child: SpringCheckbox(
              value: task.isCompleted,
              onChanged: (_) => _toggleComplete(task),
            ),
          ),
          const SizedBox(width: 4),
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
                Row(
                  children: [
                    _buildVisualPriorityBadge(task.priority),
                    const SizedBox(width: 8),
                    if (task.category == 'Call / Meeting') ...[
                      const Icon(Icons.phone_in_talk,
                          size: 11, color: AppColors.brightAccent),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      task.category,
                      style: TextStyle(
                        color: task.category == 'Call / Meeting'
                            ? AppColors.brightAccent
                            : AppColors.mutedText,
                        fontSize: 11,
                        fontWeight: task.category == 'Call / Meeting'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (task.earlyReminderLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.4),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active,
                                size: 9.5, color: AppColors.lightPurple),
                            const SizedBox(width: 3),
                            Text(
                              task.earlyReminderLabel!,
                              style: const TextStyle(
                                color: AppColors.lightPurple,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      isOverdue ? Icons.warning : Icons.schedule,
                      size: 13,
                      color: isOverdue ? AppColors.error : AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.relativeDueString(task.dueDate),
                      style: TextStyle(
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 18, color: AppColors.mutedText),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.secondaryBackground,
            onSelected: (action) {
              if (action == 'edit') {
                _editTask(task);
              } else if (action == 'delete') {
                _deleteTask(task);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: AppColors.secondaryText),
                    SizedBox(width: 8),
                    Text('Edit',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
