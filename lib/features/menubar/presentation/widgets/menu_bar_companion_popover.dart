import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:wifi_desk/features/menubar/presentation/cubit/menu_bar_state.dart';

/// Refined Apple-native popover menu attached to the macOS system tray status item.
class MenuBarCompanionPopover extends StatelessWidget {
  const MenuBarCompanionPopover({
    super.key,
    this.onToggleWindow,
    this.onDisconnect,
    this.onOpenDiscovery,
    this.onOpenGuide,
  });

  final VoidCallback? onToggleWindow;
  final VoidCallback? onDisconnect;
  final VoidCallback? onOpenDiscovery;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBarCubit, MenuBarState>(
      builder: (context, state) {
        final status = state.status;
        final isMirroring = status.activeDeviceName != null;

        return Container(
          width: 320,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Brand Header
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.desktop_mac_rounded,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'WifiDesk Companion',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isMirroring
                          ? AppColors.statusSuccess.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMirroring
                            ? AppColors.statusSuccess.withValues(alpha: 0.4)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: isMirroring
                              ? AppColors.statusSuccess
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isMirroring ? 'Mirroring' : 'Idle',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMirroring
                                ? AppColors.statusSuccess
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 12),

              // Active Device Session Card
              if (isMirroring) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              status.activeDeviceName!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (status.batteryLevel != null) ...[
                            const Icon(
                              Icons.battery_charging_full_rounded,
                              size: 14,
                              color: AppColors.statusSuccess,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${status.batteryLevel}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTelemetryChip(
                            icon: Icons.speed_rounded,
                            label: '${status.latencyMs ?? 18}ms',
                            color: AppColors.accentLight,
                          ),
                          const SizedBox(width: 8),
                          _buildTelemetryChip(
                            icon: Icons.motion_photos_on_rounded,
                            label: '${status.fps ?? 60} FPS',
                            color: AppColors.statusSuccess,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.discoveredDeviceCount > 0
                              ? '${status.discoveredDeviceCount} device(s) ready on Wi-Fi'
                              : 'No devices connected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Window & App Actions
              _buildActionButton(
                icon: status.isWindowVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                title: status.isWindowVisible
                    ? 'Hide Mirroring Window'
                    : 'Show Mirroring Window',
                onTap: () {
                  context.read<MenuBarCubit>().toggleWindowVisibility();
                  onToggleWindow?.call();
                },
              ),
              if (onOpenGuide != null) ...[
                const SizedBox(height: 6),
                _buildActionButton(
                  icon: Icons.menu_book_rounded,
                  title: 'User Guide & Shortcuts',
                  onTap: onOpenGuide!,
                ),
              ],
              if (isMirroring && onDisconnect != null) ...[
                const SizedBox(height: 6),
                _buildActionButton(
                  icon: Icons.power_settings_new_rounded,
                  title: 'Disconnect Stream',
                  color: AppColors.statusError,
                  onTap: onDisconnect!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelemetryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final textColor = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: AppColors.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
