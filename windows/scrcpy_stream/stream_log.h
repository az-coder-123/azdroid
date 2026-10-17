// Diagnostic logging for the native video pipeline.
//
// Writes to the debugger (OutputDebugString) and appends to
// %TEMP%\scrcpy_stream.log, the Windows counterpart of the macOS
// /tmp/scrcpy_stream.log.
#ifndef SCRCPY_STREAM_STREAM_LOG_H_
#define SCRCPY_STREAM_STREAM_LOG_H_

#include <string>

namespace scrcpy_stream {

void StreamLog(const std::string& message);

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_STREAM_LOG_H_
