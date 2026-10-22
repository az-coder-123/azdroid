import 'package:desk_droid/core/platform/file_launcher/host_file_launcher.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/features/updater/data/datasources/update_remote_data_source.dart';
import 'package:desk_droid/features/updater/data/repositories/update_repository_impl.dart';
import 'package:desk_droid/features/updater/domain/repositories/update_repository.dart';
import 'package:desk_droid/features/updater/presentation/cubit/updater_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers updater contracts, remote data source, repository, and presentation Cubit.
void registerUpdaterDependencies(GetIt sl) {
  sl.registerLazySingleton<UpdateRemoteDataSource>(
    () => GithubUpdateRemoteDataSource(),
  );

  sl.registerLazySingleton<UpdateRepository>(
    () => UpdateRepositoryImpl(
      remoteDataSource: sl<UpdateRemoteDataSource>(),
      hostOs: sl<HostOs>(),
    ),
  );

  sl.registerFactory<UpdaterCubit>(
    () => UpdaterCubit(
      updateRepository: sl<UpdateRepository>(),
      fileLauncher: sl<HostFileLauncher>(),
    ),
  );
}
