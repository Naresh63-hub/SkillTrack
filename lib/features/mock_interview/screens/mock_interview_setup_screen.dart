import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/mock_interview.dart';
import '../../../repositories/mock_interview_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/mock_interview_service.dart';
import 'mock_interview_session_screen.dart';
import 'mock_interview_report_screen.dart';

class MockInterviewSetupScreen extends StatefulWidget {
  const MockInterviewSetupScreen({super.key});

  @override
  State<MockInterviewSetupScreen> createState() =>
      _MockInterviewSetupScreenState();
}

class _MockInterviewSetupScreenState extends State<MockInterviewSetupScreen> {
  final MockInterviewService _service = MockInterviewService();
  final MockInterviewRepository _repository = MockInterviewRepository();
  final ProfileRepository _profileRepo = ProfileRepository();

  String _selectedRole = 'Software Engineer';
  String _selectedCategory = 'Data Structures and Algorithms';
  String _selectedDifficulty = 'Intermediate';
  bool _isLoading = true;
  bool _isStarting = false;
  List<MockInterview> _pastInterviews = [];

  final List<String> _roles = [
    'Software Engineer',
    'Flutter Developer',
    'Python Developer',
    'Java Developer',
    'Full Stack Developer',
    'AI/ML Engineer',
    'Data Analyst',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await _profileRepo.getProfile();
    if (profile.targetJobRole.trim().isNotEmpty) {
      _selectedRole = profile.targetJobRole.trim();
    }
    final history = await _repository.getAllInterviews();

    if (mounted) {
      setState(() {
        _pastInterviews = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _startInterview() async {
    setState(() => _isStarting = true);
    try {
      final interview = await _service.startNewInterview(
        role: _selectedRole,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );

      if (mounted) {
        setState(() => _isStarting = false);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) =>
                MockInterviewSessionScreen(initialInterview: interview),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start interview: $e')),
        );
      }
    }
  }

  Future<void> _viewReport(int interviewId) async {
    final interview = await _repository.getInterviewById(interviewId);
    if (interview != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => MockInterviewReportScreen(interview: interview),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('AI Mock Interview Hub'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Configuration Card
                  _buildSetupCard(),
                  const SizedBox(height: 24),

                  // Previous Interview History
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSetupCard() {
    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.primaryPurple, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure Interview Round',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      'AI evaluates actual answers with placement scoring',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Target Role Dropdown
          const Text(
            'Target Job Role',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value:
                _roles.contains(_selectedRole) ? _selectedRole : _roles.first,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _roles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
          const SizedBox(height: 14),

          // 2. Category Chips
          const Text(
            'Interview Category',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MockInterviewService.categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.primaryPurple,
                backgroundColor: AppColors.cardBackground,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primaryPurple : AppColors.border,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 3. Difficulty Level
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: MockInterviewService.difficulties.map((diff) {
              final isSelected = _selectedDifficulty == diff;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedDifficulty = diff),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurple
                            : AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryPurple
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        diff,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.primaryText,
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isStarting ? null : _startInterview,
              icon: _isStarting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(_isStarting
                  ? 'Preparing Questions...'
                  : 'Start AI Mock Interview (5 Questions)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interview History & Performance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              '${_pastInterviews.length} sessions',
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_pastInterviews.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'No interviews taken yet. Start your first session above to test placement readiness!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, fontSize: 12.5),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pastInterviews.length,
            itemBuilder: (context, index) {
              final item = _pastInterviews[index];
              final dateStr = item.createdAt.split('T').first;
              final score = item.overallScore.clamp(0.0, 100.0);
              final isHigh = score >= 75;

              return CustomCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                onTap: () => _viewReport(item.id!),
                child: Row(
                  children: [
                    // Score Circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.status == 'Completed'
                            ? (isHigh
                                ? const Color(0xFF059669)
                                    .withValues(alpha: 0.15)
                                : const Color(0xFFD97706)
                                    .withValues(alpha: 0.15))
                            : AppColors.secondaryCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.status == 'Completed'
                              ? (isHigh
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706))
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item.status == 'Completed'
                              ? '${score.toInt()}%'
                              : '...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.status == 'Completed'
                                ? (isHigh
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706))
                                : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.jobRole} (${item.category})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.difficulty} • $dateStr • ${item.status}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.mutedText),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
