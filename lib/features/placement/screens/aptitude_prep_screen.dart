import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/placement_topic.dart';
import '../../../repositories/placement_repository.dart';
import 'add_edit_topic_dialog.dart';

class AptitudePrepScreen extends StatefulWidget {
  const AptitudePrepScreen({super.key});

  @override
  State<AptitudePrepScreen> createState() => _AptitudePrepScreenState();
}

class _AptitudePrepScreenState extends State<AptitudePrepScreen> {
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
    final results = await _repository.getTopicsByTrack('Aptitude');
    setState(() {
      _topics = results;
      _isLoading = false;
    });
  }

  Future<void> _addTopic() async {
    final newTopic = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => const AddEditTopicDialog(track: 'Aptitude'),
    );

    if (newTopic != null) {
      await _repository.addPlacementTopic(newTopic);
      _loadTopics();
    }
  }

  Future<void> _editTopic(PlacementTopic topic) async {
    final updated = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => AddEditTopicDialog(track: 'Aptitude', topic: topic),
    );

    if (updated != null) {
      await _repository.updatePlacementTopic(updated);
      _loadTopics();
    }
  }

  Future<void> _deleteTopic(PlacementTopic topic) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Aptitude Topic',
      content: 'Are you sure you want to delete "${topic.topicName}"?',
    );

    if (confirmed) {
      await _repository.deletePlacementTopic(topic.id!);
      _loadTopics();
    }
  }

  Future<void> _logPracticeDrill(PlacementTopic topic) async {
    final solvedCtrl = TextEditingController(text: '10');
    final attCtrl = TextEditingController(text: '10');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Drill for ${topic.topicName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: solvedCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Questions Solved Correctly'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: attCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Questions Attempted Total'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Log Drill')),
        ],
      ),
    );

    if (result == true) {
      final s = int.tryParse(solvedCtrl.text.trim()) ?? 0;
      final a = int.tryParse(attCtrl.text.trim()) ?? 0;
      final updated = topic.copyWith(
        problemsSolved: topic.problemsSolved + s,
        problemsAttempted: topic.problemsAttempted + a,
        completionStatus: 'In Progress',
      );
      await _repository.updatePlacementTopic(updated);
      _loadTopics();
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
    final accuracy =
        totalAttempted > 0 ? (totalSolved / totalAttempted) * 100.0 : 0.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Section'),
        onPressed: _addTopic,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accuracy Header Card
            CustomCard(
              gradient: AppColors.elevatedGradient,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                      'Questions Solved', '$totalSolved', AppColors.success),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildMetric('Attempted', '$totalAttempted', AppColors.info),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _buildMetric('Accuracy', '${accuracy.toStringAsFixed(0)}%',
                      AppColors.brightAccent),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Aptitude & Reasoning Practice Sections',
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
                    'No aptitude practice logged yet. Add Quant, Reasoning, or Verbal drills.',
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
                  return _buildAptitudeCard(topic);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAptitudeCard(PlacementTopic topic) {
    final acc = topic.problemsAttempted > 0
        ? (topic.problemsSolved / topic.problemsAttempted) * 100.0
        : 0.0;

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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.brightAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.fitness_center, size: 14),
                label: const Text('Log Drill', style: TextStyle(fontSize: 11)),
                onPressed: () => _logPracticeDrill(topic),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solved: ${topic.problemsSolved} / ${topic.problemsAttempted}',
                style: const TextStyle(
                    color: AppColors.secondaryText, fontSize: 12),
              ),
              Text(
                'Accuracy: ${acc.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: AppColors.brightAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomProgressBar(percentage: acc, height: 6),
        ],
      ),
    );
  }
}
