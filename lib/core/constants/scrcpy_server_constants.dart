/// Facts about the bundled scrcpy-server, in pure Dart (no Flutter), so the
/// app, tests, and command-line tools share one source of truth.
///
/// `test/unit/scrcpy_server_version_test.dart` checks [version] against the
/// jar itself. Upgrade steps: docs/scrcpy-upgrade-assessment.md.
class ScrcpyServerConstants {
  const ScrcpyServerConstants._();

  /// Version of `assets/scrcpy-server.jar`. Sent as the first server
  /// argument; the server exits when it differs from its own version.
  static const String version = '5.0.1';

  /// Flutter asset key (and project-relative path) of the bundled jar.
  static const String assetKey = 'assets/scrcpy-server.jar';

  /// Where the jar is pushed on the device before starting the server.
  static const String remoteJarPath = '/data/local/tmp/scrcpy-server.jar';

  /// Session id; the device socket is `localabstract:scrcpy_<scid>`.
  static const String scid = '00000000';

  /// Java class of the restore process that `cleanup=true` starts. It turns
  /// the phone screen back on (after "Screen Off") when the server exits.
  static const String cleanupMainClass = 'com.genymobile.scrcpy.CleanUp';
}
