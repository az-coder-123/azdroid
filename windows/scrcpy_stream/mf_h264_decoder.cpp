#include "mf_h264_decoder.h"

#include <codecapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <objbase.h>
#include <wmcodecdsp.h>

#include <cstring>
#include <string>

#include "mf_util.h"
#include "stream_config.h"
#include "stream_log.h"

using Microsoft::WRL::ComPtr;

namespace scrcpy_stream {

MfH264Decoder::~MfH264Decoder() { Shutdown(); }

bool MfH264Decoder::Initialize(uint32_t width, uint32_t height) {
  Shutdown();
  if (!CheckHr(CoCreateInstance(CLSID_CMSH264DecoderMFT, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&transform_)),
             "CoCreateInstance(H264 MFT)")) {
    return false;
  }

  // Emit frames as soon as they are decoded instead of buffering for reorder.
  ComPtr<ICodecAPI> codec_api;
  if (SUCCEEDED(transform_.As(&codec_api))) {
    VARIANT low_latency;
    VariantInit(&low_latency);
    low_latency.vt = VT_UI4;
    low_latency.ulVal = TRUE;
    CheckHr(codec_api->SetValue(&CODECAPI_AVLowLatencyMode, &low_latency),
          "Enable low-latency mode");
  }

  ComPtr<IMFMediaType> input_type;
  if (!CheckHr(MFCreateMediaType(&input_type), "MFCreateMediaType") ||
      !CheckHr(input_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video), "Set major type") ||
      !CheckHr(input_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_H264), "Set H264 subtype") ||
      !CheckHr(input_type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive),
             "Set progressive") ||
      !CheckHr(MFSetAttributeSize(input_type.Get(), MF_MT_FRAME_SIZE, width, height),
             "Set input frame size") ||
      !CheckHr(transform_->SetInputType(0, input_type.Get(), 0), "SetInputType")) {
    Shutdown();
    return false;
  }

  if (!ConfigureOutputType() ||
      !CheckHr(transform_->ProcessMessage(MFT_MESSAGE_NOTIFY_BEGIN_STREAMING, 0),
             "Begin streaming") ||
      !CheckHr(transform_->ProcessMessage(MFT_MESSAGE_NOTIFY_START_OF_STREAM, 0),
             "Start of stream")) {
    Shutdown();
    return false;
  }
  StreamLog("Media Foundation H.264 decoder initialized");
  return true;
}

bool MfH264Decoder::ConfigureOutputType() {
  for (DWORD index = 0;; ++index) {
    ComPtr<IMFMediaType> candidate;
    const HRESULT hr = transform_->GetOutputAvailableType(0, index, &candidate);
    if (hr == MF_E_NO_MORE_TYPES) {
      StreamLog("Decoder offers no NV12 output type");
      return false;
    }
    if (!CheckHr(hr, "GetOutputAvailableType")) return false;

    GUID subtype = GUID_NULL;
    if (FAILED(candidate->GetGUID(MF_MT_SUBTYPE, &subtype)) ||
        subtype != MFVideoFormat_NV12) {
      continue;
    }
    if (!CheckHr(transform_->SetOutputType(0, candidate.Get(), 0), "SetOutputType")) {
      return false;
    }

    UINT32 width = 0;
    UINT32 height = 0;
    MFGetAttributeSize(candidate.Get(), MF_MT_FRAME_SIZE, &width, &height);
    coded_width_ = width;
    coded_height_ = height;

    // The coded height is often aligned (1088 for 1080p); the aperture tells
    // the visible area.
    MFVideoArea aperture = {};
    if (SUCCEEDED(candidate->GetBlob(MF_MT_MINIMUM_DISPLAY_APERTURE,
                                     reinterpret_cast<UINT8*>(&aperture),
                                     sizeof(aperture), nullptr))) {
      display_width_ = static_cast<uint32_t>(aperture.Area.cx);
      display_height_ = static_cast<uint32_t>(aperture.Area.cy);
    } else {
      display_width_ = coded_width_;
      display_height_ = coded_height_;
    }
    StreamLog("Decoder output NV12 " + std::to_string(display_width_) + "x" +
              std::to_string(display_height_) + " (coded " +
              std::to_string(coded_width_) + "x" + std::to_string(coded_height_) + ")");
    return CheckHr(transform_->GetOutputStreamInfo(0, &output_info_),
                 "GetOutputStreamInfo");
  }
}

