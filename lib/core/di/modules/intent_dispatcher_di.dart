import 'package:get_it/get_it.dart';
import 'package:wifi_desk/core/services/adb_service.dart';
import 'package:wifi_desk/core/services/process_executor.dart';
import 'package:wifi_desk/features/intent_dispatcher/data/datasources/intent_datasource.dart';
import 'package:wifi_desk/features/intent_dispatcher/data/repositories/intent_repository_impl.dart';
import 'package:wifi_desk/features/intent_dispatcher/domain/repositories/intent_repository.dart';

/// Registers Intent Dispatcher data sources and repositories.
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
}
