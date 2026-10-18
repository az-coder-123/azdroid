#include "audio_channel.h"

#include <flutter/standard_method_codec.h>

#include <string>
#include <utility>
#include <variant>

#include "channel_args.h"
#include "stream_config.h"
#include "stream_log.h"

namespace scrcpy_stream {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr char kIsAvailable[] = "isAvailable";
constexpr char kStartAudio[] = "startAudio";
constexpr char kStopAudio[] = "stopAudio";
constexpr char kSetVolume[] = "setVolume";
constexpr char kSetMuted[] = "setMuted";
constexpr char kGetAudioStats[] = "getAudioStats";
constexpr char kVolumeKey[] = "volume";
constexpr char kMutedKey[] = "muted";
constexpr double kDefaultVolume = 1.0;

EncodableValue Int(uint64_t value) {
  return EncodableValue(static_cast<int64_t>(value));
}

}  // namespace

AudioChannel::AudioChannel(flutter::BinaryMessenger* messenger)
    : channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, kAudioChannelName,
          &flutter::StandardMethodCodec::GetInstance())),
      buffer_(std::make_shared<scrcpy_core::PcmJitterBuffer>(
          scrcpy_core::kAudioSampleRate, scrcpy_core::kAudioChannels,
          scrcpy_core::kAudioTargetBufferMs, scrcpy_core::kAudioMaxBufferMs)) {
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
  StreamLog("Registered " + std::string(kAudioChannelName));
}

AudioChannel::~AudioChannel() {
  channel_->SetMethodCallHandler(nullptr);
  StopAudio();
}

void AudioChannel::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<MethodResult> result) {
  const std::string& method = call.method_name();
  const auto* args = std::get_if<EncodableMap>(call.arguments());
  if (method == kIsAvailable) {
    result->Success(EncodableValue(true));
  } else if (method == kStartAudio) {
    result->Success(EncodableValue(StartAudio(args)));
  } else if (method == kStopAudio) {
    StopAudio();
    result->Success(EncodableValue(true));
  } else if (method == kSetVolume) {
    buffer_->SetGain(
        static_cast<float>(ReadDouble(args, kVolumeKey, kDefaultVolume)));
    result->Success(EncodableValue(true));
  } else if (method == kSetMuted) {
    buffer_->SetMuted(ReadBool(args, kMutedKey, false));
    result->Success(EncodableValue(true));
  } else if (method == kGetAudioStats) {
    result->Success(Stats());
  } else {
    result->NotImplemented();
  }
}

bool AudioChannel::StartAudio(const EncodableMap* args) {
  StopAudio();
  buffer_->Clear();
  auto session = std::make_unique<AudioSession>(buffer_);
  if (!session->Start(ReadHost(args), ReadPort(args))) {
    idle_state_ = scrcpy_core::AudioState::kFailed;
    return false;
  }
  session_ = std::move(session);
  return true;
}

void AudioChannel::StopAudio() {
  if (!session_) return;
  session_->Stop();
  session_.reset();
  buffer_->Clear();
  idle_state_ = scrcpy_core::AudioState::kIdle;
  StreamLog("[audio] Stopped");
}

EncodableValue AudioChannel::Stats() const {
  const scrcpy_core::PcmJitterStats buffer = buffer_->Stats();
  const scrcpy_core::AudioState state = session_ ? session_->state() : idle_state_;
  return EncodableValue(EncodableMap{
      {EncodableValue("state"),
       EncodableValue(std::string(scrcpy_core::AudioStateName(state)))},
      {EncodableValue("bytesReceived"),
       Int(session_ ? session_->bytes_received() : 0)},
      {EncodableValue("bufferedFrames"), Int(buffer.buffered_frames)},
      {EncodableValue("playedFrames"), Int(buffer.played_frames)},
      {EncodableValue("droppedFrames"), Int(buffer.dropped_frames)},
      {EncodableValue("underruns"), Int(buffer.underruns)},
  });
}

}  // namespace scrcpy_stream
