# Wi-Fi ADB Authorization Prompt Shown Once, Then Never Again

> **Subsystem:** Streaming preflight (`lib/features/streaming/data/services/stream_device_preflight.dart`)
> **Affected Platform:** All hosts; Android devices connected over Wi-Fi (`adb tcpip` / `ip:port`)
> **Severity:** High (a new computer can never mirror the phone without terminal commands)
> **Resolution Date:** October 2026

---

## 1. Context & Symptoms

DeskDroid was tested in Windows Sandbox, a fresh Windows with its own ADB key, against a Redmi phone (Android 10, MIUI) in Wi-Fi ADB mode.

- The device list showed the phone as **Unauthorized**.
- Every **Connect** and **Retry Connection** ended with *"USB debugging is not allowed on … yet"*.
- The phone showed no *"Allow USB debugging?"* prompt, although the tester was watching it.

The same happened on the first Windows run with a real PC, where the only fix was `adb disconnect <ip>:5555` followed by `adb connect <ip>:5555` in a terminal.

---

## 2. Diagnostic Traces & Evidence

1. The sandbox app log showed every attempt stopping in the preflight:
   ```text
   23:41:44 Mirroring session not started: StreamStartException(deviceUnauthorized, 192.168.1.3:5555)
   ```
2. The phone's adbd log (`adb shell logcat -d -s adbd:*`) showed a single prompt request, about 30 s after the app started and a minute before the tester's first click:
   ```text
   23:40:49.990 adbd: Calling send_auth_request...
   23:40:50.010 adbd: Loading keys from /data/misc/adb/adb_keys
   ```
   No further `send_auth_request` appeared for the later attempts.
3. `dumpsys window` showed no authorization dialog on screen during the retries.

---

## 3. Root Cause Analysis

1. adbd asks the phone UI for confirmation **only when a new connection authenticates**. While the host keeps its existing (unauthorized) transport open, nothing asks again.
2. The first connection was opened by **auto-discovery** (a subnet sweep that connects to port 5555), so the prompt appeared while nobody was looking and timed out.
3. `adb connect` to an address that is already connected is a no-op, and the preflight only read `adb devices`, so neither Connect nor Retry opened a new connection.

---

## 4. Architectural Solution

`StreamDevicePreflight.ensureReady` now reconnects an unauthorized Wi-Fi device before reporting the failure:

1. `wifiEndpointOf(serial)` parses `ip:port` serials; USB and mDNS serials return `null` and are left alone (replugging USB triggers a new prompt).
2. For `deviceUnauthorized` it runs `adb disconnect <serial>` and `adb connect <ip> <port>`, which makes the phone show the prompt again, then throws the same `StreamStartException`.
3. The message tells the user to watch the phone, tap **Allow**, and retry; on USB, to replug.

Verified in Windows Sandbox: the next Retry logged `Reconnecting 192.168.1.3:5555 so the phone asks to allow it again`, the prompt appeared, and the following Retry started mirroring.

---

## 5. Prevention & Reusability Checklist

- [x] **A permission prompt that the OS shows once must be re-triggerable from the UI.** A Retry that only re-reads state cannot recover.
- [x] **Automatic background actions must not spend one-time user prompts.** Auto-discovery opening the first connection caused the missed prompt.
- [x] **Read the device-side log** (`logcat -s adbd:*`, look for `send_auth_request`) before assuming the prompt is broken.
- [x] **Test first-contact flows on a host the phone has never seen** (Windows Sandbox, a new VM); a developer machine is always already authorized.
