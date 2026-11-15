import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks and persists navigation state (active tab, active screen route)
/// across app backgrounding, OS process recreation, and multitasking.
class NavigationStateService {
  static final NavigationStateService instance =
      NavigationStateService._internal();
  NavigationStateService._internal();

  static const String _keyActiveTab = 'last_active_tab_index';
  static const String _keyActiveRoute = 'last_active_route';
  static const String _keyLastBackgroundTime = 'last_background_timestamp';
  static const String _keyHasActiveSession = 'has_active_session';

  /// Save current active tab index (0: Home, 1: Skills, 2: Portfolio, 3: Tasks, 4: Placement)
  Future<void> saveActiveTab(int tabIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyActiveTab, tabIndex.clamp(0, 4));
      await prefs.setBool(_keyHasActiveSession, true);
    } catch (e) {
      debugPrint('NavigationStateService saveActiveTab error: $e');
    }
  }

  /// Retrieve the last active tab index
  Future<int> getActiveTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyActiveTab) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Save active route/sub-screen (e.g., 'notes_planner', 'roadmaps', 'resume', etc.)
  Future<void> saveActiveRoute(String? routeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (routeName == null || routeName.isEmpty) {
        await prefs.remove(_keyActiveRoute);
      } else {
        await prefs.setString(_keyActiveRoute, routeName);
      }
    } catch (e) {
      debugPrint('NavigationStateService saveActiveRoute error: $e');
    }
  }

  /// Retrieve last active route
  Future<String?> getActiveRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyActiveRoute);
    } catch (e) {
      return null;
    }
  }

  /// Record timestamp when app enters background / pause
  Future<void> recordAppBackgrounded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _keyLastBackgroundTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Check if the last session was recent (e.g. within 24 hours)
  Future<bool> isRecentSession(
      {Duration threshold = const Duration(hours: 24)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_keyLastBackgroundTime);
      if (lastMs == null) return false;
      final diff =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
      return diff <= threshold;
    } catch (_) {
      return false;
    }
  }

  /// Clear session state upon explicit user logout
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveTab);
      await prefs.remove(_keyActiveRoute);
      await prefs.remove(_keyHasActiveSession);
      await prefs.remove(_keyLastBackgroundTime);
    } catch (_) {}
  }
}
