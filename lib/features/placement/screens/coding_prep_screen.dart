import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/placement_topic.dart';
import '../../../repositories/placement_repository.dart';
import 'add_edit_topic_dialog.dart';

class CodingPrepScreen extends StatefulWidget {
  final VoidCallback? onTopicsChanged;
  const CodingPrepScreen({super.key, this.onTopicsChanged});

  @override
  State<CodingPrepScreen> createState() => _CodingPrepScreenState();
}

class _CodingPrepScreenState extends State<CodingPrepScreen> {
  final PlacementRepository _repository = PlacementRepository();
  List<PlacementTopic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final results = await _repository.getTopicsByTrack('Coding');
    setState(() {
      _topics = results;
      _isLoading = false;
    });
    widget.onTopicsChanged?.call();
  }

  Future<void> _addTopic() async {
    final newTopic = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => const AddEditTopicDialog(track: 'Coding'),
    );

    if (newTopic != null) {
      await _repository.addPlacementTopic(newTopic);
      _loadTopics();
    }
  }

  Future<void> _editTopic(PlacementTopic topic) async {
    final updated = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => AddEditTopicDialog(track: 'Coding', topic: topic),
    );

    if (updated != null) {
      await _repository.updatePlacementTopic(updated);
      _loadTopics();
    }
  }

  Future<void> _deleteTopic(PlacementTopic topic) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Coding Topic',
      content: 'Are you sure you want to delete "${topic.topicName}"?',
    );

    if (confirmed) {
      await _repository.deletePlacementTopic(topic.id!);
      _loadTopics();
    }
  }

  Future<void> _incrementSolved(PlacementTopic topic) async {
    final updated = topic.copyWith(
      problemsSolved: topic.problemsSolved + 1,
      problemsAttempted: topic.problemsAttempted >= topic.problemsSolved + 1
          ? topic.problemsAttempted
          : topic.problemsSolved + 1,
      completionStatus: topic.completionStatus == 'Not Started'
          ? 'In Progress'
          : topic.completionStatus,
    );
    await _repository.updatePlacementTopic(updated);
    _loadTopics();
  }

  Future<void> _loadStandardDsaTopics() async {
    final standardTopics = [
      {
        'topic': 'Arrays & Two Pointers',
        'solved': 0,
        'att': 0,
        'diff': 'Easy',
        'link': 'https://leetcode.com/tag/array/'
      },
      {
        'topic': 'Strings & Sliding Window',
        'solved': 0,
        'att': 0,
        'diff': 'Medium',
        'link': 'https://leetcode.com/tag/sliding-window/'
      },
      {
        'topic': 'Linked Lists & Fast-Slow Pointers',
        'solved': 0,
        'att': 0,
        'diff': 'Easy',
        'link': 'https://leetcode.com/tag/linked-list/'
      },
      {
        'topic': 'Binary Trees & Traversals (BFS/DFS)',
        'solved': 0,
        'att': 0,
        'diff': 'Medium',
        'link': 'https://leetcode.com/tag/tree/'
      },
      {
        'topic': 'Dynamic Programming (1D & 2D)',
        'solved': 0,
        'att': 0,
        'diff': 'Hard',
        'link': 'https://leetcode.com/tag/dynamic-programming/'
      },
      {
        'topic': 'Graph Algorithms (Dijkstra, BFS/DFS)',
        'solved': 0,
        'att': 0,
        'diff': 'Hard',
        'link': 'https://leetcode.com/tag/graph/'
      },
    ];

    for (final t in standardTopics) {
      await _repository.addPlacementTopic(
        PlacementTopic(
          track: 'Coding',
          topicName: t['topic'] as String,
          category: 'DSA',
          problemsSolved: t['solved'] as int,
          problemsAttempted: t['att'] as int,
          practiceLinks: t['link'] as String,
          notes: 'Standard SDE sheet topic for technical placement interviews.',
          difficultyLevel: t['diff'] as String,
          completionStatus: 'Not Started',
        ),
      );
    }
    await _loadTopics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standard DSA topics added to your tracker! 🚀'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brightAccent));
    }

    final totalSolved =
        _topics.fold<int>(0, (sum, t) => sum + t.problemsSolved);
    final totalAttempted =
        _topics.fold<int>(0, (sum, t) => sum + t.problemsAttempted);

    return Scaffold(
      appBar: ModalRoute.of(context)?.canPop == true
          ? AppBar(title: const Text('Coding Practice (DSA)'))
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add DSA Topic'),
        onPressed: _addTopic,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Header Card (Clean, high-contrast Bento style)
            CustomCard(
              backgroundColor: AppColors.cardBackground,
              borderRadius: 18,
              border: Border.all(color: AppColors.border, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderMetric(
                    'Total Solved',
                    '$totalSolved',
                    const Color(0xFF10B981),
                    Icons.check_circle_outline_rounded,
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildHeaderMetric(
                    'Attempted',
                    '$totalAttempted',
                    const Color(0xFF3B82F6),
                    Icons.pending_actions_rounded,
                  ),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildHeaderMetric(
                    'Topics Tracked',
                    '${_topics.length}',
                    AppColors.primaryPurple,
                    Icons.auto_stories_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Data Structures & Algorithms Topics',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (_topics.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(22),
                borderRadius: 18,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: AppColors.primaryPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No DSA Topics Tracked Yet',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track your progress on Striver/NeetCode SDE sheet patterns (Arrays, Two Pointers, Trees, Dynamic Programming).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text(
                        'Load Standard DSA Topics',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _loadStandardDsaTopics,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  return _buildTopicCard(topic);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(PlacementTopic topic) {
    Color statusColor;
    switch (topic.completionStatus) {
      case 'Completed':
        statusColor = AppColors.success;
        break;
      case 'In Progress':
        statusColor = AppColors.brightAccent;
        break;
      case 'Needs Revision':
        statusColor = AppColors.warning;
        break;
      case 'Not Started':
      default:
        statusColor = AppColors.mutedText;
        break;
    }

    return CustomCard(
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
                  topic.topicName,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  topic.completionStatus,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold),
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
                    _editTopic(topic);
                  } else if (action == 'delete') {
                    _deleteTopic(topic);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Solved: ${topic.problemsSolved} / ${topic.problemsAttempted}',
                style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.brightAccent,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+1 Solved', style: TextStyle(fontSize: 11)),
                onPressed: () => _incrementSolved(topic),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomProgressBar(
            percentage: topic.completionPercentage,
            height: 6,
          ),
          if (topic.practiceLinks != null &&
              topic.practiceLinks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl(topic.practiceLinks!),
              child: Row(
                children: [
                  const Icon(Icons.link,
                      size: 14, color: AppColors.secondaryAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      topic.practiceLinks!,
                      style: const TextStyle(
                        color: AppColors.secondaryAccent,
                        fontSize: 11.5,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
