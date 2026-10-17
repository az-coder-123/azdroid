import 'package:desk_droid/features/logging/domain/entities/log_file_recording_status.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_cubit.dart';
import 'package:desk_droid/features/logging/presentation/cubit/device_log_state.dart';
import 'package:desk_droid/features/logging/presentation/widgets/log_action_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceLogCubit extends Mock implements DeviceLogCubit {}

void main() {
  group('LogActionFooter Responsiveness & Interaction Tests', () {
    late MockDeviceLogCubit mockCubit;
    var exportCalled = false;

    setUp(() {
      mockCubit = MockDeviceLogCubit();
      exportCalled = false;

      when(() => mockCubit.state).thenReturn(const DeviceLogInitial());
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.togglePause()).thenReturn(null);
      when(() => mockCubit.toggleAutoScroll()).thenReturn(null);
      when(() => mockCubit.toggleSoftWrap()).thenReturn(null);
      when(() => mockCubit.clearConsole()).thenReturn(null);
      when(() => mockCubit.clearDeviceBuffer()).thenAnswer((_) async => true);
      when(() => mockCubit.toggleFileRecording()).thenAnswer((_) async {});
    });

    Widget createSubject({
      double width = 720.0,
      LogFileRecordingStatus recordingStatus = const LogFileRecordingStatus(),
      bool isPaused = false,
      bool autoScroll = true,
      bool softWrap = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: BlocProvider<DeviceLogCubit>.value(
                value: mockCubit,
                child: LogActionFooter(
                  totalEntries: 5000,
                  filteredEntries: 5000,
                  recordingStatus: recordingStatus,
                  isPaused: isPaused,
                  autoScroll: autoScroll,
                  softWrap: softWrap,
                  onExportSnapshot: () => exportCalled = true,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders at 720px width without layout overflow', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(width: 720.0));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Showing 5000 of 5000 lines'), findsOneWidget);
      expect(find.text('Record to File'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets(
      'Renders at 720px width with active recording without layout overflow',
      (tester) async {
        const activeStatus = LogFileRecordingStatus(
          isRecording: true,
          targetFilePath: '/tmp/test.log',
          bytesWritten: 1048576,
          linesWritten: 2500,
        );

        await tester.pumpWidget(
          createSubject(width: 720.0, recordingStatus: activeStatus),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('REC: 1.00 MB (2500 lines)'),
          findsOneWidget,
        );
        expect(find.text('Stop REC'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders at narrow 450px width without overflow via horizontal scrolling',
      (tester) async {
        await tester.pumpWidget(createSubject(width: 450.0));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsWidgets);
      },
    );

    testWidgets(
      'Action buttons dispatch corresponding cubit calls and export callback',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createSubject(width: 1000.0));
        await tester.pump();

        // Pause button
        await tester.tap(find.byIcon(Icons.pause_rounded));
        verify(() => mockCubit.togglePause()).called(1);

        // Auto-scroll toggle
        await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
        verify(() => mockCubit.toggleAutoScroll()).called(1);

        // Soft-wrap toggle
        await tester.tap(find.byIcon(Icons.wrap_text_rounded));
        verify(() => mockCubit.toggleSoftWrap()).called(1);

        // Clear console
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        verify(() => mockCubit.clearConsole()).called(1);

        // Clear device buffer
        await tester.tap(find.byIcon(Icons.delete_forever_outlined));
        verify(() => mockCubit.clearDeviceBuffer()).called(1);

        // Record to file
        await tester.tap(find.text('Record to File'));
        verify(() => mockCubit.toggleFileRecording()).called(1);

        // Export snapshot
        await tester.tap(find.text('Export'));
        expect(exportCalled, isTrue);
      },
    );
  });
}
