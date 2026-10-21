# Azdroid Windows video plugin: scrcpy H.264 stream -> Flutter texture.
# Contract: docs/native-video-contract.md. Built as a DLL like Flutter plugins.
cmake_minimum_required(VERSION 3.14)
project(scrcpy_stream LANGUAGES CXX)

set(PLUGIN_NAME "scrcpy_stream_plugin")

# Platform-neutral protocol and frame code, shared and tested on every OS.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../native/scrcpy_core"
                 "${CMAKE_CURRENT_BINARY_DIR}/scrcpy_core")

add_library(${PLUGIN_NAME} SHARED
  "include/scrcpy_stream/scrcpy_stream_plugin_c_api.h"
  "audio_channel.cpp"
  "audio_session.cpp"
  "channel_args.cpp"
  "frame_texture.cpp"
  "mf_h264_decoder.cpp"
  "mf_util.cpp"
  "scrcpy_stream_plugin.cpp"
  "scrcpy_stream_plugin_c_api.cpp"
  "stream_log.cpp"
  "stream_session.cpp"
  "wasapi_audio_output.cpp"
  "winsock_connection.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  WIN32_LEAN_AND_MEAN  # Keep windows.h from pulling in the old winsock.h.
  NOMINMAX
  # Same override as Flutter's own plugins (std::any link issue in MSVC).
  "_HAS_EXCEPTIONS=1"
)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  scrcpy_core
  mfplat mfuuid wmcodecdspuuid  # Media Foundation + H.264 decoder CLSID
  ole32 oleaut32                # COM, VARIANT (also WASAPI audio)
  ws2_32                        # Winsock
  delayimp                      # Delay-load helper for mfplat.dll below
)
# Windows N/KN editions ship without Media Foundation. Delay-loading
# mfplat.dll lets the app start there; StartStream checks for it first
# (IsMediaFoundationInstalled) and reports DECODER_UNAVAILABLE instead.
target_link_options(${PLUGIN_NAME} PRIVATE "/DELAYLOAD:mfplat.dll")
