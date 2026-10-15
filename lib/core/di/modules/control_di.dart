import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/control/data/datasources/control_datasource.dart';
import 'package:wifi_desk/features/control/data/repositories/control_repository_impl.dart';
import 'package:wifi_desk/features/control/domain/repositories/control_repository.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';

/// Registers input control data sources, repositories, and BLoCs.
void registerControlDependencies(GetIt sl) {
  sl.registerLazySingleton<ControlDatasource>(
    () => ControlDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ControlRepository>(
    () => ControlRepositoryImpl(datasource: sl<ControlDatasource>()),
  );

  sl.registerFactory<ControlBloc>(
    () => ControlBloc(repository: sl<ControlRepository>()),
  );
}
