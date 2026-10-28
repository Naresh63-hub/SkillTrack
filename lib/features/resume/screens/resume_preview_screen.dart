import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';

class ResumePreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const ResumePreviewScreen({
    super.key,
    required this.pdfBytes,
    this.fileName = 'SkillTrack_Resume.pdf',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume PDF Preview'),
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        pdfFileName: fileName,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppColors.secondaryBackground,
          iconColor: AppColors.primaryText,
        ),
      ),
    );
  }
}
