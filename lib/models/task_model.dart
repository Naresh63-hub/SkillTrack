class TaskModel {
  final int? id;
  final String title;
  final String? description;
  final String category;
  final String priority; // Low, Medium, High
  final String creationDate;
  final String dueDate;
  final bool isCompleted;
  final String? completedAt;
  final String? reminderDateTime;
  final int? relatedSkillId;
  final int? relatedProjectId;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.category,
    this.priority = 'Medium',
    String? creationDate,
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.reminderDateTime,
    this.relatedSkillId,
    this.relatedProjectId,
  }) : creationDate = creationDate ?? DateTime.now().toIso8601String();

  bool get isOverdue {
    if (isCompleted) return false;
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return due.isBefore(todayEnd) && !isToday;
    } catch (_) {
      return false;
    }
  }

  bool get isToday {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      return due.year == now.year &&
          due.month == now.month &&
          due.day == now.day;
    } catch (_) {
      return false;
    }
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return due.isAfter(todayEnd);
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'creation_date': creationDate,
      'due_date': dueDate,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
      'reminder_date_time': reminderDateTime,
      'related_skill_id': relatedSkillId,
      'related_project_id': relatedProjectId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'General',
      priority: map['priority'] as String? ?? 'Medium',
      creationDate: map['creation_date'] as String?,
      dueDate: map['due_date'] as String? ?? DateTime.now().toIso8601String(),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] as String?,
      reminderDateTime: map['reminder_date_time'] as String?,
      relatedSkillId: map['related_skill_id'] as int?,
      relatedProjectId: map['related_project_id'] as int?,
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? creationDate,
    String? dueDate,
    bool? isCompleted,
    String? completedAt,
    String? reminderDateTime,
    int? relatedSkillId,
    int? relatedProjectId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      creationDate: creationDate ?? this.creationDate,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      relatedSkillId: relatedSkillId ?? this.relatedSkillId,
      relatedProjectId: relatedProjectId ?? this.relatedProjectId,
    );
  }
}
