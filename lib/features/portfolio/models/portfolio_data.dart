import '../../../models/student_profile.dart';
import '../../../models/skill.dart';
import '../../../models/project.dart';
import '../../../models/certificate.dart';
import '../../../models/github_models.dart';
import '../../../models/achievement.dart';
import '../../../models/education.dart';

class PortfolioData {
  final StudentProfile profile;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Certificate> certificates;
  final List<GithubRepositoryModel> githubRepos;
  final List<Achievement> achievements;
  final List<Education> education;
  final String handle;

  const PortfolioData({
    required this.profile,
    required this.skills,
    required this.projects,
    required this.certificates,
    required this.githubRepos,
    required this.achievements,
    required this.education,
    required this.handle,
  });

  /// Factory creating an impressive showcase student portfolio for external visitors
  /// when opening a public URL without pre-existing local database state.
  factory PortfolioData.showcase({String? handle}) {
    final cleanHandle = (handle ?? 'priya-sharma')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '')
        .trim();
    final studentName = _formatNameFromHandle(cleanHandle);

    final showcaseProfile = StudentProfile(
      name: studentName,
      email: '$cleanHandle@example.com',
      targetJobRole: 'Full Stack & Mobile Engineer',
      college: 'Indian Institute of Information Technology (IIIT)',
      degree: 'B.Tech in Computer Science & Engineering',
      branch: 'Computer Science',
      currentSemester: 'Semester 8',
      graduationYear: '2025',
      city: 'Bengaluru, India',
      bio:
          'Passionate software engineer building high-performance cross-platform mobile and web applications. Experienced in Flutter, React, Python, and scalable cloud architectures.',
      githubUrl: 'https://github.com/$cleanHandle',
      linkedinUrl: 'https://linkedin.com/in/$cleanHandle',
      portfolioUrl: 'https://skill-track-ashy.vercel.app/#/p/$cleanHandle',
    );

    final showcaseProjects = [
      Project(
        name: 'DevConnect - Developer Community & Job Hub',
        shortDescription:
            'Full-stack social platform for developers with real-time messaging, code reviews, and job discovery.',
        detailedDescription:
            'Architected a collaborative ecosystem for engineers with instant code snippet sharing, real-time discussions using WebSockets, and curated placement openings.',
        category: 'Full Stack',
        technologies: ['Flutter', 'Node.js', 'PostgreSQL', 'WebSockets', 'Docker'],
        status: 'Completed',
        githubUrl: 'https://github.com/$cleanHandle/devconnect-platform',
        liveDemoUrl: 'https://devconnect-showcase.vercel.app',
        vercelUrl: 'https://devconnect-showcase.vercel.app',
      ),
      Project(
        name: 'AI Career Copilot & Interview Simulator',
        shortDescription:
            'Interactive AI voice coach evaluating STAR-method responses and technical readiness in real-time.',
        detailedDescription:
            'Engineered an offline-capable interview prep engine with speech-to-text integration, instant rubric scoring, and personalized skill gap roadmaps.',
        category: 'AI / Machine Learning',
        technologies: ['Flutter', 'Python', 'FastAPI', 'Gemini AI', 'SQLite'],
        status: 'Completed',
        githubUrl: 'https://github.com/$cleanHandle/ai-career-copilot',
        renderUrl: 'https://career-copilot-api.onrender.com',
        liveDemoUrl: 'https://skill-track-ashy.vercel.app',
      ),
      Project(
        name: 'FinFlow - Smart Expense & Investment Tracker',
        shortDescription:
            'Financial analytics suite featuring automated categorization, PDF budget reports, and multi-currency support.',
        detailedDescription:
            'Designed modern finance dashboard with interactive chart visualizations, offline-first syncing, and biometric authentication.',
        category: 'Mobile App',
        technologies: ['Flutter', 'Riverpod', 'FL Chart', 'Hive', 'Supabase'],
        status: 'Completed',
        githubUrl: 'https://github.com/$cleanHandle/finflow-analytics',
        vercelUrl: 'https://finflow-demo.vercel.app',
        liveDemoUrl: 'https://finflow-demo.vercel.app',
      ),
    ];

