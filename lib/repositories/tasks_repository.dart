import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/task_model.dart';
import '../models/learning_goal.dart';

class TasksRepository {
  final DatabaseHelper _dbHelper;

  TasksRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<TaskModel>> getAllTasks({
    String? category,
    String? priority,
    bool? isCompleted,
    String? searchQuery,
    String sortBy = 'due_date_asc',
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    }

    if (priority != null && priority.isNotEmpty && priority != 'All') {
      final pCond = 'priority = ?';
      whereClause = whereClause == null ? pCond : '$whereClause AND $pCond';
      whereArgs.add(priority);
    }

    if (isCompleted != null) {
      final cCond = 'is_completed = ?';
      whereClause = whereClause == null ? cCond : '$whereClause AND $cCond';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sCond = '(title LIKE ? OR description LIKE ?)';
      whereClause = whereClause == null ? sCond : '$whereClause AND $sCond';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    String orderBy;
    switch (sortBy) {
      case 'due_date_desc':
        orderBy = 'due_date DESC';
        break;
      case 'priority_desc':
        // High, Medium, Low
        orderBy =
            "CASE priority WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 WHEN 'Low' THEN 3 ELSE 4 END ASC, due_date ASC";
        break;
      case 'due_date_asc':
      default:
        orderBy = 'due_date ASC';
        break;
    }

    final results = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return results.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<TaskModel?> getTaskById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return TaskModel.fromMap(results.first);
  }

  Future<int> addTask(TaskModel task) async {
    final db = await _dbHelper.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(TaskModel task) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> toggleTaskComplete(int id, bool currentStatus) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'tasks',
      {
        'is_completed': currentStatus ? 0 : 1,
        'completed_at': currentStatus ? null : now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getTaskCounts() async {
    final db = await _dbHelper.database;
    final completedCount = Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COUNT(*) FROM tasks WHERE is_completed = 1'),
        ) ??
        0;
    final pendingCount = Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COUNT(*) FROM tasks WHERE is_completed = 0'),
        ) ??
        0;
    return {
      'completed': completedCount,
      'pending': pendingCount,
      'total': completedCount + pendingCount,
    };
  }

  Future<List<TaskModel>> getUpcomingDeadlines({int limit = 4}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'tasks',
      where: 'is_completed = 0',
      orderBy: 'due_date ASC',
      limit: limit,
    );
    return results.map((m) => TaskModel.fromMap(m)).toList();
  }

  // --- Learning Goals ---
  Future<List<LearningGoal>> getLearningGoals() async {
    final db = await _dbHelper.database;
    final results =
        await db.query('learning_goals', orderBy: 'created_at DESC');
    return results.map((m) => LearningGoal.fromMap(m)).toList();
  }

  Future<int> addLearningGoal(LearningGoal goal) async {
    final db = await _dbHelper.database;
    return await db.insert('learning_goals', goal.toMap());
  }

  Future<int> updateLearningGoal(LearningGoal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      'learning_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> incrementGoal(int id) async {
    final db = await _dbHelper.database;
    final goalRes =
        await db.query('learning_goals', where: 'id = ?', whereArgs: [id]);
    if (goalRes.isEmpty) return 0;
    final goal = LearningGoal.fromMap(goalRes.first);
    final newCount = goal.currentCount + 1;
    final isDone = newCount >= goal.targetCount;
    return await db.update(
      'learning_goals',
      {
        'current_count': newCount,
        'is_completed': isDone ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLearningGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('learning_goals', where: 'id = ?', whereArgs: [id]);
  }
}
