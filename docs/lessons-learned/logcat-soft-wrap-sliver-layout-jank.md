# Logcat Soft-Wrap Sliver Layout Jank & Main Thread Freezing

> Case study on resolving a multi-second UI thread freeze in Flutter desktop virtualized lists when switching from fixed-extent to dynamic-extent layout with large buffers.

---

## 1. Context & Symptoms

In the **Device Logcat Console**, users can toggle the **"Enable soft wrap"** action (`Icons.wrap_text_rounded`) to toggle between single-line truncated mode and wrapped multi-line view.

When streaming large logcat buffers (e.g. 5,000 entries) and positioned at the bottom of the log stream:
- Toggling "Enable soft wrap" caused the entire macOS Flutter application to completely freeze and become unresponsive for **8 to 10 seconds**.
- Mouse clicks were dropped, the scrollbar became unresponsive, and macOS displayed the spinning wait cursor ("beachball").
- Once the freeze resolved, the user was unexpectedly thrown thousands of pixels backward into older log entries instead of staying anchored to the latest streaming logs.

---

## 2. Diagnostic Traces & Evidence

Benchmarking with an exact reproduction widget test (`test/widget/log_console_table_perf_test.dart`) on 5,000 real-world Android logcat entries (`{ act=android.net.conn.CONNECTIVITY_CHANGE ... }`):

```text
Current offset before toggle: 129400.0
SoftWrap toggle ON duration at bottom: 9597 ms (Over 9.5 seconds!)
```

Dissecting the layout breakdown:
1. **With SelectionArea + unbounded `maxLines: null`:** ~10,522 ms.
2. **Without SelectionArea + unbounded `maxLines: null`:** ~6,754 ms.
3. **With adaptive `reverse: true` (offset 0.0 at bottom):** **169 ms** (~57x speedup).

---

## 3. Root Cause Analysis

Three distinct technical factors compounded to create the 10-second main thread freeze:

1. **`RenderSliverList` Layout-From-Zero Traversal:**
   - In single-line mode, `ListView.builder` configured `itemExtent: 26.0`, utilizing `RenderSliverFixedExtentList`. Flutter calculates item indices in $O(1)$ time (`index = scrollOffset ~/ itemExtent`).
   - When soft wrap is enabled, `itemExtent` becomes `null`, forcing Flutter to instantiate `RenderSliverList`.
   - At the bottom of 5,000 items, `scrollController.offset` was ~129,400.0 px. Because dynamic-extent children have unknown heights, `RenderSliverList` cannot mathematically determine which child corresponds to offset 129,400.0.
   - Flutter was forced to synchronously build, measure, and layout **all 5,000 children starting from index 0** to sum their heights until reaching 129,400.0 px.

2. **Unbounded `maxLines: null` Paragraph Measurement:**
   - Giant Android dumpsys payloads or stack traces with hundreds of lines generated extreme CPU text-shaping workloads across thousands of off-screen items.

3. **`SelectionArea` Geometry Overhead:**
   - Wrapping the entire virtualized list in `SelectionArea` required every laid-out child to instantiate `Selectable` registrars and calculate selection bounding boxes.

---

## 4. Architectural Solution

We refactored `LogConsoleTable` and `LogConsoleRow` using an **Adaptive Reversed Sliver Architecture**:

### A. Adaptive Reverse Layout (`reverse: entries.length >= 25`)
- When total log count is small (< 25 entries), `reverse: false` is used so items render naturally from the top of the dialog.
- Once logs fill the viewport (>= 25 entries), `reverse: true` is activated.
- In `reverse: true`, the bottom of the console is scroll offset `0.0`, and index 0 corresponds to the latest log entry (`entries.last`).
- When soft wrap is toggled at the bottom, Flutter only needs to measure the ~25 visible children intersecting the viewport at offset 0.0. Items 26 through 5,000 are **never laid out or measured**.
- Streaming incoming logs requires zero `jumpTo(maxScrollExtent)` calls; the viewport naturally remains anchored at offset 0.0 at 60 FPS.

```dart
final isReversed = widget.entries.length >= 25;

ListView.builder(
  key: ValueKey('log_table_${isReversed}_${widget.softWrap}'),
  controller: _scrollController,
  reverse: isReversed,
  itemCount: widget.entries.length,
  physics: const ClampingScrollPhysics(),
  itemExtent: widget.softWrap ? null : 26.0,
  itemBuilder: (context, index) {
    final entry = isReversed
        ? widget.entries[widget.entries.length - 1 - index]
        : widget.entries[index];
    return LogConsoleRow(...);
  },
)
```

### B. Bounded Row Wrapping
In [log_console_row.dart](../../lib/features/logging/presentation/widgets/log_console_row.dart):
```dart
maxLines: softWrap ? 6 : 1,
overflow: TextOverflow.ellipsis,
```
- Capping wrapped entries to 6 lines guarantees predictable line measurements while multi-line intents and network dumps remain easily readable.
- Full unconstrained stack traces remain accessible via the dedicated `LogDetailDrawer`.

### C. Native Desktop Scrollbar & Explicit Action Copy
- Replaced the heavy `SelectionArea` with native desktop `Scrollbar` and 1-click line clipboard copy.

---

## 5. Prevention & Reusability Checklist

- [x] **Never toggle `itemExtent` between fixed and null at large scroll offsets:** Switching from fixed extent to dynamic extent while `scrollOffset > 0` triggers full $O(N)$ child layout.
- [x] **Prefer `reverse: true` for append-only streaming views:** In terminals, chat applications, and log consoles, offset 0.0 should be the latest content to prevent sliver traversal lag.
- [x] **Cap `maxLines` on dynamic virtualized rows:** Always set an upper bound (e.g. 6-8 lines) on table rows to prevent pathological dumpsys lines from blocking layout.
- [x] **Avoid wrapping dynamic-extent `ListView` in `SelectionArea`:** Rely on row-level copy actions or dedicated detail inspectors for high-throughput streaming tables.
