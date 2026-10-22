# Precision UI Targeting, Visual Grounding & Feedback Verification

> Architectural proposals and root cause analysis for enhancing Azdroid/DeskDroid MCP Server mobile automation capabilities.

---

## 📌 1. Executive Summary & Incident Background

During automated testing of **OpenPlayer3** (a modern Android media player built with Jetpack Compose) using the DeskDroid MCP toolchain on a physical **Xiaomi Redmi 9** (1080x2340, Android 10), the AI agent became trapped in an unproductive trial-and-error loop. The objective was straightforward: **switch to the "Recent" tab and open the first video**.

Instead of completing this in two actions, the agent executed over a dozen failing `android_tap` calls at varying coordinates (`y=115`, `y=120`, `y=210`, `y=500`, `y=840`, `y=1980`) before human intervention was required.

This retrospective analyzes why existing MCP tools failed and proposes four concrete architectural enhancements to guarantee deterministic mobile automation.

---

## 🔍 2. Root Cause Analysis

### A. Resolution Fragmentation & Artifact Downscaling
- **Symptom:** Taps intended for the `Recent` tab landed on the Android Status Bar / Camera Notch (`y=115..120`).
- **Cause:** The physical display is `1080x2340` (density ~400 dpi). When `android_take_screenshot` captured the screen, the image artifact was downscaled/compressed for model context ingestion.
- **Flaw:** The agent estimated pixel coordinates from the downscaled image preview without knowing the physical scale factor. Display metrics (resolution, density) are available via `android_get_device_info` but must be queried separately before any coordinate-based interaction.

### B. Jetpack Compose Accessibility Node Merging
- **Symptom:** `android_find_element(text="Recent")` and `android_get_semantic_tree` failed to return actionable child nodes.
- **Cause:** Unlike classic Android Views (`R.id.*`), Jetpack Compose renders onto a Canvas via `SemanticsNode` trees. Components such as `ScrollableTabRow` and `LazyVerticalGrid` often merge child semantics or omit traditional resource IDs unless explicitly tagged with `Modifier.testTag`.
- **Flaw:** DeskDroid relied strictly on classic `AccessibilityNodeInfo` dumps, leaving the agent blind when testing modern declarative UIs (Jetpack Compose, Flutter).

### C. Fire-and-Forget Actions Without State Verification
- **Symptom:** The agent tapped coordinates for "the first video" even though the "Recent" tab had never been selected.
- **Cause:** `android_tap` executes an ADB input event and immediately returns `Tapped at coordinates (x, y)`.
- **Flaw:** Zero post-action feedback. DeskDroid provided no signal indicating whether the tap triggered an event, changed UI state, or was completely ignored (e.g., tapping empty space or non-clickable scrims).

### D. Coordinate Parameter Ambiguity
- **Symptom:** Confusion between normalized ratios (`0.0..1.0`) and absolute pixels.
- **Cause:** The `android_tap` schema documented coordinates as `"normalized 0.0-1.0 or pixels"`. When given `x=130, y=120`, the server parsed them as raw pixels, landing at the status bar.

---

## 🚀 3. Proposed MCP Tool Enhancements

### Proposal 1: Improved Semantic Tree for Declarative Frameworks (Compose / Flutter)
* **Concept:** Extend `android_get_semantic_tree` to handle Jetpack Compose and Flutter accessibility node merging, which is the root cause of element discovery failures in modern declarative UIs.
* **Specification:**
  - Augment the semantic tree parser to walk merged `SemanticsNode` trees and un-merge logical children when `mergeDescendants = true` (the Compose default).
  - Fall back to `uiautomator dump --compressed` raw XML when the accessibility service tree is empty or contains zero clickable nodes, then re-parse into the compact `[#ID]` digest format.
  - Expose the existing `[#ID]` mechanism via `android_click_element_by_id` — no new tool needed.
* **Impact:** Enables deterministic, coordinate-free element interaction on Compose and Flutter apps without requiring visual heuristics or heavyweight image processing.
* **Note:** A visual Set-of-Marks overlay on screenshots (inspired by OmniParser) is technically feasible as a debug-visualization auxiliary mode, but is redundant with the text-based `[#ID]` semantic tree workflow and introduces an unnecessary computer-vision dependency on the server.

