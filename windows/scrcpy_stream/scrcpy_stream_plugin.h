// Windows implementation of the `com.deskdroid/video_stream` MethodChannel.
// Contract: docs/native-video-contract.md (shared with the macOS Swift plugin).
#ifndef SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_
#define SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>

#include <cstdint>
#include <memory>
#include <string>

#include "frame_texture.h"
#include "stream_session.h"

namespace scrcpy_stream {

class ScrcpyStreamPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit ScrcpyStreamPlugin(flutter::TextureRegistrar* textures);
  ~ScrcpyStreamPlugin() override;
  ScrcpyStreamPlugin(const ScrcpyStreamPlugin&) = delete;
  ScrcpyStreamPlugin& operator=(const ScrcpyStreamPlugin&) = delete;

 private:
  using MethodResult = flutter::MethodResult<flutter::EncodableValue>;

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<MethodResult> result);

  // Returns the new texture id, or -1 when the texture cannot be registered.
  int64_t StartStream(const std::string& host, uint16_t port);
  void StopStream();
  flutter::EncodableValue Dimensions() const;
  flutter::EncodableValue Stats() const;

  flutter::TextureRegistrar* textures_;
  std::shared_ptr<FrameTexture> texture_;
  int64_t texture_id_ = -1;
  std::unique_ptr<StreamSession> session_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_
