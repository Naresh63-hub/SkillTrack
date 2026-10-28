class Skill {
  final int? id;
  final String name;
  final String category;
  final String proficiencyLevel; // Beginner, Intermediate, Advanced, Expert
  final double progressPercentage; // 0.0 to 100.0
  final String? dateStarted;
  final String? targetCompletionDate;
  final String? learningResourceUrl;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Skill({
    this.id,
    required this.name,
    required this.category,
    this.proficiencyLevel = 'Beginner',
    this.progressPercentage = 0.0,
    this.dateStarted,
    this.targetCompletionDate,
    this.learningResourceUrl,
    this.notes,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isOverdue {
    if (targetCompletionDate == null || targetCompletionDate!.isEmpty)
      return false;
    if (progressPercentage >= 100.0) return false;
    try {
      final target = DateTime.parse(targetCompletionDate!);
      final now = DateTime.now();
      return target.isBefore(DateTime(now.year, now.month, now.day));
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'proficiency_level': proficiencyLevel,
      'progress_percentage': progressPercentage,
      'date_started': dateStarted,
      'target_completion_date': targetCompletionDate,
      'learning_resource_url': learningResourceUrl,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      proficiencyLevel: map['proficiency_level'] as String? ?? 'Beginner',
      progressPercentage:
          (map['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      dateStarted: map['date_started'] as String?,
      targetCompletionDate: map['target_completion_date'] as String?,
      learningResourceUrl: map['learning_resource_url'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Skill copyWith({
    int? id,
    String? name,
    String? category,
    String? proficiencyLevel,
    double? progressPercentage,
    String? dateStarted,
    String? targetCompletionDate,
    String? learningResourceUrl,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      dateStarted: dateStarted ?? this.dateStarted,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      learningResourceUrl: learningResourceUrl ?? this.learningResourceUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
