import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/learning_goal.dart';

class AddEditGoalDialog extends StatefulWidget {
  final LearningGoal? goal;

  const AddEditGoalDialog({super.key, this.goal});

  @override
  State<AddEditGoalDialog> createState() => _AddEditGoalDialogState();
}

class _AddEditGoalDialogState extends State<AddEditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetCountController;
  late String _goalType;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _targetCountController =
        TextEditingController(text: (g?.targetCount ?? 5).toString());
    _goalType = g?.goalType ?? 'Daily';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Goal' : 'New Learning Goal',
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
              TextFormField(
                controller: _titleController,
                validator: (v) => Validators.requiredField(v, 'Goal title'),
                style:
                    const TextStyle(color: AppColors.primaryText, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Goal Title *',
                  hintText:
                      'e.g. Solve 5 DSA problems, Study Python for 1 hour',
                  prefixIcon:
                      Icon(Icons.flag, size: 20, color: AppColors.mutedText),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _goalType,
                      dropdownColor: AppColors.secondaryBackground,
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Cadence',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Daily', child: Text('Daily Goal')),
                        DropdownMenuItem(
                            value: 'Weekly', child: Text('Weekly Goal')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _goalType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _targetCountController,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInteger(v, 'Target count'),
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Target Count',
                        hintText: 'e.g. 5',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    child: Text(isEditing ? 'Save Changes' : 'Add Goal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGoal() {
    if (!_formKey.currentState!.validate()) return;

    final target = int.tryParse(_targetCountController.text.trim()) ?? 1;
    final goal = LearningGoal(
      id: widget.goal?.id,
      title: _titleController.text.trim(),
      goalType: _goalType,
      targetCount: target,
      currentCount: widget.goal?.currentCount ?? 0,
      isCompleted: widget.goal?.isCompleted ?? false,
      createdAt: widget.goal?.createdAt,
    );

    Navigator.of(context).pop(goal);
  }
}
