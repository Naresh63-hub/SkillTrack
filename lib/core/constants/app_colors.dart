import 'package:flutter/material.dart';

class AppColors {
  // Required Premium Dark Purple Palette
  static const Color mainBackground = Color(0xFF100B16);
  static const Color cardBackground = Color(0xFF1C1722);
  static const Color secondaryCard = Color(0xFF261B32);
  static const Color secondaryBackground = Color(0xFF1C1722);
  static const Color elevatedSurface = Color(0xFF261B32);
  static const Color surfaceVariant = Color(0xFF261B32);

  // Purple Accents
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color primaryAccent = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFA78BFA);
  static const Color secondaryAccent = Color(0xFFA78BFA);
  static const Color gradientHighlight = Color(0xFFC084FC);
  static const Color brightAccent = Color(0xFFC084FC);

  // Role-Based Skill Roadmap Dedicated Palette
  static const Color roadmapBackground = Color(0xFF100B16);
  static const Color roadmapCard = Color(0xFF1C1722);
  static const Color roadmapSecondaryCard = Color(0xFF261B32);
  static const Color roadmapPrimary = Color(0xFF8B5CF6);
  static const Color roadmapSecondaryAccent = Color(0xFFA78BFA);
  static const Color roadmapText = Color(0xFFFFFFFF);
  static const Color roadmapSecondaryText = Color(0xFFB8B3C2);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB8B3C2);
  static const Color mutedText = Color(0xFF82798D);

  // Borders & Progress
  static const Color border = Color(0xFF493653);
  static const Color borderLight = Color(0xFF493653);
  static const Color progressTrack = Color(0xFF302B35);

  // Status Colors (restrained, only when genuinely needed)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFFA78BFA);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFFA78BFA);

  // Purple Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryPurple, gradientHighlight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleProgressGradient = LinearGradient(
    colors: [primaryPurple, gradientHighlight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [secondaryCard, cardBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [Color(0xFF2D1E3D), Color(0xFF1C1722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF261B32), Color(0xFF100B16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient badgeGradient = LinearGradient(
    colors: [Color(0xFF38234B), Color(0xFF261B32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
