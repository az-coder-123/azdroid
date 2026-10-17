# 🤖 DeskDroid MCP Server — Tool Enhancement Proposals

> Architectural evaluation and concrete tool proposals derived from real-world AI agent testing of mobile applications (OpenPlayer3 case study).

---

## 📌 1. Executive Summary & Context

During end-to-end testing and automation of the **OpenPlayer3** Android media player using **DeskDroid MCP Server**, several friction points were identified. While existing tools (`android_get_semantic_tree`, `android_click_element_by_id`, `android_take_screenshot`, `android_shell_command`) provide a strong foundation, protocol-level latency and mobile platform quirks introduce unnecessary overhead.

These proposals address three core challenges:
1. **IME & Autocorrect interference** with text input (`test` becoming `tét` under Vietnamese keyboards).
2. **Network/IPC latency exceeding Android gesture windows** (e.g. `< 300ms` double-tap seeking threshold).
3. **Multi-turn token consumption** when querying and clicking elements from large accessibility trees.

---

## 🛠️ 2. Proposed New MCP Tools

### Category A: Text Input & IME Governance

#### 1. `android_set_text`
- **Problem:** `android_type_text` sends sequential keyevents or text injection. When an IME with predictive text or non-English input (e.g. Vietnamese Gboard/Telex) is active, words are altered (`test` → `tét`) or corrupted by auto-suggestions.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_set_text",
    "parameters": {
      "text": { "type": "string", "description": "Exact text to set" },
      "elementId": { "type": "integer", "description": "Optional target element ID from semantic tree" },
      "deviceSerial": { "type": "string", "description": "Target device serial" }
    }
  }
  \`\`\`
- **Implementation Mechanism:** Use `AccessibilityNodeInfo.ACTION_SET_TEXT` directly, or set clipboard text and dispatch paste (`KEYCODE_PASTE` / `KeyEvent.KEYCODE_PASTE`), bypassing IME predictive engines entirely.

#### 2. `android_clear_text`
- **Problem:** Clearing existing text currently requires locating an on-screen 'Clear' button (`[#X]`) or sending dozens of `KEYCODE_DEL` events in a loop.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_clear_text",
    "parameters": {
      "elementId": { "type": "integer", "description": "Target input field ID" },
      "deviceSerial": { "type": "string", "description": "Target device serial" }
    }
  }
  \`\`\`
- **Implementation Mechanism:** Dispatch `ACTION_SET_TEXT` with an empty string `""` or select all + delete.

---

### Category B: Real-Time & Precision Gestures

#### 3. `android_double_tap`
- **Problem:** Android's native double-tap detection window is typically $\le 300\text{ms}$. Due to MCP round-trip latency (~500ms - 1000ms per tool invocation), an AI agent cannot execute two consecutive `android_tap` calls quickly enough to register as a double-tap (critical for +10s / -10s video seeking).
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_double_tap",
    "parameters": {
      "x": { "type": "number", "description": "X coordinate in pixels" },
      "y": { "type": "number", "description": "Y coordinate in pixels" },
      "intervalMs": { "type": "integer", "default": 120, "description": "Delay between taps (ms)" },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`
- **Implementation Mechanism:** Issue chained `input tap X Y && sleep 0.1 && input tap X Y` or scrcpy touch down/up sequence directly on host/daemon side in one shot.

