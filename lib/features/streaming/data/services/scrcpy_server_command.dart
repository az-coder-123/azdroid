/// Builds the `adb shell app_process` command line that starts scrcpy-server.
///
/// Every key/value argument must exist in the bundled server version; the
/// server rejects unknown keys. Verified against scrcpy v3.3.4 `Options.java`.
class ScrcpyServerCommand {
  const ScrcpyServerCommand._();

  /// Java entry point inside scrcpy-server.jar.
  static const String mainClass = 'com.genymobile.scrcpy.Server';

  /// adb arguments (after `adb`) that run the server on [deviceSerial].
  static List<String> adbArguments({
    required String deviceSerial,
    required String remoteJarPath,
    required String serverVersion,
    required String scid,
    required int videoBitRateBps,
    required int maxFps,
  }) => [
    '-s',
    deviceSerial,
    'shell',
    'CLASSPATH=$remoteJarPath',
    'app_process',
    '/',
    mainClass,
    serverVersion,
    'scid=$scid',
    // DeskDroid connects through `adb forward`, so the device listens.
    'tunnel_forward=true',
    'video_bit_rate=$videoBitRateBps',
    'max_fps=$maxFps',
    // Audio playback is not built yet.
    'audio=false',
    // Input travels over the control socket (also lets the server turn the
    // screen on at start: power_on defaults to true).
    'control=true',
    // Clipboard sync stays on the adb path; no unsolicited device messages.
    'clipboard_autosync=false',
    // Leave device settings untouched when the server exits.
    'cleanup=false',
  ];
}
