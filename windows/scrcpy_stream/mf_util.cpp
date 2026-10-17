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

MediaFoundationScope::MediaFoundationScope() {
  com_ok_ = SUCCEEDED(CoInitializeEx(nullptr, COINIT_MULTITHREADED));
  mf_ok_ = com_ok_ && CheckHr(MFStartup(MF_VERSION, MFSTARTUP_LITE), "MFStartup");
}

MediaFoundationScope::~MediaFoundationScope() {
  if (mf_ok_) MFShutdown();
  if (com_ok_) CoUninitialize();
}

}  // namespace scrcpy_stream
