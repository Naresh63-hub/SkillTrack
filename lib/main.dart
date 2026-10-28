import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }

  // Ensure the app starts completely fresh with zero mock data
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasClearedMock = prefs.getBool('fresh_start_cleared_v1') ?? false;
    if (!hasClearedMock) {
      await DatabaseHelper.instance.clearAllData();
      await prefs.setBool('fresh_start_cleared_v1', true);
    }
  } catch (_) {
    // Graceful fallback
  }

  // Initialize notifications gracefully
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // If running in test or restricted environment
  }

  runApp(const SkillTrackApp());
}
