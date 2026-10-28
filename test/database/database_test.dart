import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:skilltrack/core/database/database_helper.dart';
import 'package:skilltrack/models/skill.dart';
import 'package:skilltrack/models/project.dart';
import 'package:skilltrack/models/task_model.dart';
import 'package:skilltrack/models/certificate.dart';
import 'package:skilltrack/repositories/skills_repository.dart';
import 'package:skilltrack/repositories/projects_repository.dart';
import 'package:skilltrack/repositories/tasks_repository.dart';
import 'package:skilltrack/repositories/certificates_repository.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for tests on desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database & Repository Integration Tests', () {
    late SkillsRepository skillsRepo;
    late ProjectsRepository projectsRepo;
    late TasksRepository tasksRepo;
    late CertificatesRepository certsRepo;

    setUp(() async {
      // Run helper onCreate
      await DatabaseHelper.instance.database; // Initializes tables
      skillsRepo = SkillsRepository();
      projectsRepo = ProjectsRepository();
      tasksRepo = TasksRepository();
      certsRepo = CertificatesRepository();
    });

    test('Skills CRUD: insert, read, update, delete', () async {
      final skill = Skill(
        name: 'Kotlin',
        category: 'Mobile Development',
        proficiencyLevel: 'Beginner',
        progressPercentage: 25.0,
      );

      final id = await skillsRepo.addSkill(skill);
      expect(id, greaterThan(0));

      final retrieved = await skillsRepo.getSkillById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Kotlin');
      expect(retrieved.progressPercentage, 25.0);

      final updated = retrieved.copyWith(
          progressPercentage: 50.0, proficiencyLevel: 'Intermediate');
      await skillsRepo.updateSkill(updated);

      final checkUpdated = await skillsRepo.getSkillById(id);
      expect(checkUpdated!.progressPercentage, 50.0);
      expect(checkUpdated.proficiencyLevel, 'Intermediate');

      await skillsRepo.deleteSkill(id);
      final checkDeleted = await skillsRepo.getSkillById(id);
      expect(checkDeleted, isNull);
    });

    test('Projects CRUD: insert, search, filter by status', () async {
      final p1 = Project(
        name: 'SkillTrack App',
        shortDescription: 'Student Career Tracker',
        category: 'Mobile Development',
        technologies: ['Flutter', 'SQLite'],
        status: 'Completed',
      );
      final p2 = Project(
        name: 'Web Store',
        shortDescription: 'E-commerce web app',
        category: 'Web Development',
        technologies: ['React', 'Node'],
        status: 'In Progress',
      );

      final id1 = await projectsRepo.addProject(p1);
      final id2 = await projectsRepo.addProject(p2);

      final completedProjects =
          await projectsRepo.getAllProjects(status: 'Completed');
      expect(completedProjects.any((p) => p.name == 'SkillTrack App'), isTrue);

      final searchResults =
          await projectsRepo.getAllProjects(searchQuery: 'Store');
      expect(searchResults.length, 1);
      expect(searchResults.first.name, 'Web Store');

      await projectsRepo.deleteProject(id1);
      await projectsRepo.deleteProject(id2);
    });

    test('Tasks: toggle completion and counts', () async {
      final t1 = TaskModel(
        title: 'Complete unit tests',
        category: 'Technical Skills',
        dueDate: '2026-10-30',
        isCompleted: false,
      );

      final id = await tasksRepo.addTask(t1);
      expect(id, greaterThan(0));

      await tasksRepo.toggleTaskComplete(id, false);
      final taskAfterToggle = await tasksRepo.getTaskById(id);
      expect(taskAfterToggle!.isCompleted, isTrue);
      expect(taskAfterToggle.completedAt, isNotNull);

      await tasksRepo.deleteTask(id);
    });

    test('Certificates: insert and organization filtering', () async {
      final cert = Certificate(
        name: 'AWS Cloud Practitioner',
        issuingOrganization: 'Amazon Web Services',
        category: 'Cloud and DevOps',
        completionDate: '2026-03-15',
        credentialId: 'AWS-12345',
      );

      final id = await certsRepo.addCertificate(cert);
      final certs = await certsRepo.getAllCertificates(
          organization: 'Amazon Web Services');
      expect(certs.any((c) => c.name == 'AWS Cloud Practitioner'), isTrue);

      await certsRepo.deleteCertificate(id);
    });
  });
}
