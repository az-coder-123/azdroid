import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/intent_dispatcher/data/datasources/intent_datasource.dart';
import 'package:desk_droid/features/intent_dispatcher/data/repositories/intent_repository_impl.dart';
import 'package:desk_droid/features/intent_dispatcher/domain/repositories/intent_repository.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/cubit/intent_dispatcher_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers Intent Dispatcher data sources, repositories, and cubits.
void registerIntentDispatcherDependencies(GetIt sl) {
  sl.registerLazySingleton<IntentDatasource>(
    () => IntentDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<IntentRepository>(
    () => IntentRepositoryImpl(datasource: sl<IntentDatasource>()),
  );

  sl.registerFactory<IntentDispatcherCubit>(
    () => IntentDispatcherCubit(repository: sl<IntentRepository>()),
  );
}
