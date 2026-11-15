import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../constants/app_colors.dart';
import '../../models/certificate.dart';
import 'web_file_downloader.dart';

/// Universal helper to View, Download, and Share certificate and offer letter documents
class DocumentActionHelper {
  /// Extracts raw byte data from a Certificate's localFilePath
  /// Handles both Web Data URIs and Native local file paths.
  static Uint8List? getBytes(Certificate cert) {
    if (!cert.hasFile) return null;
    final path = cert.localFilePath!;
    try {
      if (path.startsWith('data:')) {
        final commaIdx = path.indexOf(',');
        if (commaIdx == -1) return null;
        final base64Content = path.substring(commaIdx + 1);
        return base64Decode(base64Content);
      } else if (!kIsWeb) {
        final file = File(path);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      }
    } catch (e) {
      debugPrint('DocumentActionHelper: Failed to get document bytes: $e');
    }
    return null;
  }

  /// Downloads the certificate document (PDF or Image) to user's device
  static Future<void> downloadDocument(
      BuildContext context, Certificate cert) async {
    if (!cert.hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document file attached to this credential.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final path = cert.localFilePath!;
    final fileName = cert.fileName;

    try {
      if (kIsWeb) {
        // On Web: Trigger browser download using the data URI or bytes
        if (path.startsWith('data:')) {
          final downloaded = await downloadWebFile(path, fileName);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(downloaded
                    ? 'Downloading "$fileName"...'
                    : 'Download initiated for "$fileName"'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
              ),
            );
          }
          return;
        } else {
          // If it's an external or blob url
          await launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Native (Android/iOS)
      final bytes = getBytes(cert);
      if (bytes == null) {
        throw Exception('Could not read file data from local storage.');
      }

      if (cert.isPdf) {
        // Printing.sharePdf allows saving directly to device Downloads or Drive
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saving "$fileName"...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Save image to downloads / documents
        Directory? targetDir;
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
        targetDir ??= await getApplicationDocumentsDirectory();

        final savedFile = File(p.join(targetDir.path, fileName));
        await savedFile.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to: ${savedFile.path}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => launchUrl(Uri.file(savedFile.path)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not download file: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Views the certificate document (Opens PDF viewer or Fullscreen Image viewer)
  static Future<void> viewDocument(
      BuildContext context, Certificate cert) async {
    if (cert.isPdf) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfDocumentViewerScreen(certificate: cert),
        ),
      );
    } else if (cert.isImage) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ImageDocumentViewerScreen(certificate: cert),
        ),
      );
    } else if (cert.hasVerificationUrl) {
      final uri = Uri.tryParse(cert.verificationUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document or verification link attached to view.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Opens the Share bottom sheet with multiple sharing options
  static void showShareDialog(BuildContext context, Certificate cert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ShareCredentialSheet(certificate: cert),
    );
  }
}

/// Fullscreen interactive PDF viewer with page controls, zoom, print, and share
class PdfDocumentViewerScreen extends StatelessWidget {
  final Certificate certificate;

  const PdfDocumentViewerScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    final bytes = DocumentActionHelper.getBytes(certificate);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text(
          certificate.name,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: () =>
                DocumentActionHelper.downloadDocument(context, certificate),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Credential',
            onPressed: () =>
                DocumentActionHelper.showShareDialog(context, certificate),
          ),
        ],
      ),
      body: bytes != null
          ? PdfPreview(
              build: (format) => bytes,
              pdfFileName: certificate.fileName,
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: AppColors.secondaryBackground,
                iconColor: AppColors.primaryText,
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image,
                        size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to render PDF preview.',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You can still download the document to view it.',
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => DocumentActionHelper.downloadDocument(
                          context, certificate),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Fullscreen interactive Image viewer with pinch-to-zoom and pan
class ImageDocumentViewerScreen extends StatelessWidget {
  final Certificate certificate;

  const ImageDocumentViewerScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    final filePath = certificate.localFilePath ?? '';
    final isDataUri = filePath.startsWith('data:image/');
    final bytes = DocumentActionHelper.getBytes(certificate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          certificate.name,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download Image',
            onPressed: () =>
                DocumentActionHelper.downloadDocument(context, certificate),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share Credential',
            onPressed: () =>
                DocumentActionHelper.showShareDialog(context, certificate),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.5,
          child: isDataUri && bytes != null
              ? Image.memory(bytes, fit: BoxFit.contain)
              : (kIsWeb
                  ? Image.network(
                      filePath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.white54,
                      ),
                    )
                  : Image.file(
                      File(filePath),
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.white54,
                      ),
                    )),
        ),
      ),
    );
  }
}

/// Bottom Sheet for sharing certificates, offer letters, and credentials
class ShareCredentialSheet extends StatelessWidget {
  final Certificate certificate;

  const ShareCredentialSheet({super.key, required this.certificate});

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(certificate.shareSummary);
    final uri = Uri.parse('https://wa.me/?text=$text');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  Future<void> _shareOnLinkedIn(BuildContext context) async {
    final shareUrl = certificate.verificationUrl ??
        'https://skill-track-ashy.vercel.app';
    final uri = Uri.parse(
        'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(shareUrl)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open LinkedIn.')),
        );
      }
    }
  }

  Future<void> _shareViaEmail(BuildContext context) async {
    final subject = Uri.encodeComponent('Credential: ${certificate.name}');
    final body = Uri.encodeComponent(certificate.shareSummary);
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.share_rounded,
                      color: AppColors.primaryPurple, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Share Credential',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 20, color: AppColors.mutedText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Certificate Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    certificate.isPdf
                        ? Icons.picture_as_pdf_rounded
                        : (certificate.isImage
                            ? Icons.image_rounded
                            : Icons.verified_rounded),
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.name,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${certificate.issuingOrganization} • ${certificate.category}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (certificate.hasFile) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Attachment: ${certificate.fileName}',
                          style: const TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Details'),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: certificate.shareSummary));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Credential details copied to clipboard!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              if (certificate.hasFile) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download File'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      DocumentActionHelper.downloadDocument(
                          context, certificate);
                    },
                  ),
                ),
              ],
            ],
          ),
          if (certificate.hasVerificationUrl) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Copy Verification URL'),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: certificate.verificationUrl!));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification URL copied!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Quick Share Channels
          const Text(
            'Share Directly To:',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ShareChannelButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _shareOnWhatsApp(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShareChannelButton(
                  icon: Icons.work_outline_rounded,
                  label: 'LinkedIn',
                  color: const Color(0xFF0077B5),
                  onTap: () => _shareOnLinkedIn(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShareChannelButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  color: AppColors.lightPurple,
                  onTap: () => _shareViaEmail(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareChannelButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
