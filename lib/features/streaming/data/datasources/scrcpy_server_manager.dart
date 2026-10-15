import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Manages scrcpy-server deployment, persistent daemon execution, and socket tunnels.
class ScrcpyServerManager {
  ScrcpyServerManager({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;
  Process? _daemonProcess;

  /// Default remote directory path for the server jar.
  static const String remoteServerPath = '/data/local/tmp/scrcpy-server.jar';

  /// Standard scrcpy version descriptor.
  static const String serverVersion = '2.1';

  /// Distinct scrcpy session ID for abstract socket identification.
  static const String scid = '00000000';

  /// Android Keycode constants for navigation actions.
  static const int keycodeHome = 3;
  static const int keycodeBack = 4;
  static const int keycodePower = 26;
  static const int keycodeAppSwitch = 187;

  /// Resolves the absolute path of scrcpy-server.jar across desktop dev and release bundles.
  Future<String?> _resolveLocalJarPath() async {
    final direct = File('assets/scrcpy-server.jar');
    if (await direct.exists()) return direct.path;

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final bundleJar = File(
      '$exeDir/../Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/scrcpy-server.jar',
    );
    if (await bundleJar.exists()) return bundleJar.path;

    try {
      final byteData = await rootBundle.load('assets/scrcpy-server.jar');
      final tempFile = File('${Directory.systemTemp.path}/scrcpy-server.jar');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return tempFile.path;
    } catch (e) {
      AppLogger.debug('Failed to extract jar from rootBundle: $e');
    }
    return null;
  }

  /// Configures TCP port forwarding via ADB to scrcpy abstract UNIX socket.
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
        'localabstract:scrcpy_$scid',
      ], timeout: const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to setup port forward for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
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
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to remove port forward for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Launches the scrcpy-server persistent daemon on the target Android device.
  Future<bool> startServerDaemon({
    required String deviceSerial,
    int port = SocketConfig.defaultVideoStreamPort,
    int maxFps = 60,
    int bitrateMbps = 8,
    bool stayAwake = true,
  }) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    // Ensure remote scrcpy-server.jar is pushed and available
    final localJarPath = await _resolveLocalJarPath();
    if (localJarPath != null) {
      try {
        await _executor.run(adb, [
          '-s',
          deviceSerial,
          'push',
          localJarPath,
          remoteServerPath,
        ], timeout: const Duration(seconds: 5));
      } catch (e) {
        AppLogger.debug('scrcpy-server.jar push skipped: $e');
      }
    }

    try {
      _daemonProcess?.kill();
      _daemonProcess = null;

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
        'scid=$scid',
        'tunnel_forward=true',
        'video_bit_rate=$bitrateBps',
        'max_fps=$maxFps',
        'audio=false',
        'control=false',
        'cleanup=false',
      ];

      final readyCompleter = Completer<void>();

      _daemonProcess = await Process.start(adb, serverArgs);
      _daemonProcess?.stdout.listen((data) {
        final text = String.fromCharCodes(data).trim();
        AppLogger.debug('[scrcpy] $text');
        if (text.contains('[server] INFO: Device') &&
            !readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
      });
      _daemonProcess?.stderr.listen((data) {
        AppLogger.debug('[scrcpy err] ${String.fromCharCodes(data).trim()}');
      });

      // Await daemon readiness or 2.5s fallback
      await Future.any([
        readyCompleter.future,
        Future<void>.delayed(const Duration(milliseconds: 2500)),
      ]);

      // Brief 200ms stabilization window for LocalServerSocket
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Setup port forward once server socket is listening
      await setupPortForward(deviceSerial: deviceSerial, localPort: port);
      return true;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to start scrcpy server daemon on $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Terminates daemon process and cleans up forwarded socket tunnel.
  Future<void> stopServerDaemon({
    required String deviceSerial,
    int port = SocketConfig.defaultVideoStreamPort,
  }) async {
    try {
      _daemonProcess?.kill();
      _daemonProcess = null;
    } catch (e) {
      AppLogger.debug('Error stopping scrcpy daemon process: $e');
    }
    await removePortForward(deviceSerial: deviceSerial, localPort: port);
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
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to send keyevent $keyCode to $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Toggles physical screen display state.
  Future<bool> setScreenPower({
    required String deviceSerial,
    required bool powerOff,
  }) async {
    return sendKeyevent(deviceSerial: deviceSerial, keyCode: keycodePower);
  }
}
