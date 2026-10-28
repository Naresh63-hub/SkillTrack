class Certificate {
  final int? id;
  final String name;
  final String issuingOrganization;
  final String category;
  final String completionDate;
  final String? expirationDate;
  final String? credentialId;
  final String? verificationUrl;
  final String? description;
  final String? localFilePath;
  final String? previewImagePath;
  final String createdAt;

  Certificate({
    this.id,
    required this.name,
    required this.issuingOrganization,
    required this.category,
    required this.completionDate,
    this.expirationDate,
    this.credentialId,
    this.verificationUrl,
    this.description,
    this.localFilePath,
    this.previewImagePath,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get hasFile => localFilePath != null && localFilePath!.isNotEmpty;
  bool get hasVerificationUrl =>
      verificationUrl != null && verificationUrl!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'issuing_organization': issuingOrganization,
      'category': category,
      'completion_date': completionDate,
      'expiration_date': expirationDate,
      'credential_id': credentialId,
      'verification_url': verificationUrl,
      'description': description,
      'local_file_path': localFilePath,
      'preview_image_path': previewImagePath,
      'created_at': createdAt,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      issuingOrganization: map['issuing_organization'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      completionDate: map['completion_date'] as String? ?? '',
      expirationDate: map['expiration_date'] as String?,
      credentialId: map['credential_id'] as String?,
      verificationUrl: map['verification_url'] as String?,
      description: map['description'] as String?,
      localFilePath: map['local_file_path'] as String?,
      previewImagePath: map['preview_image_path'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Certificate copyWith({
    int? id,
    String? name,
    String? issuingOrganization,
    String? category,
    String? completionDate,
    String? expirationDate,
    String? credentialId,
    String? verificationUrl,
    String? description,
    String? localFilePath,
    String? previewImagePath,
    String? createdAt,
  }) {
    return Certificate(
      id: id ?? this.id,
      name: name ?? this.name,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      category: category ?? this.category,
      completionDate: completionDate ?? this.completionDate,
      expirationDate: expirationDate ?? this.expirationDate,
      credentialId: credentialId ?? this.credentialId,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      description: description ?? this.description,
      localFilePath: localFilePath ?? this.localFilePath,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
