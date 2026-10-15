import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wifi_desk/core/constants/android_key_codes.dart';
import 'package:wifi_desk/core/di/injection.dart';
import 'package:wifi_desk/core/services/mac_file_picker_service.dart';
import 'package:wifi_desk/features/control/domain/entities/input_event_entity.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_bloc.dart';
import 'package:wifi_desk/features/control/presentation/bloc/control_event.dart';
import 'package:wifi_desk/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:wifi_desk/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:wifi_desk/features/apk_installer/presentation/widgets/apk_installer_dialog.dart';
import 'package:wifi_desk/features/productivity/presentation/widgets/device_file_manager_dialog.dart';

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

      if (logicalKey == LogicalKeyboardKey.keyS) {
        try {
          if (HardwareKeyboard.instance.isShiftPressed) {
            context.read<ScreenshotCubit>().startAreaSelection(deviceSerial);
          } else {
            context.read<ScreenshotCubit>().captureScreenshot(deviceSerial);
          }
          return KeyEventResult.handled;
        } catch (_) {}
      }

      if (logicalKey == LogicalKeyboardKey.keyR &&
          HardwareKeyboard.instance.isShiftPressed) {
        try {
          final cubit = context.read<ScreenRecordingCubit>();
          if (cubit.state is ScreenRecordingActive) {
            cubit.stopRecording();
          } else if (cubit.state is ScreenRecordingPreparing ||
              cubit.state is ScreenRecordingCountdown) {
            cubit.cancelPreparation();
          } else {
            cubit.prepareRecording(deviceSerial);
          }
          return KeyEventResult.handled;
        } catch (_) {}
      }

      if (logicalKey == LogicalKeyboardKey.tab) {
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

      if (logicalKey == LogicalKeyboardKey.keyU) {
        _triggerSendFiles(context, deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyF &&
          HardwareKeyboard.instance.isShiftPressed) {
        DeviceFileManagerDialog.show(context, deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyC &&
          HardwareKeyboard.instance.isShiftPressed) {
        try {
          context.read<ClipboardCubit>().syncHostToDevice(deviceSerial);
          return KeyEventResult.handled;
        } catch (_) {}
      }

      if (logicalKey == LogicalKeyboardKey.keyV &&
          HardwareKeyboard.instance.isShiftPressed) {
        try {
          context.read<ClipboardCubit>().syncDeviceToHost(deviceSerial);
          return KeyEventResult.handled;
        } catch (_) {}
      }

      if (logicalKey == LogicalKeyboardKey.keyI &&
          HardwareKeyboard.instance.isShiftPressed) {
        ApkInstallerDialog.show(context, deviceSerial: deviceSerial);
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

    // Escape -> Cancel area crop, recording preparation, or send Android Back
    if (logicalKey == LogicalKeyboardKey.escape) {
      try {
        final screenshotCubit = context.read<ScreenshotCubit>();
        if (screenshotCubit.state is ScreenshotSelectingArea) {
          screenshotCubit.cancelAreaSelection();
          return KeyEventResult.handled;
        }
      } catch (_) {}

      try {
        final recCubit = context.read<ScreenRecordingCubit>();
        if (recCubit.state is ScreenRecordingPreparing ||
            recCubit.state is ScreenRecordingCountdown) {
          recCubit.cancelPreparation();
          return KeyEventResult.handled;
        }
      } catch (_) {}

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

  Future<void> _triggerSendFiles(
    BuildContext context,
    String deviceSerial,
  ) async {
    final picker = sl<MacFilePickerService>();
    final files = await picker.pickFiles();
    if (files.isNotEmpty && context.mounted) {
      context.read<FileTransferCubit>().transferFiles(deviceSerial, files);
    }
  }
}
