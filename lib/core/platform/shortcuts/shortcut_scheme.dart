import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Primary-modifier convention of the host OS, as data.
///
/// Key handling (`isPrimaryPressed`, `activator`) and on-screen labels
/// (`label`, `keyCaps`) read from the same object, so they cannot drift.
class ShortcutScheme {
  const ShortcutScheme._({
    required this.usesMetaKey,
    required this.primaryLabel,
    required this.shiftLabel,
    required this.separator,
  });

  /// macOS: Command key, symbol labels such as `⌘⇧S`.
  static const ShortcutScheme mac = ShortcutScheme._(
    usesMetaKey: true,
    primaryLabel: '⌘',
    shiftLabel: '⇧',
    separator: '',
  );

  /// Windows and Linux: Control key, text labels such as `Ctrl+Shift+S`.
  static const ShortcutScheme pc = ShortcutScheme._(
    usesMetaKey: false,
    primaryLabel: 'Ctrl',
    shiftLabel: 'Shift',
    separator: '+',
  );

  /// Scheme for [os].
  static ShortcutScheme forOs(HostOs os) => os == HostOs.macos ? mac : pc;

  /// Whether the primary modifier is Command (`true`) or Control (`false`).
  final bool usesMetaKey;

  /// Label of the primary modifier.
  final String primaryLabel;

  /// Label of the Shift modifier.
  final String shiftLabel;

  /// Text placed between keys in a combined label.
  final String separator;

  /// Whether the primary modifier is currently held down.
  bool isPrimaryPressed(HardwareKeyboard keyboard) =>
      usesMetaKey ? keyboard.isMetaPressed : keyboard.isControlPressed;

  /// Activator for primary-modifier + [key] (+ Shift when [shift]).
  SingleActivator activator(LogicalKeyboardKey key, {bool shift = false}) =>
      SingleActivator(
        key,
        meta: usesMetaKey,
        control: !usesMetaKey,
        shift: shift,
      );

  /// Combined label for primary-modifier + [key], e.g. `⌘⇧S` or `Ctrl+Shift+S`.
  String label(String key, {bool shift = false}) =>
      keyCaps(key, shift: shift).join(separator);

  /// Individual key caps for primary-modifier + [key].
  List<String> keyCaps(String key, {bool shift = false}) => [
    primaryLabel,
    if (shift) shiftLabel,
    key,
  ];

  /// Recommended icon representing keyboard shortcuts for this OS.
  IconData get shortcutIcon =>
      usesMetaKey ? Icons.keyboard_command_key_rounded : Icons.keyboard_rounded;

  /// Formats a textual shortcut descriptor or feature description to match
  /// this OS scheme.
  ///
  /// On macOS ([usesMetaKey] is true), Command (`⌘` / `Cmd`) conventions
  /// are preserved.
  /// On Windows and Linux ([usesMetaKey] is false), `⌘`, `Cmd`, and Mac-specific
  /// terms are converted into their `Ctrl`, `Ctrl+Shift+`, and PC counterparts.
  String adapt(String text) {
    if (usesMetaKey) return text;
    return text
        .replaceAll('⌘⇧', 'Ctrl+Shift+')
        .replaceAll('⌘⌫', 'Ctrl+Backspace')
        .replaceAll('⌘ Keys', 'Ctrl Keys')
        .replaceAll(RegExp(r'⌘\s+'), 'Ctrl ')
        .replaceAllMapped(RegExp(r'⌘([A-Za-z0-9])'), (m) => 'Ctrl+${m[1]}')
        .replaceAll('⌘', 'Ctrl+')
        .replaceAll('Cmd+Shift+', 'Ctrl+Shift+')
        .replaceAll('Cmd+', 'Ctrl+')
        .replaceAll(RegExp(r'\bCmd\b'), 'Ctrl')
        .replaceAll('Mac Keyboard', 'Windows Keyboard')
        .replaceAll('Mac keyboard', 'Windows keyboard')
        .replaceAll(RegExp(r'\bto Mac\b'), 'to PC')
        .replaceAll(RegExp(r'\bon Mac\b'), 'on PC')
        .replaceAll(RegExp(r'\bfor Mac\b'), 'for PC')
        .replaceAll('Mac ~/Downloads', 'Downloads')
        .replaceAll('macOS pasteboard', 'Windows clipboard');
  }
}

/// Reads the app's [ShortcutScheme].
extension ShortcutSchemeContext on BuildContext {
  /// The provided scheme, or the running OS's scheme when none is provided
  /// (for example in isolated widget tests).
  ShortcutScheme get shortcuts =>
      tryRead<ShortcutScheme>() ?? ShortcutScheme.forOs(HostOs.current);
}
