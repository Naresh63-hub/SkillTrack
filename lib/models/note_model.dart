class NoteModel {
  final int? id;
  final String title;
  final String content;
  final String
      category; // 'DSA & Coding', 'Core CS', 'Interview Prep', 'College / Exam', 'Personal'
  final String? linkedSkillName;
  final bool isPinned;
  final String colorTag; // 'purple', 'blue', 'emerald', 'amber', 'rose'
  final String createdAt;
  final String updatedAt;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    this.category = 'DSA & Coding',
    this.linkedSkillName,
    this.isPinned = false,
    this.colorTag = 'purple',
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  String get formattedUpdatedDate {
    try {
      final dt = DateTime.parse(updatedAt);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return updatedAt;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'category': category,
      'linked_skill_name': linkedSkillName,
      'is_pinned': isPinned ? 1 : 0,
      'color_tag': colorTag,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      linkedSkillName: map['linked_skill_name'] as String?,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      colorTag: map['color_tag'] as String? ?? 'purple',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? linkedSkillName,
    bool? isPinned,
    String? colorTag,
    String? createdAt,
    String? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      linkedSkillName: linkedSkillName ?? this.linkedSkillName,
      isPinned: isPinned ?? this.isPinned,
      colorTag: colorTag ?? this.colorTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  static const List<String> categories = [
    'DSA & Coding',
    'Core CS',
    'Interview Prep',
    'System Design',
    'College / Exam',
    'Personal',
  ];

  static const List<String> colorTags = [
    'purple',
    'blue',
    'emerald',
    'amber',
    'rose',
  ];
}
