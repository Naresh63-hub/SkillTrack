import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }

  // Fast parallel initialization with short network timeout so app startup is never stalled
  try {
    await Future.wait([
      if (SupabaseConfig.isConfigured)
        Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        ).timeout(
          const Duration(milliseconds: 300),
          onTimeout: () {
            debugPrint(
                'Supabase init fast-path timeout: continuing in background');
            return Supabase.instance;
          },
        ).catchError((e) {
          debugPrint('Supabase initialization notice: $e');
          return Supabase.instance;
        }),
      NotificationService.instance.init().catchError((_) {}),
    ]);
  } catch (e) {
    debugPrint('Startup services fast-init notice: $e');
  }

  runApp(const SkillTrackApp());
}
