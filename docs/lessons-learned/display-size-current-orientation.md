# Screen Fractions Need the Current Orientation's Size

## 1. Context & Symptoms

MCP touch tools turn screen fractions (`xRatio: 0.5`) into pixels with the display size. That size came from `wm size` (`Physical size: 720x1600`) and was cached per device for the life of the process. In landscape (`cur=1600x720`), `xRatio: 0.9` became x = 648 instead of 1440, and a size set with `android_set_display_config` was ignored. Found on 2026-10-22 while building multi-finger input for games, which often run in landscape.

## 2. Diagnostic Traces & Evidence

```bash
adb -s ZY22J62QM9 shell wm size                  # Physical size: 720x1600 (always)
# Settings in front, user_rotation=1:
adb -s ZY22J62QM9 shell "dumpsys window displays | grep -oE 'cur=[0-9]+x[0-9]+'"   # cur=1600x720
# after wm size 600x1334:                                                           # cur=600x1334
```

`cur=` is present on Android 10 (`cur=1080x2340`) and 13. A launcher locked to portrait does not rotate, so the test needs an app that does.

## 3. Root Cause Analysis

`wm size` reports the panel in its natural orientation. Input coordinates are in the current logical orientation. A cache invalidation function existed (`invalidateDisplaySize`) but nothing called it.

## 4. Architectural Solution

`McpAdbInputOps.getDisplaySize` reads `cur=WxH` from `dumpsys window displays` (falling back to `wm size`) and reuses it for 3 seconds (`sizeCacheTtl`), enough for a burst of calls and short enough to follow a rotation.

## 5. Prevention & Reusability Checklist

- [ ] Use the current orientation's size for anything in screen coordinates.
- [ ] Do not cache device state that the user or the agent can change (rotation, overrides) for longer than a few seconds.
- [ ] Test coordinate tools in landscape with an app that rotates.
