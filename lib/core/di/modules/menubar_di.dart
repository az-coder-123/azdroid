import 'package:get_it/get_it.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';

/// Registers macOS Menu Bar companion cubit.
void registerMenuBarDependencies(GetIt sl) {
  sl.registerLazySingleton<MenuBarCubit>(() => MenuBarCubit());
}
