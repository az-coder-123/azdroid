import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_stream_entity.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/pages/mirroring_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStreamingRepository extends Mock implements StreamingRepository {}

class MockControlRepository extends Mock implements ControlRepository {}

class MockClipboardRepository extends Mock implements ClipboardRepository {}

class MockFileTransferRepository extends Mock
    implements FileTransferRepository {}

class MockAudioRepository extends Mock implements AudioRepository {}

class MockScreenshotRepository extends Mock implements ScreenshotRepository {}

class MockScreenRecordingRepository extends Mock
    implements ScreenRecordingRepository {}

void main() {
  late MockStreamingRepository mockRepository;
  late MockControlRepository mockControlRepository;
  late MockClipboardRepository mockClipboardRepository;
  late MockFileTransferRepository mockFileTransferRepository;
  late MockAudioRepository mockAudioRepository;
  late MockScreenshotRepository mockScreenshotRepository;
  late MockScreenRecordingRepository mockScreenRecordingRepository;

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

  const testAudioStream = AudioStreamEntity(
    deviceId: '192.168.1.100:5555',
    volume: 0.8,
    isMuted: false,
  );

  setUp(() async {
    await sl.reset();
    mockRepository = MockStreamingRepository();
    mockControlRepository = MockControlRepository();
    mockClipboardRepository = MockClipboardRepository();
    mockFileTransferRepository = MockFileTransferRepository();
    mockAudioRepository = MockAudioRepository();
    mockScreenshotRepository = MockScreenshotRepository();
    mockScreenRecordingRepository = MockScreenRecordingRepository();

    when(() => mockRepository.startSession(testDevice))
        .thenAnswer((_) async => testSession);
    when(() => mockRepository.stopSession(any())).thenAnswer((_) async {});
    when(() => mockRepository.sendNavigationKey(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockAudioRepository.startAudioStream(any()))
        .thenAnswer((_) async => testAudioStream);
    when(() => mockAudioRepository.stopAudioStream(any()))
        .thenAnswer((_) async {});
    when(() => mockAudioRepository.setVolume(any())).thenAnswer((_) async {});
    when(() => mockAudioRepository.toggleMute()).thenAnswer((_) async => true);

    sl.registerLazySingleton<StreamingRepository>(() => mockRepository);
    sl.registerFactory<StreamingCubit>(
      () => StreamingCubit(repository: sl<StreamingRepository>()),
    );

    sl.registerLazySingleton<ControlRepository>(() => mockControlRepository);
    sl.registerFactory<ControlBloc>(
      () => ControlBloc(repository: sl<ControlRepository>()),
    );

    sl.registerLazySingleton<ClipboardRepository>(
      () => mockClipboardRepository,
    );
    sl.registerFactory<ClipboardCubit>(
      () => ClipboardCubit(repository: sl<ClipboardRepository>()),
    );

    sl.registerLazySingleton<FileTransferRepository>(
      () => mockFileTransferRepository,
    );
    sl.registerFactory<FileTransferCubit>(
      () => FileTransferCubit(repository: sl<FileTransferRepository>()),
    );

    sl.registerLazySingleton<AudioRepository>(() => mockAudioRepository);
    sl.registerFactory<AudioCubit>(
      () => AudioCubit(repository: sl<AudioRepository>()),
    );

    sl.registerLazySingleton<ScreenshotRepository>(
      () => mockScreenshotRepository,
    );
    sl.registerFactory<ScreenshotCubit>(
      () => ScreenshotCubit(repository: sl<ScreenshotRepository>()),
    );

    sl.registerLazySingleton<ScreenRecordingRepository>(
      () => mockScreenRecordingRepository,
    );
    sl.registerFactory<ScreenRecordingCubit>(
      () => ScreenRecordingCubit(repository: sl<ScreenRecordingRepository>()),
    );

    sl.registerLazySingleton<MenuBarCubit>(() => MenuBarCubit());
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createSubject() {
    return BlocProvider<MenuBarCubit>.value(
      value: sl<MenuBarCubit>(),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MirroringPage(device: testDevice),
      ),
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

      // Verify Side Controls Toolbar buttons
      expect(find.byTooltip('Streaming Bitrate & Quality'), findsOneWidget);
      expect(find.byTooltip('Take Screenshot (Cmd+S)'), findsOneWidget);
      expect(find.byTooltip('Capture Area (Cmd+Shift+S)'), findsOneWidget);
      expect(find.byTooltip('Record Screen (Cmd+Shift+R)'), findsOneWidget);
      expect(find.byTooltip('Inject Text (Cmd+K)'), findsOneWidget);
      expect(find.byTooltip('Clipboard Synchronization'), findsOneWidget);

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
