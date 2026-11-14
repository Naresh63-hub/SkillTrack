import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/features/notes_planner/screens/notes_planner_hub_screen.dart';
import 'package:skilltrack/features/notes_planner/widgets/add_edit_note_dialog.dart';
import 'package:skilltrack/features/notes_planner/widgets/add_edit_event_dialog.dart';
import 'package:skilltrack/models/note_model.dart';
import 'package:skilltrack/models/planner_event.dart';
import 'package:skilltrack/models/skill.dart';

void main() {
  final sampleNote = NoteModel(
    id: 1,
    title: 'Sliding Window Algorithm',
    content:
        'Keep left and right pointers. Increment right, shrink left when invalid.',
    category: 'DSA & Coding',
    linkedSkillName: 'Data Structures',
    colorTag: 'purple',
    isPinned: true,
  );

  final sampleEvent = PlannerEvent(
    id: 1,
    title: 'Google Placement Assessment',
    description: 'Round 1 technical coding contest',
    eventType: 'Placement Drive',
    targetDate: '2026-12-01',
    startTime: '10:00 AM',
    endTime: '12:00 PM',
    priority: 'High',
  );

  final sampleSkill = Skill(
    id: 1,
    name: 'Data Structures',
    category: 'Computer Science',
    proficiencyLevel: 'Intermediate',
    progressPercentage: 80.0,
  );

  group('NotesPlannerHubScreen Widget Tests', () {
    testWidgets('Renders dual tabs and search field',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: NotesPlannerHubScreen(
            initialTabIndex: 0,
            initialNotes: [sampleNote],
            initialEvents: [sampleEvent],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check App bar title and tabs
      expect(find.text('Notes & Planner'), findsOneWidget);
      expect(find.text('Notes & Cheatsheets'), findsOneWidget);
      expect(find.text('Study & Placement Planner'), findsOneWidget);

      // Check Tab 1 Search field and category filter chips
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('DSA & Coding'), findsWidgets);
      expect(find.text('Core CS'), findsOneWidget);
      expect(find.text('Interview Prep'), findsOneWidget);

      // Check note card is rendered
      expect(find.text('Sliding Window Algorithm'), findsOneWidget);

      // Check FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Switches to Study & Placement Planner tab',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: NotesPlannerHubScreen(
            initialTabIndex: 1,
            initialNotes: [sampleNote],
            initialEvents: [sampleEvent],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Tab 2 contents
      expect(find.text('Study & Placement Planner'), findsOneWidget);
      expect(find.text('UPCOMING MILESTONES & DRIVES'), findsOneWidget);
      expect(find.text('Google Placement Assessment'), findsWidgets);
    });

    testWidgets('AddEditNoteDialog displays inputs and category selection',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditNoteDialog(
              note: sampleNote,
              availableSkills: [sampleSkill],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Note / Cheatsheet'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Sliding Window Algorithm'), findsOneWidget);
    });

    testWidgets('AddEditEventDialog displays form fields and event types',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditEventDialog(
              event: sampleEvent,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Save Event'), findsOneWidget);
      expect(find.text('Event Title *'), findsOneWidget);
      expect(find.text('Google Placement Assessment'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
    });
  });
}
