#include "stream_log.h"

#include <windows.h>

#include <chrono>
#include <cstdio>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <mutex>

namespace scrcpy_stream {

namespace {

constexpr wchar_t kLogFileName[] = L"scrcpy_stream.log";

std::filesystem::path LogFilePath() {
  wchar_t temp_dir[MAX_PATH + 1] = {};
  const DWORD length = GetTempPathW(MAX_PATH + 1, temp_dir);
  if (length == 0 || length > MAX_PATH) {
    return std::filesystem::path(kLogFileName);
  }
  return std::filesystem::path(temp_dir) / kLogFileName;
}

std::string Timestamp() {
  const std::time_t now =
      std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
  std::tm local = {};
  localtime_s(&local, &now);
  char buffer[32] = {};
  std::strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &local);
  return buffer;
}

}  // namespace

void StreamLog(const std::string& message) {
  static std::mutex mutex;
  const std::string line = "[" + Timestamp() + "] [ScrcpyStream] " + message + "\n";

  std::lock_guard<std::mutex> lock(mutex);
  OutputDebugStringA(line.c_str());
  std::ofstream file(LogFilePath(), std::ios::app);
  if (file) {
    file << line;
  }
}

}  // namespace scrcpy_stream
