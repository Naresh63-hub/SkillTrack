import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/career_roadmap.dart';
import '../../../models/skill.dart';
import '../../../services/roadmap_service.dart';

/// The official Role-Based Skill Roadmap confirmation dialog.
class RoadmapImportDialog extends StatelessWidget {
  const RoadmapImportDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const RoadmapImportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.roadmapCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.roadmapSecondaryCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.roadmapPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: AppColors.roadmapPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Import Roadmap',
              style: TextStyle(
                color: AppColors.roadmapText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'Would you like to add this recommended roadmap to your skills?',
        style: TextStyle(
          color: AppColors.roadmapSecondaryText,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.roadmapSecondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.roadmapPrimary,
            foregroundColor: AppColors.roadmapText,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: const Text(
            'Import Roadmap',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class RoadmapDetailScreen extends StatefulWidget {
  final CareerRoadmap roadmap;
  final RoadmapService? roadmapService;
  final Map<String, Skill>? initialExistingSkills;

  const RoadmapDetailScreen({
    super.key,
    required this.roadmap,
    this.roadmapService,
    this.initialExistingSkills,
  });

  @override
  State<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends State<RoadmapDetailScreen> {
  late final RoadmapService _roadmapService;
  Map<String, Skill> _existingSkillsMap = {};
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _roadmapService = widget.roadmapService ?? RoadmapService();
    if (widget.initialExistingSkills != null) {
      _existingSkillsMap = widget.initialExistingSkills!;
      _isLoading = false;
    } else {
      _loadExistingSkills();
    }
  }

  Future<void> _loadExistingSkills() async {
    setState(() => _isLoading = true);
    final map = await _roadmapService.getExistingSkillsMap();
    if (mounted) {
      setState(() {
        _existingSkillsMap = map;
        _isLoading = false;
      });
    }
  }

  Future<void> _promptImportRoadmap() async {
    final confirmed = await RoadmapImportDialog.show(context);
    if (confirmed == true && mounted) {
      await _executeImport();
    }
  }

  Future<void> _executeImport() async {
    setState(() => _isImporting = true);

    try {
      final result = await _roadmapService.importRoadmap(widget.roadmap);
      await _loadExistingSkills();

      if (!mounted) return;

      String message;
      if (result.addedCount > 0 && result.skippedCount > 0) {
        message =
            'Added ${result.addedCount} new skill(s) to your roadmap. ${result.skippedCount} already tracked skill(s) were preserved.';
      } else if (result.addedCount > 0) {
        message =
            'All ${result.addedCount} skills added successfully at 0% progress!';
      } else {
        message =
            'All ${result.totalSkills} skills from this roadmap are already in your skills module.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: AppColors.roadmapText, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.roadmapSecondaryCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Return true to indicate change to callers
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import roadmap: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
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
            SnackBar(content: Text('Could not open link: $url')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = widget.roadmap;
    final totalSkills = roadmap.skills.length;

    int alreadyAddedCount = 0;
    for (final item in roadmap.skills) {
      if (_existingSkillsMap.containsKey(item.name.trim().toLowerCase())) {
        alreadyAddedCount++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.roadmapBackground,
      appBar: AppBar(
        backgroundColor: AppColors.roadmapBackground,
        elevation: 0,
        title: Text(
          roadmap.roleName,
          style: const TextStyle(
            color: AppColors.roadmapText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.roadmapText),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.roadmapCard,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$alreadyAddedCount of $totalSkills Skills Tracked',
                      style: const TextStyle(
                        color: AppColors.roadmapSecondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alreadyAddedCount == totalSkills
                          ? 'Roadmap fully in your skills'
                          : '${totalSkills - alreadyAddedCount} new skills ready to import',
                      style: const TextStyle(
                        color: AppColors.roadmapText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _promptImportRoadmap,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.roadmapText,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  alreadyAddedCount == totalSkills
                      ? 'Re-Sync Roadmap'
                      : 'Import Roadmap',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roadmapPrimary,
                  foregroundColor: AppColors.roadmapText,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.roadmapPrimary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role Overview Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.roadmapSecondaryCard,
                          AppColors.roadmapCard,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.roadmapPrimary.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.roadmapPrimary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.roadmapPrimary
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                roadmap.icon,
                                color: AppColors.roadmapSecondaryAccent,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roadmap.roleName,
                                    style: const TextStyle(
                                      color: AppColors.roadmapText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    roadmap.tagline,
                                    style: const TextStyle(
                                      color: AppColors.roadmapSecondaryAccent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          roadmap.description,
                          style: const TextStyle(
                            color: AppColors.roadmapSecondaryText,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Roadmap Stats Pills
                        Row(
                          children: [
                            _buildInfoPill(
                              icon: Icons.list_alt_rounded,
                              label: '$totalSkills Milestones',
                            ),
                            const SizedBox(width: 8),
                            _buildInfoPill(
                              icon: Icons.check_circle_outline_rounded,
                              label: '$alreadyAddedCount Tracked',
                              highlight: alreadyAddedCount > 0,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoPill(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Placement Ready',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommended Skill Path',
                        style: TextStyle(
                          color: AppColors.roadmapText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '8 Steps to Mastery',
                        style: TextStyle(
                          color: AppColors.roadmapSecondaryAccent
                              .withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 8 Curated Roadmap Skills List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roadmap.skills.length,
                    separatorBuilder: (context, index) =>
                        _buildPathConnector(index),
                    itemBuilder: (context, index) {
                      final item = roadmap.skills[index];
                      final existingSkill =
                          _existingSkillsMap[item.name.trim().toLowerCase()];
                      return _buildSkillItemCard(item, existingSkill);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.roadmapPrimary.withValues(alpha: 0.2)
            : AppColors.roadmapBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? AppColors.roadmapPrimary
              : AppColors.border.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: highlight
                ? AppColors.roadmapSecondaryAccent
                : AppColors.roadmapSecondaryText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: highlight
                  ? AppColors.roadmapSecondaryAccent
                  : AppColors.roadmapSecondaryText,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathConnector(int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 31),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.roadmapPrimary.withValues(alpha: 0.6),
                AppColors.roadmapSecondaryAccent.withValues(alpha: 0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillItemCard(RoadmapSkillItem item, Skill? existingSkill) {
    final bool isAdded = existingSkill != null;
    final double progress = existingSkill?.progressPercentage ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.roadmapCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdded
              ? AppColors.roadmapPrimary.withValues(alpha: 0.45)
              : AppColors.border,
          width: isAdded ? 1.2 : 0.8,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isAdded
                      ? const LinearGradient(
                          colors: [
                            AppColors.roadmapPrimary,
                            AppColors.roadmapSecondaryAccent,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.roadmapSecondaryCard,
                            AppColors.roadmapBackground,
                          ],
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAdded
                        ? AppColors.roadmapSecondaryAccent
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${item.order}',
                    style: TextStyle(
                      color: isAdded
                          ? Colors.white
                          : AppColors.roadmapSecondaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppColors.roadmapText,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isAdded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.roadmapPrimary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.roadmapPrimary
                                    .withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.roadmapSecondaryAccent,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress.toInt()}% Tracked',
                                  style: const TextStyle(
                                    color: AppColors.roadmapSecondaryAccent,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.roadmapSecondaryCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                color: AppColors.roadmapSecondaryText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: AppColors.roadmapSecondaryText,
                            fontSize: 11.5,
                          ),
                        ),
                        const Text(
                          '  •  ',
                          style: TextStyle(
                            color: AppColors.border,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          item.proficiencyLevel,
                          style: const TextStyle(
                            color: AppColors.roadmapSecondaryAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.roadmapSecondaryText,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                if (item.learningResourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openResourceUrl(item.learningResourceUrl),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: AppColors.roadmapSecondaryAccent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Learning Resource / Docs',
                            style: TextStyle(
                              color: AppColors.roadmapSecondaryAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.roadmapSecondaryAccent
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
