#include "wasapi_audio_output.h"

#include <audioclient.h>
#include <mmdeviceapi.h>
#include <mmreg.h>
#include <wrl/client.h>

#include <utility>

#include "mf_util.h"
#include "stream_log.h"

namespace scrcpy_stream {

namespace {

using Microsoft::WRL::ComPtr;

// KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, spelled out so no GUID library is needed.
constexpr GUID kSubtypeIeeeFloat = {
    0x00000003, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}};

// Device buffer: 20 ms (REFERENCE_TIME is in 100-nanosecond units). The
// jitter buffer in front of it holds the 50 ms target.
constexpr REFERENCE_TIME kDeviceBufferDuration = 200000;
// Wakes up this often even without a device event, to check for Stop().
constexpr DWORD kRenderWaitMs = 200;
// Pause before reopening after the device was removed or changed.
constexpr DWORD kReopenDelayMs = 500;
constexpr WORD kBitsPerFloatSample = 32;
constexpr WORD kBitsPerByte = 8;

// scrcpy's format as 32-bit float. AUTOCONVERTPCM lets the audio engine
// resample it to the device mix format.
WAVEFORMATEXTENSIBLE PlaybackFormat() {
  WAVEFORMATEXTENSIBLE format{};
  format.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
  format.Format.nChannels = static_cast<WORD>(scrcpy_core::kAudioChannels);
  format.Format.nSamplesPerSec = scrcpy_core::kAudioSampleRate;
  format.Format.wBitsPerSample = kBitsPerFloatSample;
  format.Format.nBlockAlign = static_cast<WORD>(
      format.Format.nChannels * (kBitsPerFloatSample / kBitsPerByte));
  format.Format.nAvgBytesPerSec =
      format.Format.nSamplesPerSec * format.Format.nBlockAlign;
  format.Format.cbSize =
      static_cast<WORD>(sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX));
  format.Samples.wValidBitsPerSample = kBitsPerFloatSample;
  format.dwChannelMask = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
  format.SubFormat = kSubtypeIeeeFloat;
  return format;
}

// COM for the render thread.
class ComScope {
 public:
  ComScope() : ok_(SUCCEEDED(CoInitializeEx(nullptr, COINIT_MULTITHREADED))) {}
  ~ComScope() {
    if (ok_) CoUninitialize();
  }
  ComScope(const ComScope&) = delete;
  ComScope& operator=(const ComScope&) = delete;

 private:
  bool ok_;
};

struct OpenDevice {
  ComPtr<IAudioClient> client;
  ComPtr<IAudioRenderClient> render;
  UINT32 frames = 0;
};

bool Open(HANDLE ready_event, OpenDevice& device) {
  ComPtr<IMMDeviceEnumerator> enumerator;
  ComPtr<IMMDevice> endpoint;
  WAVEFORMATEXTENSIBLE format = PlaybackFormat();
  return CheckHr(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                  CLSCTX_ALL, IID_PPV_ARGS(&enumerator)),
                 "[audio] Create device enumerator") &&
         CheckHr(enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &endpoint),
                 "[audio] Get default output device") &&
         CheckHr(endpoint->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                                    reinterpret_cast<void**>(
                                        device.client.GetAddressOf())),
                 "[audio] Activate audio client") &&
         CheckHr(device.client->Initialize(
                     AUDCLNT_SHAREMODE_SHARED,
                     AUDCLNT_STREAMFLAGS_EVENTCALLBACK |
                         AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM |
                         AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY,
                     kDeviceBufferDuration, 0,
                     reinterpret_cast<const WAVEFORMATEX*>(&format), nullptr),
                 "[audio] Initialize audio client") &&
         CheckHr(device.client->SetEventHandle(ready_event),
                 "[audio] Set event handle") &&
         CheckHr(device.client->GetBufferSize(&device.frames),
                 "[audio] Get buffer size") &&
         CheckHr(device.client->GetService(IID_PPV_ARGS(&device.render)),
                 "[audio] Get render client") &&
         CheckHr(device.client->Start(), "[audio] Start audio client");
}

}  // namespace

WasapiAudioOutput::WasapiAudioOutput(
    std::shared_ptr<scrcpy_core::PcmJitterBuffer> buffer)
    : buffer_(std::move(buffer)) {}

WasapiAudioOutput::~WasapiAudioOutput() { Stop(); }

bool WasapiAudioOutput::Start() {
  Stop();
  stop_event_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (stop_event_ == nullptr) return false;
  running_ = true;
  std::promise<bool> opened;
  std::future<bool> result = opened.get_future();
  thread_ = std::thread(&WasapiAudioOutput::Run, this, std::move(opened));
  const bool ok = result.get();
  if (!ok) Stop();
  return ok;
}

void WasapiAudioOutput::Stop() {
  running_ = false;
  if (stop_event_ != nullptr) SetEvent(stop_event_);
  if (thread_.joinable()) thread_.join();
  if (stop_event_ != nullptr) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }
}

void WasapiAudioOutput::Run(std::promise<bool> opened) {
  ComScope com;
  HANDLE ready_event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
  bool reported = false;
  while (running_) {
    const bool rendered = ready_event != nullptr && RenderOnce(ready_event, opened, reported);
    if (!reported) {
      // The first open failed: tell Start() and give up.
      opened.set_value(false);
      reported = true;
      break;
    }
    if (!rendered && running_) {
      StreamLog("[audio] Output device lost; reopening the default device");
      WaitForSingleObject(stop_event_, kReopenDelayMs);
    }
  }
  if (ready_event != nullptr) CloseHandle(ready_event);
}

bool WasapiAudioOutput::RenderOnce(HANDLE ready_event, std::promise<bool>& opened,
                                   bool& reported) {
  OpenDevice device;
  if (!Open(ready_event, device)) return false;
  if (!reported) {
    opened.set_value(true);
    reported = true;
  }
  const HANDLE events[] = {stop_event_, ready_event};
  while (running_) {
    const DWORD woken = WaitForMultipleObjects(2, events, FALSE, kRenderWaitMs);
    if (woken == WAIT_OBJECT_0) break;  // Stop().
    UINT32 padding = 0;
    if (!CheckHr(device.client->GetCurrentPadding(&padding), "[audio] Get padding")) {
      return false;
    }
    const UINT32 available = device.frames - padding;
    if (available == 0) continue;
    BYTE* data = nullptr;
    if (!CheckHr(device.render->GetBuffer(available, &data), "[audio] Get buffer")) {
      return false;
    }
    buffer_->ReadInterleaved(reinterpret_cast<float*>(data), available);
    if (!CheckHr(device.render->ReleaseBuffer(available, 0),
                 "[audio] Release buffer")) {
      return false;
    }
  }
  device.client->Stop();
  return true;
}

}  // namespace scrcpy_stream
