import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads host network details and recent devices for discovery UI.
///
/// Replaces direct service lookups inside widgets so the host IP is fetched
/// in one place and shared by the empty state, pairing, and manual dialogs.
class HostContextCubit extends Cubit<HostContextState> {
  HostContextCubit({
    required NetworkInfoService networkInfoService,
    required DeviceHistoryService historyService,
  }) : _networkInfo = networkInfoService,
       _history = historyService,
       super(const HostContextState());

  final NetworkInfoService _networkInfo;
  final DeviceHistoryService _history;

  /// Fetches the host IP and recent devices in parallel.
  ///
  /// Keeps the last known values visible while reloading. Each source fails
  /// independently, so a broken history file never hides the host IP.
  Future<void> load() async {
    emit(state.copyWith(status: HostContextStatus.loading));
    final (ip, recents) = await (_loadHostIp(), _loadRecentDevices()).wait;
    if (isClosed) return;

    final failed = !ip.ok || !recents.ok;
    emit(
      state.copyWith(
        status: failed ? HostContextStatus.failure : HostContextStatus.loaded,
        hostIpAddress: ip.value,
        recentDevices: recents.value,
        errorMessage: failed ? failureMessage : null,
      ),
    );
  }

  /// User-facing message emitted when any host detail cannot be loaded.
  static const String failureMessage = 'Could not read host network details.';

  Future<({bool ok, String? value})> _loadHostIp() async {
    try {
      return (ok: true, value: await _networkInfo.getLocalIpAddress());
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to read host IP address.',
        error: error,
        stackTrace: stackTrace,
      );
      return (ok: false, value: null);
    }
  }

  Future<({bool ok, List<RecentDevice>? value})> _loadRecentDevices() async {
    try {
      return (ok: true, value: await _history.getRecentDevices());
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to read recent devices.',
        error: error,
        stackTrace: stackTrace,
      );
      return (ok: false, value: null);
    }
  }
}
