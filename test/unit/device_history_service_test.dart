import 'dart:io';

import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String historyFilePath;
  late DeviceHistoryServiceImpl historyService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('deskdroid_test_');
    historyFilePath = '${tempDir.path}/history.json';
    historyService = DeviceHistoryServiceImpl(customFilePath: historyFilePath);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DeviceHistoryServiceImpl', () {
    test('returns empty list when history file does not exist', () async {
      final devices = await historyService.getRecentDevices();
      expect(devices, isEmpty);
    });

    test('saves and retrieves recent devices ordered by most recent', () async {
      final now = DateTime.now();
      final dev1 = RecentDevice(
        id: '192.168.1.50:5555',
        name: 'Pixel 7',
        ipAddress: '192.168.1.50',
        port: 5555,
        lastConnected: now.subtract(const Duration(hours: 1)),
      );
      final dev2 = RecentDevice(
        id: '192.168.1.60:5555',
        name: 'Xiaomi 13',
        ipAddress: '192.168.1.60',
        port: 5555,
        lastConnected: now,
      );

      await historyService.saveRecentDevice(dev1);
      await historyService.saveRecentDevice(dev2);

      final devices = await historyService.getRecentDevices();
      expect(devices.length, equals(2));
      // dev2 was connected later, so it appears first
      expect(devices.first.id, equals(dev2.id));
      expect(devices.last.id, equals(dev1.id));
    });

    test('removes device by id from history', () async {
      final dev = RecentDevice(
        id: '192.168.1.100:5555',
        name: 'Samsung S23',
        ipAddress: '192.168.1.100',
        port: 5555,
        lastConnected: DateTime.now(),
      );

      await historyService.saveRecentDevice(dev);
      expect(await historyService.getRecentDevices(), hasLength(1));

      await historyService.removeRecentDevice('192.168.1.100:5555');
      expect(await historyService.getRecentDevices(), isEmpty);
    });
  });
}
