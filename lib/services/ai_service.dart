import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Secure AI Service for SkillTrack
///
/// Security Architecture:
/// 1. Backend Proxy First: In web deployments, calls are proxied through `/api/gemini`
///    where `GEMINI_API_KEY` is maintained exclusively in server-side environment variables.
/// 2. Zero Client Secret Exposure: Never bakes API keys into Flutter Web JavaScript via `--dart-define`.
/// 3. Developer Personal Key Override: Allows developers to optionally store their own personal
///    Gemini key locally in Settings.
/// 4. Graceful Fallback: If network, proxy, or upstream service fails, returns null so all modules
///    transparently fall back to offline heuristic engines without crashing.
class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static const String _prefApiKey = 'gemini_api_key';
  static const String _defaultModel = 'gemini-1.5-flash';
  static const String _defaultMobileProxyUrl =
      'https://skilltrack-tan.vercel.app/api/gemini';

  /// Retrieves user-supplied personal API key if configured in local app Settings
  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_prefApiKey);
      if (key != null && key.trim().isNotEmpty) {
        return key.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Saves or removes user's personal API key in local app Settings
  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(_prefApiKey);
    } else {
      await prefs.setString(_prefApiKey, key.trim());
    }
  }

  /// Returns true if user has saved a personal key in Settings
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Determines whether live AI service is available (via personal key or secure backend proxy)
  Future<bool> isLiveAiAvailable() async {
    if (await hasApiKey()) return true;
    // On web, the serverless proxy /api/gemini is available by default
    if (kIsWeb) return true;
    return false;
  }

  /// Sends a prompt to Gemini AI either via secure backend proxy or direct developer key
  Future<String?> generateContent({
    required String prompt,
    String? systemInstruction,
    bool forceJson = false,
  }) async {
    final personalKey = await getApiKey();

    if (personalKey != null && personalKey.isNotEmpty) {
      // Developer direct call using personal API key via HTTP header
      return _generateDirect(
        apiKey: personalKey,
        prompt: prompt,
        systemInstruction: systemInstruction,
        forceJson: forceJson,
      );
    }

    // Default Production Path: Secure Backend Proxy
    return _generateViaProxy(
      prompt: prompt,
      systemInstruction: systemInstruction,
      forceJson: forceJson,
    );
  }

  /// Calls the secure serverless backend proxy (/api/gemini)
  /// Keeps GEMINI_API_KEY 100% on the server; client never touches the secret.
  Future<String?> _generateViaProxy({
    required String prompt,
    String? systemInstruction,
    bool forceJson = false,
  }) async {
    try {
      Uri proxyUri;
      if (kIsWeb) {
        // Resolve relative to current web origin: e.g. https://domain.com/api/gemini
        proxyUri = Uri.base.resolve('/api/gemini');
      } else {
        proxyUri = Uri.parse(_defaultMobileProxyUrl);
      }

      final payload = {
        'prompt': prompt,
        if (systemInstruction != null && systemInstruction.isNotEmpty)
          'systemInstruction': systemInstruction,
        'forceJson': forceJson,
      };

      final response = await http
          .post(
            proxyUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 22));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('text')) {
          return data['text'] as String?;
        }
      } else {
        debugPrint(
            'AI backend proxy responded with status ${response.statusCode}. Falling back to offline engine.');
      }
    } catch (e) {
      debugPrint(
          'AI proxy communication unavailable. Operating in offline heuristic mode.');
    }
    return null;
  }

  /// Direct upstream call using developer-provided personal key
  Future<String?> _generateDirect({
    required String apiKey,
    required String prompt,
    String? systemInstruction,
    bool forceJson = false,
  }) async {
    try {
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
        debugPrint(
            'Direct Gemini API responded with status ${response.statusCode}. Falling back to offline engine.');
      }
    } catch (_) {
      debugPrint(
          'Direct Gemini API communication error. Operating in offline heuristic mode.');
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
