import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette according to specification
  static const Color mainBackground = Color(0xFF10091F);
  static const Color secondaryBackground = Color(0xFF170D35);
  static const Color cardBackground = Color(0xFF21133F);
  static const Color elevatedSurface = Color(0xFF2E1065);

  // Accents
  static const Color primaryAccent = Color(0xFF8B5CF6);
  static const Color brightAccent = Color(0xFFA855F7);
  static const Color secondaryAccent = Color(0xFFA78BFA);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFD4CBEA);
  static const Color mutedText = Color(0xFFA69ABD);

  // Surface & Borders
  static const Color border = Color(0xFF37255D);
  static const Color borderLight = Color(0xFF4C337E);
  static const Color surfaceVariant = Color(0xFF1F143B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF3B82F6);

  // Gradient definitions for subtle accents
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryAccent, brightAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF231445), Color(0xFF1A0E38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient elevatedGradient = LinearGradient(
    colors: [Color(0xFF34156F), Color(0xFF240D50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
