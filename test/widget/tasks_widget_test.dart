import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/widgets/search_filter_bar.dart';
import 'package:skilltrack/core/widgets/section_header.dart';

void main() {
  group('Search & Navigation Widget Tests', () {
    testWidgets('SearchFilterBar triggers onChanged callback',
        (WidgetTester tester) async {
      String typedText = '';
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBar(
              controller: controller,
              hintText: 'Search tasks...',
              onChanged: (val) => typedText = val,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Dynamic Programming');
      expect(typedText, 'Dynamic Programming');
    });

    testWidgets('SectionHeader renders title and action text',
        (WidgetTester tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Upcoming Deadlines',
              actionText: 'View All',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Upcoming Deadlines'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);

      await tester.tap(find.text('View All'));
      expect(actionTriggered, isTrue);
    });
  });
}
