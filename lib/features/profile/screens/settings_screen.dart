import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/sample_data.dart';
import '../../../services/export_import_service.dart';
import 'database_tables_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExportImportService _exportImportService = ExportImportService();

  bool _notificationsEnabled = true;
  bool _isProcessing = false;

  Future<void> _exportData() async {
    setState(() => _isProcessing = true);
    try {
      final jsonStr = await _exportImportService.exportDataToJson();
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Data Backup Exported'),
            content: const Text(
              'Your entire SkillTrack SQLite database has been successfully compiled into a structured JSON backup and copied to your clipboard!\n\nYou can paste and save it as a backup file.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importData() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your previously exported SkillTrack JSON backup below. This will replace existing database records atomically.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{\n  "app": "SkillTrack",\n  "data": { ... }\n}',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      setState(() => _isProcessing = true);
      final success =
          await _exportImportService.importDataFromJson(controller.text.trim());
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Database restored successfully!'
                : 'Invalid JSON backup format.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadDemoData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Load Portfolio Demo Data',
      content:
          'This will populate SkillTrack with comprehensive demonstration records for a final-year CS student (6 skills, 3 certificates, 3 projects, 5 tasks, DSA coding topics, core CS topics, and interview questions).\n\nExisting records will be overwritten. Proceed?',
      confirmText: 'Load Demo Data',
      confirmColor: AppColors.brightAccent,
    );

    if (confirmed) {
      setState(() => _isProcessing = true);
      await SampleData.loadDemoData();
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Demo data loaded successfully! All modules populated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reset All Local Data',
      content:
          'DANGER: This will permanently delete all skills, certificates, projects, tasks, and placement preparation records from your SQLite database.\n\nAre you sure you want to proceed?',
      confirmText: 'Delete Everything',
      confirmColor: AppColors.error,
    );

    if (confirmed) {
      setState(() => _isProcessing = true);
      await DatabaseHelper.instance.clearAllData();
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been cleared from local database.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // College Demo Data Banner
            CustomCard(
              gradient: AppColors.elevatedGradient,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school,
                          color: AppColors.brightAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'College Evaluation & Demo',
                        style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quickly load a rich, realistic B.Tech Computer Science profile to showcase all features, progress analytics, and ATS resume compilation during live presentation.',
                    style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brightAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Load Comprehensive Demo Data'),
                    onPressed: _isProcessing ? null : _loadDemoData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Preferences',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Task Reminders & Notifications',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13.5)),
                    subtitle: const Text(
                        'Receive Android local notifications for scheduled deadlines',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 11)),
                    value: _notificationsEnabled,
                    activeColor: AppColors.brightAccent,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme Direction',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13.5)),
                    subtitle: const Text('Dark Purple Developer Theme (Active)',
                        style: TextStyle(
                            color: AppColors.secondaryAccent, fontSize: 11.5)),
                    trailing: const Icon(Icons.palette,
                        color: AppColors.brightAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data Management
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup & Storage',
                      style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.primaryAccent),
                    title: const Text('Export JSON Database Backup',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13.5)),
                    subtitle: const Text(
                        'Exports all SQLite tables to a portable JSON backup',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 11)),
                    onTap: _isProcessing ? null : _exportData,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_download_outlined,
                        color: AppColors.brightAccent),
                    title: const Text('Restore from JSON Backup',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13.5)),
                    subtitle: const Text(
                        'Import database records from a verified JSON backup',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 11)),
                    onTap: _isProcessing ? null : _importData,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.table_chart_rounded,
                        color: AppColors.secondaryAccent),
                    title: const Text('Database Tables (Schema Overview)',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13.5)),
                    subtitle: const Text(
                        'Inspect local SQLite tables and live record counts',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.mutedText),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DatabaseTablesScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever,
                        color: AppColors.error),
                    title: const Text('Reset All Local Data',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Clears all tables in SQLite permanently',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 11)),
                    onTap: _isProcessing ? null : _resetAllData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy & Architecture Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Offline-First Architecture & Privacy',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 100% Offline: SkillTrack operates completely locally without external cloud databases, user tracking, or telemetry.\n'
                    '• Structured SQLite: All your skills, certificates, projects, and interview questions remain in application-private storage on this device.\n'
                    '• Document Safety: Attached certificate PDFs and images are copied into application-managed documents storage so they persist safely across cache clears.\n'
                    '• Data Retention: Uninstalling the application or clearing device storage will remove local records unless exported via JSON backup.',
                    style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                        height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About Application
            const Center(
              child: Column(
                children: [
                  Text(
                    'SkillTrack v1.0.0',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppStrings.appTagline,
                    style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Built with Flutter & SQLite for B.Tech Skill Development Course',
                    style: TextStyle(
                        color: AppColors.secondaryAccent, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
