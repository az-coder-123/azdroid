import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/di/modules/platform_di.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_cubit.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/updater/domain/repositories/update_repository.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:desk_droid/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/mcp_status_fixtures.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

class MockNetworkInfoService extends Mock implements NetworkInfoService {}

class MockDeviceHistoryService extends Mock implements DeviceHistoryService {}

class MockMcpStatusRepository extends Mock implements McpStatusRepository {}

class MockUpdateRepository extends Mock implements UpdateRepository {}

class MockHostFileLauncher extends Mock implements HostFileLauncher {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;
  late MockNetworkInfoService mockNetworkInfoService;

  setUp(() async {
    await sl.reset();
    registerPlatformDependencies(sl, os: HostOs.macos);
    mockRepository = MockDeviceDiscoveryRepository();
    mockNetworkInfoService = MockNetworkInfoService();
    when(() => mockRepository.discoverDevices()).thenAnswer((_) async => []);
    when(() => mockNetworkInfoService.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.1.12');

    sl.registerLazySingleton<NetworkInfoService>(() => mockNetworkInfoService);
    sl.registerLazySingleton<DeviceDiscoveryRepository>(() => mockRepository);
    sl.registerFactory<DiscoveryCubit>(
      () => DiscoveryCubit(repository: sl<DeviceDiscoveryRepository>()),
    );
    sl.registerFactory<PairingCubit>(
      () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
    );
    final mockHistoryService = MockDeviceHistoryService();
    when(() => mockHistoryService.getRecentDevices())
        .thenAnswer((_) async => []);
    sl.registerFactory<HostContextCubit>(
      () => HostContextCubit(
        networkInfoService: mockNetworkInfoService,
        historyService: mockHistoryService,
      ),
    );
    sl.registerLazySingleton<MenuBarCubit>(MenuBarCubit.new);
    final mcpRepository = MockMcpStatusRepository();
    when(mcpRepository.load).thenAnswer((_) async => mcpStatus());
    sl.registerFactory<McpStatusCubit>(
      () => McpStatusCubit(repository: mcpRepository),
    );
    final mockUpdateRepo = MockUpdateRepository();
    when(
      () => mockUpdateRepo.checkForUpdate(
        currentVersionRaw: any(named: 'currentVersionRaw'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => null);
    sl.registerFactory<UpdaterCubit>(
      () => UpdaterCubit(
        updateRepository: mockUpdateRepo,
        fileLauncher: MockHostFileLauncher(),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'AzdroidApp renders DiscoveryPage with title, empty state and actions',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AzdroidApp());

      // Initially loading
      expect(find.text('Azdroid'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Wait for discoverDevices to resolve
      await tester.pump();

      expect(find.text('No Devices Discovered'), findsOneWidget);
      expect(find.text('Scan for Devices'), findsOneWidget);
      expect(find.text('Pair with Wi-Fi Code'), findsOneWidget);
      expect(find.text('Pair Device'), findsOneWidget);
      expect(find.text('Direct IP'), findsOneWidget);

      // Clean up timers by unmounting widget
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('AzdroidApp renders device cards when devices are discovered', (
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

    await tester.pumpWidget(const AzdroidApp());
    await tester.pump();

    expect(find.text('Discovered Devices (1)'), findsOneWidget);
    expect(find.text('Google Pixel 8 Pro'), findsOneWidget);
    expect(find.text('Pair Device'), findsWidgets);

    // Clean up timers by unmounting widget
    await tester.pumpWidget(const SizedBox());
  });
}
