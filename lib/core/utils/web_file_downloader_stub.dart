/// Non-web fallback stubs for downloading and sharing files in browser.
Future<bool> downloadWebFilePlatform(String dataUrl, String fileName) async =>
    false;

Future<bool> shareWebFilePlatform(
    String dataUrl, String fileName, {String? title, String? text}) async =>
    false;

bool openWebFileInNewTabPlatform(String dataUrl) => false;
