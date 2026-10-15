import 'package:flutter/services.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/process_executor.dart';

/// Abstract datasource for host macOS pasteboard and Android device clipboard interactions.
abstract class ClipboardDatasource {
  /// Reads host system clipboard text.
  Future<String?> readHostClipboard();

  /// Writes text to host system clipboard.
  Future<void> writeHostClipboard(String text);

  /// Reads Android device clipboard text via ADB.
  Future<String?> readDeviceClipboard(String deviceSerial);

  /// Writes text to Android device clipboard via ADB.
  Future<bool> writeDeviceClipboard(String deviceSerial, String text);
}

/// Concrete implementation of [ClipboardDatasource].
class ClipboardDatasourceImpl implements ClipboardDatasource {
  ClipboardDatasourceImpl({
    AdbService? adbService,
    ProcessExecutor? processExecutor,
  }) : _adbService = adbService ?? AdbService(),
       _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  @override
  Future<String?> readHostClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to read host clipboard',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<void> writeHostClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to write host clipboard',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<String?> readDeviceClipboard(String deviceSerial) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return null;

    try {
      // 1. Try Android cmd clipboard
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'cmd',
        'clipboard',
        'get',
      ], timeout: const Duration(seconds: 3));

      if (result.exitCode == 0) {
        final text = result.stdout.toString().trim();
        if (text.isNotEmpty &&
            !text.contains('No shell command implementation') &&
            !text.startsWith('Error:')) {
          return text;
        }
      }

      // 2. Fallback: Try Clipper broadcast get
      final clipperResult = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'am',
        'broadcast',
        '-a',
        'clipper.get',
      ], timeout: const Duration(seconds: 3));

      if (clipperResult.exitCode == 0) {
        final out = clipperResult.stdout.toString();
        final match = RegExp(r'data="([^"]*)"').firstMatch(out);
        if (match != null && match.group(1) != null) {
          final text = match.group(1)!.trim();
          return text.isNotEmpty ? text : null;
        }
      }

      return null;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to read device clipboard for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<bool> writeDeviceClipboard(String deviceSerial, String text) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      // 1. Try Android cmd clipboard
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'cmd',
        'clipboard',
        'set',
        text,
      ], timeout: const Duration(seconds: 3));

      if (result.exitCode == 0 &&
          !result.stdout.toString().contains(
            'No shell command implementation',
          ) &&
          !result.stderr.toString().contains('Error')) {
        return true;
      }

      // 2. Fallback: Try Clipper broadcast set
      final clipperResult = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'am',
        'broadcast',
        '-a',
        'clipper.set',
        '--es',
        'text',
        text,
      ], timeout: const Duration(seconds: 3));

      return clipperResult.exitCode == 0;
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to write device clipboard for $deviceSerial',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
