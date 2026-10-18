#include "stream_session.h"

#include <array>
#include <utility>
#include <vector>

#include "mf_h264_decoder.h"
#include "mf_util.h"
#include "scrcpy_core/config_packet_merger.h"
#include "scrcpy_core/packet_header.h"
#include "stream_config.h"
#include "stream_log.h"

namespace scrcpy_stream {

namespace {

constexpr char kSupportedCodec[] = "h264";

using scrcpy_core::StreamState;

}  // namespace

StreamSession::StreamSession(std::string host, uint16_t port,
                             std::shared_ptr<scrcpy_core::LatestFrameBuffer> frames,
                             FrameReadyCallback on_frame_ready)
    : host_(std::move(host)),
      port_(port),
      frames_(std::move(frames)),
      on_frame_ready_(std::move(on_frame_ready)) {}

StreamSession::~StreamSession() { Stop(); }

void StreamSession::Start() {
  Stop();
  stats_.SetState(StreamState::kConnecting);
  running_ = true;
  thread_ = std::thread([this] { Run(); });
}

void StreamSession::Stop() {
  {
    std::lock_guard<std::mutex> lock(wake_mutex_);
    running_ = false;
  }
  wake_.notify_all();
  connection_.Close();  // Unblocks a pending recv().
  if (thread_.joinable()) {
    thread_.join();
  }
}

bool StreamSession::SleepWhileRunning(std::chrono::milliseconds delay) {
  std::unique_lock<std::mutex> lock(wake_mutex_);
  wake_.wait_for(lock, delay, [this] { return !running_.load(); });
  return running_;
}

void StreamSession::Run() {
  StreamLog("Session thread started for " + host_ + ":" + std::to_string(port_));
  WinsockScope winsock;
  MediaFoundationScope media_foundation;
  if (!winsock.ok() || !media_foundation.ok()) {
    StreamLog("Platform initialization failed; stream not started");
    stats_.SetState(StreamState::kFailed);
    return;
  }

  const auto header = ConnectAndReadHeader();
  if (!header) {
    if (running_) {
      StreamLog("Failed to connect and read the stream header after retries");
      stats_.SetState(StreamState::kFailed);
    }
  } else if (!PumpPackets(*header)) {
    stats_.SetState(StreamState::kFailed);
  } else if (running_) {
    // The loop only exits on its own when the device closes the stream.
    StreamLog("Stream closed by the device");
    stats_.SetState(StreamState::kEnded);
  }
  connection_.Close();
  StreamLog("Session thread finished");
}

std::optional<scrcpy_core::StreamHeader> StreamSession::ConnectAndReadHeader() {
  std::array<uint8_t, scrcpy_core::kStreamHeaderSize> bytes = {};
  for (int attempt = 1; attempt <= kConnectAttempts && running_; ++attempt) {
    if (!connection_.Connect(host_, port_, kReceiveTimeoutMs)) {
      SleepWhileRunning(kConnectRetryDelay);
      continue;
    }
    // The dummy byte proves the server accepted this video socket. The rest of
    // the header arrives only after the client connects the other sockets
    // (audio, control), so report "connected" for the Dart side to open them.
    if (connection_.ReadExact(bytes.data(), 1, running_) != ReadResult::kOk) {
      StreamLog("Attempt " + std::to_string(attempt) +
                ": connected but server not ready, retrying");
      connection_.Close();
      SleepWhileRunning(kHeaderRetryDelay);
      continue;
    }
    stats_.SetState(StreamState::kConnected);
    if (connection_.ReadExact(bytes.data() + 1, bytes.size() - 1, running_) !=
        ReadResult::kOk) {
      StreamLog("Attempt " + std::to_string(attempt) +
                ": stream header not received, retrying");
      stats_.SetState(StreamState::kConnecting);
      connection_.Close();
      SleepWhileRunning(kHeaderRetryDelay);
      continue;
    }
    auto header = scrcpy_core::ParseStreamHeader(bytes.data(), bytes.size());
    if (header) {
      StreamLog("Header OK: device=" + header->device_name + ", codec=" +
                header->codec);
    }
    return header;
  }
  return std::nullopt;
}

bool StreamSession::PumpPackets(const scrcpy_core::StreamHeader& header) {
  if (header.codec != kSupportedCodec) {
    StreamLog("Codec '" + header.codec + "' is not supported; expected h264");
    return false;
  }
  // The first packet is a session packet with the video size (v4.0+), like
  // the official client expects.
  std::array<uint8_t, scrcpy_core::kPacketHeaderSize> header_bytes = {};
  const auto session = ReadPacketHeader(header_bytes);
  if (!session || !session->is_session) {
    StreamLog("Expected a session packet with the video size; closing stream");
    return false;
  }
  ApplySession(*session);
  MfH264Decoder decoder;
  if (!decoder.Initialize(session->session_width, session->session_height)) {
    return false;
  }
  stats_.SetState(StreamState::kStreaming);

  scrcpy_core::ConfigPacketMerger merger;
  std::vector<uint8_t> payload;
  std::vector<uint8_t> access_unit;
  const auto on_frame = [this](const scrcpy_core::Nv12Image& image) {
    PublishFrame(image);
  };

  for (int index = 1; running_; ++index) {
    const auto packet = ReadPacketHeader(header_bytes);
    if (!packet) break;
    if (packet->is_session) {
      // A new capture session (rotation): the decoder adapts through
      // MF_E_TRANSFORM_STREAM_CHANGE; only the reported size changes here.
      ApplySession(*packet);
      continue;
    }
    payload.resize(packet->payload_size);
    if (connection_.ReadExact(payload.data(), payload.size(), running_) !=
        ReadResult::kOk) {
      break;
    }
    packet_received_at_ = std::chrono::steady_clock::now();
    stats_.AddBytes(header_bytes.size() + payload.size());
    if (index <= kVerboseLogCount || index % kPeriodicLogInterval == 0) {
      StreamLog("Packet #" + std::to_string(index) + ": size=" +
                std::to_string(packet->payload_size) +
                ", config=" + std::to_string(packet->is_config) +
                ", key=" + std::to_string(packet->is_key_frame));
    }
    if (merger.Push(payload.data(), payload.size(), packet->is_config, access_unit)) {
      decoder.Decode(access_unit.data(), access_unit.size(),
                     static_cast<int64_t>(packet->pts_us), on_frame);
    }
  }
  decoder.Shutdown();
  return true;
}

std::optional<scrcpy_core::PacketHeader> StreamSession::ReadPacketHeader(
    std::array<uint8_t, scrcpy_core::kPacketHeaderSize>& bytes) {
  if (connection_.ReadExact(bytes.data(), bytes.size(), running_) !=
      ReadResult::kOk) {
    return std::nullopt;
  }
  auto packet = scrcpy_core::ParsePacketHeader(bytes.data(), bytes.size());
  if (!packet) StreamLog("Invalid packet header; closing stream");
  return packet;
}

void StreamSession::ApplySession(const scrcpy_core::PacketHeader& session) {
  width_ = session.session_width;
  height_ = session.session_height;
  StreamLog("Session: " + std::to_string(session.session_width) + "x" +
            std::to_string(session.session_height));
}

void StreamSession::PublishFrame(const scrcpy_core::Nv12Image& image) {
  scrcpy_core::PixelFrame& frame = frames_->BeginWrite(image.width, image.height);
  // Flutter's Windows pixel-buffer textures expect RGBA byte order.
  scrcpy_core::ConvertNv12(image, scrcpy_core::PixelOrder::kRgba,
                           frame.pixels.data(), frame.stride());
  frames_->Publish();
  width_ = image.width;
  height_ = image.height;
  on_frame_ready_();
  const auto elapsed = std::chrono::duration_cast<std::chrono::microseconds>(
      std::chrono::steady_clock::now() - packet_received_at_);
  stats_.AddFrame(static_cast<uint64_t>(elapsed.count()));
}

}  // namespace scrcpy_stream
