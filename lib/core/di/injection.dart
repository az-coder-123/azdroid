import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/core/services/device_history_service.dart';
import 'package:wifi_desk/core/services/mac_file_picker_service.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/core/services/video_stream_native_service.dart';
import 'package:wifi_desk/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:wifi_desk/features/apk_installer/data/datasources/apk_metadata_datasource.dart';
import 'package:wifi_desk/features/apk_installer/data/repositories/apk_installer_repository_impl.dart';
import 'package:wifi_desk/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:wifi_desk/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:wifi_desk/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:wifi_desk/features/audio/domain/repositories/audio_repository.dart';
import 'package:wifi_desk/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:wifi_desk/features/control/data/datasources/control_datasource.dart';
import 'package:wifi_desk/features/control/data/repositories/control_repository_impl.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/data/datasources/network_subnet_scanner.dart';
import 'package:wifi_desk/features/discovery/data/services/usb_wifi_auto_handoff_service.dart';
import 'package:wifi_desk/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/logging/data/datasources/log_file_recorder.dart';
import 'package:wifi_desk/features/logging/data/datasources/logcat_stream_datasource.dart';
import 'package:wifi_desk/features/logging/data/models/logcat_threadtime_parser.dart';
import 'package:wifi_desk/features/logging/data/repositories/device_log_repository_impl.dart';
import 'package:wifi_desk/features/logging/domain/repositories/device_log_repository.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';
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
import 'package:wifi_desk/features/productivity/presentation/cubit/device_file_manager_cubit.dart';
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

  sl.registerLazySingleton<MacFilePickerService>(
    () => MacFilePickerServiceImpl(processExecutor: sl<ProcessExecutor>()),
  );

  // Discovery data sources & repositories
  sl.registerLazySingleton<NetworkSubnetScanner>(
    () => NetworkSubnetScannerImpl(
      networkInfoService: sl<NetworkInfoService>(),
      historyService: sl<DeviceHistoryService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<UsbWifiAutoHandoffService>(
    () => UsbWifiAutoHandoffServiceImpl(adbTcpipService: sl<AdbTcpipService>()),
  );

  sl.registerLazySingleton<DeviceDiscoveryDatasource>(
    () => DeviceDiscoveryDatasourceImpl(
      adbService: sl<AdbService>(),
      adbTcpipService: sl<AdbTcpipService>(),
      subnetScanner: sl<NetworkSubnetScanner>(),
      autoHandoffService: sl<UsbWifiAutoHandoffService>(),
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

  // Logging data sources & repositories
  sl.registerLazySingleton<LogcatStreamDatasource>(
    () => LogcatStreamDatasource(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<LogFileRecorder>(() => LogFileRecorder());
  sl.registerLazySingleton<LogcatThreadtimeParser>(
    () => const LogcatThreadtimeParser(),
  );

  sl.registerLazySingleton<DeviceLogRepository>(
    () => DeviceLogRepositoryImpl(
      datasource: sl<LogcatStreamDatasource>(),
      fileRecorder: sl<LogFileRecorder>(),
      parser: sl<LogcatThreadtimeParser>(),
    ),
  );

  // APK Installer services & repository
  sl.registerLazySingleton<ApkMetadataDatasource>(
    () => ApkMetadataDatasourceImpl(processExecutor: sl<ProcessExecutor>()),
  );

  sl.registerLazySingleton<ApkInstallerDatasource>(
    () => ApkInstallerDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ApkInstallerRepository>(
    () => ApkInstallerRepositoryImpl(
      metadataDatasource: sl<ApkMetadataDatasource>(),
      installerDatasource: sl<ApkInstallerDatasource>(),
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

  sl.registerFactory<DeviceFileManagerCubit>(
    () => DeviceFileManagerCubit(
      repository: sl<FileTransferRepository>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
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

  sl.registerFactory<DeviceLogCubit>(
    () => DeviceLogCubit(repository: sl<DeviceLogRepository>()),
  );
}
