import Cocoa
import CoreVideo
import FlutterMacOS

/// MethodChannel `com.deskdroid/video_stream` and the Flutter texture of the
/// mirrored screen (docs/native-video-contract.md).
///
/// The reading and decoding live in [ScrcpyVideoSession]; this class owns
/// the texture and hands the latest decoded frame to Flutter.
public class ScrcpyStreamPlugin: NSObject, FlutterPlugin, FlutterTexture {
  private static var shared: ScrcpyStreamPlugin?
  private static let channelName = "com.deskdroid/video_stream"
  private static let defaultHost = "127.0.0.1"
  private static let defaultPort = 27183

  private weak var textureRegistry: FlutterTextureRegistry?
  private var textureId: Int64?
  private var session: ScrcpyVideoSession?
  private let sessionLock = NSLock()
  /// Reported by getStats while no session exists.
  private let idleStats = ScrcpyStreamStats()
  private var currentPixelBuffer: CVPixelBuffer?
  private let pixelBufferLock = NSLock()

  static func streamLog(_ message: String) {
    ScrcpyLog.write(message)
  }

  public init(textures: FlutterTextureRegistry) {
    self.textureRegistry = textures
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    let instance = ScrcpyStreamPlugin(textures: registrar.textures)
    shared = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
    streamLog("Registered via FlutterPluginRegistrar")
  }

  @objc public static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: controller.engine.binaryMessenger)
    let instance = ScrcpyStreamPlugin(textures: controller.engine)
    shared = instance
    channel.setMethodCallHandler { call, result in
      ScrcpyStreamPlugin.shared?.handle(call, result: result)
    }
    streamLog("Registered successfully with controller.engine")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    ScrcpyLog.write("MethodChannel handle called: \(call.method)")
    switch call.method {
    case "startStream":
      let args = call.arguments as? [String: Any] ?? [:]
      startStream(
        host: args["host"] as? String ?? Self.defaultHost,
        port: args["port"] as? Int ?? Self.defaultPort,
        result: result)
    case "stopStream":
      stopStream()
      result(true)
    case "getDimensions":
      let size = currentSession()?.videoSize() ?? (width: 0, height: 0)
      result(["width": size.width, "height": size.height])
    case "getStats":
      result((currentSession()?.stats ?? idleStats).snapshot())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    pixelBufferLock.lock()
    defer { pixelBufferLock.unlock() }
    guard let buffer = currentPixelBuffer else { return nil }
    return Unmanaged.passRetained(buffer)
  }

  private func currentSession() -> ScrcpyVideoSession? {
    sessionLock.lock()
    defer { sessionLock.unlock() }
    return session
  }

  private func startStream(host: String, port: Int, result: @escaping FlutterResult) {
    ScrcpyLog.write("startStream invoked for \(host):\(port)")
    stopStream()
    guard let registry = textureRegistry else {
      ScrcpyLog.write("ERROR: textureRegistry is nil")
      result(FlutterError(code: "NO_REGISTRY", message: "Texture registry unavailable", details: nil))
      return
    }
    let id = registry.register(self)
    textureId = id
    ScrcpyLog.write("Texture registered with ID: \(id)")

    let session = ScrcpyVideoSession(host: host, port: port) { [weak self] frame in
      self?.publish(frame, textureId: id)
    }
    sessionLock.lock()
    self.session = session
    sessionLock.unlock()
    session.start()
    result(id)
  }

  /// Stop order: the producer first (no frame after session.stop()), then
  /// the texture.
  private func stopStream() {
    sessionLock.lock()
    let session = self.session
    self.session = nil
    sessionLock.unlock()
    session?.stop()

    if let id = textureId {
      textureRegistry?.unregisterTexture(id)
      textureId = nil
    }
    pixelBufferLock.lock()
    currentPixelBuffer = nil
    pixelBufferLock.unlock()
  }

  private func publish(_ frame: CVPixelBuffer, textureId id: Int64) {
    pixelBufferLock.lock()
    currentPixelBuffer = frame
    pixelBufferLock.unlock()
    DispatchQueue.main.async { [weak self] in
      // Ignore frames of a texture that was replaced meanwhile.
      guard let self, self.textureId == id else { return }
      self.textureRegistry?.textureFrameAvailable(id)
    }
  }
}
