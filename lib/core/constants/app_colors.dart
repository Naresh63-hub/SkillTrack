import 'package:flutter/material.dart';

class AppColors {
  // Reference Image Lavender Light Theme Palette (#F5F3FF)
  static const Color mainBackground =
      Color(0xFFF5F3FF); // Clean soft lavender-white
  static const Color cardBackground =
      Color(0xFFFFFFFF); // Pure crisp white cards
  static const Color secondaryCard =
      Color(0xFFEDE9FE); // Soft lavender surface for pills & chips
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDE9FE);

  // Purple Accents (Vibrant violets & purples matching the mockup)
  static const Color primaryPurple =
      Color(0xFF7C3AED); // Vibrant primary purple
  static const Color primaryAccent = Color(0xFF7C3AED);
  static const Color lightPurple = Color(0xFF8B5CF6); // Medium purple
  static const Color secondaryAccent = Color(0xFFA78BFA);
  static const Color gradientHighlight = Color(0xFFC084FC);
  static const Color brightAccent = Color(0xFF6D28D9); // Deep vibrant purple

  // Role-Based Skill Roadmap Dedicated Palette
  static const Color roadmapBackground = Color(0xFFF5F3FF);
  static const Color roadmapCard = Color(0xFFFFFFFF);
  static const Color roadmapSecondaryCard = Color(0xFFEDE9FE);
  static const Color roadmapPrimary = Color(0xFF7C3AED);
  static const Color roadmapSecondaryAccent = Color(0xFF8B5CF6);
  static const Color roadmapText = Color(0xFF1E1B4B);
  static const Color roadmapSecondaryText = Color(0xFF4B5563);

  // Text Colors (High contrast, crisp typography for light theme)
  static const Color primaryText =
      Color(0xFF1E1B4B); // Deep indigo / dark slate
  static const Color secondaryText =
      Color(0xFF4B5563); // Readable slate body text
  static const Color mutedText =
      Color(0xFF6B7280); // Neutral grey for subtitles/hints
  static const Color lightText = Color(0xFF9CA3AF);

  // Borders & Progress
  static const Color border = Color(0xFFE9D5FF); // Elegant soft lavender border
  static const Color borderLight = Color(0xFFF3E8FF);
  static const Color progressTrack =
      Color(0xFFEDE9FE); // Soft lavender-grey track

  // Status Colors (restrained, only when genuinely needed)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF7C3AED);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // Purple Gradients (matching the mockup banners & buttons)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryPurple, brightAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleProgressGradient = LinearGradient(
    colors: [primaryPurple, gradientHighlight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBackground, Color(0xFFFAF5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [brightAccent, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient badgeGradient = LinearGradient(
    colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
