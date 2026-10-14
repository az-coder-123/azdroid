import 'package:flutter/material.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';

/// Supported Android logcat severity levels.
enum LogLevel {
  verbose('V', 'Verbose', 2),
  debug('D', 'Debug', 3),
  info('I', 'Info', 4),
  warn('W', 'Warning', 5),
  error('E', 'Error', 6),
  fatal('F', 'Fatal', 7),
  unknown('?', 'Unknown', 0);

  const LogLevel(this.code, this.label, this.priority);

  final String code;
  final String label;
  final int priority;

  /// Parses a log level code character (e.g. 'V', 'D', 'I', 'W', 'E', 'F').
  static LogLevel fromCode(String code) {
    final upper = code.trim().toUpperCase();
    for (final level in LogLevel.values) {
      if (level.code == upper) return level;
    }
    return LogLevel.unknown;
  }

  /// Color associated with this log severity for UI badges and text highlights.
  Color get color {
    switch (this) {
      case LogLevel.verbose:
        return const Color(0xFF9E9E9E); // Muted grey
      case LogLevel.debug:
        return const Color(0xFF64B5F6); // Light blue
      case LogLevel.info:
        return const Color(0xFF81C784); // Fresh green
      case LogLevel.warn:
        return const Color(0xFFFFB74D); // Warm amber
      case LogLevel.error:
        return const Color(0xFFE57373); // Light red
      case LogLevel.fatal:
        return const Color(0xFFF06292); // Vivid pink/red
      case LogLevel.unknown:
        return AppColors.textSecondary;
    }
  }

  /// Subtle background highlight color for log rows.
  Color get rowBackgroundColor {
    switch (this) {
      case LogLevel.error:
        return const Color(0xFFE57373).withValues(alpha: 0.08);
      case LogLevel.fatal:
        return const Color(0xFFF06292).withValues(alpha: 0.16);
      default:
        return Colors.transparent;
    }
  }
}
