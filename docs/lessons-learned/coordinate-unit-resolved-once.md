# Coordinate Units Must Be Resolved Once, in One Place

## 1. Context & Symptoms

The MCP touch tools accept fractions (`xRatio`), pixels (`xPixel`), or raw values (`x`). A review of new tool descriptions ("use `*Ratio`/`*Pixel` to pin the unit explicitly") on 2026-10-22 found that the code did not honor that promise:

- `xPixel: 1, yPixel: 1` tapped the **bottom-right corner**, not pixel (1, 1).
- `xRatio: 0.5, yPixel: 600` tapped pixel **x = 1**, not the middle of the screen.
- A swipe decided the unit of all four values from `startX` alone.

No user report existed; the faults showed up while checking a documentation claim against code.

## 2. Diagnostic Traces & Evidence

Five places guessed the unit, with three different rules:

| Place | Rule |
| :--- | :--- |
| `McpArgumentHelper.getPointPair` | Returned `xRatio` / `xPixel` values **unconverted**, units dropped |
| `McpAdbInputOps.tap` / `doubleTap` | Both values in `[0, 1]` (inclusive) ⇒ fractions |
| `McpAdbInputOps.swipe` | `startX` in `[0, 1]` ⇒ all four are fractions |
| `McpAdbEnvironmentOps.longPress` | Both in `(0, 1)` (exclusive) ⇒ fractions, then called `swipe`, which could convert again |
| `McpAdbBatchCompiler.resolvePoint` | Both in `(0, 1)` (exclusive) |

So the explicit unit was parsed, thrown away, and re-guessed later from the value alone.

## 3. Root Cause Analysis

Coordinates crossed two layers as bare `double`s. The argument layer knew the unit; the adb layer, which needed it, did not. Each layer then "helped" by guessing, and each guess was written separately. A pixel value in `[0, 1]`, or a mix of units, is indistinguishable from fractions once the unit is gone.

## 4. Architectural Solution

- `McpPoint` (`lib/features/mcp/data/utils/mcp_point.dart`) carries the value **and** its unit per axis (`ratio`, `pixel`, `auto`) and owns the only resolution rule (`toPixels`).
- `McpPointArguments` reads points from tool arguments into `McpPoint`; the old `getPoint`, `getPointPair`, and `getOptionalPointPair` are gone.
- The adb layer takes `McpPoint` and sends pixels only (`McpAdbInputOps.toPixels`), querying `wm size` only when a fraction needs it. Element centers and compiled batch steps pass `McpPoint.pixels`.
- Scroll paths and durations are shared by `android_scroll` and batch scrolls (`mcp_scroll_path.dart`).
- `test/unit/mcp_point_test.dart` covers both faults above and checks the exact `input tap` / `input swipe` commands.

## 5. Prevention & Reusability Checklist

- [ ] Never pass a value across layers without its unit; use a type that carries it.
- [ ] Resolve units in one function; delete every other guess, do not "align" them.
- [ ] When a description promises behavior ("pins the unit"), add a test for the edge case that would break it (pixel 1, mixed units).
- [ ] Grep for the heuristic itself (`<= 1.0`, `< 1.0`) to find every copy before fixing one.
