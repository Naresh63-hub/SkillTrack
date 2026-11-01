import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/features/skills/screens/career_roadmaps_screen.dart';
import 'package:skilltrack/features/skills/screens/roadmap_detail_screen.dart';
import 'package:skilltrack/services/roadmap_service.dart';

void main() {
  group('Career Roadmaps Widget Tests', () {
    testWidgets('CareerRoadmapsScreen renders all 6 target career roles',
        (WidgetTester tester) async {
      final roadmaps = RoadmapService.getAvailableRoadmaps();

      await tester.pumpWidget(
        MaterialApp(
          home: CareerRoadmapsScreen(
            initialRoadmaps: roadmaps,
            initialSkillsMap: const {},
            initialUserTargetRole: 'Flutter Developer',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Career Skill Roadmaps'), findsOneWidget);
      expect(find.text('Target Career Roles'), findsOneWidget);
      expect(find.text('Python Developer'), findsOneWidget);
      expect(find.text('Full Stack Developer'), findsOneWidget);
      expect(find.text('Flutter Developer'), findsOneWidget);
      expect(find.text('Data Analyst'), findsOneWidget);
      expect(find.text('AI/ML Engineer'), findsOneWidget);
      expect(find.text('Java Developer'), findsOneWidget);
      expect(find.text('Your Goal'), findsOneWidget);
    });

    testWidgets('RoadmapDetailScreen displays roadmap skills and opens dialog',
        (WidgetTester tester) async {
      final flutterRoadmap =
          RoadmapService.getRoadmapById('flutter_developer')!;

      await tester.pumpWidget(
        MaterialApp(
          home: RoadmapDetailScreen(
            roadmap: flutterRoadmap,
            initialExistingSkills: const {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check roadmap header details
      expect(find.text('Flutter Developer'), findsWidgets);
      expect(find.text(flutterRoadmap.tagline), findsOneWidget);

      // Check roadmap skills are rendered
      expect(find.text('Dart Programming'), findsOneWidget);
      expect(find.text('Flutter Fundamentals'), findsOneWidget);
      expect(find.text('UI Development'), findsOneWidget);
      expect(find.text('Navigation and State Management'), findsOneWidget);
      expect(find.text('REST APIs'), findsOneWidget);
      expect(find.text('SQLite and Local Storage'), findsOneWidget);
      expect(find.text('Git and GitHub'), findsOneWidget);
      expect(find.text('Testing and App Deployment'), findsOneWidget);

      // Check Import Roadmap button in the bottom navigation bar
      final importButton =
          find.widgetWithText(ElevatedButton, 'Import Roadmap');
      expect(importButton, findsOneWidget);

      // Tap "Import Roadmap" to trigger confirmation dialog
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      // Verify the exact required confirmation dialog prompt
      expect(
        find.text(
            'Would you like to add this recommended roadmap to your skills?'),
        findsOneWidget,
      );

      // Verify the two required buttons
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Import Roadmap'),
        findsWidgets,
      );

      // Tap "Cancel"
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(
        find.text(
            'Would you like to add this recommended roadmap to your skills?'),
        findsNothing,
      );
    });

    testWidgets(
        'RoadmapImportDialog renders exact confirmation prompt and action buttons',
        (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await RoadmapImportDialog.show(ctx);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Would you like to add this recommended roadmap to your skills?'),
        findsOneWidget,
      );
      expect(find.text('Import Roadmap'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);

      // Click "Import Roadmap"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import Roadmap'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });
}
