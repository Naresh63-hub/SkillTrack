import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized auto-save draft service for form fields and inputs.
/// Prevents data loss when users switch apps or when Android terminates
/// background processes to reclaim memory.
class DraftService {
  static final DraftService instance = DraftService._internal();
  DraftService._internal();

  static const String _draftPrefix = 'skilltrack_draft_';

  /// Save form draft data under a unique [formKey]
  Future<void> saveDraft(String formKey, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftPrefix$formKey';
      final payload = Map<String, dynamic>.from(data);
      payload['_draft_saved_at'] = DateTime.now().toIso8601String();
      await prefs.setString(key, jsonEncode(payload));
    } catch (e) {
      debugPrint('DraftService saveDraft error: $e');
    }
  }

  /// Retrieve existing draft for [formKey]
  Future<Map<String, dynamic>?> getDraft(String formKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftPrefix$formKey';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('DraftService getDraft error: $e');
      return null;
    }
  }

  /// Returns true if a non-empty draft exists for [formKey]
  Future<bool> hasDraft(String formKey) async {
    final draft = await getDraft(formKey);
    if (draft == null) return false;
    // Check if any non-system field has content
    for (final entry in draft.entries) {
      if (entry.key.startsWith('_')) continue;
      if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Clear draft upon successful save/submission
  Future<void> clearDraft(String formKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftPrefix$formKey';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('DraftService clearDraft error: $e');
    }
  }

  /// Clear all drafts across all forms
  Future<void> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_draftPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('DraftService clearAllDrafts error: $e');
    }
  }
}
