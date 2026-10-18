import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:desk_droid/features/streaming/data/repositories/file_mirroring_preferences_repository.dart';
import 'package:desk_droid/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_control_connector.dart';
import 'package:desk_droid/features/streaming/data/services/scrcpy_server_jar_locator.dart';
import 'package:desk_droid/features/streaming/data/services/stream_device_preflight.dart';
import 'package:desk_droid/features/streaming/data/services/stream_telemetry_sampler.dart';
import 'package:desk_droid/features/streaming/domain/repositories/mirroring_preferences_repository.dart';
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

  sl.registerLazySingleton<IVideoStreamNativeService>(
    () => VideoStreamNativeService(),
  );

  sl.registerLazySingleton<StreamingRepository>(
    () => StreamingRepositoryImpl(
      serverManager: sl<ScrcpyServerManager>(),
      videoStreamNativeService: sl<IVideoStreamNativeService>(),
      devicePreflight: StreamDevicePreflight(adbService: sl<AdbService>()),
      telemetrySampler: StreamTelemetrySampler(
        nativeService: sl<IVideoStreamNativeService>(),
      ),
      controlConnector: ScrcpyControlConnector(
        nativeService: sl<IVideoStreamNativeService>(),
        channel: sl<ScrcpyControlChannel>(),
      ),
      audioService: sl<IAudioStreamNativeService>(),
    ),
  );

  sl.registerLazySingleton<MirroringPreferencesRepository>(
    () => FileMirroringPreferencesRepository(hostPaths: sl<HostPaths>()),
  );

  sl.registerFactory<StreamingCubit>(
    () => StreamingCubit(
      repository: sl<StreamingRepository>(),
      preferences: sl<MirroringPreferencesRepository>(),
    ),
  );
}
