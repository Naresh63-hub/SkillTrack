import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/features/portfolio/models/portfolio_data.dart';
import 'package:skilltrack/features/portfolio/screens/public_portfolio_screen.dart';
import 'package:skilltrack/features/portfolio/widgets/student_card_share_sheet.dart';

void main() {
  testWidgets('PublicPortfolioScreen renders student header, tabs, and action buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final showcase = PortfolioData.showcase(handle: 'priya-sharma');

    await tester.pumpWidget(
      MaterialApp(
        home: PublicPortfolioScreen(
          handle: 'priya-sharma',
          initialData: showcase,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Verified Student badge & name
    expect(find.text('VERIFIED STUDENT'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);

    // Verify tab headers
    expect(find.textContaining('Projects ('), findsOneWidget);
    expect(find.textContaining('Certs ('), findsOneWidget);
    expect(find.textContaining('Skills ('), findsOneWidget);
    expect(find.text('Bio & Academics'), findsOneWidget);

    // Verify footer actions
    expect(find.text('Copy Profile Link'), findsOneWidget);
    expect(find.text('Share Student Card'), findsOneWidget);

    // Tap on Certs tab
    await tester.tap(find.textContaining('Certs ('));
    await tester.pumpAndSettle();
    expect(find.textContaining('AWS Certified Cloud Practitioner'), findsOneWidget);

    // Tap on Skills tab
    await tester.tap(find.textContaining('Skills ('));
    await tester.pumpAndSettle();
    expect(find.text('Flutter & Dart'), findsOneWidget);
  });

  testWidgets('StudentCardShareSheet displays share actions and public link preview',
      (WidgetTester tester) async {
    final showcase = PortfolioData.showcase(handle: 'priya-sharma');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => StudentCardShareSheet.show(context, showcase),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Share Student Card & Portfolio'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(find.text('Twitter / X'), findsOneWidget);
    expect(find.text('Export PDF Card'), findsOneWidget);
  });
}
