import '../../models/skill.dart';
import '../../models/project.dart';
import '../../models/task_model.dart';
import '../../models/placement_topic.dart';
import '../../models/interview_question.dart';

class ProgressMetrics {
  final double overallPercentage;
  final double skillsPercentage;
  final double projectsPercentage;
  final double tasksPercentage;
  final double placementPercentage;
  final double codingPercentage;
  final double coreCsPercentage;
  final double aptitudePercentage;
  final double interviewPercentage;

  const ProgressMetrics({
    this.overallPercentage = 0.0,
    this.skillsPercentage = 0.0,
    this.projectsPercentage = 0.0,
    this.tasksPercentage = 0.0,
    this.placementPercentage = 0.0,
    this.codingPercentage = 0.0,
    this.coreCsPercentage = 0.0,
    this.aptitudePercentage = 0.0,
    this.interviewPercentage = 0.0,
  });
}

class ProgressCalculator {
  /// Calculates the overall career preparation progress score (0 to 100%).
  /// Formula:
  /// Equal weighting of the 4 key career pillars:
  /// - Skills Completion: 25%
  /// - Project Portfolio: 25%
  /// - Task Execution: 25%
  /// - Placement Preparation: 25%
  /// If a user has no records in a category, that category contributes 0.0%.
  static ProgressMetrics calculateAll({
    required List<Skill> skills,
    required List<Project> projects,
    required List<TaskModel> tasks,
    required List<PlacementTopic> placementTopics,
    required List<InterviewQuestion> interviewQuestions,
  }) {
    final skillsScore = calculateSkillsProgress(skills);
    final projectsScore = calculateProjectsProgress(projects);
    final tasksScore = calculateTasksProgress(tasks);

    // Placement breakdown
    final codingTopics =
        placementTopics.where((t) => t.track == 'Coding').toList();
    final coreCsTopics =
        placementTopics.where((t) => t.track == 'CoreCS').toList();
    final aptitudeTopics =
        placementTopics.where((t) => t.track == 'Aptitude').toList();

    final codingScore = calculateTopicTrackProgress(codingTopics);
    final coreCsScore = calculateTopicTrackProgress(coreCsTopics);
    final aptitudeScore = calculateTopicTrackProgress(aptitudeTopics);
    final interviewScore = calculateInterviewProgress(interviewQuestions);

    // Placement score is an average of the 4 placement tracks: Coding, Core CS, Aptitude, Interview
    final placementScore =
        (codingScore + coreCsScore + aptitudeScore + interviewScore) / 4.0;

    // Overall career preparation progress
    final overall = (skillsScore * 0.25) +
        (projectsScore * 0.25) +
        (tasksScore * 0.25) +
        (placementScore * 0.25);

    return ProgressMetrics(
      overallPercentage: overall.clamp(0.0, 100.0),
      skillsPercentage: skillsScore.clamp(0.0, 100.0),
      projectsPercentage: projectsScore.clamp(0.0, 100.0),
      tasksPercentage: tasksScore.clamp(0.0, 100.0),
      placementPercentage: placementScore.clamp(0.0, 100.0),
      codingPercentage: codingScore.clamp(0.0, 100.0),
      coreCsPercentage: coreCsScore.clamp(0.0, 100.0),
      aptitudePercentage: aptitudeScore.clamp(0.0, 100.0),
      interviewPercentage: interviewScore.clamp(0.0, 100.0),
    );
  }

  static double calculateSkillsProgress(List<Skill> skills) {
    if (skills.isEmpty) return 0.0;
    final totalProgress =
        skills.fold<double>(0.0, (sum, item) => sum + item.progressPercentage);
    return totalProgress / skills.length;
  }

  static double calculateProjectsProgress(List<Project> projects) {
    if (projects.isEmpty) return 0.0;
    double score = 0.0;
    for (final p in projects) {
      if (p.status == 'Completed') {
        score += 100.0;
      } else if (p.status == 'In Progress') {
        score += 50.0;
      } else if (p.status == 'On Hold') {
        score += 25.0;
      } else {
        // Planned
        score += 10.0;
      }
    }
    return score / projects.length;
  }

  static double calculateTasksProgress(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return (completed / tasks.length) * 100.0;
  }

  static double calculateTopicTrackProgress(List<PlacementTopic> topics) {
    if (topics.isEmpty) return 0.0;
    final total =
        topics.fold<double>(0.0, (sum, t) => sum + t.completionPercentage);
    return total / topics.length;
  }

  static double calculateInterviewProgress(List<InterviewQuestion> questions) {
    if (questions.isEmpty) return 0.0;
    double score = 0.0;
    for (final q in questions) {
      if (q.status == 'Completed') {
        score += 100.0;
      } else if (q.status == 'Needs Revision') {
        score += 75.0;
      } else if (q.status == 'In Progress') {
        score += 50.0;
      }
    }
    return score / questions.length;
  }
}
