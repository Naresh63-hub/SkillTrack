import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/skill.dart';
import '../../../repositories/skills_repository.dart';
import 'add_edit_skill_dialog.dart';
import 'skill_detail_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final SkillsRepository _repository = SkillsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Skill> _skills = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _sortBy = 'progress_desc';

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() => _isLoading = true);
    final results = await _repository.getAllSkills(
      category: _selectedCategory,
      searchQuery: _searchController.text,
      sortBy: _sortBy,
    );
    setState(() {
      _skills = results;
      _isLoading = false;
    });
  }

  Future<void> _addSkill() async {
    final newSkill = await showDialog<Skill>(
      context: context,
      builder: (context) => const AddEditSkillDialog(),
    );

    if (newSkill != null) {
      await _repository.addSkill(newSkill);
      _loadSkills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill added successfully')),
        );
      }
    }
  }

  Future<void> _editSkill(Skill skill) async {
    final updated = await showDialog<Skill>(
      context: context,
      builder: (context) => AddEditSkillDialog(skill: skill),
    );

    if (updated != null) {
      await _repository.updateSkill(updated);
      _loadSkills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteSkill(Skill skill) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Skill',
      content: 'Are you sure you want to delete "${skill.name}"?',
    );

    if (confirmed) {
      await _repository.deleteSkill(skill.id!);
      _loadSkills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Skills'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, size: 20),
            tooltip: 'Sort By',
            color: AppColors.secondaryBackground,
            onSelected: (val) {
              setState(() => _sortBy = val);
              _loadSkills();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'progress_desc',
                child: Text('Highest Progress',
                    style: TextStyle(color: AppColors.primaryText)),
              ),
              const PopupMenuItem(
                value: 'progress_asc',
                child: Text('Lowest Progress',
                    style: TextStyle(color: AppColors.primaryText)),
              ),
              const PopupMenuItem(
                value: 'name_asc',
                child: Text('Name (A-Z)',
                    style: TextStyle(color: AppColors.primaryText)),
              ),
              const PopupMenuItem(
                value: 'target_date',
                child: Text('Target Date',
                    style: TextStyle(color: AppColors.primaryText)),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        onPressed: _addSkill,
        tooltip: 'Add Skill',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Search skills or notes...',
              onChanged: (_) => _loadSkills(),
            ),
          ),

          // Categories horizontally scrollable chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All'),
                ...AppStrings.skillCategories.map((c) => _buildCategoryChip(c)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brightAccent))
                : _skills.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.code_off,
                        title: _searchController.text.isNotEmpty ||
                                _selectedCategory != 'All'
                            ? 'No Matching Skills Found'
                            : 'No Technical Skills Yet',
                        description: _searchController.text.isNotEmpty ||
                                _selectedCategory != 'All'
                            ? 'Try adjusting your search query or category filter.'
                            : 'Track the programming languages, frameworks, and CS fundamentals you are learning.',
                        actionLabel: 'Add Skill',
                        onAction: _addSkill,
                      )
                    : RefreshIndicator(
                        color: AppColors.brightAccent,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: _loadSkills,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _skills.length,
                          itemBuilder: (context, index) {
                            final skill = _skills[index];
                            return _buildSkillCard(skill);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        selectedColor: AppColors.elevatedSurface,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.brightAccent : AppColors.secondaryText,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.brightAccent : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _loadSkills();
        },
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    Color profColor;
    switch (skill.proficiencyLevel) {
      case 'Expert':
        profColor = const Color(0xFFC084FC);
        break;
      case 'Advanced':
        profColor = AppColors.brightAccent;
        break;
      case 'Intermediate':
        profColor = AppColors.secondaryAccent;
        break;
      case 'Beginner':
      default:
        profColor = AppColors.info;
        break;
    }

    return CustomCard(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SkillDetailScreen(initialSkill: skill),
          ),
        );
        if (result == true || result != null) {
          _loadSkills();
        }
      },
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  skill.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: profColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: profColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  skill.proficiencyLevel,
                  style: TextStyle(
                    color: profColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.mutedText),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.secondaryBackground,
                onSelected: (action) {
                  if (action == 'edit') {
                    _editSkill(skill);
                  } else if (action == 'delete') {
                    _deleteSkill(skill);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: 16, color: AppColors.secondaryText),
                        SizedBox(width: 8),
                        Text('Edit',
                            style: TextStyle(
                                color: AppColors.primaryText, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            skill.category,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          CustomProgressBar(
            percentage: skill.progressPercentage,
            showLabel: true,
            height: 7,
          ),
          if (skill.isOverdue) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  'Target date passed',
                  style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
