import FlutterMacOS
import Foundation

/// MethodChannel `com.deskdroid/audio_stream` (docs/native-audio-contract.md).
///
/// Owns the jitter buffer (so volume and mute survive sessions) and the
/// current [ScrcpyAudioSession], which does the reading and playing.
final class ScrcpyAudioPlugin: NSObject {
  private static var shared: ScrcpyAudioPlugin?
  private static let channelName = "com.deskdroid/audio_stream"

  private let buffer: OpaquePointer = sc_audio_buffer_create()
  private let lock = NSLock()
  private var session: ScrcpyAudioSession?
  /// Last state of a failed connect, when no session exists.
  private let idleStats = ScrcpyAudioStats()

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.engine.binaryMessenger)
    let instance = ScrcpyAudioPlugin()
    shared = instance
    channel.setMethodCallHandler { call, result in
      ScrcpyAudioPlugin.shared?.handle(call, result: result)
    }
  }

  deinit {
    stop()
    sc_audio_buffer_destroy(buffer)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "isAvailable":
      result(true)
    case "startAudio":
      let host = args["host"] as? String ?? "127.0.0.1"
      let port = args["port"] as? Int ?? 27183
      // Connecting to the local forward is quick, but keep it off the
      // platform thread.
      DispatchQueue.global(qos: .userInitiated).async {
        let connected = self.start(host: host, port: port)
        DispatchQueue.main.async { result(connected) }
      }
    case "stopAudio":
      stop()
      result(true)
    case "setVolume":
      sc_audio_buffer_set_gain(buffer, Float(args["volume"] as? Double ?? 1))
      result(true)
    case "setMuted":
      sc_audio_buffer_set_muted(buffer, args["muted"] as? Bool ?? false)
      result(true)
    case "getAudioStats":
      lock.lock()
      let stats = session?.stats ?? idleStats
      lock.unlock()
      result(stats.snapshot(buffer: sc_audio_buffer_stats(buffer)))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Replaces any session with a new one; `true` once the socket connected.
  private func start(host: String, port: Int) -> Bool {
    stop()
    guard let socket = ScrcpySocket.connect(host: host, port: port) else {
      ScrcpyLog.write("[audio] Connect to \(host):\(port) failed")
      idleStats.setState(.failed)
      return false
    }
    sc_audio_buffer_clear(buffer)
    let session = ScrcpyAudioSession(socket: socket, buffer: buffer)
    lock.lock()
    self.session = session
    lock.unlock()
    session.start()
    ScrcpyLog.write("[audio] Socket connected to \(host):\(port)")
    return true
  }

  private func stop() {
    lock.lock()
    let session = self.session
    self.session = nil
    lock.unlock()
    guard let session else { return }
    session.stop()
    sc_audio_buffer_clear(buffer)
    idleStats.reset()
    ScrcpyLog.write("[audio] Stopped")
  }
}
