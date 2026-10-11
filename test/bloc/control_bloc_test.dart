import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/control/domain/entities/input_event_entity.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_event.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_state.dart';

class MockControlRepository extends Mock implements ControlRepository {}

void main() {
  late MockControlRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockControlRepository();
  });

  group('ControlBloc', () {
    test('initial state is ControlReady', () {
      final bloc = ControlBloc(repository: mockRepository);
      expect(bloc.state, isA<ControlReady>());
      expect(bloc.state.injectedCount, equals(0));
      expect(bloc.state.isKeyboardCaptured, isTrue);
      bloc.close();
    });

    blocTest<ControlBloc, ControlState>(
      'emits updated ControlReady on successful ControlTapDispatched',
      build: () {
        when(
          () => mockRepository.sendTap(
            testSerial,
            normalizedX: 0.5,
            normalizedY: 0.5,
          ),
        ).thenAnswer((_) async => true);
        return ControlBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ControlTapDispatched(
          deviceSerial: testSerial,
          normalizedX: 0.5,
          normalizedY: 0.5,
        ),
      ),
      expect: () => [
        const ControlReady(
          injectedCount: 1,
          isKeyboardCaptured: true,
          lastActionDescription: 'Tap (50%, 50%)',
        ),
      ],
    );

    blocTest<ControlBloc, ControlState>(
      'emits ControlError on failed ControlTapDispatched',
      build: () {
        when(
          () => mockRepository.sendTap(
            testSerial,
            normalizedX: 0.5,
            normalizedY: 0.5,
          ),
        ).thenAnswer((_) async => false);
        return ControlBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ControlTapDispatched(
          deviceSerial: testSerial,
          normalizedX: 0.5,
          normalizedY: 0.5,
        ),
      ),
      expect: () => [
        const ControlError(
          errorMessage: 'Failed to inject tap on $testSerial',
          injectedCount: 0,
          isKeyboardCaptured: true,
        ),
      ],
    );

    blocTest<ControlBloc, ControlState>(
      'emits updated ControlReady on successful ControlKeyDispatched',
      build: () {
        when(() => mockRepository.sendKeyEvent(testSerial, 66))
            .thenAnswer((_) async => true);
        return ControlBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ControlKeyDispatched(deviceSerial: testSerial, keyCode: 66),
      ),
      expect: () => [
        const ControlReady(
          injectedCount: 1,
          isKeyboardCaptured: true,
          lastActionDescription: 'Key (66)',
        ),
      ],
    );

    blocTest<ControlBloc, ControlState>(
      'emits updated ControlReady on successful ControlTextDispatched',
      build: () {
        when(() => mockRepository.sendText(testSerial, 'Hello World'))
            .thenAnswer((_) async => true);
        return ControlBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ControlTextDispatched(
          deviceSerial: testSerial,
          text: 'Hello World',
        ),
      ),
      expect: () => [
        const ControlReady(
          injectedCount: 1,
          isKeyboardCaptured: true,
          lastActionDescription: 'Text (11 chars)',
        ),
      ],
    );

    blocTest<ControlBloc, ControlState>(
      'emits updated ControlReady on successful ControlNavigationActionDispatched',
      build: () {
        when(
          () => mockRepository.sendNavigationAction(
            testSerial,
            NavigationAction.back,
          ),
        ).thenAnswer((_) async => true);
        return ControlBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(
        const ControlNavigationActionDispatched(
          deviceSerial: testSerial,
          action: NavigationAction.back,
        ),
      ),
      expect: () => [
        const ControlReady(
          injectedCount: 1,
          isKeyboardCaptured: true,
          lastActionDescription: 'Action (back)',
        ),
      ],
    );

    blocTest<ControlBloc, ControlState>(
      'updates keyboard capture flag on ControlKeyboardCaptureToggled',
      build: () => ControlBloc(repository: mockRepository),
      act: (bloc) =>
          bloc.add(const ControlKeyboardCaptureToggled(isCaptured: false)),
      expect: () => [
        const ControlReady(isKeyboardCaptured: false, injectedCount: 0),
      ],
    );
  });
}
