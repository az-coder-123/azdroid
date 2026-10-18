import 'package:desk_droid/core/platform/host_os.dart';
import 'package:desk_droid/core/platform/shortcuts/shortcut_scheme.dart';
import 'package:flutter/material.dart';
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

  test('shortcutIcon returns command icon on macOS and keyboard on PC', () {
    expect(ShortcutScheme.mac.shortcutIcon, Icons.keyboard_command_key_rounded);
    expect(ShortcutScheme.pc.shortcutIcon, Icons.keyboard_rounded);
  });

  group('adapt string formatting', () {
    test('preserves macOS text on mac scheme', () {
      const macText =
          '⌘⇧S • Area Crop • Cmd+K • ⌘H / ⌘⌫ • Mac keyboard • to Mac';
      expect(ShortcutScheme.mac.adapt(macText), macText);
    });

    test('transforms shortcuts and platform terms on PC scheme', () {
      const pc = ShortcutScheme.pc;

      expect(pc.adapt('⌘O • Power Saver'), 'Ctrl+O • Power Saver');
      expect(pc.adapt('⌘K • Text Injector'), 'Ctrl+K • Text Injector');
      expect(pc.adapt('⌘⇧S • Area Crop'), 'Ctrl+Shift+S • Area Crop');
      expect(
        pc.adapt('⌘H / ⌘⌫ • System Nav'),
        'Ctrl+H / Ctrl+Backspace • System Nav',
      );
      expect(pc.adapt('⌘ Keys • Hotkeys'), 'Ctrl Keys • Hotkeys');
      expect(
        pc.adapt('Quick Text Injector (Cmd+K)'),
        'Quick Text Injector (Ctrl+K)',
      );
      expect(
        pc.adapt('Interactive Area Crop (Cmd+Shift+S)'),
        'Interactive Area Crop (Ctrl+Shift+S)',
      );
      expect(
        pc.adapt(
          'Core: ⌘K (Text Injector), ⌘O (Screen Toggle), ⌘R (Rotate), ⌘H (Home), ⌘⌫ (Back).',
        ),
        'Core: Ctrl+K (Text Injector), Ctrl+O (Screen Toggle), Ctrl+R (Rotate), Ctrl+H (Home), Ctrl+Backspace (Back).',
      );
      expect(
        pc.adapt('Clipboard: ⌘⇧C (Push to Phone) and ⌘⇧V (Pull to Mac).'),
        'Clipboard: Ctrl+Shift+C (Push to Phone) and Ctrl+Shift+V (Pull to PC).',
      );
      expect(
        pc.adapt('Mouse & Mac Keyboard Navigation'),
        'Mouse & Windows Keyboard Navigation',
      );
      expect(
        pc.adapt('Press Cmd+O or click the screen toggle button.'),
        'Press Ctrl+O or click the screen toggle button.',
      );
      expect(
        pc.adapt(
          'All shortcuts use the Cmd modifier for fast keyboard navigation.',
        ),
        'All shortcuts use the Ctrl modifier for fast keyboard navigation.',
      );
      // Ensures "on macOS" is not altered
      expect(
        pc.adapt(
          'Hardware decoding: VideoToolbox on macOS, Media Foundation on Windows.',
        ),
        'Hardware decoding: VideoToolbox on macOS, Media Foundation on Windows.',
      );
    });
  });
}
