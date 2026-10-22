# adb shell Joins Arguments into a Shell Command Line

## 1. Context & Symptoms

`android_type_text`, `android_set_clipboard` (via `android_set_text`), and `android_dismiss_notification` passed agent-supplied text as separate `adb shell` arguments. On a Redmi 9 (Android 10):

```text
$ adb shell input text "it's"
/system/bin/sh: no closing quote           (exit 1)
```

So `a; reboot` would have run `reboot`, and a notification key (which contains `|`) would have been split into a pipe.

## 2. Diagnostic Traces & Evidence

- `adb shell a b c` sends one string, `a b c`, to the device's `sh -c`. Quoting on the computer side (`Process.run` arguments) does not survive.
- After the fix, a device test typed `x;touch /sdcard/Download/azdroid_probe`: the tool succeeded and the file did not exist.

## 3. Root Cause Analysis

`Process.run(adb, [..., 'shell', 'input', 'text', text])` looks injection-safe on the computer, but adb concatenates everything after `shell` and the device shell parses it again. Only spaces were escaped (`%s`), for `input text` itself.

## 4. Architectural Solution

- `McpAdbTextOps.shellQuote` wraps a value in single quotes (`'` → `'\''`); used for typed text, clipboard text, and notification keys.
- `test/unit/mcp_device_capability_test.dart` asserts the exact quoted argument (`'it'\''s%sa;%sreboot'`) and the quoted key.

## 5. Prevention & Reusability Checklist

- [ ] Any value from an agent or a user that goes after `adb shell` must pass through `shellQuote` (or be a fixed token).
- [ ] Review new `adb shell` calls for `'`, `;`, `|`, `$`, and spaces in their arguments.
- [ ] Test with a payload whose side effect you can check (create a file) rather than one that harms the device.
