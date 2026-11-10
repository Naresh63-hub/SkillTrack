class GithubProfile {
  final int? id;
  final String username;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final int publicRepos;
  final int publicGists;
  final int followers;
  final int following;
  final String? htmlUrl;
  final String connectedAt;
  final String? lastSyncedAt;

  const GithubProfile({
    this.id,
    required this.username,
    this.name,
    this.avatarUrl,
    this.bio,
    this.publicRepos = 0,
    this.publicGists = 0,
    this.followers = 0,
    this.following = 0,
    this.htmlUrl,
    required this.connectedAt,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'public_repos': publicRepos,
      'public_gists': publicGists,
      'followers': followers,
      'following': following,
      'html_url': htmlUrl,
      'connected_at': connectedAt,
      'last_synced_at': lastSyncedAt,
    };
  }

  factory GithubProfile.fromMap(Map<String, dynamic> map) {
    return GithubProfile(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      name: map['name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      publicRepos: map['public_repos'] as int? ?? 0,
      publicGists: map['public_gists'] as int? ?? 0,
      followers: map['followers'] as int? ?? 0,
      following: map['following'] as int? ?? 0,
      htmlUrl: map['html_url'] as String?,
      connectedAt:
          map['connected_at'] as String? ?? DateTime.now().toIso8601String(),
      lastSyncedAt: map['last_synced_at'] as String?,
    );
  }

  factory GithubProfile.fromApiJson(Map<String, dynamic> json) {
    return GithubProfile(
      username: json['login'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      publicRepos: json['public_repos'] as int? ?? 0,
      publicGists: json['public_gists'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      htmlUrl: json['html_url'] as String?,
      connectedAt: DateTime.now().toIso8601String(),
      lastSyncedAt: DateTime.now().toIso8601String(),
    );
  }
}

class GithubRepositoryModel {
  final int? id;
  final int repoId;
  final String name;
  final String fullName;
  final String? description;
  final String htmlUrl;
  final String? language;
  final int stargazersCount;
  final int forksCount;
  final int openIssuesCount;
  final bool isFork;
  final String? updatedAt;
  final bool isImportedToPortfolio;

  const GithubRepositoryModel({
    this.id,
    required this.repoId,
    required this.name,
    required this.fullName,
    this.description,
    required this.htmlUrl,
    this.language,
    this.stargazersCount = 0,
    this.forksCount = 0,
    this.openIssuesCount = 0,
    this.isFork = false,
    this.updatedAt,
    this.isImportedToPortfolio = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'repo_id': repoId,
      'name': name,
      'full_name': fullName,
      'description': description,
      'html_url': htmlUrl,
      'language': language,
      'stargazers_count': stargazersCount,
      'forks_count': forksCount,
      'open_issues_count': openIssuesCount,
      'is_fork': isFork ? 1 : 0,
      'updated_at': updatedAt,
      'is_imported_to_portfolio': isImportedToPortfolio ? 1 : 0,
    };
  }

  factory GithubRepositoryModel.fromMap(Map<String, dynamic> map) {
    return GithubRepositoryModel(
      id: map['id'] as int?,
      repoId: map['repo_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      description: map['description'] as String?,
      htmlUrl: map['html_url'] as String? ?? '',
      language: map['language'] as String?,
      stargazersCount: map['stargazers_count'] as int? ?? 0,
      forksCount: map['forks_count'] as int? ?? 0,
      openIssuesCount: map['open_issues_count'] as int? ?? 0,
      isFork: (map['is_fork'] as int? ?? 0) == 1,
      updatedAt: map['updated_at'] as String?,
      isImportedToPortfolio:
          (map['is_imported_to_portfolio'] as int? ?? 0) == 1,
    );
  }

  factory GithubRepositoryModel.fromApiJson(Map<String, dynamic> json) {
    return GithubRepositoryModel(
      repoId: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      description: json['description'] as String?,
      htmlUrl: json['html_url'] as String? ?? '',
      language: json['language'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      forksCount: json['forks_count'] as int? ?? 0,
      openIssuesCount: json['open_issues_count'] as int? ?? 0,
      isFork: json['fork'] as bool? ?? false,
      updatedAt: json['updated_at'] as String?,
      isImportedToPortfolio: false,
    );
  }

  GithubRepositoryModel copyWith({
    int? id,
    int? repoId,
    String? name,
    String? fullName,
    String? description,
    String? htmlUrl,
    String? language,
    int? stargazersCount,
    int? forksCount,
    int? openIssuesCount,
    bool? isFork,
    String? updatedAt,
    bool? isImportedToPortfolio,
  }) {
    return GithubRepositoryModel(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      language: language ?? this.language,
      stargazersCount: stargazersCount ?? this.stargazersCount,
      forksCount: forksCount ?? this.forksCount,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      isFork: isFork ?? this.isFork,
      updatedAt: updatedAt ?? this.updatedAt,
      isImportedToPortfolio:
          isImportedToPortfolio ?? this.isImportedToPortfolio,
    );
  }
}

class GithubCommit {
  final int? id;
  final String repoName;
  final String message;
  final String commitDate;
  final String? commitUrl;
  final String? authorName;

  const GithubCommit({
    this.id,
    required this.repoName,
    required this.message,
    required this.commitDate,
    this.commitUrl,
    this.authorName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'repo_name': repoName,
      'message': message,
      'commit_date': commitDate,
      'commit_url': commitUrl,
      'author_name': authorName,
    };
  }

  factory GithubCommit.fromMap(Map<String, dynamic> map) {
    return GithubCommit(
      id: map['id'] as int?,
      repoName: map['repo_name'] as String? ?? '',
      message: map['message'] as String? ?? '',
      commitDate:
          map['commit_date'] as String? ?? DateTime.now().toIso8601String(),
      commitUrl: map['commit_url'] as String?,
      authorName: map['author_name'] as String?,
    );
  }
}
