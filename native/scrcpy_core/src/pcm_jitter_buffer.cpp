#include "scrcpy_core/pcm_jitter_buffer.h"

#include <algorithm>

namespace scrcpy_core {

namespace {

constexpr float kSampleScale = 1.0f / 32768.0f;
constexpr uint32_t kMillisecondsPerSecond = 1000;
// Room for one burst above the maximum before the overflow policy trims.
constexpr size_t kRingHeadroomFactor = 2;

size_t FramesFor(uint32_t sample_rate, uint32_t ms) {
  return static_cast<size_t>(sample_rate) * ms / kMillisecondsPerSecond;
}

}  // namespace

PcmJitterBuffer::PcmJitterBuffer(uint32_t sample_rate, uint32_t channels,
                                 uint32_t target_ms, uint32_t max_ms)
    : channels_(channels == 0 ? 1 : channels),
      target_frames_(FramesFor(sample_rate, target_ms)),
      max_frames_(std::max(FramesFor(sample_rate, max_ms),
                           FramesFor(sample_rate, target_ms))),
      tolerance_frames_(FramesFor(sample_rate, kAudioLatencyToleranceMs)),
      window_frames_(FramesFor(sample_rate, kAudioLatencyWindowMs)),
      ring_((max_frames_ + 1) * kRingHeadroomFactor * channels_),
      scratch_(std::max<size_t>(max_frames_, 1) * channels_) {}

void PcmJitterBuffer::Push(const uint8_t* data, size_t size) {
  if (data == nullptr || size == 0) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  const size_t frames_before = buffered_samples_ / channels_;
  size_t i = 0;
  if (has_pending_byte_) {
    AppendSampleLocked(static_cast<int16_t>(
        static_cast<uint16_t>(pending_byte_) |
        static_cast<uint16_t>(static_cast<uint16_t>(data[0]) << 8)));
    has_pending_byte_ = false;
    i = 1;
  }
  for (; i + 1 < size; i += kAudioBytesPerSample) {
    AppendSampleLocked(static_cast<int16_t>(
        static_cast<uint16_t>(data[i]) |
        static_cast<uint16_t>(static_cast<uint16_t>(data[i + 1]) << 8)));
  }
  if (i < size) {
    pending_byte_ = data[i];
    has_pending_byte_ = true;
  }
  const size_t frames_after = buffered_samples_ / channels_;
  if (frames_after > frames_before) {
    stats_.pushed_frames += frames_after - frames_before;
  }

  if (frames_after > max_frames_) {
    DropOldestLocked(frames_after - target_frames_);
  }
}

void PcmJitterBuffer::DropOldestLocked(size_t frames) {
  read_index_ = (read_index_ + frames * channels_) % ring_.size();
  buffered_samples_ -= frames * channels_;
  stats_.dropped_frames += frames;
}

void PcmJitterBuffer::ResetLatencyWindowLocked() {
  window_read_frames_ = 0;
  window_min_buffered_ = std::numeric_limits<size_t>::max();
}

void PcmJitterBuffer::TrimExcessLatencyLocked(size_t frames_read) {
  const size_t buffered = buffered_samples_ / channels_;
  window_min_buffered_ = std::min(window_min_buffered_, buffered);
  window_read_frames_ += frames_read;
  if (window_read_frames_ < window_frames_) {
    return;
  }
  if (window_min_buffered_ > target_frames_ + tolerance_frames_) {
    DropOldestLocked(window_min_buffered_ - target_frames_);
  }
  ResetLatencyWindowLocked();
}

void PcmJitterBuffer::AppendSampleLocked(int16_t sample) {
  if (buffered_samples_ == ring_.size()) {
    // Only reachable with a single push larger than the ring: drop the
    // oldest frame to make room, keeping frame alignment at the read side.
    DropOldestLocked(1);
  }
  ring_[(read_index_ + buffered_samples_) % ring_.size()] = sample;
  ++buffered_samples_;
}

size_t PcmJitterBuffer::TakeLocked(int16_t* out, size_t frames) {
  const size_t available = buffered_samples_ / channels_;
  const size_t take = std::min(frames, available);
  const size_t samples = take * channels_;
  for (size_t s = 0; s < samples; ++s) {
    out[s] = ring_[(read_index_ + s) % ring_.size()];
  }
  read_index_ = (read_index_ + samples) % ring_.size();
  buffered_samples_ -= samples;
  return take;
}

float PcmJitterBuffer::EffectiveGainLocked() const {
  return muted_ ? 0.0f : gain_ * kSampleScale;
}

template <typename Writer>
void PcmJitterBuffer::ReadLocked(size_t frames, Writer&& write) {
  if (priming_ && buffered_samples_ / channels_ >= target_frames_) {
    priming_ = false;
  }
  if (priming_) {
    return;  // Callers pre-fill silence.
  }
  const float gain = EffectiveGainLocked();
  const size_t chunk_frames = scratch_.size() / channels_;
  size_t done = 0;
  while (done < frames) {
    const size_t want = std::min(frames - done, chunk_frames);
    const size_t got = TakeLocked(scratch_.data(), want);
    for (size_t f = 0; f < got; ++f) {
      for (size_t c = 0; c < channels_; ++c) {
        write(done + f, c, static_cast<float>(scratch_[f * channels_ + c]) * gain);
      }
    }
    done += got;
    stats_.played_frames += got;
    if (got < want) {
      ++stats_.underruns;
      priming_ = true;
      ResetLatencyWindowLocked();
      return;
    }
  }
  TrimExcessLatencyLocked(frames);
}

void PcmJitterBuffer::ReadInterleaved(float* out, size_t frames) {
  if (out == nullptr) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  std::fill(out, out + frames * channels_, 0.0f);
  ReadLocked(frames, [out, this](size_t frame, size_t channel, float value) {
    out[frame * channels_ + channel] = value;
  });
}

void PcmJitterBuffer::ReadPlanar(float* const* out, size_t channel_count,
                                 size_t frames) {
  if (out == nullptr) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  for (size_t c = 0; c < channel_count; ++c) {
    std::fill(out[c], out[c] + frames, 0.0f);
  }
  ReadLocked(frames, [out, channel_count](size_t frame, size_t channel,
                                          float value) {
    if (channel < channel_count) {
      out[channel][frame] = value;
    }
  });
}

void PcmJitterBuffer::SetGain(float gain) {
  std::lock_guard<std::mutex> lock(mutex_);
  gain_ = std::clamp(gain, 0.0f, 1.0f);
}

void PcmJitterBuffer::SetMuted(bool muted) {
  std::lock_guard<std::mutex> lock(mutex_);
  muted_ = muted;
}

void PcmJitterBuffer::Clear() {
  std::lock_guard<std::mutex> lock(mutex_);
  read_index_ = 0;
  buffered_samples_ = 0;
  has_pending_byte_ = false;
  priming_ = true;
  ResetLatencyWindowLocked();
}

PcmJitterStats PcmJitterBuffer::Stats() const {
  std::lock_guard<std::mutex> lock(mutex_);
  PcmJitterStats stats = stats_;
  stats.buffered_frames = buffered_samples_ / channels_;
  return stats;
}

}  // namespace scrcpy_core
