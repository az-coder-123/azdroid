import 'dart:io';

import 'package:wifi_desk/core/services/process_executor.dart';

/// Represents a raw device entry parsed from `adb devices -l`.
class AdbDevice {
  const AdbDevice({
    required this.serial,
    required this.state,
    this.product,
    this.model,
    this.device,
    this.transportId,
  });

  final String serial;
  final String state;
  final String? product;
  final String? model;
  final String? device;
  final String? transportId;

  bool get isUsb => !serial.contains(':');
  bool get isAuthorized => state == 'device';
  bool get isUnauthorized => state == 'unauthorized';
}

/// Represents an mDNS service entry discovered via `adb mdns services`.
class AdbMdnsService {
  const AdbMdnsService({
    required this.serviceName,
    required this.serviceType,
    required this.ipAddress,
    required this.port,
  });

  final String serviceName;
  final String serviceType;
  final String ipAddress;
  final int port;

  bool get isPairingService => serviceType.contains('_adb-tls-pairing');
  bool get isConnectService =>
      serviceType.contains('_adb-tls-connect') ||
      serviceType.contains('_adb._tcp');
}

/// Result of an ADB command execution.
class AdbCommandResult {
  const AdbCommandResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

/// Service managing ADB interaction, mDNS queries, and device pairing.
class AdbService {
  AdbService({ProcessExecutor? processExecutor, String? explicitAdbPath})
    : _executor = processExecutor ?? const DefaultProcessExecutor(),
      _cachedAdbPath = explicitAdbPath;

  final ProcessExecutor _executor;
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
    } catch (_) {}

    for (final candidate in _knownAdbPaths) {
      try {
        final result = await _executor.run(candidate, [
          'version',
        ], timeout: const Duration(seconds: 2));
        if (result.exitCode == 0) {
          _cachedAdbPath = candidate;
          return candidate;
        }
      } catch (_) {
        // Try next candidate path
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
      return parseDevicesOutput(result.stdout.toString());
    } catch (_) {
      return [];
    }
  }

  /// Parses the stdout text from `adb devices -l`.
  List<AdbDevice> parseDevicesOutput(String stdout) {
    final devices = <AdbDevice>[];
    final lines = stdout.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('List of devices attached')) {
        continue;
      }

      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.length < 2) continue;

      final serial = tokens[0];
      final state = tokens[1];

      String? product;
      String? model;
      String? device;
      String? transportId;

      for (int i = 2; i < tokens.length; i++) {
        final pair = tokens[i];
        if (pair.startsWith('product:')) {
          product = pair.substring(8);
        } else if (pair.startsWith('model:')) {
          model = pair.substring(6).replaceAll('_', ' ');
        } else if (pair.startsWith('device:')) {
          device = pair.substring(7);
        } else if (pair.startsWith('transport_id:')) {
          transportId = pair.substring(13);
        }
      }

      devices.add(
        AdbDevice(
          serial: serial,
          state: state,
          product: product,
          model: model,
          device: device,
          transportId: transportId,
        ),
      );
    }

    return devices;
  }

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
      return parseMdnsServicesOutput(result.stdout.toString());
    } catch (_) {
      return [];
    }
  }

  /// Parses stdout output from `adb mdns services`.
  List<AdbMdnsService> parseMdnsServicesOutput(String stdout) {
    final services = <AdbMdnsService>[];
    final lines = stdout.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('List of discovered mdns services')) {
        continue;
      }

      // Format can be:
      // <name>\t<regType>\t<ip>:<port> OR <name>.<regType> <ip>:<port>
      final tokens = line.split(RegExp(r'\s+'));
      if (tokens.length >= 2) {
        String serviceName = tokens[0];
        String serviceType = '';
        String endpoint = tokens.last;

        if (tokens.length >= 3) {
          serviceType = tokens[1];
          endpoint = tokens[2];
        } else {
          // Tokens: [name._type, endpoint]
          if (serviceName.contains('._adb-tls-connect')) {
            serviceType = '_adb-tls-connect._tcp';
            serviceName = serviceName.split('._adb-tls-connect').first;
          } else if (serviceName.contains('._adb-tls-pairing')) {
            serviceType = '_adb-tls-pairing._tcp';
            serviceName = serviceName.split('._adb-tls-pairing').first;
          } else if (serviceName.contains('._adb.')) {
            serviceType = '_adb._tcp';
            serviceName = serviceName.split('._adb.').first;
          }
        }

        final endpointParts = endpoint.split(':');
        if (endpointParts.length == 2) {
          final ip = endpointParts[0].trim();
          final port = int.tryParse(endpointParts[1].trim());
          if (port != null && ip.isNotEmpty) {
            services.add(
              AdbMdnsService(
                serviceName: serviceName,
                serviceType: serviceType,
                ipAddress: ip,
                port: port,
              ),
            );
          }
        }
      }
    }

    return services;
  }

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
