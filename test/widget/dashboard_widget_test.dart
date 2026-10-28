import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/utils/progress_calculator.dart';
import 'package:skilltrack/features/dashboard/widgets/overall_progress_card.dart';
import 'package:skilltrack/features/dashboard/widgets/metric_summary_grid.dart';
import 'package:skilltrack/features/dashboard/widgets/quick_action_button.dart';

void main() {
  group('Dashboard Widgets Tests', () {
    testWidgets('OverallProgressCard renders progress percentage and pillars',
        (WidgetTester tester) async {
      const metrics = ProgressMetrics(
        overallPercentage: 75.0,
        skillsPercentage: 80.0,
        projectsPercentage: 70.0,
        tasksPercentage: 60.0,
        placementPercentage: 90.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OverallProgressCard(metrics: metrics),
          ),
        ),
      );

      expect(find.text('Career Preparation Score'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Technical Skills'), findsOneWidget);
      expect(find.text('Project Portfolio'), findsOneWidget);
      expect(find.text('Placement Prep'), findsOneWidget);
    });

    testWidgets('MetricSummaryGrid renders all 6 career metric cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricSummaryGrid(
              skillsCount: 6,
              certsCount: 3,
              projectsCount: 4,
              pendingTasksCount: 2,
              completedTasksCount: 5,
              placementProgress: 85.0,
            ),
          ),
        ),
      );

      expect(find.text('Technical Skills'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Certificates'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Placement Prep'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('QuickActionsBar renders action buttons',
        (WidgetTester tester) async {
      bool skillTapped = false;
      final actions = [
        QuickActionItem(
          label: 'Add Skill',
          icon: Icons.code,
          onTap: () => skillTapped = true,
        ),
        QuickActionItem(
          label: 'Add Task',
          icon: Icons.task,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsBar(actions: actions),
          ),
        ),
      );

      expect(find.text('Add Skill'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      await tester.tap(find.text('Add Skill'));
      expect(skillTapped, isTrue);
    });
  });
}
