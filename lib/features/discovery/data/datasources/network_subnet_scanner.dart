import 'dart:async';
import 'dart:io';

import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/discovery/data/parsers/arp_table_parser.dart';

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
  /// Upper bound for reading the local ARP cache.
  static const Duration _arpTimeout = Duration(seconds: 2);

  /// Per-host TCP connect timeout during subnet sweeps.
  static const Duration _portProbeTimeout = Duration(milliseconds: 400);

  NetworkSubnetScannerImpl({
    this.networkInfoService,
    this.historyService,
    ProcessExecutor processExecutor = const DefaultProcessExecutor(),
    HostToolchain? toolchain,
    this._arpParser = const ArpTableParser(),
  }) : _executor = processExecutor,
       _toolchain = toolchain ?? HostToolchain.current();

  final NetworkInfoService? networkInfoService;
  final DeviceHistoryService? historyService;
  final ProcessExecutor _executor;
  final HostToolchain _toolchain;
  final ArpTableParser _arpParser;

  @override
  Future<List<String>> findActiveSubnetEndpoints({
    int port = 5555,
    bool fullSubnetSweep = true,
  }) async {
    final hostIp = await networkInfoService?.getLocalIpAddress();
    if (hostIp == null || hostIp.isEmpty) return const [];

    final parts = hostIp.split('.');
    if (parts.length != 4) return const [];
    final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    final discoveredEndpoints = <String>{};

    // Stage 1: Fast ARP Table & Recent History Probing (~100-300ms)
    final priorityIps = await _collectPriorityIps(subnetPrefix, hostIp);
    if (priorityIps.isNotEmpty) {
      final active = await _probePriorityIps(priorityIps, port);
      discoveredEndpoints.addAll(active);
    }

    // Stage 2: Deep Subnet Sweep across all 254 IPs (finds all remaining devices)
    if (fullSubnetSweep) {
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
        batchSize: 48,
      );
      discoveredEndpoints.addAll(active);
    }

    return discoveredEndpoints.toList();
  }

  /// Gathers candidate IPs from the host ARP cache and recently connected device history.
  Future<Set<String>> _collectPriorityIps(
    String subnetPrefix,
    String hostIp,
  ) async {
    final candidates = <String>{};

    // 1. Query the OS ARP cache
    try {
      final res = await _executor.run(
        _toolchain.arpCommand,
        _toolchain.arpArguments,
        timeout: _arpTimeout,
      );
      if (res.exitCode == 0) {
        final arpIps = extractArpIps(res.stdout.toString(), subnetPrefix);
        candidates.addAll(arpIps);
      }
    } on Exception catch (e) {
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

  /// Parses ARP output for IPs in [subnetPrefix]; see [ArpTableParser].
  List<String> extractArpIps(String arpOutput, String subnetPrefix) =>
      _arpParser.parse(arpOutput, subnetPrefix);

  /// Probes priority IPs on default [port] and alternative ADB ports (5554, 5556).
  Future<List<String>> _probePriorityIps(
    Iterable<String> ips,
    int primaryPort,
  ) async {
    final results = <String>[];
    await Future.wait(
      ips.map((ip) async {
        if (await probePort(ip, primaryPort)) {
          results.add(ip);
          return;
        }
        // Probe secondary ADB TCP ports if primary 5555 closed
        for (final altPort in [5554, 5556, 5558]) {
          if (await probePort(ip, altPort)) {
            results.add('$ip:$altPort');
            return;
          }
        }
      }),
    );
    return results;
  }

  /// Probes a list of IPs concurrently with a non-blocking TCP socket timeout.
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
  /// Scans the entire list without premature breaks so all devices are discovered.
  Future<List<String>> _probeIpsInBatches(
    List<String> ips,
    int port, {
    int batchSize = 48,
  }) async {
    final results = <String>[];
    for (var i = 0; i < ips.length; i += batchSize) {
      final end = (i + batchSize < ips.length) ? i + batchSize : ips.length;
      final batch = ips.sublist(i, end);
      final active = await _probeIpsInParallel(batch, port);
      results.addAll(active);
    }
    return results;
  }

  /// Tests if TCP [port] on [ip] is open and listening.
  Future<bool> probePort(
    String ip,
    int port, {
    Duration timeout = _portProbeTimeout,
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
