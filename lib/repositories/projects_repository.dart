import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/project.dart';

class ProjectsRepository {
  final DatabaseHelper _dbHelper;

  ProjectsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Project>> getAllProjects({
    String? status,
    String? technology,
    String? searchQuery,
    String sortBy = 'updated_desc',
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status != 'All') {
      whereClause = 'status = ?';
      whereArgs.add(status);
    }

    if (technology != null && technology.isNotEmpty && technology != 'All') {
      final techCond = 'technologies LIKE ?';
      whereClause =
          whereClause == null ? techCond : '$whereClause AND $techCond';
      whereArgs.add('%$technology%');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchCond =
          '(name LIKE ? OR short_description LIKE ? OR technologies LIKE ?)';
      whereClause =
          whereClause == null ? searchCond : '$whereClause AND $searchCond';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    String orderBy;
    switch (sortBy) {
      case 'created_desc':
        orderBy = 'created_at DESC';
        break;
      case 'name_asc':
        orderBy = 'name ASC';
        break;
      case 'updated_desc':
      default:
        orderBy = 'updated_at DESC';
        break;
    }

    final results = await db.query(
      'projects',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return results.map((m) => Project.fromMap(m)).toList();
  }

  Future<Project?> getProjectById(int id) async {
    final db = await _dbHelper.database;
    final results =
        await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Project.fromMap(results.first);
  }

  Future<int> addProject(Project project) async {
    final db = await _dbHelper.database;
    return await db.insert('projects', project.toMap());
  }

  Future<int> updateProject(Project project) async {
    final db = await _dbHelper.database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getProjectsCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM projects'));
    return count ?? 0;
  }

  Future<List<Project>> getRecentProjects({int limit = 3}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'projects',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return results.map((m) => Project.fromMap(m)).toList();
  }

  Future<Map<String, int>> getStatusCounts() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM projects 
      GROUP BY status
    ''');
    final map = <String, int>{
      'Planned': 0,
      'In Progress': 0,
      'Completed': 0,
      'On Hold': 0,
    };
    for (final row in results) {
      final s = row['status'] as String?;
      if (s != null) {
        map[s] = row['count'] as int;
      }
    }
    return map;
  }
}
