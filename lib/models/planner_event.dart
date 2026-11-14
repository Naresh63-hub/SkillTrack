class PlannerEvent {
  final int? id;
  final String title;
  final String? description;
  final String
      eventType; // 'Placement Drive', 'Exam / Test', 'Study Sprint', 'Revision', 'Mock Interview'
  final String targetDate; // YYYY-MM-DD
  final String? startTime; // e.g. "10:00 AM"
  final String? endTime; // e.g. "12:00 PM"
  final bool isCompleted;
  final String priority; // 'High', 'Medium', 'Low'
  final int? reminderMinutesBefore;
  final String createdAt;
  final String updatedAt;

  PlannerEvent({
    this.id,
    required this.title,
    this.description,
    this.eventType = 'Study Sprint',
    String? targetDate,
    String? eventDate,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.priority = 'Medium',
    this.reminderMinutesBefore,
    String? createdAt,
    String? updatedAt,
  })  : targetDate = targetDate ??
            eventDate ??
            DateTime.now().toIso8601String().split('T').first,
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  String get eventDate => targetDate;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'target_date': targetDate,
      'start_time': startTime,
      'end_time': endTime,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'reminder_minutes_before': reminderMinutesBefore,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PlannerEvent.fromMap(Map<String, dynamic> map) {
    return PlannerEvent(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      eventType: map['event_type'] as String? ?? 'Study Sprint',
      targetDate: map['target_date'] as String? ??
          DateTime.now().toIso8601String().split('T').first,
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      priority: map['priority'] as String? ?? 'Medium',
      reminderMinutesBefore: map['reminder_minutes_before'] as int?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  PlannerEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? eventType,
    String? targetDate,
    String? startTime,
    String? endTime,
    bool? isCompleted,
    String? priority,
    int? reminderMinutesBefore,
    String? createdAt,
    String? updatedAt,
  }) {
    return PlannerEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      targetDate: targetDate ?? this.targetDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  /// Days remaining until the target date. 0 = Today, negative = Overdue, positive = Future.
  int get daysRemaining {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime.parse(targetDate);
      final targetDay = DateTime(target.year, target.month, target.day);
      return targetDay.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  bool get isToday => daysRemaining == 0;
  bool get isUpcoming => daysRemaining > 0;
  bool get isOverdue => daysRemaining < 0 && !isCompleted;

  String get countdownLabel {
    if (isCompleted) return 'Completed';
    final days = daysRemaining;
    if (days == 0) return 'TODAY';
    if (days == 1) return 'IN 1 DAY';
    if (days > 1) return 'IN $days DAYS';
    if (days == -1) return '1 DAY AGO';
    return '${days.abs()} DAYS AGO';
  }

  static const List<String> eventTypes = [
    'Placement Drive',
    'Exam / Test',
    'Study Sprint',
    'Revision',
    'Mock Interview',
  ];

  static const List<String> priorities = [
    'High',
    'Medium',
    'Low',
  ];
}
