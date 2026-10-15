import 'package:get_it/get_it.dart';
import 'package:desk_droid/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:desk_droid/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/streaming/data/datasources/scrcpy_server_manager.dart';

/// Registers audio streaming data sources, repositories, and cubits.
void registerAudioDependencies(GetIt sl) {
  sl.registerLazySingleton<AudioSocketDatasource>(
    () => AudioSocketDatasourceImpl(),
  );

  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(
      serverManager: sl<ScrcpyServerManager>(),
      socketDatasource: sl<AudioSocketDatasource>(),
    ),
  );

  sl.registerFactory<AudioCubit>(
    () => AudioCubit(repository: sl<AudioRepository>()),
  );
}
