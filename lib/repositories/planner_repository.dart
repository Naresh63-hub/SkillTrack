import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/planner_event.dart';

class PlannerRepository {
  final DatabaseHelper _dbHelper;

  PlannerRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<PlannerEvent>> getAllEvents({
    String? eventType,
    String? targetDate,
    bool? completedOnly,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (eventType != null && eventType.isNotEmpty && eventType != 'All') {
      whereConditions.add('event_type = ?');
      whereArgs.add(eventType);
    }

    if (targetDate != null && targetDate.isNotEmpty) {
      whereConditions.add('target_date = ?');
      whereArgs.add(targetDate);
    }

    if (completedOnly != null) {
      whereConditions.add('is_completed = ?');
      whereArgs.add(completedOnly ? 1 : 0);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereConditions.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final whereClause =
        whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    final results = await db.query(
      'planner_events',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'target_date ASC, start_time ASC',
    );

    return results.map((m) => PlannerEvent.fromMap(m)).toList();
  }

  Future<List<PlannerEvent>> getUpcomingEvents({int limit = 5}) async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final results = await db.query(
      'planner_events',
      where: 'target_date >= ? AND is_completed = 0',
      whereArgs: [todayStr],
      orderBy: 'target_date ASC, start_time ASC',
      limit: limit,
    );

    return results.map((m) => PlannerEvent.fromMap(m)).toList();
  }

  Future<List<PlannerEvent>> getEventsForDate(String dateStr) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'planner_events',
      where: 'target_date = ?',
      whereArgs: [dateStr],
      orderBy: 'start_time ASC',
    );
    return results.map((m) => PlannerEvent.fromMap(m)).toList();
  }

  Future<PlannerEvent?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final results =
        await db.query('planner_events', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return PlannerEvent.fromMap(results.first);
  }

  Future<int> addEvent(PlannerEvent event) async {
    final db = await _dbHelper.database;
    return await db.insert('planner_events', event.toMap());
  }

  Future<int> updateEvent(PlannerEvent event) async {
    final db = await _dbHelper.database;
    return await db.update(
      'planner_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('planner_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleEventCompleted(int id, bool currentStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      'planner_events',
      {
        'is_completed': currentStatus ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleComplete(int id, bool currentStatus) =>
      toggleEventCompleted(id, currentStatus);

  Future<Map<String, int>> getEventCounts() async {
    final db = await _dbHelper.database;
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final totalCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM planner_events')) ??
        0;

    final completedCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM planner_events WHERE is_completed = 1')) ??
        0;

    final upcomingCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM planner_events WHERE target_date >= ? AND is_completed = 0',
            [todayStr])) ??
        0;

    return {
      'total': totalCount,
      'completed': completedCount,
      'upcoming': upcomingCount,
    };
  }
}
