/// Abstract contract for bidirectional clipboard synchronization.
abstract class ClipboardRepository {
  /// Reads current text content from macOS system clipboard.
  Future<String?> getHostClipboard();

  /// Writes text content to macOS system clipboard.
  Future<void> setHostClipboard(String text);

  /// Reads current text content from the Android device clipboard.
  Future<String?> getDeviceClipboard(String deviceSerial);

  /// Sets text content on the Android device clipboard.
  Future<bool> setDeviceClipboard(String deviceSerial, String text);

  /// Synchronizes text from macOS clipboard to Android device clipboard.
  Future<bool> syncHostToDevice(String deviceSerial);

  /// Synchronizes text from Android device clipboard to macOS clipboard.
  Future<bool> syncDeviceToHost(String deviceSerial);
}
