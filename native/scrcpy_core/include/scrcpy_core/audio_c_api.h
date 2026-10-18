/* C interface to the audio part of scrcpy_core, for callers that cannot use
 * C++ directly (the macOS Swift plugin, through its bridging header).
 * Windows uses the C++ classes. Contract: docs/native-audio-contract.md. */
#ifndef SCRCPY_CORE_AUDIO_C_API_H_
#define SCRCPY_CORE_AUDIO_C_API_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Kind of audio stream announced by the 4-byte audio header. */
typedef enum {
  SC_AUDIO_STREAM_RAW = 0,
  SC_AUDIO_STREAM_DISABLED = 1,
  SC_AUDIO_STREAM_CONFIG_ERROR = 2,
  SC_AUDIO_STREAM_UNSUPPORTED_CODEC = 3,
  SC_AUDIO_STREAM_INVALID = 4 /* fewer than 4 bytes */
} ScAudioStreamKind;

typedef struct {
  uint64_t buffered_frames;
  uint64_t pushed_frames;
  uint64_t played_frames;
  uint64_t dropped_frames;
  uint64_t underruns;
} ScAudioBufferStats;

typedef struct ScAudioBuffer ScAudioBuffer;

uint32_t sc_audio_sample_rate(void);
uint32_t sc_audio_channels(void);
size_t sc_audio_header_size(void);
ScAudioStreamKind sc_audio_parse_header(const uint8_t* data, size_t size);

/* Creates a jitter buffer with the default format and buffering
 * (48 kHz stereo, 50 ms target, 200 ms maximum). Never returns NULL. */
ScAudioBuffer* sc_audio_buffer_create(void);
void sc_audio_buffer_destroy(ScAudioBuffer* buffer);
void sc_audio_buffer_push(ScAudioBuffer* buffer, const uint8_t* data,
                          size_t size);
void sc_audio_buffer_read_planar(ScAudioBuffer* buffer, float* const* out,
                                 size_t channel_count, size_t frames);
void sc_audio_buffer_set_gain(ScAudioBuffer* buffer, float gain);
void sc_audio_buffer_set_muted(ScAudioBuffer* buffer, bool muted);
void sc_audio_buffer_clear(ScAudioBuffer* buffer);
ScAudioBufferStats sc_audio_buffer_stats(const ScAudioBuffer* buffer);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // SCRCPY_CORE_AUDIO_C_API_H_
