import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_state.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/side_controls_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScreenRecordingCubit extends Mock implements ScreenRecordingCubit {}

class MockClipboardCubit extends Mock implements ClipboardCubit {}

void main() {
  const testSession = StreamSessionEntity(
    sessionId: 'session_1',
    deviceId: '192.168.1.100:5555',
    deviceName: 'Pixel 8',
    width: 1080,
    height: 2400,
    fps: 60,
    bitrateMbps: 8,
  );

  late MockScreenRecordingCubit mockRecordCubit;
  late MockClipboardCubit mockClipboardCubit;

  setUp(() {
    mockRecordCubit = MockScreenRecordingCubit();
    when(() => mockRecordCubit.state)
        .thenReturn(const ScreenRecordingInitial());
    when(() => mockRecordCubit.stream).thenAnswer((_) => const Stream.empty());

    mockClipboardCubit = MockClipboardCubit();
    when(() => mockClipboardCubit.state).thenReturn(const ClipboardInitial());
    when(() => mockClipboardCubit.stream)
        .thenAnswer((_) => const Stream.empty());
  });

  testWidgets(
    'SideControlsToolbar places Inject Text at top and Logcat Console at bottom',
    (tester) async {
      var textInjected = false;
      var screenshotTaken = false;
      var logsViewed = false;

      await tester.pumpWidget(
        RepositoryProvider<ShortcutScheme>.value(
          value: ShortcutScheme.mac,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ScreenRecordingCubit>.value(value: mockRecordCubit),
              BlocProvider<ClipboardCubit>.value(value: mockClipboardCubit),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SideControlsToolbar(
                    session: testSession,
                    deviceSerial: '192.168.1.100:5555',
                    onSelectBitrate: (_) {},
                    onToggleStayAwake: () {},
                    onScreenshot: () => screenshotTaken = true,
                    onCropScreenshot: () {},
                    onTextInject: () => textInjected = true,
                    onSendFiles: () {},
                    onBrowseFiles: () {},
                    onViewLogs: () => logsViewed = true,
                    onInstallApk: () {},
                    onDispatchIntent: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final injectTextFinder = find.byTooltip('Inject Text (⌘K)');
      final screenshotFinder = find.byTooltip('Take Screenshot (⌘S)');
      final logcatFinder = find.byTooltip('Device Logcat Console (⌘⇧L)');

      expect(injectTextFinder, findsOneWidget);
      expect(screenshotFinder, findsOneWidget);
      expect(logcatFinder, findsOneWidget);

      final injectTextY = tester.getTopLeft(injectTextFinder).dy;
      final screenshotY = tester.getTopLeft(screenshotFinder).dy;
      final logcatY = tester.getTopLeft(logcatFinder).dy;

      // Assert Inject Text is at the top (above Screenshot)
      expect(injectTextY, lessThan(screenshotY));

      // Assert Logcat Console is at the bottom (below Screenshot)
      expect(logcatY, greaterThan(screenshotY));
      expect(logcatY, greaterThan(injectTextY));

      // Assert callbacks fire
      await tester.tap(injectTextFinder);
      expect(textInjected, isTrue);

      await tester.tap(screenshotFinder);
      expect(screenshotTaken, isTrue);

      await tester.tap(logcatFinder);
      expect(logsViewed, isTrue);
    },
  );
}
