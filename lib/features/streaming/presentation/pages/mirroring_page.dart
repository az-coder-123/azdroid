import 'package:desk_droid/core/di/injection.dart';
import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-window macOS mirroring page hosting the low-latency display viewport,
/// remote input translation, Finder drag-and-drop, audio forwarding, and clipboard sync.
class MirroringPage extends StatelessWidget {
  const MirroringPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StreamingCubit>(
          create: (_) => sl<StreamingCubit>()..startSession(device),
        ),
        BlocProvider<ControlBloc>(create: (_) => sl<ControlBloc>()),
        BlocProvider<ClipboardCubit>(
          create: (_) => sl<ClipboardCubit>()..startPeriodicSync(device.serial),
        ),
        BlocProvider<FileTransferCubit>(create: (_) => sl<FileTransferCubit>()),
        BlocProvider<AudioCubit>(
          create: (_) => sl<AudioCubit>()..watchPlayback(),
        ),
        BlocProvider<ScreenshotCubit>(create: (_) => sl<ScreenshotCubit>()),
        BlocProvider<ScreenRecordingCubit>(
          create: (_) => sl<ScreenRecordingCubit>(),
        ),
      ],
      child: MirroringView(device: device),
    );
  }
}
