import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcuts orchestrator for the Logcat Console dialog.
///
/// Supported bindings:
/// - Cmd/Ctrl + F: Focus search query field.
/// - Cmd/Ctrl + K: Clear in-memory log entries.
/// - Space: Toggle pause/resume (when not typing in a text field).
/// - Cmd/Ctrl + Down: Scroll to bottom / Jump to latest logs.
/// - Esc: Unfocus search -> Close Detail Drawer -> Close Dialog.
class LogcatShortcutHandler extends StatelessWidget {
  const LogcatShortcutHandler({
    super.key,
    required this.searchFocusNode,
    required this.hasSelectedEntry,
    required this.onClearConsole,
    required this.onTogglePause,
    required this.onScrollToBottom,
    required this.onCloseDetail,
    required this.onCloseDialog,
    required this.child,
  });

  final FocusNode searchFocusNode;
  final bool hasSelectedEntry;
  final VoidCallback onClearConsole;
  final VoidCallback onTogglePause;
  final VoidCallback onScrollToBottom;
  final VoidCallback onCloseDetail;
  final VoidCallback onCloseDialog;
  final Widget child;

  void _handleSpace() {
    // Prevent pausing stream while the user is actively typing in a text field
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isEditingText =
        primaryFocus?.context != null &&
        primaryFocus!.context!.findAncestorWidgetOfExactType<EditableText>() !=
            null;

    if (!isEditingText) {
      onTogglePause();
    }
  }

  void _handleEscape() {
    if (searchFocusNode.hasFocus) {
      searchFocusNode.unfocus();
    } else if (hasSelectedEntry) {
      onCloseDetail();
    } else {
      onCloseDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = context.shortcuts;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Primary modifier is Cmd on macOS and Ctrl on Windows/Linux.
        shortcuts.activator(LogicalKeyboardKey.keyF):
            searchFocusNode.requestFocus,
        shortcuts.activator(LogicalKeyboardKey.keyK): onClearConsole,
        shortcuts.activator(LogicalKeyboardKey.arrowDown): onScrollToBottom,

        // Space: Toggle pause/resume
        const SingleActivator(LogicalKeyboardKey.space): _handleSpace,

        // Escape: Smart back navigation
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
