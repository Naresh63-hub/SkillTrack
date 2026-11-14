import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final SupabaseAuthService instance = SupabaseAuthService._internal();
  SupabaseAuthService._internal();

  static const String _guestModeKey = 'is_guest_mode';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Whether Supabase has been initialized successfully
  bool get isReady => _client != null;

  /// Currently authenticated user
  User? get currentUser => _client?.auth.currentUser;

  /// Currently active session
  Session? get currentSession => _client?.auth.currentSession;

  /// Returns true if a valid user session is active
  bool get isAuthenticated => currentUser != null;

  /// Stream of Supabase authentication state changes
  Stream<AuthState>? get onAuthStateChange => _client?.auth.onAuthStateChange;

  /// Checks if student chose to use the app in Guest / Offline mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_guestModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets or clears guest mode status
  Future<void> setGuestMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, enabled);
    } catch (_) {}
  }

  /// Signs up a new student with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }

    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: fullName != null && fullName.trim().isNotEmpty
          ? {'full_name': fullName.trim()}
          : null,
    );

    // If signup is successful, exit guest mode
    await setGuestMode(false);
    return response;
  }

  /// Signs in an existing student with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    // If login is successful, exit guest mode
    await setGuestMode(false);
    return response;
  }

  /// Signs in with Google OAuth provider
  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }

    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.skilltrack://login-callback/',
    );
  }

  /// Sends a password reset email
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }

    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Signs out the current user and clears session
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign out notice: $e');
    }
    await setGuestMode(false);
  }
}
