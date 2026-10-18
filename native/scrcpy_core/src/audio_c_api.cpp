#include "scrcpy_core/audio_c_api.h"

#include "scrcpy_core/audio_header.h"
#include "scrcpy_core/pcm_jitter_buffer.h"

struct ScAudioBuffer {
  scrcpy_core::PcmJitterBuffer impl{
      scrcpy_core::kAudioSampleRate, scrcpy_core::kAudioChannels,
      scrcpy_core::kAudioTargetBufferMs, scrcpy_core::kAudioMaxBufferMs};
};

extern "C" {

uint32_t sc_audio_sample_rate(void) { return scrcpy_core::kAudioSampleRate; }

uint32_t sc_audio_channels(void) { return scrcpy_core::kAudioChannels; }

size_t sc_audio_header_size(void) { return scrcpy_core::kAudioHeaderSize; }

ScAudioStreamKind sc_audio_parse_header(const uint8_t* data, size_t size) {
  const auto header = scrcpy_core::ParseAudioHeader(data, size);
  if (!header) {
    return SC_AUDIO_STREAM_INVALID;
  }
  switch (header->kind) {
    case scrcpy_core::AudioStreamKind::kRaw:
      return SC_AUDIO_STREAM_RAW;
    case scrcpy_core::AudioStreamKind::kDisabled:
      return SC_AUDIO_STREAM_DISABLED;
    case scrcpy_core::AudioStreamKind::kConfigError:
      return SC_AUDIO_STREAM_CONFIG_ERROR;
    case scrcpy_core::AudioStreamKind::kUnsupportedCodec:
      return SC_AUDIO_STREAM_UNSUPPORTED_CODEC;
  }
  return SC_AUDIO_STREAM_UNSUPPORTED_CODEC;
}

ScAudioBuffer* sc_audio_buffer_create(void) { return new ScAudioBuffer(); }

void sc_audio_buffer_destroy(ScAudioBuffer* buffer) { delete buffer; }

void sc_audio_buffer_push(ScAudioBuffer* buffer, const uint8_t* data,
                          size_t size) {
  if (buffer != nullptr) {
    buffer->impl.Push(data, size);
  }
}

void sc_audio_buffer_read_planar(ScAudioBuffer* buffer, float* const* out,
                                 size_t channel_count, size_t frames) {
  if (buffer != nullptr) {
    buffer->impl.ReadPlanar(out, channel_count, frames);
  }
}

void sc_audio_buffer_set_gain(ScAudioBuffer* buffer, float gain) {
  if (buffer != nullptr) {
    buffer->impl.SetGain(gain);
  }
}

void sc_audio_buffer_set_muted(ScAudioBuffer* buffer, bool muted) {
  if (buffer != nullptr) {
    buffer->impl.SetMuted(muted);
  }
}

void sc_audio_buffer_clear(ScAudioBuffer* buffer) {
  if (buffer != nullptr) {
    buffer->impl.Clear();
  }
}

ScAudioBufferStats sc_audio_buffer_stats(const ScAudioBuffer* buffer) {
  ScAudioBufferStats out{};
  if (buffer == nullptr) {
    return out;
  }
  const scrcpy_core::PcmJitterStats stats = buffer->impl.Stats();
  out.buffered_frames = stats.buffered_frames;
  out.pushed_frames = stats.pushed_frames;
  out.played_frames = stats.played_frames;
  out.dropped_frames = stats.dropped_frames;
  out.underruns = stats.underruns;
  return out;
}

}  // extern "C"
