import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../constants/app_colors.dart';
import '../../models/certificate.dart';
import 'web_file_downloader.dart';

/// Universal helper to View, Download, and Share certificate and offer letter documents.
/// Guarantees that EVERY certificate always has a viewable, downloadable, and shareable document.
class DocumentActionHelper {
  /// Extracts raw byte data from a Certificate's localFilePath.
  /// Handles Web Data URIs, Network URLs, and Native local file paths.
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

  /// Generates an official, beautifully styled Verified Digital Credential PDF document.
  static Future<Uint8List> generateCertificatePdf(Certificate cert) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#4C1D95'); // Deep Violet
    final accentColor = PdfColor.fromHex('#7C3AED'); // Vibrant Purple
    final goldColor = PdfColor.fromHex('#D97706'); // Amber / Gold
    final textColor = PdfColor.fromHex('#1E1B4B');
    final mutedColor = PdfColor.fromHex('#6B7280');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 3.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: goldColor, width: 1.2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SKILLTRACK VERIFIED CREDENTIAL',
                            style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Official Academic & Career Verification Record',
                            style: pw.TextStyle(
                                color: mutedColor, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#EDE9FE'),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          cert.category.toUpperCase(),
                          style: pw.TextStyle(
                            color: accentColor,
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Certificate Details
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'This document certifies completion and record of',
                        style: pw.TextStyle(
                          color: mutedColor,
                          fontSize: 11.5,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        cert.name,
                        style: pw.TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Issued by ${cert.issuingOrganization}',
                        style: pw.TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (cert.description != null &&
                          cert.description!.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Container(
                          constraints: const pw.BoxConstraints(maxWidth: 520),
                          child: pw.Text(
                            cert.description!,
                            style: pw.TextStyle(
                                color: textColor, fontSize: 9.5),
                            textAlign: pw.TextAlign.center,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom Metadata & Verification
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Completion Date: ${cert.completionDate}',
                              style: pw.TextStyle(
                                  color: textColor, fontSize: 9.5)),
                          if (cert.expirationDate != null &&
                              cert.expirationDate!.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Valid Until: ${cert.expirationDate}',
                                style: pw.TextStyle(
                                    color: mutedColor, fontSize: 9)),
                          ],
                          if (cert.credentialId != null &&
                              cert.credentialId!.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Credential ID: ${cert.credentialId}',
                                style: pw.TextStyle(
                                    color: mutedColor, fontSize: 9)),
                          ],
                          if (cert.hasVerificationUrl) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Verification: ${cert.verificationUrl}',
                                style: pw.TextStyle(
                                    color: accentColor, fontSize: 8.5)),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              border:
                                  pw.Border.all(color: goldColor, width: 1),
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(6)),
                            ),
                            child: pw.Text(
                              'VERIFIED BY SKILLTRACK',
                              style: pw.TextStyle(
                                color: goldColor,
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'https://skill-track-ashy.vercel.app',
                            style:
                                pw.TextStyle(color: mutedColor, fontSize: 7.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Returns uploaded document bytes or generates an official verified PDF credential
  static Future<Uint8List> getOrGenerateBytes(Certificate cert) async {
    final existing = getBytes(cert);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return await generateCertificatePdf(cert);
  }

  /// Downloads the certificate document (PDF or Image) to the user's device
  static Future<void> downloadDocument(
      BuildContext context, Certificate cert) async {
    final fileName = cert.fileName;
    try {
      final bytes = await getOrGenerateBytes(cert);

      if (kIsWeb) {
        final mime = cert.isImage ? 'image/png' : 'application/pdf';
        final base64Content = base64Encode(bytes);
        final dataUri =
            'data:$mime;name=${Uri.encodeComponent(fileName)};base64,$base64Content';

        final downloaded = await downloadWebFile(dataUri, fileName);
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
      }

      // Native (Android/iOS)
      if (cert.isPdf || !cert.hasFile) {
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

  /// Shares the actual document file (Total File Share)
  static Future<void> shareDocumentFile(
      BuildContext context, Certificate cert) async {
    final fileName = cert.fileName;
    try {
      final bytes = await getOrGenerateBytes(cert);

      if (kIsWeb) {
        final mime = cert.isImage ? 'image/png' : 'application/pdf';
        final base64Content = base64Encode(bytes);
        final dataUri =
            'data:$mime;name=${Uri.encodeComponent(fileName)};base64,$base64Content';

        // 1. Try modern Web Share API with attached file
        final shared = await shareWebFile(
          dataUri,
          fileName,
          title: cert.name,
          text: cert.shareSummary,
        );

        if (!shared) {
          // If browser doesn't support file sharing, trigger download
          await downloadWebFile(dataUri, fileName);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Downloaded "$fileName". You can now attach and send it directly!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        return;
      }

      // Native (Android/iOS): Invokes native Android share sheet with file
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share file: $e'),
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
    if (cert.hasFile && cert.isImage) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ImageDocumentViewerScreen(certificate: cert),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfDocumentViewerScreen(certificate: cert),
        ),
      );
    }
  }

  /// Opens the Share bottom sheet with full file and direct sharing options
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

/// Fullscreen interactive PDF viewer with page controls, zoom, print, and browser open
class PdfDocumentViewerScreen extends StatelessWidget {
  final Certificate certificate;

  const PdfDocumentViewerScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
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
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open in Browser Tab',
              onPressed: () async {
                final bytes =
                    await DocumentActionHelper.getOrGenerateBytes(certificate);
                final base64Content = base64Encode(bytes);
                final dataUri =
                    'data:application/pdf;name=${Uri.encodeComponent(certificate.fileName)};base64,$base64Content';
                openWebFileInNewTab(dataUri);
              },
            ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: () =>
                DocumentActionHelper.downloadDocument(context, certificate),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Document File',
            onPressed: () =>
                DocumentActionHelper.shareDocumentFile(context, certificate),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: DocumentActionHelper.getOrGenerateBytes(certificate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brightAccent),
            );
          }
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image,
                        size: 48, color: AppColors.mutedText),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to render document preview.',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => DocumentActionHelper.downloadDocument(
                          context, certificate),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download PDF Document'),
                    ),
                  ],
                ),
              ),
            );
          }

          return PdfPreview(
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
          );
        },
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
            tooltip: 'Share Document File',
            onPressed: () =>
                DocumentActionHelper.shareDocumentFile(context, certificate),
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

/// Bottom Sheet for sharing certificates, offer letters, and credentials.
/// Offers direct TOTAL FILE SHARING (sharing the actual PDF/image file) + text summary.
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
                    'Share Credential & Document',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16.5,
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
                      const SizedBox(height: 2),
                      Text(
                        'File: ${certificate.fileName}',
                        style: const TextStyle(
                          color: AppColors.lightPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

          // PRIMARY PROMINENT ACTION: SHARE TOTAL FILE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Share Total Document File (PDF / Image)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                DocumentActionHelper.shareDocumentFile(context, certificate);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Action Buttons: Download & Copy Text Details
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(
                      color: AppColors.brightAccent.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded,
                      size: 16, color: AppColors.brightAccent),
                  label: const Text(
                    'Download File',
                    style: TextStyle(
                      color: AppColors.brightAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    DocumentActionHelper.downloadDocument(context, certificate);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy Text',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: certificate.shareSummary));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Credential details copied to clipboard!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
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

          // Direct Channels
          const Text(
            'Quick Message Share:',
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
