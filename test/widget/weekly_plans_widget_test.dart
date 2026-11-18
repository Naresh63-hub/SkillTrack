import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/theme/app_theme.dart';
import 'package:skilltrack/features/dashboard/widgets/weekly_activity_card.dart';
import 'package:skilltrack/features/dashboard/screens/weekly_plans_screen.dart';
import 'package:skilltrack/models/task_model.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';

void main() {
  group('Weekly Activity & Weekly Plans Screen Tests', () {
    final sampleTasks = [
      TaskModel(
        id: 1,
        title: 'Review Flutter State Management',
        dueDate: DateTime.now().toIso8601String(),
        priority: 'High',
        category: 'Study',
        isCompleted: true,
        completedAt: DateTime.now().toIso8601String(),
      ),
      TaskModel(
        id: 2,
        title: 'Mock Interview with Mentor',
        dueDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        priority: 'Urgent',
        category: 'Call / Meeting',
        isCompleted: false,
        earlyReminderMinutes: 15,
      ),
    ];

    final sampleSkills = [
      Skill(
        id: 1,
        name: 'Flutter Architecture',
        category: 'Mobile Development',
        proficiencyLevel: 'Intermediate',
        progressPercentage: 70.0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    final sampleProjects = [
      Project(
        id: 1,
        name: 'SkillTrack App',
        shortDescription: 'Student tracking portfolio app',
        category: 'Mobile',
        status: 'In Progress',
        technologies: ['Flutter', 'SQLite'],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    testWidgets('WeeklyActivityCard renders title, day columns, and interactive tap prompt',
        (WidgetTester tester) async {
      bool cardTapped = false;
      int tappedDay = -2;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: WeeklyActivityCard(
              tasks: sampleTasks,
              skills: sampleSkills,
              projects: sampleProjects,
              onTap: () => cardTapped = true,
              onDayTap: (dayIdx) => tappedDay = dayIdx,
            ),
          ),
        ),
      );

      // Verify title & tap hint
      expect(find.text('Weekly Learning Activity'), findsOneWidget);
      expect(find.text("Tap to view this week's plans, tasks & schedule"), findsOneWidget);

      // Verify Day labels
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Tap on specific day (e.g. Mon)
      await tester.tap(find.text('Mon'));
      await tester.pump();
      expect(tappedDay, 0);

      // Tap on Sunday
      await tester.tap(find.text('Sun'));
      await tester.pump();
      expect(tappedDay, 6);

      // Tap overall card
      await tester.tap(find.text("Tap to view this week's plans, tasks & schedule"));
      await tester.pump();
      expect(cardTapped, isTrue);
    });

    testWidgets('WeeklyPlansScreen renders roadmap header, day pills, and sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: WeeklyPlansScreen(
            initialTasks: sampleTasks,
            initialSkills: sampleSkills,
            initialProjects: sampleProjects,
            initialDayIndex: -1,
          ),
        ),
      );

      // Let initial async futures resolve with mock/initial values
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Screen Title & Sections
      expect(find.text('Weekly Plans & Schedule'), findsOneWidget);
      expect(find.text('All Week'), findsOneWidget);
      expect(find.textContaining('Tasks'), findsWidgets);
      expect(find.textContaining('Future Plans'), findsWidgets);
      expect(find.textContaining('Skills In Progress'), findsWidgets);

      // Verify Action Buttons
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Schedule Plan'), findsOneWidget);
    });
  });
}
