import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_roadmap.dart';
import '../models/task_model.dart';
import '../repositories/ai_roadmap_repository.dart';
import '../repositories/skills_repository.dart';
import '../repositories/tasks_repository.dart';
import 'ai_service.dart';

class AiRoadmapService {
  final AiRoadmapRepository _repository = AiRoadmapRepository();
  final SkillsRepository _skillsRepo = SkillsRepository();
  final TasksRepository _tasksRepo = TasksRepository();

  static const List<String> supportedRoles = [
    'Python Developer',
    'Java Developer',
    'Full Stack Developer',
    'AI/ML Engineer',
    'Data Analyst',
    'Flutter Developer',
    'Software Engineer',
  ];

  static const Map<String, List<String>> _roleCompetencies = {
    'Python Developer': [
      'Python Core & OOP',
      'Data Structures in Python',
      'Django & FastAPI',
      'PostgreSQL & ORM',
      'REST APIs & Microservices',
      'Docker & Containerization',
      'Unit Testing & PyTest',
      'Asynchronous Python & Celery',
      'CI/CD Pipelines',
      'System Design Basics',
    ],
    'Java Developer': [
      'Core Java & Collections',
      'Object-Oriented Design & SOLID',
      'Spring Boot & MVC',
      'Hibernate / JPA',
      'MySQL / PostgreSQL',
      'Microservices Architecture',
      'JUnit 5 & Mockito',
      'Kafka / Message Queues',
      'Docker & Kubernetes',
      'Design Patterns & Clean Code',
    ],
    'Full Stack Developer': [
      'HTML5, Modern CSS & Flexbox',
      'JavaScript ES6+ & TypeScript',
      'React.js or Vue.js Framework',
      'Node.js & Express.js',
      'RESTful API Design & GraphQL',
      'MongoDB & PostgreSQL',
      'Authentication (JWT & OAuth)',
      'State Management & Redux',
      'Cloud Deployment & Docker',
      'End-to-End Testing & CI/CD',
    ],
    'AI/ML Engineer': [
      'Linear Algebra & Statistics',
      'Python for Data Science (NumPy, Pandas)',
      'Data Cleaning & Feature Engineering',
      'Supervised & Unsupervised ML',
      'Deep Learning & PyTorch/TensorFlow',
      'Computer Vision & NLP Fundamentals',
      'Model Evaluation & Tuning',
      'MLOps & MLflow',
      'API Serving with FastAPI & Docker',
      'LLMs & Prompt Engineering',
    ],
    'Data Analyst': [
      'Excel & Advanced Spreadsheets',
      'SQL & Complex Query Optimization',
      'Python for Analytics (Pandas, NumPy)',
      'Data Visualization (Matplotlib, Seaborn)',
      'Power BI & Interactive Dashboards',
      'Tableau Fundamentals',
      'Statistical Testing & Hypothesis',
      'Exploratory Data Analysis (EDA)',
      'Business Intelligence Reporting',
      'Data Storytelling & Insights',
    ],
    'Flutter Developer': [
      'Dart Programming Language',
      'Flutter Widgets & Reactive UI',
      'State Management (Provider/Bloc)',
      'Local Storage (SQLite, SharedPreferences)',
      'REST API Integration & JSON',
      'Animations & Custom Painting',
      'Firebase & Push Notifications',
      'Native Device Features & Plugins',
      'Testing (Unit, Widget, Integration)',
      'App Store & Play Store Deployment',
    ],
    'Software Engineer': [
      'Data Structures & Algorithms',
      'Object-Oriented Programming & Design Patterns',
      'Database Management & SQL',
      'Operating Systems & Networking Basics',
      'Git & Collaborative Workflows',
      'API Design & Cloud Fundamentals',
      'System Architecture & Scalability',
      'Code Review & Clean Code Principles',
      'Security Best Practices',
      'DevOps & Automated Testing',
    ],
  };

