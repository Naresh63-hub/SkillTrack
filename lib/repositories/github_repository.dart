import '../core/database/database_helper.dart';
import '../models/github_models.dart';

class GithubRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<GithubProfile?> getProfile() async {
    final db = await _dbHelper.database;
    final maps = await db.query('github_profile', limit: 1);
    if (maps.isEmpty) return null;
    return GithubProfile.fromMap(maps.first);
  }

  Future<void> saveProfile(GithubProfile profile) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('github_profile');
      await txn.insert('github_profile', profile.toMap()..remove('id'));
    });
  }

  Future<List<GithubRepositoryModel>> getRepositories() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'github_repositories',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => GithubRepositoryModel.fromMap(m)).toList();
  }

  Future<void> saveRepositories(List<GithubRepositoryModel> repos) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Preserve is_imported_to_portfolio flag
      final existing = await txn.query('github_repositories');
      final importedIds = <int>{};
      for (final e in existing) {
        if ((e['is_imported_to_portfolio'] as int? ?? 0) == 1) {
          importedIds.add(e['repo_id'] as int);
        }
      }

      await txn.delete('github_repositories');
      for (final r in repos) {
        final isImported = importedIds.contains(r.repoId);
        final map = r.copyWith(isImportedToPortfolio: isImported).toMap()
          ..remove('id');
        await txn.insert('github_repositories', map);
      }
    });
  }

  Future<List<GithubCommit>> getRecentCommits() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'github_commits_cache',
      orderBy: 'commit_date DESC',
      limit: 15,
    );
    return maps.map((m) => GithubCommit.fromMap(m)).toList();
  }

  Future<void> saveCommits(List<GithubCommit> commits) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('github_commits_cache');
      for (final c in commits) {
        await txn.insert('github_commits_cache', c.toMap()..remove('id'));
      }
    });
  }

  Future<void> markRepoImported(int repoId, bool isImported) async {
    final db = await _dbHelper.database;
    await db.update(
      'github_repositories',
      {'is_imported_to_portfolio': isImported ? 1 : 0},
      where: 'repo_id = ?',
      whereArgs: [repoId],
    );
  }

  Future<void> disconnect() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('github_commits_cache');
      await txn.delete('github_repositories');
      await txn.delete('github_profile');
    });
  }
}