    final showcaseCertificates = [
      Certificate(
        name: 'AWS Certified Cloud Practitioner (CLF-C02)',
        issuingOrganization: 'Amazon Web Services (AWS)',
        category: 'Cloud Computing',
        completionDate: '2024-06-15',
        credentialId: 'AWS-CCP-9284102',
        verificationUrl: 'https://aws.amazon.com/verification',
        description:
            'Demonstrated comprehensive understanding of cloud security, architecture, core services, and pricing models.',
      ),
      Certificate(
        name: 'Meta Front-End Developer Professional Certificate',
        issuingOrganization: 'Meta',
        category: 'Web Development',
        completionDate: '2024-03-20',
        credentialId: 'META-FE-774912',
        verificationUrl: 'https://coursera.org/verify/professional-cert/META-FE-774912',
        description:
            'Mastered React, responsive UI development, version control with Git, and UX/UI design principles.',
      ),
      Certificate(
        name: 'Flutter & Dart Certified Application Developer',
        issuingOrganization: 'Google Developers / App Brewery',
        category: 'Mobile Development',
        completionDate: '2024-01-10',
        credentialId: 'FLUTTER-CERT-3381',
        verificationUrl: 'https://developers.google.com/certification',
        description:
            'Advanced cross-platform architecture, state management patterns, and production Flutter deployment.',
      ),
    ];

    final showcaseSkills = [
      Skill(
        name: 'Flutter & Dart',
        category: 'Mobile',
        proficiencyLevel: 'Expert',
        progressPercentage: 95.0,
      ),
      Skill(
        name: 'React & TypeScript',
        category: 'Frontend',
        proficiencyLevel: 'Advanced',
        progressPercentage: 88.0,
      ),
      Skill(
        name: 'Python & FastAPI',
        category: 'Backend',
        proficiencyLevel: 'Advanced',
        progressPercentage: 82.0,
      ),
      Skill(
        name: 'PostgreSQL & SQL',
        category: 'Database',
        proficiencyLevel: 'Advanced',
        progressPercentage: 85.0,
      ),
      Skill(
        name: 'Docker & CI/CD',
        category: 'DevOps',
        proficiencyLevel: 'Intermediate',
        progressPercentage: 75.0,
      ),
      Skill(
        name: 'Git & Open Source Collaboration',
        category: 'Tools',
        proficiencyLevel: 'Expert',
        progressPercentage: 92.0,
      ),
    ];

    final showcaseRepos = [
      GithubRepositoryModel(
        repoId: 101,
        name: 'devconnect-platform',
        fullName: '$cleanHandle/devconnect-platform',
        description: 'Collaborative platform for developers with real-time chat and code review tools.',
        htmlUrl: 'https://github.com/$cleanHandle/devconnect-platform',
        language: 'Dart',
        stargazersCount: 42,
        forksCount: 12,
        isImportedToPortfolio: true,
      ),
      GithubRepositoryModel(
        repoId: 102,
        name: 'ai-career-copilot',
        fullName: '$cleanHandle/ai-career-copilot',
        description: 'Intelligent interview prep engine with speech analysis and STAR feedback.',
        htmlUrl: 'https://github.com/$cleanHandle/ai-career-copilot',
        language: 'Python',
        stargazersCount: 68,
        forksCount: 19,
        isImportedToPortfolio: true,
      ),
      GithubRepositoryModel(
        repoId: 103,
        name: 'flutter-ui-components',
        fullName: '$cleanHandle/flutter-ui-components',
        description: 'Collection of 40+ polished, reusable Material 3 widgets and animations.',
        htmlUrl: 'https://github.com/$cleanHandle/flutter-ui-components',
        language: 'Dart',
        stargazersCount: 115,
        forksCount: 34,
        isImportedToPortfolio: true,
      ),
    ];

    final showcaseAchievements = [
      Achievement(
        title: 'National Winner - Smart India Hackathon 2024',
        dateAchieved: '2024-04-12',
        description: 'Ministry of Education & AICTE - Built an AI-assisted smart healthcare triage engine selected as #1 out of 500+ national teams.',
      ),
      Achievement(
        title: "Dean's Academic Excellence Honor Roll",
        dateAchieved: '2023-11-20',
        description: 'IIIT Bengaluru - Awarded for top 5% academic performance across Computer Science department.',
      ),
    ];

    final showcaseEducation = [
      Education(
        institution: 'Indian Institute of Information Technology (IIIT)',
        degree: 'Bachelor of Technology (B.Tech)',
        fieldOfStudy: 'Computer Science and Engineering',
        startYear: '2021',
        endYear: '2025',
        gradeOrCgpa: '9.1 CGPA (First Class with Distinction)',
      ),
    ];

    return PortfolioData(
      profile: showcaseProfile,
      skills: showcaseSkills,
      projects: showcaseProjects,
      certificates: showcaseCertificates,
      githubRepos: showcaseRepos,
      achievements: showcaseAchievements,
      education: showcaseEducation,
      handle: cleanHandle,
    );
  }

  static String _formatNameFromHandle(String handle) {
    if (handle.isEmpty || handle.toLowerCase() == 'student') {
      return 'Priya Sharma';
    }
    final words = handle
        .split(RegExp(r'[\-_.]'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
        .toList();
    return words.isNotEmpty ? words.join(' ') : 'Priya Sharma';
  }
}
