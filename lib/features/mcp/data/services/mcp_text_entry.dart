/// How `android_set_text` entered its text.
enum McpTextEntry {
  /// Pasted through the device clipboard: exact, immune to IME rewriting.
  pasted,

  /// Typed as key events because the clipboard is unavailable; an active IME
  /// (such as Vietnamese Telex) may still rewrite it.
  typed,

  /// Nothing was entered (element not found, or the input command failed).
  failed,
}
