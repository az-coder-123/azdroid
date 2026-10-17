import 'package:desk_droid/features/menubar/domain/entities/menu_bar_status_entity.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit managing the macOS Menu Bar companion status item and window visibility.
class MenuBarCubit extends Cubit<MenuBarState> {
  MenuBarCubit() : super(const MenuBarState());

  /// Updates active device streaming telemetry in the Menu Bar.
  void updateActiveSession({
    String? deviceName,
    int? batteryLevel,
    int? latencyMs,
    int? fps,
  }) {
    emit(
      state.copyWith(
        status: state.status.copyWith(
          activeDeviceName: deviceName,
          batteryLevel: batteryLevel,
          latencyMs: latencyMs,
          fps: fps,
        ),
      ),
    );
  }

  /// Clears active device session when mirroring concludes.
  void clearActiveSession() {
    emit(
      state.copyWith(
        status: const MenuBarStatusEntity(
          activeDeviceName: null,
          batteryLevel: null,
          latencyMs: null,
          fps: null,
        ),
      ),
    );
  }

  /// Toggles desktop window visibility between shown and hidden.
  void toggleWindowVisibility() {
    final updated = !state.status.isWindowVisible;
    emit(
      state.copyWith(status: state.status.copyWith(isWindowVisible: updated)),
    );
  }

  /// Updates count of nearby discovered Wi-Fi devices.
  void updateDiscoveredCount(int count) {
    emit(
      state.copyWith(
        status: state.status.copyWith(discoveredDeviceCount: count),
      ),
    );
  }
}
