class PlacementTopic {
  final int? id;
  final String track; // 'Coding', 'CoreCS', 'Aptitude'
  final String topicName;
  final String? category;
  final int problemsSolved;
  final int problemsAttempted;
  final String? practiceLinks;
  final String? notes;
  final String difficultyLevel; // 'Easy', 'Medium', 'Hard', 'Comprehensive'
  final String
      completionStatus; // 'Not Started', 'In Progress', 'Completed', 'Needs Revision'
  final String updatedAt;

  PlacementTopic({
    this.id,
    required this.track,
    required this.topicName,
    this.category,
    this.problemsSolved = 0,
    this.problemsAttempted = 0,
    this.practiceLinks,
    this.notes,
    this.difficultyLevel = 'Medium',
    this.completionStatus = 'Not Started',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isCompleted => completionStatus == 'Completed';

  double get completionPercentage {
    if (completionStatus == 'Completed') return 100.0;
    if (problemsAttempted > 0) {
      final p = (problemsSolved / problemsAttempted) * 100.0;
      return p > 100.0 ? 100.0 : p;
    }
    if (completionStatus == 'In Progress') return 50.0;
    if (completionStatus == 'Needs Revision') return 75.0;
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'track': track,
      'topic_name': topicName,
      'category': category,
      'problems_solved': problemsSolved,
      'problems_attempted': problemsAttempted,
      'practice_links': practiceLinks,
      'notes': notes,
      'difficulty_level': difficultyLevel,
      'completion_status': completionStatus,
      'updated_at': updatedAt,
    };
  }

  factory PlacementTopic.fromMap(Map<String, dynamic> map) {
    return PlacementTopic(
      id: map['id'] as int?,
      track: map['track'] as String? ?? 'Coding',
      topicName: map['topic_name'] as String? ?? '',
      category: map['category'] as String?,
      problemsSolved: map['problems_solved'] as int? ?? 0,
      problemsAttempted: map['problems_attempted'] as int? ?? 0,
      practiceLinks: map['practice_links'] as String?,
      notes: map['notes'] as String?,
      difficultyLevel: map['difficulty_level'] as String? ?? 'Medium',
      completionStatus: map['completion_status'] as String? ?? 'Not Started',
      updatedAt: map['updated_at'] as String?,
    );
  }

  PlacementTopic copyWith({
    int? id,
    String? track,
    String? topicName,
    String? category,
    int? problemsSolved,
    int? problemsAttempted,
    String? practiceLinks,
    String? notes,
    String? difficultyLevel,
    String? completionStatus,
    String? updatedAt,
  }) {
    return PlacementTopic(
      id: id ?? this.id,
      track: track ?? this.track,
      topicName: topicName ?? this.topicName,
      category: category ?? this.category,
      problemsSolved: problemsSolved ?? this.problemsSolved,
      problemsAttempted: problemsAttempted ?? this.problemsAttempted,
      practiceLinks: practiceLinks ?? this.practiceLinks,
      notes: notes ?? this.notes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      completionStatus: completionStatus ?? this.completionStatus,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
