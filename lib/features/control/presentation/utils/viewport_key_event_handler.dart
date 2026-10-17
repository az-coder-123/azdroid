import 'package:desk_droid/core/constants/android_key_codes.dart';
import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:desk_droid/features/apk_installer/presentation/widgets/apk_installer_dialog.dart';
import 'package:desk_droid/features/control/domain/entities/input_event_entity.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_bloc.dart';
import 'package:desk_droid/features/control/presentation/bloc/control_event.dart';
import 'package:desk_droid/features/control/presentation/widgets/quick_text_input_dialog.dart';
import 'package:desk_droid/features/intent_dispatcher/presentation/widgets/intent_dispatcher_dialog.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/clipboard_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/file_transfer_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screen_recording_state.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_cubit.dart';
import 'package:desk_droid/features/productivity/presentation/cubit/screenshot_state.dart';
import 'package:desk_droid/features/productivity/presentation/widgets/device_file_manager_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    final isPrimary = context.shortcuts.isPrimaryPressed(
      HardwareKeyboard.instance,
    );
    final logicalKey = event.logicalKey;

    // macOS Command shortcuts
    if (isPrimary) {
      if (logicalKey == LogicalKeyboardKey.keyH) {
        context.read<ControlBloc>().add(
          ControlNavigationActionDispatched(
            deviceSerial: deviceSerial,
            action: NavigationAction.home,
          ),
        );
        return KeyEventResult.handled;
      }

      final screenshotCubit = context.tryRead<ScreenshotCubit>();
      if (logicalKey == LogicalKeyboardKey.keyS && screenshotCubit != null) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          screenshotCubit.startAreaSelection(deviceSerial);
        } else {
          screenshotCubit.captureScreenshot(deviceSerial);
        }
        return KeyEventResult.handled;
      }

      final recordingCubit = context.tryRead<ScreenRecordingCubit>();
      if (logicalKey == LogicalKeyboardKey.keyR &&
          HardwareKeyboard.instance.isShiftPressed &&
          recordingCubit != null) {
        _toggleRecording(recordingCubit, deviceSerial);
        return KeyEventResult.handled;
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
        context.read<FileTransferCubit>().pickAndTransferFiles(deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyF &&
          HardwareKeyboard.instance.isShiftPressed) {
        DeviceFileManagerDialog.show(context, deviceSerial);
        return KeyEventResult.handled;
      }

      final clipboardCubit = context.tryRead<ClipboardCubit>();
      if (logicalKey == LogicalKeyboardKey.keyC &&
          HardwareKeyboard.instance.isShiftPressed &&
          clipboardCubit != null) {
        clipboardCubit.syncHostToDevice(deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyV &&
          HardwareKeyboard.instance.isShiftPressed &&
          clipboardCubit != null) {
        clipboardCubit.syncDeviceToHost(deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyI &&
          HardwareKeyboard.instance.isShiftPressed) {
        ApkInstallerDialog.show(context, deviceSerial: deviceSerial);
        return KeyEventResult.handled;
      }

      if (logicalKey == LogicalKeyboardKey.keyD &&
          HardwareKeyboard.instance.isShiftPressed) {
        IntentDispatcherDialog.show(context, deviceSerial);
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
      final screenshotCubit = context.tryRead<ScreenshotCubit>();
      if (screenshotCubit?.state is ScreenshotSelectingArea) {
        screenshotCubit!.cancelAreaSelection();
        return KeyEventResult.handled;
      }

      final recordingCubit = context.tryRead<ScreenRecordingCubit>();
      if (recordingCubit != null && _isPreparing(recordingCubit.state)) {
        recordingCubit.cancelPreparation();
        return KeyEventResult.handled;
      }

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

  bool _isPreparing(ScreenRecordingState state) =>
      state is ScreenRecordingPreparing || state is ScreenRecordingCountdown;

  void _toggleRecording(ScreenRecordingCubit cubit, String deviceSerial) {
    if (cubit.state is ScreenRecordingActive) {
      cubit.stopRecording();
    } else if (_isPreparing(cubit.state)) {
      cubit.cancelPreparation();
    } else {
      cubit.prepareRecording(deviceSerial);
    }
  }
}
