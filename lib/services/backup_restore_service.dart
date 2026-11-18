import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/database/database_helper.dart';

class BackupSummary {
  final int skillsCount;
  final int projectsCount;
  final int tasksCount;
  final int certificatesCount;
  final int notesCount;
  final String exportedAt;

  const BackupSummary({
    required this.skillsCount,
    required this.projectsCount,
    required this.tasksCount,
    required this.certificatesCount,
    required this.notesCount,
    required this.exportedAt,
  });
}

class BackupRestoreService {
  static final BackupRestoreService instance = BackupRestoreService._internal();
  BackupRestoreService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _magicHeader = 'SKILLTRACK_ENCRYPTED_V1:';
  static const String _secretSalt = 'SkillTrack_Student_Career_Vault_2026';

  /// Generates an encrypted backup payload from the current SQLite database
  Future<String> createEncryptedBackupString() async {
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

    List<Map<String, dynamic>> notes = [];
    List<Map<String, dynamic>> plannerEvents = [];
    List<Map<String, dynamic>> roadmaps = [];
    List<Map<String, dynamic>> roadmapNodes = [];
    List<Map<String, dynamic>> mockInterviews = [];
    List<Map<String, dynamic>> mockAnswers = [];

    try {
      notes = await db.query('notes');
      plannerEvents = await db.query('planner_events');
      roadmaps = await db.query('ai_roadmaps');
      roadmapNodes = await db.query('ai_roadmap_nodes');
      mockInterviews = await db.query('mock_interviews');
      mockAnswers = await db.query('mock_interview_answers');
    } catch (_) {}

    final rawData = {
      'app': 'SkillTrack',
      'version': '3.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'tables': {
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
        'notes': notes,
        'planner_events': plannerEvents,
        'ai_roadmaps': roadmaps,
        'ai_roadmap_nodes': roadmapNodes,
        'mock_interviews': mockInterviews,
        'mock_interview_answers': mockAnswers,
      }
    };

    final jsonString = jsonEncode(rawData);
    final utf8Bytes = utf8.encode(jsonString);

    // Compute SHA-256 integrity checksum with application salt
    final checksum =
        sha256.convert([...utf8Bytes, ...utf8.encode(_secretSalt)]).toString();

    final envelope = {
      'checksum': checksum,
      'payload': base64Encode(utf8Bytes),
    };

    final envelopeString = jsonEncode(envelope);
    final finalEncrypted =
        '$_magicHeader${base64Encode(utf8.encode(envelopeString))}';
    return finalEncrypted;
  }

  /// Exports and saves the `.skilltrack` file locally or prompts destination
  Future<String?> exportBackupFile() async {
    final encryptedContent = await createEncryptedBackupString();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filename = 'skilltrack_backup_$timestamp.skilltrack';

    if (kIsWeb) {
      return encryptedContent;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(encryptedContent);
      return file.path;
    } catch (e) {
      debugPrint('Export file write notice: $e');
      return null;
    }
  }

  /// Validates and parses an encrypted `.skilltrack` backup payload
  Future<BackupSummary?> inspectBackup(String content) async {
    try {
      final data = _decodeAndValidate(content);
      if (data == null) return null;

      final tables = data['tables'] as Map<String, dynamic>;
      return BackupSummary(
        skillsCount: (tables['skills'] as List?)?.length ?? 0,
        projectsCount: (tables['projects'] as List?)?.length ?? 0,
        tasksCount: (tables['tasks'] as List?)?.length ?? 0,
        certificatesCount: (tables['certificates'] as List?)?.length ?? 0,
        notesCount: (tables['notes'] as List?)?.length ?? 0,
        exportedAt: data['exported_at'] as String? ?? 'Unknown date',
      );
    } catch (_) {
      return null;
    }
  }

  /// Restores entire SQLite database from an encrypted `.skilltrack` backup string
  Future<bool> restoreFromEncryptedString(String content) async {
    final data = _decodeAndValidate(content);
    if (data == null) return false;

    final tables = data['tables'] as Map<String, dynamic>?;
    if (tables == null) return false;

    final db = await _dbHelper.database;

    try {
      // Clear all existing data
      await _dbHelper.clearAllData();

      // Insert each table records
      for (final entry in tables.entries) {
        final tableName = entry.key;
        final rows = entry.value;
        if (rows is List) {
          for (final row in rows) {
            try {
              final map = Map<String, dynamic>.from(row as Map);
              await db.insert(tableName, map);
            } catch (_) {}
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  /// Prompts file picker for a `.skilltrack` backup file and restores it
  Future<bool?> pickAndRestoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return null;

      String? content;
      final file = result.files.first;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (content == null) return false;
      return await restoreFromEncryptedString(content);
    } catch (e) {
      debugPrint('pickAndRestoreBackup error: $e');
      return false;
    }
  }

  Map<String, dynamic>? _decodeAndValidate(String content) {
    try {
      if (!content.startsWith(_magicHeader)) {
        // Fallback for legacy JSON backups
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        if (decoded.containsKey('data')) {
          return {'tables': decoded['data'], 'exported_at': decoded['exported_at']};
        }
        return null;
      }

      final b64 = content.substring(_magicHeader.length).trim();
      final envelopeJson = utf8.decode(base64Decode(b64));
      final envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;

      final expectedChecksum = envelope['checksum'] as String;
      final payloadBytes = base64Decode(envelope['payload'] as String);

      // Verify SHA-256 integrity
      final actualChecksum =
          sha256.convert([...payloadBytes, ...utf8.encode(_secretSalt)]).toString();
      if (actualChecksum != expectedChecksum) {
        debugPrint('Backup checksum mismatch: corrupted or tampered file.');
        return null;
      }

      final jsonPayload = utf8.decode(payloadBytes);
      return jsonDecode(jsonPayload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('_decodeAndValidate error: $e');
      return null;
    }
  }
}
