import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/logging/data/datasources/log_file_recorder.dart';
import 'package:wifi_desk/features/logging/data/datasources/logcat_stream_datasource.dart';
import 'package:wifi_desk/features/logging/data/models/logcat_threadtime_parser.dart';
import 'package:wifi_desk/features/logging/data/repositories/device_log_repository_impl.dart';
import 'package:wifi_desk/features/logging/domain/repositories/device_log_repository.dart';
import 'package:wifi_desk/features/logging/presentation/cubit/device_log_cubit.dart';

/// Registers logcat streaming data sources, repositories, and cubits.
void registerLoggingDependencies(GetIt sl) {
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

  sl.registerFactory<DeviceLogCubit>(
    () => DeviceLogCubit(repository: sl<DeviceLogRepository>()),
  );
}
