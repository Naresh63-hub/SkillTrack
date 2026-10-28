import 'dart:convert';
import '../core/database/database_helper.dart';

class ExportImportService {
  final DatabaseHelper _dbHelper;

  ExportImportService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Exports all tables from SQLite to a single structured JSON string.
  Future<String> exportDataToJson() async {
    final db = await _dbHelper.database;

    final profile = await db.query('student_profile');
    final skills = await db.query('skills');
    final certificates = await db.query('certificates');
    final projects = await db.query('projects');
    final tasks = await db.query('tasks');
    final learningGoals = await db.query('learning_goals');
    final placementTopics = await db.query('placement_topics');
    final interviewQuestions = await db.query('interview_questions');
    final jobApplications = await db.query('job_applications');
    final education = await db.query('education');
    final achievements = await db.query('achievements');

    final exportMap = {
      'app': 'SkillTrack',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'student_profile': profile,
        'skills': skills,
        'certificates': certificates,
        'projects': projects,
        'tasks': tasks,
        'learning_goals': learningGoals,
        'placement_topics': placementTopics,
        'interview_questions': interviewQuestions,
        'job_applications': jobApplications,
        'education': education,
        'achievements': achievements,
      }
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Imports JSON backup data safely using a single database transaction.
  Future<bool> importDataFromJson(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      if (!decoded.containsKey('data')) return false;

      final data = decoded['data'] as Map<String, dynamic>;
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Clear old records
        await txn.delete('achievements');
        await txn.delete('education');
        await txn.delete('job_applications');
        await txn.delete('interview_questions');
        await txn.delete('placement_topics');
        await txn.delete('learning_goals');
        await txn.delete('tasks');
        await txn.delete('projects');
        await txn.delete('certificates');
        await txn.delete('skills');
        await txn.delete('student_profile');

        // Insert new records
        if (data['student_profile'] is List) {
          for (final row in data['student_profile'] as List) {
            await txn.insert(
                'student_profile', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['skills'] is List) {
          for (final row in data['skills'] as List) {
            await txn.insert('skills', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['certificates'] is List) {
          for (final row in data['certificates'] as List) {
            await txn.insert(
                'certificates', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['projects'] is List) {
          for (final row in data['projects'] as List) {
            await txn.insert('projects', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['tasks'] is List) {
          for (final row in data['tasks'] as List) {
            await txn.insert('tasks', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['learning_goals'] is List) {
          for (final row in data['learning_goals'] as List) {
            await txn.insert(
                'learning_goals', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['placement_topics'] is List) {
          for (final row in data['placement_topics'] as List) {
            await txn.insert(
                'placement_topics', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['interview_questions'] is List) {
          for (final row in data['interview_questions'] as List) {
            await txn.insert(
                'interview_questions', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['job_applications'] is List) {
          for (final row in data['job_applications'] as List) {
            await txn.insert(
                'job_applications', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['education'] is List) {
          for (final row in data['education'] as List) {
            await txn.insert(
                'education', Map<String, dynamic>.from(row as Map));
          }
        }
        if (data['achievements'] is List) {
          for (final row in data['achievements'] as List) {
            await txn.insert(
                'achievements', Map<String, dynamic>.from(row as Map));
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
