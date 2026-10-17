import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/logging/domain/entities/log_level.dart';
import 'package:flutter/material.dart';

/// Presentation colors for [LogLevel], kept out of the domain entity.
extension LogLevelColors on LogLevel {
  /// Foreground color for badges and highlighted text.
  Color get color => switch (this) {
    LogLevel.verbose => AppColors.logVerbose,
    LogLevel.debug => AppColors.logDebug,
    LogLevel.info => AppColors.logInfo,
    LogLevel.warn => AppColors.logWarn,
    LogLevel.error => AppColors.logError,
    LogLevel.fatal => AppColors.logFatal,
    LogLevel.unknown => AppColors.textSecondary,
  };

  /// Subtle row tint that makes errors stand out in the console.
  Color get rowBackgroundColor => switch (this) {
    LogLevel.error => AppColors.logError.withValues(alpha: 0.08),
    LogLevel.fatal => AppColors.logFatal.withValues(alpha: 0.16),
    _ => Colors.transparent,
  };
}
