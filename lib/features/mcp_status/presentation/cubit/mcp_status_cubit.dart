import 'dart:async';

import 'package:desk_droid/core/constants/mcp_status_constants.dart';
import 'package:desk_droid/core/services/app_logger.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_activity.dart';
import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:desk_droid/features/mcp_status/domain/repositories/mcp_status_repository.dart';
import 'package:desk_droid/features/mcp_status/presentation/cubit/mcp_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reports the Azdroid MCP server state: one full check on [load] (and on
/// each refresh), then the running sessions every [sessionPollInterval] and
/// their activity every [activityPollInterval]. A state is emitted only when
/// something visible changed.
class McpStatusCubit extends Cubit<McpStatusState> {
  McpStatusCubit({
    required McpStatusRepository repository,
    this.sessionPollInterval = McpStatusConstants.sessionPollInterval,
    this.activityPollInterval = McpStatusConstants.activityPollInterval,
  }) : _statusRepository = repository,
       super(const McpStatusInitial());

  final McpStatusRepository _statusRepository;
  final Duration sessionPollInterval;
  final Duration activityPollInterval;
  Timer? _sessionTimer;
  Timer? _activityTimer;
  bool _polling = false;

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
    _stopPolling();
    try {
      final status = await _statusRepository.load();
      if (isClosed) return;
      emit(McpStatusLoaded(status: status));
      _sessionTimer = Timer.periodic(sessionPollInterval, (_) {
        _poll((s) async => s.copyWith(livePids: await _sessionsOr(s)));
      });
      _activityTimer = Timer.periodic(activityPollInterval, (_) {
        _poll((s) async => s.copyWith(activity: await _activityOf(s)));
      });
    } on Exception catch (error) {
      AppLogger.warning('MCP status check failed', error: error);
      if (isClosed) return;
      emit(McpStatusFailure(message: 'Could not check the MCP server: $error'));
    }
  }

  Future<Set<int>?> _sessionsOr(McpServerStatus status) async =>
      await _statusRepository.listServerPids() ?? status.livePids;

  Future<McpActivitySnapshot> _activityOf(McpServerStatus status) =>
      _statusRepository.readActivity(livePids: status.livePids);

  /// Applies one periodic update, never two at once and never during a full
  /// check, and emits only a changed status.
  Future<void> _poll(
    Future<McpServerStatus> Function(McpServerStatus status) update,
  ) async {
    final current = state;
    if (_polling || current is! McpStatusLoaded || current.isRefreshing) return;
    _polling = true;
    try {
      final next = await update(current.status);
      final latest = state;
      if (isClosed || latest is! McpStatusLoaded || latest.isRefreshing) return;
      if (next != latest.status) emit(McpStatusLoaded(status: next));
    } on Exception catch (error) {
      AppLogger.debug('MCP status poll failed: $error');
    } finally {
      _polling = false;
    }
  }

  void _stopPolling() {
    _sessionTimer?.cancel();
    _activityTimer?.cancel();
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
