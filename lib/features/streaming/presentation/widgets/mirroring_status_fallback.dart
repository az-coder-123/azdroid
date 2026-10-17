import 'package:desk_droid/core/models/device_entity.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/core/theme/app_typography.dart';
import 'package:desk_droid/features/streaming/presentation/cubit/streaming_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fallback display while stream is initializing.
class MirroringStartingFallback extends StatelessWidget {
  const MirroringStartingFallback({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 20),
          Text(
            'Starting Display Stream on $deviceName...',
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
}

/// Fallback display when stream encounter an error.
class MirroringErrorFallback extends StatelessWidget {
  const MirroringErrorFallback({
    super.key,
    required this.device,
    required this.message,
  });

  final DeviceEntity device;
  final String message;

  @override
  Widget build(BuildContext context) {
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
              message,
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
                  onPressed: () =>
                      context.read<StreamingCubit>().startSession(device),
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
