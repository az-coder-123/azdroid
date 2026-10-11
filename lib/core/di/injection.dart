import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/control/data/datasources/control_datasource.dart';
import 'package:wifi_desk/features/control/data/repositories/control_repository_impl.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/pairing_cubit.dart';
import 'package:wifi_desk/features/streaming/data/datasources/scrcpy_server_manager.dart';
import 'package:wifi_desk/features/streaming/data/datasources/streaming_socket_datasource.dart';
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

  sl.registerLazySingleton<AdbService>(
    () => AdbService(processExecutor: sl<ProcessExecutor>()),
  );

  // Discovery data sources & repositories
  sl.registerLazySingleton<DeviceDiscoveryDatasource>(
    () => DeviceDiscoveryDatasourceImpl(adbService: sl<AdbService>()),
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

  sl.registerLazySingleton<StreamingSocketDatasource>(
    () => StreamingSocketDatasourceImpl(),
  );

  sl.registerLazySingleton<StreamingRepository>(
    () => StreamingRepositoryImpl(
      serverManager: sl<ScrcpyServerManager>(),
      socketDatasource: sl<StreamingSocketDatasource>(),
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

  // Cubits & Blocs (Factory registrations so each consumer receives a fresh instance)
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(repository: sl<DeviceDiscoveryRepository>()),
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
}
