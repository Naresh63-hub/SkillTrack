class StudentProfile {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String college;
  final String degree;
  final String branch;
  final String currentSemester;
  final String graduationYear;
  final String targetJobRole;
  final String githubUrl;
  final String linkedinUrl;
  final String portfolioUrl;
  final String bio;
  final String updatedAt;

  StudentProfile({
    this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.city = '',
    this.college = '',
    this.degree = '',
    this.branch = '',
    this.currentSemester = '',
    this.graduationYear = '',
    this.targetJobRole = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.portfolioUrl = '',
    this.bio = '',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'college': college,
      'degree': degree,
      'branch': branch,
      'current_semester': currentSemester,
      'graduation_year': graduationYear,
      'target_job_role': targetJobRole,
      'github_url': githubUrl,
      'linkedin_url': linkedinUrl,
      'portfolio_url': portfolioUrl,
      'bio': bio,
      'updated_at': updatedAt,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      college: map['college'] as String? ?? '',
      degree: map['degree'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      currentSemester: map['current_semester'] as String? ?? '',
      graduationYear: map['graduation_year'] as String? ?? '',
      targetJobRole: map['target_job_role'] as String? ?? '',
      githubUrl: map['github_url'] as String? ?? '',
      linkedinUrl: map['linkedin_url'] as String? ?? '',
      portfolioUrl: map['portfolio_url'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  StudentProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? college,
    String? degree,
    String? branch,
    String? currentSemester,
    String? graduationYear,
    String? targetJobRole,
    String? githubUrl,
    String? linkedinUrl,
    String? portfolioUrl,
    String? bio,
    String? updatedAt,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      college: college ?? this.college,
      degree: degree ?? this.degree,
      branch: branch ?? this.branch,
      currentSemester: currentSemester ?? this.currentSemester,
      graduationYear: graduationYear ?? this.graduationYear,
      targetJobRole: targetJobRole ?? this.targetJobRole,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      bio: bio ?? this.bio,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
