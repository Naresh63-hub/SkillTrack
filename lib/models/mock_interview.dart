import 'dart:convert';

class MockInterview {
  final int? id;
  final String jobRole;
  final String
      category; // 'Python', 'Java', 'SQL', 'DSA', 'Web/Frontend', 'AI/ML', 'HR'
  final String difficulty; // 'Entry Level', 'Intermediate', 'Advanced'
  final int totalQuestions;
  final int completedQuestions;
  final double overallScore; // 0.0 - 100.0
  final String status; // 'In Progress', 'Completed'
  final String? feedbackSummary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendedTopics;
  final String createdAt;
  final String? completedAt;
  final bool isAiEvaluated;
  final List<MockInterviewAnswer> answers;

  const MockInterview({
    this.id,
    required this.jobRole,
    required this.category,
    this.difficulty = 'Intermediate',
    this.totalQuestions = 5,
    this.completedQuestions = 0,
    this.overallScore = 0.0,
    this.status = 'In Progress',
    this.feedbackSummary,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendedTopics = const [],
    required this.createdAt,
    this.completedAt,
    this.isAiEvaluated = false,
    this.answers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_role': jobRole,
      'category': category,
      'difficulty': difficulty,
      'total_questions': totalQuestions,
      'completed_questions': completedQuestions,
      'overall_score': overallScore,
      'status': status,
      'feedback_summary': feedbackSummary,
      'strengths': jsonEncode(strengths),
      'weaknesses': jsonEncode(weaknesses),
      'recommended_topics': jsonEncode(recommendedTopics),
      'is_ai_evaluated': isAiEvaluated ? 1 : 0,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  factory MockInterview.fromMap(Map<String, dynamic> map,
      {List<MockInterviewAnswer> answers = const []}) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      try {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [];
    }

    return MockInterview(
      id: map['id'] as int?,
      jobRole: map['job_role'] as String? ?? 'Software Engineer',
      category: map['category'] as String? ?? 'General Technical',
      difficulty: map['difficulty'] as String? ?? 'Intermediate',
      totalQuestions: map['total_questions'] as int? ?? 5,
      completedQuestions: map['completed_questions'] as int? ?? 0,
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'In Progress',
      feedbackSummary: map['feedback_summary'] as String?,
      strengths: parseList(map['strengths']),
      weaknesses: parseList(map['weaknesses']),
      recommendedTopics: parseList(map['recommended_topics']),
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      completedAt: map['completed_at'] as String?,
      isAiEvaluated: (map['is_ai_evaluated'] as int? ?? 0) == 1,
      answers: answers,
    );
  }

  MockInterview copyWith({
    int? id,
    String? jobRole,
    String? category,
    String? difficulty,
    int? totalQuestions,
    int? completedQuestions,
    double? overallScore,
    String? status,
    String? feedbackSummary,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? recommendedTopics,
    String? createdAt,
    String? completedAt,
    bool? isAiEvaluated,
    List<MockInterviewAnswer>? answers,
  }) {
    return MockInterview(
      id: id ?? this.id,
      jobRole: jobRole ?? this.jobRole,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completedQuestions: completedQuestions ?? this.completedQuestions,
      overallScore: overallScore ?? this.overallScore,
      status: status ?? this.status,
      feedbackSummary: feedbackSummary ?? this.feedbackSummary,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      recommendedTopics: recommendedTopics ?? this.recommendedTopics,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isAiEvaluated: isAiEvaluated ?? this.isAiEvaluated,
      answers: answers ?? this.answers,
    );
  }
}

/// Structured 3-dimension evaluation rubrics for interview responses
class InterviewRubrics {
  final double communicationScore; // 0.0 - 100.0
  final String starAdherence; // 'Strong', 'Good', 'Developing'
  final String communicationFeedback;

  final double technicalScore; // 0.0 - 100.0
  final String technicalAccuracy; // 'Exemplary', 'Proficient', 'Partial', 'Needs Review'
  final String technicalFeedback;

  final double terminologyScore; // 0.0 - 100.0
  final List<String> detectedTerms;
  final List<String> missingTerms;
  final String terminologyFeedback;

