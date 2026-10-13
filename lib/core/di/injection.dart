import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/core/services/device_history_service.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/core/services/video_stream_native_service.dart';
import 'package:wifi_desk/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:wifi_desk/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:wifi_desk/features/audio/domain/repositories/audio_repository.dart';
import 'package:wifi_desk/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:wifi_desk/features/control/data/datasources/control_datasource.dart';
import 'package:wifi_desk/features/control/data/repositories/control_repository_impl.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:wifi_desk/features/productivity/data/datasources/clipboard_datasource.dart';
import 'package:wifi_desk/features/productivity/data/datasources/file_transfer_datasource.dart';
import 'package:wifi_desk/features/productivity/data/datasources/screen_recording_datasource.dart';
import 'package:wifi_desk/features/productivity/data/datasources/screenshot_datasource.dart';
import 'package:wifi_desk/features/productivity/data/repositories/clipboard_repository_impl.dart';
import 'package:wifi_desk/features/productivity/data/repositories/file_transfer_repository_impl.dart';
import 'package:wifi_desk/features/productivity/data/repositories/screen_recording_repository_impl.dart';
import 'package:wifi_desk/features/productivity/data/repositories/screenshot_repository_impl.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:wifi_desk/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:wifi_desk/features/streaming/data/repositories/streaming_repository_impl.dart';
import 'package:wifi_desk/features/streaming/domain/repositories/streaming_repository.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Configures and registers all application dependencies.
Future<void> initDependencies() async {
  // Core infrastructure & system process services
  sl.registerLazySingleton<ProcessExecutor>(
    () => const DefaultProcessExecutor(),
  );

  sl.registerLazySingleton<NetworkInfoService>(() => NetworkInfoServiceImpl());

  sl.registerLazySingleton<AdbService>(
    () => AdbService(processExecutor: sl<ProcessExecutor>()),
  );

  sl.registerLazySingleton<AdbTcpipService>(
    () => AdbTcpipService(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<DeviceHistoryService>(
    () => DeviceHistoryServiceImpl(),
  );

  // Discovery data sources & repositories
  sl.registerLazySingleton<DeviceDiscoveryDatasource>(
    () => DeviceDiscoveryDatasourceImpl(
      adbService: sl<AdbService>(),
      adbTcpipService: sl<AdbTcpipService>(),
    ),
  );

  sl.registerLazySingleton<DeviceDiscoveryRepository>(
    () => DeviceDiscoveryRepositoryImpl(
      datasource: sl<DeviceDiscoveryDatasource>(),
    ),
  );

  // Streaming data sources & repositories
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

  // Control data sources & repositories
  sl.registerLazySingleton<ControlDatasource>(
    () => ControlDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ControlRepository>(
    () => ControlRepositoryImpl(datasource: sl<ControlDatasource>()),
  );

  // Productivity data sources & repositories
  sl.registerLazySingleton<ClipboardDatasource>(
    () => ClipboardDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ClipboardRepository>(
    () => ClipboardRepositoryImpl(datasource: sl<ClipboardDatasource>()),
  );

  sl.registerLazySingleton<FileTransferDatasource>(
    () => FileTransferDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<FileTransferRepository>(
    () => FileTransferRepositoryImpl(datasource: sl<FileTransferDatasource>()),
  );

  sl.registerLazySingleton<ScreenshotDatasource>(
    () => ScreenshotDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ScreenshotRepository>(
    () => ScreenshotRepositoryImpl(datasource: sl<ScreenshotDatasource>()),
  );

  sl.registerLazySingleton<ScreenRecordingDatasource>(
    () => ScreenRecordingDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ScreenRecordingRepository>(
    () => ScreenRecordingRepositoryImpl(
      datasource: sl<ScreenRecordingDatasource>(),
    ),
  );

  // Audio data sources & repositories
  sl.registerLazySingleton<AudioSocketDatasource>(
    () => AudioSocketDatasourceImpl(),
  );

  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(
      serverManager: sl<ScrcpyServerManager>(),
      socketDatasource: sl<AudioSocketDatasource>(),
    ),
  );

  // Menu Bar companion service
  sl.registerLazySingleton<MenuBarCubit>(() => MenuBarCubit());

  // Cubits & Blocs (Factory registrations so each consumer receives a fresh instance)
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      repository: sl<DeviceDiscoveryRepository>(),
      historyService: sl<DeviceHistoryService>(),
    ),
  );

  sl.registerFactory<PairingCubit>(
    () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
  );

  sl.registerFactory<StreamingCubit>(
    () => StreamingCubit(repository: sl<StreamingRepository>()),
  );

  sl.registerFactory<ControlBloc>(
    () => ControlBloc(repository: sl<ControlRepository>()),
  );

  sl.registerFactory<ClipboardCubit>(
    () => ClipboardCubit(repository: sl<ClipboardRepository>()),
  );

  sl.registerFactory<FileTransferCubit>(
    () => FileTransferCubit(repository: sl<FileTransferRepository>()),
  );

  sl.registerFactory<AudioCubit>(
    () => AudioCubit(repository: sl<AudioRepository>()),
  );

  sl.registerFactory<ScreenshotCubit>(
    () => ScreenshotCubit(repository: sl<ScreenshotRepository>()),
  );

  sl.registerFactory<ScreenRecordingCubit>(
    () => ScreenRecordingCubit(repository: sl<ScreenRecordingRepository>()),
  );
}
