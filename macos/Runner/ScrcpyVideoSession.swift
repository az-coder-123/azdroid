import CoreVideo
import Foundation

/// One video connection: connects to the scrcpy video socket with the
/// contract's retry policy, reads the header and packets on its own thread,
/// and decodes them. Contract: docs/native-video-contract.md.
///
/// Each session owns its socket, decoder, state, and stop flag; only its
/// reader thread closes the socket and the decoder, so a stopped session
/// cannot affect the next one. Free of Flutter.
final class ScrcpyVideoSession {
  private static let connectAttempts = 30
  private static let connectRetryDelay: TimeInterval = 0.3
  private static let headerRetryDelay: TimeInterval = 0.4
  private static let deviceNameSize = 64
  private static let codecIdSize = 4
  private static let packetHeaderSize = 12
  // scrcpy v4.0+ media flags: bit 63 marks a session packet (video size),
  // bit 62 a codec config packet, bit 61 a key frame.
  private static let sessionFlag: UInt64 = 1 << 63
  private static let configFlag: UInt64 = 1 << 62
  private static let keyFrameFlag: UInt64 = 1 << 61
  private static let packetLogCount = 5
  private static let packetLogInterval = 60

  let stats = ScrcpyStreamStats()
  private let host: String
  private let port: Int
  private let onFrame: (CVPixelBuffer) -> Void
  private let lock = NSLock()
  private var stopped = false
  /// The socket being read, so stop() can wake the reader at once.
  private var socket: ScrcpySocket?
  private var width = 0
  private var height = 0

  /// [onFrame] runs on VideoToolbox's thread, never after stop().
  init(host: String, port: Int, onFrame: @escaping (CVPixelBuffer) -> Void) {
    self.host = host
    self.port = port
    self.onFrame = onFrame
  }

  func start() {
    stats.reset(to: .connecting)
    let thread = Thread { [self] in run() }
    thread.name = "com.deskdroid.scrcpy_stream"
    thread.start()
  }

  /// After this returns, no frame is delivered. The connection ends at
  /// once; the reader thread then closes the socket and the decoder.
  func stop() {
    lock.lock()
    stopped = true
    width = 0
    height = 0
    let socket = self.socket
    lock.unlock()
    socket?.interrupt()
    stats.reset(to: .idle)
  }

