import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'skilltrack_app.db';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      final db = await openDatabase(
        _dbName,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      await _ensureV2Tables(db);
      return db;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        try {
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA busy_timeout = 5000');
        } catch (_) {}
      },
    );
    await _ensureV2Tables(db);
    return db;
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

      // Create v2 tables (AI modules)
      await _executeCreateV2(txn);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureV2Tables(db);
    }
  }

  static Future<void> _executeCreateV2(dynamic executor) async {
    // 12. ai_roadmaps table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS ai_roadmaps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_role TEXT NOT NULL,
        skill_level TEXT NOT NULL DEFAULT 'Beginner',
        overall_progress REAL NOT NULL DEFAULT 0.0,
        summary TEXT,
        skill_gaps TEXT,
        is_ai_generated INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 13. ai_roadmap_nodes table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS ai_roadmap_nodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roadmap_id INTEGER NOT NULL,
        level TEXT NOT NULL DEFAULT 'Beginner',
        topic_title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        estimated_days INTEGER NOT NULL DEFAULT 3,
        resource_title TEXT,
        resource_url TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (roadmap_id) REFERENCES ai_roadmaps (id) ON DELETE CASCADE
      )
    ''');

    // 14. github_profile table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS github_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        name TEXT,
        avatar_url TEXT,
        bio TEXT,
        public_repos INTEGER NOT NULL DEFAULT 0,
        public_gists INTEGER NOT NULL DEFAULT 0,
        followers INTEGER NOT NULL DEFAULT 0,
        following INTEGER NOT NULL DEFAULT 0,
        html_url TEXT,
        connected_at TEXT NOT NULL,
        last_synced_at TEXT
      )
    ''');

    // 15. github_repositories table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS github_repositories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repo_id INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        full_name TEXT NOT NULL,
        description TEXT,
        html_url TEXT NOT NULL,
        language TEXT,
        stargazers_count INTEGER NOT NULL DEFAULT 0,
        forks_count INTEGER NOT NULL DEFAULT 0,
        open_issues_count INTEGER NOT NULL DEFAULT 0,
        is_fork INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT,
        is_imported_to_portfolio INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 16. github_commits_cache table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS github_commits_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repo_name TEXT NOT NULL,
        message TEXT NOT NULL,
        commit_date TEXT NOT NULL,
        commit_url TEXT,
        author_name TEXT
      )
    ''');

    // 17. mock_interviews table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS mock_interviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_role TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL DEFAULT 'Intermediate',
        total_questions INTEGER NOT NULL DEFAULT 5,
        completed_questions INTEGER NOT NULL DEFAULT 0,
        overall_score REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'In Progress',
        feedback_summary TEXT,
        strengths TEXT,
        weaknesses TEXT,
        recommended_topics TEXT,
        is_ai_evaluated INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    // 18. mock_interview_answers table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS mock_interview_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        interview_id INTEGER NOT NULL,
        question_index INTEGER NOT NULL,
        question TEXT NOT NULL,
        user_answer TEXT,
        expected_points TEXT,
        score REAL NOT NULL DEFAULT 0.0,
        feedback TEXT,
        improvement_tips TEXT,
        FOREIGN KEY (interview_id) REFERENCES mock_interviews (id) ON DELETE CASCADE
      )
    ''');

    // 19. career_chat_sessions table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS career_chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 20. career_chat_messages table
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS career_chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        action_type TEXT,
        action_payload TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES career_chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    // V2 Indexes
    await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_roadmap_role ON ai_roadmaps (target_role);');
    await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_roadmap_nodes_road ON ai_roadmap_nodes (roadmap_id);');
    await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_mock_interviews_role ON mock_interviews (job_role);');
    await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_mock_answers_interview ON mock_interview_answers (interview_id);');
    await executor.execute(
        'CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON career_chat_messages (session_id);');
  }

  Future<void> _ensureV2Tables(Database db) async {
    await _executeCreateV2(db);
    try {
      await db.execute(
          'ALTER TABLE ai_roadmaps ADD COLUMN is_ai_generated INTEGER DEFAULT 0;');
    } catch (_) {}
    try {
      await db.execute(
          'ALTER TABLE mock_interviews ADD COLUMN is_ai_evaluated INTEGER DEFAULT 0;');
    } catch (_) {}
  }

  /// Clears all application data from the SQLite tables.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('career_chat_messages');
      await txn.delete('career_chat_sessions');
      await txn.delete('mock_interview_answers');
      await txn.delete('mock_interviews');
      await txn.delete('github_commits_cache');
      await txn.delete('github_repositories');
      await txn.delete('github_profile');
      await txn.delete('ai_roadmap_nodes');
      await txn.delete('ai_roadmaps');
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
