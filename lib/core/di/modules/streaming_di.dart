import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/adb_port_forwarder.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_jar_locator.dart';
import 'package:desk_droid/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers display streaming data sources, repositories, and cubits.
void registerStreamingDependencies(GetIt sl) {
  sl.registerLazySingleton<ScrcpyServerManager>(
    () => ScrcpyServerManager(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
      jarLocator: ScrcpyServerJarLocator(hostPaths: sl<HostPaths>()),
    ),
  );
  // Shared tunnel manager exposed to other features through a core contract.
  sl.registerLazySingleton<AdbPortForwarder>(() => sl<ScrcpyServerManager>());

  sl.registerLazySingleton<IVideoStreamNativeService>(
    () => VideoStreamNativeService(),
  );

  sl.registerLazySingleton<StreamingRepository>(
    () => StreamingRepositoryImpl(
      serverManager: sl<ScrcpyServerManager>(),
      videoStreamNativeService: sl<IVideoStreamNativeService>(),
    ),
  );

  sl.registerFactory<StreamingCubit>(
    () => StreamingCubit(repository: sl<StreamingRepository>()),
  );
}
