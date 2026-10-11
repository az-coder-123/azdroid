import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/main.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;

  setUp(() async {
    await sl.reset();
    mockRepository = MockDeviceDiscoveryRepository();
    when(() => mockRepository.discoverDevices()).thenAnswer((_) async => []);

    sl.registerLazySingleton<DeviceDiscoveryRepository>(() => mockRepository);
    sl.registerFactory<DiscoveryCubit>(
      () => DiscoveryCubit(repository: sl<DeviceDiscoveryRepository>()),
    );
    sl.registerFactory<PairingCubit>(
      () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'WifiDeskApp renders DiscoveryPage with title, empty state and actions',
    (WidgetTester tester) async {
      await tester.pumpWidget(const WifiDeskApp());

      // Initially loading
      expect(find.text('WifiDesk'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Wait for discoverDevices to resolve
      await tester.pump();

      expect(find.text('No Devices Discovered'), findsOneWidget);
      expect(find.text('Scan for Devices'), findsOneWidget);
      expect(find.text('Pair Device'), findsOneWidget);
      expect(find.text('Direct IP'), findsOneWidget);

      // Clean up timers by unmounting widget
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('WifiDeskApp renders device cards when devices are discovered', (
    WidgetTester tester,
  ) async {
    const testDevice = DeviceEntity(
      id: '192.168.1.100:5555',
      name: 'Google Pixel 8 Pro',
      ipAddress: '192.168.1.100',
      port: 5555,
      connectionType: DeviceConnectionType.wireless,
      requiresPairing: true,
      pairingPort: 37123,
    );

    when(() => mockRepository.discoverDevices())
        .thenAnswer((_) async => [testDevice]);

    await tester.pumpWidget(const WifiDeskApp());
    await tester.pump();

    expect(find.text('Discovered Devices (1)'), findsOneWidget);
    expect(find.text('Google Pixel 8 Pro'), findsOneWidget);
    expect(find.text('Pair Device'), findsWidgets);

    // Clean up timers by unmounting widget
    await tester.pumpWidget(const SizedBox());
  });
}
