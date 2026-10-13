import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/features/discovery/domain/entities/device_entity.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:wifi_desk/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/mirroring_active_view.dart';
import 'package:wifi_desk/features/streaming/presentation/widgets/mirroring_status_fallback.dart';

/// Interactive mirroring view managing stream lifecycle and delegating active UI to [MirroringActiveView].
class MirroringView extends StatelessWidget {
  const MirroringView({super.key, required this.device});

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
            return MirroringStartingFallback(deviceName: device.name);
          }

          if (state is StreamingError) {
            return MirroringErrorFallback(
              device: device,
              message: state.message,
            );
          }

          if (state is StreamingActive) {
            return MirroringActiveView(device: device, state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
