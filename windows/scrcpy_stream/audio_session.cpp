#include "audio_session.h"

#include <array>
#include <utility>
#include <vector>

#include "scrcpy_core/audio_header.h"
#include "scrcpy_core/packet_header.h"
#include "stream_config.h"
#include "stream_log.h"

namespace scrcpy_stream {

namespace {

using scrcpy_core::AudioState;
using scrcpy_core::AudioStreamKind;

}  // namespace

AudioSession::AudioSession(std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer)
    : buffer_(std::move(buffer)) {}

AudioSession::~AudioSession() { Stop(); }

bool AudioSession::Start(const std::string& host, uint16_t port) {
  Stop();
  if (!winsock_.ok() || !connection_.Connect(host, port, kReceiveTimeoutMs)) {
    StreamLog("[audio] Connect to " + host + ":" + std::to_string(port) + " failed");
    state_ = AudioState::kFailed;
    return false;
  }
  state_ = AudioState::kConnecting;
  bytes_received_ = 0;
  running_ = true;
  thread_ = std::thread([this] { Run(); });
  StreamLog("[audio] Socket connected to " + host + ":" + std::to_string(port));
  return true;
}

void AudioSession::Stop() {
  const bool was_running = running_.exchange(false);
  connection_.Close();  // Unblocks a pending recv().
  if (thread_.joinable()) thread_.join();
  if (was_running) state_ = AudioState::kIdle;
}

void AudioSession::Report(AudioState state) {
  if (running_) state_ = state;
}

void AudioSession::Push(const uint8_t* data, size_t size) {
  std::lock_guard<std::mutex> lock(push_mutex_);
  if (running_) buffer_->Push(data, size);
}

void AudioSession::Run() {
  std::array<uint8_t, scrcpy_core::kAudioHeaderSize> header_bytes{};
  if (connection_.ReadExact(header_bytes.data(), header_bytes.size(), running_) !=
      ReadResult::kOk) {
    Report(AudioState::kEnded);
    return;
  }
  const auto header =
      scrcpy_core::ParseAudioHeader(header_bytes.data(), header_bytes.size());
  if (!header || header->kind != AudioStreamKind::kRaw) {
    const AudioStreamKind kind =
        header ? header->kind : AudioStreamKind::kUnsupportedCodec;
    StreamLog(std::string("[audio] No playable audio: ") +
              scrcpy_core::AudioStreamKindName(kind));
    Report(kind == AudioStreamKind::kDisabled ? AudioState::kDisabled
                                              : AudioState::kFailed);
    return;
  }

  output_ = std::make_unique<WasapiAudioOutput>(buffer_);
  if (!output_->Start()) {
    output_.reset();
    Report(AudioState::kFailed);
    return;
  }
  Report(AudioState::kPlaying);
  StreamLog("[audio] Playing raw PCM");

  std::array<uint8_t, scrcpy_core::kPacketHeaderSize> meta{};
  std::vector<uint8_t> payload;
  while (running_) {
    if (connection_.ReadExact(meta.data(), meta.size(), running_) != ReadResult::kOk) {
      break;
    }
    const auto packet = scrcpy_core::ParsePacketHeader(meta.data(), meta.size());
    if (!packet) break;
    if (packet->is_session) continue;  // Video only; never sent for audio.
    payload.resize(packet->payload_size);
    if (connection_.ReadExact(payload.data(), payload.size(), running_) !=
        ReadResult::kOk) {
      break;
    }
    bytes_received_ += meta.size() + payload.size();
    if (!packet->is_config) Push(payload.data(), payload.size());
  }
  output_->Stop();
  output_.reset();
  // The loop only ends on its own when the device closes the socket.
  if (running_) {
    StreamLog("[audio] Device closed the audio socket");
    Report(AudioState::kEnded);
  }
}

}  // namespace scrcpy_stream
