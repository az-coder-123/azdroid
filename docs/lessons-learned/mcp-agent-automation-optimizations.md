# MCP Agent Automation Optimizations: Multi-Touch, ROI Crop & Host Polling

> Engineering case study on overcoming traditional ADB single-point bottlenecks, vision token exhaustion, and resolution fragmentation in AI Agent mobile automation.

---

## 1. Context & Symptoms

When AI Agents interact with real Android devices through standard Model Context Protocol (MCP) toolchains, three severe friction points emerge:

1. **Resolution Fragility with Pixel Coordinates:** Jetpack Compose, Flutter Canvas, and SurfaceView surfaces lack inspectable accessibility nodes. Forcing AI Agents to fallback to raw pixel coordinates (`x=540, y=1170`) failed catastrophically when executing identical test scripts across heterogeneous screens (1080x2400 FHD vs. 1440x3120 QHD vs. Foldables/Tablets).
2. **Vision Token & Bandwidth Waste (Full-Screen Screenshots):** Inspecting a specific UI badge, subtitle, or toggle required capturing and transferring 1080x2400 uncompressed PNGs (~2.5 MB). This consumed excessive LLM Vision context tokens and introduced noticeable processing latency (~1.8s per step).
3. **Multi-Touch Impossibility on Headless ADB:** Standard `adb shell input` only supports single-finger taps and swipes. Testing pinch-to-zoom (media players, maps, galleries) was unsupported without cumbersome third-party binaries or root access.
4. **Transient State Misses & Argument Friction:** Polling for asynchronous states (e.g., activity resumption, element disappearance) generated excessive round-trip token waste, while inconsistent argument naming (`scale` vs `scaleFactor`, `localPath` vs `local_path`) caused agent argument exceptions.

---

## 2. Diagnostic Traces & Evidence

### A. Resolution Fragmentation
An agent clicking a top-right action button at `x=980, y=120` on a 1080-wide screen missed completely on a 1440-wide device, landing in empty space:
```text
[AdbInputOps] Executing: input tap 980 120
[Result] Tap executed, but action unhandled (Expected bounds [1320, 90, 1420, 190]).
```

### B. Screenshot Payload Latency
```text
[McpScreen] Screencap raw size: 2,842,109 bytes (PNG 1440x3120).
[LLM Tokenizer] Image token footprint: 1,600 vision tokens.
[McpActivity] android_take_screenshot duration: 1840ms.
```

### C. Single-Touch ADB Limitation
```text
$ adb shell input pinch
Error: Unknown command: pinch
Supported commands: tap, swipe, keyevent, text, draganddrop
```

---

## 3. Root Cause Analysis

1. **Device Resolution Variance:** Physical display dimensions differ across Android form factors. Without cached display resolution querying (`wm size`) and ratio-to-pixel interpolation, relative positions cannot be mapped deterministically.
2. **Uncropped Vision Ingestion:** Standard screencap captures the full frame buffer. AI Agents examining localized widgets do not need the entire viewport; uncropped images exhaust context limits and incur unnecessary encoding/decoding overhead.
3. **Android Input Daemon (adbd) Surface Limitations:** `input` command is a Java wrapper (`/system/bin/app_process`) targeting `InputManager.injectInputEvent`. It is hardcoded to single-pointer motion events unless driven via low-level multi-touch Linux input event streams (`/dev/input/event*`) or Scrcpy control sockets.
4. **Client/Server IPC Roundtrips for Wait Loops:** Having the agent loop with `android_take_screenshot` or `android_dump_hierarchy` until a condition is met consumes huge token budgets and network latency.

---

## 4. Architectural Solution

We implemented five decoupled, high-impact enhancements across Azdroid MCP:

### A. Normalized Percentage Coordinates & Resolution Caching
All coordinate-based tools (`android_tap`, `android_double_tap`, `android_swipe`, `android_drag`, `android_batch_actions`) accept normalized ratios (`0.0..1.0`):
- `McpAdbInputOps.getDisplaySize()` queries `wm size` and caches per device serial.
- Automatic interpolation: `pixelX = (xRatio * screenWidth).round()`.
- Screen dimension cache is invalidated on rotation or resolution changes.

### B. Native Multi-Touch Pinch & Scrcpy Stream Injection
`android_pinch_gesture` supports `scale` (or `scaleFactor`), `centerX`, `centerY`, and `durationMs`:
- **When Scrcpy is Active:** Stream injects true multi-touch events using `ControlDatasource.injectTouchStream()` with 2 simultaneous pointers (`p1` and `p2`), linearly interpolating touch separation over `steps = 8`.
- **Pure ADB Fallback:** Automatically falls back to Android's universal 1-finger double-tap-and-drag zoom gesture (double tap + vertical swipe from center point), recognized natively by Google Maps, Chrome, and video players.

### C. Region-of-Interest (ROI) Cropping & Compression
`McpImageProcessor` performs pure Dart headless cropping and JPEG compression:
- Supports bounding boxes via pixels (`crop: {x, y, width, height}`) or ratios (`cropRatio` or ratio values inside `crop`).
- Format conversion (`jpeg` at quality `1..100`) reduces screenshot payload by ~85% (from 2.8MB down to <120KB) and sets `mimeType: image/jpeg`.
- Extracted into dedicated `McpScreenToolExecutor` to comply with Single Responsibility Principle (< 250 lines).

### D. Smart Host Condition Polling (`android_wait_for_condition`)
Executes fast host-side polling (`intervalMs: 500`, `timeoutMs: 10000`) for:
- `element_present`: Appears in accessibility tree.
- `element_gone`: Disappears after dismiss or deletion.
- `activity_resumed`: Focused activity matches regex pattern.
- `logcat_match`: Target string or regex detected in logcat output.

### E. Universal Argument Normalization
`McpArgumentHelper` normalizes keys across snake_case, camelCase, kebab-case, and case-insensitive aliases, eliminating invalid argument exceptions.

---

## 5. Prevention & Reusability Checklist

- [x] **Support Dual Coordinate Modes:** Always allow both normalized ratios (`0.0..1.0`) and physical pixels (`x`, `y`) across all touch automation tools.
- [x] **Cache Resolution Responsibly:** Cache `wm size` queries per device serial, and provide an explicit invalidator on display configuration changes.
- [x] **Default to Vision Economy:** Provide ROI cropping and JPEG compression options to minimize agent token spend and latency.
- [x] **Scrcpy Over ADB for Input:** Use Scrcpy control sockets for multi-pointer gestures where available, with graceful fallback to standard Android input chains.
- [x] **Host-Side Polling for Async Conditions:** Never force an AI agent to execute multiple round-trip tool calls to poll for state changes; delegate polling to the host server.
- [x] **Strict SRP Compliance:** Keep all MCP executor and processor files under 250 lines by modularizing screen, touch, device control, and automation handlers.
