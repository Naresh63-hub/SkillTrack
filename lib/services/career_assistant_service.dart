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
      'college': profile.college,
      'degree': profile.degree,
      'branch': profile.branch,
      'graduationYear': profile.graduationYear,
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

  Future<CareerChatMessage> processUserMessage({
    required int sessionId,
    required String userText,
    required List<CareerChatMessage> history,
  }) async {
    final now = DateTime.now().toIso8601String();

    // 1. Save user message to database
    final userMsg = CareerChatMessage(
      sessionId: sessionId,
      sender: 'user',
      content: userText.trim(),
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
You are SkillTrack's AI Career Assistant, an expert collegiate career coach and technical hiring advisor.
You are talking to ${context['name']}, a student at ${context['college']} (${context['degree']} ${context['branch']}, graduating in ${context['graduationYear']}).
Their target career role is "${context['targetRole']}".
Their current skills: ${(context['skills'] as List).join(', ')}.
Their completed projects: ${(context['completedProjects'] as List).join(', ')}.
Their in-progress projects: ${(context['inProgressProjects'] as List).join(', ')}.
Certificates: ${(context['certificates'] as List).join(', ')}.
Tasks completed: ${context['completedTasks']}, pending: ${context['pendingTasks']}.

Guidelines:
- Give concise, motivating, actionable advice (2-4 paragraphs maximum).
- Directly reference their actual skills, target role, and projects to make guidance deeply personal.
- If they ask about roadmaps, mention the AI Learning Roadmap module.
- If they ask about interview practice, recommend taking an AI Mock Interview.
- If they ask about GitHub or projects, suggest connecting their GitHub to showcase open-source work.
''';

      final conversationSnippet = history
          .take(6)
          .map((m) => '${m.isUser ? "Student" : "Assistant"}: ${m.content}')
          .join('\n');

      final prompt = '''
$conversationSnippet
Student: $userText
Assistant:
''';

      aiResponse = await AiService.instance.generateContent(
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
    } catch (e) {
      debugPrint('AI Career Assistant exception: $e');
    }

    // 4. Fallback if offline / no API key
    if (aiResponse == null || aiResponse.isEmpty) {
      final fallbackData = _generateFallbackGuidance(userText, context);
      aiResponse = fallbackData['text'] as String;
      detectedAction = fallbackData['action'] as String?;
      detectedPayload = fallbackData['payload'] as String?;
    } else {
      // Auto-detect action pills from AI text
      final lower = userText.toLowerCase();
      if (lower.contains('roadmap') ||
          lower.contains('path') ||
          lower.contains('learn next')) {
        detectedAction = 'roadmap';
        detectedPayload = context['targetRole'];
      } else if (lower.contains('interview') ||
          lower.contains('mock') ||
          lower.contains('dsa')) {
        detectedAction = 'interview';
        detectedPayload = context['targetRole'];
      } else if (lower.contains('github') ||
          lower.contains('repo') ||
          lower.contains('git')) {
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

    if (q.contains('roadmap') ||
        q.contains('learn') ||
        q.contains('what should i')) {
      return {
        'text':
            'Hello $name! For your goal of becoming a **$role**, your current technical stack (${skills.take(3).join(', ')}) provides a great starting point.\n\nTo become placement-ready, I recommend focusing on closing your skill gaps through our **AI Learning Roadmap**. It will guide you step-by-step through beginner, intermediate, and advanced milestones with official documentation and practice tasks.',
        'action': 'roadmap',
        'payload': role,
      };
    }

    if (q.contains('interview') ||
        q.contains('prepare') ||
        q.contains('dsa') ||
        q.contains('placement')) {
      return {
        'text':
            'Preparing for placement interviews requires both algorithmic depth and clear technical communication, $name.\n\nI recommend starting an **AI Mock Interview** for **$role**. Our interviewer will ask you 5 realistic technical or HR questions, evaluate your actual responses, and give you an objective placement readiness score.',
        'action': 'interview',
        'payload': role,
      };
    }

    if (q.contains('resume') || q.contains('cv') || q.contains('portfolio')) {
      return {
        'text':
            'For your **$role** resume, recruiters look for hands-on proof of problem-solving. You currently have ${projects.length} completed project(s) recorded (${projects.join(', ')}).\n\n**Key Tips for Your Resume:**\n1. Use action verbs and quantifiable metrics (e.g., "Reduced latency by 35% using caching").\n2. Highlight your GitHub repository links and live demo deployments.\n3. Make sure to export your SkillTrack verified resume from the Resume tab!',
        'action': 'github',
        'payload': null,
      };
    }

    if (q.contains('github') || q.contains('project')) {
      return {
        'text':
            'Connecting your GitHub is one of the highest-leverage steps for campus placements, $name! Recruiters love seeing active commit streaks and well-documented README files.\n\nHead over to the **GitHub Activity Hub** where you can sync your repositories, showcase your public contributions, and import your repos directly into your SkillTrack portfolio with one tap.',
        'action': 'github',
        'payload': null,
      };
    }

    // Default guidance
    return {
      'text':
          'Great question, $name! As an aspiring **$role**, consistency is your greatest competitive advantage.\n\nRight now, you have ${ctx['completedTasks']} completed tasks and ${ctx['pendingTasks']} pending tasks. Make sure to solve at least 2 coding problems daily and build full-stack portfolio projects to stand out in placement drives.\n\nFeel free to ask me about:\n• Recommended project ideas for $role\n• How to structure your placement resume\n• Mock technical interview practice\n• What certifications add real value',
      'action': null,
      'payload': null,
    };
  }
}
