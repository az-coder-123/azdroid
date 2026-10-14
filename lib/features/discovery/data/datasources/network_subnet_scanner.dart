import 'dart:async';
import 'dart:io';

import 'package:wifi_desk/core/services/app_logger.dart';
import 'package:wifi_desk/core/services/device_history_service.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Contract for scanning local Wi-Fi subnet and ARP cache to discover active Android endpoints.
abstract class NetworkSubnetScanner {
  /// Scans for active Android ADB endpoints (port 5555) on the local Wi-Fi network.
  Future<List<String>> findActiveSubnetEndpoints({
    int port = 5555,
    bool fullSubnetSweep = false,
  });
}

/// Production implementation leveraging macOS ARP cache, recent device history,
/// and fast parallel asynchronous TCP port probing.
class NetworkSubnetScannerImpl implements NetworkSubnetScanner {
  const NetworkSubnetScannerImpl({
    this.networkInfoService,
    this.historyService,
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
  }) : _executor = processExecutor;

  final NetworkInfoService? networkInfoService;
  final DeviceHistoryService? historyService;
  final ProcessExecutor _executor;

  @override
  Future<List<String>> findActiveSubnetEndpoints({
    int port = 5555,
    bool fullSubnetSweep = false,
  }) async {
    final hostIp = await networkInfoService?.getLocalIpAddress();
    if (hostIp == null || hostIp.isEmpty) return const [];

    final parts = hostIp.split('.');
    if (parts.length != 4) return const [];
    final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    final discoveredIps = <String>{};

    // Stage 1: Fast ARP Table & Recent History Probing (~100-300ms)
    final priorityIps = await _collectPriorityIps(subnetPrefix, hostIp);
    if (priorityIps.isNotEmpty) {
      final active = await _probeIpsInParallel(priorityIps, port);
      discoveredIps.addAll(active);
    }

    // Stage 2: Deep Subnet Sweep (if no priority endpoints responded, or full sweep explicitly requested)
    if (discoveredIps.isEmpty || fullSubnetSweep) {
      final allSubnetIps = <String>[];
      for (var i = 1; i <= 254; i++) {
        final candidate = '$subnetPrefix.$i';
        if (candidate != hostIp && !priorityIps.contains(candidate)) {
          allSubnetIps.add(candidate);
        }
      }
      final active = await _probeIpsInBatches(
        allSubnetIps,
        port,
        batchSize: 32,
      );
      discoveredIps.addAll(active);
    }

    return discoveredIps.toList();
  }

  /// Gathers candidate IPs from macOS ARP cache and recently connected device history.
  Future<Set<String>> _collectPriorityIps(
    String subnetPrefix,
    String hostIp,
  ) async {
    final candidates = <String>{};

    // 1. Query ARP cache via /usr/sbin/arp -an
    try {
      final res = await _executor.run('/usr/sbin/arp', [
        '-an',
      ], timeout: const Duration(seconds: 2));
      if (res.exitCode == 0) {
        final arpIps = extractArpIps(res.stdout.toString(), subnetPrefix);
        candidates.addAll(arpIps);
      }
    } catch (e) {
      AppLogger.debug('ARP lookup failed: $e');
    }

    // 2. Query recent devices history
    try {
      if (historyService != null) {
        final recents = await historyService!.getRecentDevices();
        for (final r in recents) {
          if (r.ipAddress.startsWith('$subnetPrefix.')) {
            candidates.add(r.ipAddress);
          }
        }
      }
    } catch (e) {
      AppLogger.debug('Recent devices lookup failed: $e');
    }

    candidates.remove(hostIp);
    return candidates;
  }

  /// Parses stdout of `arp -an` for IP addresses matching the specified subnet.
  List<String> extractArpIps(String arpOutput, String subnetPrefix) {
    final ips = <String>[];
    final regex = RegExp(r'\(([\d\.]+)\)');
    for (final line in arpOutput.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final ip = match.group(1)!;
        if (ip.startsWith('$subnetPrefix.') &&
            !ip.endsWith('.255') &&
            !ip.endsWith('.0')) {
          ips.add(ip);
        }
      }
    }
    return ips;
  }

  /// Probes a list of IPs concurrently with a short non-blocking TCP socket timeout.
  Future<List<String>> _probeIpsInParallel(
    Iterable<String> ips,
    int port,
  ) async {
    final results = <String>[];
    await Future.wait(
      ips.map((ip) async {
        final isOpen = await probePort(ip, port);
        if (isOpen) {
          results.add(ip);
        }
      }),
    );
    return results;
  }

  /// Probes a larger list of IPs in controlled batches to avoid socket exhaustion.
  Future<List<String>> _probeIpsInBatches(
    List<String> ips,
    int port, {
    int batchSize = 32,
  }) async {
    final results = <String>[];
    for (var i = 0; i < ips.length; i += batchSize) {
      final end = (i + batchSize < ips.length) ? i + batchSize : ips.length;
      final batch = ips.sublist(i, end);
      final active = await _probeIpsInParallel(batch, port);
      results.addAll(active);
      if (results.isNotEmpty) {
        // Early stop if an active device was detected on small networks
        break;
      }
    }
    return results;
  }

  /// Tests if TCP [port] on [ip] is open and listening.
  Future<bool> probePort(
    String ip,
    int port, {
    Duration timeout = const Duration(milliseconds: 250),
  }) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
