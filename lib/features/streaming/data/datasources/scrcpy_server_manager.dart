import 'dart:async';
import 'dart:io';

import 'package:desk_droid/core/constants/adb_timeouts.dart';
import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/core/constants/scrcpy_server_constants.dart';
import 'package:desk_droid/core/constants/socket_config.dart';
import 'package:desk_droid/core/services/adb_port_forwarder.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_command.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_jar_locator.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_output.dart';

/// Manages scrcpy-server deployment, persistent daemon execution, and socket tunnels.
class ScrcpyServerManager implements AdbPortForwarder {
  /// Max wait for the scrcpy server ready signal before continuing.
  static const Duration _serverReadyFallback = Duration(milliseconds: 2500);

  /// Settle time for the device LocalServerSocket before forwarding.
  static const Duration _socketSettleDelay = Duration(milliseconds: 200);

  ScrcpyServerManager({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
    ScrcpyServerJarLocator? jarLocator,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor(),
       _jarLocator = jarLocator ?? ScrcpyServerJarLocator();

  final AdbService _adbService;
  final ScrcpyServerJarLocator _jarLocator;
  final ProcessExecutor _executor;
  Process? _daemonProcess;

  /// Remote path of the server jar on the device.
  static const String remoteServerPath = ScrcpyServerConstants.remoteJarPath;

  static const int _bitsPerMegabit = 1000000;

  /// Version of the bundled scrcpy-server.
  static const String serverVersion = ScrcpyServerConstants.version;

  /// Session id of the device socket (`scrcpy_<scid>`).
  static const String scid = ScrcpyServerConstants.scid;

  /// Configures TCP port forwarding via ADB to scrcpy abstract UNIX socket.
  @override
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
      ], timeout: AdbTimeouts.connect);
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
  @override
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
      ], timeout: AdbTimeouts.quickQuery);
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
    final localJarPath = await _jarLocator.locate();
    if (localJarPath != null) {
      try {
        final push = await _executor.run(adb, [
          '-s',
          deviceSerial,
          'push',
          localJarPath,
          remoteServerPath,
        ], timeout: AdbTimeouts.connect);
        if (push.exitCode != 0) {
          // A stale jar may remain on the device; a version mismatch is then
          // reported by the server output check below.
          AppLogger.warning('scrcpy-server.jar push failed: ${push.stderr}');
        }
      } on Exception catch (e) {
        AppLogger.warning('scrcpy-server.jar push failed: $e');
      }
    }

    try {
      _daemonProcess?.kill();
      _daemonProcess = null;

      final serverArgs = ScrcpyServerCommand.adbArguments(
        deviceSerial: deviceSerial,
        remoteJarPath: remoteServerPath,
        serverVersion: serverVersion,
        scid: scid,
        videoBitRateBps: bitrateMbps * _bitsPerMegabit,
        maxFps: maxFps,
      );

      // Completes with true when ready, false on a version mismatch.
      final readyCompleter = Completer<bool>();
      final process = await Process.start(adb, serverArgs);
      _daemonProcess = process;
      process.stdout.listen((data) => _onServerOutput(data, readyCompleter));
      process.stderr.listen((data) => _onServerOutput(data, readyCompleter));

      // Await daemon readiness or the fallback delay.
      final ready = await Future.any([
        readyCompleter.future,
        Future<bool>.delayed(_serverReadyFallback, () => true),
      ]);
      if (!ready) return false;

      // Brief 200ms stabilization window for LocalServerSocket
      await Future<void>.delayed(_socketSettleDelay);

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

  void _onServerOutput(List<int> data, Completer<bool> readyCompleter) {
    final chunk = String.fromCharCodes(data);
    for (final (event, line) in ScrcpyServerOutput.parseChunk(chunk)) {
      switch (event) {
        case ScrcpyServerEvent.ready:
          AppLogger.debug('[scrcpy] $line');
          if (!readyCompleter.isCompleted) readyCompleter.complete(true);
        case ScrcpyServerEvent.versionMismatch:
          AppLogger.error(
            'scrcpy-server on the device is not v$serverVersion: $line',
          );
          if (!readyCompleter.isCompleted) readyCompleter.complete(false);
        case ScrcpyServerEvent.error:
          AppLogger.warning('[scrcpy] $line');
        case ScrcpyServerEvent.other:
          AppLogger.debug('[scrcpy] $line');
      }
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
      ], timeout: AdbTimeouts.quickQuery);
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
    return sendKeyevent(
      deviceSerial: deviceSerial,
      keyCode: AndroidKeyCodes.keycodePower,
    );
  }
}
