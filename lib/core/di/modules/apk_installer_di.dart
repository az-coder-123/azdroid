import 'package:get_it/get_it.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_metadata_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/repositories/apk_installer_repository_impl.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';

/// Registers APK installer inspection, installation data sources, and repositories.
void registerApkInstallerDependencies(GetIt sl) {
  sl.registerLazySingleton<ApkMetadataDatasource>(
    () => ApkMetadataDatasourceImpl(processExecutor: sl<ProcessExecutor>()),
  );

  sl.registerLazySingleton<ApkInstallerDatasource>(
    () => ApkInstallerDatasourceImpl(
      adbService: sl<AdbService>(),
      processExecutor: sl<ProcessExecutor>(),
    ),
  );

  sl.registerLazySingleton<ApkInstallerRepository>(
    () => ApkInstallerRepositoryImpl(
      metadataDatasource: sl<ApkMetadataDatasource>(),
      installerDatasource: sl<ApkInstallerDatasource>(),
    ),
  );
}
