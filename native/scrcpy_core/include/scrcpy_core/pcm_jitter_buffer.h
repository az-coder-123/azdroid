// Jitter buffer between the audio socket (producer) and the host audio
// device callback (consumer), for scrcpy raw audio: 16-bit little-endian
// PCM, interleaved. See docs/native-audio-contract.md.
//
// Policy, kept deliberately simple:
//   - Priming: output silence until [target_ms] of audio is buffered, at
//     start and after every underrun, so playback restarts cleanly.
//   - Underrun: when the device callback asks for more than is buffered, the
//     rest is silence, the underrun is counted, and the buffer primes again.
//   - Overflow: when more than [max_ms] is buffered (network burst, or the
//     device clock running faster than the host), the oldest audio is
//     dropped down to [target_ms], so latency cannot grow without bound.
//
// Thread safety: Push() and the Read*() calls may run on different threads.
// A mutex guards short copies only; no allocation happens after creation.
#ifndef SCRCPY_CORE_PCM_JITTER_BUFFER_H_
#define SCRCPY_CORE_PCM_JITTER_BUFFER_H_

#include <cstddef>
#include <cstdint>
#include <mutex>
#include <vector>

namespace scrcpy_core {

// scrcpy-server's raw audio format (AudioConfig.java).
inline constexpr uint32_t kAudioSampleRate = 48000;
inline constexpr uint32_t kAudioChannels = 2;
inline constexpr size_t kAudioBytesPerSample = 2;

// Buffering defaults: scrcpy's own client targets 50 ms.
inline constexpr uint32_t kAudioTargetBufferMs = 50;
inline constexpr uint32_t kAudioMaxBufferMs = 200;

struct PcmJitterStats {
  uint64_t buffered_frames = 0;  // Frames waiting to be played now.
  uint64_t pushed_frames = 0;    // Frames received in total.
  uint64_t played_frames = 0;    // Frames handed to the device (not silence).
  uint64_t dropped_frames = 0;   // Frames discarded by the overflow policy.
  uint64_t underruns = 0;        // Reads that ran out of audio.
};

class PcmJitterBuffer {
 public:
  PcmJitterBuffer(uint32_t sample_rate, uint32_t channels, uint32_t target_ms,
                  uint32_t max_ms);

  PcmJitterBuffer(const PcmJitterBuffer&) = delete;
  PcmJitterBuffer& operator=(const PcmJitterBuffer&) = delete;

  // Appends raw PCM bytes. A trailing partial sample or frame is kept and
  // completed by the next call, so packet boundaries do not matter.
  void Push(const uint8_t* data, size_t size);

  // Writes [frames] frames of interleaved float samples (-1..1), gain
  // applied. Silence fills whatever is not available.
  void ReadInterleaved(float* out, size_t frames);

  // Same as ReadInterleaved, into one buffer per channel ([channel_count]
  // must equal the buffer's channel count; extra channels get silence).
  void ReadPlanar(float* const* out, size_t channel_count, size_t frames);

  // Linear gain applied on read, clamped to 0..1.
  void SetGain(float gain);
  void SetMuted(bool muted);

  // Drops all buffered audio and primes again (for example on reconnect).
  void Clear();

  PcmJitterStats Stats() const;

  uint32_t channels() const { return channels_; }

 private:
  // Copies up to [frames] buffered frames into [out] (interleaved int16) and
  // returns how many were copied. Caller holds mutex_.
  size_t TakeLocked(int16_t* out, size_t frames);
  // Shared read path: hands each played sample to [write](frame, channel,
  // value); unplayed positions keep the silence the caller pre-filled.
  template <typename Writer>
  void ReadLocked(size_t frames, Writer&& write);
  void AppendSampleLocked(int16_t sample);
  float EffectiveGainLocked() const;

  const uint32_t channels_;
  const size_t target_frames_;
  const size_t max_frames_;

  mutable std::mutex mutex_;
  std::vector<int16_t> ring_;     // Capacity: max_frames_ + headroom.
  size_t read_index_ = 0;         // In samples.
  size_t buffered_samples_ = 0;
  uint8_t pending_byte_ = 0;      // Low byte of a sample split across pushes.
  bool has_pending_byte_ = false;
  bool priming_ = true;
  float gain_ = 1.0f;
  bool muted_ = false;
  std::vector<int16_t> scratch_;  // Read staging, sized at creation.
  PcmJitterStats stats_;
};

}  // namespace scrcpy_core

#endif  // SCRCPY_CORE_PCM_JITTER_BUFFER_H_
