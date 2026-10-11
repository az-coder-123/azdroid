import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/android_key_codes.dart';
import 'package:wifi_desk/core/constants/control_constants.dart';
import 'package:wifi_desk/core/theme/app_colors.dart';
import 'package:wifi_desk/features/control/domain/entities/input_event_entity.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_event.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:wifi_desk/features/control/presentation/widgets/touch_indicator_overlay.dart';

/// Interactive viewport overlay translating macOS mouse gestures, trackpad scrolling,
/// and keyboard keystrokes into normalized Android touch and key actions.
class InputGestureViewportOverlay extends StatefulWidget {
  const InputGestureViewportOverlay({
    required this.deviceSerial,
    required this.child,
    this.showTouchIndicators = true,
    super.key,
  });

  final String deviceSerial;
  final Widget child;
  final bool showTouchIndicators;

  @override
  State<InputGestureViewportOverlay> createState() =>
      _InputGestureViewportOverlayState();
}

class _InputGestureViewportOverlayState
    extends State<InputGestureViewportOverlay> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<TouchIndicatorOverlayState> _touchOverlayKey =
      GlobalKey<TouchIndicatorOverlayState>();

  Offset? _pointerDownPosition;
  int _pointerDownButtons = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final logicalKey = event.logicalKey;

    // macOS Command shortcuts
    if (isMeta) {
      if (logicalKey == LogicalKeyboardKey.keyH) {
        // Cmd + H -> Home
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: widget.deviceSerial,
            action: NavigationAction.home,
          ),
        );
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyS ||
          logicalKey == LogicalKeyboardKey.tab) {
        // Cmd + S or Cmd + Tab -> App Switcher
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: widget.deviceSerial,
            action: NavigationAction.appSwitch,
          ),
        );
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyK) {
        // Cmd + K -> Quick Text Injection Dialog
        QuickTextInputDialog.show(context, widget.deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.backspace) {
        // Cmd + Backspace -> Back
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: widget.deviceSerial,
            action: NavigationAction.back,
          ),
        );
        return KeyEventResult.handled;
      }
    }

    // Escape -> Android Back
    if (logicalKey == LogicalKeyboardKey.escape) {
      context.read<ControlBloc>().add(
        ControlNavigationActionDispatched(
          deviceSerial: widget.deviceSerial,
          action: NavigationAction.back,
        ),
      );
      return KeyEventResult.handled;
    }

    // Standard keycode mapping
    final mappedCode = AndroidKeyCodes.mapLogicalKey(logicalKey);
    if (mappedCode != null) {
      context.read<ControlBloc>().add(
        ControlKeyDispatched(
          deviceSerial: widget.deviceSerial,
          keyCode: mappedCode,
        ),
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _pointerDownPosition = event.localPosition;
              _pointerDownButtons = event.buttons;

              // Check for Secondary Click (Right-Click) -> Android Back
              if (event.buttons == kSecondaryMouseButton) {
                context.read<ControlBloc>().add(
                  ControlNavigationActionDispatched(
                    deviceSerial: widget.deviceSerial,
                    action: NavigationAction.back,
                  ),
                );
                return;
              }

              // Check for Tertiary Click (Middle-Click) -> Android Home
              if (event.buttons == kMiddleMouseButton) {
                context.read<ControlBloc>().add(
                  ControlNavigationActionDispatched(
                    deviceSerial: widget.deviceSerial,
                    action: NavigationAction.home,
                  ),
                );
                return;
              }
            },
            onPointerUp: (event) {
              final startPos = _pointerDownPosition;
              final buttons = _pointerDownButtons;
              _pointerDownPosition = null;
              _pointerDownButtons = 0;

              // If it was right or middle click, already handled
              if (buttons == kSecondaryMouseButton ||
                  buttons == kMiddleMouseButton ||
                  startPos == null ||
                  width <= 0 ||
                  height <= 0) {
                return;
              }

              final endPos = event.localPosition;
              final distance = (endPos - startPos).distance;

              if (distance < ControlConstants.minSwipeDistance) {
                // Primary Tap
                final normX = (endPos.dx / width).clamp(0.0, 1.0);
                final normY = (endPos.dy / height).clamp(0.0, 1.0);

                if (widget.showTouchIndicators) {
                  _touchOverlayKey.currentState?.addTouch(endPos);
                }

                context.read<ControlBloc>().add(
                  ControlTapDispatched(
                    deviceSerial: widget.deviceSerial,
                    normalizedX: normX,
                    normalizedY: normY,
                  ),
                );
              } else {
                // Drag / Swipe
                final startX = (startPos.dx / width).clamp(0.0, 1.0);
                final startY = (startPos.dy / height).clamp(0.0, 1.0);
                final endX = (endPos.dx / width).clamp(0.0, 1.0);
                final endY = (endPos.dy / height).clamp(0.0, 1.0);

                context.read<ControlBloc>().add(
                  ControlSwipeDispatched(
                    deviceSerial: widget.deviceSerial,
                    startX: startX,
                    startY: startY,
                    endX: endX,
                    endY: endY,
                    durationMs: ControlConstants.defaultSwipeDurationMs,
                  ),
                );
              }
            },
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent && width > 0 && height > 0) {
                final normX = (signal.localPosition.dx / width).clamp(0.0, 1.0);
                final normY = (signal.localPosition.dy / height).clamp(
                  0.0,
                  1.0,
                );

                context.read<ControlBloc>().add(
                  ControlScrollDispatched(
                    deviceSerial: widget.deviceSerial,
                    normalizedX: normX,
                    normalizedY: normY,
                    deltaX: signal.scrollDelta.dx,
                    deltaY: signal.scrollDelta.dy,
                  ),
                );
              }
            },
            child: Stack(
              children: [
                TouchIndicatorOverlay(
                  key: _touchOverlayKey,
                  enabled: widget.showTouchIndicators,
                  child: widget.child,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _ControlShortcutHelpBadge(
                    onTapTextInject: () {
                      QuickTextInputDialog.show(context, widget.deviceSerial);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Subtle HUD badge showing mouse and keyboard shortcuts.
class _ControlShortcutHelpBadge extends StatelessWidget {
  const _ControlShortcutHelpBadge({required this.onTapTextInject});

  final VoidCallback onTapTextInject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mouse_outlined,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          const Text(
            'R-Click: Back  •  M-Click: Home',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTapTextInject,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_alt_outlined,
                    size: 11,
                    color: AppColors.accentLight,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '⌘K Text',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
