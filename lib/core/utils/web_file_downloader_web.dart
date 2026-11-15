import 'dart:js_interop';

@JS('downloadFileFromDataUrl')
external bool _downloadFileFromDataUrl(JSString dataUrl, JSString fileName);

/// Web implementation using the DOM to trigger a browser file download.
Future<bool> downloadWebFilePlatform(String dataUrl, String fileName) async {
  try {
    return _downloadFileFromDataUrl(dataUrl.toJS, fileName.toJS);
  } catch (_) {
    return false;
  }
}
