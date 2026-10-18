import 'dart:async';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reports the DeskDroid MCP server state: one full check on [load] (and on
/// each refresh), then the running-session count every [pollInterval].
class McpStatusCubit extends Cubit<McpStatusState> {
  McpStatusCubit({
    required McpStatusRepository repository,
    this.pollInterval = McpStatusConstants.sessionPollInterval,
  }) : _statusRepository = repository,
       super(const McpStatusInitial());

  final McpStatusRepository _statusRepository;
  final Duration pollInterval;
  Timer? _pollTimer;

  /// JSON for an AI client's configuration (launches this app's server).
  String get configurationSnippet => _statusRepository.configurationSnippet();

  /// Runs the full check; while one runs, further calls are ignored.
  Future<void> load() async {
    final current = state;
    if (current is McpStatusLoading) return;
    if (current is McpStatusLoaded) {
      if (current.isRefreshing) return;
      emit(McpStatusLoaded(status: current.status, isRefreshing: true));
    } else {
      emit(const McpStatusLoading());
    }
    _pollTimer?.cancel();
    try {
      final status = await _statusRepository.load();
      if (isClosed) return;
      emit(McpStatusLoaded(status: status));
      _pollTimer = Timer.periodic(pollInterval, (_) => _refreshSessions());
    } on Exception catch (error) {
      AppLogger.warning('MCP status check failed', error: error);
      if (isClosed) return;
      emit(McpStatusFailure(message: 'Could not check the MCP server: $error'));
    }
  }

  Future<void> _refreshSessions() async {
    if (state case McpStatusLoaded(isRefreshing: false)) {
      final count = await _statusRepository.countRunningSessions();
      if (isClosed || count == null) return;
      final current = state;
      if (current is McpStatusLoaded &&
          !current.isRefreshing &&
          current.status.runningSessions != count) {
        emit(
          McpStatusLoaded(
            status: current.status.copyWith(runningSessions: count),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
