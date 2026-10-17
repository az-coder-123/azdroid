import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/adb_tcpip_service.dart';
import 'package:desk_droid/core/services/device_history_service.dart';
import 'package:desk_droid/core/services/network_info_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:desk_droid/features/discovery/data/datasources/network_subnet_scanner.dart';
import 'package:desk_droid/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:desk_droid/features/discovery/data/services/usb_wifi_auto_handoff_service.dart';
import 'package:desk_droid/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/host_context_cubit.dart';
import 'package:desk_droid/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers discovery and wireless pairing data sources, repositories, and cubits.
void registerDiscoveryDependencies(GetIt sl) {
  sl.registerLazySingleton<NetworkSubnetScanner>(
    () => NetworkSubnetScannerImpl(
      networkInfoService: sl<NetworkInfoService>(),
      historyService: sl<DeviceHistoryService>(),
      processExecutor: sl<ProcessExecutor>(),
      toolchain: sl<HostToolchain>(),
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

  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      repository: sl<DeviceDiscoveryRepository>(),
      historyService: sl<DeviceHistoryService>(),
    ),
  );

  sl.registerFactory<HostContextCubit>(
    () => HostContextCubit(
      networkInfoService: sl<NetworkInfoService>(),
      historyService: sl<DeviceHistoryService>(),
    ),
  );

  sl.registerFactory<PairingCubit>(
    () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
  );
}
