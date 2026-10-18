import Foundation

/// Thread-safe audio state for `getAudioStats` (docs/native-audio-contract.md).
/// Jitter buffer counters come from scrcpy_core at snapshot time.
final class ScrcpyAudioStats {
  enum State: String {
    case idle, connecting, playing, disabled, failed, ended
  }

  private let lock = NSLock()
  private var state = State.idle
  private var bytesReceived = 0

  func setState(_ newState: State) {
    lock.lock()
    defer { lock.unlock() }
    state = newState
  }

  func currentState() -> State {
    lock.lock()
    defer { lock.unlock() }
    return state
  }

  func addBytes(_ count: Int) {
    lock.lock()
    defer { lock.unlock() }
    bytesReceived += count
  }

  func reset() {
    lock.lock()
    defer { lock.unlock() }
    state = .idle
    bytesReceived = 0
  }

  func snapshot(buffer: ScAudioBufferStats) -> [String: Any] {
    lock.lock()
    defer { lock.unlock() }
    return [
      "state": state.rawValue,
      "bytesReceived": bytesReceived,
      "bufferedFrames": Int(buffer.buffered_frames),
      "playedFrames": Int(buffer.played_frames),
      "droppedFrames": Int(buffer.dropped_frames),
      "underruns": Int(buffer.underruns),
    ]
  }
}
