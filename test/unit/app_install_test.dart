import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/services/app_install_service.dart';

void main() {
  group('AppInstallService Unit Tests', () {
    final service = AppInstallService.instance;

    test('All download and web URLs are valid HTTPS schemes', () {
      expect(AppInstallService.directApkUrl, startsWith('https://'));
      expect(AppInstallService.directApkUrl, endsWith('.apk'));

      expect(AppInstallService.latestReleaseUrl, startsWith('https://'));
      expect(AppInstallService.githubReleasesUrl, startsWith('https://'));
      expect(AppInstallService.liveWebUrl, startsWith('https://'));

      expect(Uri.parse(AppInstallService.directApkUrl).isAbsolute, isTrue);
      expect(Uri.parse(AppInstallService.latestReleaseUrl).isAbsolute, isTrue);
      expect(Uri.parse(AppInstallService.githubReleasesUrl).isAbsolute, isTrue);
      expect(Uri.parse(AppInstallService.liveWebUrl).isAbsolute, isTrue);
    });

    test('Non-web default stub values return safe fallbacks', () {
      // In the VM test environment, isInstalledPWA should safely be false without errors
      expect(service.isInstalledPWA, isFalse);
      expect(service.triggerInstall(), isFalse);
    });
  });
}
