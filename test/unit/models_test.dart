import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/constants/app_strings.dart';
import 'package:skilltrack/models/student_profile.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';
import 'package:skilltrack/models/placement_topic.dart';
import 'package:skilltrack/models/task_model.dart';

void main() {
  group('Model Serialization & Logic Tests', () {
    test('StudentProfile fromMap and toMap round-trip', () {
      final profile = StudentProfile(
        id: 1,
        name: 'Naresh Kumar',
        email: 'naresh@college.edu',
        college: 'NIT',
        targetJobRole: 'Flutter Engineer',
      );

      final map = profile.toMap();
      final revived = StudentProfile.fromMap(map);

      expect(revived.name, 'Naresh Kumar');
      expect(revived.email, 'naresh@college.edu');
      expect(revived.college, 'NIT');
      expect(revived.targetJobRole, 'Flutter Engineer');
    });

    test('Skill overdue logic works as expected', () {
      final pastDate =
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final futureDate =
          DateTime.now().add(const Duration(days: 15)).toIso8601String();

      final overdueSkill = Skill(
        name: 'Overdue Skill',
        category: 'Web',
        targetCompletionDate: pastDate,
        progressPercentage: 50.0,
      );
      expect(overdueSkill.isOverdue, isTrue);

      final completedSkill = Skill(
        name: 'Done Skill',
        category: 'Web',
        targetCompletionDate: pastDate,
        progressPercentage: 100.0,
      );
      expect(completedSkill.isOverdue, isFalse);

      final onTrackSkill = Skill(
        name: 'On Track',
        category: 'Mobile',
        targetCompletionDate: futureDate,
        progressPercentage: 20.0,
      );
      expect(onTrackSkill.isOverdue, isFalse);
    });

    test(
        'Project serialization handles technology list and deployment links correctly',
        () {
      final project = Project(
        name: 'SkillTrack',
        shortDescription: 'Student Career Tracker',
        category: 'Mobile',
        technologies: ['Flutter', 'Dart', 'SQLite'],
        status: 'Completed',
        githubUrl: 'https://github.com/user/skilltrack',
        vercelUrl: 'https://skilltrack.vercel.app',
        renderUrl: 'https://skilltrack-api.onrender.com',
        liveDemoUrl: 'https://skilltrack.app',
      );

      expect(project.hasLinks, isTrue);
      expect(project.deploymentLinks.length, 4);
      expect(project.deploymentLinks.any((l) => l.type == 'vercel'), isTrue);
      expect(project.deploymentLinks.any((l) => l.type == 'render'), isTrue);

      final map = project.toMap();
      expect(map['technologies'], 'Flutter,Dart,SQLite');
      expect(map['vercel_url'], 'https://skilltrack.vercel.app');
      expect(map['render_url'], 'https://skilltrack-api.onrender.com');

      final revived = Project.fromMap(map);
      expect(revived.technologies.length, 3);
      expect(revived.technologies, contains('Flutter'));
      expect(revived.isCompleted, isTrue);
      expect(revived.vercelUrl, 'https://skilltrack.vercel.app');
      expect(revived.renderUrl, 'https://skilltrack-api.onrender.com');
    });

    test('PlacementTopic completion percentage calculation', () {
      final topic = PlacementTopic(
        track: 'Coding',
        topicName: 'Binary Trees',
        problemsSolved: 15,
        problemsAttempted: 20,
      );

      expect(topic.completionPercentage, 75.0);

      final completedTopic = PlacementTopic(
        track: 'Coding',
        topicName: 'Graphs',
        completionStatus: 'Completed',
      );

      expect(completedTopic.completionPercentage, 100.0);
    });

    test('TaskModel early reminder serialization and label calculation', () {
      expect(AppStrings.taskCategories, contains('Call / Meeting'));

      final task = TaskModel(
        id: 42,
        title: 'Weekly 1-on-1 Mentor Sync',
        category: 'Call / Meeting',
        priority: 'High',
        dueDate: '2026-11-20T15:00:00.000',
        earlyReminderMinutes: 15,
        reminderDateTime: '2026-11-20T14:45:00.000',
      );

      expect(task.category, 'Call / Meeting');
      expect(task.earlyReminderMinutes, 15);
      expect(task.earlyReminderLabel, '15 mins early');

      final atTime = task.copyWith(earlyReminderMinutes: 0);
      expect(atTime.earlyReminderLabel, 'At due time');

      final oneHour = task.copyWith(earlyReminderMinutes: 60);
      expect(oneHour.earlyReminderLabel, '1 hour early');

      final oneDay = task.copyWith(earlyReminderMinutes: 1440);
      expect(oneDay.earlyReminderLabel, '1 day early');

      final map = task.toMap();
      expect(map['early_reminder_minutes'], 15);
      expect(map['category'], 'Call / Meeting');

      final revived = TaskModel.fromMap(map);
      expect(revived.id, 42);
      expect(revived.title, 'Weekly 1-on-1 Mentor Sync');
      expect(revived.category, 'Call / Meeting');
      expect(revived.earlyReminderMinutes, 15);
      expect(revived.earlyReminderLabel, '15 mins early');
    });
  });
}
