import 'package:desk_droid/core/services/audio_stream_native_service.dart';
import 'package:desk_droid/features/audio/data/repositories/audio_repository_impl.dart';
import 'package:desk_droid/features/audio/domain/repositories/audio_repository.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:get_it/get_it.dart';

/// Registers audio playback controls. The native player itself is a core
/// service shared with streaming (core_di).
void registerAudioDependencies(GetIt sl) {
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(native: sl<IAudioStreamNativeService>()),
  );

  sl.registerFactory<AudioCubit>(
    () => AudioCubit(repository: sl<AudioRepository>()),
  );
}
