import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('requiredField validates null and empty', () {
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField(''), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
      expect(Validators.requiredField('Valid Name'), isNull);
    });

    test('progress validator enforces 0 to 100 boundary', () {
      expect(Validators.progress(null), isNotNull);
      expect(Validators.progress(''), isNotNull);
      expect(Validators.progress('abc'), isNotNull);
      expect(Validators.progress('-5'), isNotNull);
      expect(Validators.progress('105'), isNotNull);
      expect(Validators.progress('0'), isNull);
      expect(Validators.progress('50.5'), isNull);
      expect(Validators.progress('100'), isNull);
    });

    test('optionalUrl validates schemes correctly', () {
      expect(Validators.optionalUrl(null), isNull);
      expect(Validators.optionalUrl(''), isNull);
      expect(Validators.optionalUrl('not-a-url'), isNotNull);
      expect(Validators.optionalUrl('ftp://example.com'), isNotNull);
      expect(Validators.optionalUrl('https://github.com/test'), isNull);
      expect(Validators.optionalUrl('http://mysite.org'), isNull);
    });

    test('optionalEmail validates format', () {
      expect(Validators.optionalEmail(null), isNull);
      expect(Validators.optionalEmail(''), isNull);
      expect(Validators.optionalEmail('invalid-email'), isNotNull);
      expect(Validators.optionalEmail('user@domain.com'), isNull);
    });
  });
}
