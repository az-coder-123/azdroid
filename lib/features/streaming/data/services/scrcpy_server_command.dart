/// Builds the `adb shell app_process` command line that starts scrcpy-server.
///
/// Every key/value argument must exist in the bundled server version; the
/// server rejects unknown keys. Verified against scrcpy v5.0.1 `Options.java`.
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
    required bool stayAwake,
    required bool audio,
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
    // Raw PCM needs no decoder on the computer (docs/native-audio-contract.md).
    // The default source, `output`, moves the phone's sound to the computer.
    'audio=$audio',
    if (audio) 'audio_codec=raw',
    // Input travels over the control socket (also lets the server turn the
    // screen on at start: power_on defaults to true).
    'control=true',
    // Clipboard sync stays on the adb path; no unsolicited device messages.
    'clipboard_autosync=false',
    // A restore process turns the phone screen back on when the server
    // exits after "Screen Off", even if it is killed. It also deletes the
    // pushed jar; DeskDroid pushes it on every start.
    'cleanup=true',
    // Reports user activity every few seconds, so the screen does not time
    // out, on battery or charging. Unlike `stay_awake`, it changes no device
    // setting, so nothing is left to restore.
    if (stayAwake) 'keep_active=true',
  ];
}
