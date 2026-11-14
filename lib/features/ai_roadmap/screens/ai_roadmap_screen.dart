import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/ai_roadmap.dart';
import '../../../repositories/ai_roadmap_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/ai_roadmap_service.dart';

class AiRoadmapScreen extends StatefulWidget {
  final String? initialRole;

  const AiRoadmapScreen({super.key, this.initialRole});

  @override
  State<AiRoadmapScreen> createState() => _AiRoadmapScreenState();
}

class _AiRoadmapScreenState extends State<AiRoadmapScreen> {
  final AiRoadmapService _service = AiRoadmapService();
  final AiRoadmapRepository _repository = AiRoadmapRepository();
  final ProfileRepository _profileRepo = ProfileRepository();

  AiRoadmap? _roadmap;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _showWeeklySchedule = false;
  String _selectedRole = 'Flutter Developer';
  String _selectedTierFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    final profile = await _profileRepo.getProfile();
    final preferredRole = widget.initialRole ??
        (profile.targetJobRole.trim().isNotEmpty
            ? profile.targetJobRole.trim()
            : 'Flutter Developer');

    _selectedRole = preferredRole;
    var roadmap = await _repository.getRoadmapByRole(_selectedRole);
    roadmap ??= await _service.generateRoadmap(targetRole: _selectedRole);

