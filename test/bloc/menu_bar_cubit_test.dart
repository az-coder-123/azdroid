import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_state.dart';

void main() {
  group('MenuBarCubit', () {
    test('initial state has default MenuBarStatusEntity', () {
      final cubit = MenuBarCubit();
      expect(cubit.state.status.activeDeviceName, isNull);
      expect(cubit.state.status.isWindowVisible, isTrue);
      cubit.close();
    });

    blocTest<MenuBarCubit, MenuBarState>(
      'updateActiveSession sets device name, latency, and fps',
      build: () => MenuBarCubit(),
      act: (cubit) => cubit.updateActiveSession(
        deviceName: 'Google Pixel 8',
        batteryLevel: 88,
        latencyMs: 16,
        fps: 60,
      ),
      expect: () => [
        isA<MenuBarState>()
            .having(
              (s) => s.status.activeDeviceName,
              'activeDeviceName',
              'Google Pixel 8',
            )
            .having((s) => s.status.batteryLevel, 'batteryLevel', 88),
      ],
    );

    blocTest<MenuBarCubit, MenuBarState>(
      'clearActiveSession resets device info',
      build: () {
        final cubit = MenuBarCubit();
        cubit.updateActiveSession(deviceName: 'Pixel');
        return cubit;
      },
      act: (cubit) => cubit.clearActiveSession(),
      expect: () => [
        isA<MenuBarState>().having(
          (s) => s.status.activeDeviceName,
          'activeDeviceName',
          isNull,
        ),
      ],
    );

    blocTest<MenuBarCubit, MenuBarState>(
      'toggleWindowVisibility inverts isWindowVisible',
      build: () => MenuBarCubit(),
      act: (cubit) => cubit.toggleWindowVisibility(),
      expect: () => [
        isA<MenuBarState>().having(
          (s) => s.status.isWindowVisible,
          'isWindowVisible',
          isFalse,
        ),
      ],
    );
  });
}
