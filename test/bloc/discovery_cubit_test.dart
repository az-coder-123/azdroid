import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_state.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;
  late DiscoveryCubit discoveryCubit;

  setUp(() {
    mockRepository = MockDeviceDiscoveryRepository();
    discoveryCubit = DiscoveryCubit(repository: mockRepository);
  });

  tearDown(() {
    discoveryCubit.close();
  });

  group('DiscoveryCubit', () {
    const testDevice = DeviceEntity(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
    );

    test('initial state should be DiscoveryInitial', () {
      expect(discoveryCubit.state, equals(const DiscoveryInitial()));
    });

    blocTest<DiscoveryCubit, DiscoveryState>(
      'emits [DiscoveryLoading, DiscoveryLoaded] when scanDevices succeeds',
      build: () {
        when(() => mockRepository.discoverDevices())
            .thenAnswer((_) async => [testDevice]);
        return discoveryCubit;
      },
      act: (cubit) => cubit.scanDevices(),
      expect: () => [
        const DiscoveryLoading(),
        const DiscoveryLoaded(devices: [testDevice]),
      ],
      verify: (_) {
        verify(() => mockRepository.discoverDevices()).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'emits [DiscoveryLoading, DiscoveryError] when scanDevices throws an exception',
      build: () {
        when(() => mockRepository.discoverDevices())
            .thenThrow(Exception('Scan failed'));
        return discoveryCubit;
      },
      act: (cubit) => cubit.scanDevices(),
      expect: () => [
        const DiscoveryLoading(),
        const DiscoveryError(
          message: 'Failed to scan for devices: Exception: Scan failed',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.discoverDevices()).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'connects to device and refreshes device list on success',
      build: () {
        when(() => mockRepository.connectDevice(testDevice))
            .thenAnswer((_) async => true);
        when(() => mockRepository.discoverDevices())
            .thenAnswer((_) async => [testDevice.copyWith(isConnected: true)]);
        return discoveryCubit;
      },
      act: (cubit) => cubit.connect(testDevice),
      expect: () => [
        const DiscoveryLoading(),
        DiscoveryLoaded(devices: [testDevice.copyWith(isConnected: true)]),
      ],
      verify: (_) {
        verify(() => mockRepository.connectDevice(testDevice)).called(1);
        verify(() => mockRepository.discoverDevices()).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'manualConnect succeeds and refreshes list',
      build: () {
        when(
          () => mockRepository.manualConnect(
            ipAddress: '192.168.1.50',
            port: 5555,
          ),
        ).thenAnswer((_) async => true);
        when(() => mockRepository.discoverDevices())
            .thenAnswer((_) async => [testDevice]);
        return discoveryCubit;
      },
      act: (cubit) =>
          cubit.manualConnect(ipAddress: '192.168.1.50', port: 5555),
      expect: () => [
        const DiscoveryLoading(),
        const DiscoveryLoaded(devices: [testDevice]),
      ],
      verify: (_) {
        verify(
          () => mockRepository.manualConnect(
            ipAddress: '192.168.1.50',
            port: 5555,
          ),
        ).called(1);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'manualConnect emits DiscoveryError when connect fails',
      build: () {
        when(
          () => mockRepository.manualConnect(
            ipAddress: '192.168.1.50',
            port: 5555,
          ),
        ).thenAnswer((_) async => false);
        return discoveryCubit;
      },
      act: (cubit) =>
          cubit.manualConnect(ipAddress: '192.168.1.50', port: 5555),
      expect: () => [
        const DiscoveryLoading(),
        const DiscoveryError(
          message: 'Failed to connect to 192.168.1.50:5555. Ensure Wireless Debugging is on.',
        ),
      ],
    );

    test(
      'switchUsbToWifi delegates to repository and returns result',
      () async {
        const usbDev = DeviceEntity(
          id: 'usb123',
          name: 'USB Phone',
          ipAddress: '127.0.0.1',
          port: 5555,
          connectionType: DeviceConnectionType.usb,
        );

        when(() => mockRepository.switchUsbToWifi('usb123', port: 5555))
            .thenAnswer((_) async => true);
        when(() => mockRepository.discoverDevices())
            .thenAnswer((_) async => []);

        final result = await discoveryCubit.switchUsbToWifi(usbDev);
        expect(result, isTrue);
        verify(() => mockRepository.switchUsbToWifi('usb123', port: 5555))
            .called(1);
      },
    );
  });
}
