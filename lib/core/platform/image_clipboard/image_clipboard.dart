/// Contract for placing a PNG image on the host OS clipboard.
///
/// Implementations: `MacImageClipboard`, `WindowsImageClipboard`.
/// Selected once in `platform_di.dart`.
abstract class ImageClipboard {
  /// Copies the PNG at [pngPath] to the clipboard. Returns `false` on failure.
  Future<bool> copyPng(String pngPath);
}
