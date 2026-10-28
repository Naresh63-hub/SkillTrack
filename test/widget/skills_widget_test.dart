import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/widgets/progress_bar.dart';
import 'package:skilltrack/core/widgets/empty_state.dart';
import 'package:skilltrack/core/widgets/custom_card.dart';

void main() {
  group('Skills & Core Custom Widgets Tests', () {
    testWidgets('CustomProgressBar displays correct percentage label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomProgressBar(
              percentage: 65.0,
              showLabel: true,
              labelText: 'Mastery',
            ),
          ),
        ),
      );

      expect(find.text('Mastery'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets(
        'EmptyStateWidget renders title, description, and action button',
        (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.code_off,
              title: 'No Technical Skills',
              description:
                  'Start tracking the programming languages you are learning.',
              actionLabel: 'Add First Skill',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Technical Skills'), findsOneWidget);
      expect(
          find.text(
              'Start tracking the programming languages you are learning.'),
          findsOneWidget);
      expect(find.text('Add First Skill'), findsOneWidget);

      await tester.tap(find.text('Add First Skill'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('CustomCard executes onTap callback',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () => tapped = true,
              child: const Text('Clickable Card'),
            ),
          ),
        ),
      );

      expect(find.text('Clickable Card'), findsOneWidget);
      await tester.tap(find.text('Clickable Card'));
      expect(tapped, isTrue);
    });
  });
}
