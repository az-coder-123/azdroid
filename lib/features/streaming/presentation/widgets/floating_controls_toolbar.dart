import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/audio/presentation/widgets/audio_controls_widget.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:flutter/material.dart';

/// Floating HUD toolbar providing quick access to Android navigation and core stream controls.
class FloatingControlsToolbar extends StatelessWidget {
  const FloatingControlsToolbar({
    super.key,
    required this.session,
    required this.onBack,
    required this.onHome,
    required this.onAppSwitch,
    required this.onRotate,
    required this.onToggleScreenOff,
  });

  final StreamSessionEntity session;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onAppSwitch;
  final VoidCallback onRotate;
  final VoidCallback onToggleScreenOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Android System Navigation Keys
            _buildToolButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back (Right Click)',
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.circle_outlined,
              tooltip: 'Home (Cmd+H / Middle Click)',
              onPressed: onHome,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: Icons.crop_square_rounded,
              tooltip: 'App Switcher (Cmd+Tab)',
              onPressed: onAppSwitch,
            ),
            const SizedBox(width: 12),
            _buildDivider(),
            const SizedBox(width: 12),

            // Display & Stream Controls
            _buildToolButton(
              icon: Icons.rotate_right_rounded,
              tooltip: 'Rotate Display',
              onPressed: onRotate,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              icon: session.isScreenOff
                  ? Icons.screen_lock_portrait_rounded
                  : Icons.stay_current_portrait_rounded,
              tooltip: session.isScreenOff
                  ? 'Turn Phone Screen On'
                  : 'Turn Phone Screen Off (--turn-screen-off)',
              color: session.isScreenOff ? AppColors.statusWarning : null,
              onPressed: onToggleScreenOff,
            ),
            const SizedBox(width: 8),
            const AudioControlsWidget(),

            const SizedBox(width: 12),
            _buildDivider(),
            const SizedBox(width: 12),

            // Ergonomic Mouse Shortcuts Guide
            const Tooltip(
              message:
                  'Quick gestures: Right-Click for Back, Middle-Click for Home',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mouse_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'R-Click: Back  •  M-Click: Home',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1.0, height: 20.0, color: AppColors.borderSubtle);
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        hoverColor: AppColors.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20.0, color: color ?? AppColors.textPrimary),
        ),
      ),
    );
  }
}
