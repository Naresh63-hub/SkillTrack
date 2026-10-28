import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/interview_question.dart';

class AddEditInterviewQDialog extends StatefulWidget {
  final InterviewQuestion? question;

  const AddEditInterviewQDialog({super.key, this.question});

  @override
  State<AddEditInterviewQDialog> createState() =>
      _AddEditInterviewQDialogState();
}

class _AddEditInterviewQDialogState extends State<AddEditInterviewQDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _answerController;
  late String _category;
  late String _status;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionController = TextEditingController(text: q?.question ?? '');
    _answerController = TextEditingController(text: q?.answer ?? '');
    _category = q?.category ?? AppStrings.interviewCategories.first;
    _status = q?.status ?? 'Not Started';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;

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
                      isEditing
                          ? 'Edit Interview QA'
                          : 'New Interview Question',
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

                // Category & Status
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        dropdownColor: AppColors.secondaryBackground,
                        style: const TextStyle(
                            color: AppColors.primaryText, fontSize: 13),
                        decoration:
                            const InputDecoration(labelText: 'Category *'),
                        items: AppStrings.interviewCategories.map((c) {
                          return DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _category = v);
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
                const SizedBox(height: 14),

                // Question
                TextFormField(
                  controller: _questionController,
                  validator: (v) =>
                      Validators.requiredField(v, 'Question text'),
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Interview Question *',
                    hintText:
                        'e.g. Tell me about yourself, What is Polymorphism?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),

                // Answer / Talking Points
                TextFormField(
                  controller: _answerController,
                  maxLines: 5,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Your Prepared Answer / STAR Points',
                    hintText: 'Structure: Situation, Task, Action, Result...',
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
                      onPressed: _saveQuestion,
                      child: Text(isEditing ? 'Save Changes' : 'Add Question'),
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

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) return;

    final q = InterviewQuestion(
      id: widget.question?.id,
      category: _category,
      question: _questionController.text.trim(),
      answer: _answerController.text.trim().isEmpty
          ? null
          : _answerController.text.trim(),
      status: _status,
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(q);
  }
}
