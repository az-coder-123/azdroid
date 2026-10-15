import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/core/services/device_history_service.dart';
import 'package:wifi_desk/core/services/mac_file_picker_service.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';

/// Registers core infrastructure services and process runners.
void registerCoreDependencies(GetIt sl) {
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
}
