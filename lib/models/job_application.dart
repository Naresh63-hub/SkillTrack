class JobApplication {
  final int? id;
  final String companyName;
  final String role;
  final String applicationDate;
  final String? applicationDeadline;
  final String
      status; // 'Interested', 'Preparing', 'Applied', 'Assessment', 'Interview', 'Selected', 'Rejected', 'Withdrawn'
  final String? jobDescriptionUrl;
  final String? requiredSkills;
  final String? interviewDate;
  final String? notes;
  final String updatedAt;

  JobApplication({
    this.id,
    required this.companyName,
    required this.role,
    required this.applicationDate,
    this.applicationDeadline,
    this.status = 'Applied',
    this.jobDescriptionUrl,
    this.requiredSkills,
    this.interviewDate,
    this.notes,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  bool get hasUpcomingInterview {
    if (interviewDate == null || interviewDate!.isEmpty) return false;
    try {
      final interview = DateTime.parse(interviewDate!);
      return interview
          .isAfter(DateTime.now().subtract(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }

  bool get isDeadlineApproaching {
    if (applicationDeadline == null || applicationDeadline!.isEmpty)
      return false;
    if (status == 'Applied' ||
        status == 'Selected' ||
        status == 'Rejected' ||
        status == 'Withdrawn') {
      return false;
    }
    try {
      final deadline = DateTime.parse(applicationDeadline!);
      final now = DateTime.now();
      final diff = deadline.difference(now).inDays;
      return diff >= 0 && diff <= 5;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'role': role,
      'application_date': applicationDate,
      'application_deadline': applicationDeadline,
      'status': status,
      'job_description_url': jobDescriptionUrl,
      'required_skills': requiredSkills,
      'interview_date': interviewDate,
      'notes': notes,
      'updated_at': updatedAt,
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as int?,
      companyName: map['company_name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      applicationDate: map['application_date'] as String? ?? '',
      applicationDeadline: map['application_deadline'] as String?,
      status: map['status'] as String? ?? 'Applied',
      jobDescriptionUrl: map['job_description_url'] as String?,
      requiredSkills: map['required_skills'] as String?,
      interviewDate: map['interview_date'] as String?,
      notes: map['notes'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  JobApplication copyWith({
    int? id,
    String? companyName,
    String? role,
    String? applicationDate,
    String? applicationDeadline,
    String? status,
    String? jobDescriptionUrl,
    String? requiredSkills,
    String? interviewDate,
    String? notes,
    String? updatedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      applicationDate: applicationDate ?? this.applicationDate,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      status: status ?? this.status,
      jobDescriptionUrl: jobDescriptionUrl ?? this.jobDescriptionUrl,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      interviewDate: interviewDate ?? this.interviewDate,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
