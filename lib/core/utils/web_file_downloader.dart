import 'web_file_downloader_stub.dart'
    if (dart.library.js_interop) 'web_file_downloader_web.dart';

/// Downloads a file in the browser using a Data URL / Blob URL and a target filename.
Future<bool> downloadWebFile(String dataUrl, String fileName) =>
    downloadWebFilePlatform(dataUrl, fileName);
