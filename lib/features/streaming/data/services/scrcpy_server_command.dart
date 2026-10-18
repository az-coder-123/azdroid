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
    // Video only: input uses `adb shell input`; audio playback is not built.
    'audio=false',
    'control=false',
    // Leave device settings untouched when the server exits.
    'cleanup=false',
  ];
}
