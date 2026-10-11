import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_theme.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/widgets/pairing_dialog.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;

  setUp(() async {
    await sl.reset();
    mockRepository = MockDeviceDiscoveryRepository();

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
    'PairingDialog renders title, guide steps, and pre-fills device info',
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

      expect(find.text('Pair Wireless Device'), findsOneWidget);
      expect(find.text('Quick Setup Guide:'), findsOneWidget);
      expect(find.text('192.168.1.150'), findsOneWidget);
      expect(find.text('39123'), findsOneWidget);
      expect(find.text('Pair & Connect'), findsOneWidget);
    },
  );

  testWidgets(
    'PairingDialog displays error when invalid pairing code submitted',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());

      // Enter short code
      await tester.enterText(find.byType(TextField).at(0), '192.168.1.100');
      await tester.enterText(find.byType(TextField).at(1), '37123');
      await tester.enterText(find.byType(TextField).at(2), '123'); // < 6 digits

      await tester.tap(find.text('Pair & Connect'));
      await tester.pump();

      expect(
        find.text('Pairing code must be exactly 6 digits.'),
        findsOneWidget,
      );
    },
  );
}
