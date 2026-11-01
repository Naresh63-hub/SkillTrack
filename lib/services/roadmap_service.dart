import 'package:flutter/material.dart';
import '../models/career_roadmap.dart';
import '../models/skill.dart';
import '../repositories/skills_repository.dart';

class RoadmapService {
  final SkillsRepository _skillsRepository;

  RoadmapService({SkillsRepository? skillsRepository})
      : _skillsRepository = skillsRepository ?? SkillsRepository();

  /// Returns all 6 curated career role roadmaps.
  static List<CareerRoadmap> getAvailableRoadmaps() {
    return [
      _flutterDeveloperRoadmap,
      _pythonDeveloperRoadmap,
      _fullStackDeveloperRoadmap,
      _dataAnalystRoadmap,
      _aiMlEngineerRoadmap,
      _javaDeveloperRoadmap,
    ];
  }

  /// Look up a roadmap by its unique ID.
  static CareerRoadmap? getRoadmapById(String id) {
    try {
      return getAvailableRoadmaps().firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Look up a roadmap matching or closely matching a student's target role name.
  static CareerRoadmap? getRoadmapByRoleName(String roleName) {
    final lower = roleName.trim().toLowerCase();
    if (lower.isEmpty) return null;

    final roadmaps = getAvailableRoadmaps();
    for (final roadmap in roadmaps) {
      if (roadmap.roleName.toLowerCase() == lower) {
        return roadmap;
      }
    }

    // Partial search / keywords
    if (lower.contains('flutter') ||
        lower.contains('dart') ||
        lower.contains('mobile')) {
      return _flutterDeveloperRoadmap;
    }
    if (lower.contains('full stack') ||
        lower.contains('fullstack') ||
        lower.contains('web')) {
      return _fullStackDeveloperRoadmap;
    }
    if (lower.contains('python') ||
        lower.contains('django') ||
        lower.contains('fastapi')) {
      return _pythonDeveloperRoadmap;
    }
    if (lower.contains('data') ||
        lower.contains('analyst') ||
        lower.contains('analytics') ||
        lower.contains('bi')) {
      return _dataAnalystRoadmap;
    }
    if (lower.contains('ai') ||
        lower.contains('ml') ||
        lower.contains('machine learning') ||
        lower.contains('deep learning')) {
      return _aiMlEngineerRoadmap;
    }
    if (lower.contains('java') || lower.contains('spring')) {
      return _javaDeveloperRoadmap;
    }

    return null;
  }

  /// Idempotently imports all non-duplicate skills from a roadmap into SQLite.
  ///
  /// - Initial progress for newly imported skills is 0.0%.
  /// - Skills already present in the student's database (matched case-insensitively by name)
  ///   are strictly preserved and never overwritten or reset.
  /// - Calling this multiple times will never generate duplicate entries.
  Future<RoadmapImportResult> importRoadmap(CareerRoadmap roadmap) async {
    final existingSkills = await _skillsRepository.getAllSkills();
    final existingNormalizedNames = <String>{};

    for (final s in existingSkills) {
      existingNormalizedNames.add(s.name.trim().toLowerCase());
    }

    final addedList = <String>[];
    final skippedList = <String>[];

    for (final item in roadmap.skills) {
      final normalizedName = item.name.trim().toLowerCase();
      if (existingNormalizedNames.contains(normalizedName)) {
        skippedList.add(item.name);
      } else {
        final newSkill = item.toSkill();
        await _skillsRepository.addSkill(newSkill);
        addedList.add(item.name);
        existingNormalizedNames.add(normalizedName);
      }
    }

    return RoadmapImportResult(
      roleName: roadmap.roleName,
      totalSkills: roadmap.skills.length,
      addedCount: addedList.length,
      skippedCount: skippedList.length,
      addedSkillNames: addedList,
      skippedSkillNames: skippedList,
    );
  }

  /// Returns a map of normalized skill name -> existing [Skill] to inspect current progress.
  Future<Map<String, Skill>> getExistingSkillsMap() async {
    final list = await _skillsRepository.getAllSkills();
    final map = <String, Skill>{};
    for (final s in list) {
      map[s.name.trim().toLowerCase()] = s;
    }
    return map;
  }

  // ===========================================================================
  // Curated 8-Step Career Roadmaps
  // ===========================================================================

  static const CareerRoadmap _flutterDeveloperRoadmap = CareerRoadmap(
    id: 'flutter_developer',
    roleName: 'Flutter Developer',
    tagline: 'Cross-Platform Mobile & Desktop App Engineering',
    description:
        'Master Dart and Flutter to build production-ready iOS, Android, and Web applications with smooth animations, robust state management, and offline SQLite caching.',
    icon: Icons.phone_android_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'Dart Programming',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        description:
            'Core syntax, OOP, null safety, asynchronous programming (Futures & Streams), and collections in Dart.',
        learningResourceUrl: 'https://dart.dev/guides',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'Flutter Fundamentals',
        category: 'Mobile Development',
        proficiencyLevel: 'Beginner',
        description:
            'Widget tree lifecycle, StatelessWidget vs StatefulWidget, BuildContext, themes, and Material 3 design principles.',
        learningResourceUrl: 'https://docs.flutter.dev/ui',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'UI Development',
        category: 'Mobile Development',
        proficiencyLevel: 'Intermediate',
        description:
            'Complex responsive layouts, CustomPainter, Implicit & Explicit animations, Hero transitions, and sliver scrolling.',
        learningResourceUrl: 'https://docs.flutter.dev/ui/layout',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Navigation and State Management',
        category: 'Frameworks and Libraries',
        proficiencyLevel: 'Intermediate',
        description:
            'Deep linking, Navigator 2.0 / GoRouter, Provider, Riverpod, or BLoC architectural patterns.',
        learningResourceUrl:
            'https://docs.flutter.dev/data-and-backend/state-mgmt/intro',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'REST APIs',
        category: 'Web Development',
        proficiencyLevel: 'Intermediate',
        description:
            'HTTP requests, JSON serialization, interceptors, error handling, Dio package, and repository data patterns.',
        learningResourceUrl:
            'https://docs.flutter.dev/cookbook/networking/fetch-data',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'SQLite and Local Storage',
        category: 'Databases',
        proficiencyLevel: 'Intermediate',
        description:
            'Offline-first architecture, SharedPreferences, sqflite schema migrations, transactions, and secure key-value storage.',
        learningResourceUrl:
            'https://docs.flutter.dev/cookbook/persistence/sqlite',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'Git and GitHub',
        category: 'Developer Tools',
        proficiencyLevel: 'Beginner',
        description:
            'Branching strategies, pull requests, resolving merge conflicts, semantic commits, and GitHub collaborative workflows.',
        learningResourceUrl: 'https://docs.github.com/en/get-started',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'Testing and App Deployment',
        category: 'Developer Tools',
        proficiencyLevel: 'Advanced',
        description:
            'Unit, widget, and integration testing with flutter_test, Play Store / App Store release building, CI/CD with GitHub Actions.',
        learningResourceUrl: 'https://docs.flutter.dev/testing',
      ),
    ],
  );

