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
        'android_type_text can only type ASCII characters: Android\'s '
        '`input text` crashes on others (accents, CJK, emoji). Use '
        'android_set_text, which pastes through the clipboard on devices '
        'that support it.',
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

    // Move to end, Select All (Ctrl+A), and Delete (DEL) in a single shell invocation.
    const cmd =
        'input keyevent 123 && input keyevent --meta 4096 29 && input keyevent 67';
    final res = await client.run(['-s', serial, 'shell', cmd]);
    return res.exitCode == 0;
  }

  /// Sends hardware keyevent by keycode.
  static Future<bool> pressKey(
    McpAdbClient client,
    String serial,
    int keyCode,
  ) async {
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

  /// Maps human-friendly key names to Android KeyEvent integers.
  static int resolveKeyCode(String key) {
    return switch (key.toUpperCase().trim()) {
      'HOME' => 3,
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
              'Unknown key "$key". Use BACK, HOME, APP_SWITCH, ENTER, TAB, '
              'POWER, VOLUME_UP, VOLUME_DOWN, or a numeric Android key code.',
            )),
    };
  }
}
