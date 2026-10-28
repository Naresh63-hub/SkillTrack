class Education {
  final int? id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startYear;
  final String endYear;
  final String? gradeOrCgpa;
  final String createdAt;

  Education({
    this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startYear,
    required this.endYear,
    this.gradeOrCgpa,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_year': startYear,
      'end_year': endYear,
      'grade_or_cgpa': gradeOrCgpa,
      'created_at': createdAt,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] as int?,
      institution: map['institution'] as String? ?? '',
      degree: map['degree'] as String? ?? '',
      fieldOfStudy: map['field_of_study'] as String? ?? '',
      startYear: map['start_year'] as String? ?? '',
      endYear: map['end_year'] as String? ?? '',
      gradeOrCgpa: map['grade_or_cgpa'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Education copyWith({
    int? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? startYear,
    String? endYear,
    String? gradeOrCgpa,
    String? createdAt,
  }) {
    return Education(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      gradeOrCgpa: gradeOrCgpa ?? this.gradeOrCgpa,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
