import Darwin
import Foundation

/// Blocking TCP socket to an `adb forward` port, for the scrcpy streams.
///
/// Reads wake up every second (`SO_RCVTIMEO`) so a stop request is honored
/// without closing the socket from another thread.
final class ScrcpySocket {
  private var descriptor: Int32
  private static let receiveTimeoutSeconds = 1

  private init(descriptor: Int32) {
    self.descriptor = descriptor
  }

  /// Connects to [host]:[port]; `nil` when the connection fails.
  static func connect(host: String, port: Int) -> ScrcpySocket? {
    let sock = Darwin.socket(AF_INET, SOCK_STREAM, 0)
    guard sock >= 0 else { return nil }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = in_port_t(UInt16(port).bigEndian)
    guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
      Darwin.close(sock)
      return nil
    }
    let connected = withUnsafePointer(to: &address) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Darwin.connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
      }
    }
    guard connected == 0 else {
      Darwin.close(sock)
      return nil
    }
    var timeout = timeval(tv_sec: receiveTimeoutSeconds, tv_usec: 0)
    setsockopt(
      sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
    return ScrcpySocket(descriptor: sock)
  }

  /// Reads exactly [count] bytes. Returns `nil` on end of stream, on an
  /// error, or when [isRunning] turns false while waiting.
  func readExact(_ count: Int, isRunning: () -> Bool) -> Data? {
    var data = Data(count: count)
    var total = 0
    while total < count {
      guard isRunning(), descriptor >= 0 else { return nil }
      let read = data.withUnsafeMutableBytes { buffer -> Int in
        guard let base = buffer.baseAddress else { return -1 }
        return Darwin.recv(descriptor, base.advanced(by: total), count - total, 0)
      }
      if read > 0 {
        total += read
      } else if read == 0 {
        return nil
      } else if errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
        return nil
      }
    }
    return data
  }

  func close() {
    guard descriptor >= 0 else { return }
    Darwin.close(descriptor)
    descriptor = -1
  }

  deinit {
    close()
  }
}
