#include "winsock_connection.h"

#include <ws2tcpip.h>

#include <algorithm>
#include <climits>

#include "stream_log.h"

namespace scrcpy_stream {

namespace {

constexpr WORD kWinsockVersion = MAKEWORD(2, 2);

}  // namespace

WinsockScope::WinsockScope() {
  WSADATA data = {};
  ok_ = WSAStartup(kWinsockVersion, &data) == 0;
  if (!ok_) {
    StreamLog("WSAStartup failed: " + std::to_string(WSAGetLastError()));
  }
}

WinsockScope::~WinsockScope() {
  if (ok_) {
    WSACleanup();
  }
}

WinsockConnection::~WinsockConnection() { Close(); }

bool WinsockConnection::Connect(const std::string& host, uint16_t port,
                                uint32_t recv_timeout_ms) {
  Close();
  SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (sock == INVALID_SOCKET) {
    return false;
  }

  sockaddr_in address = {};
  address.sin_family = AF_INET;
  address.sin_port = htons(port);
  if (inet_pton(AF_INET, host.c_str(), &address.sin_addr) != 1 ||
      connect(sock, reinterpret_cast<const sockaddr*>(&address),
              sizeof(address)) != 0) {
    closesocket(sock);
    return false;
  }

  const DWORD timeout = recv_timeout_ms;
  setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO,
             reinterpret_cast<const char*>(&timeout), sizeof(timeout));
  socket_ = sock;
  return true;
}

ReadResult WinsockConnection::ReadExact(uint8_t* buffer, size_t size,
                                        const std::atomic<bool>& keep_running) {
  size_t total = 0;
  while (total < size) {
    if (!keep_running) {
      return ReadResult::kCancelled;
    }
    const SOCKET sock = socket_;
    if (sock == INVALID_SOCKET) {
      return ReadResult::kCancelled;
    }
    const int chunk = static_cast<int>(std::min<size_t>(size - total, INT_MAX));
    const int received =
        recv(sock, reinterpret_cast<char*>(buffer + total), chunk, 0);
    if (received > 0) {
      total += static_cast<size_t>(received);
      continue;
    }
    if (received == 0) {
      return ReadResult::kClosed;
    }
    const int error = WSAGetLastError();
    if (error == WSAETIMEDOUT || error == WSAEINTR) {
      continue;  // Poll keep_running again.
    }
    return keep_running ? ReadResult::kError : ReadResult::kCancelled;
  }
  return ReadResult::kOk;
}

void WinsockConnection::Close() {
  const SOCKET sock = socket_.exchange(INVALID_SOCKET);
  if (sock != INVALID_SOCKET) {
    shutdown(sock, SD_BOTH);
    closesocket(sock);
  }
}

}  // namespace scrcpy_stream
