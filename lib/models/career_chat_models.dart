class CareerChatSession {
  final int? id;
  final String title;
  final String createdAt;
  final String updatedAt;

  const CareerChatSession({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CareerChatSession.fromMap(Map<String, dynamic> map) {
    return CareerChatSession(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Career Guidance Session',
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class CareerChatMessage {
  final int? id;
  final int sessionId;
  final String sender; // 'user' or 'assistant'
  final String content;
  final String? actionType; // 'roadmap', 'interview', 'github', 'tasks'
  final String? actionPayload;
  final String createdAt;

  const CareerChatMessage({
    this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    this.actionType,
    this.actionPayload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'sender': sender,
      'content': content,
      'action_type': actionType,
      'action_payload': actionPayload,
      'created_at': createdAt,
    };
  }

  factory CareerChatMessage.fromMap(Map<String, dynamic> map) {
    return CareerChatMessage(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int? ?? 0,
      sender: map['sender'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      actionType: map['action_type'] as String?,
      actionPayload: map['action_payload'] as String?,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  bool get isUser => sender == 'user';
}
