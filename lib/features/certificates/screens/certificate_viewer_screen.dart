import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/certificate.dart';

class CertificateViewerScreen extends StatelessWidget {
  final Certificate certificate;

  const CertificateViewerScreen({super.key, required this.certificate});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open verification link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = certificate.hasFile;
    final filePath = certificate.localFilePath ?? '';
    final isImage = hasFile && FileUtils.isImageFile(filePath);
    final isPdf = hasFile && FileUtils.isPdfFile(filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(certificate.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Section
            if (hasFile && isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  color: AppColors.cardBackground,
                  child: kIsWeb
                      ? Image.network(
                          filePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: AppColors.mutedText),
                                SizedBox(height: 8),
                                Text('Image file moved or deleted',
                                    style: TextStyle(color: AppColors.mutedText)),
                              ],
                            ),
                          ),
                        )
                      : Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 40, color: AppColors.mutedText),
                                  SizedBox(height: 8),
                                  Text('Image file moved or deleted',
                                      style: TextStyle(color: AppColors.mutedText)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (hasFile && isPdf) ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: AppColors.error, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Certificate Document',
                            style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            filePath.split(RegExp(r'[/\\]')).last,
                            style: const TextStyle(
                                color: AppColors.mutedText, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Details Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          certificate.category,
                          style: const TextStyle(
                              color: AppColors.secondaryText, fontSize: 12),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.brightAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Recorded',
                            style: TextStyle(
                                color: AppColors.brightAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    certificate.name,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Issued by: ${certificate.issuingOrganization}',
                    style: const TextStyle(
                      color: AppColors.secondaryAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow('Date of Completion',
                      DateFormatter.format(certificate.completionDate)),
                  if (certificate.expirationDate != null &&
                      certificate.expirationDate!.isNotEmpty)
                    _buildDetailRow('Expiration Date',
                        DateFormatter.format(certificate.expirationDate)),
                  if (certificate.credentialId != null &&
                      certificate.credentialId!.isNotEmpty)
                    _buildDetailRow('Credential ID', certificate.credentialId!),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Verification Link
            if (certificate.hasVerificationUrl) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.open_in_browser, size: 20),
                label: const Text('Verify Credential Online'),
                onPressed: () =>
                    _launchUrl(context, certificate.verificationUrl!),
              ),
              const SizedBox(height: 12),
            ],

            // Description
            if (certificate.description != null &&
                certificate.description!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview & Competencies',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.description!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
