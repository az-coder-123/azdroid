// C entry point used by the runner to register the Azdroid video plugin.
#ifndef SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_C_API_H_
#define SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void ScrcpyStreamPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // SCRCPY_STREAM_SCRCPY_STREAM_PLUGIN_C_API_H_
