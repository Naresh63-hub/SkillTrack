import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/features/app_install/widgets/install_app_dialog.dart';
import 'package:skilltrack/features/app_install/widgets/install_app_banner.dart';

void main() {
  group('Install & Download App Widget Tests', () {
    testWidgets('InstallAppDialog renders headers, action buttons, and tabs',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InstallAppDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header & CTAs
      expect(find.text('Install & Download App'), findsOneWidget);
      expect(
          find.text('Offline-ready on Android, iOS & Desktop'), findsOneWidget);
      expect(find.text('Install App'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);

      // Check 3 Platform Tabs
      expect(find.text('Android'), findsOneWidget);
      expect(find.text('iPhone / iOS'), findsOneWidget);
      expect(find.text('PC / Mac'), findsOneWidget);

      // Check Android content is shown initially
      expect(find.text('Install as Progressive Web App (Fastest)'),
          findsOneWidget);
      expect(find.text('Why Install SkillTrack?'), findsOneWidget);

      // Tap iOS Tab
      await tester.tap(find.text('iPhone / iOS'));
      await tester.pumpAndSettle();
      expect(find.text('Open in Safari'), findsOneWidget);
      expect(find.text('Tap "Add to Home Screen"'), findsOneWidget);

      // Tap PC / Mac Tab
      await tester.tap(find.text('PC / Mac'));
      await tester.pumpAndSettle();
      expect(find.text('Use Chrome or Microsoft Edge'), findsOneWidget);

      // Check Footer links
      expect(find.text('Copy Web Link'), findsOneWidget);
      expect(find.text('GitHub Releases'), findsOneWidget);
    });

    testWidgets('InstallAppBanner renders and dismisses on close tap',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: InstallAppBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Get the SkillTrack App'), findsOneWidget);
      expect(find.text('Install / Download'), findsOneWidget);
      expect(find.text('Direct APK'), findsOneWidget);

      // Dismiss banner
      final dismissBtn = find.byTooltip('Dismiss banner');
      expect(dismissBtn, findsOneWidget);
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(find.text('Get the SkillTrack App'), findsNothing);
    });
  });
}
