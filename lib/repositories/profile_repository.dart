import '../core/database/database_helper.dart';
import '../models/student_profile.dart';
import '../models/education.dart';
import '../models/achievement.dart';

class ProfileRepository {
  final DatabaseHelper _dbHelper;

  ProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<StudentProfile> getProfile() async {
    final db = await _dbHelper.database;
    final results = await db.query('student_profile', limit: 1);
    if (results.isNotEmpty) {
      return StudentProfile.fromMap(results.first);
    }
    // Default initial profile matching mockup
    return StudentProfile(
      name: 'Priya Sharma',
      email: 'priya.sharma@college.edu',
      targetJobRole: 'Software Developer',
      college: 'B.Tech - Tech Institute',
      branch: 'Computer Science',
      currentSemester: '6th Semester',
      graduationYear: '2026',
      githubUrl: 'https://github.com/priya',
      linkedinUrl: 'https://linkedin.com/in/priya',
    );
  }

  Future<int> saveProfile(StudentProfile profile) async {
    final db = await _dbHelper.database;
    final results = await db.query('student_profile', limit: 1);
    if (results.isEmpty) {
      return await db.insert('student_profile', profile.toMap());
    } else {
      final existingId = results.first['id'] as int;
      return await db.update(
        'student_profile',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [existingId],
      );
    }
  }

  // Education CRUD
  Future<List<Education>> getEducationList() async {
    final db = await _dbHelper.database;
    final results = await db.query('education', orderBy: 'start_year DESC');
    return results.map((e) => Education.fromMap(e)).toList();
  }

  Future<int> addEducation(Education education) async {
    final db = await _dbHelper.database;
    return await db.insert('education', education.toMap());
  }

  Future<int> deleteEducation(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('education', where: 'id = ?', whereArgs: [id]);
  }

  // Achievements CRUD
  Future<List<Achievement>> getAchievements() async {
    final db = await _dbHelper.database;
    final results = await db.query('achievements', orderBy: 'created_at DESC');
    return results.map((e) => Achievement.fromMap(e)).toList();
  }

  Future<int> addAchievement(Achievement achievement) async {
    final db = await _dbHelper.database;
    return await db.insert('achievements', achievement.toMap());
  }

  Future<int> deleteAchievement(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('achievements', where: 'id = ?', whereArgs: [id]);
  }
}
