import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/job_application.dart';

class AddEditApplicationDialog extends StatefulWidget {
  final JobApplication? application;

  const AddEditApplicationDialog({super.key, this.application});

  @override
  State<AddEditApplicationDialog> createState() =>
      _AddEditApplicationDialogState();
}

class _AddEditApplicationDialogState extends State<AddEditApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _urlController;
  late TextEditingController _skillsController;
  late TextEditingController _notesController;
  late String _status;

  DateTime _appDate = DateTime.now();
  DateTime? _deadline;
  DateTime? _interviewDate;

  @override
  void initState() {
    super.initState();
    final a = widget.application;
    _companyController = TextEditingController(text: a?.companyName ?? '');
    _roleController = TextEditingController(text: a?.role ?? '');
    _urlController = TextEditingController(text: a?.jobDescriptionUrl ?? '');
    _skillsController = TextEditingController(text: a?.requiredSkills ?? '');
    _notesController = TextEditingController(text: a?.notes ?? '');
    _status = a?.status ?? 'Applied';

    if (a?.applicationDate != null && a!.applicationDate.isNotEmpty) {
      try {
        _appDate = DateTime.parse(a.applicationDate);
      } catch (_) {}
    }
    if (a?.applicationDeadline != null && a!.applicationDeadline!.isNotEmpty) {
      try {
        _deadline = DateTime.parse(a.applicationDeadline!);
      } catch (_) {}
    }
    if (a?.interviewDate != null && a!.interviewDate!.isNotEmpty) {
      try {
        _interviewDate = DateTime.parse(a.interviewDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _urlController.dispose();
    _skillsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.application != null;

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
                          ? 'Edit Job Application'
                          : 'Track Job Application',
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

                // Company Name
                TextFormField(
                  controller: _companyController,
                  validator: (v) => Validators.requiredField(v, 'Company name'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    hintText: 'e.g. Google, Microsoft, Infosys',
                    prefixIcon: Icon(Icons.business,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Role
                TextFormField(
                  controller: _roleController,
                  validator: (v) => Validators.requiredField(v, 'Role'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Position / Role *',
                    hintText: 'e.g. Software Engineer, Graduate Trainee',
                    prefixIcon: Icon(Icons.work_outline,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Status
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: AppColors.secondaryBackground,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Pipeline Status *',
                    prefixIcon: Icon(Icons.timeline,
                        size: 20, color: AppColors.mutedText),
                  ),
                  items: AppStrings.applicationStatuses.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 12),

                // Dates: Application Date & Deadline
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(
                          'Applied: ${_appDate.day}/${_appDate.month}/${_appDate.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _appDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _appDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.timer, size: 14),
                        label: Text(
                          _deadline == null
                              ? 'Deadline'
                              : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deadline ??
                                DateTime.now().add(const Duration(days: 14)),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setState(() => _deadline = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Interview Date
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42)),
                  icon: const Icon(Icons.event_available, size: 16),
                  label: Text(
                    _interviewDate == null
                        ? 'Set Interview Date (Optional)'
                        : 'Interview Scheduled: ${_interviewDate!.day}/${_interviewDate!.month}/${_interviewDate!.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _interviewDate ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _interviewDate = picked);
                  },
                ),
                const SizedBox(height: 12),

                // JD Link
                TextFormField(
                  controller: _urlController,
                  validator: Validators.optionalUrl,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Job Description URL (Optional)',
                    hintText: 'https://careers.company.com/job/1234',
                    prefixIcon:
                        Icon(Icons.link, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Required Skills
                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13.5),
                  decoration: const InputDecoration(
                    labelText: 'Required Skills / Keywords',
                    hintText: 'e.g. Flutter, Dart, Java, SQL, Problem Solving',
                    prefixIcon: Icon(Icons.psychology,
                        size: 20, color: AppColors.mutedText),
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
                    labelText: 'Interview Round Notes / Package Details',
                    hintText: 'Round 1 technical topics, CTC breakdown...',
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
                      onPressed: _saveApplication,
                      child: Text(
                          isEditing ? 'Save Changes' : 'Track Application'),
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

  void _saveApplication() {
    if (!_formKey.currentState!.validate()) return;

    final app = JobApplication(
      id: widget.application?.id,
      companyName: _companyController.text.trim(),
      role: _roleController.text.trim(),
      applicationDate: _appDate.toIso8601String().split('T').first,
      applicationDeadline: _deadline?.toIso8601String().split('T').first,
      status: _status,
      jobDescriptionUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      requiredSkills: _skillsController.text.trim().isEmpty
          ? null
          : _skillsController.text.trim(),
      interviewDate: _interviewDate?.toIso8601String().split('T').first,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(app);
  }
}
