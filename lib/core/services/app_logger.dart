import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralized, structured application logger adhering to AGENTS.md error handling standards.
class AppLogger {
  const AppLogger._();

  /// Append-only diagnostic log file used for post-mortem debugging.
  static const String logFilePath = '/tmp/deskdroid_dart.log';

  /// Logger name used when the diagnostic log file itself cannot be written.
  static const String _fileSinkTag = 'DeskDroid.LogFile';

  static void _logToFile(String line) {
    try {
      File(logFilePath).writeAsStringSync(
        '${DateTime.now().toIso8601String()} $line\n',
        mode: FileMode.append,
        flush: true,
      );
    } on FileSystemException catch (error) {
      // Report through the VM log only, to avoid recursing into the file sink.
      developer.log(
        'Failed to write diagnostic log file',
        name: _fileSinkTag,
        level: 900,
        error: error,
      );
    }
  }

  /// Logs informational system messages.
  static void info(String message, {String tag = 'DeskDroid'}) {
    developer.log(message, name: tag, level: 800);
    debugPrint('[$tag] $message');
    _logToFile('INFO [$tag] $message');
  }

  /// Logs debug messages during development.
  static void debug(String message, {String tag = 'DeskDroid'}) {
    if (kDebugMode) {
      developer.log(message, name: tag, level: 500);
      debugPrint('[$tag] $message');
      _logToFile('DEBUG [$tag] $message');
    }
  }

  /// Logs warnings and recoverable failures with optional error and stack trace.
  static void warning(
    String message, {
    String tag = 'DeskDroid',
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
    debugPrint('[$tag] WARNING: $message ${error ?? ""}');
    _logToFile('WARN [$tag] $message ${error ?? ""}');
  }

  /// Logs critical errors and boundary exceptions with required error details.
  static void error(
    String message, {
    String tag = 'DeskDroid',
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
    debugPrint('[$tag] ERROR: $message ${error ?? ""}');
    _logToFile('ERROR [$tag] $message ${error ?? ""}');
  }
}
