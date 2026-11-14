import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:skilltrack/models/ai_roadmap.dart';
import 'package:skilltrack/models/github_models.dart';
import 'package:skilltrack/models/mock_interview.dart';
import 'package:skilltrack/models/career_chat_models.dart';
import 'package:skilltrack/services/ai_roadmap_service.dart';
import 'package:skilltrack/services/mock_interview_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('AI Learning Roadmap Unit Tests', () {
    test('AiRoadmap serialization and progress calculations', () {
      final now = DateTime.now();
      final nodes = [
        AiRoadmapNode(
          id: 1,
          roadmapId: 10,
          topicTitle: 'Dart Basics',
          description: 'Variables, loops, and OOP fundamentals',
          level: 'Beginner',
          category: 'Language',
          estimatedDays: 3,
          resourceTitle: 'Dart Docs',
          resourceUrl: 'https://dart.dev',
          isCompleted: true,
          orderIndex: 1,
          createdAt: now.toIso8601String(),
        ),
        AiRoadmapNode(
          id: 2,
          roadmapId: 10,
          topicTitle: 'Flutter Widgets',
          description: 'Stateless and Stateful widgets',
          level: 'Intermediate',
          category: 'Framework',
          estimatedDays: 5,
          resourceTitle: 'Flutter Docs',
          resourceUrl: 'https://flutter.dev',
          isCompleted: false,
          orderIndex: 2,
          createdAt: now.toIso8601String(),
        ),
      ];

      final roadmap = AiRoadmap(
        id: 10,
        targetRole: 'Flutter Developer',
        skillLevel: 'Intermediate',
        overallProgress: 50.0,
        summary: 'Roadmap for Flutter mastery',
        skillGaps: const ['State management', 'Backend integration'],
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
        nodes: nodes,
      );

      expect(roadmap.targetRole, equals('Flutter Developer'));
      expect(roadmap.skillLevel, equals('Intermediate'));
      expect(roadmap.overallProgress, equals(50.0));
      expect(roadmap.nodes.length, equals(2));
      expect(roadmap.skillGaps.length, equals(2));

      // Test toMap and fromMap
      final map = roadmap.toMap();
      expect(map['target_role'], equals('Flutter Developer'));
      expect(map['overall_progress'], equals(50.0));

      final fromMapRoadmap = AiRoadmap.fromMap(map, nodes: nodes);
      expect(fromMapRoadmap.id, equals(10));
      expect(fromMapRoadmap.targetRole, equals('Flutter Developer'));
      expect(fromMapRoadmap.nodes.length, equals(2));

      // Test node toMap and fromMap
      final nodeMap = nodes.first.toMap();
      expect(nodeMap['topic_title'], equals('Dart Basics'));
      expect(nodeMap['is_completed'], equals(1));

      final fromMapNode = AiRoadmapNode.fromMap(nodeMap);
      expect(fromMapNode.topicTitle, equals('Dart Basics'));
      expect(fromMapNode.isCompleted, isTrue);
      expect(fromMapNode.level, equals('Beginner'));
    });

    test('AiRoadmapService provides all 7 required career roles', () {
      final supportedRoles = AiRoadmapService.supportedRoles;
      expect(supportedRoles.length, equals(7));
      expect(supportedRoles, contains('Python Developer'));
      expect(supportedRoles, contains('Java Developer'));
      expect(supportedRoles, contains('Full Stack Developer'));
      expect(supportedRoles, contains('AI/ML Engineer'));
      expect(supportedRoles, contains('Data Analyst'));
      expect(supportedRoles, contains('Flutter Developer'));
      expect(supportedRoles, contains('Software Engineer'));
    });
  });

  group('GitHub Integration Models Unit Tests', () {
    test('GithubProfile serialization round-trip', () {
      final now = DateTime.now();
      final profile = GithubProfile(
        username: 'naresh-dev',
        name: 'Naresh G',
        avatarUrl: 'https://avatars.githubusercontent.com/u/12345',
        bio: 'Flutter and AI Developer',
        publicRepos: 25,
        publicGists: 5,
        followers: 120,
        following: 80,
        htmlUrl: 'https://github.com/naresh-dev',
        connectedAt: now.toIso8601String(),
        lastSyncedAt: now.toIso8601String(),
      );

      final map = profile.toMap();
      expect(map['username'], equals('naresh-dev'));
      expect(map['public_repos'], equals(25));
      expect(map['followers'], equals(120));

      final fromMap = GithubProfile.fromMap(map);
      expect(fromMap.username, equals('naresh-dev'));
      expect(fromMap.publicRepos, equals(25));
      expect(fromMap.bio, equals('Flutter and AI Developer'));
    });

    test('GithubRepositoryModel serialization and parsing', () {
      final repo = GithubRepositoryModel(
        repoId: 1001,
        name: 'SkillTrack',
        fullName: 'naresh-dev/SkillTrack',
        description: 'Student Skills and Placement Tracker App',
        language: 'Dart',
        stargazersCount: 15,
        forksCount: 3,
        htmlUrl: 'https://github.com/naresh-dev/SkillTrack',
        updatedAt: '2026-11-09T10:00:00Z',
        isFork: false,
        isImportedToPortfolio: false,
      );

      final map = repo.toMap();
      expect(map['repo_id'], equals(1001));
      expect(map['name'], equals('SkillTrack'));
      expect(map['language'], equals('Dart'));
      expect(map['stargazers_count'], equals(15));
      expect(map['is_imported_to_portfolio'], equals(0));

      final fromMap = GithubRepositoryModel.fromMap(map);
      expect(fromMap.repoId, equals(1001));
      expect(fromMap.fullName, equals('naresh-dev/SkillTrack'));
      expect(fromMap.language, equals('Dart'));
      expect(fromMap.isImportedToPortfolio, isFalse);
    });

    test('GithubCommit serialization', () {
      final commit = const GithubCommit(
        repoName: 'SkillTrack',
        message: 'feat: add ai learning roadmap',
        commitDate: '2026-11-10T06:00:00Z',
        authorName: 'Naresh G',
      );

      final map = commit.toMap();
      expect(map['message'], equals('feat: add ai learning roadmap'));
      expect(map['repo_name'], equals('SkillTrack'));

      final fromMap = GithubCommit.fromMap(map);
      expect(fromMap.authorName, equals('Naresh G'));
      expect(fromMap.repoName, equals('SkillTrack'));
    });
  });

  group('AI Mock Interview Unit Tests', () {
    test('MockInterview serialization and properties', () {
      final now = DateTime.now();
      final interview = MockInterview(
        id: 7,
        jobRole: 'Python Developer',
        category: 'Python',
        difficulty: 'Medium',
        totalQuestions: 5,
        completedQuestions: 5,
        overallScore: 82.5,
        status: 'Completed',
        strengths: const ['Good grasp of OOP', 'decorators'],
        weaknesses: const ['Need improvement in asyncio'],
        recommendedTopics: const ['Concurrency', 'Generators'],
        feedbackSummary:
            'Strong technical foundation with great syntax clarity.',
        createdAt: now.toIso8601String(),
      );

      final map = interview.toMap();
      expect(map['job_role'], equals('Python Developer'));
      expect(map['category'], equals('Python'));
      expect(map['difficulty'], equals('Medium'));
      expect(map['overall_score'], equals(82.5));
      expect(map['status'], equals('Completed'));

      final fromMap = MockInterview.fromMap(map);
      expect(fromMap.id, equals(7));
      expect(fromMap.jobRole, equals('Python Developer'));
      expect(fromMap.overallScore, equals(82.5));
      expect(fromMap.status, equals('Completed'));
      expect(fromMap.strengths, contains('decorators'));
    });

    test('MockInterviewAnswer serialization and score parsing', () {
      final answer = const MockInterviewAnswer(
        id: 1,
        interviewId: 7,
        questionIndex: 1,
        question: 'What are Python decorators and how do they work?',
        userAnswer:
            'A decorator is a function that takes another function as an argument, extends its behavior without modifying it, and returns a new function.',
        score: 88.0,
        feedback: 'Accurate definition with correct mention of closures.',
        expectedPoints:
            'A decorator wraps a function to modify or extend its behavior.',
      );

      final map = answer.toMap();
      expect(map['interview_id'], equals(7));
      expect(map['question_index'], equals(1));
      expect(map['score'], equals(88.0));

      final fromMap = MockInterviewAnswer.fromMap(map);
      expect(fromMap.id, equals(1));
      expect(fromMap.score, equals(88.0));
      expect(fromMap.userAnswer, contains('decorator is a function'));
    });

    test('MockInterviewService category question coverage', () {
      final categories = MockInterviewService.categories;
      expect(categories, contains('Python'));
      expect(categories, contains('Java'));
      expect(categories, contains('SQL'));
      expect(categories, contains('Data Structures and Algorithms'));
      expect(categories, contains('HTML/CSS/JavaScript'));
      expect(categories, contains('AI/ML'));
      expect(categories, contains('HR & Behavioral'));
    });
  });

  group('AI Career Assistant Unit Tests', () {
    test('CareerChatSession and CareerChatMessage serialization', () {
      final now = DateTime.now();
      final session = CareerChatSession(
        id: 3,
        title: 'Career Planning for Flutter',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      final sessionMap = session.toMap();
      expect(sessionMap['id'], equals(3));
      expect(sessionMap['title'], equals('Career Planning for Flutter'));

      final fromSessionMap = CareerChatSession.fromMap(sessionMap);
      expect(fromSessionMap.id, equals(3));
      expect(fromSessionMap.title, equals('Career Planning for Flutter'));

      final message = CareerChatMessage(
        id: 11,
        sessionId: 3,
        sender: 'user',
        content: 'What should I learn after state management in Flutter?',
        createdAt: now.toIso8601String(),
      );

      final messageMap = message.toMap();
      expect(messageMap['session_id'], equals(3));
      expect(messageMap['sender'], equals('user'));
      expect(messageMap['content'], contains('state management'));

      final fromMessageMap = CareerChatMessage.fromMap(messageMap);
      expect(fromMessageMap.id, equals(11));
      expect(fromMessageMap.sender, equals('user'));
      expect(fromMessageMap.content, equals(message.content));
    });
  });

  group('Weekly Schedule & Security Unit Tests', () {
    test('organizeWeeklySchedule organizes nodes into 4 structured weeks', () {
      final now = DateTime.now().toIso8601String();
      final nodes = List.generate(
        8,
        (i) => AiRoadmapNode(
          roadmapId: 1,
          level: i < 3
              ? 'Beginner'
              : i < 6
                  ? 'Intermediate'
                  : 'Advanced',
          topicTitle: 'Topic ${i + 1}',
          description: 'Description $i',
          category: 'Category',
          estimatedDays: 3,
          resourceTitle: 'Resource',
          resourceUrl: 'https://example.com',
          orderIndex: i,
          createdAt: now,
        ),
      );

      final service = AiRoadmapService();
      final schedule = service.organizeWeeklySchedule(nodes);

      expect(schedule.length, equals(4));
      expect(schedule[0]['week'], equals(1));
      expect(schedule[0]['targetDays'], equals('Days 1-7'));
      expect((schedule[0]['nodes'] as List).isNotEmpty, isTrue);
      expect(schedule[3]['week'], equals(4));
    });
  });
}
