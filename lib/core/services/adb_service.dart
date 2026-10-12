import 'dart:io';

import 'package:wifi_desk/core/models/adb_command_result.dart';
import 'package:wifi_desk/core/models/adb_device.dart';
import 'package:wifi_desk/core/models/adb_mdns_service.dart';
import 'package:wifi_desk/core/services/adb_output_parser.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

export 'package:wifi_desk/core/models/adb_command_result.dart';
export 'package:wifi_desk/core/models/adb_device.dart';
export 'package:wifi_desk/core/models/adb_mdns_service.dart';
export 'package:wifi_desk/core/services/adb_output_parser.dart';

/// Service managing ADB interaction, mDNS queries, and device pairing.
class AdbService {
  AdbService({
    ProcessExecutor? processExecutor,
    String? explicitAdbPath,
    AdbOutputParser? parser,
  }) : _executor = processExecutor ?? const DefaultProcessExecutor(),
       _cachedAdbPath = explicitAdbPath,
       _parser = parser ?? const AdbOutputParser();

  final ProcessExecutor _executor;
  final AdbOutputParser _parser;
  String? _cachedAdbPath;

  /// Known macOS fallback paths where ADB is frequently installed.
  static final List<String> _knownAdbPaths = [
    'adb',
    '/Users/trannamlong/Library/Android/sdk/platform-tools/adb',
    '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb',
    '/opt/homebrew/bin/adb',
    '/usr/local/bin/adb',
  ];

  /// Locates and caches the active ADB executable path.
  Future<String?> resolveAdbPath() async {
    if (_cachedAdbPath != null) {
      return _cachedAdbPath;
    }

    // Try finding via /usr/bin/which
    try {
      final whichResult = await _executor.run('/usr/bin/which', ['adb']);
      if (whichResult.exitCode == 0 &&
          whichResult.stdout.toString().trim().isNotEmpty) {
        final path = whichResult.stdout.toString().trim();
        _cachedAdbPath = path;
        return path;
      }
    } catch (e) {
      AppLogger.debug('which adb resolution failed: $e');
    }

    for (final candidate in _knownAdbPaths) {
      try {
        final result = await _executor.run(candidate, [
          'version',
        ], timeout: const Duration(seconds: 2));
        if (result.exitCode == 0) {
          _cachedAdbPath = candidate;
          return candidate;
        }
      } catch (e) {
        AppLogger.debug('ADB candidate $candidate check failed: $e');
      }
    }
    return null;
  }

  /// Checks if ADB is installed and reachable.
  Future<bool> isAdbAvailable() async {
    final path = await resolveAdbPath();
    return path != null;
  }

  /// Lists all attached devices via `adb devices -l`.
  Future<List<AdbDevice>> getAttachedDevices() async {
    final adb = await resolveAdbPath();
    if (adb == null) return [];

    try {
      final result = await _executor.run(adb, [
        'devices',
        '-l',
      ], timeout: const Duration(seconds: 5));

      if (result.exitCode != 0) return [];
      return _parser.parseDevices(result.stdout.toString());
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to list attached ADB devices',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Parses stdout output from `adb devices -l`.
  List<AdbDevice> parseDevicesOutput(String stdout) =>
      _parser.parseDevices(stdout);

  /// Lists discovered mDNS services via `adb mdns services`.
  Future<List<AdbMdnsService>> getMdnsServices() async {
    final adb = await resolveAdbPath();
    if (adb == null) return [];

    try {
      final result = await _executor.run(adb, [
        'mdns',
        'services',
      ], timeout: const Duration(seconds: 5));

      if (result.exitCode != 0) return [];
      return _parser.parseMdnsServices(result.stdout.toString());
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to list mDNS services from ADB',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Parses stdout output from `adb mdns services`.
  List<AdbMdnsService> parseMdnsServicesOutput(String stdout) =>
      _parser.parseMdnsServices(stdout);

  /// Connects to a wireless target via `adb connect <ip>:<port>`.
  Future<AdbCommandResult> connect(String ipAddress, int port) async {
    final adb = await resolveAdbPath();
    if (adb == null) {
      return const AdbCommandResult(
        isSuccess: false,
        message: 'ADB binary could not be located on this Mac.',
      );
    }

    try {
      final target = '$ipAddress:$port';
      final result = await _executor.run(adb, [
        'connect',
        target,
      ], timeout: const Duration(seconds: 8));

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      final combined = '$out $err'.trim();

      if (combined.toLowerCase().contains('connected to') ||
          combined.toLowerCase().contains('already connected to')) {
        return AdbCommandResult(
          isSuccess: true,
          message: out.isNotEmpty ? out : 'Connected successfully.',
        );
      }

      return AdbCommandResult(
        isSuccess: false,
        message: combined.isNotEmpty ? combined : 'Connection refused.',
      );
    } catch (e) {
      return AdbCommandResult(
        isSuccess: false,
        message: 'Failed to connect: $e',
      );
    }
  }

  /// Disconnects an active target via `adb disconnect <target>`.
  Future<AdbCommandResult> disconnect(String target) async {
    final adb = await resolveAdbPath();
    if (adb == null) {
      return const AdbCommandResult(
        isSuccess: false,
        message: 'ADB binary could not be located on this Mac.',
      );
    }

    try {
      final result = await _executor.run(adb, [
        'disconnect',
        target,
      ], timeout: const Duration(seconds: 5));

      final out = result.stdout.toString().trim();
      return AdbCommandResult(isSuccess: true, message: out);
    } catch (e) {
      return AdbCommandResult(
        isSuccess: false,
        message: 'Failed to disconnect: $e',
      );
    }
  }

  /// Pairs an Android 11+ device via `adb pair <ip>:<port> <pairingCode>`.
  Future<AdbCommandResult> pair(
    String ipAddress,
    int port,
    String pairingCode,
  ) async {
    final adb = await resolveAdbPath();
    if (adb == null) {
      return const AdbCommandResult(
        isSuccess: false,
        message: 'ADB binary could not be located on this Mac.',
      );
    }

    try {
      final target = '$ipAddress:$port';
      final result = await _executor.run(adb, [
        'pair',
        target,
        pairingCode,
      ], timeout: const Duration(seconds: 10));

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      final combined = '$out $err'.trim();

      if (combined.toLowerCase().contains('successfully paired')) {
        return AdbCommandResult(
          isSuccess: true,
          message: out.isNotEmpty ? out : 'Successfully paired to device.',
        );
      }

      return AdbCommandResult(
        isSuccess: false,
        message: combined.isNotEmpty
            ? combined
            : 'Pairing failed. Check IP, port, and pairing code.',
      );
    } catch (e) {
      return AdbCommandResult(
        isSuccess: false,
        message: 'Pairing exception: $e',
      );
    }
  }
}
