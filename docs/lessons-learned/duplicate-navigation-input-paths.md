# Two Paths for the Same Key: Toolbar Buttons Still Used adb

## 1. Context & Symptoms

After input moved to the scrcpy control socket, the keyboard shortcuts (<kbd>Cmd</kbd>+<kbd>H</kbd>, <kbd>Cmd</kbd>+<kbd>⌫</kbd>, <kbd>Esc</kbd>) and the right and middle mouse buttons sent BACK and HOME through it. The **Back, Home, and App Switch buttons** of the bottom toolbar did not: each press still started an `adb shell input keyevent` process, with its latency and without the scrcpy fallback logic.

## 2. Diagnostic Traces & Evidence

```text
Shortcut / mouse:  ControlBloc -> ControlRepository.sendNavigationAction
                   -> FallbackControlDatasource (scrcpy socket, adb fallback)
Toolbar button:    StreamingCubit.sendBack -> StreamingRepository.sendNavigationKey
                   -> ScrcpyServerManager.sendKeyevent -> adb shell input keyevent
```

Both paths existed because the toolbar lives in the streaming feature and was wired to the streaming cubit, while the shortcuts live in the control feature.

## 3. Root Cause Analysis

The same user action had two implementations in two features. When the control path was upgraded, only one implementation changed. Nothing tied them together, and no test asserted which path a toolbar button used.

## 4. Architectural Solution

- The toolbar buttons dispatch `ControlNavigationActionDispatched` to `ControlBloc`, which the mirroring page already provides; composing another feature's bloc in presentation is allowed by [dependency-boundaries.md](../dependency-boundaries.md).
- The duplicate path was removed: `StreamingCubit.sendBack/sendHome/sendAppSwitch`, `StreamingRepository.sendNavigationKey`, and `ScrcpyServerManager.sendKeyevent`.
- `mirroring_page_test.dart` taps all three buttons and verifies `ControlRepository.sendNavigationAction` with the right action.

## 5. Prevention & Reusability Checklist

- [ ] One user action, one implementation: buttons, shortcuts, and gestures dispatch the same event.
- [ ] When changing how an action works, search for every caller of the old mechanism (`sendKeyevent`, `input keyevent`) and remove the leftovers.
- [ ] Test that each entry point (button, shortcut, mouse) reaches the shared handler.
