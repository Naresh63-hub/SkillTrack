import 'dart:convert';

class AiRoadmap {
  final int? id;
  final String targetRole;
  final String skillLevel;
  final double overallProgress;
  final String summary;
  final List<String> skillGaps;
  final String createdAt;
  final String updatedAt;
  final bool isAiGenerated;
  final List<AiRoadmapNode> nodes;

  const AiRoadmap({
    this.id,
    required this.targetRole,
    this.skillLevel = 'Beginner',
    this.overallProgress = 0.0,
    required this.summary,
    this.skillGaps = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isAiGenerated = false,
    this.nodes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'target_role': targetRole,
      'skill_level': skillLevel,
      'overall_progress': overallProgress,
      'summary': summary,
      'skill_gaps': jsonEncode(skillGaps),
      'is_ai_generated': isAiGenerated ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AiRoadmap.fromMap(Map<String, dynamic> map,
      {List<AiRoadmapNode> nodes = const []}) {
    List<String> gaps = [];
    if (map['skill_gaps'] != null) {
      try {
        final decoded = jsonDecode(map['skill_gaps'] as String);
        if (decoded is List) {
          gaps = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return AiRoadmap(
      id: map['id'] as int?,
      targetRole: map['target_role'] as String? ?? 'Software Engineer',
      skillLevel: map['skill_level'] as String? ?? 'Beginner',
      overallProgress: (map['overall_progress'] as num?)?.toDouble() ?? 0.0,
      summary: map['summary'] as String? ?? '',
      skillGaps: gaps,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      isAiGenerated: (map['is_ai_generated'] as int? ?? 0) == 1,
      nodes: nodes,
    );
  }

  AiRoadmap copyWith({
    int? id,
    String? targetRole,
    String? skillLevel,
    double? overallProgress,
    String? summary,
    List<String>? skillGaps,
    String? createdAt,
    String? updatedAt,
    bool? isAiGenerated,
    List<AiRoadmapNode>? nodes,
  }) {
    return AiRoadmap(
      id: id ?? this.id,
      targetRole: targetRole ?? this.targetRole,
      skillLevel: skillLevel ?? this.skillLevel,
      overallProgress: overallProgress ?? this.overallProgress,
      summary: summary ?? this.summary,
      skillGaps: skillGaps ?? this.skillGaps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      nodes: nodes ?? this.nodes,
    );
  }
}

class AiRoadmapNode {
  final int? id;
  final int roadmapId;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final String topicTitle;
  final String description;
  final String category;
  final int estimatedDays;
  final String resourceTitle;
  final String resourceUrl;
  final bool isCompleted;
  final String? completedAt;
  final int orderIndex;
  final String createdAt;

  const AiRoadmapNode({
    this.id,
    required this.roadmapId,
    required this.level,
    required this.topicTitle,
    required this.description,
    required this.category,
    this.estimatedDays = 3,
    required this.resourceTitle,
    required this.resourceUrl,
    this.isCompleted = false,
    this.completedAt,
    this.orderIndex = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roadmap_id': roadmapId,
      'level': level,
      'topic_title': topicTitle,
      'description': description,
      'category': category,
      'estimated_days': estimatedDays,
      'resource_title': resourceTitle,
      'resource_url': resourceUrl,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
      'order_index': orderIndex,
      'created_at': createdAt,
    };
  }

  factory AiRoadmapNode.fromMap(Map<String, dynamic> map) {
    return AiRoadmapNode(
      id: map['id'] as int?,
      roadmapId: map['roadmap_id'] as int? ?? 0,
      level: map['level'] as String? ?? 'Beginner',
      topicTitle: map['topic_title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Core',
      estimatedDays: map['estimated_days'] as int? ?? 3,
      resourceTitle:
          map['resource_title'] as String? ?? 'Official Documentation',
      resourceUrl: map['resource_url'] as String? ?? '',
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  AiRoadmapNode copyWith({
    int? id,
    int? roadmapId,
    String? level,
    String? topicTitle,
    String? description,
    String? category,
    int? estimatedDays,
    String? resourceTitle,
    String? resourceUrl,
    bool? isCompleted,
    String? completedAt,
    int? orderIndex,
    String? createdAt,
  }) {
    return AiRoadmapNode(
      id: id ?? this.id,
      roadmapId: roadmapId ?? this.roadmapId,
      level: level ?? this.level,
      topicTitle: topicTitle ?? this.topicTitle,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      resourceTitle: resourceTitle ?? this.resourceTitle,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
