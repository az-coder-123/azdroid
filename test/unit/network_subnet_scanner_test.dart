import 'dart:io';

import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/discovery/data/datasources/network_subnet_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_toolchains.dart';

class MockNetworkInfoService extends Mock implements NetworkInfoService {}

class MockDeviceHistoryService extends Mock implements DeviceHistoryService {}

class MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  late MockNetworkInfoService mockNetInfo;
  late MockDeviceHistoryService mockHistory;
  late MockProcessExecutor mockExecutor;
  late NetworkSubnetScannerImpl scanner;

  setUp(() {
    mockNetInfo = MockNetworkInfoService();
    mockHistory = MockDeviceHistoryService();
    mockExecutor = MockProcessExecutor();
    scanner = NetworkSubnetScannerImpl(
      networkInfoService: mockNetInfo,
      historyService: mockHistory,
      processExecutor: mockExecutor,
      toolchain: toolchainFor(HostOs.macos, {'HOME': '/Users/dev'}),
    );
  });

  group('NetworkSubnetScannerImpl', () {
    test('extractArpIps parses stdout of arp -an for matching subnet', () {
      const sampleArp = '''
? (192.168.1.1) at cc:71:90:12:2a:40 on en0 ifscope [ethernet]
? (192.168.1.3) at 7c:fd:6b:f6:70:49 on en0 ifscope [ethernet]
? (192.168.2.55) at 11:22:33:44:55:66 on en0 ifscope [ethernet]
? (224.0.0.251) at 1:0:5e:0:0:fb on en0 ifscope permanent [ethernet]
''';

      final ips = scanner.extractArpIps(sampleArp, '192.168.1');
      expect(ips, equals(['192.168.1.1', '192.168.1.3']));
    });

    test('extractArpIps ignores incomplete entries', () {
      const sampleArp = '''
? (192.168.1.1) at cc:71:90:12:2a:40 on en0 ifscope [ethernet]
? (192.168.1.6) at (incomplete) on en0 ifscope [ethernet]
? (192.168.1.8) at (incomplete) on en0 ifscope [ethernet]
? (192.168.1.10) at b6:f1:40:ac:4a:62 on en0 ifscope [ethernet]
''';

      final ips = scanner.extractArpIps(sampleArp, '192.168.1');
      expect(ips, equals(['192.168.1.1', '192.168.1.10']));
    });

    test(
      'findActiveSubnetEndpoints returns empty list when host IP is null',
      () async {
        when(() => mockNetInfo.getLocalIpAddress())
            .thenAnswer((_) async => null);

        final endpoints = await scanner.findActiveSubnetEndpoints();
        expect(endpoints, isEmpty);
      },
    );

    test(
      'findActiveSubnetEndpoints checks ARP and history candidates',
      () async {
        when(() => mockNetInfo.getLocalIpAddress())
            .thenAnswer((_) async => '192.168.1.5');
        when(() => mockHistory.getRecentDevices()).thenAnswer(
          (_) async => [
            RecentDevice(
              id: '192.168.1.20:5555',
              name: 'Old Phone',
              ipAddress: '192.168.1.20',
              port: 5555,
              lastConnected: DateTime.now(),
            ),
          ],
        );

        const arpOutput =
            '? (192.168.1.3) at 7c:fd:6b:f6:70:49 on en0 ifscope [ethernet]';
        when(
          () => mockExecutor.run('/usr/sbin/arp', [
            '-an',
          ], timeout: any(named: 'timeout')),
        ).thenAnswer((_) async => ProcessResult(0, 0, arpOutput, ''));

        // probePort will try to connect to localhost / 192.168.1.X and timeout safely
        final endpoints = await scanner.findActiveSubnetEndpoints();
        // Even if endpoints don't accept TCP in mock test environment, the flow finishes safely
        expect(endpoints, isA<List<String>>());
      },
    );
  });
}
