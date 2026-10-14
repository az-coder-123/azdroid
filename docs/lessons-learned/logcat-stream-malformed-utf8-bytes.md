# Engineering Case Study: Handling Malformed UTF-8 Bytes in Real-time Android Logcat Streams

> **Category:** Android OS Quirk & Stream Decoding  
> **Target Subsystem:** `lib/features/logging/data/datasources/logcat_stream_datasource.dart`  
> **Status:** Resolved & Permanently Prevented

---

## 1. Context & Symptoms

When launching the **Device Logcat Console** while connected to a live Android device (such as Xiaomi Redmi 9 over Wi-Fi), the console abruptly terminated after streaming ~27,000 bytes and transitioned into the failure state:

```text
Logcat Stream Failed
FormatException: Invalid UTF-8 byte (at offset 27664)
```

The error completely blocked log inspection and rendered the console unusable upon encountering specific device logs.

---

## 2. Diagnostic Traces & Evidence

Inspecting the stream pipeline in `LogcatStreamDatasource`:

```dart
// Vulnerable pipeline
process.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(...)
```

When low-level OEM drivers (e.g. MediaTek camera ISP, baseband modems, kernel dmesg, or graphics drivers) print diagnostic hex dumps or unescaped non-ASCII bytes (e.g. `0xFF`, `0x80`, `0xFE`), standard Dart `utf8.decoder` throws an unhandled `FormatException`:

```text
FormatException: Invalid UTF-8 byte (at offset 27664)
  #0 _Utf8Decoder._throwMalformed (dart:convert-patch/convert_patch.dart)
  #1 _Utf8Decoder._consumeNonAscii (dart:convert-patch/convert_patch.dart)
  #2 _Utf8Decoder.convertChunk (dart:convert-patch/convert_patch.dart)
```

Because `utf8.decoder` defaults to `allowMalformed: false`, any non-compliant byte immediately aborts the stdout stream and crashes downstream consumers.

---

## 3. Root Cause Analysis

1. **Android Logcat Is Not Guaranteed Clean UTF-8:**
   Android applications and native kernel daemons (`logd`) accept arbitrary C strings (`char*`) via `__android_log_print()`. Native drivers and C/C++ libraries often write binary traces, raw memory pointers, or localized strings in non-UTF-8 character encodings (e.g., Latin-1, GBK).
2. **Default Strict Decoding in Dart:**
   Dart's default `utf8.decoder` enforces strict RFC 3629 compliance. If `allowMalformed` is `false`, any byte sequence that does not conform to valid UTF-8 code point encodings throws an uncaught `FormatException`.
3. **Chunk Boundary Fragmentation:**
   Even when strings are mostly UTF-8, network or pipe socket chunks can occasionally split multi-byte characters at chunk boundaries. While Dart's stateful decoder handles split code units across chunks, an isolated illegal byte will crash strict decoders.

---

## 4. Architectural Solution

### Non-Destructive Resilient UTF-8 Decoding

Configure `Utf8Decoder` with `allowMalformed: true` across all stdout and stderr stream transformers in `LogcatStreamDatasource`:

```dart
// Resilient streaming pipeline
process.stdout
    .transform(const Utf8Decoder(allowMalformed: true))
    .transform(const LineSplitter())
    .listen(
      (line) {
        if (!controller.isClosed) controller.add(line);
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.warning('Logcat stdout error: $error', error: error, stackTrace: stack);
        // Do not crash the entire session on transient stream glitches
      },
      onDone: () {
        if (!controller.isClosed) controller.close();
      },
      cancelOnError: false,
    );
```

### Key Technical Properties:
- **Unicode Replacement Characters:** Any invalid or stray byte is non-destructively translated to `\uFFFD` (``), preserving the rest of the line and surrounding context intact.
- **Continuous Stream Health:** The process stdout stream remains healthy and open for continuous logging, even when thousands of driver binary logs arrive per second.

---

## 5. Prevention & Reusability Checklist

When consuming raw process streams or sockets from external systems (Android ADB, Scrcpy, system shells):

- [x] **Never use default `utf8.decoder`:** Always explicitly instantiate `const Utf8Decoder(allowMalformed: true)`.
- [x] **Guard stream error handlers:** Non-fatal line parsing errors must log diagnostics via `AppLogger` without prematurely aborting the broadcast `StreamController`.
- [x] **Unit test invalid byte sequences:** Include tests that pass byte arrays containing `0xFF, 0xFE, 0x80` directly to the stream transformer to verify zero exceptions.
