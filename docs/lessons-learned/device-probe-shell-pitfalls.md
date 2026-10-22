# Shell Pitfalls When Probing Devices (Process Lesson)

## 1. Context & Symptoms

While measuring device behavior for the development tools on 2026-10-22, several probes gave wrong or empty results that had nothing to do with the devices:

| Probe | Wrong result |
| :--- | :--- |
| `A="adb -s $D shell"; $A getprop …` | `command not found: adb -s … shell` (same mistake made earlier in the session) |
| `while read L; do adb shell "…$L…"; done < layers.txt` | Only the first layer was measured |
| Background `(sleep 9; am start …) &` started before an MCP `wait` call | Waits timed out; the action happened before the wait began |
| Reading PNG bytes with Python `zlib` to compare brightness | Same mean for dark and light screens |
| `fps` on the Settings home page, idle | 125 frames: looked like a bug |
| Restoring `pointer_location` from a saved value | `settings put … null` fails: the setting was never set; `settings delete` restores the default |

## 2. Diagnostic Traces & Evidence

- zsh does not split an unquoted `$A` into words, unlike bash.
- `adb shell` reads stdin, consuming the rest of the `while read` input.
- The MCP driver starts `dart run` (several seconds) and runs earlier calls first, so fixed sleeps in a background job do not line up with a later call.
- PNG rows are filtered before compression; raw decompressed bytes are not pixel values.
- `dumpsys gfxinfo` showed 193 frames in 2 s on that page: an animation, so the measurement was right.

## 3. Root Cause Analysis

The probes were written quickly, as bash habits in a zsh session, and timing assumptions were not checked. Each gave a plausible but false signal; two were nearly recorded as device behavior.

## 4. Architectural Solution

Corrected probes: a shell function `a(){ adb -s $D shell "$@" </dev/null; }`; start the wait first, then trigger the action from the shell after a delay; view screenshots instead of decoding PNG by hand; confirm a surprising number with a second source (`gfxinfo` for frame counts, a manual command for logcat filters).

## 5. Prevention & Reusability Checklist

- [ ] In zsh, use functions or arrays, never a command stored in a string.
- [ ] Add `</dev/null` to `adb shell` inside loops that read stdin.
- [ ] Trigger device actions after a blocking call has started, not on a fixed schedule from the start.
- [ ] Do not hand-decode image formats; look at the image or use a decoder.
- [ ] Before reporting a device result as a bug or a fact, confirm it with a second, independent measurement.
- [ ] When saving a setting to restore it, treat `null` as "not set" and restore with `settings delete`.
