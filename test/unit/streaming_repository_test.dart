import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:wifi_desk/features/streaming/data/datasources/streaming_socket_datasource.dart';
import 'package:wifi_desk/features/streaming/data/repositories/streaming_repository_impl.dart';

class MockScrcpyServerManager extends Mock implements ScrcpyServerManager {}

class MockStreamingSocketDatasource extends Mock
    implements StreamingSocketDatasource {}

void main() {
  late MockScrcpyServerManager mockServerManager;
  late MockStreamingSocketDatasource mockSocketDatasource;
  late StreamingRepositoryImpl repository;

  setUp(() {
    mockServerManager = MockScrcpyServerManager();
    mockSocketDatasource = MockStreamingSocketDatasource();
    repository = StreamingRepositoryImpl(
      serverManager: mockServerManager,
      socketDatasource: mockSocketDatasource,
    );
  });

  group('StreamingRepositoryImpl', () {
    const testDevice = DeviceEntity(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8 Pro',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
    );

    test(
      'startSession starts server daemon, connects socket, and returns session',
      () async {
        when(
          () => mockServerManager.startServerDaemon(
            deviceSerial: any(named: 'deviceSerial'),
            port: any(named: 'port'),
            maxFps: any(named: 'maxFps'),
            bitrateMbps: any(named: 'bitrateMbps'),
          ),
        ).thenAnswer((_) async => true);

        when(() => mockSocketDatasource.connect(port: any(named: 'port')))
            .thenAnswer((_) async => true);

        final session = await repository.startSession(testDevice);

        expect(session.deviceId, equals(testDevice.id));
        expect(session.deviceName, equals(testDevice.name));
        expect(session.fps, equals(60));
        expect(session.bitrateMbps, equals(8));

        verify(
          () => mockServerManager.startServerDaemon(
            deviceSerial: testDevice.id,
            maxFps: 60,
            bitrateMbps: 8,
          ),
        ).called(1);
      },
    );

    test('stopSession disconnects socket and removes port forward', () async {
      when(
        () => mockServerManager.startServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
          port: any(named: 'port'),
          maxFps: any(named: 'maxFps'),
          bitrateMbps: any(named: 'bitrateMbps'),
        ),
      ).thenAnswer((_) async => true);

      when(() => mockSocketDatasource.connect(port: any(named: 'port')))
          .thenAnswer((_) async => true);

      when(() => mockSocketDatasource.disconnect()).thenAnswer((_) async {});
      when(
        () => mockServerManager.removePortForward(
          deviceSerial: any(named: 'deviceSerial'),
        ),
      ).thenAnswer((_) async => true);

      final session = await repository.startSession(testDevice);
      await repository.stopSession(session.sessionId);

      verify(() => mockSocketDatasource.disconnect()).called(1);
      verify(
        () => mockServerManager.removePortForward(deviceSerial: testDevice.id),
      ).called(1);
    });

    test('sendNavigationKey forwards keyevent to server manager', () async {
      when(
        () => mockServerManager.startServerDaemon(
          deviceSerial: any(named: 'deviceSerial'),
          port: any(named: 'port'),
          maxFps: any(named: 'maxFps'),
          bitrateMbps: any(named: 'bitrateMbps'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockSocketDatasource.connect(port: any(named: 'port')))
          .thenAnswer((_) async => true);
      when(
        () => mockServerManager.sendKeyevent(
          deviceSerial: any(named: 'deviceSerial'),
          keyCode: any(named: 'keyCode'),
        ),
      ).thenAnswer((_) async => true);

      final session = await repository.startSession(testDevice);
      await repository.sendNavigationKey(session.sessionId, 4);

      verify(
        () => mockServerManager.sendKeyevent(
          deviceSerial: testDevice.id,
          keyCode: 4,
        ),
      ).called(1);
    });
  });
}
