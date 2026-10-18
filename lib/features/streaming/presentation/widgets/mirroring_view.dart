import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_state.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_active_view.dart';
import 'package:desk_droid/features/streaming/presentation/widgets/mirroring_status_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Interactive mirroring view managing stream lifecycle and delegating active UI to [MirroringActiveView].
class MirroringView extends StatelessWidget {
  const MirroringView({
    super.key,
    required this.device,
    this.deviceStatusBanner,
  });

  final DeviceEntity device;

  /// Status badge shown over the active view (see MirroringPage).
  final Widget? deviceStatusBanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<StreamingCubit, StreamingState>(
        listener: (context, state) {
          if (state is StreamingActive) {
            final telemetry = state.telemetry;
            context.read<MenuBarCubit>().updateActiveSession(
              deviceName: state.session.deviceName,
              latencyMs: telemetry?.latencyMs?.round(),
              fps: telemetry?.fps?.round(),
            );
          } else if (state is StreamingInitial) {
            context.read<MenuBarCubit>().clearActiveSession();
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
            return MirroringActiveView(
              device: device,
              state: state,
              deviceStatusBanner: deviceStatusBanner,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
