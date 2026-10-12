import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/android_key_codes.dart';
import 'package:wifi_desk/features/control/domain/entities/input_event_entity.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_event.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';

/// Translates raw desktop keyboard events into Android navigation and key inputs.
class ViewportKeyEventHandler {
  const ViewportKeyEventHandler();

  KeyEventResult handleKeyEvent({
    required BuildContext context,
    required String deviceSerial,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final logicalKey = event.logicalKey;

    // macOS Command shortcuts
    if (isMeta) {
      if (logicalKey == LogicalKeyboardKey.keyH) {
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: deviceSerial,
            action: NavigationAction.home,
          ),
        );
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyS ||
          logicalKey == LogicalKeyboardKey.tab) {
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: deviceSerial,
            action: NavigationAction.appSwitch,
          ),
        );
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyK) {
        QuickTextInputDialog.show(context, deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.backspace) {
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: deviceSerial,
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
          deviceSerial: deviceSerial,
          action: NavigationAction.back,
        ),
      );
      return KeyEventResult.handled;
    }

    // Standard keycode mapping
    final mappedCode = AndroidKeyCodes.mapLogicalKey(logicalKey);
    if (mappedCode != null) {
      context.read<ControlBloc>().add(
        ControlKeyDispatched(deviceSerial: deviceSerial, keyCode: mappedCode),
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
