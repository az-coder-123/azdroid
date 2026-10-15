import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_request_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/entities/intent_result_entity.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/repositories/intent_repository.dart';
import 'package:wifi_desk/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:wifi_desk/features/intent_dispatcher/presentation/cubit/intent_dispatcher_state.dart';

class MockIntentRepository extends Mock implements IntentRepository {}

void main() {
  late MockIntentRepository mockRepo;
  const testSerial = '192.168.1.5:5555';
  const testRequest = IntentRequestEntity(
    dataUri: 'https://flutter.dev',
    action: 'android.intent.action.VIEW',
  );

  setUpAll(() {
    registerFallbackValue(testRequest);
  });

  setUp(() {
    mockRepo = MockIntentRepository();
  });

  group('IntentDispatcherCubit', () {
    test('initial state is IntentDispatcherInitial', () {
      final cubit = IntentDispatcherCubit(repository: mockRepo);
      expect(cubit.state, equals(const IntentDispatcherInitial()));
    });

    test('reset emits IntentDispatcherInitial', () {
      final cubit = IntentDispatcherCubit(repository: mockRepo);
      cubit.reset();
      expect(cubit.state, equals(const IntentDispatcherInitial()));
    });

    blocTest<IntentDispatcherCubit, IntentDispatcherState>(
      'emits IntentDispatcherFailure when all destination targets are empty',
      build: () => IntentDispatcherCubit(repository: mockRepo),
      act: (cubit) => cubit.dispatchIntent(
        testSerial,
        const IntentRequestEntity(
          dataUri: '',
          packageName: '',
          componentName: '',
        ),
      ),
      expect: () => [
        const IntentDispatcherFailure(
          errorMessage:
              'Please provide at least a Data URI, Package Name, or Component.',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.dispatchIntent(any(), any()));
      },
    );

    blocTest<IntentDispatcherCubit, IntentDispatcherState>(
      'emits [IntentDispatcherSending, IntentDispatcherSuccess] upon successful dispatch',
      build: () {
        when(() => mockRepo.dispatchIntent(testSerial, any())).thenAnswer(
          (_) async => const IntentResultEntity(
            success: true,
            message: 'Intent successfully dispatched.',
          ),
        );
        return IntentDispatcherCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.dispatchIntent(testSerial, testRequest),
      expect: () => [
        const IntentDispatcherSending(),
        const IntentDispatcherSuccess(
          result: IntentResultEntity(
            success: true,
            message: 'Intent successfully dispatched.',
          ),
          request: testRequest,
        ),
      ],
    );

    blocTest<IntentDispatcherCubit, IntentDispatcherState>(
      'emits [IntentDispatcherSending, IntentDispatcherFailure] when dispatch fails',
      build: () {
        when(() => mockRepo.dispatchIntent(testSerial, any())).thenAnswer(
          (_) async => const IntentResultEntity(
            success: false,
            message: 'Activity not found',
          ),
        );
        return IntentDispatcherCubit(repository: mockRepo);
      },
      act: (cubit) => cubit.dispatchIntent(testSerial, testRequest),
      expect: () => [
        const IntentDispatcherSending(),
        const IntentDispatcherFailure(errorMessage: 'Activity not found'),
      ],
    );
  });
}
