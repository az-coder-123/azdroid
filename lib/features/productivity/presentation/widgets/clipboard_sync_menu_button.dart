import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_state.dart';

/// Floating HUD button with menu for manual and automatic clipboard synchronization.
class ClipboardSyncMenuButton extends StatelessWidget {
  const ClipboardSyncMenuButton({required this.deviceSerial, super.key});

  final String deviceSerial;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClipboardCubit, ClipboardState>(
      builder: (context, state) {
        final isSyncing = state is ClipboardSyncing;
        final autoSync = state.autoSyncEnabled;

        return PopupMenuButton<String>(
          tooltip: 'Clipboard Synchronization',
          color: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              : Icon(
                  Icons.content_paste_go_rounded,
                  size: 20,
                  color: autoSync
                      ? AppColors.accentLight
                      : AppColors.textPrimary,
                ),
          onSelected: (value) {
            final cubit = context.read<ClipboardCubit>();
            switch (value) {
              case 'mac_to_android':
                cubit.syncHostToDevice(deviceSerial);
                break;
              case 'android_to_mac':
                cubit.syncDeviceToHost(deviceSerial);
                break;
              case 'toggle_auto':
                cubit.toggleAutoSync(deviceSerial);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mac_to_android',
              child: Row(
                children: [
                  Icon(Icons.upload_rounded, size: 16, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(child: Text('Push Mac ➔ Android')),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'android_to_mac',
              child: Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 16,
                    color: AppColors.statusSuccess,
                  ),
                  SizedBox(width: 8),
                  Expanded(child: Text('Pull Android ➔ Mac')),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'toggle_auto',
              child: Row(
                children: [
                  Icon(
                    autoSync
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: autoSync
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      autoSync ? 'Auto-Sync (Active)' : 'Enable Auto-Sync',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
