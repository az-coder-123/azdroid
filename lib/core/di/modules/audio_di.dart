import 'package:desk_droid/core/services/adb_port_forwarder.dart';
import 'package:desk_droid/features/audio/data/datasources/audio_socket_datasource.dart';
import 'package:desk_droid/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers audio streaming data sources, repositories, and cubits.
void registerAudioDependencies(GetIt sl) {
  sl.registerLazySingleton<AudioSocketDatasource>(
    AudioSocketDatasourceImpl.new,
    dispose: (datasource) => datasource.dispose(),
  );

  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(
      portForwarder: sl<AdbPortForwarder>(),
      socketDatasource: sl<AudioSocketDatasource>(),
    ),
  );

  sl.registerFactory<AudioCubit>(
    () => AudioCubit(repository: sl<AudioRepository>()),
  );
}
