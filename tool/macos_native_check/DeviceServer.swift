import Foundation

/// Starts scrcpy-server on a device for the native checks, with its own
/// scid, port, and jar path so a running DeskDroid is not disturbed.
/// Control is off, so the socket order is video, then audio (when on).
final class DeviceServer {
  static let localPort = 27195
  private static let scid = "7a5e000b"
  private static let remoteJar = "/data/local/tmp/deskdroid-native-check.jar"
  private static let startupDelay: TimeInterval = 2.5

  private let adb: String
  private let serial: String
  private let process = Process()

  init(adb: String, serial: String) {
    self.adb = adb
    self.serial = serial
  }

  func start(jar: String, audio: Bool) throws {
    shell(["input keyevent KEYCODE_WAKEUP"])
    run(["push", jar, Self.remoteJar])
    process.executableURL = URL(fileURLWithPath: adb)
    process.arguments = [
      "-s", serial, "shell", "CLASSPATH=\(Self.remoteJar)", "app_process", "/",
      "com.genymobile.scrcpy.Server", "3.3.4", "scid=\(Self.scid)", "tunnel_forward=true",
      "control=false", "audio=\(audio)", "audio_codec=raw", "cleanup=true",
      "video_bit_rate=2000000",
    ]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
    Thread.sleep(forTimeInterval: Self.startupDelay)
    run(["forward", "tcp:\(Self.localPort)", "localabstract:scrcpy_\(Self.scid)"])
  }

  func stop() {
    process.terminate()
    run(["forward", "--remove", "tcp:\(Self.localPort)"])
    shell(["rm -f \(Self.remoteJar)"])
  }

  /// Changes what is on screen, so the encoder produces frames.
  func changeScreen() {
    shell(["am start -a android.settings.SETTINGS"])
  }

  private func shell(_ command: [String]) {
    run(["shell"] + command)
  }

  @discardableResult
  private func run(_ arguments: [String]) -> String {
    let child = Process()
    child.executableURL = URL(fileURLWithPath: adb)
    child.arguments = ["-s", serial] + arguments
    let pipe = Pipe()
    child.standardOutput = pipe
    child.standardError = pipe
    try? child.run()
    child.waitUntilExit()
    return String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  }
}
