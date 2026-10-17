import 'dart:io';

import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_launcher/mac_host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_launcher/windows_host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/platform/image_clipboard/mac_image_clipboard.dart';
import 'package:desk_droid/core/platform/image_clipboard/windows_image_clipboard.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:get_it/get_it.dart';

/// Registers host-platform services. This is the only place that decides
/// which OS implementation is used; everything else depends on contracts.
void registerPlatformDependencies(GetIt sl, {HostOs? os}) {
  final hostOs = os ?? HostOs.current;
  sl.registerSingleton<HostOs>(hostOs);

  sl.registerSingleton<ShortcutScheme>(ShortcutScheme.forOs(hostOs));

  sl.registerLazySingleton<HostPaths>(() => SystemHostPaths(os: hostOs));

  sl.registerLazySingleton<HostToolchain>(
    () => HostToolchain.forHost(
      os: hostOs,
      paths: sl<HostPaths>(),
      environment: Platform.environment,
    ),
  );

  // Cross-platform plugin: one implementation for every OS.
  sl.registerLazySingleton<HostFilePicker>(
    () => const FileSelectorHostFilePicker(),
  );

  // Strategy selection: one switch per OS-specific behavior, nowhere else.
  sl.registerLazySingleton<HostFileLauncher>(
    () => switch (hostOs) {
      HostOs.windows => WindowsHostFileLauncher(
        processExecutor: sl<ProcessExecutor>(),
      ),
      HostOs.macos || HostOs.linux => MacHostFileLauncher(
        processExecutor: sl<ProcessExecutor>(),
      ),
    },
  );

  sl.registerLazySingleton<ImageClipboard>(
    () => switch (hostOs) {
      HostOs.windows => WindowsImageClipboard(
        processExecutor: sl<ProcessExecutor>(),
      ),
      HostOs.macos ||
      HostOs.linux => MacImageClipboard(processExecutor: sl<ProcessExecutor>()),
    },
  );
}
