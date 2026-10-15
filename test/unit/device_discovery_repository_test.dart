import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:desk_droid/features/discovery/data/models/device_model.dart';
import 'package:desk_droid/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:desk_droid/features/discovery/domain/entities/device_entity.dart';

class MockDeviceDiscoveryDatasource extends Mock
    implements DeviceDiscoveryDatasource {}

void main() {
  late MockDeviceDiscoveryDatasource mockDatasource;
  late DeviceDiscoveryRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockDeviceDiscoveryDatasource();
    repository = DeviceDiscoveryRepositoryImpl(datasource: mockDatasource);
  });

  group('DeviceDiscoveryRepositoryImpl', () {
    const testModel = DeviceModel(
      id: '192.168.1.100:5555',
      name: 'Pixel 8',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
    );

    test(
      'discoverDevices delegates to datasource and returns entities',
      () async {
        when(() => mockDatasource.scanDevices())
            .thenAnswer((_) async => [testModel]);

        final result = await repository.discoverDevices();

        expect(result, equals([testModel]));
        verify(() => mockDatasource.scanDevices()).called(1);
      },
    );

    test('connectDevice calls datasource.connect', () async {
      when(() => mockDatasource.connect('192.168.1.100', 5555))
          .thenAnswer((_) async => true);

      final result = await repository.connectDevice(testModel);

      expect(result, isTrue);
      verify(() => mockDatasource.connect('192.168.1.100', 5555)).called(1);
    });

    test('pairDevice calls datasource.pair', () async {
      when(() => mockDatasource.pair('192.168.1.100', 37123, '123456'))
          .thenAnswer((_) async => true);

      final result = await repository.pairDevice(
        ipAddress: '192.168.1.100',
        port: 37123,
        pairingCode: '123456',
      );

      expect(result, isTrue);
      verify(() => mockDatasource.pair('192.168.1.100', 37123, '123456'))
          .called(1);
    });

    test(
      'manualConnect calls datasource.connect with explicit credentials',
      () async {
        when(() => mockDatasource.connect('10.0.0.5', 5555))
            .thenAnswer((_) async => true);

        final result = await repository.manualConnect(
          ipAddress: '10.0.0.5',
          port: 5555,
        );

        expect(result, isTrue);
        verify(() => mockDatasource.connect('10.0.0.5', 5555)).called(1);
      },
    );

    test('switchUsbToWifi delegates to datasource.switchUsbToWifi', () async {
      when(() => mockDatasource.switchUsbToWifi('serial123', port: 5555))
          .thenAnswer((_) async => true);

      final result = await repository.switchUsbToWifi('serial123', port: 5555);

      expect(result, isTrue);
      verify(() => mockDatasource.switchUsbToWifi('serial123', port: 5555))
          .called(1);
    });
  });
}
