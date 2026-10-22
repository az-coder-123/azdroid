# `input keyevent --meta` Is Not Supported: Clearing Removed One Character

## 1. Context & Symptoms

On 2026-10-22, while testing the consolidated `android_input_text` on a Moto g play (Android 13), an empty `text` (clear) answered `Cleared text on ZY22J62QM9`, but the search field still read `wifi  x`.

## 2. Diagnostic Traces & Evidence

The tool ran `input keyevent 123 && input keyevent --meta 4096 29 && input keyevent 67` (end, Ctrl+A, delete):

```bash
adb -s ZY22J62QM9 shell input text hello
adb -s ZY22J62QM9 shell input keyevent --meta 4096 29   # exit 0, field still "hello"
adb -s ZY22J62QM9 shell input keycombination 113 29     # selects all
adb -s ZY22J62QM9 shell input keyevent 67               # field empty (hint shown)
adb -s 192.168.1.3:5555 shell input keycombination 113 29   # Android 10: prints "Usage: input ..."
```

`input`'s usage lists `keyevent [--longpress|--doubletap]` on Android 13 and `keyevent [--longpress]` on Android 10: no `--meta` on either.

## 3. Root Cause Analysis

`input` ignored the unknown flag and still exited 0, so the chain only moved the cursor to the end and deleted one character. The tool checked the exit code alone, the same false success as [adb-shell-false-success.md](adb-shell-false-success.md). The Ctrl+A step had never worked on a real device.

## 4. Architectural Solution

`McpAdbTextOps.clearText`:

1. `input keycombination 113 29` (Android 13+), then DEL, when the output is not a usage message.
2. Otherwise moves to the end and sends one DEL per character of the focused field, read from the UI tree (`focusedTextLength`); with no focused field it reports failure.

Verified on the Moto through the server (clear, `clearFirst`) and the fallback command by hand; Android 10 accepts several key codes in one `input keyevent`.

## 5. Prevention & Reusability Checklist

- [ ] Check `input`'s usage on each Android version before relying on a flag.
- [ ] An exit code of 0 from `input` does not mean the flag was understood.
- [ ] Verify an action by reading the state back on a device (here the field's text), not by the tool's own message.
