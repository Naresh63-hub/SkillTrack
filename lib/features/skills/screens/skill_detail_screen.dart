import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/skill.dart';
import '../../../repositories/skills_repository.dart';
import 'add_edit_skill_dialog.dart';

class SkillDetailScreen extends StatefulWidget {
  final Skill initialSkill;

  const SkillDetailScreen({super.key, required this.initialSkill});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  late Skill _skill;
  final SkillsRepository _repository = SkillsRepository();

  @override
  void initState() {
    super.initState();
    _skill = widget.initialSkill;
  }

  Future<void> _updateProgress(double newProgress) async {
    final updated = _skill.copyWith(progressPercentage: newProgress);
    setState(() => _skill = updated);
    await _repository.updateSkill(updated);
  }

  Future<void> _editSkill() async {
    final result = await showDialog<Skill>(
      context: context,
      builder: (context) => AddEditSkillDialog(skill: _skill),
    );

    if (result != null) {
      await _repository.updateSkill(result);
      setState(() {
        _skill = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteSkill() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Skill',
      content:
          'Are you sure you want to delete "${_skill.name}"? This action cannot be undone.',
    );

    if (confirmed && mounted) {
      await _repository.deleteSkill(_skill.id!);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true indicating deletion
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open resource link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color proficiencyColor;
    switch (_skill.proficiencyLevel) {
      case 'Expert':
        proficiencyColor = const Color(0xFFC084FC);
        break;
      case 'Advanced':
        proficiencyColor = AppColors.brightAccent;
        break;
      case 'Intermediate':
        proficiencyColor = AppColors.secondaryAccent;
        break;
      case 'Beginner':
      default:
        proficiencyColor = AppColors.info;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_skill.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit Skill',
            onPressed: _editSkill,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            tooltip: 'Delete Skill',
            onPressed: _deleteSkill,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _skill.category,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: proficiencyColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: proficiencyColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _skill.proficiencyLevel,
                          style: TextStyle(
                            color: proficiencyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _skill.name,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar & Slider
                  CustomProgressBar(
                    percentage: _skill.progressPercentage,
                    showLabel: true,
                    labelText: 'Overall Mastery',
                    height: 10,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Update Progress:',
                        style:
                            TextStyle(color: AppColors.mutedText, fontSize: 12),
                      ),
                      Text(
                        '${_skill.progressPercentage.toInt()}%',
                        style: const TextStyle(
                          color: AppColors.brightAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _skill.progressPercentage,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.brightAccent,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (v) => _updateProgress(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dates & Milestones Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline & Milestones',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.mutedText),
                      const SizedBox(width: 8),
                      const Text('Started:',
                          style: TextStyle(
                              color: AppColors.secondaryText, fontSize: 13)),
                      const Spacer(),
                      Text(
                        DateFormatter.format(_skill.dateStarted),
                        style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.flag,
                          size: 16, color: AppColors.mutedText),
                      const SizedBox(width: 8),
                      const Text('Target Completion:',
                          style: TextStyle(
                              color: AppColors.secondaryText, fontSize: 13)),
                      const Spacer(),
                      Text(
                        DateFormatter.format(_skill.targetCompletionDate),
                        style: TextStyle(
                          color: _skill.isOverdue
                              ? AppColors.error
                              : AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_skill.isOverdue) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: AppColors.error, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Target date passed. Goal is currently overdue.',
                            style:
                                TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Learning Resource Card
            if (_skill.learningResourceUrl != null &&
                _skill.learningResourceUrl!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Resource',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchUrl(_skill.learningResourceUrl!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primaryAccent
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_browser,
                                color: AppColors.brightAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _skill.learningResourceUrl!,
                                style: const TextStyle(
                                  color: AppColors.secondaryAccent,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Notes Card
            if (_skill.notes != null && _skill.notes!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes & Key Concepts',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _skill.notes!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
