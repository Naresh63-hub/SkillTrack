import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_models.dart';
import '../models/project.dart';
import '../repositories/github_repository.dart';
import '../repositories/projects_repository.dart';

class GithubService {
  final GithubRepository _repository = GithubRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();

  static const String _prefTokenKey = 'github_access_token';
  static const String _prefUsernameKey = 'github_saved_username';

  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getConnectedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefUsernameKey);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'SkillTrack-Career-App',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Connects or syncs a GitHub user profile, repositories, and recent events
  Future<GithubProfile> syncGithubAccount({
    required String username,
    String? personalAccessToken,
  }) async {
    final cleanUsername = username.trim();
    final prefs = await SharedPreferences.getInstance();

    if (personalAccessToken != null && personalAccessToken.isNotEmpty) {
      await prefs.setString(_prefTokenKey, personalAccessToken.trim());
    }
    await prefs.setString(_prefUsernameKey, cleanUsername);

    final token = personalAccessToken ?? await getAccessToken();
    final headers = _buildHeaders(token);

    // 1. Fetch User Profile
    final userUrl = Uri.parse('https://api.github.com/users/$cleanUsername');
    final userRes = await http.get(userUrl, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (userRes.statusCode == 404) {
      throw Exception('GitHub user "$cleanUsername" was not found.');
    }
    if (userRes.statusCode == 403 && userRes.body.contains('rate limit')) {
      throw Exception(
          'GitHub API rate limit exceeded. Provide a personal access token in settings to increase limits.');
    }
    if (userRes.statusCode != 200) {
      throw Exception(
          'Failed to fetch GitHub profile (HTTP ${userRes.statusCode})');
    }

    final userJson = jsonDecode(userRes.body) as Map<String, dynamic>;
    final profile = GithubProfile.fromApiJson(userJson);
    await _repository.saveProfile(profile);

    // 2. Fetch Repositories
    try {
      final reposUrl = Uri.parse(
          'https://api.github.com/users/$cleanUsername/repos?sort=updated&per_page=30');
      final reposRes = await http.get(reposUrl, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      if (reposRes.statusCode == 200) {
        final reposList = jsonDecode(reposRes.body) as List;
        final repos = reposList
            .map((r) =>
                GithubRepositoryModel.fromApiJson(r as Map<String, dynamic>))
            .toList();
        await _repository.saveRepositories(repos);
      }
    } catch (e) {
      debugPrint('Error syncing GitHub repos: $e');
    }

    // 3. Fetch Recent Commit Activity from Events
    try {
      final eventsUrl = Uri.parse(
          'https://api.github.com/users/$cleanUsername/events/public?per_page=30');
      final eventsRes = await http.get(eventsUrl, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      if (eventsRes.statusCode == 200) {
        final eventsList = jsonDecode(eventsRes.body) as List;
        final commits = <GithubCommit>[];

        for (final ev in eventsList) {
          final type = ev['type'] as String?;
          if (type == 'PushEvent') {
            final repoName =
                (ev['repo']?['name'] as String?)?.split('/').last ?? 'repo';
            final payload = ev['payload'] as Map<String, dynamic>?;
            final payloadCommits = payload?['commits'] as List?;
            final createdAt =
                ev['created_at'] as String? ?? DateTime.now().toIso8601String();

            if (payloadCommits != null) {
              for (final c in payloadCommits) {
                commits.add(GithubCommit(
                  repoName: repoName,
                  message: c['message'] as String? ?? 'Code commit',
                  commitDate: createdAt,
                  commitUrl:
                      'https://github.com/${ev['repo']?['name']}/commit/${c['sha']}',
                  authorName: c['author']?['name'] as String? ?? cleanUsername,
                ));
              }
            }
          }
        }
        if (commits.isNotEmpty) {
          await _repository.saveCommits(commits);
        }
      }
    } catch (e) {
      debugPrint('Error syncing GitHub events: $e');
    }

    return profile;
  }

  /// Disconnects the GitHub account, wiping cached data and local auth tokens
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefUsernameKey);
    await _repository.disconnect();
  }

  /// 1-Tap import from a GitHub repository into SkillTrack portfolio projects
  Future<Project> importRepositoryToPortfolio(
      GithubRepositoryModel repo) async {
    final now = DateTime.now().toIso8601String();
    final dateStr = repo.updatedAt != null
        ? repo.updatedAt!.split('T').first
        : now.split('T').first;

    final project = Project(
      name: repo.name,
      shortDescription:
          repo.description ?? 'Imported from GitHub: ${repo.fullName}',
      detailedDescription:
          'Repository: ${repo.fullName}\nLanguage: ${repo.language ?? "General"}\nStars: ${repo.stargazersCount} | Forks: ${repo.forksCount}\nGitHub URL: ${repo.htmlUrl}',
      category: repo.language ?? 'Other',
      technologies: [
        if (repo.language != null && repo.language!.isNotEmpty)
          repo.language!
        else
          'Source Code'
      ],
      status: 'Completed',
      startDate: dateStr,
      completionDate: dateStr,
      githubUrl: repo.htmlUrl,
      notes: 'Imported via SkillTrack GitHub Integration module.',
    );

    final createdId = await _projectsRepo.addProject(project);
    await _repository.markRepoImported(repo.repoId, true);
    return project.copyWith(id: createdId);
  }
}
