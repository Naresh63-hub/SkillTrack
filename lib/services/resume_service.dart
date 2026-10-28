import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/student_profile.dart';
import '../models/education.dart';
import '../models/skill.dart';
import '../models/project.dart';
import '../models/certificate.dart';
import '../models/achievement.dart';

class ResumeData {
  final StudentProfile profile;
  final List<Education> education;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Certificate> certificates;
  final List<Achievement> achievements;

  ResumeData({
    required this.profile,
    required this.education,
    required this.skills,
    required this.projects,
    required this.certificates,
    required this.achievements,
  });
}

class ResumeService {
  /// Builds a clean, ATS-compliant professional PDF resume.
  static Future<Uint8List> generateResumePdf(ResumeData data) async {
    final pdf = pw.Document();

    final profile = data.profile;
    final primaryColor = PdfColor.fromHex('#21133F');
    final accentColor = PdfColor.fromHex('#6D28D9');
    final textDark = PdfColor.fromHex('#1F2937');
    final textMuted = PdfColor.fromHex('#4B5563');

    // Group skills by category
    final skillsByCategory = <String, List<String>>{};
    for (final s in data.skills) {
      skillsByCategory.putIfAbsent(s.category, () => []).add(s.name);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: accentColor, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (profile.targetJobRole.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      profile.targetJobRole,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 6),
                  pw.Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (profile.email.isNotEmpty)
                        pw.Text(profile.email,
                            style:
                                pw.TextStyle(fontSize: 9.5, color: textMuted)),
                      if (profile.phone.isNotEmpty)
                        pw.Text(profile.phone,
                            style:
                                pw.TextStyle(fontSize: 9.5, color: textMuted)),
                      if (profile.city.isNotEmpty)
                        pw.Text(profile.city,
                            style:
                                pw.TextStyle(fontSize: 9.5, color: textMuted)),
                      if (profile.githubUrl.isNotEmpty)
                        pw.Text(profile.githubUrl,
                            style:
                                pw.TextStyle(fontSize: 9.5, color: textMuted)),
                      if (profile.linkedinUrl.isNotEmpty)
                        pw.Text(profile.linkedinUrl,
                            style:
                                pw.TextStyle(fontSize: 9.5, color: textMuted)),
                    ],
                  ),
                ],
              ),
            ),

            // Professional Summary
            if (profile.bio.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _buildSectionTitle('PROFESSIONAL SUMMARY', accentColor),
              pw.SizedBox(height: 4),
              pw.Text(
                profile.bio,
                style:
                    pw.TextStyle(fontSize: 10, color: textDark, lineSpacing: 2),
              ),
            ],

            // Education
            if (data.education.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildSectionTitle('EDUCATION', accentColor),
              pw.SizedBox(height: 6),
              ...data.education.map((edu) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              edu.institution,
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            pw.Text(
                              '${edu.degree} in ${edu.fieldOfStudy}',
                              style:
                                  pw.TextStyle(fontSize: 9.5, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '${edu.startYear} - ${edu.endYear}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: textMuted,
                            ),
                          ),
                          if (edu.gradeOrCgpa != null &&
                              edu.gradeOrCgpa!.isNotEmpty)
                            pw.Text(
                              edu.gradeOrCgpa!,
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Technical Skills
            if (skillsByCategory.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildSectionTitle('TECHNICAL SKILLS', accentColor),
              pw.SizedBox(height: 6),
              ...skillsByCategory.entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${entry.key}: ',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        pw.TextSpan(
                          text: entry.value.join(', '),
                          style: pw.TextStyle(fontSize: 9.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // Projects
            if (data.projects.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildSectionTitle('KEY PROJECTS', accentColor),
              pw.SizedBox(height: 6),
              ...data.projects.map((proj) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            proj.name,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          if (proj.status.isNotEmpty)
                            pw.Text(
                              proj.status,
                              style:
                                  pw.TextStyle(fontSize: 9, color: accentColor),
                            ),
                        ],
                      ),
                      if (proj.technologies.isNotEmpty)
                        pw.Text(
                          'Technologies: ${proj.technologies.join(', ')}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: textMuted,
                          ),
                        ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        proj.shortDescription,
                        style: pw.TextStyle(fontSize: 9.5, color: textDark),
                      ),
                      if (proj.keyFeatures != null &&
                          proj.keyFeatures!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        ...proj.keyFeatures!
                            .split('\n')
                            .where((l) => l.trim().isNotEmpty)
                            .map((feat) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 8, top: 1),
                            child: pw.Text('• $feat',
                                style: pw.TextStyle(
                                    fontSize: 8.5, color: textMuted)),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ],

            // Certifications
            if (data.certificates.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildSectionTitle('CERTIFICATIONS', accentColor),
              pw.SizedBox(height: 6),
              ...data.certificates.map((cert) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              cert.name,
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            pw.Text(
                              cert.issuingOrganization,
                              style:
                                  pw.TextStyle(fontSize: 8.5, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        cert.completionDate,
                        style: pw.TextStyle(fontSize: 9, color: textMuted),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Achievements
            if (data.achievements.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildSectionTitle('HONORS & ACHIEVEMENTS', accentColor),
              pw.SizedBox(height: 6),
              ...data.achievements.map((ach) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ${ach.title}',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      if (ach.description != null &&
                          ach.description!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: pw.Text(
                            ach.description!,
                            style:
                                pw.TextStyle(fontSize: 8.5, color: textMuted),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: color, width: 1),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
