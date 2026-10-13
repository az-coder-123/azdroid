/// Destination options for captured screenshots.
enum ScreenshotDestination {
  /// Write only to macOS system clipboard without saving a file to disk.
  clipboard,

  /// Save lossless PNG file to disk without modifying system clipboard.
  file,

  /// Both save file to disk and copy to macOS system clipboard.
  both,
}
