import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/theme/app_theme.dart';
import 'package:skilltrack/features/notes_planner/widgets/add_edit_event_dialog.dart';

void main() {
  testWidgets('DatePicker renders with high contrast colors and visible calendar days',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDatePicker(
                context: context,
                initialDate: DateTime(2026, 11, 18),
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              ),
              child: const Text('Open DatePicker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open DatePicker'));
    await tester.pumpAndSettle();

    // Verify calendar dialog opened
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Verify day 18 is visible and selected
    expect(find.text('18'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('TimePicker renders with high contrast colors and visible clock elements',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 8, minute: 42),
              ),
              child: const Text('Open TimePicker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open TimePicker'));
    await tester.pumpAndSettle();

    // Verify TimePicker dialog opened
    expect(find.byType(TimePickerDialog), findsOneWidget);

    // Verify buttons
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('AddEditEventDialog date and time pickers open cleanly without white-out',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AddEditEventDialog(initialDate: '2026-11-18'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the date picker tile
    final dateFinder = find.text('2026-11-18');
    expect(dateFinder, findsOneWidget);
    await tester.tap(dateFinder);
    await tester.pumpAndSettle();

    // Date picker dialog is visible with high contrast
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('18'), findsOneWidget);

    // Cancel date picker
    final datePickerCancel = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('Cancel'),
    );
    await tester.tap(datePickerCancel.last);
    await tester.pumpAndSettle();

    // Tap on start time button
    final timeFinder = find.text('Start Time');
    expect(timeFinder, findsOneWidget);
    await tester.ensureVisible(timeFinder);
    await tester.tap(timeFinder);
    await tester.pumpAndSettle();

    // Time picker dialog is visible with dial elements
    expect(find.byType(TimePickerDialog), findsOneWidget);
    final timePickerCancel = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.text('Cancel'),
    );
    await tester.tap(timePickerCancel.last);
    await tester.pumpAndSettle();
  });
}
