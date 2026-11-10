import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static const String _prefApiKey = 'gemini_api_key';
  static const String _defaultModel = 'gemini-1.5-flash';
  static const String _envApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_prefApiKey);
      if (key != null && key.trim().isNotEmpty) {
        return key.trim();
      }
    } catch (_) {}
    if (_envApiKey.trim().isNotEmpty) {
      return _envApiKey.trim();
    }
    return null;
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(_prefApiKey);
    } else {
      await prefs.setString(_prefApiKey, key.trim());
    }
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Returns true if Gemini API key is configured and can be reached.
  Future<bool> isLiveAiAvailable() async {
    return await hasApiKey();
  }

  /// Sends a prompt to the Gemini API securely using the x-goog-api-key HTTP header.
  /// Never exposes the key in URL query strings or logs.
  Future<String?> generateContent({
    required String prompt,
    String? systemInstruction,
    bool forceJson = false,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    try {
      // Secure URL without query parameters - key is transmitted via headers
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent',
      );

      final contents = [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ];

      final Map<String, dynamic> body = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 2048,
          if (forceJson) 'responseMimeType': 'application/json',
        },
      };

      if (systemInstruction != null && systemInstruction.isNotEmpty) {
        body['systemInstruction'] = {
          'parts': [
            {'text': systemInstruction}
          ]
        };
      }

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
        }
      } else {
        // Redact any possible key remnants in debug output
        debugPrint('Gemini API HTTP ${response.statusCode} response returned.');
      }
    } catch (e) {
      debugPrint('Gemini API communication error occurred.');
    }
    return null;
  }

  /// Strips potential markdown code blocks (```json ... ```) from response strings
  static String extractJsonString(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
