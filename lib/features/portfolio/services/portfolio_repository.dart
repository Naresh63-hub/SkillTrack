import '../../../models/skill.dart';
import '../../../models/project.dart';
import '../../../models/certificate.dart';
import '../../../models/github_models.dart';
import '../../../models/achievement.dart';
import '../../../models/education.dart';
import '../../../repositories/profile_repository.dart';
import '../../../repositories/projects_repository.dart';
import '../../../repositories/certificates_repository.dart';
import '../../../repositories/skills_repository.dart';
import '../../../repositories/github_repository.dart';
import '../models/portfolio_data.dart';

class PortfolioRepository {
  final ProfileRepository _profileRepo;
  final ProjectsRepository _projectsRepo;
  final CertificatesRepository _certificatesRepo;
  final SkillsRepository _skillsRepo;
  final GithubRepository _githubRepo;

  PortfolioRepository({
    ProfileRepository? profileRepo,
    ProjectsRepository? projectsRepo,
    CertificatesRepository? certificatesRepo,
    SkillsRepository? skillsRepo,
    GithubRepository? githubRepo,
  })  : _profileRepo = profileRepo ?? ProfileRepository(),
        _projectsRepo = projectsRepo ?? ProjectsRepository(),
        _certificatesRepo = certificatesRepo ?? CertificatesRepository(),
        _skillsRepo = skillsRepo ?? SkillsRepository(),
        _githubRepo = githubRepo ?? GithubRepository();

  /// Loads portfolio data for the given handle or active user.
  /// If local database has no student profile (e.g. anonymous visitor on Web),
  /// a polished showcase portfolio tailored to the handle is returned.
  Future<PortfolioData> loadPortfolio({String? handle}) async {
    try {
      final profile = await _profileRepo.getProfile();

      // Check if local profile exists and is populated
      final hasLocalData = profile.name.trim().isNotEmpty;

      if (!hasLocalData) {
        return PortfolioData.showcase(handle: handle);
      }

      // If handle is provided and differs from local user, but user is on local DB,
      // local profile will still be used unless database is totally empty.
      final results = await Future.wait([
        _projectsRepo.getAllProjects().catchError((_) => <Project>[]),
        _certificatesRepo.getAllCertificates().catchError((_) => <Certificate>[]),
        _skillsRepo.getAllSkills().catchError((_) => <Skill>[]),
        _githubRepo.getRepositories().catchError((_) => <GithubRepositoryModel>[]),
        _profileRepo.getEducationList().catchError((_) => <Education>[]),
        _profileRepo.getAchievements().catchError((_) => <Achievement>[]),
      ]);

      final projects = results[0] as List<Project>;
      final certificates = results[1] as List<Certificate>;
      final skills = results[2] as List<Skill>;
      final githubRepos = results[3] as List<GithubRepositoryModel>;
      final education = results[4] as List<Education>;
      final achievements = results[5] as List<Achievement>;

      final activeHandle = (handle != null && handle.trim().isNotEmpty)
          ? handle.trim()
          : profile.publicHandle;

      return PortfolioData(
        profile: profile,
        skills: skills.isNotEmpty ? skills : PortfolioData.showcase(handle: activeHandle).skills,
        projects: projects.isNotEmpty ? projects : PortfolioData.showcase(handle: activeHandle).projects,
        certificates: certificates.isNotEmpty
            ? certificates
            : PortfolioData.showcase(handle: activeHandle).certificates,
        githubRepos: githubRepos,
        achievements: achievements,
        education: education,
        handle: activeHandle,
      );
    } catch (_) {
      return PortfolioData.showcase(handle: handle);
    }
  }
}
