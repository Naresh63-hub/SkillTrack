import 'dart:js_interop';

@JS('isPWAStandalone')
external bool _isPWAStandalone();

@JS('triggerPWAInstall')
external bool _triggerPWAInstall();

/// Web implementation checking if the web app is running standalone as a PWA.
bool isPWAStandalonePlatform() {
  try {
    return _isPWAStandalone();
  } catch (_) {
    return false;
  }
}

/// Web implementation triggering the browser's PWA install prompt.
bool triggerPWAInstallPlatform() {
  try {
    return _triggerPWAInstall();
  } catch (_) {
    return false;
  }
}
