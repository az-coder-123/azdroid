import 'package:desk_droid/core/constants/adb_timeouts.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Abstract datasource contract for injecting native input events into an Android device.
abstract class ControlDatasource {
  /// Injects a single tap at the given pixel coordinates.
  Future<bool> injectTap(String deviceSerial, int x, int y);

  /// Injects a swipe gesture from start coordinates to end coordinates with a given duration in milliseconds.
  Future<bool> injectSwipe(
    String deviceSerial,
    int startX,
    int startY,
    int endX,
    int endY,
    int durationMs,
  );

  /// Injects an Android physical keyevent by its integer keycode.
  Future<bool> injectKeyevent(String deviceSerial, int keyCode);

  /// Injects raw text or international characters into the active input focus.
  Future<bool> injectText(String deviceSerial, String text);
}

/// Concrete implementation of [ControlDatasource] leveraging ADB shell commands.
class ControlDatasourceImpl implements ControlDatasource {
  ControlDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  @override
  Future<bool> injectTap(String deviceSerial, int x, int y) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'input',
        'tap',
        x.toString(),
        y.toString(),
      ], timeout: AdbTimeouts.quickQuery);
      return result.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to inject tap at ($x, $y) for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> injectSwipe(
    String deviceSerial,
    int startX,
    int startY,
    int endX,
    int endY,
    int durationMs,
  ) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'input',
        'swipe',
        startX.toString(),
        startY.toString(),
        endX.toString(),
        endY.toString(),
        durationMs.toString(),
      ], timeout: AdbTimeouts.shellCommand);
      return result.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to inject swipe for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> injectKeyevent(String deviceSerial, int keyCode) async {
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
        'Failed to inject keyevent $keyCode for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<bool> injectText(String deviceSerial, String text) async {
    if (text.isEmpty) return true;

    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      // Escape shell arguments:
      // Replace spaces with %s which android `input text` expects.
      final formattedText = _sanitizeTextForAdb(text);
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'input',
        'text',
        formattedText,
      ], timeout: AdbTimeouts.shellCommand);
      return result.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to inject text for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Sanitizes text for ADB shell `input text`.
  /// Escapes spaces and characters with special shell meaning.
  String _sanitizeTextForAdb(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == ' ') {
        sb.write('%s');
      } else if (char == '\n') {
        sb.write('%s'); // or can trigger Enter keyevent
      } else if (char == r'$' ||
          char == r'`' ||
          char == r'"' ||
          char == r'\' ||
          char == r'&' ||
          char == r';' ||
          char == r'<' ||
          char == r'>' ||
          char == r'(' ||
          char == r')' ||
          char == r'|') {
        sb.write(r'\');
        sb.write(char);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }
}
