import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/validators.dart';
import '../../../models/task_model.dart';
import '../../../services/draft_service.dart';

class AddEditTaskDialog extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskDialog({super.key, this.task});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _category;
  late String _priority;
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = const TimeOfDay(hour: 18, minute: 0);
  bool _setReminder = false;
  int _earlyReminderMinutes = 15;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? AppStrings.taskCategories.first;
    _priority = t?.priority ?? 'Medium';

    if (t?.dueDate != null && t!.dueDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(t.dueDate);
        _dueDate = dt;
        _dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    } else {
      final now = DateTime.now();
      final nextHour = now.add(const Duration(hours: 1));
      if (now.hour >= 22) {
        _dueDate = now.add(const Duration(days: 1));
        _dueTime = const TimeOfDay(hour: 10, minute: 0);
      } else {
        _dueDate = now;
        _dueTime = TimeOfDay(hour: nextHour.hour, minute: 0);
      }
    }
    _setReminder = (t?.reminderDateTime != null && t!.reminderDateTime!.isNotEmpty) ||
        (t?.earlyReminderMinutes != null);
    _earlyReminderMinutes = t?.earlyReminderMinutes ?? 15;

    if (widget.task == null) {
      _restoreDraft();
      _titleController.addListener(_autoSaveDraft);
      _descController.addListener(_autoSaveDraft);
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await DraftService.instance.getDraft('add_task');
    if (draft != null && mounted) {
      setState(() {
        if (draft['title'] != null && _titleController.text.isEmpty) {
          _titleController.text = draft['title'];
        }
        if (draft['description'] != null && _descController.text.isEmpty) {
          _descController.text = draft['description'];
        }
        if (draft['category'] != null) {
          _category = draft['category'];
        }
        if (draft['priority'] != null) {
          _priority = draft['priority'];
        }
        if (draft['earlyReminderMinutes'] != null) {
          _earlyReminderMinutes = draft['earlyReminderMinutes'] as int;
        }
        if (draft['setReminder'] != null) {
          _setReminder = draft['setReminder'] as bool;
        }
        if (_titleController.text.isNotEmpty ||
            _descController.text.isNotEmpty) {
          _draftRestored = true;
        }
      });
    }
  }

  void _autoSaveDraft() {
    if (widget.task != null) return;
    DraftService.instance.saveDraft('add_task', {
      'title': _titleController.text,
      'description': _descController.text,
      'category': _category,
      'priority': _priority,
      'earlyReminderMinutes': _earlyReminderMinutes,
      'setReminder': _setReminder,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _autoSaveDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEditing ? 'Edit Task' : 'New Task',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_draftRestored) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primaryPurple
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Draft restored',
                              style: TextStyle(
                                color: AppColors.lightPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedText),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  validator: (v) => Validators.requiredField(v, 'Task title'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g. Solve 5 Graph problems, Revise OS notes',
                    prefixIcon:
                        Icon(Icons.task, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Additional details or steps to complete...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Category & Priority
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        dropdownColor: AppColors.secondaryBackground,
                        style: const TextStyle(
                            color: AppColors.primaryText, fontSize: 12.5),
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category,
                              size: 18, color: AppColors.mutedText),
                        ),
                        items: AppStrings.taskCategories.map((c) {
                          return DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _category = v;
                              if (v == 'Call / Meeting' && !_setReminder) {
                                _setReminder = true;
                                _earlyReminderMinutes = 15;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priority,
                        dropdownColor: AppColors.secondaryBackground,
                        style: const TextStyle(
                            color: AppColors.primaryText, fontSize: 12.5),
                        decoration: const InputDecoration(
                          labelText: 'Priority *',
                          prefixIcon: Icon(Icons.flag,
                              size: 18, color: AppColors.mutedText),
                        ),
                        items: AppStrings.taskPriorities.map((p) {
                          return DropdownMenuItem(value: p, child: Text(p));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Due Date & Time
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: Text(
                          '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _dueDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 15),
                        label: Text(
                          _dueTime.format(context),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _dueTime,
                          );
                          if (picked != null) setState(() => _dueTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Early Reminder Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _setReminder
                          ? AppColors.primaryPurple.withValues(alpha: 0.4)
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _category == 'Call / Meeting'
                                    ? Icons.phone_in_talk_rounded
                                    : Icons.notifications_active_outlined,
                                size: 18,
                                color: _setReminder
                                    ? AppColors.lightPurple
                                    : AppColors.mutedText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _category == 'Call / Meeting'
                                    ? 'Call / Meeting Reminder'
                                    : 'Early Notification Reminder',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _setReminder,
                            activeColor: AppColors.brightAccent,
                            onChanged: (v) async {
                              if (v) {
                                await NotificationService.instance.requestPermissions();
                                final fullDue = DateTime(
                                  _dueDate.year,
                                  _dueDate.month,
                                  _dueDate.day,
                                  _dueTime.hour,
                                  _dueTime.minute,
                                );
                                final alertAt = fullDue.subtract(
                                    Duration(minutes: _earlyReminderMinutes));
                                if (alertAt.isBefore(DateTime.now())) {
                                  final futureTime =
                                      DateTime.now().add(const Duration(hours: 1));
                                  _dueDate = DateTime(
                                      futureTime.year, futureTime.month, futureTime.day);
                                  _dueTime = TimeOfDay(
                                      hour: futureTime.hour, minute: futureTime.minute);
                                }
                              }
                              setState(() => _setReminder = v);
                            },
                          ),
                        ],
                      ),
                      if (_setReminder) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Remind me ahead of time:',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _earlyReminderMinutes,
                          dropdownColor: AppColors.secondaryBackground,
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 13),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            prefixIcon: const Icon(Icons.timer_outlined,
                                size: 18, color: AppColors.lightPurple),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 0, child: Text('At due time (0 mins)')),
                            DropdownMenuItem(
                                value: 5, child: Text('5 minutes early')),
                            DropdownMenuItem(
                                value: 10, child: Text('10 minutes early')),
                            DropdownMenuItem(
                                value: 15,
                                child: Text('15 minutes early (Recommended)')),
                            DropdownMenuItem(
                                value: 30, child: Text('30 minutes early')),
                            DropdownMenuItem(
                                value: 60, child: Text('1 hour early')),
                            DropdownMenuItem(
                                value: 1440, child: Text('1 day early')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _earlyReminderMinutes = val);
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final fullDue = DateTime(
                              _dueDate.year,
                              _dueDate.month,
                              _dueDate.day,
                              _dueTime.hour,
                              _dueTime.minute,
                            );
                            final alertAt = fullDue.subtract(
                                Duration(minutes: _earlyReminderMinutes));
                            final isPast = alertAt.isBefore(DateTime.now());
                            return Text(
                              isPast
                                  ? '⚠️ Notice: Reminder time is in the past'
                                  : '⏰ Alert scheduled for ${DateFormat('MMM d, h:mm a').format(alertAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isPast
                                    ? Colors.amberAccent
                                    : AppColors.lightPurple,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(isEditing ? 'Save Changes' : 'Create Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final fullDueDate = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final earlyMins = _setReminder ? _earlyReminderMinutes : null;
    if (_setReminder && earlyMins != null) {
      final alertAt = fullDueDate.subtract(Duration(minutes: earlyMins));
      if (alertAt.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '⚠️ Reminder time is in the past. Please choose a future time or turn off reminder.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    final reminderDate = _setReminder
        ? fullDueDate.subtract(Duration(minutes: earlyMins!)).toIso8601String()
        : null;

    final task = TaskModel(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: fullDueDate.toIso8601String(),
      reminderDateTime: reminderDate,
      earlyReminderMinutes: earlyMins,
      isCompleted: widget.task?.isCompleted ?? false,
      completedAt: widget.task?.completedAt,
      creationDate: widget.task?.creationDate,
    );

    if (widget.task == null) {
      DraftService.instance.clearDraft('add_task');
    }
    Navigator.of(context).pop(task);
  }
}
