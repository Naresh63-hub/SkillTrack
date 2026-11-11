import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/github_models.dart';
import '../../../repositories/github_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/github_service.dart';

class GithubDashboardScreen extends StatefulWidget {
  const GithubDashboardScreen({super.key});

  @override
  State<GithubDashboardScreen> createState() => _GithubDashboardScreenState();
}

class _GithubDashboardScreenState extends State<GithubDashboardScreen> {
  final GithubService _service = GithubService();
  final GithubRepository _repository = GithubRepository();
  final ProfileRepository _profileRepo = ProfileRepository();

  GithubProfile? _profile;
  List<GithubRepositoryModel> _repos = [];
  List<GithubCommit> _commits = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _obscureToken = true;
  String _selectedLanguage = 'All';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    setState(() => _isLoading = true);
    final profile = await _repository.getProfile();
    final repos = await _repository.getRepositories();
    final commits = await _repository.getRecentCommits();

    if (profile == null) {
      // Pre-fill username from student profile if available
      final student = await _profileRepo.getProfile();
      if (student.githubUrl.isNotEmpty) {
        final uri = Uri.tryParse(student.githubUrl);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          _usernameController.text = uri.pathSegments.first;
        }
      }
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _repos = repos;
        _commits = commits;
        _isLoading = false;
      });
    }
  }

  Future<void> _connectAccount() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a GitHub username.')),
      );
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final token = _tokenController.text.trim().isNotEmpty
          ? _tokenController.text.trim()
          : null;
      await _service.syncGithubAccount(
        username: username,
        personalAccessToken: token,
      );
      await _loadLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Connected to GitHub account @$username successfully!'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _syncNow() async {
    if (_profile == null) return;
    setState(() => _isSyncing = true);
    try {
      await _service.syncGithubAccount(username: _profile!.username);
      await _loadLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GitHub data refreshed!'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect GitHub?'),
        content: const Text(
            'This will remove your cached GitHub repositories and commit stream from SkillTrack.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.disconnect();
      await _loadLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub account disconnected.')),
        );
      }
    }
  }

  Future<void> _importRepo(GithubRepositoryModel repo) async {
    try {
      await _service.importRepositoryToPortfolio(repo);
      await _loadLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${repo.name}" to your Project Portfolio!'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('GitHub Activity & Portfolio'),
        actions: [
          if (_profile != null) ...[
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryPurple),
                    )
                  : const Icon(Icons.sync_rounded),
              tooltip: 'Sync Latest Activity',
              onPressed: _isSyncing ? null : _syncNow,
            ),
            IconButton(
              icon: const Icon(Icons.link_off_rounded),
              tooltip: 'Disconnect Account',
              onPressed: _disconnect,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple))
          : _profile == null
              ? _buildConnectView()
              : _buildConnectedDashboard(),
    );
  }

  Widget _buildConnectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondaryCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: const Icon(
              Icons.code_rounded,
              size: 56,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connect Your GitHub',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Showcase real open-source contributions, sync your repositories, and import projects directly into your placement portfolio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GitHub Username',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. octocat or Naresh63-hub',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personal Access Token (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recommended for higher rate limits. Minimum scope: public_repo or no scopes.',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  decoration: InputDecoration(
                    hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.mutedText,
                      ),
                      onPressed: () =>
                          setState(() => _obscureToken = !_obscureToken),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Protected locally using AES-256-GCM authenticated encryption.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _connectAccount,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.link_rounded),
                    label: Text(_isSyncing
                        ? 'Connecting...'
                        : 'Connect GitHub Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDashboard() {
    final p = _profile!;
    final totalStars = _repos.fold<int>(0, (sum, r) => sum + r.stargazersCount);
    final totalForks = _repos.fold<int>(0, (sum, r) => sum + r.forksCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Hero Card
          _buildProfileCard(p),
          const SizedBox(height: 14),

          // 4 Stats Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Repositories',
                  '${p.publicRepos}',
                  Icons.folder_special_rounded,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Total Stars',
                  '$totalStars',
                  Icons.star_rounded,
                  const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Forks',
                  '$totalForks',
                  Icons.fork_right_rounded,
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Followers',
                  '${p.followers}',
                  Icons.people_alt_rounded,
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
          if (GithubService.lastRateLimitInfo != null) ...[
            const SizedBox(height: 12),
            _buildRateLimitBanner(GithubService.lastRateLimitInfo!),
          ],
          const SizedBox(height: 20),

          // Recent Commit Activity Timeline
          if (_commits.isNotEmpty) ...[
            _buildSectionHeader(
                'Recent Commit Activity', '${_commits.length} recent events'),
            const SizedBox(height: 10),
            _buildCommitsCard(),
            const SizedBox(height: 20),
          ],

          // Repositories List
          _buildSectionHeader(
              'Public Repositories', '${_repos.length} repos available'),
          const SizedBox(height: 10),
          _buildLanguageFilters(),
          const SizedBox(height: 10),
          _buildReposList(),
        ],
      ),
    );
  }

  Widget _buildRateLimitBanner(GithubRateLimitInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded,
              size: 16, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GitHub API Quota: ${info.remaining}/${info.limit} requests remaining (Resets in ${info.minutesUntilReset})',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageFilters() {
    final languages = <String>{'All'};
    for (final r in _repos) {
      if (r.language != null && r.language!.isNotEmpty) {
        languages.add(r.language!);
      }
    }
    if (languages.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: languages.map((lang) {
          final isSelected = _selectedLanguage == lang;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(lang),
              selected: isSelected,
              selectedColor: AppColors.primaryPurple,
              backgroundColor: AppColors.cardBackground,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primaryPurple : AppColors.border,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedLanguage = lang);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileCard(GithubProfile p) {
    return CustomCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: ClipOval(
              child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                  ? Image.network(
                      p.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name ?? p.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${p.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                if (p.bio != null && p.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (p.htmlUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
              tooltip: 'Open GitHub Profile',
              onPressed: () => _openUrl(p.htmlUrl!),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCommitsCard() {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _commits.take(4).length,
        separatorBuilder: (_, __) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final c = _commits[index];
          final dateStr = c.commitDate.split('T').first;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.commit_rounded,
                    size: 16, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.message.trim().split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.repoName} • $dateStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              if (c.commitUrl != null)
                IconButton(
                  icon: const Icon(Icons.arrow_outward_rounded,
                      size: 16, color: AppColors.primaryPurple),
                  onPressed: () => _openUrl(c.commitUrl!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReposList() {
    final filteredRepos = _selectedLanguage == 'All'
        ? _repos
        : _repos.where((r) => r.language == _selectedLanguage).toList();

    if (filteredRepos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            _selectedLanguage == 'All'
                ? 'No public repositories found for this account.'
                : 'No $_selectedLanguage repositories found.',
            style: const TextStyle(color: AppColors.mutedText),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRepos.length,
      itemBuilder: (context, index) {
        final r = filteredRepos[index];
        return _buildRepoCard(r);
      },
    );
  }

  Widget _buildRepoCard(GithubRepositoryModel r) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book_outlined,
                  size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (r.isImportedToPortfolio)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text(
                        'In Portfolio',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (r.language != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  r.language!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              const Icon(Icons.star_outline_rounded,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('${r.stargazersCount}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.mutedText)),
              const SizedBox(width: 12),
              const Icon(Icons.fork_right_rounded,
                  size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
              Text('${r.forksCount}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.mutedText)),
              const Spacer(),
              // Import / View Buttons
              if (!r.isImportedToPortfolio)
                OutlinedButton.icon(
                  onPressed: () => _importRepo(r),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.primaryPurple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 13),
                  label: const Text('Add to Portfolio',
                      style: TextStyle(fontSize: 11)),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                tooltip: 'Open Repository',
                onPressed: () => _openUrl(r.htmlUrl),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
