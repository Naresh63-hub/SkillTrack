import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/notifications/notification_service.dart';
import 'models/student_profile.dart';
import 'repositories/profile_repository.dart';
import 'services/supabase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }

  // Fast parallel initialization with short network timeout so app startup is never stalled
  Widget? fastHome;
  try {
    final results = await Future.wait([
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
      SharedPreferences.getInstance(),
      ProfileRepository()
          .getProfile()
          .catchError((_) => StudentProfile(name: '')),
    ]);

    final prefs = results[2] as SharedPreferences;
    final profile = results[3] as StudentProfile;

    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    final hasValidProfile = profile.name.trim().isNotEmpty;
    final isGuest = prefs.getBool('is_guest_mode') ?? false;
    final isAuth = SupabaseAuthService.instance.isAuthenticated;

    // Direct Instant Resume: If the student is already an active user,
    // mount MainNavigationShell immediately on frame 1 without showing SplashScreen.
    if (hasOnboarded && (hasValidProfile || isGuest || isAuth)) {
      if (hasValidProfile) {
        final savedTab = prefs.getInt('last_active_tab_index') ?? 0;
        final savedRoute = prefs.getString('last_active_route');
        fastHome = MainNavigationShell(
          initialIndex: savedTab,
          initialRoute: savedRoute,
        );
      }
    }
  } catch (e) {
    debugPrint('Startup fast-resume notice: $e');
  }

  runApp(SkillTrackApp(initialHome: fastHome));
}
