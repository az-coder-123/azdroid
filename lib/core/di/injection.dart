import 'package:get_it/get_it.dart';
import 'package:wifi_desk/features/discovery/data/datasources/device_discovery_datasource.dart';
import 'package:wifi_desk/features/discovery/data/repositories/device_discovery_repository_impl.dart';
import 'package:wifi_desk/features/discovery/domain/repositories/device_discovery_repository.dart';
import 'package:wifi_desk/features/discovery/presentation/cubit/discovery_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Configures and registers all application dependencies.
Future<void> initDependencies() async {
  // Data sources
  sl.registerLazySingleton<DeviceDiscoveryDatasource>(
    () => const DeviceDiscoveryDatasourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<DeviceDiscoveryRepository>(
    () => DeviceDiscoveryRepositoryImpl(datasource: sl()),
  );

  // Cubits & Blocs (Factory registrations so each consumer receives a fresh instance)
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(repository: sl()),
  );
}
