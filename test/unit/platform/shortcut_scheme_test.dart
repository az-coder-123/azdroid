import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forOs maps macOS to Command and others to Control', () {
    expect(ShortcutScheme.forOs(HostOs.macos), same(ShortcutScheme.mac));
    expect(ShortcutScheme.forOs(HostOs.windows), same(ShortcutScheme.pc));
    expect(ShortcutScheme.forOs(HostOs.linux), same(ShortcutScheme.pc));
  });

  test('labels follow each platform convention', () {
    expect(ShortcutScheme.mac.label('S', shift: true), '⌘⇧S');
    expect(ShortcutScheme.pc.label('S', shift: true), 'Ctrl+Shift+S');
    expect(ShortcutScheme.pc.keyCaps('K'), ['Ctrl', 'K']);
  });

  test('activators use the matching modifier', () {
    final mac = ShortcutScheme.mac.activator(LogicalKeyboardKey.keyF);
    final pc = ShortcutScheme.pc.activator(
      LogicalKeyboardKey.keyF,
      shift: true,
    );

    expect((mac.meta, mac.control), (true, false));
    expect((pc.meta, pc.control, pc.shift), (false, true, true));
  });
}
