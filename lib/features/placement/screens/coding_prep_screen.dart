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
  const CodingPrepScreen({super.key});

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
            // Summary Header Card
            CustomCard(
              gradient: AppColors.elevatedGradient,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderMetric(
                      'Total Solved', '$totalSolved', AppColors.success),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildHeaderMetric(
                      'Attempted', '$totalAttempted', AppColors.info),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildHeaderMetric('Topics Tracked', '${_topics.length}',
                      AppColors.brightAccent),
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
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'No DSA topics recorded. Tap "Add DSA Topic" or load demo data in Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
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

  Widget _buildHeaderMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
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
