import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/custom_card.dart';

class DailyFocusChecklist extends StatefulWidget {
  final VoidCallback? onStreakActivity;

  const DailyFocusChecklist({super.key, this.onStreakActivity});

  @override
  State<DailyFocusChecklist> createState() => _DailyFocusChecklistState();
}

class _DailyFocusChecklistState extends State<DailyFocusChecklist> {
  bool _potdDone = false;
  bool _studyDone = false;
  bool _placementDone = false;
  bool _isLoading = true;

  // Curated 7-day rolling rotation of standard interview problems
  static const List<Map<String, String>> _curatedPotd = [
    {
      'title': 'Two Sum (Hash Map Lookup)',
      'difficulty': 'Easy',
      'platform': 'LeetCode',
      'url': 'https://leetcode.com/problems/two-sum/',
    },
    {
      'title': 'Valid Parentheses (Stack)',
      'difficulty': 'Easy',
      'platform': 'LeetCode',
      'url': 'https://leetcode.com/problems/valid-parentheses/',
    },
    {
      'title': 'Reverse Linked List',
      'difficulty': 'Easy',
      'platform': 'LeetCode',
      'url': 'https://leetcode.com/problems/reverse-linked-list/',
    },
    {
      'title': 'Maximum Subarray (Kadane)',
      'difficulty': 'Medium',
      'platform': 'LeetCode',
      'url': 'https://leetcode.com/problems/maximum-subarray/',
    },
    {
      'title': 'Binary Search in Rotated Array',
      'difficulty': 'Medium',
      'platform': 'LeetCode',
      'url': 'https://leetcode.com/problems/search-in-rotated-sorted-array/',
    },
    {
      'title': 'Longest Substring Without Repeating',
      'difficulty': 'Medium',
      'platform': 'LeetCode',
      'url':
          'https://leetcode.com/problems/longest-substring-without-repeating-characters/',
    },
    {
      'title': 'Lowest Common Ancestor (BST)',
      'difficulty': 'Medium',
      'platform': 'LeetCode',
      'url':
          'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/',
    },
  ];

  Map<String, String> get _todayProblem {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _curatedPotd[dayOfYear % _curatedPotd.length];
  }

  String get _dateKeyPrefix {
    final now = DateTime.now();
    return 'daily_focus_${now.year}_${now.month}_${now.day}_';
  }

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final pKey = _dateKeyPrefix;
    if (mounted) {
      setState(() {
        _potdDone = prefs.getBool('${pKey}potd') ?? false;
        _studyDone = prefs.getBool('${pKey}study') ?? false;
        _placementDone = prefs.getBool('${pKey}placement') ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleItem(String item, bool current) async {
    HapticFeedback.mediumImpact();
    final next = !current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dateKeyPrefix$item', next);

    if (next) {
      await StreakCalculator.recordTodayActive();
      widget.onStreakActivity?.call();
    }

    setState(() {
      if (item == 'potd') _potdDone = next;
      if (item == 'study') _studyDone = next;
      if (item == 'placement') _placementDone = next;
    });

    // Check if all 3 non-negotiables are completed today!
    if (_potdDone && _studyDone && _placementDone) {
      if (mounted) {
        ConfettiOverlay.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Congratulations! All 3 Daily Non-Negotiables Crushed!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _launchPotd(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final completedCount =
        (_potdDone ? 1 : 0) + (_studyDone ? 1 : 0) + (_placementDone ? 1 : 0);
    final potd = _todayProblem;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.stars_rounded,
                        color: AppColors.primaryPurple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's 3 Non-Negotiables",
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Consistent daily actions protect your streak',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completedCount == 3
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completedCount == 3
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '$completedCount/3 Done',
                  style: TextStyle(
                    color: completedCount == 3
                        ? AppColors.success
                        : AppColors.primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Problem of the Day
          _buildCheckRow(
            isDone: _potdDone,
            title: 'POTD: ${potd['title']}',
            subtitle: '${potd['difficulty']} • ${potd['platform']}',
            badgeColor: potd['difficulty'] == 'Easy'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            onToggle: () => _toggleItem('potd', _potdDone),
            trailingAction: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 13),
              label: const Text('Solve', style: TextStyle(fontSize: 11.5)),
              onPressed: () => _launchPotd(potd['url']!),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Study Session
          _buildCheckRow(
            isDone: _studyDone,
            title: 'Focus 30-min Skill Study Session',
            subtitle: 'Core theory or implementation practice',
            onToggle: () => _toggleItem('study', _studyDone),
          ),
          const SizedBox(height: 8),

          // 3. Placement / Task
          _buildCheckRow(
            isDone: _placementDone,
            title: 'Solve 1 Core CS / Aptitude Concept',
            subtitle: 'OS, DBMS, CN or quantitative problem',
            onToggle: () => _toggleItem('placement', _placementDone),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow({
    required bool isDone,
    required String title,
    required String subtitle,
    Color? badgeColor,
    required VoidCallback onToggle,
    Widget? trailingAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.surfaceVariant.withValues(alpha: 0.4)
            : AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.success : AppColors.mutedText,
                  width: 1.8,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDone ? AppColors.mutedText : AppColors.primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 10.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingAction != null) trailingAction,
        ],
      ),
    );
  }
}
