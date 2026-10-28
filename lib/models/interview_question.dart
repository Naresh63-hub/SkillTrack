class InterviewQuestion {
  final int? id;
  final String category;
  final String question;
  final String? answer;
  final String
      status; // 'Not Started', 'In Progress', 'Completed', 'Needs Revision'
  final String updatedAt;

  InterviewQuestion({
    this.id,
    required this.category,
    required this.question,
    this.answer,
    this.status = 'Not Started',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isCompleted => status == 'Completed';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'status': status,
      'updated_at': updatedAt,
    };
  }

  factory InterviewQuestion.fromMap(Map<String, dynamic> map) {
    return InterviewQuestion(
      id: map['id'] as int?,
      category: map['category'] as String? ?? 'Technical',
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String?,
      status: map['status'] as String? ?? 'Not Started',
      updatedAt: map['updated_at'] as String?,
    );
  }

  InterviewQuestion copyWith({
    int? id,
    String? category,
    String? question,
    String? answer,
    String? status,
    String? updatedAt,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      status: status ?? this.status,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
