# Lessons Learned: MCP Defensive Argument Parsing, Transient UI Latency, & SurfaceView Automation

## 1. Context & Symptoms

During automated end-to-end device testing driven by AI agents via the Azdroid MCP server, agents encountered tool failures and timed-out interactions across three distinct scenarios:

1. **Unsafe Type Downcasts in MCP Handlers:**
   Invoking `android_push_file` or `android_wake_screen` failed with unhandled Dart runtime exceptions:
   ```text
   Tool execution exception: type 'Null' is not a subtype of type 'String' in type cast
   Tool execution exception: type 'Null' is not a subtype of type 'bool' in type cast
   ```
2. **Transient UI Expiration (3.5s Timeout):**
   Video players (VLC for Android, ExoPlayer, YouTube) display overlay controls (play/pause, resolution, audio track) for only ~3.5 seconds before auto-hiding. When an agent dispatched sequential actions (tap screen center -> wait -> tap settings gear), host-to-device roundtrip latency caused the overlay to vanish before the second tap arrived.
3. **Empty Accessibility Bounds on Native Video Canvases:**
   Invoking `android_dump_hierarchy` or `android_get_semantic_tree` while a video was playing returned `android.view.SurfaceView` with zero nested children or bounds `[0,0][0,0]`, leaving the agent unable to resolve UI element IDs inside the player surface.

---

## 2. Diagnostic Traces & Evidence

### Type Cast Stack Trace
```text
[Azdroid MCP] Tool error on android_push_file:
TypeError: type 'Null' is not a subtype of type 'String' in type cast
  at McpAppDeviceToolExecutor.execute (mcp_app_device_tool_executor.dart:45)
  at McpToolExecutor.execute (mcp_tool_executor.dart:55)
```
The agent omitted the exact parameter key `localPath` and instead passed `filePath` or `path`, which evaluated to `null` and threw on `arguments['localPath'] as String`. Similarly, `arguments['wake'] as bool` threw when `wake` was omitted because the agent intended to rely on the default behavior.

### Process Spawning Overhead Analysis
Tracing each sequential ADB call from the macOS host:
```text
Process.run('adb', ['-s', serial, 'shell', 'input', 'tap', ...]) -> ~180ms
Future.delayed(Duration(milliseconds: 300))                         -> ~300ms
Process.run('adb', ['-s', serial, 'shell', 'input', 'tap', ...]) -> ~190ms
Process.run('adb', ['-s', serial, 'shell', 'input', 'tap', ...]) -> ~210ms
Total elapsed: ~880ms + Agent LLM inference (1500-2500ms) = ~3380ms > 3500ms
```
The overlay control dismissed itself just milliseconds prior to the target click injection.

---

## 3. Root Cause Analysis

1. **Brittle Argument Casting:** MCP handlers performed direct Dart downcasting (`as String`, `as bool`, `as num`, `as int`) without alias resolution or null checks. Natural variances in LLM schema outputs (such as passing `'true'` as a string, `1` as an int, or using synonyms like `pkg` instead of `package`) triggered unrecoverable `TypeError` crashes.
2. **Host-Side IPC Overhead in Batch Actions:** Executing sequential actions by repeatedly spawning `adb` child processes on the host incurs process creation, daemon socket negotiation, and OS scheduling overhead for every individual action.
3. **Native SurfaceView Hardware DRM Bypasses Accessibility:** `SurfaceView` and Jetpack Compose hardware canvases render video frames directly via SurfaceFlinger into dedicated hardware layers. They do not publish UI child nodes to the Android Accessibility Framework (`AccessibilityNodeInfo`).

---

## 4. Architectural Solution

### A. Defensive Argument Extraction (`McpArgumentHelper`)
Created `lib/features/mcp/data/utils/mcp_argument_helper.dart` providing `McpArgumentMapExtension`:
- **Alias Resolution:** Automatically checks primary keys and fallback synonyms (e.g., `['pkg', 'packageName', 'app']`).
- **Flexible Type Coercion:** Coerces strings (`'1'`, `'true'`, `'yes'`, `'on'`) and integers into booleans without throwing.
- **Graceful Defaults:** `getInt` and `getDouble` return non-nullable primitives with defaults; `getOptionalInt` and `getOptionalDouble` handle optional fields safely.
- **Friendly Exceptions:** Missing required parameters throw `McpArgumentException` with actionable descriptions instead of runtime crashes.

### B. Compound Shell Pipeline in Batch Execution
Refactored `McpAdbAutomationOps.batchActions` to compile homogeneous input/sleep sequences into a single atomic ADB shell command:
```sh
input tap 540 1170 && echo "DD_STEP:0:OK" || echo "DD_STEP:0:FAIL"; \
sleep 0.2 && echo "DD_STEP:1:OK" || echo "DD_STEP:1:FAIL"; \
input tap 980 120 && echo "DD_STEP:2:OK" || echo "DD_STEP:2:FAIL"
```
The entire chain executes locally inside the Android device shell in ~220ms total with zero network hops between steps.

### C. SurfaceView Coordinate Guidance
For video canvases lacking accessibility nodes, the agent must leverage relative coordinate calculation based on display dimensions retrieved via `android_get_device_info` rather than relying solely on element IDs.

---

## 5. Prevention & Reusability Checklist

- [x] **Zero Raw Downcasts:** Never write `arguments['key'] as Type` in MCP handlers. Always use `arguments.getString`, `arguments.getBool`, `arguments.getInt`, or `arguments.getDouble`.
- [x] **Support Standard Aliases:** Accept common synonyms for identifiers (e.g., `deviceSerial`/`serial`, `package`/`pkg`, `localPath`/`path`/`filePath`).
- [x] **Compound Shell Pipelines for Fast UI:** When executing multiple touch or gesture actions against transient UI, compile them into a single compound shell string to avoid host IPC latency.
- [x] **Defensive Error Boundaries:** Wrap tool handler executions to catch `McpArgumentException` and return helpful error messages back to the agent.
- [x] **File Compactness (< 250 lines):** Maintain strict SRP across all executor and helper files.
