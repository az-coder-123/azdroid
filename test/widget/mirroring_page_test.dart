import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/di/modules/platform_di.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_theme.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
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
import 'package:desk_droid/features/streaming/domain/entities/stream_telemetry.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/pages/mirroring_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fake_host_file_launcher.dart';
import '../helpers/fake_mirroring_preferences_repository.dart';

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
  setUpAll(() => registerFallbackValue(NavigationAction.back));

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
  );

  // Measured values deliberately differ from the session's targets above.
  const testTelemetry = StreamTelemetry(
    health: StreamHealth.live,
    fps: 59.6,
    bitrateMbps: 7.84,
    latencyMs: 12.4,
  );

  const testPlayback = AudioPlayback(status: AudioPlaybackStatus.playing);

  setUp(() async {
    await sl.reset();
    registerPlatformDependencies(sl, os: HostOs.macos);
    mockRepository = MockStreamingRepository();
    mockControlRepository = MockControlRepository();
    mockClipboardRepository = MockClipboardRepository();
    mockFileTransferRepository = MockFileTransferRepository();
    mockAudioRepository = MockAudioRepository();
    mockScreenshotRepository = MockScreenshotRepository();
    mockScreenRecordingRepository = MockScreenRecordingRepository();

    when(() => mockRepository.startSession(testDevice, stayAwake: true))
        .thenAnswer((_) async => testSession);
    when(() => mockRepository.stopSession(any())).thenAnswer((_) async {});
    when(() => mockRepository.watchTelemetry())
        .thenAnswer((_) => Stream.value(testTelemetry));
    when(() => mockControlRepository.sendNavigationAction(any(), any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.toggleScreenOff(any(), any()))
        .thenAnswer((_) async => true);
    when(() => mockAudioRepository.watch())
        .thenAnswer((_) => Stream.value(testPlayback));
    when(() => mockAudioRepository.volume).thenReturn(1);
    when(() => mockAudioRepository.isMuted).thenReturn(false);
    when(() => mockAudioRepository.setVolume(any())).thenAnswer((_) async {});
    when(() => mockAudioRepository.setMuted(any())).thenAnswer((_) async {});

    sl.registerLazySingleton<StreamingRepository>(() => mockRepository);
    sl.registerFactory<StreamingCubit>(
      () => StreamingCubit(
        repository: sl<StreamingRepository>(),
        preferences: FakeMirroringPreferencesRepository(),
      ),
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
      () => ScreenshotCubit(
        repository: sl<ScreenshotRepository>(),
        fileLauncher: FakeHostFileLauncher(),
      ),
    );

    sl.registerLazySingleton<ScreenRecordingRepository>(
      () => mockScreenRecordingRepository,
    );
    sl.registerFactory<ScreenRecordingCubit>(
      () => ScreenRecordingCubit(
        repository: sl<ScreenRecordingRepository>(),
        fileLauncher: FakeHostFileLauncher(),
      ),
    );

    sl.registerLazySingleton<MenuBarCubit>(() => MenuBarCubit());
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createSubject() {
    // Mirror main.dart: widgets read the scheme from the tree, not from `sl`.
    return RepositoryProvider<ShortcutScheme>.value(
      value: sl<ShortcutScheme>(),
      child: BlocProvider<MenuBarCubit>.value(
        value: sl<MenuBarCubit>(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MirroringPage(device: testDevice),
        ),
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
      // Header shows measured telemetry, not the configured targets.
      await tester.pump();
      expect(find.text('12ms'), findsOneWidget);
      expect(find.text('60 FPS'), findsOneWidget);
      expect(find.text('7.8 Mbps'), findsOneWidget);

      // Labels come from the scheme registered by the platform module.
      final keys = sl<ShortcutScheme>();

      // Verify HUD navigation buttons
      expect(find.byTooltip('Back (Right Click)'), findsOneWidget);
      expect(
        find.byTooltip('Home (${keys.label('H')} / Middle Click)'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('App Switcher (${keys.label('Tab')})'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Rotate Display (${keys.label('R')})'),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Turn Phone Screen Off, Keep Mirroring (${keys.label('O')})',
        ),
        findsOneWidget,
      );

      // Verify Side Controls Toolbar buttons
      expect(find.byTooltip('Streaming Bitrate & Quality'), findsOneWidget);
      expect(
        find.byTooltip('Take Screenshot (${keys.label('S')})'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Capture Area (${keys.label('S', shift: true)})'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Record Screen (${keys.label('R', shift: true)})'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Inject Text (${keys.label('K')})'),
        findsOneWidget,
      );
      expect(find.byTooltip('Clipboard Synchronization'), findsOneWidget);

      // The screen-power shortcut reaches the streaming cubit instead of
      // typing "o" on the device.
      final primary = keys.usesMetaKey
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(primary);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(primary);
      await tester.pump();
      verify(() => mockRepository.toggleScreenOff('session_123', true))
          .called(1);
      expect(find.text('Screen Off'), findsOneWidget);

      // The toolbar buttons use the control path (control socket, adb
      // fallback), like the shortcuts and mouse buttons.
      await tester.tap(find.byTooltip('Back (Right Click)'));
      await tester.pump();
      verify(
        () => mockControlRepository.sendNavigationAction(
          testDevice.serial,
          NavigationAction.back,
        ),
      ).called(1);
      await tester.tap(
        find.byTooltip('Home (${keys.label('H')} / Middle Click)'),
      );
      await tester.pump();
      verify(
        () => mockControlRepository.sendNavigationAction(
          testDevice.serial,
          NavigationAction.home,
        ),
      ).called(1);
      await tester.tap(find.byTooltip('App Switcher (${keys.label('Tab')})'));
      await tester.pump();
      verify(
        () => mockControlRepository.sendNavigationAction(
          testDevice.serial,
          NavigationAction.appSwitch,
        ),
      ).called(1);

      // Clean up
      await tester.pumpWidget(const SizedBox());
    },
  );
}
