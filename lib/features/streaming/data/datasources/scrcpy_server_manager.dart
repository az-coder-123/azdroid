import 'package:wifi_desk/core/constants/socket_config.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Manages scrcpy-server deployment, daemon execution, and socket tunnel configuration.
class ScrcpyServerManager {
  ScrcpyServerManager({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  /// Default remote directory path for the server jar.
  static const String remoteServerPath = '/data/local/tmp/scrcpy-server.jar';

  /// Standard scrcpy version descriptor.
  static const String serverVersion = '2.1';

  /// Android Keycode constants for navigation actions.
  static const int keycodeHome = 3;
  static const int keycodeBack = 4;
  static const int keycodePower = 26;
  static const int keycodeAppSwitch = 187;

  /// Configures TCP port forwarding via ADB.
  Future<bool> setupPortForward({
    required String deviceSerial,
    int localPort = SocketConfig.defaultVideoStreamPort,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'forward',
        'tcp:$localPort',
        'localabstract:scrcpy',
      ], timeout: const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Removes an existing TCP port forward.
  Future<bool> removePortForward({
    required String deviceSerial,
    int localPort = SocketConfig.defaultVideoStreamPort,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'forward',
        '--remove',
        'tcp:$localPort',
      ], timeout: const Duration(seconds: 3));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Launches the scrcpy-server daemon on the target Android device.
  Future<bool> startServerDaemon({
    required String deviceSerial,
    int port = SocketConfig.defaultVideoStreamPort,
    int maxFps = 60,
    int bitrateMbps = 8,
    bool stayAwake = true,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    // First setup port forward
    await setupPortForward(deviceSerial: deviceSerial, localPort: port);

    try {
      final bitrateBps = bitrateMbps * 1000000;
      final serverArgs = [
        '-s',
        deviceSerial,
        'shell',
        'CLASSPATH=$remoteServerPath',
        'app_process',
        '/',
        'com.genymobile.scrcpy.Server',
        serverVersion,
        'tunnel_forward=true',
        'video_bit_rate=$bitrateBps',
        'max_fps=$maxFps',
        'stay_awake=$stayAwake',
        'control=true',
        'cleanup=true',
      ];

      // Launch process with timeout protection
      final result = await _executor.run(
        adb,
        serverArgs,
        timeout: const Duration(seconds: 3),
      );

      // Even if command times out or is in background, port forward is ready
      return result.exitCode == 0 || result.exitCode == -1;
    } catch (_) {
      return false;
    }
  }

  /// Injects an Android keyevent via ADB shell.
  Future<bool> sendKeyevent({
    required String deviceSerial,
    required int keyCode,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'input',
        'keyevent',
        keyCode.toString(),
      ], timeout: const Duration(seconds: 3));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Toggles physical screen display state.
  Future<bool> setScreenPower({
    required String deviceSerial,
    required bool powerOff,
  }) async {
    if (powerOff) {
      // Send power key to turn screen off
      return sendKeyevent(deviceSerial: deviceSerial, keyCode: keycodePower);
    } else {
      // Wake up device screen
      return sendKeyevent(deviceSerial: deviceSerial, keyCode: keycodePower);
    }
  }
}