  const InterviewRubrics({
    this.communicationScore = 75.0,
    this.starAdherence = 'Good',
    this.communicationFeedback = '',
    this.technicalScore = 75.0,
    this.technicalAccuracy = 'Proficient',
    this.technicalFeedback = '',
    this.terminologyScore = 75.0,
    this.detectedTerms = const [],
    this.missingTerms = const [],
    this.terminologyFeedback = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'communication_score': communicationScore,
      'star_adherence': starAdherence,
      'communication_feedback': communicationFeedback,
      'technical_score': technicalScore,
      'technical_accuracy': technicalAccuracy,
      'technical_feedback': technicalFeedback,
      'terminology_score': terminologyScore,
      'detected_terms': detectedTerms,
      'missing_terms': missingTerms,
      'terminology_feedback': terminologyFeedback,
    };
  }

  factory InterviewRubrics.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [];
    }

    return InterviewRubrics(
      communicationScore:
          (map['communication_score'] as num?)?.toDouble() ?? 75.0,
      starAdherence: map['star_adherence'] as String? ?? 'Good',
      communicationFeedback: map['communication_feedback'] as String? ?? '',
      technicalScore: (map['technical_score'] as num?)?.toDouble() ?? 75.0,
      technicalAccuracy:
          map['technical_accuracy'] as String? ?? 'Proficient',
      technicalFeedback: map['technical_feedback'] as String? ?? '',
      terminologyScore:
          (map['terminology_score'] as num?)?.toDouble() ?? 75.0,
      detectedTerms: parseList(map['detected_terms']),
      missingTerms: parseList(map['missing_terms']),
      terminologyFeedback: map['terminology_feedback'] as String? ?? '',
    );
  }

  factory InterviewRubrics.fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return const InterviewRubrics();
    }
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return InterviewRubrics.fromMap(decoded);
      }
    } catch (_) {}
    return const InterviewRubrics();
  }
}

class MockInterviewAnswer {
  final int? id;
  final int interviewId;
  final int questionIndex;
  final String question;
  final String? userAnswer;
  final String? expectedPoints;
  final double score; // 0.0 - 100.0
  final String? feedback;
  final String? improvementTips;
  final String? rubricsJson;
  final InterviewRubrics? rubrics;

  const MockInterviewAnswer({
    this.id,
    required this.interviewId,
    required this.questionIndex,
    required this.question,
    this.userAnswer,
    this.expectedPoints,
    this.score = 0.0,
    this.feedback,
    this.improvementTips,
    this.rubricsJson,
    this.rubrics,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'interview_id': interviewId,
      'question_index': questionIndex,
      'question': question,
      'user_answer': userAnswer,
      'expected_points': expectedPoints,
      'score': score,
      'feedback': feedback,
      'improvement_tips': improvementTips,
      'rubrics_json':
          rubricsJson ?? (rubrics != null ? jsonEncode(rubrics!.toMap()) : null),
    };
  }

  factory MockInterviewAnswer.fromMap(Map<String, dynamic> map) {
    final rawRubrics = map['rubrics_json'] as String?;
    InterviewRubrics? parsedRubrics;
    if (rawRubrics != null && rawRubrics.isNotEmpty) {
      parsedRubrics = InterviewRubrics.fromJsonString(rawRubrics);
    }

    return MockInterviewAnswer(
      id: map['id'] as int?,
      interviewId: map['interview_id'] as int? ?? 0,
      questionIndex: map['question_index'] as int? ?? 0,
      question: map['question'] as String? ?? '',
      userAnswer: map['user_answer'] as String?,
      expectedPoints: map['expected_points'] as String?,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      feedback: map['feedback'] as String?,
      improvementTips: map['improvement_tips'] as String?,
      rubricsJson: rawRubrics,
      rubrics: parsedRubrics,
    );
  }

  MockInterviewAnswer copyWith({
    int? id,
    int? interviewId,
    int? questionIndex,
    String? question,
    String? userAnswer,
    String? expectedPoints,
    double? score,
    String? feedback,
    String? improvementTips,
    String? rubricsJson,
    InterviewRubrics? rubrics,
  }) {
    return MockInterviewAnswer(
      id: id ?? this.id,
      interviewId: interviewId ?? this.interviewId,
      questionIndex: questionIndex ?? this.questionIndex,
      question: question ?? this.question,
      userAnswer: userAnswer ?? this.userAnswer,
      expectedPoints: expectedPoints ?? this.expectedPoints,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      improvementTips: improvementTips ?? this.improvementTips,
      rubricsJson: rubricsJson ?? this.rubricsJson,
      rubrics: rubrics ?? this.rubrics,
    );
  }
}
