import Foundation

/// One audio connection: reads the scrcpy audio socket on its own thread,
/// feeds the shared jitter buffer, and runs the output device.
///
/// Each session has its own state and stop flag, so a stopped session can
/// never affect the next one. Free of Flutter (docs/native-audio-contract.md).
final class ScrcpyAudioSession {
  private static let packetHeaderSize = 12
  private static let configFlag: UInt64 = 1 << 63
  /// Upper bound for one packet; raw packets are about 4 KiB.
  private static let maxPacketSize = 1 << 20

  let stats = ScrcpyAudioStats()
  private let socket: ScrcpySocket
  private let buffer: OpaquePointer
  private let lock = NSLock()
  private var stopped = false
  private var output: ScrcpyAudioOutput?

  init(socket: ScrcpySocket, buffer: OpaquePointer) {
    self.socket = socket
    self.buffer = buffer
  }

  func start() {
    stats.setState(.connecting)
    let thread = Thread { [self] in
      defer { socket.close() }
      readLoop()
    }
    thread.name = "scrcpy-audio-reader"
    thread.qualityOfService = .userInteractive
    thread.start()
  }

  /// After this returns, the session no longer touches the buffer; the
  /// reader closes the socket within a second.
  func stop() {
    lock.lock()
    stopped = true
    let output = self.output
    self.output = nil
    lock.unlock()
    output?.stop()
    stats.setState(.idle)
  }

  private func isRunning() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return !stopped
  }

  private func report(_ state: ScrcpyAudioStats.State) {
    lock.lock()
    defer { lock.unlock() }
    if !stopped { stats.setState(state) }
  }

  private func readLoop() {
    guard let header = socket.readExact(Int(sc_audio_header_size()), isRunning: isRunning)
    else {
      report(.ended)
      return
    }
    let kind = header.withUnsafeBytes {
      sc_audio_parse_header($0.bindMemory(to: UInt8.self).baseAddress, header.count)
    }
    switch kind {
    case SC_AUDIO_STREAM_RAW:
      break
    case SC_AUDIO_STREAM_DISABLED:
      ScrcpyLog.write("[audio] Device cannot capture audio (Android 10 or older)")
      report(.disabled)
      return
    default:
      ScrcpyLog.write("[audio] Unusable audio stream (kind \(kind.rawValue))")
      report(.failed)
      return
    }
    guard startOutput() else {
      report(.failed)
      return
    }
    report(.playing)
    ScrcpyLog.write("[audio] Playing raw PCM")

    while isRunning() {
      guard let meta = socket.readExact(Self.packetHeaderSize, isRunning: isRunning) else { break }
      let flags = meta.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self).bigEndian }
      let size = Int(
        meta.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 8, as: UInt32.self).bigEndian })
      guard size > 0, size <= Self.maxPacketSize,
        let payload = socket.readExact(size, isRunning: isRunning)
      else { break }
      stats.addBytes(Self.packetHeaderSize + size)
      if flags & Self.configFlag != 0 { continue }
      push(payload)
    }
    // The loop only ends on its own when the device closes the socket.
    if isRunning() {
      ScrcpyLog.write("[audio] Device closed the audio socket")
      report(.ended)
    }
  }

  /// Pushes under the session lock, so nothing lands after stop().
  private func push(_ payload: Data) {
    lock.lock()
    defer { lock.unlock() }
    guard !stopped else { return }
    payload.withUnsafeBytes {
      sc_audio_buffer_push(buffer, $0.bindMemory(to: UInt8.self).baseAddress, payload.count)
    }
  }

  private func startOutput() -> Bool {
    let output = ScrcpyAudioOutput(buffer: buffer)
    guard output.start() else { return false }
    lock.lock()
    defer { lock.unlock() }
    guard !stopped else {
      output.stop()
      return false
    }
    self.output = output
    return true
  }
}
