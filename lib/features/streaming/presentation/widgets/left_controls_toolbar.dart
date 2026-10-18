import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/core/theme/app_colors.dart';
import 'package:desk_droid/features/audio/presentation/widgets/audio_controls_widget.dart';
import 'package:desk_droid/features/streaming/domain/entities/stream_session_entity.dart';
import 'package:flutter/material.dart';

/// Vertical actions toolbar placed on the left side of the real-time phone display,
/// providing fast access to Android system navigation, power/screen lock, display orientation,
/// screen-off streaming, zen mode, audio forwarding, features showcase, and user guide.
class LeftControlsToolbar extends StatelessWidget {
  const LeftControlsToolbar({
    super.key,
    required this.session,
    required this.onBack,
    required this.onHome,
    required this.onAppSwitch,
    required this.onPower,
    required this.onRotate,
    this.onToggleStayAwake,
    required this.onToggleScreenOff,
    required this.onToggleZenMode,
    required this.onOpenShowcase,
  });

  final StreamSessionEntity session;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onAppSwitch;
  final VoidCallback onPower;
  final VoidCallback onRotate;
  final VoidCallback? onToggleStayAwake;
  final VoidCallback onToggleScreenOff;
  final VoidCallback onToggleZenMode;
  final VoidCallback onOpenShowcase;

  @override
  Widget build(BuildContext context) {
    final keys = context.shortcuts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group 1: Device Power & Screen Lock (top-level, isolated with distinct accent)
            _buildToolButton(
              icon: Icons.power_settings_new_rounded,
              tooltip: 'Lock Phone / Power (${keys.label('P')})',
              color: AppColors.statusError,
              backgroundColor: AppColors.statusError.withValues(alpha: 0.14),
              onPressed: onPower,
            ),

            const SizedBox(height: 10),
            _buildDivider(),
            const SizedBox(height: 10),

            // Group 2: Android System Navigation
            _buildToolButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back (Right Click)',
              onPressed: onBack,
            ),
            const SizedBox(height: 4),
            _buildToolButton(
              icon: Icons.circle_outlined,
              tooltip: 'Home (${keys.label('H')} / Middle Click)',
              onPressed: onHome,
            ),
            const SizedBox(height: 4),
            _buildToolButton(
              icon: Icons.crop_square_rounded,
              tooltip: 'App Switcher (${keys.label('Tab')})',
              onPressed: onAppSwitch,
            ),

            const SizedBox(height: 6),
            _buildDivider(),
            const SizedBox(height: 6),

            // Group 3: Display & Hardware Controls
            _buildToolButton(
              icon: Icons.rotate_right_rounded,
              tooltip: 'Rotate Display (${keys.label('R')})',
              onPressed: onRotate,
            ),
            const SizedBox(height: 4),
            _buildToolButton(
              icon: session.stayAwake
                  ? Icons.light_mode_rounded
                  : Icons.light_mode_outlined,
              tooltip: session.stayAwake
                  ? 'Keep Phone Awake: On (phone settings restored when you stop)'
                  : 'Keep Phone Awake: Off (phone sleeps on its own timer)',
              color: session.stayAwake ? AppColors.accent : null,
              onPressed: onToggleStayAwake,
            ),
            const SizedBox(height: 4),
            _buildToolButton(
              icon: session.isScreenOff
                  ? Icons.screen_lock_portrait_rounded
                  : Icons.stay_current_portrait_rounded,
              tooltip: session.isScreenOff
                  ? 'Turn Phone Screen On (${keys.label('O')})'
                  : 'Turn Phone Screen Off, Keep Mirroring (${keys.label('O')})',
              color: session.isScreenOff ? AppColors.statusWarning : null,
              onPressed: onToggleScreenOff,
            ),
            const SizedBox(height: 4),
            _buildToolButton(
              icon: Icons.fullscreen_rounded,
              tooltip: 'Zen Mode (Hide Toolbars)',
              onPressed: onToggleZenMode,
            ),

            const SizedBox(height: 6),
            _buildDivider(),
            const SizedBox(height: 6),

            // Group 3: Real-Time Audio Forwarding Controls
            const AudioControlsWidget(),

            const SizedBox(height: 6),
            _buildDivider(),
            const SizedBox(height: 6),

            // Group 4: Features Showcase (All 21 Features & Shortcuts)
            _buildToolButton(
              icon: Icons.auto_awesome_rounded,
              tooltip: 'Features Showcase (All 21 Features)',
              color: AppColors.accent,
              onPressed: onOpenShowcase,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
    Color? backgroundColor,
  }) {
    final button = IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: onPressed == null
            ? AppColors.textTertiary
            : (color ?? AppColors.textPrimary),
      ),
      tooltip: tooltip,
      splashRadius: 18,
      onPressed: onPressed,
    );
    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: button,
      );
    }
    return button;
  }

  Widget _buildDivider() {
    return const SizedBox(
      width: 24,
      child: Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
    );
  }
}
