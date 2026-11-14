import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltrack/core/config/supabase_config.dart';
import 'package:skilltrack/services/supabase_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Configuration & Auth Service Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SupabaseConfig has valid project URL and publishable key', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.url, contains('supabase.co'));
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test(
        'SupabaseAuthService guest mode toggles correctly in SharedPreferences',
        () async {
      final authService = SupabaseAuthService.instance;

      expect(await authService.isGuestMode(), isFalse);

      await authService.setGuestMode(true);
      expect(await authService.isGuestMode(), isTrue);

      await authService.setGuestMode(false);
      expect(await authService.isGuestMode(), isFalse);
    });

    test(
        'SupabaseAuthService gracefully reports unauthenticated when client is uninitialized',
        () {
      final authService = SupabaseAuthService.instance;
      expect(authService.currentUser, isNull);
      expect(authService.currentSession, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}
