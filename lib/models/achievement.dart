class Achievement {
  final int? id;
  final String title;
  final String? description;
  final String? dateAchieved;
  final String createdAt;

  Achievement({
    this.id,
    required this.title,
    this.description,
    this.dateAchieved,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date_achieved': dateAchieved,
      'created_at': createdAt,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      dateAchieved: map['date_achieved'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Achievement copyWith({
    int? id,
    String? title,
    String? description,
    String? dateAchieved,
    String? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateAchieved: dateAchieved ?? this.dateAchieved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
