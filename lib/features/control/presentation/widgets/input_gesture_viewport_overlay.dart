import 'package:desk_droid/core/constants/control_constants.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_event.dart';
import 'package:desk_droid/features/control/presentation/utils/touch_gesture_tracker.dart';
import 'package:desk_droid/features/control/presentation/utils/viewport_key_event_handler.dart';
import 'package:desk_droid/features/control/presentation/widgets/control_shortcut_help_badge.dart';
import 'package:desk_droid/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:desk_droid/features/control/presentation/widgets/touch_indicator_overlay.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Interactive viewport overlay translating macOS mouse gestures, trackpad scrolling,
/// and keyboard keystrokes into normalized Android touch and key actions.
class InputGestureViewportOverlay extends StatefulWidget {
  const InputGestureViewportOverlay({
    required this.deviceSerial,
    required this.child,
    this.showTouchIndicators = true,
    this.showShortcutBadge = true,
    super.key,
  });

  final String deviceSerial;
  final Widget child;
  final bool showTouchIndicators;
  final bool showShortcutBadge;

  @override
  State<InputGestureViewportOverlay> createState() =>
      _InputGestureViewportOverlayState();
}

class _InputGestureViewportOverlayState
    extends State<InputGestureViewportOverlay> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<TouchIndicatorOverlayState> _touchOverlayKey =
      GlobalKey<TouchIndicatorOverlayState>();
  static const ViewportKeyEventHandler _keyHandler = ViewportKeyEventHandler();

  Offset? _pointerDownPosition;
  int _pointerDownButtons = 0;
  late final TouchGestureTracker _gestures = TouchGestureTracker(
    (phase, points) => context.read<ControlBloc>().add(
      ControlTouchStreamed(
        deviceSerial: widget.deviceSerial,
        phase: phase,
        points: points,
      ),
    ),
  );

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

  void _onPointerDown(PointerDownEvent event, Size viewport) {
    // Alt + left drag: two-finger pinch/rotate around the screen center.
    if (event.buttons == kPrimaryButton &&
        HardwareKeyboard.instance.isAltPressed) {
      _gestures.mirroredStart(event.localPosition, viewport);
      return;
    }
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
  }

  void _onPointerUp(PointerUpEvent event, double width, double height) {
    if (_gestures.isMirroring) {
      _gestures.mirroredEnd();
      return;
    }
    final startPos = _pointerDownPosition;
    final buttons = _pointerDownButtons;
    _pointerDownPosition = null;
    _pointerDownButtons = 0;

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
  }

  void _onPointerSignal(
    PointerSignalEvent signal,
    double width,
    double height,
  ) {
    if (signal is PointerScrollEvent && width > 0 && height > 0) {
      final normX = (signal.localPosition.dx / width).clamp(0.0, 1.0);
      final normY = (signal.localPosition.dy / height).clamp(0.0, 1.0);

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
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _keyHandler.handleKeyEvent(
        context: context,
        deviceSerial: widget.deviceSerial,
        event: event,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _onPointerDown(e, Size(width, height)),
            onPointerMove: (e) {
              if (_gestures.isMirroring) {
                _gestures.mirroredMove(e.localPosition);
              }
            },
            onPointerUp: (e) => _onPointerUp(e, width, height),
            onPointerCancel: (_) => _gestures.mirroredEnd(),
            onPointerSignal: (s) => _onPointerSignal(s, width, height),
            // Trackpad: pan is a live one-finger drag (scroll), pinch and
            // rotate are two fingers. Mouse wheels still use onPointerSignal.
            onPointerPanZoomStart: (e) =>
                _gestures.panZoomStart(e.localPosition, Size(width, height)),
            onPointerPanZoomUpdate: (e) => _gestures.panZoomUpdate(
              pan: e.pan,
              scale: e.scale,
              rotation: e.rotation,
            ),
            onPointerPanZoomEnd: (_) => _gestures.panZoomEnd(),
            child: Stack(
              children: [
                TouchIndicatorOverlay(
                  key: _touchOverlayKey,
                  enabled: widget.showTouchIndicators,
                  child: widget.child,
                ),
                if (widget.showShortcutBadge)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: ControlShortcutHelpBadge(
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
