import 'package:equatable/equatable.dart';
import 'package:desk_droid/features/menubar/domain/entities/menu_bar_status_entity.dart';

/// State for the macOS Menu Bar companion tray item.
class MenuBarState extends Equatable {
  const MenuBarState({this.status = const MenuBarStatusEntity()});

  final MenuBarStatusEntity status;

  MenuBarState copyWith({MenuBarStatusEntity? status}) {
    return MenuBarState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
