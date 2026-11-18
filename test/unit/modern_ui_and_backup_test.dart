import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:skilltrack/core/widgets/pulsing_dot.dart';
import 'package:skilltrack/core/widgets/dynamic_gradient_progress_bar.dart';
import 'package:skilltrack/core/widgets/spring_checkbox.dart';
import 'package:skilltrack/services/backup_restore_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Modern UI Widgets Unit Tests', () {
    testWidgets('PulsingDot renders cleanly with custom color and size',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PulsingDot(
              color: Color(0xFF10B981),
              size: 8.0,
            ),
          ),
        ),
      );

      expect(find.byType(PulsingDot), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PulsingDot), findsOneWidget);
    });

    testWidgets('DynamicGradientProgressBar renders percentage and mastered badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicGradientProgressBar(
              percentage: 100.0,
              showLabel: true,
              showMasteredBadge: true,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Mastered ✨'), findsOneWidget);
    });

    testWidgets('DynamicGradientProgressBar renders intermediate percentage',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicGradientProgressBar(
              percentage: 65.0,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Mastered ✨'), findsNothing);
    });

    testWidgets('SpringCheckbox toggles state and responds to tap',
        (tester) async {
      bool checked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SpringCheckbox(
                  value: checked,
                  onChanged: (val) {
                    setState(() => checked = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(SpringCheckbox), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.byType(SpringCheckbox));
      await tester.pumpAndSettle();

      expect(checked, isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('BackupRestoreService Security & Integrity Unit Tests', () {
    test('BackupRestoreService rejects tampered payload', () async {
      final service = BackupRestoreService.instance;
      // Intentionally forged payload
      const tamperedContent =
          'SKILLTRACK_ENCRYPTED_V1:eyJjaGVja3N1bSI6ImJhZGNhbGN1bGF0aW9uIiwicGF5bG9hZCI6ImV5SnplWE4wWlcwNklpd2ljRzl5ZEdadmJHbHZJanA3SW4wPSJ9';

      final summary = await service.inspectBackup(tamperedContent);
      expect(summary, isNull);

      final restored = await service.restoreFromEncryptedString(tamperedContent);
      expect(restored, isFalse);
    });

    test('BackupRestoreService rejects invalid header strings', () async {
      final service = BackupRestoreService.instance;
      const invalidHeader = 'INVALID_ENCRYPTED_HEADER_DATA_12345';

      final summary = await service.inspectBackup(invalidHeader);
      expect(summary, isNull);

      final restored = await service.restoreFromEncryptedString(invalidHeader);
      expect(restored, isFalse);
    });
  });
}