bool MfH264Decoder::Decode(const uint8_t* data, size_t size, int64_t pts_us,
                           const FrameCallback& on_frame) {
  if (!transform_) return false;

  ComPtr<IMFMediaBuffer> buffer;
  ComPtr<IMFSample> sample;
  BYTE* destination = nullptr;
  const DWORD length = static_cast<DWORD>(size);
  if (!CheckHr(MFCreateMemoryBuffer(length, &buffer), "MFCreateMemoryBuffer") ||
      !CheckHr(buffer->Lock(&destination, nullptr, nullptr), "Lock input")) {
    return false;
  }
  std::memcpy(destination, data, size);
  buffer->Unlock();
  buffer->SetCurrentLength(length);

  if (!CheckHr(MFCreateSample(&sample), "MFCreateSample") ||
      !CheckHr(sample->AddBuffer(buffer.Get()), "AddBuffer")) {
    return false;
  }
  sample->SetSampleTime(pts_us * kHundredNsPerMicrosecond);

  HRESULT hr = transform_->ProcessInput(0, sample.Get(), 0);
  if (hr == MF_E_NOTACCEPTING) {
    // Output is pending: drain it, then the input is accepted.
    if (!DrainOutput(on_frame)) return false;
    hr = transform_->ProcessInput(0, sample.Get(), 0);
  }
  return CheckHr(hr, "ProcessInput") && DrainOutput(on_frame);
}

bool MfH264Decoder::DrainOutput(const FrameCallback& on_frame) {
  const bool decoder_allocates =
      (output_info_.dwFlags & (MFT_OUTPUT_STREAM_PROVIDES_SAMPLES |
                               MFT_OUTPUT_STREAM_CAN_PROVIDE_SAMPLES)) != 0;
  for (;;) {
    ComPtr<IMFSample> own_sample;
    if (!decoder_allocates && FAILED(CreateOutputSample(&own_sample))) {
      return false;
    }
    MFT_OUTPUT_DATA_BUFFER output = {};
    output.pSample = own_sample.Get();
    DWORD status = 0;
    const HRESULT hr = transform_->ProcessOutput(0, 1, &output, &status);
    if (output.pEvents != nullptr) output.pEvents->Release();

    if (hr == MF_E_TRANSFORM_NEED_MORE_INPUT) return true;
    if (hr == MF_E_TRANSFORM_STREAM_CHANGE) {
      // New SPS (resolution or rotation): pick the new output type and retry.
      if (!ConfigureOutputType()) return false;
      continue;
    }
    if (!CheckHr(hr, "ProcessOutput")) return false;

    const bool emitted = EmitSample(output.pSample, on_frame);
    if (decoder_allocates && output.pSample != nullptr) output.pSample->Release();
    if (!emitted) return false;
  }
}

HRESULT MfH264Decoder::CreateOutputSample(IMFSample** sample) const {
  ComPtr<IMFSample> created;
  ComPtr<IMFMediaBuffer> buffer;
  HRESULT hr = MFCreateSample(&created);
  if (SUCCEEDED(hr)) hr = MFCreateMemoryBuffer(output_info_.cbSize, &buffer);
  if (SUCCEEDED(hr)) hr = created->AddBuffer(buffer.Get());
  if (SUCCEEDED(hr)) *sample = created.Detach();
  return hr;
}

bool MfH264Decoder::EmitSample(IMFSample* sample, const FrameCallback& on_frame) {
  ComPtr<IMFMediaBuffer> buffer;
  if (sample == nullptr ||
      !CheckHr(sample->ConvertToContiguousBuffer(&buffer), "ConvertToContiguousBuffer")) {
    return false;
  }

  // Prefer the real pitch from IMF2DBuffer; fall back to a tightly packed
  // contiguous buffer.
  ComPtr<IMF2DBuffer> buffer_2d;
  BYTE* scanline0 = nullptr;
  LONG pitch = 0;
  BYTE* contiguous = nullptr;
  const bool locked_2d = SUCCEEDED(buffer.As(&buffer_2d)) &&
                         SUCCEEDED(buffer_2d->Lock2D(&scanline0, &pitch));
  if (!locked_2d) {
    if (!CheckHr(buffer->Lock(&contiguous, nullptr, nullptr), "Lock output")) {
      return false;
    }
    scanline0 = contiguous;
    pitch = static_cast<LONG>(coded_width_);
  }
  if (pitch <= 0) {
    // Bottom-up NV12 does not occur for decoder output; refuse rather than
    // read out of bounds.
    StreamLog("Unexpected NV12 pitch " + std::to_string(pitch));
  } else {
    const size_t stride = static_cast<size_t>(pitch);
    scrcpy_core::Nv12Image image;
    image.y_plane = scanline0;
    image.y_stride = stride;
    image.uv_plane = scanline0 + stride * coded_height_;
    image.uv_stride = stride;
    image.width = display_width_;
    image.height = display_height_;
    on_frame(image);

    ++frame_count_;
    if (frame_count_ <= kVerboseLogCount || frame_count_ % kPeriodicLogInterval == 0) {
      StreamLog("Decoded frame #" + std::to_string(frame_count_));
    }
  }

  if (locked_2d) {
    buffer_2d->Unlock2D();
  } else {
    buffer->Unlock();
  }
  return true;
}

void MfH264Decoder::Shutdown() {
  if (transform_) {
    transform_->ProcessMessage(MFT_MESSAGE_NOTIFY_END_OF_STREAM, 0);
    transform_->ProcessMessage(MFT_MESSAGE_COMMAND_FLUSH, 0);
    transform_.Reset();
  }
  output_info_ = {};
  coded_width_ = coded_height_ = display_width_ = display_height_ = 0;
  frame_count_ = 0;
}

}  // namespace scrcpy_stream
