# Windows SDK Macros Clash With Local Identifiers

> **Subsystem:** Windows video plugin (`windows/scrcpy_stream/scrcpy_stream_plugin.cpp`)
> **Affected Platform:** Windows (MSVC + Windows SDK headers)
> **Severity:** Medium (Windows build fails; no runtime impact)
> **Resolution Date:** October 2026

---

## 1. 🔍 Context & Symptoms

`flutter run -d windows` failed while compiling the `scrcpy_stream` plugin:

```text
scrcpy_stream_plugin.cpp(41,23): error C2062: type 'char' unexpected
```

Line 41 contained no `char` at all:

```cpp
if (const auto* small = std::get_if<int32_t>(&it->second)) port = *small;
```

The same code compiled cleanly in the platform-neutral `scrcpy_core` tests and
on other toolchains.

---

## 2. 🔬 Diagnostic Traces & Evidence

1. The column (23) points at the variable name `small`, not at a type.
2. The error says the compiler saw the type `char` where a name was expected.
3. The Windows SDK header `rpcndr.h`, pulled in transitively by `windows.h`
   (through the Flutter Windows plugin headers), contains:
   ```c
   #define small char
   ```
4. After preprocessing, the line reads `const auto* char = ...`, which is
   invalid C++.

---

## 3. 🧩 Root Cause Analysis

The Windows SDK defines several short, lowercase, object-like macros for
legacy RPC/IDL and 16-bit compatibility. The preprocessor replaces them
everywhere, ignoring C++ scope and namespaces. Any local variable, parameter,
or member with one of these names breaks the build — but only in translation
units that include `windows.h`, so shared code may compile fine elsewhere.

Known offenders include `small`, `hyper`, `near`, `far`, `interface`,
`min`, `max` (unless `NOMINMAX`), and `ERROR`.

---

## 4. 🏛️ Architectural Solution

Renamed the variables to describe their content rather than their size:

```cpp
// Avoid the name `small`: the Windows SDK defines it as a macro.
if (const auto* port32 = std::get_if<int32_t>(&it->second)) port = *port32;
if (const auto* port64 = std::get_if<int64_t>(&it->second)) port = *port64;
```

No behavior changed. A short comment marks the reason so a later cleanup does
not reintroduce the name.

---

## 5. ✅ Prevention & Reusability Checklist

- [x] **Never use SDK macro names as identifiers** in any file that may include
      `windows.h`: `small`, `hyper`, `near`, `far`, `interface`, `min`, `max`,
      `ERROR`.
- [x] **Read MSVC "type unexpected" errors as a macro hint:** when the reported
      type does not appear in the source line, suspect a macro expansion.
- [x] **Build shared native code on Windows too:** passing `scrcpy_core` tests
      on another host does not prove the code compiles next to `windows.h`.
- [x] **Prefer descriptive names** (`port32`, `port64`) over size words; they
      are clearer and avoid this class of clash.
