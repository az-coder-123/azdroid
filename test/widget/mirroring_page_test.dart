import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_theme.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:wifi_desk/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/pages/mirroring_page.dart';

class MockStreamingRepository extends Mock implements StreamingRepository {}

void main() {
  late MockStreamingRepository mockRepository;

  const testDevice = DeviceEntity(
    id: '192.168.1.100:5555',
    name: 'Google Pixel 8',
    ipAddress: '192.168.1.100',
    port: 5555,
    connectionType: DeviceConnectionType.wireless,
  );

  const testSession = StreamSessionEntity(
    sessionId: 'session_123',
    deviceId: '192.168.1.100:5555',
    deviceName: 'Google Pixel 8',
    width: 1080,
    height: 2400,
    fps: 60,
    bitrateMbps: 8,
    latencyMs: 18,
  );

  setUp(() async {
    await sl.reset();
    mockRepository = MockStreamingRepository();

    when(() => mockRepository.startSession(testDevice))
        .thenAnswer((_) async => testSession);
    when(() => mockRepository.stopSession(any())).thenAnswer((_) async {});
    when(() => mockRepository.sendNavigationKey(any(), any()))
        .thenAnswer((_) async {});

    sl.registerLazySingleton<StreamingRepository>(() => mockRepository);
    sl.registerFactory<StreamingCubit>(
      () => StreamingCubit(repository: sl<StreamingRepository>()),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const MirroringPage(device: testDevice),
    );
  }

  testWidgets(
    'MirroringPage initializes stream and displays telemetry and HUD',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());

      // Initially starting
      expect(
        find.text('Starting Display Stream on Google Pixel 8...'),
        findsOneWidget,
      );

      // Complete session future
      await tester.pump();

      // Verify Telemetry Header
      expect(find.text('Google Pixel 8'), findsWidgets);
      expect(find.text('18ms'), findsOneWidget);
      expect(find.text('60 FPS'), findsOneWidget);
      expect(find.text('8 Mbps'), findsOneWidget);

      // Verify HUD navigation buttons
      expect(find.byTooltip('Back (Right Click)'), findsOneWidget);
      expect(find.byTooltip('Home (Cmd+H / Middle Click)'), findsOneWidget);
      expect(find.byTooltip('App Switcher (Cmd+Tab)'), findsOneWidget);
      expect(find.byTooltip('Rotate Display'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.byTooltip('Back (Right Click)'));
      await tester.pump();
      verify(() => mockRepository.sendNavigationKey('session_123', 4))
          .called(1);

      // Clean up
      await tester.pumpWidget(const SizedBox());
    },
  );
}
