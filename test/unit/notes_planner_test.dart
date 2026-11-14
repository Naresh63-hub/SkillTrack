import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:skilltrack/core/database/database_helper.dart';
import 'package:skilltrack/models/note_model.dart';
import 'package:skilltrack/models/planner_event.dart';
import 'package:skilltrack/repositories/notes_repository.dart';
import 'package:skilltrack/repositories/planner_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NoteModel Unit Tests', () {
    test('NoteModel toMap and fromMap serialization round-trip', () {
      final note = NoteModel(
        id: 1,
        title: 'Binary Search Edge Cases',
        content: 'Check for mid = low + (high - low) ~/ 2 to avoid overflow.',
        category: 'DSA & Coding',
        linkedSkillName: 'Data Structures',
        colorTag: 'purple',
        isPinned: true,
        createdAt: '2026-11-14T10:00:00.000',
        updatedAt: '2026-11-14T12:00:00.000',
      );

      final map = note.toMap();
      final revived = NoteModel.fromMap(map);

      expect(revived.id, 1);
      expect(revived.title, 'Binary Search Edge Cases');
      expect(revived.content, contains('overflow'));
      expect(revived.category, 'DSA & Coding');
      expect(revived.linkedSkillName, 'Data Structures');
      expect(revived.colorTag, 'purple');
      expect(revived.isPinned, isTrue);
      expect(revived.createdAt, '2026-11-14T10:00:00.000');
      expect(revived.updatedAt, '2026-11-14T12:00:00.000');
    });

    test('NoteModel copyWith produces modified clone', () {
      final note = NoteModel(
        title: 'Original Title',
        content: 'Original Content',
        category: 'Personal',
      );

      final updated = note.copyWith(
        title: 'New Title',
        isPinned: true,
        colorTag: 'amber',
      );

      expect(updated.title, 'New Title');
      expect(updated.content, 'Original Content');
      expect(updated.category, 'Personal');
      expect(updated.isPinned, isTrue);
      expect(updated.colorTag, 'amber');
    });

    test('NoteModel default values and formattedUpdatedDate', () {
      final note = NoteModel(
        title: 'Quick Note',
        content: 'Some note text',
      );

      expect(note.category, 'DSA & Coding');
      expect(note.colorTag, 'purple');
      expect(note.isPinned, isFalse);
      expect(note.formattedUpdatedDate, isNotEmpty);
    });
  });

  group('PlannerEvent Unit Tests', () {
    test('PlannerEvent toMap and fromMap serialization round-trip', () {
      final event = PlannerEvent(
        id: 42,
        title: 'Google Campus Placement Drive',
        description: 'Round 1: Online Coding Test on HackerEarth',
        eventType: 'Placement Drive',
        targetDate: '2026-12-01',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        priority: 'High',
        isCompleted: false,
      );

      final map = event.toMap();
      final revived = PlannerEvent.fromMap(map);

      expect(revived.id, 42);
      expect(revived.title, 'Google Campus Placement Drive');
      expect(revived.eventType, 'Placement Drive');
      expect(revived.targetDate, '2026-12-01');
      expect(revived.startTime, '10:00 AM');
      expect(revived.priority, 'High');
      expect(revived.isCompleted, isFalse);
    });

    test('PlannerEvent countdown calculations (today, upcoming, overdue)', () {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final todayEvent = PlannerEvent(
        title: 'Today Exam',
        eventType: 'Exam / Test',
        targetDate: todayStr,
      );
      expect(todayEvent.isToday, isTrue);
      expect(todayEvent.daysRemaining, 0);
      expect(todayEvent.countdownLabel, 'TODAY');

      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr =
          "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
      final tomorrowEvent = PlannerEvent(
        title: 'Tomorrow Drive',
        eventType: 'Placement Drive',
        targetDate: tomorrowStr,
      );
      expect(tomorrowEvent.daysRemaining, 1);
      expect(tomorrowEvent.isUpcoming, isTrue);
      expect(tomorrowEvent.countdownLabel, 'IN 1 DAY');

      final future = now.add(const Duration(days: 7));
      final futureStr =
          "${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}";
      final futureEvent = PlannerEvent(
        title: 'Future Sprint',
        eventType: 'Study Sprint',
        targetDate: futureStr,
      );
      expect(futureEvent.daysRemaining, 7);
      expect(futureEvent.isUpcoming, isTrue);
      expect(futureEvent.countdownLabel, 'IN 7 DAYS');

      final past = now.subtract(const Duration(days: 3));
      final pastStr =
          "${past.year}-${past.month.toString().padLeft(2, '0')}-${past.day.toString().padLeft(2, '0')}";
      final pastEvent = PlannerEvent(
        title: 'Past Mock',
        eventType: 'Mock Interview',
        targetDate: pastStr,
      );
      expect(pastEvent.daysRemaining, lessThan(0));
      expect(pastEvent.isOverdue, isTrue);
      expect(pastEvent.countdownLabel, contains('AGO'));
    });

    test('PlannerEvent copyWith toggles completion', () {
      final event = PlannerEvent(
        title: 'Resume Review',
        eventType: 'Revision',
        targetDate: '2026-11-20',
        isCompleted: false,
      );

      final completed = event.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
      expect(completed.title, 'Resume Review');
    });
  });

  group('Notes & Planner Database & Repository Integration Tests', () {
    late NotesRepository notesRepo;
    late PlannerRepository plannerRepo;

    setUp(() async {
      await DatabaseHelper.instance.database;
      notesRepo = NotesRepository();
      plannerRepo = PlannerRepository();
    });

    test('Notes CRUD: insert, search, filter, pin, update, delete', () async {
      final note1 = NoteModel(
        title: 'Sliding Window DSA Pattern',
        content:
            'Use two pointers l and r. Expand r until invalid, then advance l.',
        category: 'DSA & Coding',
        linkedSkillName: 'Data Structures',
        colorTag: 'purple',
        isPinned: false,
      );

      final note2 = NoteModel(
        title: 'Operating Systems Semaphores',
        content: 'Wait(P) decrements and Signal(V) increments semaphore value.',
        category: 'Core CS',
        linkedSkillName: 'Operating Systems',
        colorTag: 'cyan',
        isPinned: true,
      );

      final id1 = await notesRepo.addNote(note1);
      final id2 = await notesRepo.addNote(note2);

      expect(id1, greaterThan(0));
      expect(id2, greaterThan(0));

      // Retrieve all
      final allNotes = await notesRepo.getAllNotes();
      expect(allNotes.any((n) => n.id == id1), isTrue);
      expect(allNotes.any((n) => n.id == id2), isTrue);

      // Search keyword
      final searchResults =
          await notesRepo.getAllNotes(searchQuery: 'Pointers');
      expect(searchResults.any((n) => n.id == id1), isTrue);
      expect(searchResults.any((n) => n.id == id2), isFalse);

      // Category filter
      final csNotes = await notesRepo.getAllNotes(category: 'Core CS');
      expect(csNotes.any((n) => n.id == id2), isTrue);
      expect(csNotes.any((n) => n.id == id1), isFalse);

      // Linked skill filter
      final dsaSkillNotes =
          await notesRepo.getAllNotes(linkedSkillName: 'Data Structures');
      expect(dsaSkillNotes.any((n) => n.id == id1), isTrue);

      // Pin toggle
      await notesRepo.togglePin(id1, false);
      final pinnedNote1 = await notesRepo.getNoteById(id1);
      expect(pinnedNote1!.isPinned, isTrue);

      // Update
      final updatedNote = pinnedNote1.copyWith(
        title: 'Sliding Window & Two Pointers (Advanced)',
        colorTag: 'emerald',
      );
      await notesRepo.updateNote(updatedNote);
      final checkUpdated = await notesRepo.getNoteById(id1);
      expect(checkUpdated!.title, 'Sliding Window & Two Pointers (Advanced)');
      expect(checkUpdated.colorTag, 'emerald');

      // Count
      final count = await notesRepo.getNotesCount();
      expect(count, greaterThanOrEqualTo(2));

      // Cleanup
      await notesRepo.deleteNote(id1);
      await notesRepo.deleteNote(id2);

      final afterDelete1 = await notesRepo.getNoteById(id1);
      expect(afterDelete1, isNull);
    });

    test('Planner CRUD: insert, date filter, upcoming, toggle complete, delete',
        () async {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr =
          "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

      final eventToday = PlannerEvent(
        title: 'Amazon Online Assessment',
        eventType: 'Placement Drive',
        targetDate: todayStr,
        startTime: '02:00 PM',
        endTime: '04:00 PM',
        priority: 'High',
        isCompleted: false,
      );

      final eventTomorrow = PlannerEvent(
        title: 'System Design Mock Interview',
        eventType: 'Mock Interview',
        targetDate: tomorrowStr,
        startTime: '05:00 PM',
        priority: 'Medium',
        isCompleted: false,
      );

      final idToday = await plannerRepo.addEvent(eventToday);
      final idTomorrow = await plannerRepo.addEvent(eventTomorrow);

      expect(idToday, greaterThan(0));
      expect(idTomorrow, greaterThan(0));

      // Date filtering
      final todayEvents = await plannerRepo.getEventsForDate(todayStr);
      expect(todayEvents.any((e) => e.id == idToday), isTrue);
      expect(todayEvents.any((e) => e.id == idTomorrow), isFalse);

      // Upcoming events query
      final upcoming = await plannerRepo.getUpcomingEvents(limit: 10);
      expect(
          upcoming.any((e) => e.id == idToday || e.id == idTomorrow), isTrue);

      // Toggle complete
      await plannerRepo.toggleEventCompleted(idToday, false);
      final completedEvent = await plannerRepo.getEventById(idToday);
      expect(completedEvent!.isCompleted, isTrue);

      // Event counts
      final counts = await plannerRepo.getEventCounts();
      expect(counts['total'], greaterThanOrEqualTo(2));

      // Cleanup
      await plannerRepo.deleteEvent(idToday);
      await plannerRepo.deleteEvent(idTomorrow);

      final afterDelete = await plannerRepo.getEventById(idToday);
      expect(afterDelete, isNull);
    });
  });
}
