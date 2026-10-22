import 'dart:io';

/// Reads an `adb shell` result the way Android actually reports failures.
///
/// `adb shell cmd <service> …` exits with code 0 even when the service has
/// no shell command (`No shell command implementation.`) or does not exist
/// (`Can't find service`): verified on Android 10 and 13 for `clipboard`,
/// `fingerprint`, `biometric`, and `location` on Android 10. Exit code 0
/// alone therefore does not mean the command ran.
extension McpShellResult on ProcessResult {
  static const List<String> _missingCommandMarkers = [
    'No shell command implementation',
    "Can't find service",
    'Unknown command',
  ];

  /// The device has no such shell command or service.
  bool get isMissingCommand {
    // `this.` is required: unqualified, `stdout`/`stderr` resolve to the
    // dart:io console streams (top-level names win over extension members).
    final output = '${this.stdout}\n${this.stderr}';
    return _missingCommandMarkers.any(output.contains);
  }

  /// The command exists on the device and exited normally.
  bool get succeeded => exitCode == 0 && !isMissingCommand;
}
