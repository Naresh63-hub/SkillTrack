import 'package:flutter/foundation.dart';
import '../models/career_chat_models.dart';
import '../repositories/career_assistant_repository.dart';
import '../repositories/certificates_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/projects_repository.dart';
import '../repositories/skills_repository.dart';
import '../repositories/tasks_repository.dart';
import 'ai_service.dart';

class CareerAssistantService {
  final CareerAssistantRepository _repository = CareerAssistantRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final SkillsRepository _skillsRepo = SkillsRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();
  final TasksRepository _tasksRepo = TasksRepository();
  final CertificatesRepository _certsRepo = CertificatesRepository();

  Future<Map<String, dynamic>> _gatherStudentContext() async {
    final profile = await _profileRepo.getProfile();
    final skills = await _skillsRepo.getAllSkills();
    final projects = await _projectsRepo.getAllProjects();
    final tasks = await _tasksRepo.getAllTasks();
    final certs = await _certsRepo.getAllCertificates();

    return {
      'name': profile.name.isNotEmpty ? profile.name : 'Student',
      'college': profile.college.isNotEmpty ? profile.college : 'Engineering College',
      'degree': profile.degree.isNotEmpty ? profile.degree : 'B.Tech',
      'branch': profile.branch.isNotEmpty ? profile.branch : 'Computer Science',
      'graduationYear': profile.graduationYear.isNotEmpty ? profile.graduationYear : '2026',
      'targetRole': profile.targetJobRole.isNotEmpty
          ? profile.targetJobRole
          : 'Software Engineer',
      'skills': skills
          .map((s) =>
              '${s.name} (${s.proficiencyLevel}, ${s.progressPercentage.toInt()}%)')
          .toList(),
      'completedProjects': projects
          .where((p) => p.status == 'Completed')
          .map((p) => p.name)
          .toList(),
      'inProgressProjects': projects
          .where((p) => p.status == 'In Progress')
          .map((p) => p.name)
          .toList(),
      'completedTasks': tasks.where((t) => t.isCompleted).length,
      'pendingTasks': tasks.where((t) => !t.isCompleted).length,
      'certificates': certs.map((c) => c.name).toList(),
    };
  }

  String _sanitizeInput(String input) {
    // Prevent delimiter / control injection attacks
    return input
        .replaceAll('```', '')
        .replaceAll('System:', '')
        .replaceAll('Assistant:', '')
        .trim();
  }

