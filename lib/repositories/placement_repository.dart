import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/placement_topic.dart';
import '../models/interview_question.dart';
import '../models/job_application.dart';

class PlacementRepository {
  final DatabaseHelper _dbHelper;

  PlacementRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Topics by Track ('Coding', 'CoreCS', 'Aptitude')
  Future<List<PlacementTopic>> getTopicsByTrack(String track) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'placement_topics',
      where: 'track = ?',
      whereArgs: [track],
      orderBy: 'id ASC',
    );
    return results.map((m) => PlacementTopic.fromMap(m)).toList();
  }

  Future<int> addPlacementTopic(PlacementTopic topic) async {
    final db = await _dbHelper.database;
    return await db.insert('placement_topics', topic.toMap());
  }

  Future<int> updatePlacementTopic(PlacementTopic topic) async {
    final db = await _dbHelper.database;
    return await db.update(
      'placement_topics',
      topic.toMap(),
      where: 'id = ?',
      whereArgs: [topic.id],
    );
  }

  Future<int> deletePlacementTopic(int id) async {
    final db = await _dbHelper.database;
    return await db
        .delete('placement_topics', where: 'id = ?', whereArgs: [id]);
  }

  // Interview Questions
  Future<List<InterviewQuestion>> getInterviewQuestions(
      {String? category, String? status}) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    }

    if (status != null && status.isNotEmpty && status != 'All') {
      final sCond = 'status = ?';
      whereClause = whereClause == null ? sCond : '$whereClause AND $sCond';
      whereArgs.add(status);
    }

    final results = await db.query(
      'interview_questions',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id ASC',
    );
    return results.map((m) => InterviewQuestion.fromMap(m)).toList();
  }

  Future<int> addInterviewQuestion(InterviewQuestion question) async {
    final db = await _dbHelper.database;
    return await db.insert('interview_questions', question.toMap());
  }

  Future<int> updateInterviewQuestion(InterviewQuestion question) async {
    final db = await _dbHelper.database;
    return await db.update(
      'interview_questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteInterviewQuestion(int id) async {
    final db = await _dbHelper.database;
    return await db
        .delete('interview_questions', where: 'id = ?', whereArgs: [id]);
  }

  // Job Applications
  Future<List<JobApplication>> getJobApplications(
      {String? status, String? searchQuery}) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status != 'All') {
      whereClause = 'status = ?';
      whereArgs.add(status);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sCond =
          '(company_name LIKE ? OR role LIKE ? OR required_skills LIKE ?)';
      whereClause = whereClause == null ? sCond : '$whereClause AND $sCond';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final results = await db.query(
      'job_applications',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'application_date DESC',
    );
    return results.map((m) => JobApplication.fromMap(m)).toList();
  }

  Future<int> addJobApplication(JobApplication application) async {
    final db = await _dbHelper.database;
    return await db.insert('job_applications', application.toMap());
  }

  Future<int> updateJobApplication(JobApplication application) async {
    final db = await _dbHelper.database;
    return await db.update(
      'job_applications',
      application.toMap(),
      where: 'id = ?',
      whereArgs: [application.id],
    );
  }

  Future<int> deleteJobApplication(int id) async {
    final db = await _dbHelper.database;
    return await db
        .delete('job_applications', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JobApplication>> getUpcomingInterviews() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'job_applications',
      where: "interview_date IS NOT NULL AND interview_date != ''",
      orderBy: 'interview_date ASC',
    );
    final apps = results.map((m) => JobApplication.fromMap(m)).toList();
    return apps.where((a) => a.hasUpcomingInterview).toList();
  }

  Future<int> getTotalApplicationsCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM job_applications'));
    return count ?? 0;
  }
}
