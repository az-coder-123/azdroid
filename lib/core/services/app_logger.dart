import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized, structured application logger adhering to AGENTS.md error handling standards.
class AppLogger {
  const AppLogger._();

  /// Logs informational system messages.
  static void info(String message, {String tag = 'WifiDesk'}) {
    developer.log(message, name: tag, level: 800);
  }

  /// Logs debug messages during development.
  static void debug(String message, {String tag = 'WifiDesk'}) {
    if (kDebugMode) {
      developer.log(message, name: tag, level: 500);
    }
  }

  /// Logs warnings and recoverable failures with optional error and stack trace.
  static void warning(
    String message, {
    String tag = 'WifiDesk',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs critical errors and boundary exceptions with required error details.
  static void error(
    String message, {
    String tag = 'WifiDesk',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
