import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/repositories/control_repository_impl.dart';
import 'package:desk_droid/features/control/domain/entities/frame_size.dart';
import 'package:desk_droid/features/control/domain/entities/touch_stream.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/domain/repositories/video_frame_size_source.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_event.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements ControlDatasource {}

class _MockFrameSource extends Mock implements VideoFrameSizeSource {}

class _MockRepository extends Mock implements ControlRepository {}

void main() {
  const serial = '192.168.1.3:5555';
  const point = NormalizedPoint(0.5, 0.25);

  setUpAll(() {
    registerFallbackValue(TouchStreamPhase.start);
    registerFallbackValue(const FrameSize(1, 1));
  });

  group('ControlRepositoryImpl.sendTouchStream', () {
    late _MockDatasource datasource;
    late _MockFrameSource frames;
    late ControlRepositoryImpl repository;

    setUp(() {
      datasource = _MockDatasource();
      frames = _MockFrameSource();
      repository = ControlRepositoryImpl(
        datasource: datasource,
        frameSizeSource: frames,
      );
      when(() => frames.current())
          .thenAnswer((_) async => const FrameSize(1080, 2336));
      when(
        () => datasource.injectTouchStream(
          any(),
          any(),
          any(),
          frame: any(named: 'frame'),
        ),
      ).thenAnswer((_) async => true);
    });

    test('reads the frame once per stream and maps to its pixels', () async {
      await repository.sendTouchStream(serial, TouchStreamPhase.start, [point]);
      await repository.sendTouchStream(serial, TouchStreamPhase.move, [
        const NormalizedPoint(1.4, -0.2), // Clamped into the frame.
      ]);
      await repository.sendTouchStream(serial, TouchStreamPhase.end, []);

      verify(() => frames.current()).called(1);
      final calls = verify(
        () => datasource.injectTouchStream(
          serial,
          captureAny(),
          captureAny(),
          frame: const FrameSize(1080, 2336),
        ),
      ).captured;
      expect(calls[1], [(x: 540, y: 584)]);
      expect(calls[3], [(x: 1080, y: 0)]);
      expect(calls[5], isEmpty);
    });

    test('the next stream reads the frame again (rotation)', () async {
      await repository.sendTouchStream(serial, TouchStreamPhase.start, [point]);
      await repository.sendTouchStream(serial, TouchStreamPhase.end, []);
      await repository.sendTouchStream(serial, TouchStreamPhase.start, [point]);

      verify(() => frames.current()).called(2);
    });
  });

  group('ControlBloc touch stream', () {
    late _MockRepository repository;
    late List<String> log;

    setUp(() {
      repository = _MockRepository();
      log = [];
      when(() => repository.sendTouchStream(any(), any(), any()))
          .thenAnswer((invocation) async {
            final phase = invocation.positionalArguments[1] as TouchStreamPhase;
            log.add('${phase.name} begin');
            // A slow start (the frame size lookup) must not let a move pass it.
            if (phase == TouchStreamPhase.start) {
              await Future<void>.delayed(const Duration(milliseconds: 30));
            }
            log.add('${phase.name} end');
            return true;
          });
    });

    blocTest<ControlBloc, ControlState>(
      'handles stream events one at a time, in order',
      build: () => ControlBloc(repository: repository),
      act: (bloc) => bloc
        ..add(
          const ControlTouchStreamed(
            deviceSerial: serial,
            phase: TouchStreamPhase.start,
            points: [point],
          ),
        )
        ..add(
          const ControlTouchStreamed(
            deviceSerial: serial,
            phase: TouchStreamPhase.move,
            points: [point],
          ),
        )
        ..add(
          const ControlTouchStreamed(
            deviceSerial: serial,
            phase: TouchStreamPhase.end,
            points: [point, point],
          ),
        ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ControlReady(injectedCount: 1, lastActionDescription: 'Pinch'),
      ],
      verify: (_) => expect(log, [
        'start begin',
        'start end',
        'move begin',
        'move end',
        'end begin',
        'end end',
      ]),
    );

    blocTest<ControlBloc, ControlState>(
      'reports a stream that cannot start',
      setUp: () =>
          when(() => repository.sendTouchStream(any(), any(), any()))
              .thenAnswer((_) async => false),
      build: () => ControlBloc(repository: repository),
      act: (bloc) => bloc.add(
        const ControlTouchStreamed(
          deviceSerial: serial,
          phase: TouchStreamPhase.start,
          points: [point],
        ),
      ),
      expect: () => [
        const ControlError(errorMessage: 'Failed to inject touch'),
      ],
    );
  });
}
