import 'package:flutter/material.dart';

/// Design tokens for colors tailored for macOS dark-mode aesthetic.
class AppColors {
  const AppColors._();

  // Primary Accent Colors (Apple System Blue palette)
  static const Color accent = Color(0xFF007AFF);
  static const Color accentHover = Color(0xFF0062CC);
  static const Color accentLight = Color(0xFF409CFF);

  // Surface & Background Colors
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252526);
  static const Color surfaceCard = Color(0xFF2D2D30);
  static const Color surfaceElevated = Color(0xFF333336);

  // Border & Divider Colors
  static const Color border = Color(0xFF3E3E42);
  static const Color borderSubtle = Color(0xFF2E2E32);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);

  // Status & Telemetry Indicators
  static const Color statusSuccess = Color(0xFF34C759); // Green
  static const Color statusWarning = Color(0xFFFF9500); // Orange
  static const Color statusError = Color(0xFFFF3B30);   // Red
  static const Color statusInfo = Color(0xFF5AC8FA);    // Light Blue
}
