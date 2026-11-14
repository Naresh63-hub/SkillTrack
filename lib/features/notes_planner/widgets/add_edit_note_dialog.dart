import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/note_model.dart';
import '../../../models/skill.dart';
import '../../../repositories/skills_repository.dart';

class AddEditNoteDialog extends StatefulWidget {
  final NoteModel? note;
  final String? preselectedSkillName;
  final List<Skill>? availableSkills;

  const AddEditNoteDialog({
    super.key,
    this.note,
    this.preselectedSkillName,
    this.availableSkills,
  });

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final SkillsRepository _skillsRepo = SkillsRepository();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  late String _selectedColorTag;
  String? _selectedSkillName;
  late bool _isPinned;

  List<Skill> _availableSkills = [];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _selectedCategory = note?.category ?? NoteModel.categories.first;
    _selectedColorTag = note?.colorTag ?? 'purple';
    _selectedSkillName = note?.linkedSkillName ?? widget.preselectedSkillName;
    _isPinned = note?.isPinned ?? false;

    if (widget.availableSkills != null) {
      _availableSkills = widget.availableSkills!;
    } else {
      _loadSkills();
    }
  }

  Future<void> _loadSkills() async {
    final skills = await _skillsRepo.getAllSkills();
    if (mounted) {
      setState(() {
        _availableSkills = skills;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Color _resolveTagColor(String tag) {
    switch (tag) {
      case 'blue':
        return const Color(0xFF38BDF8);
      case 'emerald':
        return const Color(0xFF34D399);
      case 'amber':
        return const Color(0xFFFBBF24);
      case 'rose':
        return const Color(0xFFFB7185);
      case 'purple':
      default:
        return AppColors.primaryPurple;
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final updated = NoteModel(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      linkedSkillName:
          _selectedSkillName != null && _selectedSkillName!.isNotEmpty
              ? _selectedSkillName
              : null,
      isPinned: _isPinned,
      colorTag: _selectedColorTag,
      createdAt: widget.note?.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: SizedBox(
        width: 580,
        height: 620,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _resolveTagColor(_selectedColorTag)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _resolveTagColor(_selectedColorTag)
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.note_alt_rounded,
                            color: _resolveTagColor(_selectedColorTag),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditing ? 'Edit Note / Cheatsheet' : 'Add Note / Cheatsheet',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.mutedText, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                              color: AppColors.primaryText, fontSize: 14),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter note title'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Title *',
                            hintText:
                                'e.g., Sliding Window DSA Pattern, OS Paging notes...',
                            labelStyle:
                                const TextStyle(color: AppColors.secondaryText),
                            filled: true,
                            fillColor: AppColors.secondaryCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Category & Linked Skill row
                        Row(
                          children: [
                            // Category
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                dropdownColor: AppColors.secondaryCard,
                                style: const TextStyle(
                                    color: AppColors.primaryText, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  labelStyle: const TextStyle(
                                      color: AppColors.secondaryText),
                                  filled: true,
                                  fillColor: AppColors.secondaryCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                                items: NoteModel.categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Linked Skill
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedSkillName,
                                isExpanded: true,
                                dropdownColor: AppColors.secondaryCard,
                                style: const TextStyle(
                                    color: AppColors.primaryText, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Linked Skill (Optional)',
                                  labelStyle: const TextStyle(
                                      color: AppColors.secondaryText),
                                  filled: true,
                                  fillColor: AppColors.secondaryCard,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('None (General Note)'),
                                  ),
                                  if (_selectedSkillName != null &&
                                      !_availableSkills.any((s) =>
                                          s.name == _selectedSkillName))
                                    DropdownMenuItem<String?>(
                                      value: _selectedSkillName,
                                      child: Text(
                                        _selectedSkillName!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ..._availableSkills.map((s) {
                                    return DropdownMenuItem<String?>(
                                      value: s.name,
                                      child: Text(
                                        s.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedSkillName = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Color Tag & Pin Toggle row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Color dots
                            Row(
                              children: [
                                const Text(
                                  'Color: ',
                                  style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                ...NoteModel.colorTags.map((tag) {
                                  final isSelected = _selectedColorTag == tag;
                                  final color = _resolveTagColor(tag);
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedColorTag = tag),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withValues(
                                                      alpha: 0.5),
                                                  blurRadius: 6,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),

                            // Pin toggle
                            InkWell(
                              onTap: () =>
                                  setState(() => _isPinned = !_isPinned),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      size: 16,
                                      color: _isPinned
                                          ? AppColors.lightPurple
                                          : AppColors.mutedText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pin to Top',
                                      style: TextStyle(
                                        color: _isPinned
                                            ? AppColors.lightPurple
                                            : AppColors.mutedText,
                                        fontSize: 12,
                                        fontWeight: _isPinned
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Content (Markdown / Code / Text)
                        TextFormField(
                          controller: _contentController,
                          maxLines: 12,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13.5,
                            fontFamily: 'monospace',
                            height: 1.45,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter note content'
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Note Content & Code Snippets *',
                            alignLabelWithHint: true,
                            hintText:
                                'Write algorithms, syntax, formula, interview answers, or revision cheat sheet here...',
                            labelStyle:
                                const TextStyle(color: AppColors.secondaryText),
                            filled: true,
                            fillColor: AppColors.secondaryCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondaryText),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        isEditing ? 'Save Changes' : 'Create Note',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
}
