import 'package:bloc_test/bloc_test.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkInfoService extends Mock implements NetworkInfoService {}

class MockDeviceHistoryService extends Mock implements DeviceHistoryService {}

void main() {
  late MockNetworkInfoService networkInfo;
  late MockDeviceHistoryService history;

  final recent = RecentDevice(
    id: '192.168.1.20:5555',
    name: 'Pixel',
    ipAddress: '192.168.1.20',
    port: 5555,
    lastConnected: DateTime(2026, 10, 17),
  );

  setUp(() {
    networkInfo = MockNetworkInfoService();
    history = MockDeviceHistoryService();
  });

  HostContextCubit build() => HostContextCubit(
    networkInfoService: networkInfo,
    historyService: history,
  );

  group('HostContextCubit', () {
    test('initial state is empty', () {
      expect(build().state, const HostContextState());
    });

    blocTest<HostContextCubit, HostContextState>(
      'load emits [loading, loaded] with host IP and recent devices',
      setUp: () {
        when(() => networkInfo.getLocalIpAddress())
            .thenAnswer((_) async => '192.168.1.12');
        when(() => history.getRecentDevices())
            .thenAnswer((_) async => [recent]);
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const HostContextState(status: HostContextStatus.loading),
        HostContextState(
          status: HostContextStatus.loaded,
          hostIpAddress: '192.168.1.12',
          recentDevices: [recent],
        ),
      ],
    );

    blocTest<HostContextCubit, HostContextState>(
      'load keeps the host IP when the history source fails',
      setUp: () {
        when(() => networkInfo.getLocalIpAddress())
            .thenAnswer((_) async => '10.0.0.5');
        when(() => history.getRecentDevices())
            .thenThrow(Exception('corrupt history'));
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => const [
        HostContextState(status: HostContextStatus.loading),
        HostContextState(
          status: HostContextStatus.failure,
          hostIpAddress: '10.0.0.5',
          errorMessage: HostContextCubit.failureMessage,
        ),
      ],
    );
  });
}
