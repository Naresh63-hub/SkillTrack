import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/note_model.dart';

class NotesRepository {
  final DatabaseHelper _dbHelper;

  NotesRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<NoteModel>> getAllNotes({
    String? category,
    String? searchQuery,
    bool? pinnedOnly,
    String? linkedSkillName,
  }) async {
    final db = await _dbHelper.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }

    if (pinnedOnly == true) {
      whereConditions.add('is_pinned = 1');
    }

    if (linkedSkillName != null && linkedSkillName.isNotEmpty) {
      whereConditions.add('linked_skill_name = ?');
      whereArgs.add(linkedSkillName);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereConditions.add('(title LIKE ? OR content LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final whereClause =
        whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    final results = await db.query(
      'notes',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );

    return results.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<NoteModel?> getNoteById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return NoteModel.fromMap(results.first);
  }

  Future<int> addNote(NoteModel note) async {
    final db = await _dbHelper.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await _dbHelper.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> togglePin(int id, bool currentPinState) async {
    final db = await _dbHelper.database;
    return await db.update(
      'notes',
      {
        'is_pinned': currentPinState ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getNotesCount() async {
    final db = await _dbHelper.database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM notes'));
    return count ?? 0;
  }
}
