import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/career_chat_models.dart';
import '../../../repositories/career_assistant_repository.dart';
import '../../../services/ai_service.dart';
import '../../../services/career_assistant_service.dart';
import '../../ai_roadmap/screens/ai_roadmap_screen.dart';
import '../../github/screens/github_dashboard_screen.dart';
import '../../mock_interview/screens/mock_interview_setup_screen.dart';
import '../../profile/screens/settings_screen.dart';

class CareerAssistantScreen extends StatefulWidget {
  const CareerAssistantScreen({super.key});

  @override
  State<CareerAssistantScreen> createState() => _CareerAssistantScreenState();
}

class _CareerAssistantScreenState extends State<CareerAssistantScreen> {
  final CareerAssistantService _service = CareerAssistantService();
  final CareerAssistantRepository _repository = CareerAssistantRepository();

  CareerChatSession? _session;
  List<CareerChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasAiKey = false;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'What skills should I learn next?',
    'How do I prepare for placement interviews?',
    'How can I improve my tech resume?',
    'Recommend portfolio projects for my role',
  ];

  @override
  void initState() {
    super.initState();
    _checkAiKey();
    _loadSession();
  }

  Future<void> _checkAiKey() async {
    final hasKey = await AiService.instance.hasApiKey();
    if (mounted) setState(() => _hasAiKey = hasKey);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);
    final session = await _repository.getOrCreateActiveSession();
    final messages = await _repository.getMessages(session.id!);

    if (mounted) {
      setState(() {
        _session = session;
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _session == null) return;

    _inputController.clear();
    setState(() => _isSending = true);

    try {
      await _service.processUserMessage(
        sessionId: _session!.id!,
        userText: cleanText,
        history: _messages,
      );

      final updated = await _repository.getMessages(_session!.id!);
      if (mounted) {
        setState(() {
          _messages = updated;
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    if (_session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
            'This will wipe previous messages in this guidance session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearMessages(_session!.id!);
      _loadSession();
    }
  }

  void _handleAction(String actionType, String? payload) {
    if (actionType == 'roadmap') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => AiRoadmapScreen(initialRole: payload),
        ),
      );
    } else if (actionType == 'interview') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const MockInterviewSetupScreen(),
        ),
      );
    } else if (actionType == 'github') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const GithubDashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AppColors.primaryPurple, size: 20),
            SizedBox(width: 8),
            Text('AI Career Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Conversation',
            onPressed: _messages.isEmpty ? null : _clearChat,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : Column(
              children: [
                _buildStatusBanner(),

                // Quick Suggestion Chips
                _buildQuickPromptsBar(),

                // Chat Messages Stream
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildMessageBubble(msg);
                          },
                        ),
                ),

                if (_isSending)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCard,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Assistant is thinking...',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),

                // Input Bar
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    if (_hasAiKey) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.secondaryCard.withValues(alpha: 0.8),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Running offline heuristic mode. Add Gemini API key in Settings for cloud generative AI.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  )
                  .then((_) => _checkAiKey());
            },
            child: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(prompt),
              backgroundColor: AppColors.secondaryCard,
              labelStyle: const TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              onPressed: _isSending ? null : () => _sendMessage(prompt),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.secondaryCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Personal Tech Career Coach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask anything about placement preparation, resume feedback, skill roadmap choices, or interview strategies tailored to your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(CareerChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondaryCard,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryText,
                        height: 1.45,
                      ),
                    ),
                    if (msg.actionType != null) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            _handleAction(msg.actionType!, msg.actionPayload),
                        icon: Icon(
                          msg.actionType == 'roadmap'
                              ? Icons.route_rounded
                              : msg.actionType == 'interview'
                                  ? Icons.record_voice_over_rounded
                                  : Icons.code_rounded,
                          size: 14,
                        ),
                        label: Text(
                          msg.actionType == 'roadmap'
                              ? 'Open AI Learning Roadmap'
                              : msg.actionType == 'interview'
                                  ? 'Start AI Mock Interview'
                                  : 'Open GitHub Hub',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask about career goals, skills, resumes...',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: AppColors.secondaryCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _isSending ? null : _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon:
                    const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                onPressed: _isSending
                    ? null
                    : () => _sendMessage(_inputController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
