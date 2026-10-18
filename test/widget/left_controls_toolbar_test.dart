import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/features/audio/domain/entities/audio_playback.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_state.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/left_controls_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioCubit extends Mock implements AudioCubit {}

void main() {
  const testSession = StreamSessionEntity(
    sessionId: 'session_1',
    deviceId: 'device_1',
    deviceName: 'Pixel 8',
    width: 1080,
    height: 2400,
    fps: 60,
    bitrateMbps: 8,
  );

  late MockAudioCubit mockAudioCubit;

  setUp(() {
    mockAudioCubit = MockAudioCubit();
    when(() => mockAudioCubit.state).thenReturn(
      const AudioActive(
        playback: AudioPlayback(status: AudioPlaybackStatus.playing),
      ),
    );
    when(() => mockAudioCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('LeftControlsToolbar renders all groups and handles callbacks', (
    tester,
  ) async {
    var backTapped = false;
    var homeTapped = false;
    var appSwitchTapped = false;
    var powerTapped = false;
    var rotateTapped = false;
    var screenOffTapped = false;
    var zenModeTapped = false;
    var showcaseTapped = false;
    var guideTapped = false;

    await tester.pumpWidget(
      RepositoryProvider<ShortcutScheme>.value(
        value: ShortcutScheme.mac,
        child: BlocProvider<AudioCubit>.value(
          value: mockAudioCubit,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: LeftControlsToolbar(
                  session: testSession,
                  onBack: () => backTapped = true,
                  onHome: () => homeTapped = true,
                  onAppSwitch: () => appSwitchTapped = true,
                  onPower: () => powerTapped = true,
                  onRotate: () => rotateTapped = true,
                  onToggleScreenOff: () => screenOffTapped = true,
                  onToggleZenMode: () => zenModeTapped = true,
                  onOpenShowcase: () => showcaseTapped = true,
                  onOpenGuide: () => guideTapped = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all tooltips exist
    expect(find.byTooltip('Back (Right Click)'), findsOneWidget);
    expect(find.byTooltip('Home (⌘H / Middle Click)'), findsOneWidget);
    expect(find.byTooltip('App Switcher (⌘Tab)'), findsOneWidget);
    expect(find.byTooltip('Lock Phone / Power (⌘P)'), findsOneWidget);
    expect(find.byTooltip('Rotate Display (⌘R)'), findsOneWidget);
    expect(
      find.byTooltip('Turn Phone Screen Off, Keep Mirroring (⌘O)'),
      findsOneWidget,
    );
    expect(find.byTooltip('Zen Mode (Hide Toolbars)'), findsOneWidget);
    expect(
      find.byTooltip('Features Showcase (All 21 Features)'),
      findsOneWidget,
    );
    expect(find.byTooltip('User Guide & Keyboard Shortcuts'), findsOneWidget);

    // Tap each button and verify callback triggers
    await tester.tap(find.byTooltip('Back (Right Click)'));
    expect(backTapped, isTrue);

    await tester.tap(find.byTooltip('Home (⌘H / Middle Click)'));
    expect(homeTapped, isTrue);

    await tester.tap(find.byTooltip('App Switcher (⌘Tab)'));
    expect(appSwitchTapped, isTrue);

    await tester.tap(find.byTooltip('Lock Phone / Power (⌘P)'));
    expect(powerTapped, isTrue);

    await tester.tap(find.byTooltip('Rotate Display (⌘R)'));
    expect(rotateTapped, isTrue);

    await tester.tap(
      find.byTooltip('Turn Phone Screen Off, Keep Mirroring (⌘O)'),
    );
    expect(screenOffTapped, isTrue);

    await tester.tap(find.byTooltip('Zen Mode (Hide Toolbars)'));
    expect(zenModeTapped, isTrue);

    await tester.tap(find.byTooltip('Features Showcase (All 21 Features)'));
    expect(showcaseTapped, isTrue);

    await tester.tap(find.byTooltip('User Guide & Keyboard Shortcuts'));
    expect(guideTapped, isTrue);
  });
}
