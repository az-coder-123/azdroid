import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Dedicated service responsible for switching USB-connected Android devices to wireless TCP/IP mode.
class AdbTcpipService {
  AdbTcpipService({AdbService? adbService, ProcessExecutor? processExecutor})
    : _adbService = adbService ?? AdbService(),
      _executor = processExecutor ?? const DefaultProcessExecutor();

  final AdbService _adbService;
  final ProcessExecutor _executor;

  /// Retrieves the device's internal Wi-Fi IPv4 address while attached via USB.
  Future<String?> getDeviceWifiIp(String serial) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) return null;

    // Strategy 1: Check wlan0 inet interface address
    try {
      final result = await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        'ip',
        '-f',
        'inet',
        'addr',
        'show',
        'wlan0',
      ], timeout: const Duration(seconds: 4));

      final output = result.stdout.toString();
      final match = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)').firstMatch(output);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    } catch (e) {
      AppLogger.debug('wlan0 IP query failed for $serial: $e');
    }

    // Strategy 2: Fallback to ip route table source IP
    try {
      final result = await _executor.run(adb, [
        '-s',
        serial,
        'shell',
        'ip',
        'route',
      ], timeout: const Duration(seconds: 4));

      final output = result.stdout.toString();
      final match = RegExp(r'src\s+(\d+\.\d+\.\d+\.\d+)').firstMatch(output);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    } catch (e) {
      AppLogger.debug('ip route query failed for $serial: $e');
    }

    return null;
  }

  /// Switches device to TCP mode using `adb -s <serial> tcpip <port>`.
  Future<AdbCommandResult> enableTcpip(String serial, {int port = 5555}) async {
    final adb = await _adbService.resolveAdbPath();
    if (adb == null) {
      return const AdbCommandResult(
        isSuccess: false,
        message: 'ADB binary could not be located on this Mac.',
      );
    }

    try {
      final result = await _executor.run(adb, [
        '-s',
        serial,
        'tcpip',
        port.toString(),
      ], timeout: const Duration(seconds: 8));

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      final combined = '$out $err'.trim();

      if (combined.toLowerCase().contains('restarting in tcp mode') ||
          result.exitCode == 0) {
        return AdbCommandResult(
          isSuccess: true,
          message: out.isNotEmpty
              ? out
              : 'Restarted in TCP mode on port $port.',
        );
      }

      return AdbCommandResult(
        isSuccess: false,
        message: combined.isNotEmpty
            ? combined
            : 'Failed to switch to TCP mode.',
      );
    } catch (e) {
      return AdbCommandResult(
        isSuccess: false,
        message: 'Failed to switch to TCP mode: $e',
      );
    }
  }

  /// Complete 1-click pipeline: Queries Wi-Fi IP, enables TCP mode, and connects.
  Future<AdbCommandResult> switchUsbToWifi(
    String serial, {
    int port = 5555,
  }) async {
    // 1. Resolve phone's Wi-Fi IP while still on USB
    final wifiIp = await getDeviceWifiIp(serial);

    // 2. Enable TCP/IP on phone
    final tcpResult = await enableTcpip(serial, port: port);
    if (!tcpResult.isSuccess) {
      return tcpResult;
    }

    // Small delay to allow adbd to restart in TCP mode
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // 3. If Wi-Fi IP was identified, connect immediately!
    if (wifiIp != null && wifiIp.isNotEmpty) {
      final connectResult = await _adbService.connect(wifiIp, port);
      if (connectResult.isSuccess) {
        return AdbCommandResult(
          isSuccess: true,
          message:
              'Connected wirelessly to $wifiIp:$port! You can now safely unplug the USB cable.',
        );
      }
    }

    return AdbCommandResult(
      isSuccess: true,
      message:
          'TCP mode enabled on port $port. ${wifiIp != null ? "Connect manually to $wifiIp:$port." : "Connect to your phone Wi-Fi IP."}',
    );
  }
}
