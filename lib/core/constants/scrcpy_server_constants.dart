/// Facts about the bundled scrcpy-server, in pure Dart (no Flutter), so the
/// app, tests, and command-line tools share one source of truth.
///
/// `test/unit/scrcpy_server_version_test.dart` checks [version] against the
/// jar itself. Upgrade steps: docs/scrcpy-upgrade-assessment.md.
class ScrcpyServerConstants {
  const ScrcpyServerConstants._();

  /// Version of `assets/scrcpy-server.jar`. Sent as the first server
  /// argument; the server exits when it differs from its own version.
  static const String version = '3.3.4';

  /// Flutter asset key (and project-relative path) of the bundled jar.
  static const String assetKey = 'assets/scrcpy-server.jar';

  /// Where the jar is pushed on the device before starting the server.
  static const String remoteJarPath = '/data/local/tmp/scrcpy-server.jar';

  /// Session id; the device socket is `localabstract:scrcpy_<scid>`.
  static const String scid = '00000000';

  /// Java class of the restore process that `cleanup=true` starts. It
  /// restores the settings changed for "stay awake" when the server exits.
  static const String cleanupMainClass = 'com.genymobile.scrcpy.CleanUp';

  /// Screen-off timeout set while "stay awake" is on: 24 hours, in ms.
  ///
  /// Long enough to keep the phone awake on battery for any session, yet
  /// finite: if the restore never runs (the phone reboots mid-session), the
  /// phone still sleeps eventually.
  static const int stayAwakeScreenOffTimeoutMs = 24 * 60 * 60 * 1000;
}
