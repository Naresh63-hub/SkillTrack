import 'package:flutter_test/flutter_test.dart';
import 'package:skilltrack/core/utils/progress_calculator.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';
import 'package:skilltrack/models/task_model.dart';
import 'package:skilltrack/models/placement_topic.dart';
import 'package:skilltrack/models/interview_question.dart';

void main() {
  group('ProgressCalculator Unit Tests', () {
    test('Calculates empty records as zero progress', () {
      final metrics = ProgressCalculator.calculateAll(
        skills: [],
        projects: [],
        tasks: [],
        placementTopics: [],
        interviewQuestions: [],
      );

      expect(metrics.overallPercentage, 0.0);
      expect(metrics.skillsPercentage, 0.0);
      expect(metrics.projectsPercentage, 0.0);
      expect(metrics.tasksPercentage, 0.0);
      expect(metrics.placementPercentage, 0.0);
    });

    test('Calculates skills average correctly', () {
      final skills = [
        Skill(name: 'Flutter', category: 'Mobile', progressPercentage: 80.0),
        Skill(name: 'Python', category: 'Backend', progressPercentage: 60.0),
      ];

      final score = ProgressCalculator.calculateSkillsProgress(skills);
      expect(score, 70.0);
    });

    test('Calculates project status weights correctly', () {
      final projects = [
        Project(
            name: 'P1',
            shortDescription: 'desc',
            category: 'Mobile',
            technologies: ['Flutter'],
            status: 'Completed'), // 100
        Project(
            name: 'P2',
            shortDescription: 'desc',
            category: 'Web',
            technologies: ['React'],
            status: 'In Progress'), // 50
      ];

      final score = ProgressCalculator.calculateProjectsProgress(projects);
      expect(score, 75.0);
    });

    test('Calculates task completion ratio correctly', () {
      final tasks = [
        TaskModel(
            title: 'T1',
            category: 'DSA',
            dueDate: '2026-10-30',
            isCompleted: true),
        TaskModel(
            title: 'T2',
            category: 'DSA',
            dueDate: '2026-10-30',
            isCompleted: false),
        TaskModel(
            title: 'T3',
            category: 'DSA',
            dueDate: '2026-10-30',
            isCompleted: true),
        TaskModel(
            title: 'T4',
            category: 'DSA',
            dueDate: '2026-10-30',
            isCompleted: false),
      ];

      final score = ProgressCalculator.calculateTasksProgress(tasks);
      expect(score, 50.0);
    });

    test('Calculates 4-pillar overall weighted score correctly', () {
      final skills = [
        Skill(name: 'Flutter', category: 'Mobile', progressPercentage: 100.0)
      ]; // 100 * 0.25 = 25
      final projects = [
        Project(
            name: 'P1',
            shortDescription: 'desc',
            category: 'Mobile',
            technologies: ['Flutter'],
            status: 'Completed')
      ]; // 100 * 0.25 = 25
      final tasks = [
        TaskModel(
            title: 'T1',
            category: 'DSA',
            dueDate: '2026-10-30',
            isCompleted: true)
      ]; // 100 * 0.25 = 25
      final topics = [
        PlacementTopic(
            track: 'Coding', topicName: 'Arrays', completionStatus: 'Completed')
      ]; // 100
      final questions = [
        InterviewQuestion(category: 'HR', question: 'Q', status: 'Completed')
      ]; // 100

      final metrics = ProgressCalculator.calculateAll(
        skills: skills,
        projects: projects,
        tasks: tasks,
        placementTopics: topics,
        interviewQuestions: questions,
      );

      // (100*0.25) + (100*0.25) + (100*0.25) + (placement*0.25)
      expect(metrics.overallPercentage, greaterThan(75.0));
    });
  });
}
