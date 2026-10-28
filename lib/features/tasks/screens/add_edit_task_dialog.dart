import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/task_model.dart';

class AddEditTaskDialog extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskDialog({super.key, this.task});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _category;
  late String _priority;
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = const TimeOfDay(hour: 18, minute: 0);
  bool _setReminder = false;

  @override
  void initState() {
    super.initState();
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
    }
    _setReminder =
        t?.reminderDateTime != null && t!.reminderDateTime!.isNotEmpty;
  }

  @override
  void dispose() {
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
                    Text(
                      isEditing ? 'Edit Task' : 'New Task',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          if (v != null) setState(() => _category = v);
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
                const SizedBox(height: 10),

                // Reminder Checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Schedule task notification reminder',
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 13)),
                  value: _setReminder,
                  activeColor: AppColors.brightAccent,
                  onChanged: (v) => setState(() => _setReminder = v ?? false),
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

    final task = TaskModel(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: fullDueDate.toIso8601String(),
      reminderDateTime: _setReminder ? fullDueDate.toIso8601String() : null,
      isCompleted: widget.task?.isCompleted ?? false,
      completedAt: widget.task?.completedAt,
      creationDate: widget.task?.creationDate,
    );

    Navigator.of(context).pop(task);
  }
}
