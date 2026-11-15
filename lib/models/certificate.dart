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

  /// Returns the document file name (or extracts it from data URI / path)
  String get fileName {
    if (!hasFile) return '';
    final path = localFilePath!;
    if (path.startsWith('data:')) {
      final match = RegExp(r'name=([^;]+);').firstMatch(path);
      if (match != null) {
        return Uri.decodeComponent(match.group(1)!);
      }
      return '${name.replaceAll(RegExp(r'[^\w\-]'), '_')}.${isPdf ? "pdf" : "png"}';
    }
    return path.split(RegExp(r'[/\\]')).last;
  }

  /// True if the attached document is a PDF
  bool get isPdf {
    if (!hasFile) return false;
    final path = localFilePath!;
    if (path.startsWith('data:application/pdf')) return true;
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf');
  }

  /// True if the attached document is an image (PNG, JPG, WebP)
  bool get isImage {
    if (!hasFile) return false;
    final path = localFilePath!;
    if (path.startsWith('data:image/')) return true;
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  /// Generates a clean, professional summary text suitable for sharing
  String get shareSummary {
    final buffer = StringBuffer();
    buffer.writeln('🎓 $name');
    buffer.writeln('🏢 Issued By: $issuingOrganization');
    buffer.writeln('📂 Category: $category');
    buffer.writeln('📅 Completion Date: $completionDate');
    if (credentialId != null && credentialId!.isNotEmpty) {
      buffer.writeln('🆔 Credential ID: $credentialId');
    }
    if (hasVerificationUrl) {
      buffer.writeln('🔗 Verification: $verificationUrl');
    }
    buffer.write('Verified on SkillTrack ⚡');
    return buffer.toString();
  }

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
