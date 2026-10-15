import 'package:equatable/equatable.dart';
import 'package:desk_droid/features/productivity/domain/entities/clipboard_item_entity.dart';

/// Base state for clipboard synchronization.
sealed class ClipboardState extends Equatable {
  const ClipboardState({this.autoSyncEnabled = true});

  final bool autoSyncEnabled;

  @override
  List<Object?> get props => [autoSyncEnabled];
}

/// Initial uninitialized state.
class ClipboardInitial extends ClipboardState {
  const ClipboardInitial({super.autoSyncEnabled = true});
}

/// State emitted while active sync is underway.
class ClipboardSyncing extends ClipboardState {
  const ClipboardSyncing({required this.direction, super.autoSyncEnabled});

  final String direction;

  @override
  List<Object?> get props => [...super.props, direction];
}

/// State emitted when text has successfully synced.
class ClipboardSynced extends ClipboardState {
  const ClipboardSynced({required this.lastItem, super.autoSyncEnabled});

  final ClipboardItemEntity lastItem;

  @override
  List<Object?> get props => [...super.props, lastItem];
}

/// State emitted upon sync failure.
class ClipboardError extends ClipboardState {
  const ClipboardError({required this.errorMessage, super.autoSyncEnabled});

  final String errorMessage;

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
