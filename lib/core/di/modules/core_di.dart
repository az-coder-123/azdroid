import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/adb_tcpip_service.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:get_it/get_it.dart';

/// Registers core infrastructure services and process runners.
void registerCoreDependencies(GetIt sl) {
  sl.registerLazySingleton<ProcessExecutor>(
    () => const DefaultProcessExecutor(),
  );

  sl.registerLazySingleton<NetworkInfoService>(() => NetworkInfoServiceImpl());

  sl.registerLazySingleton<AdbService>(
    () => AdbService(
      processExecutor: sl<ProcessExecutor>(),
      pathResolver: AdbPathResolver(
        executor: sl<ProcessExecutor>(),
        toolchain: sl<HostToolchain>(),
      ),
    ),
  );

  sl.registerLazySingleton<AdbTcpipService>(
    () => AdbTcpipService(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<DeviceHistoryService>(
    () => DeviceHistoryServiceImpl(hostPaths: sl<HostPaths>()),
  );

  // One control socket per mirroring session, shared by streaming (opens and
  // closes it) and control (sends input through it).
  sl.registerLazySingleton<ScrcpyControlChannel>(
    SocketScrcpyControlChannel.new,
    dispose: (channel) => channel.close(),
  );
  // Native audio player: opened by streaming, controlled by audio.
  sl.registerLazySingleton<IAudioStreamNativeService>(
    AudioStreamNativeService.new,
  );
}
