import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltrack/core/utils/streak_calculator.dart';
import 'package:skilltrack/models/task_model.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';
import 'package:skilltrack/models/certificate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakCalculator Comprehensive Unit Tests', () {
    test('Calculates 1 day streak when active today via project update', () {
      final now = DateTime.now();
      final project = Project(
        name: 'Portfolio Website',
        shortDescription: 'Student portfolio',
        category: 'Web Development',
        technologies: ['Flutter'],
        status: 'Completed',
        updatedAt: now.toIso8601String(),
      );

      final streak = StreakCalculator.calculateStreak(
        tasks: [],
        skills: [],
        projects: [project],
      );

      expect(streak, 1);
    });

    test('Calculates multi-day streak across consecutive days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final taskToday = TaskModel(
        title: 'Task today',
        category: 'Technical',
        dueDate: today.toIso8601String(),
        isCompleted: true,
        completedAt: today.toIso8601String(),
      );

      final skillYesterday = Skill(
        name: 'Python',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        updatedAt: yesterday.toIso8601String(),
      );

      final projectTwoDaysAgo = Project(
        name: 'API Service',
        shortDescription: 'Backend',
        category: 'Web',
        technologies: ['Node'],
        updatedAt: twoDaysAgo.toIso8601String(),
      );

      final streak = StreakCalculator.calculateStreak(
        tasks: [taskToday],
        skills: [skillYesterday],
        projects: [projectTwoDaysAgo],
      );

      expect(streak, 3);
    });

    test('Preserves streak from yesterday if student has not completed actions today yet', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final skillYesterday = Skill(
        name: 'Dart',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        updatedAt: yesterday.toIso8601String(),
      );

      final taskTwoDaysAgo = TaskModel(
        title: 'Task 2 days ago',
        category: 'Technical',
        dueDate: twoDaysAgo.toIso8601String(),
        isCompleted: true,
        completedAt: twoDaysAgo.toIso8601String(),
      );

      final streak = StreakCalculator.calculateStreak(
        tasks: [taskTwoDaysAgo],
        skills: [skillYesterday],
        projects: [],
      );

      expect(streak, 2);
    });

    test('Returns 0 when activity is older than yesterday (broken streak)', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      final task = TaskModel(
        title: 'Old task',
        category: 'Technical',
        dueDate: threeDaysAgo.toIso8601String(),
        isCompleted: true,
        completedAt: threeDaysAgo.toIso8601String(),
      );

      final streak = StreakCalculator.calculateStreak(
        tasks: [task],
        skills: [],
      );

      expect(streak, 0);
    });

    test('Persistent recordTodayActive records current day into active dates', () async {
      await StreakCalculator.recordTodayActive();
      final dates = await StreakCalculator.getSavedActiveDates();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(dates.contains(today), isTrue);

      final streak = StreakCalculator.calculateStreak(
        tasks: [],
        skills: [],
        additionalDates: dates,
      );

      expect(streak, 1);
    });
  });
}
