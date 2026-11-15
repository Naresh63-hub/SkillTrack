import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../core/utils/streak_calculator.dart';
import '../models/skill.dart';

class SkillsRepository {
  final DatabaseHelper _dbHelper;

  SkillsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Skill>> getAllSkills({
    String? category,
    String? searchQuery,
    String sortBy =
        'level_asc', // 'level_asc', 'level_desc', 'progress_desc', 'progress_asc', 'name_asc', 'target_date'
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchCond = '(name LIKE ? OR notes LIKE ?)';
      whereClause =
          whereClause == null ? searchCond : '$whereClause AND $searchCond';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    String orderBy;
    switch (sortBy) {
      case 'level_asc':
        orderBy = '''
          CASE proficiency_level
            WHEN 'Beginner' THEN 1
            WHEN 'Intermediate' THEN 2
            WHEN 'Advanced' THEN 3
            WHEN 'Expert' THEN 4
            ELSE 5
          END ASC, progress_percentage DESC, name ASC
        ''';
        break;
      case 'level_desc':
        orderBy = '''
          CASE proficiency_level
            WHEN 'Expert' THEN 1
            WHEN 'Advanced' THEN 2
            WHEN 'Intermediate' THEN 3
            WHEN 'Beginner' THEN 4
            ELSE 5
          END ASC, progress_percentage DESC, name ASC
        ''';
        break;
      case 'progress_asc':
        orderBy = 'progress_percentage ASC, name ASC';
        break;
      case 'name_asc':
        orderBy = 'name ASC';
        break;
      case 'target_date':
        orderBy = 'target_completion_date ASC';
        break;
      case 'progress_desc':
        orderBy = 'progress_percentage DESC, name ASC';
        break;
      default:
        orderBy = '''
          CASE proficiency_level
            WHEN 'Beginner' THEN 1
            WHEN 'Intermediate' THEN 2
            WHEN 'Advanced' THEN 3
            WHEN 'Expert' THEN 4
            ELSE 5
          END ASC, progress_percentage DESC, name ASC
        ''';
        break;
    }

    final results = await db.query(
      'skills',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return results.map((m) => Skill.fromMap(m)).toList();
  }

  Future<Skill?> getSkillById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('skills', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Skill.fromMap(results.first);
  }

  Future<int> addSkill(Skill skill) async {
    final db = await _dbHelper.database;
    await StreakCalculator.recordTodayActive();
    return await db.insert('skills', skill.toMap());
  }

  Future<int> updateSkill(Skill skill) async {
    final db = await _dbHelper.database;
    final map = skill.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    await StreakCalculator.recordTodayActive();
    return await db.update(
      'skills',
      map,
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  Future<int> deleteSkill(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('skills', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getSkillsCount() async {
    final db = await _dbHelper.database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM skills'));
    return count ?? 0;
  }
}
