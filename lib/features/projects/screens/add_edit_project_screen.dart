import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/project.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Project? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _detailedDescController;
  late TextEditingController _techInputController;
  late TextEditingController _githubController;
  late TextEditingController _demoController;
  late TextEditingController _featuresController;
  late TextEditingController _problemsController;
  late TextEditingController _learnedController;
  late TextEditingController _notesController;

  late String _category;
  late String _status;
  List<String> _technologies = [];
  DateTime? _startDate;
  DateTime? _completionDate;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameController = TextEditingController(text: p?.name ?? '');
    _shortDescController =
        TextEditingController(text: p?.shortDescription ?? '');
    _detailedDescController =
        TextEditingController(text: p?.detailedDescription ?? '');
    _techInputController = TextEditingController();
    _githubController = TextEditingController(text: p?.githubUrl ?? '');
    _demoController = TextEditingController(text: p?.liveDemoUrl ?? '');
    _featuresController = TextEditingController(text: p?.keyFeatures ?? '');
    _problemsController = TextEditingController(text: p?.problemsSolved ?? '');
    _learnedController = TextEditingController(text: p?.whatLearned ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    _category = p?.category ?? AppStrings.skillCategories.first;
    _status = p?.status ?? 'In Progress';
    _technologies = p != null ? List<String>.from(p.technologies) : [];

    if (p?.startDate != null && p!.startDate!.isNotEmpty) {
      try {
        _startDate = DateTime.parse(p.startDate!);
      } catch (_) {}
    }
    if (p?.completionDate != null && p!.completionDate!.isNotEmpty) {
      try {
        _completionDate = DateTime.parse(p.completionDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _detailedDescController.dispose();
    _techInputController.dispose();
    _githubController.dispose();
    _demoController.dispose();
    _featuresController.dispose();
    _problemsController.dispose();
    _learnedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addTechnology(String tech) {
    final trimmed = tech.trim();
    if (trimmed.isNotEmpty && !_technologies.contains(trimmed)) {
      setState(() {
        _technologies.add(trimmed);
        _techInputController.clear();
      });
    }
  }

  void _removeTechnology(String tech) {
    setState(() => _technologies.remove(tech));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'New Portfolio Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.brightAccent),
            tooltip: 'Save',
            onPressed: _saveProject,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name
              TextFormField(
                controller: _nameController,
                validator: (v) => Validators.requiredField(v, 'Project name'),
                style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'e.g. SkillTrack, FoodAI',
                  prefixIcon: Icon(Icons.folder, color: AppColors.mutedText),
                ),
              ),
              const SizedBox(height: 14),

              // Short Description
              TextFormField(
                controller: _shortDescController,
                validator: (v) =>
                    Validators.requiredField(v, 'Short description'),
                maxLines: 2,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Short Tagline / Summary *',
                  hintText:
                      'Brief one or two sentence description of the project...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // Category & Status
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppColors.secondaryBackground,
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category,
                            size: 20, color: AppColors.mutedText),
                      ),
                      items: AppStrings.skillCategories.map((c) {
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
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag,
                            size: 20, color: AppColors.mutedText),
                      ),
                      items: AppStrings.projectStatuses.map((s) {
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

              // Technologies Tag Entry
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _techInputController,
                      style: const TextStyle(
                          color: AppColors.primaryText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Technologies Used',
                        hintText:
                            'Type tech (e.g. Flutter, SQLite) & press add',
                        prefixIcon: Icon(Icons.memory,
                            size: 20, color: AppColors.mutedText),
                      ),
                      onSubmitted: _addTechnology,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _addTechnology(_techInputController.text),
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_technologies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _technologies.map((tech) {
                    return Chip(
                      label: Text(tech),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removeTechnology(tech),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),

              // Dates
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
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.task_alt, size: 15),
                      label: Text(
                        _completionDate == null
                            ? 'Completion Date'
                            : '${_completionDate!.day}/${_completionDate!.month}/${_completionDate!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _completionDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null)
                          setState(() => _completionDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // URLs
              TextFormField(
                controller: _githubController,
                validator: Validators.optionalUrl,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'GitHub Repository URL',
                  hintText: 'https://github.com/username/project',
                  prefixIcon:
                      Icon(Icons.code, size: 20, color: AppColors.mutedText),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _demoController,
                validator: Validators.optionalUrl,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Live Demo URL (Optional)',
                  hintText: 'https://project-demo.web.app',
                  prefixIcon:
                      Icon(Icons.launch, size: 20, color: AppColors.mutedText),
                ),
              ),
              const SizedBox(height: 14),

              // Detailed Description
              TextFormField(
                controller: _detailedDescController,
                maxLines: 4,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Detailed Architecture & Overview',
                  hintText:
                      'Architecture, offline storage implementation, performance considerations...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // Key Features
              TextFormField(
                controller: _featuresController,
                maxLines: 3,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Key Features (1 per line)',
                  hintText:
                      '1. Dynamic progress tracking\n2. SQLite schema migrations\n3. ATS resume generation',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // Problems Solved
              TextFormField(
                controller: _problemsController,
                maxLines: 2,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'Problems Solved',
                  hintText:
                      'What challenge did this software address for users?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // What Learned
              TextFormField(
                controller: _learnedController,
                maxLines: 2,
                style: const TextStyle(
                    color: AppColors.primaryText, fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: 'What You Learned',
                  hintText: 'Technical skills and best practices gained...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Create Project'),
                onPressed: _saveProject,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) return;

    final project = Project(
      id: widget.project?.id,
      name: _nameController.text.trim(),
      shortDescription: _shortDescController.text.trim(),
      detailedDescription: _detailedDescController.text.trim().isEmpty
          ? null
          : _detailedDescController.text.trim(),
      category: _category,
      technologies: _technologies,
      status: _status,
      startDate: _startDate?.toIso8601String().split('T').first,
      completionDate: _completionDate?.toIso8601String().split('T').first,
      githubUrl: _githubController.text.trim().isEmpty
          ? null
          : _githubController.text.trim(),
      liveDemoUrl: _demoController.text.trim().isEmpty
          ? null
          : _demoController.text.trim(),
      keyFeatures: _featuresController.text.trim().isEmpty
          ? null
          : _featuresController.text.trim(),
      problemsSolved: _problemsController.text.trim().isEmpty
          ? null
          : _problemsController.text.trim(),
      whatLearned: _learnedController.text.trim().isEmpty
          ? null
          : _learnedController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.project?.createdAt,
    );

    Navigator.of(context).pop(project);
  }
}
