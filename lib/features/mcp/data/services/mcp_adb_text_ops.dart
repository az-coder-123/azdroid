part of 'mcp_adb_client.dart';

/// Implements Text Injection, IME bypassing, and Keyevent dispatch for ADB MCP.
class McpAdbTextOps {
  const McpAdbTextOps._();

  /// Types [text] as key events (`adb shell input text`).
  ///
  /// `input text` only handles ASCII: other characters crash it (verified on
  /// Android 10 and 13), so they are rejected with an explanation. The text
  /// is single-quoted for the device shell, which `adb shell` runs it through:
  /// unquoted, `it's` broke the command and `a; reboot` ran `reboot`.
  static Future<bool> typeText(
    McpAdbClient client,
    String serial,
    String text,
  ) async {
    if (!isAscii(text)) {
      throw const McpUnsupportedOnDeviceException(
        'Typing (android_input_text method "type") handles ASCII only: '
        'Android\'s `input text` crashes on other characters (accents, CJK, '
        'emoji). Use method "paste", which pastes through the clipboard on '
        'devices that support it.',
      );
    }
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'text',
      // `input text` reads %s as a space; the device shell gets one quoted word.
      shellQuote(text.replaceAll(' ', '%s')),
    ]);
    return res.exitCode == 0;
  }

  /// Whether every character of [text] is 7-bit ASCII.
  static bool isAscii(String text) => text.codeUnits.every((c) => c < 0x80);

  /// [value] as one single-quoted word for a POSIX shell.
  static String shellQuote(String value) =>
      "'${value.replaceAll("'", "'\\''")}'";

  /// Sets exact text in the focused field (or element [elementId]).
  ///
  /// Pastes through the device clipboard (which it replaces), so an IME such
  /// as Telex cannot alter it. Where the clipboard cannot be set over adb
  /// (no `cmd clipboard`, as on the Android 10 and 13 devices tested), ASCII
  /// text is typed instead and other text fails with an explanation; the
  /// result says which happened.
  static Future<McpTextEntry> setText(
    McpAdbClient client,
    String serial,
    String text, {
    int? elementId,
    bool clearFirst = false,
  }) async {
    if (elementId != null) {
      final tapped = await client.clickElementById(serial, elementId);
      if (!tapped) return McpTextEntry.failed;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (clearFirst) {
      await clearText(client, serial);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (await _paste(client, serial, text)) return McpTextEntry.pasted;
    if (!isAscii(text)) {
      throw const McpUnsupportedOnDeviceException(
        'This device cannot set its clipboard over adb (no `cmd clipboard` '
        'shell command), so non-ASCII text (accents, CJK, emoji) cannot be '
        'entered. ASCII text still works.',
      );
    }
    return await typeText(client, serial, text)
        ? McpTextEntry.typed
        : McpTextEntry.failed;
  }

  /// Puts [text] on the clipboard and sends the paste key; `false` when the
  /// clipboard is unavailable or the paste key fails.
  static Future<bool> _paste(
    McpAdbClient client,
    String serial,
    String text,
  ) async {
    try {
      await McpAdbDeviceOps.setClipboard(client, serial, text);
    } on McpUnsupportedOnDeviceException {
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '$_keycodePaste',
    ]);
    return res.exitCode == 0;
  }

  /// Android `KEYCODE_PASTE`.
  static const int _keycodePaste = 279;

  /// Clears text in the focused field or focuses an element by ID before clearing.
  static Future<bool> clearText(
    McpAdbClient client,
    String serial, {
    int? elementId,
  }) async {
    if (elementId != null) {
      final tapped = await client.clickElementById(serial, elementId);
      if (!tapped) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Select all (Ctrl+A) and delete. `input keycombination` exists on
    // Android 13+; Android 10 prints its usage instead. `input keyevent
    // --meta` is not supported on either, so it never selected anything.
    final selectAll = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keycombination',
      '113',
      '29',
    ]);
    if (selectAll.succeeded && !'${selectAll.stdout}'.contains('Usage:')) {
      return (await client.run([
        '-s',
        serial,
        'shell',
        'input',
        'keyevent',
        '67',
      ])).succeeded;
    }

    // Older Android: move to the end and delete the focused field's text,
    // one DEL per character (read from the UI tree; a hint counts too, and
    // extra DELs on an empty field do nothing).
    final length = focusedTextLength(await client.dumpHierarchy(serial));
    if (length == null) return false;
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '123',
      ...List.filled(length, '67'),
    ]);
    return res.succeeded;
  }

  /// Length of the focused node's `text` in a uiautomator dump, or `null`
  /// when no node is focused.
  static int? focusedTextLength(String xml) {
    final node = RegExp(r'<node [^>]*focused="true"[^>]*>').firstMatch(xml);
    if (node == null) return null;
    final text = RegExp(r' text="([^"]*)"').firstMatch(node[0]!)?[1] ?? '';
    return text.replaceAll(RegExp('&[a-z]+;|&#[0-9]+;'), '_').length;
  }

  /// Presses key [keyCode]: through the scrcpy session when it runs
  /// ([McpFastInput]), otherwise `input keyevent`.
  static Future<bool> pressKey(
    McpAdbClient client,
    String serial,
    int keyCode,
  ) async {
    if (await McpFastInput.pressKey(client, serial, keyCode)) return true;
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '$keyCode',
    ]);
    return res.exitCode == 0;
  }

  /// Maps key names (with or without `KEYCODE_`) to Android KeyEvent
  /// codes; gamepad and D-pad keys drive games.
  static int resolveKeyCode(String key) {
    return switch (key.toUpperCase().trim().replaceFirst('KEYCODE_', '')) {
      'HOME' => 3,
      'DPAD_UP' => 19,
      'DPAD_DOWN' => 20,
      'DPAD_LEFT' => 21,
      'DPAD_RIGHT' => 22,
      'DPAD_CENTER' => 23,
      'SPACE' => 62,
      'DEL' => 67,
      'ESCAPE' => 111,
      'BUTTON_A' => 96,
      'BUTTON_B' => 97,
      'BUTTON_X' => 99,
      'BUTTON_Y' => 100,
      'BUTTON_L1' => 102,
      'BUTTON_R1' => 103,
      'BUTTON_START' => 108,
      'BUTTON_SELECT' => 109,
      'BACK' => 4,
      'VOLUME_UP' => 24,
      'VOLUME_DOWN' => 25,
      'POWER' => 26,
      'TAB' => 61,
      'ENTER' => 66,
      'APP_SWITCH' => 187,
      final other =>
        int.tryParse(other) ??
            (throw McpUnsupportedOnDeviceException(
              'Unknown key "$key". Use a listed name (BACK, HOME, DPAD_UP, '
              'BUTTON_A, …) or a numeric Android key code.',
            )),
    };
  }
}
