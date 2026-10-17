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
  static const Color statusError = Color(0xFFFF3B30); // Red
  static const Color statusInfo = Color(0xFF5AC8FA); // Light Blue

  // Mirroring viewport backdrop behind the device frame
  static const Color viewportBackdrop = Color(0xFF0D0E12);

  // Logcat severity palette
  static const Color logVerbose = Color(0xFF9E9E9E);
  static const Color logDebug = Color(0xFF64B5F6);
  static const Color logInfo = Color(0xFF81C784);
  static const Color logWarn = Color(0xFFFFB74D);
  static const Color logError = Color(0xFFE57373);
  static const Color logFatal = Color(0xFFF06292);

  // Remote file type palette
  static const Color fileImage = Color(0xFFC084FC);
  static const Color fileVideo = Color(0xFF60A5FA);
  static const Color fileAudio = Color(0xFFFBBF24);
  static const Color fileApk = Color(0xFF4ADE80);
}