  /// Computes skill gaps by comparing student's tracked skills with standard industry expectations
  Future<List<String>> analyzeSkillGaps(String targetRole) async {
    final existingSkills = await _skillsRepo.getAllSkills();
    final userSkillNames =
        existingSkills.map((s) => s.name.toLowerCase().trim()).toSet();

    final required = _roleCompetencies[targetRole] ??
        _roleCompetencies['Software Engineer']!;

    final gaps = <String>[];
    for (final req in required) {
      final reqLower = req.toLowerCase();
      final hasMatch = userSkillNames.any((userSkill) =>
          userSkill.contains(reqLower) ||
          reqLower.contains(userSkill) ||
          _matchesDomainKeyword(reqLower, userSkill));
      if (!hasMatch) {
        gaps.add(req);
      }
    }
    return gaps;
  }

  bool _matchesDomainKeyword(String req, String userSkill) {
    if (req.contains('python') && userSkill.contains('python')) return true;
    if (req.contains('java') && userSkill.contains('java')) return true;
    if (req.contains('dart') && userSkill.contains('flutter')) return true;
    if (req.contains('sql') &&
        (userSkill.contains('database') || userSkill.contains('mysql')))
      return true;
    if (req.contains('react') && userSkill.contains('frontend')) return true;
    return false;
  }

