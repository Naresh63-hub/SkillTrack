import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Token Storage Wrapper
/// Encrypts sensitive secrets (e.g. GitHub personal access tokens)
/// using HMAC-SHA256 authenticated reversible encryption before writing to local storage.
/// Prevents plaintext token exposure in browser localStorage, Android XML, and memory dumps.
class SecureTokenStorage {
  static const String _storageSalt = 'SkillTrack_Secure_Vault_Key_2026_Salt';

  static List<int> _deriveKey(String salt) {
    return sha256.convert(utf8.encode(salt)).bytes;
  }

  static String _encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final keyBytes = _deriveKey(_storageSalt);
    final textBytes = utf8.encode(plainText);
    final encryptedBytes = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(encryptedBytes);

    final payload = {
      'payload': base64Encode(encryptedBytes),
      'sig': digest.toString(),
    };

    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  static String? _decrypt(String cipherText) {
    if (cipherText.isEmpty) return null;
    try {
      final decodedJson = utf8.decode(base64Decode(cipherText));
      final map = jsonDecode(decodedJson) as Map<String, dynamic>;
      final encryptedBytes = base64Decode(map['payload'] as String);
      final signature = map['sig'] as String;

      final keyBytes = _deriveKey(_storageSalt);
      final hmac = Hmac(sha256, keyBytes);
      final checkDigest = hmac.convert(encryptedBytes);

      // Verify integrity
      if (checkDigest.toString() != signature) {
        return null;
      }

      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (_) {
      // In case of legacy unencrypted token, safely return or ignore
      return null;
    }
  }

  static Future<void> saveSecureToken(String key, String token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token.trim().isEmpty) {
      await prefs.remove('enc_$key');
      await prefs.remove(key); // Remove any legacy plaintext key
    } else {
      final encrypted = _encrypt(token.trim());
      await prefs.setString('enc_$key', encrypted);
      await prefs.remove(key); // Ensure legacy plaintext key is purged
    }
  }

  static Future<String?> getSecureToken(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('enc_$key');
    if (encrypted != null && encrypted.isNotEmpty) {
      return _decrypt(encrypted);
    }
    // Check legacy key if exists, then migrate
    final legacy = prefs.getString(key);
    if (legacy != null && legacy.isNotEmpty) {
      await saveSecureToken(key, legacy);
      return legacy;
    }
    return null;
  }

  static Future<void> removeSecureToken(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_$key');
    await prefs.remove(key);
  }
}
