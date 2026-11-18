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
import 'career_roadmaps_screen.dart';
import '../../notes_planner/screens/notes_planner_hub_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => SkillsScreenState();
}

class SkillsScreenState extends State<SkillsScreen> {
  final SkillsRepository _repository = SkillsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Skill> _skills = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _sortBy = 'level_asc';

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  void reload() {
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

  Future<void> _openRoadmaps() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CareerRoadmapsScreen()),
    );
    if (result == true || mounted) {
      _loadSkills();
    }
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotesPlannerHubScreen(initialTabIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_alt_outlined, size: 21),
            tooltip: 'Notes & Cheatsheets',
            onPressed: _openNotes,
          ),
          IconButton(
            icon: const Icon(Icons.alt_route_rounded, size: 22),
            tooltip: 'Role Roadmaps',
            onPressed: _openRoadmaps,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, size: 20),
            tooltip: 'Sort By',
            color: AppColors.secondaryBackground,
            initialValue: _sortBy,
            onSelected: (val) {
              setState(() => _sortBy = val);
              _loadSkills();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'level_asc',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'level_asc'
                          ? Icons.check_circle_rounded
                          : Icons.stairs_rounded,
                      size: 18,
                      color: _sortBy == 'level_asc'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level (Beginner → Intermediate)',
                      style: TextStyle(
                        color: _sortBy == 'level_asc'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'level_asc'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'level_desc',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'level_desc'
                          ? Icons.check_circle_rounded
                          : Icons.military_tech_rounded,
                      size: 18,
                      color: _sortBy == 'level_desc'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level (Advanced → Beginner)',
                      style: TextStyle(
                        color: _sortBy == 'level_desc'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'level_desc'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'progress_desc',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'progress_desc'
                          ? Icons.check_circle_rounded
                          : Icons.trending_up_rounded,
                      size: 18,
                      color: _sortBy == 'progress_desc'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Highest Progress',
                      style: TextStyle(
                        color: _sortBy == 'progress_desc'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'progress_desc'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'progress_asc',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'progress_asc'
                          ? Icons.check_circle_rounded
                          : Icons.trending_down_rounded,
                      size: 18,
                      color: _sortBy == 'progress_asc'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lowest Progress',
                      style: TextStyle(
                        color: _sortBy == 'progress_asc'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'progress_asc'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name_asc'
                          ? Icons.check_circle_rounded
                          : Icons.sort_by_alpha_rounded,
                      size: 18,
                      color: _sortBy == 'name_asc'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Name (A-Z)',
                      style: TextStyle(
                        color: _sortBy == 'name_asc'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'name_asc'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'target_date',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'target_date'
                          ? Icons.check_circle_rounded
                          : Icons.calendar_today_rounded,
                      size: 18,
                      color: _sortBy == 'target_date'
                          ? AppColors.brightAccent
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Target Date',
                      style: TextStyle(
                        color: _sortBy == 'target_date'
                            ? AppColors.brightAccent
                            : AppColors.primaryText,
                        fontWeight: _sortBy == 'target_date'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
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
          // Career Roadmaps Discovery Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: InkWell(
              onTap: _openRoadmaps,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Role Roadmaps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Explore career-based skill roadmaps',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),

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
        selectedColor: AppColors.primaryPurple,
        backgroundColor: AppColors.cardBackground,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.secondaryText,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primaryPurple : AppColors.border,
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
    Color profBg;
    switch (skill.proficiencyLevel) {
      case 'Expert':
        profColor = const Color(0xFFD97706);
        profBg = const Color(0xFFFEF3C7);
        break;
      case 'Advanced':
        profColor = AppColors.brightAccent;
        profBg = const Color(0xFFEDE9FE);
        break;
      case 'Intermediate':
        profColor = const Color(0xFF2563EB);
        profBg = const Color(0xFFDBEAFE);
        break;
      case 'Beginner':
      default:
        profColor = const Color(0xFF059669);
        profBg = const Color(0xFFD1FAE5);
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: profBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: profColor.withValues(alpha: 0.35), width: 0.8),
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
