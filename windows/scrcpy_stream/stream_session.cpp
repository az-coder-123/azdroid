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
    return;
  }

  const auto header = ConnectAndReadHeader();
  if (header) {
    PumpPackets(*header);
  } else if (running_) {
    StreamLog("Failed to connect and read the stream header after retries");
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
    if (connection_.ReadExact(bytes.data(), bytes.size(), running_) != ReadResult::kOk) {
      StreamLog("Attempt " + std::to_string(attempt) +
                ": connected but header not ready, retrying");
      connection_.Close();
      SleepWhileRunning(kHeaderRetryDelay);
      continue;
    }
    auto header = scrcpy_core::ParseStreamHeader(bytes.data(), bytes.size());
    if (header) {
      width_ = header->width;
      height_ = header->height;
      StreamLog("Header OK: device=" + header->device_name + ", codec=" +
                header->codec + ", " + std::to_string(header->width) + "x" +
                std::to_string(header->height));
    }
    return header;
  }
  return std::nullopt;
}

void StreamSession::PumpPackets(const scrcpy_core::StreamHeader& header) {
  if (header.codec != kSupportedCodec) {
    StreamLog("Codec '" + header.codec + "' is not supported; expected h264");
    return;
  }
  MfH264Decoder decoder;
  if (!decoder.Initialize(header.width, header.height)) {
    return;
  }

  scrcpy_core::ConfigPacketMerger merger;
  std::array<uint8_t, scrcpy_core::kPacketHeaderSize> header_bytes = {};
  std::vector<uint8_t> payload;
  std::vector<uint8_t> access_unit;
  const auto on_frame = [this](const scrcpy_core::Nv12Image& image) {
    PublishFrame(image);
  };

  for (int index = 1; running_; ++index) {
    if (connection_.ReadExact(header_bytes.data(), header_bytes.size(), running_) !=
        ReadResult::kOk) {
      break;
    }
    const auto packet =
        scrcpy_core::ParsePacketHeader(header_bytes.data(), header_bytes.size());
    if (!packet) {
      StreamLog("Invalid packet header; closing stream");
      break;
    }
    payload.resize(packet->payload_size);
    if (connection_.ReadExact(payload.data(), payload.size(), running_) !=
        ReadResult::kOk) {
      break;
    }
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
}

}  // namespace scrcpy_stream
