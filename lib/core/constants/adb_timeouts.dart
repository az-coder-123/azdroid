/// Timeout tiers for ADB host commands.
///
/// Pick the tier that matches the expected cost of the command rather than
/// adding a new literal. Wireless links add latency, so tiers are generous.
class AdbTimeouts {
  const AdbTimeouts._();

  /// Single-value shell reads (`getprop`, clipboard, `wm size`).
  static const Duration quickQuery = Duration(seconds: 3);

  /// Short shell actions (`input`, `am broadcast`, `ls`, `tcpip` probes).
  static const Duration shellCommand = Duration(seconds: 4);

  /// Connection setup (`connect`, `forward`, `devices -l`, `am start`).
  static const Duration connect = Duration(seconds: 5);

  /// Slower commands that may scan or wait on the device (`pair`, `ls -la`).
  static const Duration slowCommand = Duration(seconds: 8);

  /// Device-wide operations such as `disconnect` or `uninstall`.
  static const Duration deviceOperation = Duration(seconds: 10);

  /// Package queries that may wake the package manager.
  static const Duration packageOperation = Duration(seconds: 15);
}
