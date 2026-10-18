# `dumpsys` Focus Lines Differ by Android Version and Screen State

## 1. Context & Symptoms

The MCP tool `android_get_current_app` returned *"Unable to detect active foreground application."* on a Redmi 9 (MIUI, Android 10). It was noticed by chance while verifying MCP live activity (backlog BL-09). The same tool worked on a Moto g play 2023 (Android 13) in the same state.

## 2. Diagnostic Traces & Evidence

Both phones were locked (`isStatusBarKeyguard=true`, `mWakefulness=Asleep`). `dumpsys window displays`:

```text
# Redmi 9, Android 10
mCurrentFocus=Window{999448a u0 StatusBar}
mFocusedApp=AppWindowToken{fa39d7e token=Token{da57339 ActivityRecord{1b46f00 u0 com.miui.home/.launcher.Launcher t3}}}

# Moto, Android 13
mCurrentFocus=Window{d3073c1 u0 NotificationShade}
mFocusedApp=ActivityRecord{d357582 u0 com.motorola.launcher3/com.android.launcher3.CustomizationPanelLauncher} t6}
```

The parser tried `mCurrentFocus=Window{… pkg/activity` and then `mFocusedApp=ActivityRecord{…`. Before and after the fix, on the same locked Redmi:

```text
old: "Unable to detect active foreground application."  (isError)
new: Package: com.miui.home, Activity: com.miui.home.launcher.Launcher,
     Note: the system window "StatusBar" is in front of it …
```

## 3. Root Cause Analysis

Two assumptions failed together:

1. **The focused window is an app.** On the lock screen, or with the notification shade open, focus belongs to a system window (`StatusBar`, `NotificationShade`) whose title has no `package/activity`.
2. **`mFocusedApp` starts with `ActivityRecord{`.** Android 10 wraps it as `AppWindowToken{… ActivityRecord{…}}`; Android 11+ prints the record directly.

On Android 11+ the fallback still matched, so the tool looked fine on newer devices. It also looked fine on unlocked phones, so tests with an app in focus never showed the problem.

## 4. Architectural Solution

- `McpForegroundAppParser` (pure Dart, `lib/features/mcp/domain/services/`) reads, in order:
  1. `mCurrentFocus` when it is an app window;
  2. the first `ActivityRecord{… pkg/activity` after `mFocusedApp=` (both formats);
  3. `ResumedActivity` from `dumpsys activity activities` (second command, only when 1 and 2 fail).
- When a system window has focus, the tool still returns the app and adds a note naming that window, so the AI knows to unlock or close it before tapping.
- Short activity names (`.launcher.Launcher`) are expanded to the full class.
- Unit tests use the real lines above as fixtures.

## 5. Prevention & Reusability Checklist

- [ ] Parse `dumpsys` output with fixtures from the **oldest and newest** supported Android versions.
- [ ] Test parsers in the screen states an agent meets: locked, notification shade open, dialog, app.
- [ ] Match the inner record (`ActivityRecord{…}`) anywhere on the line, not the wrapper type that precedes it.
- [ ] When a "not found" result has a reason (a system window in front), return the reason instead of a bare error.
- [ ] `git stash` does not stash untracked files: to prove a test fails without a fix, also stash or move the new files (`git stash -u`), or compare old and new builds on a device.
