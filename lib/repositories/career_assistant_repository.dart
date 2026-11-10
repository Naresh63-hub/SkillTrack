import '../core/database/database_helper.dart';
import '../models/career_chat_models.dart';

class CareerAssistantRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<CareerChatSession> getOrCreateActiveSession() async {
    final db = await _dbHelper.database;
    final sessions = await db.query(
      'career_chat_sessions',
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (sessions.isNotEmpty) {
      return CareerChatSession.fromMap(sessions.first);
    }

    final now = DateTime.now().toIso8601String();
    final newSession = CareerChatSession(
      title: 'Career Guidance Chat',
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert(
        'career_chat_sessions', newSession.toMap()..remove('id'));
    return CareerChatSession(
      id: id,
      title: newSession.title,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<CareerChatMessage>> getMessages(int sessionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'career_chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => CareerChatMessage.fromMap(m)).toList();
  }

  Future<CareerChatMessage> addMessage(CareerChatMessage message) async {
    final db = await _dbHelper.database;
    final id =
        await db.insert('career_chat_messages', message.toMap()..remove('id'));
    await db.update(
      'career_chat_sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [message.sessionId],
    );
    return CareerChatMessage(
      id: id,
      sessionId: message.sessionId,
      sender: message.sender,
      content: message.content,
      actionType: message.actionType,
      actionPayload: message.actionPayload,
      createdAt: message.createdAt,
    );
  }

  Future<void> clearMessages(int sessionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'career_chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
