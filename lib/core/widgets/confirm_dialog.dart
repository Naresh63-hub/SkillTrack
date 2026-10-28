import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Delete',
    this.confirmColor = AppColors.error,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Delete',
    Color confirmColor = AppColors.error,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.secondaryText)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
