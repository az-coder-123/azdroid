# CMake `install(CODE)` Ignores Configurations and Escaped Generator Expressions

> **Subsystem:** Windows build (`windows/CMakeLists.txt`): bundled adb check and `deskdroid-mcp.exe` compile step
> **Affected Platform:** Windows (Flutter desktop, CMake 3.14+, Visual Studio generator)
> **Severity:** High (Debug runs blocked; Release packages could not be built)
> **Resolution Date:** October 2026

---

## 1. Context & Symptoms

Two install-time steps were added for standalone Windows packages: a check that fails Release builds without the bundled adb, and a step that compiles the MCP server into `deskdroid-mcp.exe`. Both were declared with `install(CODE ... CONFIGURATIONS Release)`.

1. `flutter run -d windows` (Debug) failed at the INSTALL step, although the check was meant for Release only:
   ```text
   error MSB3073: ... cmake.exe -DBUILD_TYPE=Debug -P cmake_install.cmake exited with code 1.
   ```
2. After the Debug guard was fixed and adb was fetched, `flutter build windows --release` failed in the MCP step:
   ```text
   The system cannot find the file specified.
   CMake Error at cmake_install.cmake:251 (message):
     Failed to compile the MCP server (deskdroid-mcp.exe).
   ```

MSBuild only reports `MSB3073`; the real message appears when the install script runs on its own.

---

## 2. Diagnostic Traces & Evidence

1. Run the install script directly to see CMake's own error:
   ```powershell
   cd build\windows\x64
   cmake -DBUILD_TYPE=Debug -P cmake_install.cmake
   # Release builds must bundle adb. Run 'dart run tool/fetch_platform_tools.dart --os=windows'.
   ```
2. The generated `cmake_install.cmake` contained the `FATAL_ERROR` with **no configuration condition**, unlike `install(DIRECTORY ... CONFIGURATIONS Release)` blocks, which are wrapped in `if(CMAKE_INSTALL_CONFIG_NAME MATCHES ...)`.
3. The same `dart.bat compile exe` command succeeded from PowerShell, and `dart.bat --version` succeeded inside `cmake -P`. The difference was the output path. The top of `cmake_install.cmake` shows why:
   ```cmake
   set(CMAKE_INSTALL_PREFIX "$<TARGET_FILE_DIR:desk_droid>")
   ```
   The compile step wrote to `${CMAKE_INSTALL_PREFIX}/deskdroid-mcp.exe`, escaped as `\${...}` in `CMakeLists.txt`, so `dart` received the literal path `$<TARGET_FILE_DIR:desk_droid>/deskdroid-mcp.exe`.

---

## 3. Root Cause Analysis

1. **`CONFIGURATIONS` has no effect on `install(CODE)`** (and `install(SCRIPT)`). The option is accepted silently, so the code runs for Debug, Profile, and Release.
2. **Flutter's Windows template sets `CMAKE_INSTALL_PREFIX` to a generator expression** (`$<TARGET_FILE_DIR:...>`). `install(DIRECTORY/FILES/TARGETS)` resolve it when CMake generates the build. `install(CODE)` resolves generator expressions only in the code text written at configure time; an escaped `\${CMAKE_INSTALL_PREFIX}` is expanded later, at install time, to the unresolved string.

---

## 4. Architectural Solution

Both steps in `windows/CMakeLists.txt` now check the configuration inside the code and use a configure-time path:

```cmake
install(CODE "
  if(\"\${CMAKE_INSTALL_CONFIG_NAME}\" STREQUAL \"Release\")
    execute_process(
      COMMAND \"${FLUTTER_ROOT}/bin/dart.bat\" compile exe \"${MCP_SERVER_ENTRYPOINT}\"
              -o \"${INSTALL_BUNDLE_LIB_DIR}/deskdroid-mcp.exe\"
      RESULT_VARIABLE mcp_result)
    ...
  endif()
  " COMPONENT Runtime)
```

- `\${CMAKE_INSTALL_CONFIG_NAME}` stays escaped: it must be read at install time.
- `${INSTALL_BUNDLE_LIB_DIR}` is not escaped: its generator expression is written into the code and resolved per configuration.

`scripts/build_release.ps1` now fetches Platform-Tools before building and smoke-tests the packaged `adb.exe` and `deskdroid-mcp.exe`. The ZIP was then verified in an environment without adb, Flutter, Dart, or `ANDROID_HOME`: the app and the MCP server both logged `Using bundled adb` and listed real devices.

---

## 5. Prevention & Reusability Checklist

- [x] **Never rely on `CONFIGURATIONS` with `install(CODE)` or `install(SCRIPT)`.** Guard with `if("${CMAKE_INSTALL_CONFIG_NAME}" STREQUAL "Release")` inside the code.
- [x] **In Flutter's CMake, treat `CMAKE_INSTALL_PREFIX` as a generator expression.** Use it unescaped (or `INSTALL_BUNDLE_LIB_DIR`) in `install(CODE)`; never `\${CMAKE_INSTALL_PREFIX}`.
- [x] **Debug `MSB3073` with `cmake -DBUILD_TYPE=<Config> -P cmake_install.cmake`** in `build\windows\x64`.
- [x] **Read the generated `cmake_install.cmake`** to confirm every Release-only block has a configuration condition.
- [x] **Verify standalone packages in a clean environment** (no tool on `PATH`, no SDK variables), not only on the build machine.
