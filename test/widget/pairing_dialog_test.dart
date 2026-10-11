import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/theme/app_theme.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing_dialog.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

class MockNetworkInfoService extends Mock implements NetworkInfoService {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;
  late MockNetworkInfoService mockNetworkInfoService;

  setUp(() async {
    await sl.reset();
    mockRepository = MockDeviceDiscoveryRepository();
    mockNetworkInfoService = MockNetworkInfoService();

    when(() => mockNetworkInfoService.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.1.12');

    sl.registerLazySingleton<NetworkInfoService>(() => mockNetworkInfoService);
    sl.registerLazySingleton<DeviceDiscoveryRepository>(() => mockRepository);
    sl.registerFactory<PairingCubit>(
      () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createSubject({DeviceEntity? device}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: PairingDialog(initialDevice: device)),
    );
  }

  testWidgets(
    'PairingDialog renders title, QR code tab by default, and switches to manual PIN tab',
    (WidgetTester tester) async {
      const testDevice = DeviceEntity(
        id: '192.168.1.150:5555',
        name: 'Pixel 8',
        ipAddress: '192.168.1.150',
        port: 5555,
        connectionType: DeviceConnectionType.wireless,
        requiresPairing: true,
        pairingPort: 39123,
      );

      await tester.pumpWidget(createSubject(device: testDevice));
      await tester.pumpAndSettle();

      // Header and Host IP banner
      expect(find.text('Pair Wireless Device'), findsOneWidget);
      expect(find.text('Mac Wi-Fi IP: 192.168.1.12'), findsOneWidget);

      // Default tab: QR Code
      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('How to pair using QR code:'), findsOneWidget);

      // Switch to Manual PIN tab
      await tester.tap(find.text('Manual 6-Digit PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Manual PIN Entry Guide:'), findsOneWidget);
      expect(find.text('192.168.1.150'), findsOneWidget);
      expect(find.text('39123'), findsOneWidget);
      expect(find.text('Pair & Connect'), findsOneWidget);
    },
  );

  testWidgets(
    'PairingDialog displays error when invalid pairing code submitted in manual tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Switch to Manual tab first
      await tester.tap(find.text('Manual 6-Digit PIN'));
      await tester.pumpAndSettle();

      // Enter short code
      await tester.enterText(find.byType(TextField).at(0), '192.168.1.100');
      await tester.enterText(find.byType(TextField).at(1), '37123');
      await tester.enterText(find.byType(TextField).at(2), '123'); // < 6 digits

      await tester.ensureVisible(find.text('Pair & Connect'));
      await tester.tap(find.text('Pair & Connect'));
      await tester.pump();

      expect(
        find.text('Pairing code must be exactly 6 digits.'),
        findsOneWidget,
      );
    },
  );
}
