import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/portfolio_data.dart';

class PortfolioPdfService {
  /// Generates a high-quality Student Portfolio Card PDF summary suitable
  /// for printing, attaching to emails, or recruiter review.
  static Future<Uint8List> generatePortfolioPdf(PortfolioData data) async {
    final pdf = pw.Document();

    final profile = data.profile;
    final primaryColor = PdfColor.fromHex('#21133F');
    final accentPurple = PdfColor.fromHex('#7C3AED');
    final emeraldGreen = PdfColor.fromHex('#059669');
    final textDark = PdfColor.fromHex('#111827');
    final textMuted = PdfColor.fromHex('#4B5563');
    final bgLight = PdfColor.fromHex('#F9FAFB');
    final borderCol = PdfColor.fromHex('#E5E7EB');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Top Header: Badge & Student Info
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: bgLight,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderCol, width: 1),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: accentPurple,
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                'SKILLTRACK VERIFIED STUDENT CARD',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: emeraldGreen,
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Text(
                                'ACTIVE PORTFOLIO',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          profile.name.isNotEmpty ? profile.name : 'Student Name',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          profile.targetJobRole.isNotEmpty
                              ? profile.targetJobRole
                              : 'Aspiring Software Engineer',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: accentPurple,
                          ),
                        ),
                        if (profile.college.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${profile.degree.isNotEmpty ? "${profile.degree} | " : ""}${profile.college}${profile.graduationYear.isNotEmpty ? " (Class of ${profile.graduationYear})" : ""}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Public Portfolio Link:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'https://skill-track-ashy.vercel.app/#/p/${data.handle}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: accentPurple,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                      if (profile.email.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          profile.email,
                          style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                        ),
                      ],
                      if (profile.githubUrl.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          profile.githubUrl,
                          style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (profile.bio.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderCol, width: 0.8),
                ),
                child: pw.Text(
                  profile.bio,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: textDark,
                    lineSpacing: 1.3,
                  ),
                ),
              ),
            ],

            // Metrics Summary Row
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                _buildPdfMetric(
                  label: 'Verified Certs',
                  value: '${data.certificates.length}',
                  accentColor: emeraldGreen,
                  borderCol: borderCol,
                ),
                pw.SizedBox(width: 8),
                _buildPdfMetric(
                  label: 'Featured Projects',
                  value: '${data.projects.length}',
                  accentColor: accentPurple,
                  borderCol: borderCol,
                ),
                pw.SizedBox(width: 8),
                _buildPdfMetric(
                  label: 'Technical Skills',
                  value: '${data.skills.length}',
                  accentColor: primaryColor,
                  borderCol: borderCol,
                ),
              ],
            ),

            // Section: Verified Credentials & Certifications
            pw.SizedBox(height: 14),
            _buildPdfSectionHeader('VERIFIED CREDENTIALS & CERTIFICATES', accentPurple),
            pw.SizedBox(height: 6),
            if (data.certificates.isEmpty)
              pw.Text('No verified certificates on file.',
                  style: pw.TextStyle(fontSize: 9, color: textMuted))
            else
              ...data.certificates.take(4).map((c) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderCol, width: 0.5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              c.name,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Issued by ${c.issuingOrganization} | ${c.category}',
                              style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                            ),
                            if (c.credentialId != null && c.credentialId!.isNotEmpty)
                              pw.Text(
                                'Credential ID: ${c.credentialId}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: accentPurple,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            c.completionDate,
                            style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark),
                          ),
                          if (c.verificationUrl != null &&
                              c.verificationUrl!.isNotEmpty)
                            pw.Text(
                              'Verified Online',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: emeraldGreen,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            // Section: Featured Projects & Live Demos
            pw.SizedBox(height: 12),
            _buildPdfSectionHeader('FEATURED PROJECTS & LIVE DEMOS', accentPurple),
            pw.SizedBox(height: 6),
            if (data.projects.isEmpty)
              pw.Text('No projects listed.',
                  style: pw.TextStyle(fontSize: 9, color: textMuted))
            else
              ...data.projects.take(4).map((p) {
                final links = <String>[];
                if (p.liveDemoUrl != null && p.liveDemoUrl!.isNotEmpty) {
                  links.add('Demo: ${p.liveDemoUrl}');
                }
                if (p.vercelUrl != null && p.vercelUrl!.isNotEmpty) {
                  links.add('Vercel: ${p.vercelUrl}');
                }
                if (p.githubUrl != null && p.githubUrl!.isNotEmpty) {
                  links.add('Repo: ${p.githubUrl}');
                }
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: borderCol, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            p.name,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          pw.Text(
                            p.status,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: accentPurple,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        p.shortDescription,
                        style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                      ),
                      if (p.technologies.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Tech Stack: ${p.technologies.join(', ')}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: textDark,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                      if (links.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          links.join('  |  '),
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: accentPurple,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

            // Section: Core Technical Skills
            pw.SizedBox(height: 12),
            _buildPdfSectionHeader('CORE TECHNICAL SKILLS', accentPurple),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.skills.map((s) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: borderCol, width: 0.5),
                  ),
                  child: pw.Text(
                    '${s.name} (${s.proficiencyLevel})',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: textDark,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

            // Footer
            pw.SizedBox(height: 18),
            pw.Divider(color: borderCol, thickness: 0.8),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Verified via SkillTrack Career Platform',
                  style: pw.TextStyle(fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'https://skill-track-ashy.vercel.app/#/p/${data.handle}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: accentPurple,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfMetric({
    required String label,
    required String value,
    required PdfColor accentColor,
    required PdfColor borderCol,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderCol, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: color, width: 1.5),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
