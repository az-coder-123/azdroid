# Bypassing IME Predictive Text Alteration & Sub-300ms Gesture Latency

> **Subsystem:** MCP Server (`lib/features/mcp/data/services/mcp_adb_input_ops.dart`, `mcp_basic_tool_executor.dart`)  
> **Affected Platform:** Android 10+ / Custom IME Keyboards (Gboard, Telex, Samsung Keyboard) / Remote AI Agents  
> **Severity:** High (Text Input Data Corruption & Gesture Timeout Failures)  
> **Resolution Date:** October 2026  

---

## 1. 🔍 Context & Symptoms

During automated end-to-end testing of mobile apps (such as the OpenPlayer3 audio player) using AI agents over MCP:
1. **IME & Autocorrect Text Corruption:** When using character-by-character key injections (`android_type_text`), devices with active predictive keyboards (e.g., Vietnamese Telex on Gboard or LabanKey) altered sequential keystrokes. For example, typing `"test"` produced `"tét"`, and typing `"open"` became `"ô-p-e-n"`, while auto-suggestions unpredictably injected unwanted words.
2. **Double-Tap Seeking Timeout:** Android media players and photo viewers require a double-tap gesture within $\le 300\text{ms}$ (commonly $120\text{ms} - 180\text{ms}$) to trigger $\pm 10\text{s}$ video seeking or photo zoom. Because MCP round-trip invocations over stdio JSON-RPC incur $400\text{ms} - 800\text{ms}$ of IPC latency, an AI agent issuing two consecutive `android_tap` tool calls failed 100% of the time.
3. **Multi-Turn Input Reset Overhead:** Clearing existing text in a search bar required searching the screen for a clear icon or dispatching dozens of `KEYCODE_DEL` events sequentially.

---

## 2. 🔬 Diagnostic Traces & Evidence

1. **Character-by-Character IME Processing:**
   ```bash
   adb shell input text "test"
   # With Vietnamese Telex active:
   # 't' -> 'e' -> 's' -> triggers acute accent on 'e' -> produces "tét"
   ```
2. **Round-Trip Delay Exceeding Gesture Windows:**
   - Tap 1 issued: $T_0$
   - Client round-trip & LLM turn decision: $T_0 + 620\text{ms}$
   - Tap 2 issued: $T_0 + 650\text{ms}$
   - **Result:** Android registered two unrelated single taps instead of a double-tap.

---

## 3. 🧩 Root Cause Analysis

1. **Software Keyboard Hooking:** `input text` injects keyevents into Android's active input method (IME). If the user has a localized keyboard (Vietnamese, Japanese, Chinese, or auto-capitalization) enabled, the software keyboard intercepts sequential keycodes to build compound glyphs or apply spelling corrections.
2. **Network/IPC Window Incompatibility:** Complex gestures (double-tap, triple-tap, precise scrubbing) are real-time physical phenomena with millisecond tolerances. Decoupled agent loops cannot satisfy real-time OS timing constraints across network boundaries.

---

## 4. 🏛️ Architectural Solution

Azdroid introduced dedicated **Phase 1 Friction-Breaker Tools** in `McpAdbInputOps`:

1. **Atomic Clipboard Paste (`android_set_text`):**
   - Injects text into the Android system clipboard via `cmd clipboard set <text>`.
   - Dispatches a single `KEYCODE_PASTE` (Keycode 279) event:
     ```dart
     await client.setClipboard(serial, text);
     await client.run(['-s', serial, 'shell', 'input', 'keyevent', '279']);
     ```
   - **Result:** Text is inserted as a monolithic clipboard block in a single frame. The active IME cannot alter, suggest, or distort characters.
   - Optionally auto-focuses target fields via `elementId` and clears existing content with `clearFirst: true`.

2. **Compound Shell Chaining (`android_double_tap`):**
   - Chains two taps on the device side within a single ADB shell session:
     ```bash
     input tap X Y && sleep 0.12 && input tap X Y
     ```
   - **Result:** The 120ms interval is guaranteed by the device kernel regardless of host MCP latency.

3. **Atomic Clear Sequence (`android_clear_text`):**
   - Dispatches cursor move-to-end, select-all (`Ctrl+A`), and forward-delete in a single shot:
     ```bash
     input keyevent 123 && input keyevent --meta 4096 29 && input keyevent 67
     ```

---

## 5. ✅ Prevention & Reusability Checklist

- [x] **Never type complex strings character-by-character:** Always prefer clipboard paste (`KEYCODE_PASTE`) when setting exact strings or credentials.
- [x] **Bundle time-sensitive gestures on device side:** Never let agent round-trips govern sub-second gesture windows; chain them in one shell command.
- [x] **Support element auto-focusing:** Allow setting text and clearing text by `elementId` so agents don't waste turns tapping before typing.
