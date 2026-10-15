import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/core/services/video_stream_native_service.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:wifi_desk/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:wifi_desk/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';

/// Registers display streaming data sources, repositories, and cubits.
void registerStreamingDependencies(GetIt sl) {
  sl.registerLazySingleton<ScrcpyServerManager>(
    () => ScrcpyServerManager(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

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
