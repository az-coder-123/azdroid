// Media Foundation / COM helpers shared by the decoder.
#ifndef SCRCPY_STREAM_MF_UTIL_H_
#define SCRCPY_STREAM_MF_UTIL_H_

#include <windows.h>

namespace scrcpy_stream {

// Initializes COM (multithreaded) and Media Foundation for the current thread
// and shuts both down on destruction.
class MediaFoundationScope {
 public:
  MediaFoundationScope();
  ~MediaFoundationScope();
  MediaFoundationScope(const MediaFoundationScope&) = delete;
  MediaFoundationScope& operator=(const MediaFoundationScope&) = delete;

  bool ok() const { return com_ok_ && mf_ok_; }

 private:
  bool com_ok_ = false;
  bool mf_ok_ = false;
};

// Logs "<step> failed: 0x........" when [hr] is a failure.
// Returns true on success.
bool CheckHr(HRESULT hr, const char* step);

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_MF_UTIL_H_
