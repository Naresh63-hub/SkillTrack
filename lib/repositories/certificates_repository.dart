import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/certificate.dart';

class CertificatesRepository {
  final DatabaseHelper _dbHelper;

  CertificatesRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Certificate>> getAllCertificates({
    String? category,
    String? organization,
    String? searchQuery,
    String sortBy = 'completion_date_desc',
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClause = 'category = ?';
      whereArgs.add(category);
    }

    if (organization != null &&
        organization.isNotEmpty &&
        organization != 'All') {
      final orgCond = 'issuing_organization = ?';
      whereClause = whereClause == null ? orgCond : '$whereClause AND $orgCond';
      whereArgs.add(organization);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final searchCond =
          '(name LIKE ? OR issuing_organization LIKE ? OR description LIKE ?)';
      whereClause =
          whereClause == null ? searchCond : '$whereClause AND $searchCond';
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    String orderBy;
    switch (sortBy) {
      case 'completion_date_asc':
        orderBy = 'completion_date ASC';
        break;
      case 'name_asc':
        orderBy = 'name ASC';
        break;
      case 'completion_date_desc':
      default:
        orderBy = 'completion_date DESC';
        break;
    }

    final results = await db.query(
      'certificates',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return results.map((m) => Certificate.fromMap(m)).toList();
  }

  Future<Certificate?> getCertificateById(int id) async {
    final db = await _dbHelper.database;
    final results =
        await db.query('certificates', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Certificate.fromMap(results.first);
  }

  Future<int> addCertificate(Certificate certificate) async {
    final db = await _dbHelper.database;
    return await db.insert('certificates', certificate.toMap());
  }

  Future<int> updateCertificate(Certificate certificate) async {
    final db = await _dbHelper.database;
    return await db.update(
      'certificates',
      certificate.toMap(),
      where: 'id = ?',
      whereArgs: [certificate.id],
    );
  }

  Future<int> deleteCertificate(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('certificates', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCertificatesCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM certificates'));
    return count ?? 0;
  }

  Future<Map<String, int>> getCategoryCounts() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM certificates 
      GROUP BY category
    ''');
    final map = <String, int>{};
    for (final row in results) {
      map[row['category'] as String] = row['count'] as int;
    }
    return map;
  }
}
