import 'package:flutter/material.dart';
import 'skill.dart';

/// Represents an individual skill milestone within a career role roadmap.
class RoadmapSkillItem {
  final int order;
  final String name;
  final String category;
  final String proficiencyLevel;
  final String description;
  final String learningResourceUrl;

  const RoadmapSkillItem({
    required this.order,
    required this.name,
    required this.category,
    this.proficiencyLevel = 'Beginner',
    required this.description,
    this.learningResourceUrl = '',
  });

  /// Converts this roadmap item into an application [Skill] model with initial 0% progress.
  Skill toSkill() {
    return Skill(
      name: name,
      category: category,
      proficiencyLevel: proficiencyLevel,
      progressPercentage: 0.0,
      notes: description,
      learningResourceUrl:
          learningResourceUrl.isNotEmpty ? learningResourceUrl : null,
      dateStarted: DateTime.now().toIso8601String().split('T').first,
    );
  }
}

/// Represents a targeted career track with a curated 8-step skill roadmap.
class CareerRoadmap {
  final String id;
  final String roleName;
  final String tagline;
  final String description;
  final IconData icon;
  final List<RoadmapSkillItem> skills;

  const CareerRoadmap({
    required this.id,
    required this.roleName,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.skills,
  });
}

/// Result returned after importing a roadmap into the student's skills repository.
class RoadmapImportResult {
  final String roleName;
  final int totalSkills;
  final int addedCount;
  final int skippedCount;
  final List<String> addedSkillNames;
  final List<String> skippedSkillNames;

  const RoadmapImportResult({
    required this.roleName,
    required this.totalSkills,
    required this.addedCount,
    required this.skippedCount,
    this.addedSkillNames = const [],
    this.skippedSkillNames = const [],
  });

  bool get hasAddedAny => addedCount > 0;
  bool get allWereAlreadyImported => addedCount == 0 && totalSkills > 0;
}