### Proposal 2: Multi-Stage OCR Fallback for Zero-Accessibility Screens
* **Concept:** When semantic tree queries fail at every stage, apply OCR as a last-resort element discovery mechanism.
* **Specification:** Implement a three-step fallback chain inside `android_find_element` and `android_click_element`:
  1. **Stage 1 — Accessibility Service** *(current)*: Query `AccessibilityNodeInfo` tree.
  2. **Stage 2 — UIAutomator Raw Dump** *(new)*: Run `adb shell uiautomator dump` and parse the raw XML. This often captures nodes that the accessibility service omits.
  3. **Stage 3 — On-Device OCR** *(new, last resort)*: When both stages above return zero matches, trigger an on-device OCR pass (e.g., Android MLKit Text Recognition) to extract word bounding boxes and return center coordinates `(x, y)` for the matched label.
* **Impact:** Guarantees element discovery across any UI framework. OCR is intentionally gated behind two cheaper stages to avoid the 10–50× latency penalty of image recognition on every query.

### Proposal 3: Post-Action Semantic State Verification (`verifyChange`)
* **Concept:** Close the feedback loop after gesture execution by comparing the UI semantic state before and after a tap — replacing the agent's current "fire-and-forget" assumption.
* **Specification:**
  - Add `verifyChange: boolean` (default `false`) to `android_tap`.
  - When `true`, DeskDroid captures a snapshot of the accessibility tree **before** the tap, waits ~300ms (covering Material 3 standard animation duration), then captures the tree **after**.
  - The diff (activity changed? focused element changed? node count changed?) is returned inline:
    ```json
    {
      "tapped": {"x": 150, "y": 260},
      "stateChanged": false,
      "warning": "Tap produced no detectable UI change. The target may be non-clickable, obscured, or out of active bounds."
    }
    ```
* **Why semantic diff, not pixel hash:** Pixel frame-buffer comparison produces excessive false positives (status-bar clock updates, idle animations, notification badges) and false negatives (subtle focus-ring changes). Semantic tree diffing is lightweight, reliable, and animation-invariant.
* **Impact:** Instantly breaks blind trial-and-error tapping loops; the agent receives structured evidence to re-evaluate rather than repeating the same gesture.

### Proposal 4: Additive Coordinate Aliases (`xRatio` / `xPixel`)
* **Concept:** Eliminate runtime coordinate misinterpretation without introducing a breaking API change.
* **Specification:**
  - Add **optional alias parameters** to `android_tap`, `android_double_tap`, and `android_swipe` alongside the existing `x`/`y`:
    - `xRatio` / `yRatio` — normalized float `0.0 .. 1.0` (screen-relative).
    - `xPixel` / `yPixel` — absolute integer physical pixels.
  - When an alias is supplied it takes precedence; `x`/`y` auto-detection (`>1.0 → pixels`, `≤1.0 → ratio`) is retained for backward compatibility. **No deprecation.**
* **Why not deprecate `x`/`y`:** All existing agent workflows, prompt templates, and documentation reference `x`/`y`. A breaking rename would require rewriting every integration point with zero functional gain.
* **Impact:** Ensures cross-device deterministic behavior (phone, tablet, foldable) for new agent code while preserving full backward compatibility.

---

## 📊 4. Priority & Feasibility Matrix

| Proposal | Primary Benefit | Complexity | Status / Target |
| :--- | :--- | :---: | :---: |
| **1. Semantic Tree — Compose/Flutter** | Coordinate-free element discovery on declarative UIs | Medium | ✅ **Completed** |
| **2. Multi-Stage OCR Fallback** | Last-resort discovery for zero-accessibility screens | Medium | ⏳ Phase 3 Backlog |
| **3. Semantic State Verification (`verifyChange`)** | Breaks blind trial-and-error tap loops with structured feedback | Low | ✅ **Completed** |
| **4. Additive Coordinate Aliases** | Cross-device resolution invariance, zero breaking changes | Low | ✅ **Completed** |
