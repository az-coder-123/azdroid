// H.264 Annex B decoder built on the Media Foundation H.264 MFT.
//
// Milestone 1a: software output to system-memory NV12 frames. Input may carry
// SPS/PPS inline (see scrcpy_core::ConfigPacketMerger); resolution and
// rotation changes are handled through MF_E_TRANSFORM_STREAM_CHANGE.
//
// Must be created, used, and destroyed on one thread that has COM and
// Media Foundation initialized (see MediaFoundationScope in mf_util.h).
#ifndef SCRCPY_STREAM_MF_H264_DECODER_H_
#define SCRCPY_STREAM_MF_H264_DECODER_H_

#include <mfapi.h>
#include <mftransform.h>
#include <wrl/client.h>

#include <cstddef>
#include <cstdint>
#include <functional>

#include "scrcpy_core/nv12_converter.h"

namespace scrcpy_stream {

class MfH264Decoder {
 public:
  // Receives each decoded frame; the image is valid only during the call.
  using FrameCallback = std::function<void(const scrcpy_core::Nv12Image&)>;

  MfH264Decoder() = default;
  ~MfH264Decoder();
  MfH264Decoder(const MfH264Decoder&) = delete;
  MfH264Decoder& operator=(const MfH264Decoder&) = delete;

  // Creates the MFT. [width]/[height] are hints from the stream header.
  bool Initialize(uint32_t width, uint32_t height);

  // Decodes one access unit (Annex B) and emits every frame it produces.
  bool Decode(const uint8_t* data, size_t size, int64_t pts_us,
              const FrameCallback& on_frame);

  // Flushes and releases the MFT. Safe to call more than once.
  void Shutdown();

 private:
  bool ConfigureOutputType();
  bool DrainOutput(const FrameCallback& on_frame);
  bool EmitSample(IMFSample* sample, const FrameCallback& on_frame);
  HRESULT CreateOutputSample(IMFSample** sample) const;

  Microsoft::WRL::ComPtr<IMFTransform> transform_;
  MFT_OUTPUT_STREAM_INFO output_info_ = {};
  uint32_t coded_width_ = 0;
  uint32_t coded_height_ = 0;
  uint32_t display_width_ = 0;
  uint32_t display_height_ = 0;
  int frame_count_ = 0;
};

}  // namespace scrcpy_stream

#endif  // SCRCPY_STREAM_MF_H264_DECODER_H_
