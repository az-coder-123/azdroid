import 'package:desk_droid/features/mcp_status/domain/entities/mcp_server_status.dart';
import 'package:equatable/equatable.dart';

sealed class McpStatusState extends Equatable {
  const McpStatusState();

  @override
  List<Object?> get props => [];
}

final class McpStatusInitial extends McpStatusState {
  const McpStatusInitial();
}

/// The first full check is running.
final class McpStatusLoading extends McpStatusState {
  const McpStatusLoading();
}

final class McpStatusLoaded extends McpStatusState {
  const McpStatusLoaded({required this.status, this.isRefreshing = false});

  final McpServerStatus status;

  /// A full re-check runs; [status] is the previous result until it ends.
  final bool isRefreshing;

  @override
  List<Object?> get props => [status, isRefreshing];
}

final class McpStatusFailure extends McpStatusState {
  const McpStatusFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
