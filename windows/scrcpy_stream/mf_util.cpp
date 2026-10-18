#include "mf_util.h"

#include <mfapi.h>
#include <objbase.h>

#include <cstdio>
#include <string>

#include "stream_log.h"

namespace scrcpy_stream {

bool CheckHr(HRESULT hr, const char* step) {
  if (SUCCEEDED(hr)) return true;
  char code[16] = {};
  std::snprintf(code, sizeof(code), "0x%08lX", static_cast<unsigned long>(hr));
  StreamLog(std::string(step) + " failed: " + code);
  return false;
}

bool IsMediaFoundationInstalled() {
  // Loading the DLL once is enough; it stays loaded for the delay-load stubs.
  static const bool installed =
      LoadLibraryExW(L"mfplat.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32) !=
      nullptr;
  return installed;
}

MediaFoundationScope::MediaFoundationScope() {
  com_ok_ = SUCCEEDED(CoInitializeEx(nullptr, COINIT_MULTITHREADED));
  if (!IsMediaFoundationInstalled()) {
    StreamLog("Media Foundation is not installed (Windows N/KN edition?)");
    return;
  }
  mf_ok_ = com_ok_ && CheckHr(MFStartup(MF_VERSION, MFSTARTUP_LITE), "MFStartup");
}

MediaFoundationScope::~MediaFoundationScope() {
  if (mf_ok_) MFShutdown();
  if (com_ok_) CoUninitialize();
}

}  // namespace scrcpy_stream
