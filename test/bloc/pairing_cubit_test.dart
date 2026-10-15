import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:desk_droid/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_state.dart';

class MockDeviceDiscoveryRepository extends Mock
    implements DeviceDiscoveryRepository {}

void main() {
  late MockDeviceDiscoveryRepository mockRepository;
  late PairingCubit pairingCubit;

  setUp(() {
    mockRepository = MockDeviceDiscoveryRepository();
    pairingCubit = PairingCubit(repository: mockRepository);
  });

  tearDown(() {
    pairingCubit.close();
  });

  group('PairingCubit', () {
    test('initial state should be PairingInitial', () {
      expect(pairingCubit.state, equals(const PairingInitial()));
    });

    blocTest<PairingCubit, PairingState>(
      'emits [PairingFailure] when IP is empty',
      build: () => pairingCubit,
      act: (cubit) =>
          cubit.pair(ipAddress: '   ', port: 37123, pairingCode: '123456'),
      expect: () => [
        const PairingFailure(error: 'IP Address cannot be empty.'),
      ],
    );

    blocTest<PairingCubit, PairingState>(
      'emits [PairingFailure] when pairing code is not 6 digits',
      build: () => pairingCubit,
      act: (cubit) => cubit.pair(
        ipAddress: '192.168.1.100',
        port: 37123,
        pairingCode: '123',
      ),
      expect: () => [
        const PairingFailure(error: 'Pairing code must be exactly 6 digits.'),
      ],
    );

    blocTest<PairingCubit, PairingState>(
      'emits [PairingSubmitting, PairingSuccess] when pairDevice succeeds',
      build: () {
        when(
          () => mockRepository.pairDevice(
            ipAddress: '192.168.1.100',
            port: 37123,
            pairingCode: '123456',
          ),
        ).thenAnswer((_) async => true);
        return pairingCubit;
      },
      act: (cubit) => cubit.pair(
        ipAddress: '192.168.1.100',
        port: 37123,
        pairingCode: '123456',
      ),
      expect: () => [
        const PairingSubmitting(),
        const PairingSuccess(
          message: 'Device successfully paired at 192.168.1.100:37123!',
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepository.pairDevice(
            ipAddress: '192.168.1.100',
            port: 37123,
            pairingCode: '123456',
          ),
        ).called(1);
      },
    );

    blocTest<PairingCubit, PairingState>(
      'emits [PairingSubmitting, PairingFailure] when pairDevice returns false',
      build: () {
        when(
          () => mockRepository.pairDevice(
            ipAddress: '192.168.1.100',
            port: 37123,
            pairingCode: '123456',
          ),
        ).thenAnswer((_) async => false);
        return pairingCubit;
      },
      act: (cubit) => cubit.pair(
        ipAddress: '192.168.1.100',
        port: 37123,
        pairingCode: '123456',
      ),
      expect: () => [
        const PairingSubmitting(),
        const PairingFailure(
          error: 'Pairing rejected. Please ensure the pairing dialog is currently open on your phone.',
        ),
      ],
    );

    test('reset emits PairingInitial', () {
      pairingCubit.reset();
      expect(pairingCubit.state, equals(const PairingInitial()));
    });
  });
}
