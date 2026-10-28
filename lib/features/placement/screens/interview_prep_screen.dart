import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/interview_question.dart';
import '../../../repositories/placement_repository.dart';
import 'add_edit_interview_q_dialog.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  final PlacementRepository _repository = PlacementRepository();
  List<InterviewQuestion> _questions = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final results = await _repository.getInterviewQuestions(
      category: _selectedCategory,
    );
    setState(() {
      _questions = results;
      _isLoading = false;
    });
  }

  Future<void> _addQuestion() async {
    final newQ = await showDialog<InterviewQuestion>(
      context: context,
      builder: (context) => const AddEditInterviewQDialog(),
    );

    if (newQ != null) {
      await _repository.addInterviewQuestion(newQ);
      _loadQuestions();
    }
  }

  Future<void> _editQuestion(InterviewQuestion question) async {
    final updated = await showDialog<InterviewQuestion>(
      context: context,
      builder: (context) => AddEditInterviewQDialog(question: question),
    );

    if (updated != null) {
      await _repository.updateInterviewQuestion(updated);
      _loadQuestions();
    }
  }

  Future<void> _deleteQuestion(InterviewQuestion question) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Question',
      content: 'Are you sure you want to delete this interview question?',
    );

    if (confirmed) {
      await _repository.deleteInterviewQuestion(question.id!);
      _loadQuestions();
    }
  }

  Future<void> _cycleStatus(InterviewQuestion question) async {
    String nextStatus;
    switch (question.status) {
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
    final updated = question.copyWith(status: nextStatus);
    await _repository.updateInterviewQuestion(updated);
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brightAccent));
    }

    final completedCount =
        _questions.where((q) => q.status == 'Completed').length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Question'),
        onPressed: _addQuestion,
      ),
      body: Column(
        children: [
          // Category horizontal chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('All'),
                  ...AppStrings.interviewCategories
                      .map((c) => _buildCategoryChip(c)),
                ],
              ),
            ),
          ),

          // Header summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_questions.length} Questions Prepared',
                  style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '$completedCount Ready for Interview',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _questions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No interview questions in this category. Add technical or HR questions to practice your STAR responses.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.mutedText, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      return _buildQuestionCard(q);
                    },
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
          setState(() => _selectedCategory = category);
          _loadQuestions();
        },
      ),
    );
  }

  Widget _buildQuestionCard(InterviewQuestion q) {
    Color statusColor;
    switch (q.status) {
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
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        collapsedIconColor: AppColors.secondaryAccent,
        iconColor: AppColors.brightAccent,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                q.question,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _cycleStatus(q),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  q.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            q.category,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 11.5),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.record_voice_over,
                        color: AppColors.brightAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Prepared Answer / Talking Points:',
                      style: TextStyle(
                          color: AppColors.secondaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.answer ??
                      'No answer recorded yet. Tap edit to write key points.',
                  style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                onPressed: () => _editQuestion(q),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete, size: 14),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                onPressed: () => _deleteQuestion(q),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
