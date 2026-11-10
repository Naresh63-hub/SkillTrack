import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/mock_interview.dart';
import '../../../repositories/mock_interview_repository.dart';
import '../../../services/mock_interview_service.dart';
import 'mock_interview_report_screen.dart';

class MockInterviewSessionScreen extends StatefulWidget {
  final MockInterview initialInterview;

  const MockInterviewSessionScreen({
    super.key,
    required this.initialInterview,
  });

  @override
  State<MockInterviewSessionScreen> createState() =>
      _MockInterviewSessionScreenState();
}

class _MockInterviewSessionScreenState extends State<MockInterviewSessionScreen>
    with SingleTickerProviderStateMixin {
  final MockInterviewService _service = MockInterviewService();
  final MockInterviewRepository _repository = MockInterviewRepository();

  late MockInterview _interview;
  int _currentIndex = 0;
  bool _isEvaluating = false;
  bool _isListening = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechInitialized = false;

  final TextEditingController _answerController = TextEditingController();
  late AnimationController _micAnimController;

  @override
  void initState() {
    super.initState();
    _interview = widget.initialInterview;
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _speechToText.stop();
    _micAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceDictation() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechInitialized) {
      _speechInitialized = await _speechToText.initialize(
        onError: (err) {
          debugPrint('Speech recognition error: ${err.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
            }
          }
        },
      );
    }

    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone access is not supported on this browser/device, or was blocked. Please type your answer directly.'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _answerController.text = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
    );
  }

  String get _currentQuestion {
    if (_interview.answers.isEmpty ||
        _currentIndex >= _interview.answers.length) {
      return 'Interview complete.';
    }
    return _interview.answers[_currentIndex].question;
  }

  Future<void> _submitCurrentAnswer() async {
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please articulate or type your answer before proceeding.')),
      );
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final answerRecord = _interview.answers[_currentIndex];
      final evaluation = await _service.evaluateAnswer(
        question: answerRecord.question,
        userAnswer: answerText,
        category: _interview.category,
        difficulty: _interview.difficulty,
      );

      final score = (evaluation['score'] as num?)?.toDouble() ?? 70.0;
      final feedback = evaluation['feedback'] as String? ?? '';
      final tips = evaluation['improvement_tips'] as String? ?? '';

      if (answerRecord.id != null) {
        await _repository.saveAnswer(
          answerId: answerRecord.id!,
          interviewId: _interview.id!,
          userAnswer: answerText,
          score: score,
          feedback: feedback,
          improvementTips: tips,
        );
      }

      // Show intermediate question feedback dialog
      if (mounted) {
        await _showQuestionFeedbackDialog(score, feedback, tips);
      }

      // Move to next question or finalize
      if (_currentIndex + 1 < _interview.answers.length) {
        if (mounted) {
          setState(() {
            _currentIndex++;
            _answerController.clear();
            _isEvaluating = false;
          });
        }
      } else {
        // Finalize interview
        final finalized = await _service.finalizeInterview(_interview.id!);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (ctx) => MockInterviewReportScreen(interview: finalized),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEvaluating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation error: $e')),
        );
      }
    }
  }

  Future<void> _showQuestionFeedbackDialog(
    double score,
    String feedback,
    String tips,
  ) async {
    final isHigh = score >= 75;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isHigh
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color:
                    isHigh ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Text('Evaluation: ${score.toInt()}%'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feedback,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Coach Tip: $tips',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _currentIndex + 1 < _interview.answers.length
                    ? 'Next Question'
                    : 'View Final Score Report',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _interview.answers.length;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('${_interview.jobRole} Interview'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            alignment: Alignment.center,
            child: Text(
              'Q${_currentIndex + 1} of ${_interview.answers.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPurple,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.progressTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple),
              ),
            ),
            const SizedBox(height: 16),

            // AI Interviewer Question Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryPurple.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: AppColors.primaryPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Technical Interviewer',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            Text(
                              '${_interview.category} • ${_interview.difficulty}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _currentQuestion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Answer Input Box & Voice Dictation
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Response',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      // Speech-to-text Dictation Button
                      InkWell(
                        onTap: _toggleVoiceDictation,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(0xFFDC2626)
                                    .withValues(alpha: 0.15)
                                : AppColors.secondaryCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isListening
                                  ? const Color(0xFFDC2626)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _micAnimController,
                                builder: (context, child) {
                                  return Icon(
                                    _isListening
                                        ? Icons.mic
                                        : Icons.mic_none_rounded,
                                    size: 16,
                                    color: _isListening
                                        ? const Color(0xFFDC2626)
                                        : AppColors.primaryPurple,
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isListening
                                    ? 'Listening...'
                                    : 'Voice Dictation',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isListening
                                      ? const Color(0xFFDC2626)
                                      : AppColors.primaryPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _answerController,
                    maxLines: 7,
                    decoration: InputDecoration(
                      hintText:
                          'Articulate your answer clearly. Include technical definitions, trade-offs, and examples as you would in a placement interview...',
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isEvaluating ? null : _submitCurrentAnswer,
                      icon: _isEvaluating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isEvaluating
                            ? 'Evaluating with AI...'
                            : _currentIndex + 1 < _interview.answers.length
                                ? 'Submit & Next Question'
                                : 'Complete & Generate Report',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
