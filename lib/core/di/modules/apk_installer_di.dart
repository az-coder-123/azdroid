import 'package:desk_droid/core/platform/file_picker/host_file_picker.dart';
import 'package:desk_droid/core/platform/host_toolchain.dart';
import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_installer_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/datasources/apk_metadata_datasource.dart';
import 'package:desk_droid/features/apk_installer/data/repositories/apk_installer_repository_impl.dart';
import 'package:desk_droid/features/apk_installer/data/services/aapt_path_resolver.dart';
import 'package:desk_droid/features/apk_installer/domain/repositories/apk_installer_repository.dart';
import 'package:desk_droid/features/apk_installer/presentation/cubit/apk_installer_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers APK installer data sources, repositories, and cubits.
void registerApkInstallerDependencies(GetIt sl) {
  sl.registerLazySingleton<ApkMetadataDatasource>(
    () => ApkMetadataDatasourceImpl(
      processExecutor: sl<ProcessExecutor>(),
      aaptResolver: AaptPathResolver(
        processExecutor: sl<ProcessExecutor>(),
        toolchain: sl<HostToolchain>(),
      ),
    ),
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
      filePicker: sl<HostFilePicker>(),
    ),
  );
}
