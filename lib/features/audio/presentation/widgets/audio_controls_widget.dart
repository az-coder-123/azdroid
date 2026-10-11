import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/audio/presentation/cubit/audio_cubit.dart';
import 'package:wifi_desk/features/audio/presentation/cubit/audio_state.dart';

/// Interactive audio control button providing mute toggle and slider volume adjustment.
class AudioControlsWidget extends StatelessWidget {
  const AudioControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, state) {
        if (state is! AudioActive) {
          return IconButton(
            tooltip: 'Audio Stream Inactive',
            icon: const Icon(
              Icons.volume_mute_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
            splashRadius: 18,
            onPressed: null,
          );
        }

        final isMuted = state.audioStream.isMuted;
        final volume = state.audioStream.volume;

        final IconData icon = isMuted || volume == 0.0
            ? Icons.volume_off_rounded
            : volume < 0.5
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

        return PopupMenuButton<void>(
          tooltip: isMuted
              ? 'Audio Muted'
              : 'Audio Volume (${(volume * 100).toInt()}%)',
          color: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          icon: Icon(
            icon,
            size: 20,
            color: isMuted ? AppColors.statusWarning : AppColors.textPrimary,
          ),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Audio Volume',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMuted ? 'Muted' : '${(volume * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: isMuted
                                ? AppColors.statusWarning
                                : AppColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: isMuted ? 0.0 : volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          context.read<AudioCubit>().setVolume(val);
                        },
                      ),
                    ),
                    const Divider(height: 12, color: AppColors.border),
                    InkWell(
                      onTap: () {
                        context.read<AudioCubit>().toggleMute();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMuted
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isMuted ? 'Unmute Audio' : 'Mute Audio',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
