import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/secure_token_storage.dart';
import '../models/github_models.dart';
import '../models/project.dart';
import '../repositories/github_repository.dart';
import '../repositories/projects_repository.dart';

class GithubRateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime resetTime;

  const GithubRateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetTime,
  });

  String get minutesUntilReset {
    final diff = resetTime.difference(DateTime.now()).inMinutes;
    return diff > 0 ? '${diff}m' : 'shortly';
  }
}

class GithubService {
  final GithubRepository _repository = GithubRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();

  static const String _tokenVaultKey = 'github_pat_vault';
  static const String _prefUsernameKey = 'github_saved_username';

  static GithubRateLimitInfo? lastRateLimitInfo;

  Future<String?> getAccessToken() async {
    try {
      return await SecureTokenStorage.getSecureToken(_tokenVaultKey);
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
      'User-Agent': 'SkillTrack-Career-Platform',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _extractRateLimit(http.Response response) {
    try {
      final limitStr = response.headers['x-ratelimit-limit'];
      final remStr = response.headers['x-ratelimit-remaining'];
      final resetStr = response.headers['x-ratelimit-reset'];

      if (limitStr != null && remStr != null && resetStr != null) {
        final limit = int.tryParse(limitStr) ?? 60;
        final rem = int.tryParse(remStr) ?? 60;
        final resetEpoch = int.tryParse(resetStr);
        final resetTime = resetEpoch != null
            ? DateTime.fromMillisecondsSinceEpoch(resetEpoch * 1000)
            : DateTime.now().add(const Duration(hours: 1));

        lastRateLimitInfo = GithubRateLimitInfo(
          limit: limit,
          remaining: rem,
          resetTime: resetTime,
        );
      }
    } catch (_) {}
  }

  /// Connects or syncs a GitHub user profile, repositories, and recent events
  Future<GithubProfile> syncGithubAccount({
    required String username,
    String? personalAccessToken,
  }) async {
    final cleanUsername = username.trim();
    final prefs = await SharedPreferences.getInstance();

    if (personalAccessToken != null && personalAccessToken.isNotEmpty) {
      // Securely store encrypted token
      await SecureTokenStorage.saveSecureToken(
          _tokenVaultKey, personalAccessToken.trim());
    }
    await prefs.setString(_prefUsernameKey, cleanUsername);

    final token = personalAccessToken ?? await getAccessToken();
    final headers = _buildHeaders(token);

    // 1. Fetch User Profile
    final userUrl = Uri.parse('https://api.github.com/users/$cleanUsername');
    final userRes = await http.get(userUrl, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    _extractRateLimit(userRes);

    if (userRes.statusCode == 401) {
      throw Exception(
          'GitHub Token invalid or expired. Please check your Personal Access Token.');
    }
    if (userRes.statusCode == 404) {
      throw Exception('GitHub user "$cleanUsername" was not found.');
    }
    if (userRes.statusCode == 403 && userRes.body.contains('rate limit')) {
      final resetMins = lastRateLimitInfo?.minutesUntilReset ?? '60m';
      throw Exception(
          'GitHub API rate limit reached. Limit resets in $resetMins. Add a Personal Access Token in connection settings for 5,000 requests/hr.');
    }
    if (userRes.statusCode != 200) {
      throw Exception(
          'Failed to connect to GitHub (HTTP ${userRes.statusCode}).');
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

      _extractRateLimit(reposRes);

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

    // 3. Fetch Recent Commit Activity from Public Events
    try {
      final eventsUrl = Uri.parse(
          'https://api.github.com/users/$cleanUsername/events/public?per_page=30');
      final eventsRes = await http.get(eventsUrl, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      _extractRateLimit(eventsRes);

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

  /// Disconnects the GitHub account, wiping cached data and local auth tokens securely
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureTokenStorage.removeSecureToken(_tokenVaultKey);
    await prefs.remove(_prefUsernameKey);
    await _repository.disconnect();
    lastRateLimitInfo = null;
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