  static const CareerRoadmap _pythonDeveloperRoadmap = CareerRoadmap(
    id: 'python_developer',
    roleName: 'Python Developer',
    tagline: 'Backend Systems, APIs & Automation Engineering',
    description:
        'Become proficient in Python backend development, relational database integration, asynchronous request processing, and deploying scalable web services.',
    icon: Icons.terminal_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'Python Fundamentals & OOP',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        description:
            'Data types, control structures, list comprehensions, object-oriented design, decorators, generators, and clean code practices.',
        learningResourceUrl: 'https://docs.python.org/3/tutorial/',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'Data Structures & Algorithms in Python',
        category: 'Data Structures and Algorithms',
        proficiencyLevel: 'Intermediate',
        description:
            'Hash tables, trees, heaps, graph traversals, dynamic programming, and Big-O algorithmic complexity analysis.',
        learningResourceUrl: 'https://realpython.com/python-data-structures/',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'Virtual Environments & Packaging',
        category: 'Developer Tools',
        proficiencyLevel: 'Beginner',
        description:
            'Managing dependencies with venv, pip, Poetry, pyproject.toml, and modular package organization.',
        learningResourceUrl: 'https://packaging.python.org/en/latest/',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Relational Databases & SQL',
        category: 'Databases',
        proficiencyLevel: 'Intermediate',
        description:
            'PostgreSQL / SQLite schemas, indexing, complex JOIN queries, ACID properties, and query optimization.',
        learningResourceUrl: 'https://sqlbolt.com/',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'Django & FastAPI Frameworks',
        category: 'Frameworks and Libraries',
        proficiencyLevel: 'Intermediate',
        description:
            'Building web servers, Pydantic data validation, async route handlers, dependency injection, and ORM abstractions.',
        learningResourceUrl: 'https://fastapi.tiangolo.com/',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'REST APIs & Serialization',
        category: 'Web Development',
        proficiencyLevel: 'Intermediate',
        description:
            'HTTP status codes, REST conventions, JWT authentication, rate limiting, and OpenAPI/Swagger documentation.',
        learningResourceUrl: 'https://restfulapi.net/',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'Git & Version Control',
        category: 'Developer Tools',
        proficiencyLevel: 'Beginner',
        description:
            'Git commands, rebasing, cherry-picking, code reviews, and remote branch management on GitHub or GitLab.',
        learningResourceUrl: 'https://git-scm.com/doc',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'Testing, Docker & Deployment',
        category: 'Cloud and DevOps',
        proficiencyLevel: 'Advanced',
        description:
            'Pytest unit & integration test suites, mocking, multi-stage Docker containerization, and production cloud deployment.',
        learningResourceUrl: 'https://docs.pytest.org/',
      ),
    ],
  );

  static const CareerRoadmap _fullStackDeveloperRoadmap = CareerRoadmap(
    id: 'full_stack_developer',
    roleName: 'Full Stack Developer',
    tagline: 'End-to-End Modern Web Applications',
    description:
        'Bridge interactive frontend user interfaces and resilient backend web services, databases, authentication pipelines, and containerized deployment.',
    icon: Icons.layers_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'HTML5, CSS3 & Responsive UI',
        category: 'Web Development',
        proficiencyLevel: 'Beginner',
        description:
            'Semantic markup, CSS Grid, Flexbox, responsive media queries, Tailwind CSS, and web accessibility (a11y).',
        learningResourceUrl: 'https://developer.mozilla.org/en-US/docs/Learn',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'JavaScript & Modern TypeScript',
        category: 'Programming Languages',
        proficiencyLevel: 'Intermediate',
        description:
            'ES6+ syntax, asynchronous event loop, promises, TypeScript strict type checking, generics, and interfaces.',
        learningResourceUrl: 'https://www.typescriptlang.org/docs/',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'React or Vue Frontend Frameworks',
        category: 'Frameworks and Libraries',
        proficiencyLevel: 'Intermediate',
        description:
            'Component architecture, hooks, virtual DOM, client-side routing, and global state management with Zustand or Redux.',
        learningResourceUrl: 'https://react.dev/learn',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Node.js & Express Backend',
        category: 'Web Development',
        proficiencyLevel: 'Intermediate',
        description:
            'Event-driven server runtime, middleware architectures, REST controller routing, request parsing, and security headers.',
        learningResourceUrl: 'https://nodejs.org/en/docs',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'Database Design (PostgreSQL & MongoDB)',
        category: 'Databases',
        proficiencyLevel: 'Intermediate',
        description:
            'Relational schema normalization vs NoSQL document modeling, Prisma/Mongoose ORMs, indexing, and aggregate pipelines.',
        learningResourceUrl: 'https://www.prisma.io/docs',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'RESTful APIs & Authentication',
        category: 'Web Development',
        proficiencyLevel: 'Intermediate',
        description:
            'Session management, JWT access & refresh tokens, OAuth2 integration, password hashing (bcrypt), and CORS policies.',
        learningResourceUrl: 'https://auth0.com/intro-to-iam/what-is-jwt',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'Git, GitHub & CI/CD Pipelines',
        category: 'Developer Tools',
        proficiencyLevel: 'Intermediate',
        description:
            'Collaborative Git workflows, automated linting, test validation, and GitHub Actions continuous deployment workflows.',
        learningResourceUrl: 'https://docs.github.com/en/actions',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'Cloud Deployment & Containerization',
        category: 'Cloud and DevOps',
        proficiencyLevel: 'Advanced',
        description:
            'Dockerfile optimization, Docker Compose multi-service environments, Nginx reverse proxies, and deployment on AWS/Vercel.',
        learningResourceUrl: 'https://docs.docker.com/get-started/',
      ),
    ],
  );

  static const CareerRoadmap _dataAnalystRoadmap = CareerRoadmap(
    id: 'data_analyst',
    roleName: 'Data Analyst',
    tagline: 'Data Wrangling, Business Intelligence & Insights',
    description:
        'Transform complex raw datasets into actionable executive insights through advanced SQL, Python analytics libraries, and high-impact visual dashboards.',
    icon: Icons.insights_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'Advanced Spreadsheets & Excel Modeling',
        category: 'Other',
        proficiencyLevel: 'Beginner',
        description:
            'XLOOKUP, INDEX/MATCH, pivot tables, conditional logic formulas, what-if analyses, and interactive data modeling.',
        learningResourceUrl: 'https://support.microsoft.com/en-us/excel',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'Relational Databases & Complex SQL',
        category: 'Databases',
        proficiencyLevel: 'Intermediate',
        description:
            'Window functions (ROW_NUMBER, RANK, LAG/LEAD), subqueries, Common Table Expressions (CTEs), and query profiling.',
        learningResourceUrl: 'https://mode.com/sql-tutorial/',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'Python for Data Analysis (Pandas & NumPy)',
        category: 'Programming Languages',
        proficiencyLevel: 'Intermediate',
        description:
            'Vectorized numerical operations, DataFrame manipulations, grouping, merging datasets, and datetime handling.',
        learningResourceUrl:
            'https://pandas.pydata.org/docs/user_guide/index.html',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Data Visualization (Matplotlib & Seaborn)',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Intermediate',
        description:
            'Statistical plotting, distributions, heatmaps, boxplots, multi-panel visual storytelling, and chart customization.',
        learningResourceUrl: 'https://seaborn.pydata.org/tutorial.html',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'BI Dashboards (Power BI / Tableau)',
        category: 'Other',
        proficiencyLevel: 'Intermediate',
        description:
            'Data modeling, DAX calculated measures, interactive filters, KPI cards, and executive business reporting.',
        learningResourceUrl: 'https://learn.microsoft.com/en-us/power-bi/',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'Applied Statistics & Exploratory Data Analysis',
        category: 'Computer Science Fundamentals',
        proficiencyLevel: 'Intermediate',
        description:
            'Descriptive statistics, hypothesis testing (t-tests, z-tests, ANOVA), correlation vs causation, and sampling methods.',
        learningResourceUrl: 'https://openintro-ims.netlify.app/',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'Data Cleaning & Feature Engineering',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Intermediate',
        description:
            'Handling missing values, outlier detection, string normalization, categorical encoding, and automated pipeline scripts.',
        learningResourceUrl:
            'https://towardsdatascience.com/data-cleaning-in-python',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'Business Reporting & Stakeholder Presentation',
        category: 'Other',
        proficiencyLevel: 'Advanced',
        description:
            'Translating quantitative data into business metrics (CAC, LTV, churn, ROI), writing analytical summaries, and executive decks.',
        learningResourceUrl: 'https://hbr.org/topic/subject/data-visualization',
      ),
    ],
  );

  static const CareerRoadmap _aiMlEngineerRoadmap = CareerRoadmap(
    id: 'ai_ml_engineer',
    roleName: 'AI/ML Engineer',
    tagline: 'Intelligent Models, Deep Learning & Generative AI',
    description:
        'Design, train, optimize, and deploy cutting-edge machine learning and deep learning models into production systems with modern MLOps pipelines.',
    icon: Icons.psychology_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'Python for Machine Learning & Numerical Computing',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        description:
            'NumPy array broadcasting, vector calculations, matrix manipulations, and scientific Python ecosystem essentials.',
        learningResourceUrl:
            'https://numpy.org/doc/stable/user/absolute_beginners.html',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'Mathematics (Linear Algebra, Calculus & Probability)',
        category: 'Computer Science Fundamentals',
        proficiencyLevel: 'Intermediate',
        description:
            'Matrix decompositions (SVD, PCA), gradients & backpropagation calculus, probability distributions, and Bayes theorem.',
        learningResourceUrl: 'https://mml-book.github.io/',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'Data Wrangling & Feature Extraction',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Intermediate',
        description:
            'Feature scaling, one-hot encoding, imputation, dimensionality reduction, train/validation/test splitting, and cross-validation.',
        learningResourceUrl:
            'https://scikit-learn.org/stable/modules/preprocessing.html',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Supervised & Unsupervised Machine Learning',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Intermediate',
        description:
            'Linear/Logistic Regression, Decision Trees, Random Forests, XGBoost, K-Means clustering, and evaluation metrics (ROC-AUC, F1).',
        learningResourceUrl:
            'https://scikit-learn.org/stable/supervised_learning.html',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'Deep Learning & Neural Networks',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Advanced',
        description:
            'Multi-layer perceptrons, activation functions, optimizers (Adam, SGD), loss functions, PyTorch or TensorFlow model development.',
        learningResourceUrl: 'https://pytorch.org/tutorials/',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'Natural Language Processing & Computer Vision',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Advanced',
        description:
            'Tokenization, embeddings (Word2Vec), Transformer architectures, Convolutional Neural Networks (CNNs), and transfer learning.',
        learningResourceUrl: 'https://huggingface.co/learn/nlp-course',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'MLOps, Model Deployment & API Serving',
        category: 'Cloud and DevOps',
        proficiencyLevel: 'Advanced',
        description:
            'Serving models with FastAPI, ONNX runtime, model tracking with MLflow, containerized inference with Docker, and monitoring.',
        learningResourceUrl: 'https://ml-ops.org/',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'Generative AI, LLMs & RAG Architectures',
        category: 'Artificial Intelligence and Machine Learning',
        proficiencyLevel: 'Advanced',
        description:
            'Prompt engineering, fine-tuning pretrained models, vector databases (Chroma/Pinecone), LangChain/LlamaIndex, and RAG pipelines.',
        learningResourceUrl:
            'https://platform.openai.com/docs/guides/prompt-engineering',
      ),
    ],
  );

  static const CareerRoadmap _javaDeveloperRoadmap = CareerRoadmap(
    id: 'java_developer',
    roleName: 'Java Developer',
    tagline: 'Enterprise Applications, Spring Boot & Distributed Services',
    description:
        'Engineer robust, high-throughput enterprise systems with Java, the Spring framework, relational databases, microservices, and containerization.',
    icon: Icons.coffee_rounded,
    skills: [
      RoadmapSkillItem(
        order: 1,
        name: 'Java Core & Object-Oriented Programming',
        category: 'Programming Languages',
        proficiencyLevel: 'Beginner',
        description:
            'Java syntax, classes, inheritance, polymorphism, encapsulation, abstract classes, exception handling, and JVM memory model.',
        learningResourceUrl: 'https://dev.java/learn/',
      ),
      RoadmapSkillItem(
        order: 2,
        name: 'Java Collections, Generics & Streams API',
        category: 'Programming Languages',
        proficiencyLevel: 'Intermediate',
        description:
            'Lists, Sets, Maps, generics type bounds, lambdas, functional interfaces, and stream filter/map/reduce operations.',
        learningResourceUrl:
            'https://dev.java/learn/api/collections-framework/',
      ),
      RoadmapSkillItem(
        order: 3,
        name: 'Data Structures & Algorithms in Java',
        category: 'Data Structures and Algorithms',
        proficiencyLevel: 'Intermediate',
        description:
            'Custom linked lists, binary search trees, hashing collisions, graph algorithms, and algorithmic complexity in Java.',
        learningResourceUrl: 'https://algs4.cs.princeton.edu/home/',
      ),
      RoadmapSkillItem(
        order: 4,
        name: 'Relational Databases & SQL (PostgreSQL / MySQL)',
        category: 'Databases',
        proficiencyLevel: 'Intermediate',
        description:
            'Schema design, foreign keys, normalization, joins, indexes, transaction isolation levels, and JDBC connection pooling.',
        learningResourceUrl:
            'https://dev.mysql.com/doc/refman/8.0/en/tutorial.html',
      ),
      RoadmapSkillItem(
        order: 5,
        name: 'Spring Boot & Spring Framework Ecosystem',
        category: 'Frameworks and Libraries',
        proficiencyLevel: 'Intermediate',
        description:
            'Inversion of Control (IoC), Dependency Injection, Spring Boot auto-configuration, application.properties, and Actuator.',
        learningResourceUrl: 'https://spring.io/guides/gs/spring-boot/',
      ),
      RoadmapSkillItem(
        order: 6,
        name: 'Hibernate / JPA & RESTful Microservices',
        category: 'Web Development',
        proficiencyLevel: 'Intermediate',
        description:
            'Entity mappings, relationships (@OneToMany, @ManyToMany), Spring Data JPA repositories, REST controllers, and DTOs.',
        learningResourceUrl: 'https://spring.io/guides/gs/accessing-data-jpa/',
      ),
      RoadmapSkillItem(
        order: 7,
        name: 'Build Automation (Maven / Gradle) & Git',
        category: 'Developer Tools',
        proficiencyLevel: 'Beginner',
        description:
            'Managing dependencies, build lifecycles, plugins with pom.xml / build.gradle, and standard Git branch management.',
        learningResourceUrl: 'https://maven.apache.org/guides/getting-started/',
      ),
      RoadmapSkillItem(
        order: 8,
        name: 'JUnit Testing, Mockito & Docker Containerization',
        category: 'Developer Tools',
        proficiencyLevel: 'Advanced',
        description:
            'Unit and integration tests with JUnit 5 & Mockito, Testcontainers, building JVM Docker images, and cloud deployments.',
        learningResourceUrl:
            'https://junit.org/junit5/docs/current/user-guide/',
      ),
    ],
  );
}