#### 4. `android_long_press`
- **Problem:** Long-pressing is required to trigger context menus, multi-select modes, and secondary actions.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_long_press",
    "parameters": {
      "x": { "type": "number", "description": "X coordinate in pixels" },
      "y": { "type": "number", "description": "Y coordinate in pixels" },
      "durationMs": { "type": "integer", "default": 800, "description": "Press duration in ms" },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`
- **Implementation Mechanism:** Execute `input swipe X Y X Y <durationMs>` or inject down/wait/up events via scrcpy control socket.

#### 5. `android_drag` (Smooth Scrubbing)
- **Problem:** Timeline seekbars and brightness/volume sliders require continuous, controlled dragging rather than fast ballistic swipes.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_drag",
    "parameters": {
      "startX": { "type": "number" }, "startY": { "type": "number" },
      "endX": { "type": "number" }, "endY": { "type": "number" },
      "durationMs": { "type": "integer", "default": 1000 },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`

---

### Category C: Smart Element Querying & State Synchronization

#### 6. `android_click_by_text` & `android_click_by_desc`
- **Problem:** Currently, clicking a known button requires a 3-turn workflow:
  1. Fetch `android_get_semantic_tree` (dumps large output to disk).
  2. Parse/grep the output file for the element ID.
  3. Invoke `android_click_element_by_id`.
- **Proposed Signatures:**
  \`\`\`json
  {
    "name": "android_click_by_text",
    "parameters": {
      "text": { "type": "string", "description": "Exact or partial text to match" },
      "exactMatch": { "type": "boolean", "default": false },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`
  \`\`\`json
  {
    "name": "android_click_by_desc",
    "parameters": {
      "contentDesc": { "type": "string", "description": "Accessibility content description" },
      "exactMatch": { "type": "boolean", "default": false },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`
- **Benefit:** Reduces tool execution turns by 66%, cutting LLM token usage and latency.

#### 7. `android_wait_for_element`
- **Problem:** Asynchronous UI transitions (e.g., confirmation dialog opening, database deletion, loading spinner) cause race conditions where AI takes screenshots before the UI finishes rendering.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_wait_for_element",
    "parameters": {
      "query": { "type": "string", "description": "Text, content description, or ID" },
      "timeoutMs": { "type": "integer", "default": 5000 },
      "condition": { "type": "string", "enum": ["appear", "disappear"], "default": "appear" },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`

---

### Category D: Diagnostics & File Governance

#### 8. `android_scan_media_file`
- **Problem:** When testing media apps, newly pushed or modified audio/video files are invisible to `MediaStore` until indexed. Running `am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE` via raw shell command is verbose and error-prone.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_scan_media_file",
    "parameters": {
      "filePath": { "type": "string", "description": "Device path e.g. /sdcard/Movies/sample.mp4" },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`

#### 9. `android_check_crash`
- **Problem:** Diagnosing app crashes requires manual logcat querying and regex filtering.
- **Proposed Signature:**
  \`\`\`json
  {
    "name": "android_check_crash",
    "parameters": {
      "package": { "type": "string", "description": "Target package name" },
      "lines": { "type": "integer", "default": 50 },
      "deviceSerial": { "type": "string" }
    }
  }
  \`\`\`
- **Benefit:** Returns a clean stack trace if a `FATAL EXCEPTION` or ANR occurred, allowing immediate debugging.

---

## 📈 3. Impact Assessment Matrix

| Tool | Impact Area | Primary Benefit | Implementation Complexity | Status |
| :--- | :--- | :--- | :---: | :---: |
| **`android_set_text`** | Accuracy | Eliminates 100% of IME / Telex autocorrect corruption | Low | ✅ **Implemented (v1.0.1)** |
| **`android_clear_text`** | Ergonomics | 1-step input reset without UI navigation | Low | ✅ **Implemented (v1.0.1)** |
| **`android_double_tap`** | Capability | Enables media player scrubbing & zoom tests | Low | ✅ **Implemented (v1.0.1)** |
| **`android_long_press`** | Capability | Long-press gesture with duration | Low | ✅ **Available (`McpAutomationTools`)** |
| **`android_wait_for_element`** | Reliability | Eliminates test race conditions during animations | Medium | ✅ **Available (Phase 3 for `disappear`)** |
| **`android_click_by_desc` / `text`** | Efficiency | Saves 2 tool turns & ~1,500 prompt tokens per click | Medium | ⏳ **Phase 3 (`exactMatch` param)** |
| **`android_drag`** | Precision | Smooth timeline scrubbing & slider controls | Medium | ⏳ **Phase 2 (Planned)** |
| **`android_scan_media_file`** | Workflow | Instant MediaStore indexing for media app testing | Low | ⏳ **Phase 2 (Planned)** |
| **`android_check_crash`** | Diagnostics | Instant stack trace retrieval upon failure | Low | ⏳ **Phase 2 (Planned)** |
