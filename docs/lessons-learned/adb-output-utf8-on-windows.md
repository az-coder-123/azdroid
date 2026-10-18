# adb Output Garbled on Windows (System Encoding Is Not UTF-8)

> **Subsystem:** Process execution (`lib/core/services/process_executor.dart`, `process_output_encoding.dart`) and the MCP adb client
> **Affected Platform:** Windows (any locale); macOS unaffected
> **Severity:** Medium (non-ASCII device text garbled in MCP tools and in the app)
> **Resolution Date:** October 2026

---

## 1. Context & Symptoms

On Windows, `android_get_semantic_tree` returned Vietnamese UI text as mojibake:

```text
[#5] TextView text:"CÃ i Ä‘áº·t" id:"icon_title"        # expected "Cài đặt"
[#8] TextView text:"Quáº£n lÃ½ Táº­p tin"              # expected "Quản lý Tập tin"
```

The same text appeared correctly on macOS and in the mirrored video.

---

## 2. Diagnostic Traces & Evidence

1. The garbling pattern (`Ã`, `Ä‘`, `áº`) is UTF-8 bytes read as Windows-1252.
2. `McpAdbClient.run` called `Process.run(adb, args)`, and `DefaultProcessExecutor.run` called `Process.run` without an encoding. Both default to `systemEncoding`.
3. `systemEncoding` is UTF-8 on macOS but the ANSI code page on Windows. adb forwards the device's bytes unchanged, and Android emits UTF-8.
4. About 46 adb call sites in the app go through the same executor (file listings, clipboard, package names, logcat snapshots).

---

## 3. Root Cause Analysis

The decoding depends on **who produced the bytes**, not on the host. adb output always comes from Android (UTF-8). Host tools (`where`, `arp`, `powershell`) print in the host code page. A single default (`systemEncoding`) is right for one group and wrong for the other on Windows, and the bug stays invisible on macOS, where both are UTF-8.

---

## 4. Architectural Solution

- `process_output_encoding.dart` defines `adbOutputEncoding` (`Utf8Codec(allowMalformed: true)`, so binary dumps never throw) and `processOutputEncodingFor(executable)`, which returns it for `adb` / `adb.exe` and `systemEncoding` for everything else.
- `DefaultProcessExecutor.run` passes that encoding as `stdoutEncoding` and `stderrEncoding`, which fixes every adb call in the app in one place without changing the `ProcessExecutor` interface or its mocks.
- `McpAdbClient.run` uses `adbOutputEncoding` directly. Binary calls (`exec-out screencap`) keep `stdoutEncoding: null`.

Verified on Windows: a fresh MCP server returned `"Chỉ cuộc gọi khẩn cấp"` and `"Tín hiệu Wi-Fi đầy."` from a Redmi phone.

---

## 5. Prevention & Reusability Checklist

- [x] **Choose the decoding by the producer of the bytes.** Device output (adb) is UTF-8; host tool output is the host code page.
- [x] **Never rely on `systemEncoding` for data from another machine.**
- [x] **Use `allowMalformed: true` for streams that may contain binary data.**
- [x] **Test non-ASCII text on Windows**; macOS hides encoding bugs because its system encoding is UTF-8.
