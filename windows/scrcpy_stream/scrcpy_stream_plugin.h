// Windows implementation of the `com.azdroid/video_stream` MethodChannel
// (docs/native-video-contract.md) and owner of the audio channel
// (docs/native-audio-contract.md). Shared contracts with the macOS plugins.
#ifndef SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_
#define SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>

#include <cstdint>
#include <memory>
#include <string>

#include "audio_channel.h"
#include "frame_texture.h"
#include "stream_session.h"

namespace scrcpy_stream {

class ScrcpyStreamPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  ScrcpyStreamPlugin(flutter::TextureRegistrar* textures,
                     flutter::BinaryMessenger* messenger);
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
  // Second channel of this plugin: docs/native-audio-contract.md.
  std::unique_ptr<AudioChannel> audio_;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_H_
