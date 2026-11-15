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

/// Modern application certificate management: viewing, downloading, and rich sharing.
/// Emulates the gold standard of platforms like Coursera, Credly, and LinkedIn.
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
      BuildContext context, Certificate cert, [Uint8List? preloadedBytes]) async {
    final fileName = cert.fileName;
    try {
      final bytes = preloadedBytes ?? await getOrGenerateBytes(cert);

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

  /// Official 1-Click LinkedIn Add-To-Profile scheme
  static Future<void> addToLinkedInProfile(
      BuildContext context, Certificate cert) async {
    int? issueYear;
    int? issueMonth;
    try {
      final date = DateTime.tryParse(cert.completionDate);
      if (date != null) {
        issueYear = date.year;
        issueMonth = date.month;
      }
    } catch (_) {}

    int? expYear;
    int? expMonth;
    if (cert.expirationDate != null && cert.expirationDate!.isNotEmpty) {
      try {
        final expDate = DateTime.tryParse(cert.expirationDate!);
        if (expDate != null) {
          expYear = expDate.year;
          expMonth = expDate.month;
        }
      } catch (_) {}
    }

    final queryParams = <String, String>{
      'startTask': 'CERTIFICATION_NAME',
      'name': cert.name,
      'organizationName': cert.issuingOrganization,
      if (issueYear != null) 'issueYear': issueYear.toString(),
      if (issueMonth != null) 'issueMonth': issueMonth.toString(),
      if (expYear != null) 'expirationYear': expYear.toString(),
      if (expMonth != null) 'expirationMonth': expMonth.toString(),
      if (cert.credentialId != null && cert.credentialId!.isNotEmpty)
        'certId': cert.credentialId!,
      if (cert.hasVerificationUrl)
        'certUrl': cert.verificationUrl!
      else
        'certUrl': 'https://skill-track-ashy.vercel.app',
    };

    final uri = Uri.https('www.linkedin.com', '/profile/add', queryParams);
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

  /// Shares achievement to LinkedIn Feed / Post
  static Future<void> shareToLinkedInFeed(
      BuildContext context, Certificate cert) async {
    final shareUrl = cert.hasVerificationUrl
        ? cert.verificationUrl!
        : 'https://skill-track-ashy.vercel.app';
    final uri = Uri.https('www.linkedin.com', '/sharing/share-offsite/', {
      'url': shareUrl,
    });
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

  /// Shares achievement to X / Twitter
  static Future<void> shareToTwitter(
      BuildContext context, Certificate cert) async {
    final text =
        'Excited to share that I earned the "${cert.name}" credential issued by ${cert.issuingOrganization}! 🎓⚡ Verified on #SkillTrack #CareerReady';
    final shareUrl = cert.hasVerificationUrl
        ? cert.verificationUrl!
        : 'https://skill-track-ashy.vercel.app';
    final uri = Uri.https('twitter.com', '/intent/tweet', {
      'text': text,
      'url': shareUrl,
    });
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Twitter/X.')),
        );
      }
    }
  }

  /// Directly shares the certificate document file (PDF or Image)
  static Future<void> shareDocumentFileDirect(
    BuildContext context,
    Certificate cert, {
    Uint8List? preloadedBytes,
    String? preloadedDataUri,
  }) async {
    try {
      final bytes = preloadedBytes ?? await getOrGenerateBytes(cert);
      final fileName = cert.fileName;
      if (kIsWeb) {
        final mime = cert.isImage ? 'image/png' : 'application/pdf';
        final dataUri = preloadedDataUri ??
            'data:$mime;name=${Uri.encodeComponent(fileName)};base64,${base64Encode(bytes)}';
        final shared = await shareWebFile(
          dataUri,
          fileName,
          title: cert.name,
          text: cert.shareSummary,
        );
        if (!shared && context.mounted) {
          await downloadWebFile(dataUri, fileName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Downloaded "$fileName". You can attach it directly into your chat!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
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

  /// Sends the formatted rich text message to WhatsApp
  static Future<void> sendWhatsAppTextMessage(
      BuildContext context, Certificate cert) async {
    final text = Uri.encodeComponent(cert.modernShareSummary);
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

  /// Presents WhatsApp sharing options: Send PDF / Image Document or Send Formatted Message Card
  static Future<void> shareToWhatsApp(
      BuildContext context, Certificate cert) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WhatsAppShareSheet(certificate: cert),
    );
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

  /// Opens the modern Share bottom sheet
  static void showShareDialog(BuildContext context, Certificate cert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
            tooltip: 'Share Certificate',
            onPressed: () =>
                DocumentActionHelper.showShareDialog(context, certificate),
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
            tooltip: 'Share Certificate',
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

/// Modern interactive Bottom Sheet for sharing certificates, offer letters, and credentials.
/// Emulates modern apps (Coursera, Credly, LinkedIn) with zero-latency file sharing,
/// 1-click LinkedIn profile import, WhatsApp card formatting, and social broadcast.
class ShareCredentialSheet extends StatefulWidget {
  final Certificate certificate;

  const ShareCredentialSheet({super.key, required this.certificate});

  @override
  State<ShareCredentialSheet> createState() => _ShareCredentialSheetState();
}

class _ShareCredentialSheetState extends State<ShareCredentialSheet> {
  Uint8List? _preparedBytes;
  String? _preparedDataUri;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _prepareDocumentData();
  }

  Future<void> _prepareDocumentData() async {
    try {
      final bytes =
          await DocumentActionHelper.getOrGenerateBytes(widget.certificate);
      final fileName = widget.certificate.fileName;
      final mime =
          widget.certificate.isImage ? 'image/png' : 'application/pdf';
      final base64Content = base64Encode(bytes);
      final dataUri =
          'data:$mime;name=${Uri.encodeComponent(fileName)};base64,$base64Content';

      if (mounted) {
        setState(() {
          _preparedBytes = bytes;
          _preparedDataUri = dataUri;
        });
      }
    } catch (_) {}
  }

  /// Triggers instant file share preserving the browser/mobile user gesture
  Future<void> _handleFileShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      Uint8List? bytes = _preparedBytes;
      String? dataUri = _preparedDataUri;

      if (bytes == null || dataUri == null) {
        bytes =
            await DocumentActionHelper.getOrGenerateBytes(widget.certificate);
        final fileName = widget.certificate.fileName;
        final mime =
            widget.certificate.isImage ? 'image/png' : 'application/pdf';
        dataUri =
            'data:$mime;name=${Uri.encodeComponent(fileName)};base64,${base64Encode(bytes)}';
      }

      final fileName = widget.certificate.fileName;

      if (kIsWeb) {
        // Modern Web Share API with attached document file
        final shared = await shareWebFile(
          dataUri,
          fileName,
          title: widget.certificate.name,
          text: widget.certificate.shareSummary,
        );

        if (!shared && mounted) {
          // Fallback to downloading so user can manually attach
          await downloadWebFile(dataUri, fileName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Downloaded "$fileName". You can now attach and share it directly!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Native Android/iOS: Launches system ACTION_SEND sheet with attached document
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share file: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareViaEmail(BuildContext context) async {
    final subject =
        Uri.encodeComponent('Verified Credential: ${widget.certificate.name}');
    final body = Uri.encodeComponent(widget.certificate.modernShareSummary);
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
    final cert = widget.certificate;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: AppColors.brightAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Share Credential',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 22, color: AppColors.mutedText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Modern Certificate Badge Card (Social Preview)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cert.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 15, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cert.name,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Issued by ${cert.issuingOrganization}',
                    style: const TextStyle(
                      color: AppColors.brightAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed: ${cert.completionDate}',
                        style: const TextStyle(
                            color: AppColors.mutedText, fontSize: 11),
                      ),
                      if (cert.credentialId != null &&
                          cert.credentialId!.isNotEmpty)
                        Text(
                          'ID: ${cert.credentialId}',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PRIMARY HERO ACTION: TOTAL FILE SHARING
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brightAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isSharing
                      ? 'Opening Share Sheet...'
                      : 'Share Document File (PDF / Image)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                onPressed: _isSharing ? null : _handleFileShare,
              ),
            ),
            const SizedBox(height: 14),

            // PROFESSIONAL & SOCIAL CHANNELS
            const Text(
              'Share To Professional & Social Networks:',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Official 1-Click LinkedIn Add to Profile Button (Gold standard)
            InkWell(
              onTap: () =>
                  DocumentActionHelper.addToLinkedInProfile(context, cert),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0077B5).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.badge_rounded,
                        color: Color(0xFF0077B5), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to LinkedIn Profile',
                            style: TextStyle(
                              color: Color(0xFF0077B5),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '1-click official certification import',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: Color(0xFF0077B5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Network Buttons: WhatsApp, LinkedIn Feed, X/Twitter, Email
            Row(
              children: [
                Expanded(
                  child: _ModernSocialButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () =>
                        DocumentActionHelper.shareToWhatsApp(context, cert),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModernSocialButton(
                    icon: Icons.public_rounded,
                    label: 'LinkedIn Feed',
                    color: const Color(0xFF0077B5),
                    onTap: () =>
                        DocumentActionHelper.shareToLinkedInFeed(context, cert),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModernSocialButton(
                    icon: Icons.tag_rounded,
                    label: 'X (Twitter)',
                    color: const Color(0xFF1DA1F2),
                    onTap: () =>
                        DocumentActionHelper.shareToTwitter(context, cert),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModernSocialButton(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    color: AppColors.lightPurple,
                    onTap: () => _shareViaEmail(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // UTILITIES: Download, Copy Details, View Document
            const Divider(height: 1, thickness: 0.8, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded,
                        size: 16, color: AppColors.brightAccent),
                    label: const Text(
                      'Download PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brightAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => DocumentActionHelper.downloadDocument(
                        context, cert, _preparedBytes),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text(
                      'Copy Text',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: cert.modernShareSummary));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Formatted credential copied to clipboard!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
                if (cert.hasVerificationUrl) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: const Text(
                        'Copy Link',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: cert.verificationUrl!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification link copied!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModernSocialButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppShareSheet extends StatefulWidget {
  final Certificate certificate;

  const _WhatsAppShareSheet({required this.certificate});

  @override
  State<_WhatsAppShareSheet> createState() => _WhatsAppShareSheetState();
}

class _WhatsAppShareSheetState extends State<_WhatsAppShareSheet> {
  Uint8List? _preparedBytes;
  String? _preparedDataUri;

  @override
  void initState() {
    super.initState();
    _prewarmDocument();
  }

  Future<void> _prewarmDocument() async {
    try {
      final bytes =
          await DocumentActionHelper.getOrGenerateBytes(widget.certificate);
      final fileName = widget.certificate.fileName;
      final mime =
          widget.certificate.isImage ? 'image/png' : 'application/pdf';
      final base64Content = base64Encode(bytes);
      final dataUri =
          'data:$mime;name=${Uri.encodeComponent(fileName)};base64,$base64Content';
      if (mounted) {
        setState(() {
          _preparedBytes = bytes;
          _preparedDataUri = dataUri;
        });
      }
    } catch (_) {}
  }

  Future<void> _shareFile() async {
    final navigator = Navigator.of(context);
    final cert = widget.certificate;
    final bytes = _preparedBytes;
    final dataUri = _preparedDataUri;
    navigator.pop();
    await DocumentActionHelper.shareDocumentFileDirect(
      context,
      cert,
      preloadedBytes: bytes,
      preloadedDataUri: dataUri,
    );
  }

  Future<void> _shareMessage() async {
    final navigator = Navigator.of(context);
    final cert = widget.certificate;
    navigator.pop();
    await DocumentActionHelper.sendWhatsAppTextMessage(context, cert);
  }

  @override
  Widget build(BuildContext context) {
    const waGreen = Color(0xFF25D366);
    final isPdf = widget.certificate.isPdf;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: waGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: waGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share to WhatsApp',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select how you want to share this credential',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.mutedText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Option 1: Send Document File (PDF / Image)
            InkWell(
              onTap: _shareFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: waGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: waGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: waGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isPdf
                                    ? 'Send PDF Document'
                                    : 'Send Image Document',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: waGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'File',
                                  style: TextStyle(
                                    color: waGreen,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Attach the verified ${isPdf ? "PDF certificate" : "document file"} directly into WhatsApp chat',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: waGreen,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Send Formatted Message Card
            InkWell(
              onTap: _shareMessage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.text_snippet_rounded,
                        color: AppColors.lightPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Send Formatted Message Card',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lightPurple
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Text',
                                  style: TextStyle(
                                    color: AppColors.lightPurple,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Share rich card with bold title, issuing org, credential ID & verification link',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
