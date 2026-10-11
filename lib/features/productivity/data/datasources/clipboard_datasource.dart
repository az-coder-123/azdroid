import 'package:flutter/services.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

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
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeHostClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      // Ignored
    }
  }

  @override
  Future<String?> readDeviceClipboard(String deviceSerial) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return null;

    try {
      // Android 10+ standard command service
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
        return text.isNotEmpty ? text : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> writeDeviceClipboard(String deviceSerial, String text) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return false;

    try {
      // Set clipboard on Android via cmd clipboard set or input text fallback
      final result = await _executor.run(adb, [
        '-s',
        deviceSerial,
        'shell',
        'cmd',
        'clipboard',
        'set',
        text,
      ], timeout: const Duration(seconds: 3));

      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
