import 'package:desk_droid/core/extensions/optional_read_extension.dart';
import 'package:desk_droid/core/platform/host_os.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
}

/// Reads the app's [ShortcutScheme].
extension ShortcutSchemeContext on BuildContext {
  /// The provided scheme, or the running OS's scheme when none is provided
  /// (for example in isolated widget tests).
  ShortcutScheme get shortcuts =>
      tryRead<ShortcutScheme>() ?? ShortcutScheme.forOs(HostOs.current);
}
