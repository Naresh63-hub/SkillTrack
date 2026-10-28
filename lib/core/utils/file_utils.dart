import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  /// Safely copies a picked file to application-managed persistent documents storage.
  /// This prevents loss when temporary cache files are cleared by Android.
  static Future<String?> copyFileToAppStorage(String sourcePath,
      {String subDir = 'certificates'}) async {
    if (kIsWeb) return sourcePath;
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDir.path, subDir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
      final destinationPath = p.join(targetDir.path, fileName);
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> fileExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    if (kIsWeb) return true;
    try {
      return await File(filePath).exists();
    } catch (_) {
      return false;
    }
  }

  static String getFileExtension(String filePath) {
    return p.extension(filePath).toLowerCase();
  }

  static bool isImageFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp';
  }

  static bool isPdfFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ext == '.pdf';
  }

  static Future<int> getFileSizeInBytes(String filePath) async {
    if (kIsWeb) return 0;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }
}
