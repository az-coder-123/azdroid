import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_metadata_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/repositories/apk_installer_repository_impl.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers APK installer data sources, repositories, and cubits.
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

  // The cubit is scoped to one device, passed as the factory parameter.
  sl.registerFactoryParam<ApkInstallerCubit, String, void>(
    (deviceSerial, _) => ApkInstallerCubit(
      repository: sl<ApkInstallerRepository>(),
      deviceSerial: deviceSerial,
    ),
  );
}
