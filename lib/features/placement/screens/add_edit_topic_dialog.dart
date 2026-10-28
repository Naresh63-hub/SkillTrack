import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/placement_topic.dart';

class AddEditTopicDialog extends StatefulWidget {
  final String track; // 'Coding', 'CoreCS', 'Aptitude'
  final PlacementTopic? topic;

  const AddEditTopicDialog({super.key, required this.track, this.topic});

  @override
  State<AddEditTopicDialog> createState() => _AddEditTopicDialogState();
}

class _AddEditTopicDialogState extends State<AddEditTopicDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _solvedController;
  late TextEditingController _attemptedController;
  late TextEditingController _linksController;
  late TextEditingController _notesController;
  late String _difficulty;
  late String _status;

  @override
  void initState() {
    super.initState();
    final t = widget.topic;
    _nameController = TextEditingController(text: t?.topicName ?? '');
    _solvedController =
        TextEditingController(text: (t?.problemsSolved ?? 0).toString());
    _attemptedController =
        TextEditingController(text: (t?.problemsAttempted ?? 0).toString());
    _linksController = TextEditingController(text: t?.practiceLinks ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _difficulty = t?.difficultyLevel ??
        (widget.track == 'CoreCS' ? 'Comprehensive' : 'Medium');
    _status = t?.completionStatus ?? 'Not Started';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _solvedController.dispose();
    _attemptedController.dispose();
    _linksController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.topic != null;

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
                      isEditing ? 'Edit Topic' : 'Add ${widget.track} Topic',
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

                // Topic Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) => Validators.requiredField(v, 'Topic name'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Topic Name *',
                    hintText:
                        'e.g. Dynamic Programming, Normalization, Syllogisms',
                    prefixIcon: Icon(Icons.menu_book,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Solved & Attempted Counters
                if (widget.track == 'Coding' || widget.track == 'Aptitude') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _solvedController,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              Validators.positiveInteger(v, 'Problems solved'),
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Problems Solved',
                            prefixIcon: Icon(Icons.check_circle,
                                size: 18, color: AppColors.success),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _attemptedController,
                          keyboardType: TextInputType.number,
                          validator: (v) => Validators.positiveInteger(
                              v, 'Problems attempted'),
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Total Attempted',
                            prefixIcon: Icon(Icons.play_arrow,
                                size: 18, color: AppColors.info),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Difficulty & Status
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _difficulty,
                        dropdownColor: AppColors.secondaryBackground,
                        style: const TextStyle(
                            color: AppColors.primaryText, fontSize: 13),
                        decoration:
                            const InputDecoration(labelText: 'Difficulty'),
                        items: const [
                          DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                          DropdownMenuItem(
                              value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                          DropdownMenuItem(
                              value: 'Comprehensive',
                              child: Text('Comprehensive')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _difficulty = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        dropdownColor: AppColors.secondaryBackground,
                        style: const TextStyle(
                            color: AppColors.primaryText, fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: AppStrings.itemStatuses.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Practice Link
                TextFormField(
                  controller: _linksController,
                  validator: Validators.optionalUrl,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Practice URL (Optional)',
                    hintText: 'https://leetcode.com/tag/dynamic-programming',
                    prefixIcon:
                        Icon(Icons.link, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Revision Notes & Key Formulas',
                    hintText:
                        'Time complexities, edge cases, formulas to remember...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveTopic,
                      child: Text(isEditing ? 'Save Changes' : 'Add Topic'),
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

  void _saveTopic() {
    if (!_formKey.currentState!.validate()) return;

    final solved = int.tryParse(_solvedController.text.trim()) ?? 0;
    final attempted = int.tryParse(_attemptedController.text.trim()) ?? 0;

    final topic = PlacementTopic(
      id: widget.topic?.id,
      track: widget.track,
      topicName: _nameController.text.trim(),
      category: widget.track,
      problemsSolved: solved,
      problemsAttempted: attempted > solved ? attempted : solved,
      practiceLinks: _linksController.text.trim().isEmpty
          ? null
          : _linksController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      difficultyLevel: _difficulty,
      completionStatus: _status,
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(topic);
  }
}
