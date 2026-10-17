import Foundation

/// Lifecycle state and cumulative counters for one video stream.
///
/// Swift twin of `native/scrcpy_core/stream_stats.h`. The stream thread and the
/// VideoToolbox callback record events; the platform thread reads a snapshot
/// for the `getStats` channel method. Contract: docs/native-video-contract.md.
final class ScrcpyStreamStats {
  /// Wire names shared with the Windows plugin and the Dart client.
  enum State: String {
    case idle, connecting, streaming, failed, ended
  }

  private let lock = NSLock()
  private var state: State = .idle
  private var framesDecoded: Int64 = 0
  private var bytesReceived: Int64 = 0
  private var processingTimeUs: Int64 = 0

  /// Starts a new stream: sets [newState] and clears all counters.
  func reset(to newState: State) {
    lock.lock()
    defer { lock.unlock() }
    state = newState
    framesDecoded = 0
    bytesReceived = 0
    processingTimeUs = 0
  }

  func setState(_ newState: State) {
    lock.lock()
    defer { lock.unlock() }
    state = newState
  }

  func addBytes(_ count: Int) {
    lock.lock()
    defer { lock.unlock() }
    bytesReceived += Int64(count)
  }

  /// Records one decoded frame whose packet was fully received at
  /// [receivedAtNs] (`DispatchTime.uptimeNanoseconds`).
  func recordFrame(receivedAtNs: UInt64) {
    let now = DispatchTime.now().uptimeNanoseconds
    let elapsedUs = now > receivedAtNs ? Int64((now - receivedAtNs) / 1_000) : 0
    lock.lock()
    defer { lock.unlock() }
    framesDecoded += 1
    processingTimeUs += elapsedUs
  }

  /// Channel payload for `getStats`.
  func snapshot() -> [String: Any] {
    lock.lock()
    defer { lock.unlock() }
    return [
      "state": state.rawValue,
      "framesDecoded": framesDecoded,
      "bytesReceived": bytesReceived,
      "processingTimeUs": processingTimeUs,
    ]
  }
}