    if (mounted) {
      setState(() {
        _roadmap = roadmap;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchRole(String newRole) async {
    if (newRole == _selectedRole && _roadmap != null) return;
    setState(() {
      _selectedRole = newRole;
      _isLoading = true;
    });

    var roadmap = await _repository.getRoadmapByRole(newRole);
    roadmap ??= await _service.generateRoadmap(targetRole: newRole);

    if (mounted) {
      setState(() {
        _roadmap = roadmap;
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateRoadmap() async {
    setState(() => _isGenerating = true);
    try {
      final updated = await _service.generateRoadmap(targetRole: _selectedRole);
      if (mounted) {
        setState(() {
          _roadmap = updated;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AI Roadmap for "$_selectedRole" refreshed with latest progress!'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating roadmap: $e')),
        );
      }
    }
  }

  Future<void> _toggleNodeCompletion(AiRoadmapNode node) async {
    if (node.id == null) return;
    final newStatus = !node.isCompleted;
    await _repository.toggleNodeCompletion(node.id!, newStatus);

    // Refresh roadmap state
    final refreshed = await _repository.getRoadmapByRole(_selectedRole);
    if (mounted) {
      setState(() {
        _roadmap = refreshed;
      });
    }
  }

  Future<void> _addNodeToTasks(AiRoadmapNode node) async {
    try {
      await _service.convertNodeToTask(node);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${node.topicTitle}" to your Tasks!'),
            backgroundColor: AppColors.primaryPurple,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create task: $e')),
        );
      }
    }
  }

  Future<void> _openResourceUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open documentation: $url')),
          );
        }
      }
    }
  }

  void _showRoleSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_rounded,
                        color: AppColors.primaryPurple, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Select Target Career Goal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose the role you want AI to generate a personalized skill path for:',
                  style:
                      TextStyle(color: AppColors.secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: AiRoadmapService.supportedRoles.map((role) {
                      final isSelected = role == _selectedRole;
                      return ListTile(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _switchRole(role);
                        },
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryPurple
                              : AppColors.mutedText,
                        ),
                        title: Text(
                          role,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.primaryText,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        tileColor: isSelected
                            ? AppColors.secondaryCard
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = _roadmap;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('AI Learning Roadmap'),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primaryPurple),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Regenerate Roadmap with AI',
            onPressed: _isGenerating ? null : _regenerateRoadmap,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Change Career Goal',
            onPressed: _showRoleSelectionDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : roadmap == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Header & Selector Pill
                      _buildRoleHeader(),
                      const SizedBox(height: 14),

                      // Overall Progress Card
                      _buildProgressHeroCard(roadmap),
                      const SizedBox(height: 14),

                      // Skill Gaps Analysis Banner
                      if (roadmap.skillGaps.isNotEmpty) ...[
                        _buildSkillGapsCard(roadmap.skillGaps),
                        const SizedBox(height: 14),
                      ],

                      // View Mode Toggle
                      _buildViewModeToggle(),
                      const SizedBox(height: 14),

                      if (!_showWeeklySchedule) ...[
                        // Level Filter Tabs
                        _buildTierFilterChips(),
                        const SizedBox(height: 14),

                        // Roadmap Milestone Nodes
                        _buildNodesList(roadmap),
                      ] else ...[
                        // Structured 4-Week Daily & Weekly Schedule
                        _buildWeeklyScheduleList(roadmap),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildRoleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Career Goal',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _selectedRole,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _showRoleSelectionDialog,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
          label: const Text('Change Goal', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildProgressHeroCard(AiRoadmap roadmap) {
    final completedCount = roadmap.nodes.where((n) => n.isCompleted).length;
    final totalCount = roadmap.nodes.length;
    final progressPct = roadmap.overallProgress.clamp(0.0, 100.0);

    return CustomCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.route_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Roadmap Completion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount of $totalCount Done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progressPct / 100.0,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    Center(
                      child: Text(
                        '${progressPct.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  roadmap.summary,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roadmap.isAiGenerated
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roadmap.isAiGenerated
                          ? Icons.auto_awesome
                          : Icons.offline_bolt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      roadmap.isAiGenerated
                          ? 'Gemini Live AI Generated'
                          : 'Curated Offline Engine',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGapsCard(List<String> gaps) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFD97706), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Identified Skill Gaps',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${gaps.length} areas to build',
                style:
                    const TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Based on your current skill profile, prioritize these topics to achieve placement readiness:',
            style: TextStyle(
                color: AppColors.secondaryText, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: gaps.map((gap) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 12, color: AppColors.primaryPurple),
                    const SizedBox(width: 4),
                    Text(
                      gap,
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeeklySchedule = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showWeeklySchedule
                      ? AppColors.cardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_showWeeklySchedule
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 16,
                      color: !_showWeeklySchedule
                          ? AppColors.primaryPurple
                          : AppColors.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Curriculum Tiers',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: !_showWeeklySchedule
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: !_showWeeklySchedule
                            ? AppColors.primaryPurple
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeeklySchedule = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showWeeklySchedule
                      ? AppColors.cardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _showWeeklySchedule
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: _showWeeklySchedule
                          ? AppColors.primaryPurple
                          : AppColors.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '4-Week Schedule',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _showWeeklySchedule
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _showWeeklySchedule
                            ? AppColors.primaryPurple
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleList(AiRoadmap roadmap) {
    final weeklyPlan = _service.organizeWeeklySchedule(roadmap.nodes);

    if (weeklyPlan.isEmpty) {
      return const Center(
        child: Text(
          'No scheduled targets available.',
          style: TextStyle(color: AppColors.mutedText),
        ),
      );
    }

    return Column(
      children: weeklyPlan.map((week) {
        final weekNodes = week['nodes'] as List<AiRoadmapNode>;
        final completed = weekNodes.where((n) => n.isCompleted).length;
        final total = weekNodes.length;
        final weekPct = total > 0 ? (completed / total) : 0.0;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          week['targetDays'] as String,
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Week ${week['week']}',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$completed / $total Done',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                week['title'] as String,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: weekPct,
                  minHeight: 5,
                  backgroundColor: AppColors.progressTrack,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(height: 14),
              ...weekNodes.asMap().entries.map((entry) {
                final idx = entry.key;
                final node = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: node.isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.05)
                          : AppColors.secondaryCard.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: node.isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _toggleNodeCompletion(node),
                          borderRadius: BorderRadius.circular(6),
                          child: Icon(
                            node.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: node.isCompleted
                                ? const Color(0xFF10B981)
                                : AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.topicTitle,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: node.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Day ${idx * 2 + 1}-${idx * 2 + 2} • ${node.category} • ${node.estimatedDays} days',
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_task_rounded,
                              size: 18, color: AppColors.primaryPurple),
                          tooltip: 'Add to Tasks',
                          onPressed: () => _addNodeToTasks(node),
                        ),
                        if (node.resourceUrl.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 16, color: AppColors.secondaryText),
                            tooltip: 'Open Guide',
                            onPressed: () => _openResourceUrl(node.resourceUrl),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTierFilterChips() {
    final tiers = ['All', 'Beginner', 'Intermediate', 'Advanced'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tiers.map((tier) {
          final isSelected = _selectedTierFilter == tier;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tier == 'All' ? 'All Milestones' : '$tier Tier'),
              selected: isSelected,
              selectedColor: AppColors.primaryPurple,
              backgroundColor: AppColors.cardBackground,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primaryPurple : AppColors.border,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedTierFilter = tier);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNodesList(AiRoadmap roadmap) {
    final filteredNodes = _selectedTierFilter == 'All'
        ? roadmap.nodes
        : roadmap.nodes.where((n) => n.level == _selectedTierFilter).toList();

    if (filteredNodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No topics found under $_selectedTierFilter tier.',
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredNodes.length,
      itemBuilder: (context, index) {
        final node = filteredNodes[index];
        return _buildNodeCard(node, index + 1);
      },
    );
  }

  Widget _buildNodeCard(AiRoadmapNode node, int displayIndex) {
    Color tierColor;
    switch (node.level) {
      case 'Advanced':
        tierColor = const Color(0xFFDC2626);
        break;
      case 'Intermediate':
        tierColor = const Color(0xFFD97706);
        break;
      case 'Beginner':
      default:
        tierColor = const Color(0xFF059669);
        break;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: node.isCompleted
            ? AppColors.primaryPurple.withValues(alpha: 0.5)
            : AppColors.border,
        width: node.isCompleted ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Toggle
              InkWell(
                onTap: () => _toggleNodeCompletion(node),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: node.isCompleted
                        ? AppColors.primaryPurple
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.isCompleted
                          ? AppColors.primaryPurple
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: node.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Topic info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            node.level,
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '~${node.estimatedDays} days',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node.topicTitle,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: node.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            node.description,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons: Resource Link & Add to Tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (node.resourceUrl.isNotEmpty)
                InkWell(
                  onTap: () => _openResourceUrl(node.resourceUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_rounded,
                            size: 14, color: AppColors.primaryPurple),
                        const SizedBox(width: 4),
                        Text(
                          node.resourceTitle.isNotEmpty
                              ? node.resourceTitle
                              : 'Documentation',
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(),
              TextButton.icon(
                onPressed: () => _addNodeToTasks(node),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.add_task_rounded, size: 14),
                label: const Text('Add to Tasks',
                    style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.route_rounded,
                size: 64, color: AppColors.primaryPurple),
            const SizedBox(height: 16),
            const Text(
              'No Learning Roadmap Generated Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a customized 3-tier roadmap with skill gaps analysis and recommended study resources.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _regenerateRoadmap,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generate AI Roadmap'),
            ),
          ],
        ),
      ),
    );
  }
}
