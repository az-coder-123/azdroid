import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/adb_tcpip_service.dart';
import 'package:wifi_desk/core/services/device_history_service.dart';
import 'package:wifi_desk/core/services/network_info_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/data/datasources/network_subnet_scanner.dart';
import 'package:wifi_desk/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:wifi_desk/features/discovery/data/services/usb_wifi_auto_handoff_service.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';

/// Registers discovery and wireless pairing data sources, repositories, and cubits.
void registerDiscoveryDependencies(GetIt sl) {
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

  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      repository: sl<DeviceDiscoveryRepository>(),
      historyService: sl<DeviceHistoryService>(),
    ),
  );

  sl.registerFactory<PairingCubit>(
    () => PairingCubit(repository: sl<DeviceDiscoveryRepository>()),
  );
}
