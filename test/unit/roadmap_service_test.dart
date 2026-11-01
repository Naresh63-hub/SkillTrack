import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:skilltrack/core/constants/app_strings.dart';
import 'package:skilltrack/core/database/database_helper.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/repositories/skills_repository.dart';
import 'package:skilltrack/services/roadmap_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RoadmapService & Model Specifications', () {
    test('Provides all 6 required target career roles', () {
      final roadmaps = RoadmapService.getAvailableRoadmaps();
      expect(roadmaps.length, 6);

      final roleNames = roadmaps.map((r) => r.roleName).toList();
      expect(roleNames, contains('Python Developer'));
      expect(roleNames, contains('Full Stack Developer'));
      expect(roleNames, contains('Flutter Developer'));
      expect(roleNames, contains('Data Analyst'));
      expect(roleNames, contains('AI/ML Engineer'));
      expect(roleNames, contains('Java Developer'));
    });

    test('Each roadmap contains exactly 8 curated skills with valid categories',
        () {
      final roadmaps = RoadmapService.getAvailableRoadmaps();
      final validCategories = AppStrings.skillCategories.toSet();

      for (final roadmap in roadmaps) {
        expect(roadmap.skills.length, 8,
            reason: '${roadmap.roleName} should have 8 skills');

        for (var i = 0; i < roadmap.skills.length; i++) {
          final skill = roadmap.skills[i];
          expect(skill.order, i + 1);
          expect(skill.name.trim().isNotEmpty, isTrue);
          expect(validCategories.contains(skill.category), isTrue,
              reason: '${skill.name} has category "${skill.category}"');
        }
      }
    });

    test(
        'Flutter Developer roadmap matches exact recommended skills and initial 0% progress',
        () {
      final flutterRoadmap =
          RoadmapService.getRoadmapById('flutter_developer')!;
      expect(flutterRoadmap, isNotNull);

      final skillNames = flutterRoadmap.skills.map((s) => s.name).toList();
      expect(skillNames, [
        'Dart Programming',
        'Flutter Fundamentals',
        'UI Development',
        'Navigation and State Management',
        'REST APIs',
        'SQLite and Local Storage',
        'Git and GitHub',
        'Testing and App Deployment',
      ]);

      for (final item in flutterRoadmap.skills) {
        final skill = item.toSkill();
        expect(skill.progressPercentage, 0.0);
        expect(skill.name, item.name);
        expect(skill.category, item.category);
      }
    });

    test('Roadmap lookup by ID and role name works accurately', () {
      expect(RoadmapService.getRoadmapById('python_developer')?.roleName,
          'Python Developer');
      expect(RoadmapService.getRoadmapByRoleName('Flutter')?.id,
          'flutter_developer');
      expect(
          RoadmapService.getRoadmapByRoleName('ai / ml')?.id, 'ai_ml_engineer');
      expect(RoadmapService.getRoadmapByRoleName('java')?.id, 'java_developer');
    });
  });

  group('Roadmap Persistence & Import Tests', () {
    late SkillsRepository skillsRepo;
    late RoadmapService roadmapService;

    setUp(() async {
      await DatabaseHelper.instance.database;
      skillsRepo = SkillsRepository();
      roadmapService = RoadmapService(skillsRepository: skillsRepo);

      // Clean skills table before each test
      final db = await DatabaseHelper.instance.database;
      await db.delete('skills');
    });

    test('Imports all 8 skills when student has no existing skills', () async {
      final flutterRoadmap =
          RoadmapService.getRoadmapById('flutter_developer')!;
      final result = await roadmapService.importRoadmap(flutterRoadmap);

      expect(result.totalSkills, 8);
      expect(result.addedCount, 8);
      expect(result.skippedCount, 0);
      expect(result.hasAddedAny, isTrue);

      final dbSkills = await skillsRepo.getAllSkills();
      expect(dbSkills.length, 8);

      for (final s in dbSkills) {
        expect(s.progressPercentage, 0.0,
            reason: '${s.name} must start with 0% progress');
      }
    });

    test('Duplicate prevention: importing the same roadmap twice is idempotent',
        () async {
      final pythonRoadmap = RoadmapService.getRoadmapById('python_developer')!;

      // First import
      final firstResult = await roadmapService.importRoadmap(pythonRoadmap);
      expect(firstResult.addedCount, 8);
      expect(firstResult.skippedCount, 0);

      final countAfterFirst = await skillsRepo.getSkillsCount();
      expect(countAfterFirst, 8);

      // Second import (idempotent duplicate prevention)
      final secondResult = await roadmapService.importRoadmap(pythonRoadmap);
      expect(secondResult.addedCount, 0);
      expect(secondResult.skippedCount, 8);
      expect(secondResult.allWereAlreadyImported, isTrue);

      // Verify no duplicates were created
      final countAfterSecond = await skillsRepo.getSkillsCount();
      expect(countAfterSecond, 8);
    });

    test(
        'Preserves student existing skills and their progress when roadmap is imported',
        () async {
      // Pre-populate student database with "Dart Programming" at 75% progress
      final existingSkill = Skill(
        name: 'Dart Programming',
        category: 'Programming Languages',
        proficiencyLevel: 'Intermediate',
        progressPercentage: 75.0,
        notes: 'Already solved 100+ LeetCode problems in Dart',
      );
      final id = await skillsRepo.addSkill(existingSkill);
      expect(id, greaterThan(0));

      final flutterRoadmap =
          RoadmapService.getRoadmapById('flutter_developer')!;
      final result = await roadmapService.importRoadmap(flutterRoadmap);

      // 1 skipped (Dart Programming), 7 added
      expect(result.addedCount, 7);
      expect(result.skippedCount, 1);
      expect(result.skippedSkillNames, contains('Dart Programming'));

      // Check Dart Programming is preserved exactly
      final allSkills = await skillsRepo.getAllSkills();
      expect(allSkills.length, 8);

      final dartSkill =
          allSkills.firstWhere((s) => s.name == 'Dart Programming');
      expect(dartSkill.progressPercentage, 75.0,
          reason: 'Existing progress must never be reset');
      expect(dartSkill.notes, 'Already solved 100+ LeetCode problems in Dart');

      // Check that newly imported skills have 0% progress
      final flutterFund =
          allSkills.firstWhere((s) => s.name == 'Flutter Fundamentals');
      expect(flutterFund.progressPercentage, 0.0);
    });

    test('Case-insensitive duplicate prevention avoids redundant skills',
        () async {
      // Add lowercase 'git and github'
      await skillsRepo.addSkill(Skill(
        name: 'git and github',
        category: 'Developer Tools',
        proficiencyLevel: 'Beginner',
        progressPercentage: 40.0,
      ));

      final flutterRoadmap =
          RoadmapService.getRoadmapById('flutter_developer')!;
      final result = await roadmapService.importRoadmap(flutterRoadmap);

      expect(result.skippedCount, 1);
      expect(result.addedCount, 7);

      final allSkills = await skillsRepo.getAllSkills();
      final gitSkills = allSkills
          .where((s) => s.name.trim().toLowerCase() == 'git and github')
          .toList();
      expect(gitSkills.length, 1);
      expect(gitSkills.first.progressPercentage, 40.0);
    });

    test('Students can update imported skill progress individually', () async {
      final javaRoadmap = RoadmapService.getRoadmapById('java_developer')!;
      await roadmapService.importRoadmap(javaRoadmap);

      final skills = await skillsRepo.getAllSkills();
      final springBootSkill =
          skills.firstWhere((s) => s.name.contains('Spring Boot'));
      expect(springBootSkill.progressPercentage, 0.0);

      // Student studies and updates progress to 65%
      final updatedSkill = springBootSkill.copyWith(
          progressPercentage: 65.0, notes: 'Built REST API project');
      await skillsRepo.updateSkill(updatedSkill);

      // Re-read from repository to verify persistence
      final refreshed = await skillsRepo.getSkillById(springBootSkill.id!);
      expect(refreshed, isNotNull);
      expect(refreshed!.progressPercentage, 65.0);
      expect(refreshed.notes, 'Built REST API project');
    });
  });
}
