import 'package:get_it/get_it.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';

/// Registers macOS Menu Bar companion cubit.
void registerMenuBarDependencies(GetIt sl) {
  sl.registerLazySingleton<MenuBarCubit>(() => MenuBarCubit());
}
