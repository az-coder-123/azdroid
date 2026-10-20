part of 'mcp_adb_client.dart';

/// Implements Text Injection, IME bypassing, and Keyevent dispatch for ADB MCP.
class McpAdbTextOps {
  const McpAdbTextOps._();

  /// Types text with space escaping (character-by-character via IME).
  static Future<bool> typeText(
    McpAdbClient client,
    String serial,
    String text,
  ) async {
    final escaped = text.replaceAll(' ', '%s');
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'text',
      escaped,
    ]);
    return res.exitCode == 0;
  }

  /// Injects exact text bypassing IME predictive engines and Telex autocorrect.
  static Future<bool> setText(
    McpAdbClient client,
    String serial,
    String text, {
    int? elementId,
    bool clearFirst = false,
  }) async {
    if (elementId != null) {
      final tapped = await client.clickElementById(serial, elementId);
      if (!tapped) return false;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (clearFirst) {
      await clearText(client, serial);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Set Android system clipboard and paste as atomic block.
    final copied = await client.setClipboard(serial, text);
    if (!copied) {
      return await typeText(client, serial, text);
    }

    await Future.delayed(const Duration(milliseconds: 100));
    final res = await client.run([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '279',
    ]);
    return res.exitCode == 0;
  }

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
      _ => int.tryParse(key) ?? 4,
    };
  }
}
