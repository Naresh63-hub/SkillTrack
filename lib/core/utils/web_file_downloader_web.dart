import 'dart:js_interop';

@JS('downloadFileFromDataUrl')
external bool _downloadFileFromDataUrl(JSString dataUrl, JSString fileName);

@JS('shareFileFromDataUrl')
external JSPromise<JSBoolean> _shareFileFromDataUrl(
    JSString dataUrl, JSString fileName, JSString title, JSString text);

@JS('openFileInNewTab')
external bool _openFileInNewTab(JSString dataUrl);

/// Web implementation using the DOM to trigger a browser file download.
Future<bool> downloadWebFilePlatform(String dataUrl, String fileName) async {
  try {
    return _downloadFileFromDataUrl(dataUrl.toJS, fileName.toJS);
  } catch (_) {
    return false;
  }
}

/// Web implementation using Web Share API to share a file.
Future<bool> shareWebFilePlatform(
    String dataUrl, String fileName, {String? title, String? text}) async {
  try {
    final promise = _shareFileFromDataUrl(
      dataUrl.toJS,
      fileName.toJS,
      (title ?? fileName).toJS,
      (text ?? '').toJS,
    );
    final result = await promise.toDart;
    return result.toDart;
  } catch (_) {
    return false;
  }
}

/// Opens a file in a new browser tab.
bool openWebFileInNewTabPlatform(String dataUrl) {
  try {
    return _openFileInNewTab(dataUrl.toJS);
  } catch (_) {
    return false;
  }
}
