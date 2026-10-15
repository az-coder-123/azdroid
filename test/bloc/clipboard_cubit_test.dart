import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_state.dart';

class MockClipboardRepository extends Mock implements ClipboardRepository {}

void main() {
  late MockClipboardRepository mockRepository;
  const testSerial = '192.168.1.100:5555';

  setUp(() {
    mockRepository = MockClipboardRepository();
  });

  group('ClipboardCubit', () {
    test('initial state is ClipboardInitial with autoSyncEnabled = true', () {
      final cubit = ClipboardCubit(repository: mockRepository);
      expect(cubit.state, isA<ClipboardInitial>());
      expect(cubit.state.autoSyncEnabled, isTrue);
      cubit.close();
    });

    blocTest<ClipboardCubit, ClipboardState>(
      'syncHostToDevice emits [ClipboardSyncing, ClipboardSynced] on success',
      build: () {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => 'Copied on Mac');
        when(
          () => mockRepository.setDeviceClipboard(testSerial, 'Copied on Mac'),
        ).thenAnswer((_) async => true);
        return ClipboardCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.syncHostToDevice(testSerial),
      expect: () => [
        const ClipboardSyncing(
          direction: 'Mac ➔ Android',
          autoSyncEnabled: true,
        ),
        isA<ClipboardSynced>().having(
          (s) => s.lastItem.text,
          'text',
          'Copied on Mac',
        ),
      ],
    );

    blocTest<ClipboardCubit, ClipboardState>(
      'syncHostToDevice emits [ClipboardSyncing, ClipboardError] when host is empty',
      build: () {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => '');
        return ClipboardCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.syncHostToDevice(testSerial),
      expect: () => [
        const ClipboardSyncing(
          direction: 'Mac ➔ Android',
          autoSyncEnabled: true,
        ),
        const ClipboardError(
          errorMessage: 'macOS clipboard is empty.',
          autoSyncEnabled: true,
        ),
      ],
    );

    blocTest<ClipboardCubit, ClipboardState>(
      'syncDeviceToHost emits [ClipboardSyncing, ClipboardSynced] on success',
      build: () {
        when(() => mockRepository.getDeviceClipboard(testSerial))
            .thenAnswer((_) async => 'Copied on Android');
        when(() => mockRepository.setHostClipboard('Copied on Android'))
            .thenAnswer((_) async {});
        return ClipboardCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.syncDeviceToHost(testSerial),
      expect: () => [
        const ClipboardSyncing(
          direction: 'Android ➔ Mac',
          autoSyncEnabled: true,
        ),
        isA<ClipboardSynced>().having(
          (s) => s.lastItem.text,
          'text',
          'Copied on Android',
        ),
      ],
    );

    blocTest<ClipboardCubit, ClipboardState>(
      'toggleAutoSync switches autoSyncEnabled flag',
      build: () => ClipboardCubit(repository: mockRepository),
      act: (cubit) => cubit.toggleAutoSync(testSerial),
      expect: () => [const ClipboardInitial(autoSyncEnabled: false)],
    );

    test(
      'autoResetDuration automatically resets state to initial after sync',
      () async {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => 'Auto Reset Text');
        when(
          () =>
              mockRepository.setDeviceClipboard(testSerial, 'Auto Reset Text'),
        ).thenAnswer((_) async => true);

        final cubit = ClipboardCubit(
          repository: mockRepository,
          autoResetDuration: const Duration(milliseconds: 30),
        );

        await cubit.syncHostToDevice(testSerial);
        expect(cubit.state, isA<ClipboardSynced>());

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cubit.state, isA<ClipboardInitial>());

        await cubit.close();
      },
    );

    test(
      'reset() immediately emits ClipboardInitial and cancels auto-reset timer',
      () async {
        when(() => mockRepository.getHostClipboard())
            .thenAnswer((_) async => 'Text');
        when(() => mockRepository.setDeviceClipboard(testSerial, 'Text'))
            .thenAnswer((_) async => true);

        final cubit = ClipboardCubit(
          repository: mockRepository,
          autoResetDuration: const Duration(seconds: 10),
        );

        await cubit.syncHostToDevice(testSerial);
        expect(cubit.state, isA<ClipboardSynced>());

        cubit.reset();
        expect(cubit.state, isA<ClipboardInitial>());

        await cubit.close();
      },
    );
  });
}
