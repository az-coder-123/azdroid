import 'dart:developer' as developer;
import 'dart:io';

import 'package:desk_droid/core/platform/host_paths.dart';

/// Centralized, structured application logger adhering to AGENTS.md error handling standards.
class AppLogger {
  const AppLogger._();

  static const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');

  /// Append-only diagnostic log file used for post-mortem debugging.
  static final String logFilePath = SystemHostPaths().diagnosticLogFile;

  /// Logger name used when the diagnostic log file itself cannot be written.
  static const String _fileSinkTag = 'Azdroid.LogFile';

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

  static void _writeStderr(String line) {
    try {
      stderr.writeln(line);
    } catch (_) {
      // Fallback if stderr is closed.
    }
  }

  /// Logs informational system messages.
  static void info(String message, {String tag = 'Azdroid'}) {
    developer.log(message, name: tag, level: 800);
    _writeStderr('[$tag] $message');
    _logToFile('INFO [$tag] $message');
  }

  /// Logs debug messages during development.
  static void debug(String message, {String tag = 'Azdroid'}) {
    if (_kDebugMode) {
      developer.log(message, name: tag, level: 500);
      _writeStderr('[$tag] $message');
      _logToFile('DEBUG [$tag] $message');
    }
  }

  /// Logs warnings and recoverable failures with optional error and stack trace.
  static void warning(
    String message, {
    String tag = 'Azdroid',
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
    _writeStderr('[$tag] WARNING: $message ${error ?? ""}');
    _logToFile('WARN [$tag] $message ${error ?? ""}');
  }

  /// Logs critical errors and boundary exceptions with required error details.
  static void error(
    String message, {
    String tag = 'Azdroid',
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
    _writeStderr('[$tag] ERROR: $message ${error ?? ""}');
    _logToFile('ERROR [$tag] $message ${error ?? ""}');
  }
}
