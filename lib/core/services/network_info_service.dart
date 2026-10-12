import 'dart:io';

import 'package:wifi_desk/core/services/app_logger.dart';

/// Abstract service providing host machine local network information.
abstract class NetworkInfoService {
  /// Resolves the primary local IPv4 address of the host machine (e.g. Wi-Fi).
  Future<String?> getLocalIpAddress();
}

/// Concrete implementation querying system network interfaces.
class NetworkInfoServiceImpl implements NetworkInfoService {
  @override
  Future<String?> getLocalIpAddress() async {
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
              return addr.address;
            }
          }
        }
      }

      // Fallback to any valid non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
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
    return null;
  }
}
