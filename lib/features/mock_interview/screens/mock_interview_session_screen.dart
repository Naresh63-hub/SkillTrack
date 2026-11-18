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

  // Countdown response timer state
  int _selectedDurationSeconds = 90; // Default 90 seconds
  int _remainingSeconds = 90;
  Timer? _countdownTimer;
  bool _isTimerRunning = false;
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _interview = widget.initialInterview;
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Auto-start timer for question 1
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _answerController.dispose();
    _speechToText.stop();
    _micAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = true;
      _isTimeUp = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerRunning = false;
          _isTimeUp = true;
        });
        if (_isListening) {
          _speechToText.stop();
          setState(() => _isListening = false);
        }
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() => _isTimerRunning = false);
    }
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _extendTime(int seconds) {
    setState(() {
      _remainingSeconds += seconds;
      _isTimeUp = false;
    });
    if (!_isTimerRunning) {
      _startTimer();
    }
  }

  void _resetTimer([int? newDuration]) {
    _countdownTimer?.cancel();
    if (newDuration != null) {
      _selectedDurationSeconds = newDuration;
    }
    setState(() {
      _remainingSeconds = _selectedDurationSeconds;
      _isTimeUp = false;
    });
    _startTimer();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_isTimeUp || _remainingSeconds == 0) return const Color(0xFFDC2626);
    if (_remainingSeconds <= 15) return const Color(0xFFDC2626); // Urgent red
    if (_remainingSeconds <= 30) return const Color(0xFFD97706); // Warning amber
    return AppColors.lightPurple; // Normal purple
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
    if (!_isTimerRunning && !_isTimeUp) {
      _startTimer();
    }

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

    _pauseTimer();
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
      final rubrics = evaluation['rubrics'] as InterviewRubrics?;
      final rubricsJson = evaluation['rubrics_json'] as String?;

      if (answerRecord.id != null) {
        await _repository.saveAnswer(
          answerId: answerRecord.id!,
          interviewId: _interview.id!,
          userAnswer: answerText,
          score: score,
          feedback: feedback,
          improvementTips: tips,
          rubricsJson: rubricsJson,
        );
      }

      // Show intermediate question feedback with 3-rubrics breakdown
      if (mounted) {
        await _showQuestionFeedbackDialog(score, feedback, tips, rubrics);
      }

      // Move to next question or finalize
      if (_currentIndex + 1 < _interview.answers.length) {
        if (mounted) {
          setState(() {
            _currentIndex++;
            _answerController.clear();
            _isEvaluating = false;
          });
          _resetTimer();
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
        _startTimer();
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
    InterviewRubrics? rubrics,
  ) async {
    final effectiveRubrics = rubrics ?? const InterviewRubrics();
    final isHigh = score >= 75;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHigh
                      ? const Color(0xFF059669).withValues(alpha: 0.15)
                      : const Color(0xFFD97706).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHigh
                      ? Icons.check_circle_rounded
                      : Icons.insights_rounded,
                  color: isHigh
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} Evaluation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      'Score: ${score.toInt()}% • 3-Rubric Analysis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHigh
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rubric 1: Communication & Structure (STAR Method)
                  _buildRubricCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '1. Communication & Structure (STAR)',
                    score: effectiveRubrics.communicationScore,
                    tag: 'STAR: ${effectiveRubrics.starAdherence}',
                    tagColor: effectiveRubrics.starAdherence == 'Strong'
                        ? const Color(0xFF059669)
                        : (effectiveRubrics.starAdherence == 'Good'
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD97706)),
                    feedback: effectiveRubrics.communicationFeedback,
                  ),
                  const SizedBox(height: 10),

                  // Rubric 2: Technical Accuracy
                  _buildRubricCard(
                    icon: Icons.precision_manufacturing_outlined,
                    title: '2. Technical Accuracy',
                    score: effectiveRubrics.technicalScore,
                    tag: effectiveRubrics.technicalAccuracy,
                    tagColor: effectiveRubrics.technicalAccuracy == 'Exemplary'
                        ? const Color(0xFF059669)
                        : (effectiveRubrics.technicalAccuracy == 'Proficient'
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD97706)),
                    feedback: effectiveRubrics.technicalFeedback,
                  ),
                  const SizedBox(height: 10),

                  // Rubric 3: Key Terminology Used
                  _buildTerminologyCard(effectiveRubrics),
                  const SizedBox(height: 12),

                  // Coach Tip
                  if (tips.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Interviewer Coach Tip:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tips,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryText,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _currentIndex + 1 < _interview.answers.length
                    ? 'Next Question →'
                    : 'View Final Score Report →',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRubricCard({
    required IconData icon,
    required String title,
    required double score,
    required String tag,
    required Color tagColor,
    required String feedback,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$tag (${score.toInt()}%)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feedback,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminologyCard(InterviewRubrics rubrics) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sell_outlined,
                  size: 16, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '3. Key Terminology Used',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rubrics.terminologyScore.toInt()}% Density',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Detected Terms
          if (rubrics.detectedTerms.isNotEmpty) ...[
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: rubrics.detectedTerms.map((term) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check,
                          size: 11, color: Color(0xFF059669)),
                      const SizedBox(width: 3),
                      Text(
                        term,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Missing Terms Recommendation
          if (rubrics.missingTerms.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: rubrics.missingTerms.map((term) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    '+ $term',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.lightPurple,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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
            const SizedBox(height: 14),

            // Countdown Response Timer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondaryCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _timerColor.withValues(alpha: 0.45),
                  width: _remainingSeconds <= 15 ? 1.5 : 1,
                ),
                boxShadow: _remainingSeconds <= 15
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFDC2626).withValues(alpha: 0.18),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _timerColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isTimeUp
                              ? Icons.timer_off_rounded
                              : Icons.timer_rounded,
                          color: _timerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: _timerColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _timerColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _isTimeUp
                                        ? 'TIME EXPIRED'
                                        : (_remainingSeconds <= 15
                                            ? 'FINAL SECONDS'
                                            : 'PRESSURE TIMER'),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: _timerColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isTimeUp
                                  ? 'Time is up! Wrap up your thoughts and click Submit.'
                                  : 'Articulate your response within the ${_selectedDurationSeconds}s target window.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isTimerRunning
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 24,
                          color: AppColors.primaryPurple,
                        ),
                        tooltip:
                            _isTimerRunning ? 'Pause Timer' : 'Resume Timer',
                        onPressed: _toggleTimer,
                      ),
                      InkWell(
                        onTap: () => _extendTime(30),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.more_time_rounded,
                                  size: 14, color: AppColors.lightPurple),
                              SizedBox(width: 4),
                              Text(
                                '+30s',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mini Timer Duration Selector
                  Row(
                    children: [
                      const Text(
                        'Target Pace: ',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ...[60, 90, 120].map((dur) {
                        final isSel = _selectedDurationSeconds == dur;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _resetTimer(dur),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primaryPurple
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${dur}s${dur == 90 ? " (Default)" : ""}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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
