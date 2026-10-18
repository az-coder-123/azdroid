#include "scrcpy_stream_plugin.h"

#include <flutter/standard_method_codec.h>

#include <utility>
#include <variant>

#include "channel_args.h"
#include "stream_config.h"
#include "stream_log.h"

namespace scrcpy_stream {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr char kStartStream[] = "startStream";
constexpr char kStopStream[] = "stopStream";
constexpr char kGetDimensions[] = "getDimensions";
constexpr char kGetStats[] = "getStats";
constexpr char kNoRegistryCode[] = "NO_REGISTRY";

}  // namespace

void ScrcpyStreamPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<ScrcpyStreamPlugin>(
      registrar->texture_registrar(), registrar->messenger());
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
  StreamLog("Registered " + std::string(kChannelName));
}

ScrcpyStreamPlugin::ScrcpyStreamPlugin(flutter::TextureRegistrar* textures,
                                       flutter::BinaryMessenger* messenger)
    : textures_(textures), audio_(std::make_unique<AudioChannel>(messenger)) {}

ScrcpyStreamPlugin::~ScrcpyStreamPlugin() { StopStream(); }

void ScrcpyStreamPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<MethodResult> result) {
  const std::string& method = call.method_name();
  if (method == kStartStream) {
    const auto* args = std::get_if<EncodableMap>(call.arguments());
    const int64_t id = StartStream(ReadHost(args), ReadPort(args));
    if (id < 0) {
      result->Error(kNoRegistryCode, "Texture registry unavailable");
    } else {
      result->Success(EncodableValue(id));
    }
  } else if (method == kStopStream) {
    StopStream();
    result->Success(EncodableValue(true));
  } else if (method == kGetDimensions) {
    result->Success(Dimensions());
  } else if (method == kGetStats) {
    result->Success(Stats());
  } else {
    result->NotImplemented();
  }
}

int64_t ScrcpyStreamPlugin::StartStream(const std::string& host, uint16_t port) {
  StreamLog("startStream " + host + ":" + std::to_string(port));
  StopStream();
  if (textures_ == nullptr) return -1;

  texture_ = std::make_shared<FrameTexture>();
  texture_id_ = textures_->RegisterTexture(texture_->variant());

  const int64_t id = texture_id_;
  flutter::TextureRegistrar* textures = textures_;
  session_ = std::make_unique<StreamSession>(
      host, port, texture_->frames(),
      // MarkTextureFrameAvailable is safe to call from any thread.
      [textures, id] { textures->MarkTextureFrameAvailable(id); });
  session_->Start();
  return texture_id_;
}

void ScrcpyStreamPlugin::StopStream() {
  // Stop the producer first so no frame is announced for a removed texture.
  if (session_) {
    session_->Stop();
    session_.reset();
  }
  if (texture_id_ >= 0 && textures_ != nullptr) {
    // The callback holds the last reference until the engine has let go.
    textures_->UnregisterTexture(texture_id_, [texture = std::move(texture_)] {});
  }
  texture_.reset();
  texture_id_ = -1;
}

EncodableValue ScrcpyStreamPlugin::Dimensions() const {
  const int32_t width = session_ ? static_cast<int32_t>(session_->width()) : 0;
  const int32_t height = session_ ? static_cast<int32_t>(session_->height()) : 0;
  return EncodableValue(EncodableMap{
      {EncodableValue("width"), EncodableValue(width)},
      {EncodableValue("height"), EncodableValue(height)},
  });
}

EncodableValue ScrcpyStreamPlugin::Stats() const {
  const scrcpy_core::StreamStatsSnapshot stats =
      session_ ? session_->stats() : scrcpy_core::StreamStatsSnapshot{};
  return EncodableValue(EncodableMap{
      {EncodableValue("state"),
       EncodableValue(std::string(scrcpy_core::StreamStateName(stats.state)))},
      {EncodableValue("framesDecoded"),
       EncodableValue(static_cast<int64_t>(stats.frames_decoded))},
      {EncodableValue("bytesReceived"),
       EncodableValue(static_cast<int64_t>(stats.bytes_received))},
      {EncodableValue("processingTimeUs"),
       EncodableValue(static_cast<int64_t>(stats.processing_time_us))},
  });
}

}  // namespace scrcpy_stream
