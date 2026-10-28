import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/skill.dart';

class AddEditSkillDialog extends StatefulWidget {
  final Skill? skill;

  const AddEditSkillDialog({super.key, this.skill});

  @override
  State<AddEditSkillDialog> createState() => _AddEditSkillDialogState();
}

class _AddEditSkillDialogState extends State<AddEditSkillDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  late String _category;
  late String _proficiency;
  late double _progress;
  DateTime? _startDate;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final s = widget.skill;
    _nameController = TextEditingController(text: s?.name ?? '');
    _urlController = TextEditingController(text: s?.learningResourceUrl ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _category = s?.category ?? AppStrings.skillCategories.first;
    _proficiency = s?.proficiencyLevel ?? 'Beginner';
    _progress = s?.progressPercentage ?? 0.0;

    if (s?.dateStarted != null && s!.dateStarted!.isNotEmpty) {
      try {
        _startDate = DateTime.parse(s.dateStarted!);
      } catch (_) {}
    }
    if (s?.targetCompletionDate != null &&
        s!.targetCompletionDate!.isNotEmpty) {
      try {
        _targetDate = DateTime.parse(s.targetCompletionDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.skill != null;

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
                      isEditing ? 'Edit Skill' : 'Add New Skill',
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

                // Skill Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) => Validators.requiredField(v, 'Skill name'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Skill Name *',
                    hintText: 'e.g. Flutter, Python, Docker',
                    prefixIcon:
                        Icon(Icons.code, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: AppColors.secondaryBackground,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: Icon(Icons.category,
                        size: 20, color: AppColors.mutedText),
                  ),
                  items: AppStrings.skillCategories.map((cat) {
                    return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 14),

                // Proficiency Level
                DropdownButtonFormField<String>(
                  value: _proficiency,
                  dropdownColor: AppColors.secondaryBackground,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                    prefixIcon:
                        Icon(Icons.stars, size: 20, color: AppColors.mutedText),
                  ),
                  items: AppStrings.proficiencyLevels.map((lvl) {
                    return DropdownMenuItem(value: lvl, child: Text(lvl));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _proficiency = v);
                  },
                ),
                const SizedBox(height: 16),

                // Progress Percentage Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Learning Progress',
                      style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${_progress.toInt()}%',
                      style: const TextStyle(
                          color: AppColors.brightAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: _progress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.brightAccent,
                  inactiveColor: AppColors.surfaceVariant,
                  label: '${_progress.toInt()}%',
                  onChanged: (v) => setState(() => _progress = v),
                ),
                const SizedBox(height: 12),

                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: Text(
                          _startDate == null
                              ? 'Start Date'
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setState(() => _startDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flag, size: 15),
                        label: Text(
                          _targetDate == null
                              ? 'Target Date'
                              : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _targetDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setState(() => _targetDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Learning Resource URL
                TextFormField(
                  controller: _urlController,
                  validator: Validators.optionalUrl,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Resource URL (Optional)',
                    hintText: 'https://docs.flutter.dev',
                    prefixIcon:
                        Icon(Icons.link, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Learning Notes / Objectives',
                    hintText: 'Key concepts to master...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

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
                      onPressed: _saveSkill,
                      child: Text(isEditing ? 'Save Changes' : 'Add Skill'),
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

  void _saveSkill() {
    if (!_formKey.currentState!.validate()) return;

    final skill = Skill(
      id: widget.skill?.id,
      name: _nameController.text.trim(),
      category: _category,
      proficiencyLevel: _proficiency,
      progressPercentage: _progress,
      dateStarted: _startDate?.toIso8601String(),
      targetCompletionDate: _targetDate?.toIso8601String(),
      learningResourceUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.skill?.createdAt,
    );

    Navigator.of(context).pop(skill);
  }
}
