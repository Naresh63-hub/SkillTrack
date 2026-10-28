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

  // Ensure any lingering "Priya" mock data is completely deleted
  try {
    final db = await DatabaseHelper.instance.database;
    final checkPriya = await db.query('student_profile',
        where: 'LOWER(name) LIKE ?', whereArgs: ['%priya%']);
    if (checkPriya.isNotEmpty) {
      await DatabaseHelper.instance.clearAllData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_setup_profile');
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
