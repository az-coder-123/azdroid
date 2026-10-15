import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/productivity/domain/entities/clipboard_item_entity.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/domain/services/clipboard_sync_daemon.dart';

class MockClipboardRepository extends Mock implements ClipboardRepository {}

void main() {
  late MockClipboardRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockClipboardRepository();
  });

  group('ClipboardSyncDaemon Tests', () {
    test('start and stop controls timer execution state', () {
      final daemon = ClipboardSyncDaemon(
        repository: mockRepository,
        deviceSerial: testSerial,
        interval: const Duration(seconds: 1),
      );

      expect(daemon.isRunning, isFalse);
      daemon.start();
      expect(daemon.isRunning, isTrue);
      daemon.stop();
      expect(daemon.isRunning, isFalse);
      daemon.dispose();
    });

    test('tick syncs host to device when host changes', () async {
      when(() => mockRepository.getHostClipboard())
          .thenAnswer((_) async => 'Text from Mac');
      when(() => mockRepository.getDeviceClipboard(testSerial))
          .thenAnswer((_) async => null);
      when(() => mockRepository.setDeviceClipboard(testSerial, 'Text from Mac'))
          .thenAnswer((_) async => true);

      ClipboardItemEntity? syncedItem;
      final daemon = ClipboardSyncDaemon(
        repository: mockRepository,
        deviceSerial: testSerial,
        onSynced: (item) => syncedItem = item,
      );

      await daemon.tick();

      expect(syncedItem, isNotNull);
      expect(syncedItem!.text, 'Text from Mac');
      expect(syncedItem!.source, ClipboardSource.host);
      verify(
        () => mockRepository.setDeviceClipboard(testSerial, 'Text from Mac'),
      ).called(1);

      daemon.dispose();
    });

    test('tick syncs device to host when device changes', () async {
      when(() => mockRepository.getHostClipboard())
          .thenAnswer((_) async => null);
      when(() => mockRepository.getDeviceClipboard(testSerial))
          .thenAnswer((_) async => 'Text from Phone');
      when(() => mockRepository.setHostClipboard('Text from Phone'))
          .thenAnswer((_) async {});

      ClipboardItemEntity? syncedItem;
      final daemon = ClipboardSyncDaemon(
        repository: mockRepository,
        deviceSerial: testSerial,
        onSynced: (item) => syncedItem = item,
      );

      await daemon.tick();

      expect(syncedItem, isNotNull);
      expect(syncedItem!.text, 'Text from Phone');
      expect(syncedItem!.source, ClipboardSource.device);
      verify(() => mockRepository.setHostClipboard('Text from Phone'))
          .called(1);

      daemon.dispose();
    });

    test('prevents echo loops when syncing from host to device', () async {
      // First tick: host has new text
      when(() => mockRepository.getHostClipboard())
          .thenAnswer((_) async => 'Ping Pong Test');
      when(() => mockRepository.getDeviceClipboard(testSerial))
          .thenAnswer((_) async => null);
      when(
        () => mockRepository.setDeviceClipboard(testSerial, 'Ping Pong Test'),
      ).thenAnswer((_) async => true);

      int syncCount = 0;
      final daemon = ClipboardSyncDaemon(
        repository: mockRepository,
        deviceSerial: testSerial,
        onSynced: (_) => syncCount++,
      );

      await daemon.tick();
      expect(syncCount, 1);

      // Second tick: phone now has that same text
      when(() => mockRepository.getHostClipboard())
          .thenAnswer((_) async => 'Ping Pong Test');
      when(() => mockRepository.getDeviceClipboard(testSerial))
          .thenAnswer((_) async => 'Ping Pong Test');

      await daemon.tick();
      // Should NOT echo back to Mac
      expect(syncCount, 1);
      verifyNever(() => mockRepository.setHostClipboard(any()));

      daemon.dispose();
    });

    test(
      'recordHostSync and recordDeviceSync prime cache for manual sync',
      () async {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => 'Manual Text');
        when(() => mockRepository.getDeviceClipboard(testSerial))
            .thenAnswer((_) async => 'Manual Text');

        int syncCount = 0;
        final daemon = ClipboardSyncDaemon(
          repository: mockRepository,
          deviceSerial: testSerial,
          onSynced: (_) => syncCount++,
        );

        daemon.recordHostSync('Manual Text');

        await daemon.tick();
        expect(syncCount, 0);

        daemon.dispose();
      },
    );

    test('handles exceptions and calls onError callback', () async {
      when(() => mockRepository.getHostClipboard())
          .thenThrow(Exception('ADB socket broken'));

      String? errorMessage;
      final daemon = ClipboardSyncDaemon(
        repository: mockRepository,
        deviceSerial: testSerial,
        onError: (err) => errorMessage = err,
      );

      await daemon.tick();
      expect(errorMessage, contains('ADB socket broken'));

      daemon.dispose();
    });
  });
}
