# Lessons Learned: Decoupling AppLogger from Flutter Foundation for Standalone Dart MCP CLI Execution

> **Subsystem:** MCP Server, Core Logging & Dart VM CLI Execution  
> **Impact:** Enables headless `dart run bin/azdroid_mcp.dart` execution without requiring Flutter UI engine or breaking JSON-RPC stdio framing.  
> **Relevant Files:** `lib/core/services/app_logger.dart`, `bin/azdroid_mcp.dart`, `scripts/start_mcp_server.sh`

---

## 1. Context & Symptoms

Azdroid's Model Context Protocol (MCP) server is designed to execute as a standalone, headless CLI tool (`bin/azdroid_mcp.dart`) over Standard I/O (`stdio`) via `scripts/start_mcp_server.sh`. Frontier AI clients (Claude Desktop, Cursor, Antigravity, Windsurf) launch this script directly without launching `Azdroid.app`.

When invoking `dart run bin/azdroid_mcp.dart` in a terminal or headless agent environment, compilation failed immediately with cascading errors:

```text
../../DevTools/flutter/packages/flutter/lib/src/foundation/change_notifier.dart:81:23: Error: 'VoidCallback' isn't a type.
  void removeListener(VoidCallback listener);
                      ^^^^^^^^^^^^
../../DevTools/flutter/packages/flutter/lib/src/foundation/debug.dart:129:4: Error: 'Brightness' isn't a type.
ui.Brightness? debugBrightnessOverride;
   ^^^^^^^^^^
../../DevTools/flutter/packages/flutter/lib/src/foundation/diagnostics.dart:2133:16: Error: The method 'clampDouble' isn't defined for the type 'PercentProperty'.
```

The process exited with code `254`, preventing Claude Desktop and agent IDEs from spawning the MCP server.

---

## 2. Diagnostic Traces & Evidence

Running a dependency graph trace from `bin/azdroid_mcp.dart` revealed the transitive import path:

```text
bin/azdroid_mcp.dart
  └── lib/features/mcp/data/handlers/mcp_protocol_handler.dart
      └── lib/features/mcp/data/handlers/mcp_tool_executor.dart
          └── lib/features/mcp/data/handlers/mcp_app_device_tool_executor.dart
              └── lib/features/mcp/data/services/mcp_adb_client.dart
                  └── lib/features/control/data/datasources/control_datasource.dart
                      └── lib/core/services/adb_service.dart
                          └── lib/core/services/adb_path_resolver.dart
                              └── lib/core/services/app_logger.dart
                                  └── package:flutter/foundation.dart
```

Only one single file (`lib/core/services/app_logger.dart`) imported `package:flutter/foundation.dart`.

---

## 3. Root Cause Analysis

1. **Flutter Foundation Package in Pure Dart CLI:**
   - Standalone `dart run` uses the Dart VM compiler without the Flutter embedder or `dart:ui` native libraries.
   - `package:flutter/foundation.dart` transitively references `dart:ui` types (`Brightness`, `VoidCallback`, `ui.Image`, `clampDouble`). When loaded in pure Dart VM, analysis fails because `dart:ui` is unavailable.

2. **Stdio Protocol Corruption Risk (`debugPrint`):**
   - `debugPrint` in `flutter/foundation.dart` writes directly to `stdout` by default.
   - The MCP protocol specification requires that `stdout` is strictly reserved for valid JSON-RPC 2.0 messages (`{"jsonrpc":"2.0",...}`). Any informational or debug log printed to `stdout` causes JSON parsing syntax errors in the AI client.

---

## 4. Architectural Solution

We completely decoupled `AppLogger` from `package:flutter/foundation.dart`:

1. **Replaced `kDebugMode` with Pure Dart Constant:**
   ```dart
   static const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');
   ```

2. **Redirected Console Logs to `stderr`:**
   ```dart
   static void _writeStderr(String line) {
     try {
       stderr.writeln(line);
     } catch (_) {
       // Graceful fallback if stderr is closed.
     }
   }
   ```

3. **Guaranteed Zero UI Overhead & Safe MCP Framing:**
   - Diagnostic messages (`INFO`, `WARN`, `ERROR`, `DEBUG`) now write exclusively to `stderr` and the local diagnostic file (`SystemHostPaths().diagnosticLogFile`).
   - `stdout` remains 100% pristine for MCP JSON-RPC 2.0 frames.
   - `bin/azdroid_mcp.dart` compiles and executes in ~150ms on standalone Dart VM without requiring the Flutter SDK or GUI runtime.

---

## 5. Prevention & Reusability Checklist

- [ ] **Pure Dart Isolation for CLI/Core Services:** Never import `package:flutter/*` inside `lib/core/` services that may be consumed by headless entrypoints (`bin/*.dart`) or daemons.
- [ ] **Reserved Stdout for Protocols:** When building CLI servers (MCP, LSP, DAP) communicating over stdio, all logging and diagnostic output must be routed to `stderr` or rotating log files, never `stdout`.
- [ ] **Environment Check via Dart VM:** Use `!bool.fromEnvironment('dart.vm.product')` instead of importing `package:flutter/foundation.dart`'s `kDebugMode` in non-UI modules.
