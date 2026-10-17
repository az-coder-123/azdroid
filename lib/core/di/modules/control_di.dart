import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/repositories/control_repository_impl.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:get_it/get_it.dart';

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