  Future<CareerChatMessage> processUserMessage({
    required int sessionId,
    required String userText,
    required List<CareerChatMessage> history,
  }) async {
    final cleanText = _sanitizeInput(userText);
    final now = DateTime.now().toIso8601String();

    // 1. Save user message to database
    final userMsg = CareerChatMessage(
      sessionId: sessionId,
      sender: 'user',
      content: cleanText,
      createdAt: now,
    );
    await _repository.addMessage(userMsg);

    // 2. Load live student context
    final context = await _gatherStudentContext();

    // 3. Attempt Gemini AI Response
    String? aiResponse;
    String? detectedAction;
    String? detectedPayload;

    try {
      final systemInstruction = '''
You are SkillTrack's AI Career Assistant, an elite collegiate career coach and technical hiring advisor.
You are talking to ${context['name']}, a student at ${context['college']} (${context['degree']} ${context['branch']}, graduating in ${context['graduationYear']}).
Their target career role is "${context['targetRole']}".
Their current tracked skills: ${(context['skills'] as List).join(', ')}.
Their completed projects: ${(context['completedProjects'] as List).join(', ')}.
Their in-progress projects: ${(context['inProgressProjects'] as List).join(', ')}.
Certificates: ${(context['certificates'] as List).join(', ')}.
Tasks completed: ${context['completedTasks']}, pending: ${context['pendingTasks']}.

Guidelines:
- Give concise, motivating, actionable advice (2-4 paragraphs maximum).
- Directly reference their actual skills, target role, and projects to make guidance deeply personal.
- If they ask about roadmaps or what to learn next, recommend the AI Learning Roadmap module.
- If they ask about interview practice or placement screening, recommend an AI Mock Interview.
- If they ask about GitHub or portfolio building, suggest connecting their GitHub to showcase open-source work.
- Provide concrete tips for: career planning, placement preparation, project recommendations, resume improvement, and technical skill development.
''';

      // Keep recent 14 messages for extended conversation memory
      final recentHistory = history.length > 14
          ? history.sublist(history.length - 14)
          : history;

      final conversationSnippet = recentHistory
          .map((m) => '${m.isUser ? "Student" : "Assistant"}: ${m.content}')
          .join('\n');

      final prompt = '''
$conversationSnippet
Student: $cleanText
Assistant:
''';

      aiResponse = await AiService.instance.generateContent(
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
    } catch (e) {
      debugPrint('AI Career Assistant communication exception: $e');
    }

    // 4. Fallback if offline / no API key configured
    if (aiResponse == null || aiResponse.isEmpty) {
      final fallbackData = _generateFallbackGuidance(cleanText, context);
      aiResponse = fallbackData['text'] as String;
      detectedAction = fallbackData['action'] as String?;
      detectedPayload = fallbackData['payload'] as String?;
    } else {
      // Auto-detect action pills from user query and response
      final lower = cleanText.toLowerCase();
      if (lower.contains('roadmap') ||
          lower.contains('path') ||
          lower.contains('learn next') ||
          lower.contains('curriculum')) {
        detectedAction = 'roadmap';
        detectedPayload = context['targetRole'];
      } else if (lower.contains('interview') ||
          lower.contains('mock') ||
          lower.contains('dsa') ||
          lower.contains('hr')) {
        detectedAction = 'interview';
        detectedPayload = context['targetRole'];
      } else if (lower.contains('github') ||
          lower.contains('repo') ||
          lower.contains('git') ||
          lower.contains('portfolio')) {
        detectedAction = 'github';
      }
    }

    final assistantMsg = CareerChatMessage(
      sessionId: sessionId,
      sender: 'assistant',
      content: aiResponse,
      actionType: detectedAction,
      actionPayload: detectedPayload,
      createdAt: DateTime.now().toIso8601String(),
    );

    return await _repository.addMessage(assistantMsg);
  }

  Map<String, dynamic> _generateFallbackGuidance(
    String query,
    Map<String, dynamic> ctx,
  ) {
    final q = query.toLowerCase();
    final name = ctx['name'] as String;
    final role = ctx['targetRole'] as String;
    final skills = (ctx['skills'] as List).cast<String>();
    final projects = (ctx['completedProjects'] as List).cast<String>();

    // 1. Roadmap & Skill Acquisition
    if (q.contains('roadmap') ||
        q.contains('learn') ||
        q.contains('what should i') ||
        q.contains('skill')) {
      return {
        'text':
            'Hello $name! For your goal of becoming a **$role**, your current technical stack (${skills.take(3).join(', ')}) provides a solid foundation.\n\nTo become placement-ready, I recommend focusing on closing your skill gaps through our **AI Learning Roadmap**. It will guide you step-by-step through beginner, intermediate, and advanced milestones with official documentation and practice tasks.\n\n*(💡 Local heuristic guidance: Configure your Gemini API key in Settings for cloud generative AI)*',
        'action': 'roadmap',
        'payload': role,
      };
    }

    // 2. Interview & Placement Preparation
    if (q.contains('interview') ||
        q.contains('prepare') ||
        q.contains('dsa') ||
        q.contains('placement') ||
        q.contains('campus')) {
      return {
        'text':
            'Preparing for placement drives requires algorithmic problem-solving and confident technical communication, $name.\n\n**3 Key Placement Steps:**\n1. Solve 2 LeetCode / HackerRank problems daily focusing on Arrays, Trees, and Dynamic Programming.\n2. Review Core Computer Science fundamentals (DBMS, OS, and Computer Networks).\n3. Take an **AI Mock Interview** for **$role** to practice real technical questions and receive objective scoring.\n\n*(💡 Local heuristic guidance: Configure your Gemini API key in Settings for cloud generative AI)*',
        'action': 'interview',
        'payload': role,
      };
    }

    // 3. Resume & Portfolio Improvement
    if (q.contains('resume') || q.contains('cv') || q.contains('ats')) {
      return {
        'text':
            'For your **$role** resume, recruiters prioritize measurable outcomes, $name. You currently have ${projects.length} completed project(s) recorded (${projects.join(', ')}).\n\n**Actionable Resume Checklist:**\n• Apply the Google XYZ formula: *"Accomplished [X], as measured by [Y], by doing [Z]"*.\n• Include active GitHub repository links and live deployed demos.\n• Ensure high ATS compatibility by exporting your verified resume directly from SkillTrack\'s Resume tab.\n\n*(💡 Local heuristic guidance: Configure your Gemini API key in Settings for cloud generative AI)*',
        'action': 'github',
        'payload': null,
      };
    }

    // 4. Projects & GitHub Recommendations
    if (q.contains('github') || q.contains('project') || q.contains('idea')) {
      return {
        'text':
            'Connecting your GitHub is a top differentiator for campus placements, $name! Recruiters love seeing active commit history and well-structured README documentation.\n\n**Recommended Project Ideas for $role:**\n1. **Full-Stack SaaS Platform**: Role-based authentication, PostgreSQL/SQLite database, and RESTful API endpoints.\n2. **Real-Time System**: WebSocket chat or live collaborative dashboard.\n3. Sync your existing GitHub repositories into SkillTrack with one tap from the GitHub Activity Hub.\n\n*(💡 Local heuristic guidance: Configure your Gemini API key in Settings for cloud generative AI)*',
        'action': 'github',
        'payload': null,
      };
    }

    // 5. Default General Guidance
    return {
      'text':
          'Great question, $name! As an aspiring **$role** graduating in ${ctx['graduationYear']}, daily consistency is your greatest competitive advantage.\n\nCurrently, you have ${ctx['completedTasks']} completed tasks and ${ctx['pendingTasks']} pending tasks. Target solving at least 1-2 coding problems daily and building production-grade projects.\n\nFeel free to ask me about:\n• Recommended project ideas for $role\n• How to structure your placement resume\n• Mock technical interview practice\n• What certifications add real value\n\n*(💡 Local heuristic guidance: Configure your Gemini API key in Settings for cloud generative AI)*',
      'action': null,
      'payload': null,
    };
  }
}
