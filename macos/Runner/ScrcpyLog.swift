import Foundation

/// Diagnostic log shared by the native scrcpy plugins: the system log plus
/// `/tmp/scrcpy_stream.log` (docs/native-video-contract.md). Free of Flutter,
/// so the audio session can also run in the command-line check.
enum ScrcpyLog {
  private static let path = "/tmp/scrcpy_stream.log"
  private static let lock = NSLock()

  static func write(_ message: String) {
    NSLog("[ScrcpyStream] %@", message)
    guard let data = "[\(Date())] \(message)\n".data(using: .utf8) else { return }
    lock.lock()
    defer { lock.unlock() }
    if let handle = FileHandle(forWritingAtPath: path) {
      handle.seekToEndOfFile()
      handle.write(data)
      handle.closeFile()
    } else {
      try? data.write(to: URL(fileURLWithPath: path))
    }
  }
}
