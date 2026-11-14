import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';

/// Returns true if the app is currently running as a standalone installed PWA.
bool isPWAStandalone() => isPWAStandalonePlatform();

/// Triggers the browser's native PWA installation prompt if available.
/// Returns true if the prompt was successfully triggered.
bool triggerPWAInstall() => triggerPWAInstallPlatform();
