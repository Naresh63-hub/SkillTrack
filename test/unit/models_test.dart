import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/models/student_profile.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';
import 'package:skilltrack/models/placement_topic.dart';

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

    test('Project serialization handles technology list correctly', () {
      final project = Project(
        name: 'SkillTrack',
        shortDescription: 'Student Career Tracker',
        category: 'Mobile',
        technologies: ['Flutter', 'Dart', 'SQLite'],
        status: 'Completed',
      );

      final map = project.toMap();
      expect(map['technologies'], 'Flutter,Dart,SQLite');

      final revived = Project.fromMap(map);
      expect(revived.technologies.length, 3);
      expect(revived.technologies, contains('Flutter'));
      expect(revived.isCompleted, isTrue);
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
  });
}
