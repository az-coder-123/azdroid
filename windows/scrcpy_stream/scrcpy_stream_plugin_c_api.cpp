#include "include/scrcpy_stream/scrcpy_stream_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "scrcpy_stream_plugin.h"

void ScrcpyStreamPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  scrcpy_stream::ScrcpyStreamPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
