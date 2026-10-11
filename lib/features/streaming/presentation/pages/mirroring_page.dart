import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/core/theme/app_typography.dart';
import 'package:wifi_desk/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/control/presentation/widgets/input_gesture_viewport_overlay.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/file_drop_target_overlay.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/transfer_status_banner.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/floating_controls_toolbar.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/stream_telemetry_header.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/video_display_viewport.dart';

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
          create: (_) => sl<AudioCubit>()..startAudio(device.serial),
        ),
      ],
      child: _MirroringView(device: device),
    );
  }
}

class _MirroringView extends StatelessWidget {
  const _MirroringView({required this.device});

  final DeviceEntity device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<StreamingCubit, StreamingState>(
        listener: (context, state) {
          if (state is StreamingActive) {
            sl<MenuBarCubit>().updateActiveSession(
              deviceName: state.session.deviceName,
              latencyMs: state.session.latencyMs,
              fps: state.session.fps,
            );
          } else if (state is StreamingInitial) {
            sl<MenuBarCubit>().clearActiveSession();
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          if (state is StreamingStarting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 20),
                  Text(
                    'Starting Display Stream on ${device.name}...',
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Initializing hardware video decoder & tunneling sockets...',
                    style: AppTypography.subtitle,
                  ),
                ],
              ),
            );
          }

          if (state is StreamingError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.statusError,
                      size: 54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Devices'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<StreamingCubit>()
                              .startSession(device),
                          child: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StreamingActive) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Video Frame Viewport with Drag-and-Drop and Remote Input
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 60.0,
                  ),
                  child: FileDropTargetOverlay(
                    deviceSerial: device.serial,
                    child: InputGestureViewportOverlay(
                      deviceSerial: device.serial,
                      child: VideoDisplayViewport(
                        session: state.session,
                        rotationDegrees: state.rotationDegrees,
                      ),
                    ),
                  ),
                ),

                // Top Telemetry Header
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: StreamTelemetryHeader(
                      session: state.session,
                      onClose: () {
                        context.read<StreamingCubit>().stopSession();
                      },
                    ),
                  ),
                ),

                // Top-Right Transfer Notification Banner
                const Positioned(
                  top: 16,
                  right: 16,
                  child: TransferStatusBanner(),
                ),

                // Bottom Floating Controls Toolbar
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingControlsToolbar(
                      session: state.session,
                      deviceSerial: device.serial,
                      onBack: () => context.read<StreamingCubit>().sendBack(),
                      onHome: () => context.read<StreamingCubit>().sendHome(),
                      onAppSwitch: () =>
                          context.read<StreamingCubit>().sendAppSwitch(),
                      onRotate: () =>
                          context.read<StreamingCubit>().rotateScreen(),
                      onToggleScreenOff: () =>
                          context.read<StreamingCubit>().toggleScreenOff(),
                      onSelectBitrate: (bitrate) =>
                          context.read<StreamingCubit>().updateBitrate(bitrate),
                      onTextInject: () =>
                          QuickTextInputDialog.show(context, device.serial),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
