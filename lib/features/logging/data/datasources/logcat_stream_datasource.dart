import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Datasource responsible for managing low-level ADB logcat processes and streaming raw stdout lines.
class LogcatStreamDatasource {
  LogcatStreamDatasource({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;
  Process? _activeProcess;
  StreamController<String>? _activeController;

  /// Spawns `adb -s <serial> logcat -v threadtime` and returns a real-time stream of lines.
  Stream<String> startLogcatStream(String serial) {
    stop();

    final controller = StreamController<String>.broadcast();
    _activeController = controller;

    _launchProcess(serial, controller);

    return controller.stream;
  }

  Future<void> _launchProcess(
    String serial,
    StreamController<String> controller,
  ) async {
    try {
      final adbPath = await _adbService.resolveAdbPath();
      if (adbPath == null) {
        controller.addError(
          Exception('ADB executable not found. Please install platform-tools.'),
        );
        await controller.close();
        return;
      }

      final process = await _executor.start(adbPath, [
        '-s',
        serial,
        'logcat',
        '-v',
        'threadtime',
      ]);
      _activeProcess = process;

      // Handle standard output stream with malformed byte recovery
      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (!controller.isClosed) {
                controller.add(line);
              }
            },
            onError: (Object error, StackTrace stack) {
              AppLogger.warning(
                'Logcat stdout error: $error',
                error: error,
                stackTrace: stack,
              );
            },
            onDone: () {
              AppLogger.info('Logcat stream finished for $serial');
              if (!controller.isClosed) controller.close();
            },
            cancelOnError: false,
          );

      // Handle stderr with malformed byte recovery
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((errLine) {
            AppLogger.debug('[logcat stderr] $errLine');
          });
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to start logcat process for $serial: $e',
        error: e,
        stackTrace: stack,
      );
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  /// Clears the physical ring buffer on the target Android device via `adb logcat -c`.
  Future<void> clearLogcat(String serial) async {
    final adbPath = await _adbService.resolveAdbPath();
    if (adbPath == null) return;

    try {
      await _executor.run(adbPath, ['-s', serial, 'logcat', '-c']);
      AppLogger.info('Cleared device logcat buffer for $serial');
    } catch (e) {
      AppLogger.warning('Failed to clear logcat buffer for $serial: $e');
    }
  }

  /// Terminates the active logcat process if running.
  void stop() {
    if (_activeProcess != null) {
      try {
        _activeProcess!.kill(ProcessSignal.sigkill);
      } catch (e) {
        AppLogger.debug('Error killing logcat process: $e');
      } finally {
        _activeProcess = null;
      }
    }

    if (_activeController != null && !_activeController!.isClosed) {
      _activeController!.close();
      _activeController = null;
    }
  }
}
