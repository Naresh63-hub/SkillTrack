import '../core/database/database_helper.dart';
import '../models/mock_interview.dart';

class MockInterviewRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<MockInterview> createInterview({
    required MockInterview interview,
    required List<String> questions,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final interviewId = await txn.insert(
        'mock_interviews',
        interview.toMap()..remove('id'),
      );

      final answers = <MockInterviewAnswer>[];
      for (int i = 0; i < questions.length; i++) {
        final answer = MockInterviewAnswer(
          interviewId: interviewId,
          questionIndex: i,
          question: questions[i],
        );
        final answerId = await txn.insert(
          'mock_interview_answers',
          answer.toMap()..remove('id'),
        );
        answers.add(answer.copyWith(id: answerId));
      }

      return interview.copyWith(
        id: interviewId,
        answers: answers,
      );
    });
  }

  Future<MockInterview?> getInterviewById(int id) async {
    final db = await _dbHelper.database;
    final interviewMaps = await db.query(
      'mock_interviews',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (interviewMaps.isEmpty) return null;

    final answerMaps = await db.query(
      'mock_interview_answers',
      where: 'interview_id = ?',
      whereArgs: [id],
      orderBy: 'question_index ASC',
    );

    final answers =
        answerMaps.map((m) => MockInterviewAnswer.fromMap(m)).toList();
    return MockInterview.fromMap(interviewMaps.first, answers: answers);
  }

  Future<List<MockInterview>> getAllInterviews() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'mock_interviews',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => MockInterview.fromMap(m)).toList();
  }

  Future<void> saveAnswer({
    required int answerId,
    required int interviewId,
    required String userAnswer,
    required double score,
    required String feedback,
    required String improvementTips,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'mock_interview_answers',
        {
          'user_answer': userAnswer,
          'score': score,
          'feedback': feedback,
          'improvement_tips': improvementTips,
        },
        where: 'id = ?',
        whereArgs: [answerId],
      );

      // Update completed count
      final answered = await txn.query(
        'mock_interview_answers',
        where: 'interview_id = ? AND user_answer IS NOT NULL',
        whereArgs: [interviewId],
      );

      await txn.update(
        'mock_interviews',
        {'completed_questions': answered.length},
        where: 'id = ?',
        whereArgs: [interviewId],
      );
    });
  }

  Future<void> completeInterview({
    required int interviewId,
    required double overallScore,
    required String feedbackSummary,
    required List<String> strengths,
    required List<String> weaknesses,
    required List<String> recommendedTopics,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'mock_interviews',
      {
        'overall_score': overallScore,
        'status': 'Completed',
        'feedback_summary': feedbackSummary,
        'strengths': strengths.join('|||'),
        'weaknesses': weaknesses.join('|||'),
        'recommended_topics': recommendedTopics.join('|||'),
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [interviewId],
    );
  }

  Future<void> deleteInterview(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'mock_interviews',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