  /// Publishes [socket] as the one stop() interrupts; returns false (and
  /// closes it) when the session is already stopped.
  private func adopt(_ socket: ScrcpySocket) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard !stopped else {
      socket.close()
      return false
    }
    self.socket = socket
    return true
  }

  /// Latest video size: the stream header, then every new SPS.
  func videoSize() -> (width: Int, height: Int) {
    lock.lock()
    defer { lock.unlock() }
    return (width, height)
  }

  private func isRunning() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return !stopped
  }

  /// Sets [state] unless stopped (the contract: failed/ended only while
  /// not stopped).
  private func report(_ state: ScrcpyStreamStats.State) {
    lock.lock()
    defer { lock.unlock() }
    if !stopped { stats.setState(state) }
  }

  private func setVideoSize(width newWidth: Int, height newHeight: Int) {
    guard newWidth > 0, newHeight > 0 else { return }
    lock.lock()
    defer { lock.unlock() }
    guard !stopped, (newWidth, newHeight) != (width, height) else { return }
    width = newWidth
    height = newHeight
    ScrcpyLog.write("Video size changed to \(newWidth)x\(newHeight)")
  }

  private func deliver(_ frame: CVPixelBuffer, receivedAt: UInt64) {
    lock.lock()
    defer { lock.unlock() }
    guard !stopped else { return }
    stats.recordFrame(receivedAtNs: receivedAt)
    onFrame(frame)
  }

  private func run() {
    ScrcpyLog.write("runStreamLoop: connecting to \(host):\(port)...")
    guard let socket = connectAndReadHeader() else {
      ScrcpyLog.write("Failed to establish video stream and read header after retries")
      report(.failed)
      return
    }
    defer { socket.close() }
    report(.streaming)

    let decoder = ScrcpyH264Decoder(
      onFrame: { [weak self] frame, receivedAt in self?.deliver(frame, receivedAt: receivedAt) },
      onSizeChange: { [weak self] width, height in
        self?.setVideoSize(width: width, height: height)
      })
    defer { decoder.invalidate() }
    readPackets(from: socket, into: decoder)

    ScrcpyLog.write("Stream loop terminated.")
    // The loop only exits on its own when the device closes the stream.
    report(.ended)
  }

  /// Same retry policy as the Windows plugin (30 x 300 ms; 400 ms after a
  /// missing header). Returns the socket after a complete header.
  private func connectAndReadHeader() -> ScrcpySocket? {
    for attempt in 1...Self.connectAttempts {
      guard isRunning() else { return nil }
      guard let socket = ScrcpySocket.connect(host: host, port: port) else {
        Thread.sleep(forTimeInterval: Self.connectRetryDelay)
        continue
      }
      guard adopt(socket) else { return nil }
      // 1. The dummy byte proves the server accepted this video socket. The
      //    rest of the header arrives only after the client connects the
      //    remaining sockets (audio, control), so report "connected".
      guard socket.readExact(1, isRunning: isRunning) != nil else {
        ScrcpyLog.write("Attempt \(attempt): Connected but server not ready yet, retrying...")
        socket.close()
        Thread.sleep(forTimeInterval: Self.headerRetryDelay)
        continue
      }
      report(.connected)
      ScrcpyLog.write("Attempt \(attempt): Video socket accepted; waiting for stream header")

      // 2. Device name and codec id. The video size follows in the first
      //    session packet.
      let metaSize = Self.deviceNameSize + Self.codecIdSize
      guard let meta = socket.readExact(metaSize, isRunning: isRunning) else {
        ScrcpyLog.write("Attempt \(attempt): Stream header not received, retrying...")
        report(.connecting)
        socket.close()
        Thread.sleep(forTimeInterval: Self.headerRetryDelay)
        continue
      }
      let name = String(decoding: meta.prefix(Self.deviceNameSize), as: UTF8.self)
        .replacingOccurrences(of: "\0", with: "")
      let codec = String(decoding: meta.dropFirst(Self.deviceNameSize).prefix(Self.codecIdSize), as: UTF8.self)
      ScrcpyLog.write("Attempt \(attempt): Header OK! dev=\(name), codec=\(codec)")
      return socket
    }
    return nil
  }

  /// Packets: 8 bytes PTS and flags, 4 bytes size, then the payload. A
  /// session packet instead carries flags (4), width (4) and height (4), and
  /// no payload; it comes first and again on each capture change.
  private func readPackets(from socket: ScrcpySocket, into decoder: ScrcpyH264Decoder) {
    var index = 0
    while isRunning() {
      guard let meta = socket.readExact(Self.packetHeaderSize, isRunning: isRunning) else { return }
      let flags = meta.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self).bigEndian }
      let size = Int(meta.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 8, as: UInt32.self).bigEndian })
      if flags & Self.sessionFlag != 0 {
        let width = Int(meta.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: UInt32.self).bigEndian })
        let height = size  // Bytes 8..<12 hold the height in a session packet.
        ScrcpyLog.write("Session: \(width)x\(height)")
        stats.addBytes(Self.packetHeaderSize)
        setVideoSize(width: width, height: height)
        continue
      }
      guard size > 0, let payload = socket.readExact(size, isRunning: isRunning) else { return }
      let receivedAt = DispatchTime.now().uptimeNanoseconds
      stats.addBytes(Self.packetHeaderSize + size)

      let isConfig = flags & Self.configFlag != 0
      index += 1
      if index <= Self.packetLogCount || index % Self.packetLogInterval == 0 {
        ScrcpyLog.write(
          "Packet #\(index): size=\(size), isConfig=\(isConfig), isKey=\(flags & Self.keyFrameFlag != 0)")
      }
      if isConfig {
        decoder.applyConfig(payload)
      } else {
        decoder.decode(payload, receivedAt: receivedAt)
      }
    }
  }
}
