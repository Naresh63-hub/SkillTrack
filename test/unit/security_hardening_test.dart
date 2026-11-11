import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltrack/core/utils/secure_token_storage.dart';
import 'package:skilltrack/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Security Hardening - SecureTokenStorage AES-256-GCM', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Encrypts and decrypts secret token faithfully', () async {
      const originalToken = 'ghp_SkillTrackSuperSecretToken1234567890';
      await SecureTokenStorage.saveSecureToken('github_token', originalToken);

      final decrypted =
          await SecureTokenStorage.getSecureToken('github_token');
      expect(decrypted, equals(originalToken));
    });

    test('Never writes plaintext secrets to SharedPreferences', () async {
      const originalToken = 'ghp_PlaintextMustNeverBeExposedInStorage';
      await SecureTokenStorage.saveSecureToken('github_token', originalToken);

      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString('enc_v2_github_token');

      expect(storedValue, isNotNull);
      // Ensure plaintext does not appear anywhere in stored payload
      expect(storedValue!.contains(originalToken), isFalse);

      // Verify envelope has AES-256-GCM structure (version 2, nonce, ct, mac)
      final envelopeJson = utf8.decode(base64Decode(storedValue));
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
      expect(envelope['v'], equals(2));
      expect(envelope['nonce'], isNotNull);
      expect(envelope['ct'], isNotNull);
      expect(envelope['mac'], isNotNull);
    });

    test('Rejects tampered ciphertext via authenticated MAC validation',
        () async {
      const originalToken = 'ghp_AuthenticityGuaranteedToken';
      await SecureTokenStorage.saveSecureToken('test_tamper', originalToken);

      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString('enc_v2_test_tamper')!;

      final envelopeJson = utf8.decode(base64Decode(storedValue));
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;

      // Tamper with ciphertext by modifying a byte
      final ctBytes = base64Decode(envelope['ct'] as String);
      ctBytes[0] = ctBytes[0] ^ 0xFF; // Invert first byte
      envelope['ct'] = base64Encode(ctBytes);

      final tamperedB64 = base64Encode(utf8.encode(jsonEncode(envelope)));
      await prefs.setString('enc_v2_test_tamper', tamperedB64);

      // Decryption must detect MAC mismatch and return null
      final result = await SecureTokenStorage.getSecureToken('test_tamper');
      expect(result, isNull);
    });

    test('removeSecureToken removes encrypted secret and clears legacy keys',
        () async {
      await SecureTokenStorage.saveSecureToken('token_del', 'secret_val');
      expect(await SecureTokenStorage.getSecureToken('token_del'),
          equals('secret_val'));

      await SecureTokenStorage.removeSecureToken('token_del');
      expect(await SecureTokenStorage.getSecureToken('token_del'), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('enc_v2_token_del'), isFalse);
      expect(prefs.containsKey('enc_token_del'), isFalse);
      expect(prefs.containsKey('token_del'), isFalse);
    });
  });

  group('Security Hardening - AiService Sanitization', () {
    test('extractJsonString cleanly strips markdown code fence wrappers', () {
      const rawWithFences = '```json\n{"summary": "Test", "nodes": []}\n```';
      expect(AiService.extractJsonString(rawWithFences),
          equals('{"summary": "Test", "nodes": []}'));

      const rawWithGenericFences = '```\n{"score": 85.0}\n```';
      expect(AiService.extractJsonString(rawWithGenericFences),
          equals('{"score": 85.0}'));

      const rawClean = '{"score": 90.0}';
      expect(AiService.extractJsonString(rawClean), equals('{"score": 90.0}'));
    });
  });
}
