import 'package:desk_droid/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/recording_countdown_overlay.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/recording_setup_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScreenRecordingRepository extends Mock
    implements ScreenRecordingRepository {}

void main() {
  late MockScreenRecordingRepository mockRepo;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepo = MockScreenRecordingRepository();
  });

  Widget buildTestableWidget(Widget child, ScreenRecordingCubit cubit) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ScreenRecordingCubit>.value(
          value: cubit,
          child: child,
        ),
      ),
    );
  }

  group('RecordingSetupPill Widget', () {
    testWidgets('renders title, countdown toggle, and start button', (
      tester,
    ) async {
      final cubit = ScreenRecordingCubit(repository: mockRepo);
      const state = ScreenRecordingPreparing(
        deviceSerial: testSerial,
        countdownEnabled: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(const RecordingSetupPill(state: state), cubit),
      );

      expect(find.text('Record Screen'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tapping start button triggers startWithCountdown', (
      tester,
    ) async {
      when(
        () => mockRepo.startRecording(
          deviceSerial: testSerial,
          bitrateBps: any(named: 'bitrateBps'),
          timeLimitSeconds: any(named: 'timeLimitSeconds'),
        ),
      ).thenAnswer((_) async => '/sdcard/test.mp4');

      final cubit = ScreenRecordingCubit(repository: mockRepo);
      cubit.prepareRecording(testSerial);
      final state = cubit.state as ScreenRecordingPreparing;

      await tester.pumpWidget(
        buildTestableWidget(RecordingSetupPill(state: state), cubit),
      );

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(cubit.state, isA<ScreenRecordingCountdown>());
      await cubit.close();
    });
  });

  group('RecordingCountdownOverlay Widget', () {
    testWidgets('renders remaining seconds when counting down', (tester) async {
      final cubit = ScreenRecordingCubit(repository: mockRepo);
      cubit.emit(
        const ScreenRecordingCountdown(
          deviceSerial: testSerial,
          remainingSeconds: 3,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const RecordingCountdownOverlay(deviceSerial: testSerial),
          cubit,
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Preparing screen recording...'), findsOneWidget);
      expect(find.text('Start Now'), findsOneWidget);
      expect(find.text('Cancel (Esc)'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders shrink when not counting down', (tester) async {
      final cubit = ScreenRecordingCubit(repository: mockRepo);

      await tester.pumpWidget(
        buildTestableWidget(
          const RecordingCountdownOverlay(deviceSerial: testSerial),
          cubit,
        ),
      );

      expect(find.text('Preparing screen recording...'), findsNothing);
      await cubit.close();
    });
  });
}
