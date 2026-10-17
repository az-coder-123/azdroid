import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:desk_droid/core/platform/host_paths.dart';
import 'package:desk_droid/core/platform/image_clipboard/image_clipboard.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/productivity/data/datasources/clipboard_datasource.dart';
import 'package:desk_droid/features/productivity/data/datasources/file_transfer_datasource.dart';
import 'package:desk_droid/features/productivity/data/datasources/screen_recording_datasource.dart';
import 'package:desk_droid/features/productivity/data/datasources/screenshot_datasource.dart';
import 'package:desk_droid/features/productivity/data/repositories/clipboard_repository_impl.dart';
import 'package:desk_droid/features/productivity/data/repositories/file_transfer_repository_impl.dart';
import 'package:desk_droid/features/productivity/data/repositories/screen_recording_repository_impl.dart';
import 'package:desk_droid/features/productivity/data/repositories/screenshot_repository_impl.dart';
import 'package:desk_droid/features/productivity/domain/repositories/clipboard_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/file_transfer_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screen_recording_repository.dart';
import 'package:desk_droid/features/productivity/domain/repositories/screenshot_repository.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/device_file_manager_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers productivity tools (clipboard, files, screenshots, recording) dependencies.
void registerProductivityDependencies(GetIt sl) {
  // Clipboard
  sl.registerLazySingleton<ClipboardDatasource>(
    () => ClipboardDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );
  sl.registerLazySingleton<ClipboardRepository>(
    () => ClipboardRepositoryImpl(datasource: sl<ClipboardDatasource>()),
  );
  sl.registerFactory<ClipboardCubit>(
    () => ClipboardCubit(repository: sl<ClipboardRepository>()),
  );

  // File Transfer & Explorer
  sl.registerLazySingleton<FileTransferDatasource>(
    () => FileTransferDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );
  sl.registerLazySingleton<FileTransferRepository>(
    () => FileTransferRepositoryImpl(datasource: sl<FileTransferDatasource>()),
  );
  sl.registerFactory<FileTransferCubit>(
    () => FileTransferCubit(
      repository: sl<FileTransferRepository>(),
      filePicker: sl<HostFilePicker>(),
    ),
  );
  sl.registerFactory<DeviceFileManagerCubit>(
    () => DeviceFileManagerCubit(
      repository: sl<FileTransferRepository>(),
      hostPaths: sl<HostPaths>(),
      fileLauncher: sl<HostFileLauncher>(),
    ),
  );

  // Screenshots
  sl.registerLazySingleton<ScreenshotDatasource>(
    () => ScreenshotDatasourceImpl(
      adbService: sl<AdbService>(),
      hostPaths: sl<HostPaths>(),
      imageClipboard: sl<ImageClipboard>(),
    ),
  );
  sl.registerLazySingleton<ScreenshotRepository>(
    () => ScreenshotRepositoryImpl(datasource: sl<ScreenshotDatasource>()),
  );
  sl.registerFactory<ScreenshotCubit>(
    () => ScreenshotCubit(
      repository: sl<ScreenshotRepository>(),
      fileLauncher: sl<HostFileLauncher>(),
    ),
  );

  // Screen Recording
  sl.registerLazySingleton<ScreenRecordingDatasource>(
    () => ScreenRecordingDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
      hostPaths: sl<HostPaths>(),
    ),
  );
  sl.registerLazySingleton<ScreenRecordingRepository>(
    () => ScreenRecordingRepositoryImpl(
      datasource: sl<ScreenRecordingDatasource>(),
    ),
  );
  sl.registerFactory<ScreenRecordingCubit>(
    () => ScreenRecordingCubit(
      repository: sl<ScreenRecordingRepository>(),
      fileLauncher: sl<HostFileLauncher>(),
    ),
  );
}
