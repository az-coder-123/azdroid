# `am start -W` Can Hang Forever; Only a Host-Side Timeout Ends It

## 1. Context & Symptoms

On 2026-10-22, `android_launch_app(measure: true)` on a locked Redmi 9 (Android 10) never returned. The MCP call blocked the server until the adb process was killed by hand, three times in a row, including after wrapping the command in the device's `timeout 30`.

## 2. Diagnostic Traces & Evidence

```bash
# Host: still waiting minutes later
adb -s 192.168.1.3:5555 shell timeout 30 am start -W -n com.android.settings/.MainSettings
# Device after 30 s:
#   28716 Zs [timeout]                 <- timeout exited
#   28956 Ss  sh  SyS_rt_sigsuspend
cat /system/bin/am                     # Android 10 and 13
#   if [ "$1" != "instrument" ] ; then cmd activity "$@"   (child, no exec)
#   else ... exec app_process ... com.android.commands.am.Am "$@"
```

Calling `timeout 30 cmd activity start -W` directly also hung: the client process was gone, yet adb did not return.

## 3. Root Cause Analysis

Two layers:

1. `am` is a shell script that runs `cmd activity` as a child, so `timeout` signalled `sh`, not the command.
2. More fundamentally, `cmd activity start -W` hands the shell's output descriptors to `system_server`, which runs the command and waits for the first frame. A locked screen never draws the activity, so system_server keeps the descriptors open after the client is killed, and adb's session stays open.

`am instrument` differs: the script `exec`s `app_process`, so a device-side `timeout` does stop it.

## 4. Architectural Solution

`McpAdbClient.runWithTimeout` (`McpAdbTimeout.run`) starts adb with `Process.start`, kills it after the deadline, and returns exit code 124 with the output so far. `McpAppStartOps` uses it (30 s) and answers "showed no frame within 30s. Is the screen locked or off?". `McpInstrumentationOps` keeps the device `timeout` (it works there) and adds the host deadline 15 s later as a fallback. Verified on the locked Redmi: the call now ends after 30 s with that message.

## 5. Prevention & Reusability Checklist

- [ ] Any adb command that waits on device state (`-W`, `wait-for-*`, `instrument -w`) needs a deadline on the computer.
- [ ] Do not assume a device `timeout` stops binder shell commands (`cmd …`): they run in system_server.
- [ ] Read `/system/bin/<tool>`: a wrapper script decides which process a signal reaches.
- [ ] Test "the device cannot do it now" cases (locked screen) for every blocking command.
