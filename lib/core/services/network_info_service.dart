import 'dart:io';

import 'package:desk_droid/core/services/app_logger.dart';

/// Abstract service providing host machine local network information.
abstract class NetworkInfoService {
  /// Resolves the primary local IPv4 address of the host machine (e.g. Wi-Fi).
  Future<String?> getLocalIpAddress({bool forceRefresh = false});
}

/// Concrete implementation querying system network interfaces with in-memory caching.
class NetworkInfoServiceImpl implements NetworkInfoService {
  String? _cachedIp;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(seconds: 30);

  @override
  Future<String?> getLocalIpAddress({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIp != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedIp;
    }

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Prioritize en0 (standard macOS Wi-Fi interface)
      for (final interface in interfaces) {
        if (interface.name == 'en0') {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && !addr.address.startsWith('127.')) {
              _cachedIp = addr.address;
              _lastFetchTime = DateTime.now();
              return addr.address;
            }
          }
        }
      }

      // Fallback to any valid non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
            _cachedIp = addr.address;
            _lastFetchTime = DateTime.now();
            return addr.address;
          }
        }
      }
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to list network interfaces for host IP',
        error: e,
        stackTrace: stack,
      );
    }
    return _cachedIp;
  }
}
