# Documented Shortcuts That Typed Letters on the Phone

## 1. Context & Symptoms

The in-app guide, `docs/shortcuts.md`, and the user guide listed <kbd>Cmd</kbd> + <kbd>O</kbd> (screen off) and <kbd>Cmd</kbd> + <kbd>R</kbd> (rotate). Pressing them in the mirror did not toggle anything; the phone received the letter `o` or `r` instead.

## 2. Diagnostic Traces & Evidence

- `ViewportKeyEventHandler` (control feature) handled other primary shortcuts, but had no case for `keyO` or plain `keyR`. Unhandled keys fall through to `AndroidKeyCodes.mapLogicalKey`, which sends the letter.
- No code called `StreamingCubit.toggleScreenOff` or `rotateScreen` from the keyboard; only the toolbar buttons did.

## 3. Root Cause Analysis

The actions live in the **streaming** feature, and the key handler in the **control** feature. Control cannot import streaming (streaming already imports control's dialogs, and cycles are forbidden), so the shortcuts were documented but never connected. No test pressed them.

## 4. Architectural Solution

- The control handler returns `KeyEventResult.ignored` for primary+O and primary+R (without Shift), so the event bubbles up the focus tree.
- `MirroringActiveView` (streaming) wraps its layout in `CallbackShortcuts` built from `ShortcutScheme.activator`, so Cmd on macOS and Ctrl on Windows both work.
- `mirroring_page_test.dart` presses primary+O and verifies `toggleScreenOff` and the **Screen Off** badge. Tooltips show the shortcut labels from the same scheme.

## 5. Prevention & Reusability Checklist

- [ ] Every documented shortcut needs a widget test that sends the key combination.
- [ ] When a key handler and the action live in different features, let the event bubble to the feature that owns the action instead of importing across features.
- [ ] Show the shortcut in the button tooltip from the same `ShortcutScheme` that handles it, so docs and behavior cannot drift.
