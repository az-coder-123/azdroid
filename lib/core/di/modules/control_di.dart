import 'package:desk_droid/core/services/adb_service.dart';
import 'package:desk_droid/core/services/process_executor.dart';
import 'package:desk_droid/core/services/scrcpy_control_channel.dart';
import 'package:desk_droid/core/services/video_stream_native_service.dart';
import 'package:desk_droid/features/control/data/datasources/control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/fallback_control_datasource.dart';
import 'package:desk_droid/features/control/data/datasources/scrcpy_control_datasource.dart';
import 'package:desk_droid/features/control/data/repositories/control_repository_impl.dart';
import 'package:desk_droid/features/control/data/services/native_video_frame_size_source.dart';
import 'package:desk_droid/features/control/domain/repositories/control_repository.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:get_it/get_it.dart';

/// Registers input control data sources, repositories, and BLoCs.
void registerControlDependencies(GetIt sl) {
  // Input goes through the scrcpy control socket while mirroring, and
  // through `adb shell input` otherwise (and for text).
  sl.registerLazySingleton<ControlDatasource>(
    () => FallbackControlDatasource(
      primary: ScrcpyControlDatasource(channel: sl<ScrcpyControlChannel>()),
      fallback: ControlDatasourceImpl(
        adbService: sl<AdbService>(),
        processExecutor: sl<ProcessExecutor>(),
      ),
    ),
  );

  sl.registerLazySingleton<ControlRepository>(
    () => ControlRepositoryImpl(
      datasource: sl<ControlDatasource>(),
      frameSizeSource: NativeVideoFrameSizeSource(
        sl<IVideoStreamNativeService>(),
      ),
    ),
  );

  sl.registerFactory<ControlBloc>(
    () => ControlBloc(repository: sl<ControlRepository>()),
  );
}
