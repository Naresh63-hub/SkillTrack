import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/career_roadmap.dart';
import '../../../models/skill.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/roadmap_service.dart';
import 'roadmap_detail_screen.dart';

class CareerRoadmapsScreen extends StatefulWidget {
  final List<CareerRoadmap>? initialRoadmaps;
  final Map<String, Skill>? initialSkillsMap;
  final String? initialUserTargetRole;

  const CareerRoadmapsScreen({
    super.key,
    this.initialRoadmaps,
    this.initialSkillsMap,
    this.initialUserTargetRole,
  });

  @override
  State<CareerRoadmapsScreen> createState() => _CareerRoadmapsScreenState();
}

class _CareerRoadmapsScreenState extends State<CareerRoadmapsScreen> {
  final RoadmapService _roadmapService = RoadmapService();
  final ProfileRepository _profileRepo = ProfileRepository();

  List<CareerRoadmap> _roadmaps = [];
  Map<String, Skill> _existingSkillsMap = {};
  String _userTargetRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoadmaps != null) {
      _roadmaps = widget.initialRoadmaps!;
      _existingSkillsMap = widget.initialSkillsMap ?? {};
      _userTargetRole = widget.initialUserTargetRole ?? '';
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final roadmaps = RoadmapService.getAvailableRoadmaps();
    final skillsMap = await _roadmapService.getExistingSkillsMap();
    final profile = await _profileRepo.getProfile();

    if (mounted) {
      setState(() {
        _roadmaps = roadmaps;
        _existingSkillsMap = skillsMap;
        _userTargetRole = profile.targetJobRole.trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _openRoadmap(CareerRoadmap roadmap) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RoadmapDetailScreen(roadmap: roadmap),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadmapBackground,
      appBar: AppBar(
        backgroundColor: AppColors.roadmapBackground,
        elevation: 0,
        title: const Text(
          'Career Skill Roadmaps',
          style: TextStyle(
            color: AppColors.roadmapText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.roadmapText),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.roadmapPrimary,
              ),
            )
          : RefreshIndicator(
              color: AppColors.roadmapPrimary,
              backgroundColor: AppColors.roadmapCard,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header introduction
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.roadmapSecondaryCard,
                            AppColors.roadmapCard,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.roadmapPrimary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.roadmapPrimary
                                    .withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: AppColors.roadmapSecondaryAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Industry-Standard Roadmaps',
                                  style: TextStyle(
                                    color: AppColors.roadmapText,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select a career role to review 8 curated skills and add them directly to your personal tracker.',
                                  style: TextStyle(
                                    color: AppColors.roadmapSecondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Target Career Roles',
                      style: TextStyle(
                        color: AppColors.roadmapText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Roadmaps List
                    ..._roadmaps.map((roadmap) => _buildRoadmapCard(roadmap)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRoadmapCard(CareerRoadmap roadmap) {
    final bool isUserTarget = _userTargetRole.isNotEmpty &&
        roadmap.roleName.toLowerCase().contains(_userTargetRole.toLowerCase());

    int alreadyTracked = 0;
    for (final skill in roadmap.skills) {
      if (_existingSkillsMap.containsKey(skill.name.trim().toLowerCase())) {
        alreadyTracked++;
      }
    }

    final double completionPercent =
        roadmap.skills.isEmpty ? 0 : (alreadyTracked / roadmap.skills.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.roadmapCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUserTarget
              ? AppColors.roadmapPrimary.withValues(alpha: 0.6)
              : AppColors.border,
          width: isUserTarget ? 1.5 : 0.8,
        ),
        boxShadow: [
          if (isUserTarget)
            BoxShadow(
              color: AppColors.roadmapPrimary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRoadmap(roadmap),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.roadmapSecondaryCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.roadmapPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        roadmap.icon,
                        color: AppColors.roadmapSecondaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  roadmap.roleName,
                                  style: const TextStyle(
                                    color: AppColors.roadmapText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isUserTarget)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.roadmapPrimary
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.roadmapPrimary,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Your Goal',
                                    style: TextStyle(
                                      color: AppColors.roadmapSecondaryAccent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            roadmap.tagline,
                            style: const TextStyle(
                              color: AppColors.roadmapSecondaryAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  roadmap.description,
                  style: const TextStyle(
                    color: AppColors.roadmapSecondaryText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // Footer with tracking progress and explore button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$alreadyTracked of ${roadmap.skills.length} skills tracked',
                                style: const TextStyle(
                                  color: AppColors.roadmapSecondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                              if (alreadyTracked == roadmap.skills.length) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 13,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: completionPercent,
                              backgroundColor: AppColors.roadmapSecondaryCard,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.roadmapPrimary,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: const [
                        Text(
                          'View Roadmap',
                          style: TextStyle(
                            color: AppColors.roadmapSecondaryAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.roadmapSecondaryAccent,
                          size: 12,
                        ),
                      ],
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
