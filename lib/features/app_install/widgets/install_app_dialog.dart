import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/app_install_service.dart';

class InstallAppDialog extends StatefulWidget {
  const InstallAppDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const InstallAppDialog(),
    );
  }

  @override
  State<InstallAppDialog> createState() => _InstallAppDialogState();
}

class _InstallAppDialogState extends State<InstallAppDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppInstallService _installService = AppInstallService.instance;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePwaInstall() async {
    final prompted = _installService.triggerInstall();
    if (prompted) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Follow the browser prompt to complete installation.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Installation prompt not directly triggerable. Please follow the step-by-step guide below for your browser!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.secondaryCard,
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadApk() async {
    setState(() => _isDownloading = true);
    final success = await _installService.downloadAndroidApk();
    if (mounted) {
      setState(() => _isDownloading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Starting Android APK download from GitHub Releases...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not initiate direct download. Opening GitHub Releases page...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _installService.openGitHubReleases();
      }
    }
  }

  void _copyShareLink() {
    Clipboard.setData(const ClipboardData(text: AppInstallService.liveWebUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SkillTrack web link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStandalone = _installService.isInstalledPWA;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: SizedBox(
        width: 580,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.install_mobile_rounded,
                            color: AppColors.lightPurple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Install & Download App',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Offline-ready on Android, iOS & Desktop',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.mutedText, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Standalone Status Pill
              if (isStandalone)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SkillTrack is running in standalone installed mode!',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main CTA Action Buttons
              Row(
                children: [
                  // Install / Add to Home screen
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_to_home_screen_rounded,
                          size: 18),
                      label: const Text(
                        'Install App',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _handlePwaInstall,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Download APK
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightPurple,
                        side: const BorderSide(color: AppColors.primaryPurple),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lightPurple,
                              ),
                            )
                          : const Icon(Icons.android_rounded, size: 18),
                      label: const Text(
                        'Download APK',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isDownloading ? null : _handleDownloadApk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Platform Guides Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryPurple,
                  indicatorWeight: 3,
                  labelColor: AppColors.primaryPurple,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.android, size: 16),
                      text: 'Android',
                    ),
                    Tab(
                      icon: Icon(Icons.apple, size: 16),
                      text: 'iPhone / iOS',
                    ),
                    Tab(
                      icon: Icon(Icons.laptop_chromebook_rounded, size: 16),
                      text: 'PC / Mac',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // TabBarView Guides
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAndroidGuide(),
                    _buildIosGuide(),
                    _buildDesktopGuide(),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 20),

              // Footer: Copy Link & Releases
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Copy Web Link',
                        style: TextStyle(fontSize: 12)),
                    onPressed: _copyShareLink,
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightPurple,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('GitHub Releases',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => _installService.openGitHubReleases(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidGuide() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            stepNumber: '1',
            title: 'Install as Progressive Web App (Fastest)',
            description:
                'Open SkillTrack in Google Chrome on your phone. Tap the 3 dots (⋮) in the top-right corner, then tap "Install app" or "Add to Home screen".',
            badge: 'Recommended',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            stepNumber: '2',
            title: 'Or Download Standalone APK',
            description:
                'Tap the "Download APK" button above to get the native Android package (app-release.apk). Open the downloaded file to install directly.',
          ),
          const SizedBox(height: 8),
          _buildFeatureHighlights(),
        ],
      ),
    );
  }

  Widget _buildIosGuide() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            stepNumber: '1',
            title: 'Open in Safari',
            description:
                'Ensure you are viewing SkillTrack inside Apple Safari browser on your iPhone or iPad.',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            stepNumber: '2',
            title: 'Tap the Share Button',
            description:
                'Tap the Share icon at the bottom of the Safari screen (the square with an arrow pointing upward).',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            stepNumber: '3',
            title: 'Tap "Add to Home Screen"',
            description:
                'Scroll down in the share menu and tap "Add to Home Screen" (⊞). Then tap "Add" in the top-right corner.',
            badge: 'Instant Icon',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGuide() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepCard(
            stepNumber: '1',
            title: 'Use Chrome or Microsoft Edge',
            description:
                'Open SkillTrack in Google Chrome, Microsoft Edge, or Brave browser on your PC or Mac.',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            stepNumber: '2',
            title: 'Click the Address Bar Install Icon',
            description:
                'Look at the right side of the browser URL bar for the Install icon (a monitor screen with a down arrow). Click it and select "Install".',
            badge: 'Desktop App',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            stepNumber: '3',
            title: 'Native Window & Desktop Shortcuts',
            description:
                'SkillTrack will launch in its own standalone desktop window with Start Menu, Taskbar, and Dock integration.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: AppColors.lightPurple,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mainBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Install SkillTrack?',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.offline_bolt_rounded,
                  color: AppColors.brightAccent, size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '100% Offline Access — Review roadmaps, cheat sheets & tasks with zero internet',
                  style:
                      TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.fullscreen_rounded,
                  color: Color(0xFF38BDF8), size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Fullscreen Clean Experience — No browser URL bars or navigation clutter',
                  style:
                      TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.storage_rounded, color: Color(0xFF34D399), size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private SQLite Database — All data stored safely on your device',
                  style:
                      TextStyle(color: AppColors.secondaryText, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
