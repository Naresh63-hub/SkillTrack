class LearningGoal {
  final int? id;
  final String title;
  final String goalType; // 'Daily', 'Weekly'
  final int targetCount;
  final int currentCount;
  final bool isCompleted;
  final String createdAt;
  final String? targetDate;

  LearningGoal({
    this.id,
    required this.title,
    this.goalType = 'Daily',
    this.targetCount = 1,
    this.currentCount = 0,
    this.isCompleted = false,
    String? createdAt,
    this.targetDate,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  double get progressPercentage {
    if (targetCount <= 0) return isCompleted ? 100.0 : 0.0;
    final pct = (currentCount / targetCount) * 100.0;
    return pct > 100.0 ? 100.0 : pct;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'goal_type': goalType,
      'target_count': targetCount,
      'current_count': currentCount,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
      'target_date': targetDate,
    };
  }

  factory LearningGoal.fromMap(Map<String, dynamic> map) {
    return LearningGoal(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      goalType: map['goal_type'] as String? ?? 'Daily',
      targetCount: map['target_count'] as int? ?? 1,
      currentCount: map['current_count'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
      targetDate: map['target_date'] as String?,
    );
  }

  LearningGoal copyWith({
    int? id,
    String? title,
    String? goalType,
    int? targetCount,
    int? currentCount,
    bool? isCompleted,
    String? createdAt,
    String? targetDate,
  }) {
    return LearningGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      goalType: goalType ?? this.goalType,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
