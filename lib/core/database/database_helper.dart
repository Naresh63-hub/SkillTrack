import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'skilltrack_app.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // 1. student_profile table
      await txn.execute('''
        CREATE TABLE student_profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          city TEXT,
          college TEXT,
          degree TEXT,
          branch TEXT,
          current_semester TEXT,
          graduation_year TEXT,
          target_job_role TEXT,
          github_url TEXT,
          linkedin_url TEXT,
          portfolio_url TEXT,
          bio TEXT,
          updated_at TEXT NOT NULL
        )
      ''');

      // 2. skills table
      await txn.execute('''
        CREATE TABLE skills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          proficiency_level TEXT NOT NULL,
          progress_percentage REAL NOT NULL DEFAULT 0.0,
          date_started TEXT,
          target_completion_date TEXT,
          learning_resource_url TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 3. certificates table
      await txn.execute('''
        CREATE TABLE certificates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          issuing_organization TEXT NOT NULL,
          category TEXT NOT NULL,
          completion_date TEXT NOT NULL,
          expiration_date TEXT,
          credential_id TEXT,
          verification_url TEXT,
          description TEXT,
          local_file_path TEXT,
          preview_image_path TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 4. projects table
      await txn.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          short_description TEXT NOT NULL,
          detailed_description TEXT,
          category TEXT NOT NULL,
          technologies TEXT NOT NULL,
          status TEXT NOT NULL,
          start_date TEXT,
          completion_date TEXT,
          github_url TEXT,
          live_demo_url TEXT,
          image_path TEXT,
          key_features TEXT,
          problems_solved TEXT,
          what_learned TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 5. tasks table
      await txn.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          priority TEXT NOT NULL,
          creation_date TEXT NOT NULL,
          due_date TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          reminder_date_time TEXT,
          related_skill_id INTEGER,
          related_project_id INTEGER,
          FOREIGN KEY (related_skill_id) REFERENCES skills (id) ON DELETE SET NULL,
          FOREIGN KEY (related_project_id) REFERENCES projects (id) ON DELETE SET NULL
        )
      ''');

      // 6. learning_goals table
      await txn.execute('''
        CREATE TABLE learning_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          goal_type TEXT NOT NULL,
          target_count INTEGER NOT NULL DEFAULT 1,
          current_count INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          target_date TEXT
        )
      ''');

      // 7. placement_topics table
      await txn.execute('''
        CREATE TABLE placement_topics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          track TEXT NOT NULL,
          topic_name TEXT NOT NULL,
          category TEXT,
          problems_solved INTEGER NOT NULL DEFAULT 0,
          problems_attempted INTEGER NOT NULL DEFAULT 0,
          practice_links TEXT,
          notes TEXT,
          difficulty_level TEXT NOT NULL DEFAULT 'Medium',
          completion_status TEXT NOT NULL DEFAULT 'Not Started',
          updated_at TEXT NOT NULL
        )
      ''');

      // 8. interview_questions table
      await txn.execute('''
        CREATE TABLE interview_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          question TEXT NOT NULL,
          answer TEXT,
          status TEXT NOT NULL DEFAULT 'Not Started',
          updated_at TEXT NOT NULL
        )
      ''');

      // 9. job_applications table
      await txn.execute('''
        CREATE TABLE job_applications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          company_name TEXT NOT NULL,
          role TEXT NOT NULL,
          application_date TEXT NOT NULL,
          application_deadline TEXT,
          status TEXT NOT NULL DEFAULT 'Applied',
          job_description_url TEXT,
          required_skills TEXT,
          interview_date TEXT,
          notes TEXT,
          updated_at TEXT NOT NULL
        )
      ''');

      // 10. education table
      await txn.execute('''
        CREATE TABLE education (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          institution TEXT NOT NULL,
          degree TEXT NOT NULL,
          field_of_study TEXT NOT NULL,
          start_year TEXT NOT NULL,
          end_year TEXT NOT NULL,
          grade_or_cgpa TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 11. achievements table
      await txn.execute('''
        CREATE TABLE achievements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          date_achieved TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Indexes for performance
      await txn
          .execute('CREATE INDEX idx_skills_category ON skills (category);');
      await txn.execute(
          'CREATE INDEX idx_skills_progress ON skills (progress_percentage);');
      await txn
          .execute('CREATE INDEX idx_projects_status ON projects (status);');
      await txn.execute('CREATE INDEX idx_tasks_due_date ON tasks (due_date);');
      await txn.execute(
          'CREATE INDEX idx_tasks_is_completed ON tasks (is_completed);');
      await txn.execute(
          'CREATE INDEX idx_placement_track ON placement_topics (track);');
      await txn.execute(
          'CREATE INDEX idx_placement_status ON placement_topics (completion_status);');
      await txn.execute(
          'CREATE INDEX idx_interview_status ON interview_questions (status);');
      await txn
          .execute('CREATE INDEX idx_job_status ON job_applications (status);');
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Structured migrations for future database versions
  }

  /// Clears all application data from the SQLite tables.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
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
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
