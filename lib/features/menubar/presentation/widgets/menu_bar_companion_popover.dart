import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_cubit.dart';
import 'package:desk_droid/features/menubar/presentation/cubit/menu_bar_state.dart';
import 'package:desk_droid/features/menubar/presentation/widgets/components/menu_bar_action_button.dart';
import 'package:desk_droid/features/menubar/presentation/widgets/components/menu_bar_header.dart';
import 'package:desk_droid/features/menubar/presentation/widgets/components/menu_bar_idle_card.dart';
import 'package:desk_droid/features/menubar/presentation/widgets/components/menu_bar_session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          constraints: const BoxConstraints(maxWidth: 320),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MenuBarHeader(isMirroring: isMirroring),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 12),
                if (isMirroring) ...[
                  MenuBarSessionCard(status: status),
                  const SizedBox(height: 12),
                ] else ...[
                  MenuBarIdleCard(
                    discoveredDeviceCount: status.discoveredDeviceCount,
                  ),
                  const SizedBox(height: 12),
                ],
                MenuBarActionButton(
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
                  MenuBarActionButton(
                    icon: Icons.menu_book_rounded,
                    title: 'User Guide & Shortcuts',
                    onTap: onOpenGuide!,
                  ),
                ],
                if (isMirroring && onDisconnect != null) ...[
                  const SizedBox(height: 6),
                  MenuBarActionButton(
                    icon: Icons.power_settings_new_rounded,
                    title: 'Disconnect Stream',
                    color: AppColors.statusError,
                    onTap: onDisconnect!,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
