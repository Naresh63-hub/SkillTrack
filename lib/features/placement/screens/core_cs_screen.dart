import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/placement_topic.dart';
import '../../../repositories/placement_repository.dart';
import 'add_edit_topic_dialog.dart';

class CoreCsScreen extends StatefulWidget {
  final VoidCallback? onTopicsChanged;
  const CoreCsScreen({super.key, this.onTopicsChanged});

  @override
  State<CoreCsScreen> createState() => _CoreCsScreenState();
}

class _CoreCsScreenState extends State<CoreCsScreen> {
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
    final results = await _repository.getTopicsByTrack('CoreCS');
    setState(() {
      _topics = results;
      _isLoading = false;
    });
    widget.onTopicsChanged?.call();
  }

  Future<void> _addTopic() async {
    final newTopic = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => const AddEditTopicDialog(track: 'CoreCS'),
    );

    if (newTopic != null) {
      await _repository.addPlacementTopic(newTopic);
      _loadTopics();
    }
  }

  Future<void> _editTopic(PlacementTopic topic) async {
    final updated = await showDialog<PlacementTopic>(
      context: context,
      builder: (context) => AddEditTopicDialog(track: 'CoreCS', topic: topic),
    );

    if (updated != null) {
      await _repository.updatePlacementTopic(updated);
      _loadTopics();
    }
  }

  Future<void> _deleteTopic(PlacementTopic topic) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Subject',
      content: 'Are you sure you want to delete "${topic.topicName}"?',
    );

    if (confirmed) {
      await _repository.deletePlacementTopic(topic.id!);
      _loadTopics();
    }
  }

  Future<void> _cycleStatus(PlacementTopic topic) async {
    String nextStatus;
    switch (topic.completionStatus) {
      case 'Not Started':
        nextStatus = 'In Progress';
        break;
      case 'In Progress':
        nextStatus = 'Completed';
        break;
      case 'Completed':
        nextStatus = 'Needs Revision';
        break;
      case 'Needs Revision':
      default:
        nextStatus = 'Completed';
        break;
    }
    final updated = topic.copyWith(completionStatus: nextStatus);
    await _repository.updatePlacementTopic(updated);
    _loadTopics();
  }

  Future<void> _loadStandardCoreCsTopics() async {
    final standardCoreCs = [
      {
        'topic': 'Database Management Systems (DBMS)',
        'notes': 'SQL queries, Normalization (1NF to BCNF), Indexing, ACID properties.',
        'link': 'https://www.geeksforgeeks.org/dbms/'
      },
      {
        'topic': 'Operating Systems (OS)',
        'notes': 'Process scheduling, Concurrency, Deadlocks, Virtual memory & Paging.',
        'link': 'https://www.geeksforgeeks.org/operating-systems/'
      },
      {
        'topic': 'Computer Networks (CN)',
        'notes': 'OSI & TCP/IP models, DNS, IP addressing, Socket programming, HTTP/HTTPS.',
        'link': 'https://www.geeksforgeeks.org/computer-network-tutorials/'
      },
      {
        'topic': 'Object-Oriented Programming (OOPs)',
        'notes': '4 Pillars of OOPs, SOLID design principles, Design patterns.',
        'link': 'https://www.geeksforgeeks.org/object-oriented-programming-oops-concept-in-java/'
      },
      {
        'topic': 'System Design & Distributed Basics',
        'notes': 'Scalability, Load Balancing, Caching, Sharding, Microservices basics.',
        'link': 'https://github.com/donnemartin/system-design-primer'
      },
    ];

    for (final t in standardCoreCs) {
      await _repository.addPlacementTopic(
        PlacementTopic(
          track: 'CoreCS',
          topicName: t['topic'] as String,
          category: 'Core CS',
          problemsSolved: 0,
          problemsAttempted: 0,
          practiceLinks: t['link'] as String,
          notes: t['notes'] as String,
          difficultyLevel: 'Medium',
          completionStatus: 'Not Started',
        ),
      );
    }
    await _loadTopics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standard Core CS subjects added! 💻'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brightAccent));
    }

    final completedCount =
        _topics.where((t) => t.completionStatus == 'Completed').length;
    final progressPct =
        _topics.isEmpty ? 0.0 : (completedCount / _topics.length) * 100.0;

    return Scaffold(
      appBar: ModalRoute.of(context)?.canPop == true
          ? AppBar(title: const Text('Core CS Subjects'))
          : null,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Subject'),
        onPressed: _addTopic,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Header (Clean, high-contrast Bento style)
            CustomCard(
              backgroundColor: AppColors.cardBackground,
              borderRadius: 18,
              border: Border.all(color: AppColors.border, width: 1),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.memory_rounded,
                              size: 17, color: AppColors.primaryPurple),
                          SizedBox(width: 6),
                          Text(
                            'Core CS Mastery',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$completedCount / ${_topics.length} Subjects Revised',
                        style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomProgressBar(percentage: progressPct, height: 8),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Fundamental Computer Science Subjects',
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
                        Icons.memory_rounded,
                        color: AppColors.primaryPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Core CS Subjects Tracked Yet',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track essential technical interview subjects (DBMS, OS, Computer Networks, OOPs, System Design).',
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
                        'Load Standard Core CS Subjects',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _loadStandardCoreCsTopics,
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
                  return _buildSubjectCard(topic);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(PlacementTopic topic) {
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
              InkWell(
                onTap: () => _cycleStatus(topic),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        topic.completionStatus,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.sync, size: 12, color: statusColor),
                    ],
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
          if (topic.notes != null && topic.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              topic.notes!,
              style: const TextStyle(
                  color: AppColors.secondaryText, fontSize: 12, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
