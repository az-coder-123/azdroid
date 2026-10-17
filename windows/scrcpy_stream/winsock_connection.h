// Blocking TCP client for the local `adb forward` tunnel.
#ifndef SCRCPY_STREAM_WINSOCK_CONNECTION_H_
#define SCRCPY_STREAM_WINSOCK_CONNECTION_H_

#include <winsock2.h>

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <string>

namespace scrcpy_stream {

// Keeps Winsock initialized for the lifetime of the object (WSAStartup is
// reference counted, so nesting is safe).
class WinsockScope {
 public:
  WinsockScope();
  ~WinsockScope();
  WinsockScope(const WinsockScope&) = delete;
  WinsockScope& operator=(const WinsockScope&) = delete;

  bool ok() const { return ok_; }

 private:
  bool ok_ = false;
};

enum class ReadResult { kOk, kClosed, kError, kCancelled };

class WinsockConnection {
 public:
  WinsockConnection() = default;
  ~WinsockConnection();
  WinsockConnection(const WinsockConnection&) = delete;
  WinsockConnection& operator=(const WinsockConnection&) = delete;

  // Connects to host:port (IPv4) with a receive timeout used for polling.
  bool Connect(const std::string& host, uint16_t port, uint32_t recv_timeout_ms);

  // Reads exactly [size] bytes. Receive timeouts are retried while
  // [keep_running] is true, so Close() from another thread ends the read.
  ReadResult ReadExact(uint8_t* buffer, size_t size,
                       const std::atomic<bool>& keep_running);

  // Thread-safe: unblocks a pending ReadExact and releases the socket.
  void Close();

 private:
  std::atomic<SOCKET> socket_{INVALID_SOCKET};
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_WINSOCK_CONNECTION_H_