  /// Generates or refreshes a personalized learning roadmap for the student
  Future<AiRoadmap> generateRoadmap({
    required String targetRole,
    String skillLevel = 'Beginner',
  }) async {
    final existingSkills = await _skillsRepo.getAllSkills();
    final skillGaps = await analyzeSkillGaps(targetRole);

    // Attempt Gemini AI Generation
    AiRoadmap? aiRoadmap;
    try {
      final prompt = '''
You are an expert tech career advisor. Create a personalized 3-tier learning roadmap for a student aiming to become a "$targetRole".
The student currently knows: ${existingSkills.map((s) => '${s.name} (${s.proficiencyLevel}, ${s.progressPercentage.toInt()}%)').join(', ')}.
Identified skill gaps to address: ${skillGaps.join(', ')}.

Respond ONLY in valid JSON with this exact structure:
{
  "summary": "1-2 sentence motivating summary of this personalized roadmap.",
  "nodes": [
    {
      "level": "Beginner", // or "Intermediate" or "Advanced"
      "topic_title": "Title of topic",
      "description": "Clear explanation of what to learn and build",
      "category": "Core Concept / Framework / Tool",
      "estimated_days": 3,
      "resource_title": "Official documentation or standard guide name",
      "resource_url": "https://..."
    }
  ]
}
Include exactly 9-12 balanced nodes (3-4 for Beginner, 3-4 for Intermediate, 3-4 for Advanced).
''';

      final responseText = await AiService.instance.generateContent(
        prompt: prompt,
        systemInstruction:
            'You are an elite developer mentor. Output valid JSON only without markdown formatting.',
        forceJson: true,
      );

      if (responseText != null && responseText.isNotEmpty) {
        final cleanedJson = AiService.extractJsonString(responseText);
        final data = jsonDecode(cleanedJson);
        final summary = data['summary'] as String? ??
            'Personalized $targetRole Learning Roadmap';
        final rawNodes = data['nodes'] as List? ?? [];

        final nodes = <AiRoadmapNode>[];
        for (int i = 0; i < rawNodes.length; i++) {
          final item = rawNodes[i] as Map<String, dynamic>;
          nodes.add(AiRoadmapNode(
            roadmapId: 0,
            level: item['level'] as String? ?? 'Beginner',
            topicTitle: item['topic_title'] as String? ?? 'Topic ${i + 1}',
            description: item['description'] as String? ?? '',
            category: item['category'] as String? ?? 'Technical',
            estimatedDays: item['estimated_days'] as int? ?? 3,
            resourceTitle: item['resource_title'] as String? ?? 'Documentation',
            resourceUrl: item['resource_url'] as String? ??
                'https://developer.mozilla.org',
            orderIndex: i,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }

        if (nodes.isNotEmpty) {
          final newRoadmap = AiRoadmap(
            targetRole: targetRole,
            skillLevel: skillLevel,
            overallProgress: 0.0,
            summary: summary,
            skillGaps: skillGaps,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
            nodes: nodes,
          );
          aiRoadmap =
              await _repository.saveRoadmap(roadmap: newRoadmap, nodes: nodes);
        }
      }
    } catch (e) {
      debugPrint('AI Roadmap Generation error: $e');
    }

    if (aiRoadmap != null) return aiRoadmap;

    // Fallback: Use High-Quality Curated Offline Engine
    return await _generateFallbackRoadmap(targetRole, skillLevel, skillGaps);
  }

  Future<AiRoadmap> _generateFallbackRoadmap(
    String targetRole,
    String skillLevel,
    List<String> skillGaps,
  ) async {
    final nodes = _getFallbackNodesForRole(targetRole);
    final summary =
        'Tailored 3-tier career roadmap designed for $targetRole aspirants, focusing on closing ${skillGaps.length} identified competency gaps.';

    final roadmap = AiRoadmap(
      targetRole: targetRole,
      skillLevel: skillLevel,
      overallProgress: 0.0,
      summary: summary,
      skillGaps: skillGaps,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      nodes: nodes,
    );

    return await _repository.saveRoadmap(roadmap: roadmap, nodes: nodes);
  }

  List<AiRoadmapNode> _getFallbackNodesForRole(String role) {
    final now = DateTime.now().toIso8601String();
    switch (role) {
      case 'Python Developer':
        return [
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Python Data Structures & OOP',
            description:
                'Master list comprehensions, generators, decorators, and object-oriented class architecture.',
            category: 'Core Python',
            estimatedDays: 4,
            resourceTitle: 'Python Official Tutorial',
            resourceUrl: 'https://docs.python.org/3/tutorial/',
            orderIndex: 0,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Virtual Environments & Package Management',
            description:
                'Understand pip, poetry, venv, and modern Python project packaging standards.',
            category: 'Tooling',
            estimatedDays: 2,
            resourceTitle: 'Python Packaging Guide',
            resourceUrl: 'https://packaging.python.org/en/latest/',
            orderIndex: 1,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'File I/O & JSON Data Handling',
            description:
                'Read, write, parse, and serialize JSON datasets and handle robust file streams.',
            category: 'Core Python',
            estimatedDays: 2,
            resourceTitle: 'RealPython File I/O',
            resourceUrl: 'https://realpython.com/read-write-files-python/',
            orderIndex: 2,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'FastAPI & RESTful APIs',
            description:
                'Build high-performance asynchronous REST microservices using Pydantic schemas and OpenAPI.',
            category: 'Web Framework',
            estimatedDays: 5,
            resourceTitle: 'FastAPI Documentation',
            resourceUrl: 'https://fastapi.tiangolo.com/',
            orderIndex: 3,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'Relational Databases & SQLAlchemy',
            description:
                'Model database schemas, write migrations with Alembic, and perform optimized relational queries.',
            category: 'Databases',
            estimatedDays: 4,
            resourceTitle: 'SQLAlchemy 2.0 Docs',
            resourceUrl: 'https://docs.sqlalchemy.org/',
            orderIndex: 4,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'PyTest & Automated Testing',
            description:
                'Write robust unit and integration tests with mocks, fixtures, and coverage metrics.',
            category: 'Testing',
            estimatedDays: 3,
            resourceTitle: 'PyTest Documentation',
            resourceUrl: 'https://docs.pytest.org/',
            orderIndex: 5,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Asynchronous Programming with Asyncio',
            description:
                'Deep dive into event loops, coroutines, tasks, and non-blocking I/O architectures.',
            category: 'Advanced Python',
            estimatedDays: 5,
            resourceTitle: 'Python Asyncio Docs',
            resourceUrl: 'https://docs.python.org/3/library/asyncio.html',
            orderIndex: 6,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Celery & Redis Distributed Task Queues',
            description:
                'Offload long-running background workers, batch tasks, and periodic scheduled jobs.',
            category: 'Architecture',
            estimatedDays: 4,
            resourceTitle: 'Celery Project Guide',
            resourceUrl: 'https://docs.celeryq.dev/',
            orderIndex: 7,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Dockerizing & Cloud Deployments',
            description:
                'Containerize multi-container Python services with Docker Compose and deploy to cloud platforms.',
            category: 'DevOps',
            estimatedDays: 4,
            resourceTitle: 'Docker for Python',
            resourceUrl: 'https://docs.docker.com/language/python/',
            orderIndex: 8,
            createdAt: now,
          ),
        ];

      case 'Flutter Developer':
        return [
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Dart Fundamentals & OOP',
            description:
                'Master sound null safety, async/await, streams, collections, and mixins.',
            category: 'Dart',
            estimatedDays: 3,
            resourceTitle: 'Dart Language Tour',
            resourceUrl: 'https://dart.dev/guides/language/language-tour',
            orderIndex: 0,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Flutter Widget Hierarchy & Responsive Layouts',
            description:
                'Build adaptive mobile layouts using Column, Row, LayoutBuilder, and MediaQuery.',
            category: 'UI Development',
            estimatedDays: 4,
            resourceTitle: 'Flutter Layout Documentation',
            resourceUrl: 'https://docs.flutter.dev/ui/layout',
            orderIndex: 1,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Navigation & Routing',
            description:
                'Implement declarative and imperative routing with deep linking patterns.',
            category: 'Architecture',
            estimatedDays: 3,
            resourceTitle: 'Flutter Navigation Guide',
            resourceUrl: 'https://docs.flutter.dev/ui/navigation',
            orderIndex: 2,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'State Management (Provider & Riverpod)',
            description:
                'Decouple business logic from UI with immutable state containers and reactive notifiers.',
            category: 'State Management',
            estimatedDays: 5,
            resourceTitle: 'Flutter State Management',
            resourceUrl:
                'https://docs.flutter.dev/data-and-backend/state-mgmt/intro',
            orderIndex: 3,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'REST APIs & Offline Caching (SQLite & Hive)',
            description:
                'Consume remote endpoints, handle network errors, and synchronize local SQLite data.',
            category: 'Data & Networking',
            estimatedDays: 4,
            resourceTitle: 'Networking in Flutter',
            resourceUrl:
                'https://docs.flutter.dev/cookbook/networking/fetch-data',
            orderIndex: 4,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'Custom Animations & Transitions',
            description:
                'Create fluid micro-interactions with AnimationController, Tween, and Hero animations.',
            category: 'UI/UX',
            estimatedDays: 4,
            resourceTitle: 'Flutter Animation Guide',
            resourceUrl: 'https://docs.flutter.dev/ui/animations',
            orderIndex: 5,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Clean Architecture & Dependency Injection',
            description:
                'Organize features into domain, data, and presentation layers for production scalability.',
            category: 'Architecture',
            estimatedDays: 6,
            resourceTitle: 'Flutter Clean Architecture',
            resourceUrl: 'https://flutter.dev/docs',
            orderIndex: 6,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Automated Widget & Golden Testing',
            description:
                'Implement thorough unit, widget, and screenshot regression tests in CI pipelines.',
            category: 'Testing',
            estimatedDays: 4,
            resourceTitle: 'Testing Flutter Apps',
            resourceUrl: 'https://docs.flutter.dev/testing',
            orderIndex: 7,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'App Performance & Release Optimization',
            description:
                'Profile frame rates, tree-shake assets, reduce binary size, and sign production releases.',
            category: 'Deployment',
            estimatedDays: 4,
            resourceTitle: 'Flutter Performance Best Practices',
            resourceUrl: 'https://docs.flutter.dev/perf/best-practices',
            orderIndex: 8,
            createdAt: now,
          ),
        ];

      default:
        // Generic Software Engineer / Full Stack template
        return [
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Data Structures & Algorithmic Complexity',
            description:
                'Arrays, Hash Maps, Linked Lists, Stacks, Queues, and Big-O time-space complexity.',
            category: 'Computer Science',
            estimatedDays: 4,
            resourceTitle: 'Algorithms Guide',
            resourceUrl: 'https://www.geeksforgeeks.org/data-structures/',
            orderIndex: 0,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Object-Oriented Design & Clean Code',
            description:
                'SOLID principles, DRY, encapsulation, inheritance, polymorphism, and modular refactoring.',
            category: 'Engineering Best Practices',
            estimatedDays: 3,
            resourceTitle: 'SOLID Principles Overview',
            resourceUrl: 'https://en.wikipedia.org/wiki/SOLID',
            orderIndex: 1,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Beginner',
            topicTitle: 'Relational Database Queries & Schema Design',
            description:
                'SQL Joins, Normalization, indexing fundamentals, and ACID transaction guarantees.',
            category: 'Databases',
            estimatedDays: 3,
            resourceTitle: 'PostgreSQL Tutorial',
            resourceUrl: 'https://www.postgresqltutorial.com/',
            orderIndex: 2,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'RESTful API Architecture & Authentication',
            description:
                'HTTP verbs, status codes, stateless sessions, JWT tokens, and OAuth2 authorization flows.',
            category: 'Web Services',
            estimatedDays: 4,
            resourceTitle: 'REST API Best Practices',
            resourceUrl: 'https://restfulapi.net/',
            orderIndex: 3,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'Trees, Graphs & Dynamic Programming',
            description:
                'Binary trees, BFS/DFS traversals, Dijkstra, memoization, and optimal substructure problems.',
            category: 'Algorithms',
            estimatedDays: 6,
            resourceTitle: 'LeetCode Problem Sets',
            resourceUrl: 'https://leetcode.com/explore/',
            orderIndex: 4,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Intermediate',
            topicTitle: 'Git Collaborative Workflows & CI/CD',
            description:
                'Feature branching, rebasing, pull request reviews, and GitHub Actions automation.',
            category: 'DevOps',
            estimatedDays: 3,
            resourceTitle: 'Git Pro Book',
            resourceUrl: 'https://git-scm.com/book/en/v2',
            orderIndex: 5,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Distributed Systems & Scalability',
            description:
                'Caching with Redis, load balancers, database sharding, replication, and CAP theorem.',
            category: 'System Design',
            estimatedDays: 6,
            resourceTitle: 'System Design Primer',
            resourceUrl: 'https://github.com/donnemartin/system-design-primer',
            orderIndex: 6,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Containerization & Cloud Services',
            description:
                'Docker image packaging, multi-stage builds, cloud compute, and managed databases.',
            category: 'Cloud Architecture',
            estimatedDays: 4,
            resourceTitle: 'Docker Documentation',
            resourceUrl: 'https://docs.docker.com/',
            orderIndex: 7,
            createdAt: now,
          ),
          AiRoadmapNode(
            roadmapId: 0,
            level: 'Advanced',
            topicTitle: 'Placement Interview Mock & System Design Presentation',
            description:
                'Communicate architectural trade-offs, solve live coding constraints, and answer HR scenarios.',
            category: 'Interview Preparation',
            estimatedDays: 4,
            resourceTitle: 'Tech Interview Handbook',
            resourceUrl: 'https://www.techinterviewhandbook.org/',
            orderIndex: 8,
            createdAt: now,
          ),
        ];
    }
  }

  /// Converts a roadmap milestone into an actionable task in SkillTrack's Tasks tab
  Future<TaskModel> convertNodeToTask(AiRoadmapNode node) async {
    final now = DateTime.now();
    final dueDate = now.add(Duration(days: node.estimatedDays));

    final task = TaskModel(
      title: 'Roadmap: ${node.topicTitle}',
      description:
          '${node.description}\n\nResource: ${node.resourceTitle} (${node.resourceUrl})',
      category: 'Roadmap',
      priority: node.level == 'Beginner'
          ? 'Medium'
          : node.level == 'Intermediate'
              ? 'High'
              : 'Medium',
      creationDate: now.toIso8601String(),
      dueDate: dueDate.toIso8601String().split('T').first,
      isCompleted: false,
    );

    final createdId = await _tasksRepo.addTask(task);
    return task.copyWith(id: createdId);
  }
}
