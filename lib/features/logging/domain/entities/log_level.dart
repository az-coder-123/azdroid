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
}
