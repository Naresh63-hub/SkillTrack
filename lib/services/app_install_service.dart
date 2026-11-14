import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pwa_install.dart';

class AppInstallService {
  AppInstallService._();
  static final AppInstallService instance = AppInstallService._();

  static const String directApkUrl =
      'https://github.com/Naresh63-hub/SkillTrack/releases/latest/download/app-release.apk';
  static const String latestReleaseUrl =
      'https://github.com/Naresh63-hub/SkillTrack/releases/latest';
  static const String githubReleasesUrl =
      'https://github.com/Naresh63-hub/SkillTrack/releases';
  static const String liveWebUrl = 'https://skill-track-ashy.vercel.app';

  /// Returns true if currently running on the web
  bool get isWeb => kIsWeb;

  /// Returns true if running as an installed standalone PWA
  bool get isInstalledPWA => isPWAStandalone();

  /// Prompts the browser's native install dialog if available
  bool triggerInstall() => triggerPWAInstall();

  /// Initiates Android APK download
  Future<bool> downloadAndroidApk() async {
    final uri = Uri.parse(directApkUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fallback to releases page
    final fallbackUri = Uri.parse(latestReleaseUrl);
    if (await canLaunchUrl(fallbackUri)) {
      return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens the GitHub Releases page
  Future<bool> openGitHubReleases() async {
    final uri = Uri.parse(githubReleasesUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens the production Vercel web URL
  Future<bool> openLiveWeb() async {
    final uri = Uri.parse(liveWebUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
