class Project {
  final int? id;
  final String name;
  final String shortDescription;
  final String? detailedDescription;
  final String category;
  final List<String> technologies;
  final String status; // Planned, In Progress, Completed, On Hold
  final String? startDate;
  final String? completionDate;
  final String? githubUrl;
  final String? liveDemoUrl;
  final String? imagePath;
  final String? keyFeatures;
  final String? problemsSolved;
  final String? whatLearned;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Project({
    this.id,
    required this.name,
    required this.shortDescription,
    this.detailedDescription,
    required this.category,
    required this.technologies,
    this.status = 'In Progress',
    this.startDate,
    this.completionDate,
    this.githubUrl,
    this.liveDemoUrl,
    this.imagePath,
    this.keyFeatures,
    this.problemsSolved,
    this.whatLearned,
    this.notes,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get isCompleted => status == 'Completed';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'short_description': shortDescription,
      'detailed_description': detailedDescription,
      'category': category,
      'technologies': technologies.join(','),
      'status': status,
      'start_date': startDate,
      'completion_date': completionDate,
      'github_url': githubUrl,
      'live_demo_url': liveDemoUrl,
      'image_path': imagePath,
      'key_features': keyFeatures,
      'problems_solved': problemsSolved,
      'what_learned': whatLearned,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    final techString = map['technologies'] as String? ?? '';
    final techs = techString.isEmpty
        ? <String>[]
        : techString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return Project(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      detailedDescription: map['detailed_description'] as String?,
      category: map['category'] as String? ?? 'General',
      technologies: techs,
      status: map['status'] as String? ?? 'In Progress',
      startDate: map['start_date'] as String?,
      completionDate: map['completion_date'] as String?,
      githubUrl: map['github_url'] as String?,
      liveDemoUrl: map['live_demo_url'] as String?,
      imagePath: map['image_path'] as String?,
      keyFeatures: map['key_features'] as String?,
      problemsSolved: map['problems_solved'] as String?,
      whatLearned: map['what_learned'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Project copyWith({
    int? id,
    String? name,
    String? shortDescription,
    String? detailedDescription,
    String? category,
    List<String>? technologies,
    String? status,
    String? startDate,
    String? completionDate,
    String? githubUrl,
    String? liveDemoUrl,
    String? imagePath,
    String? keyFeatures,
    String? problemsSolved,
    String? whatLearned,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      category: category ?? this.category,
      technologies: technologies ?? this.technologies,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      completionDate: completionDate ?? this.completionDate,
      githubUrl: githubUrl ?? this.githubUrl,
      liveDemoUrl: liveDemoUrl ?? this.liveDemoUrl,
      imagePath: imagePath ?? this.imagePath,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      problemsSolved: problemsSolved ?? this.problemsSolved,
      whatLearned: whatLearned ?? this.whatLearned,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
