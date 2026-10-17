# Windows Command Output Differs From macOS

## 1. Context & Symptoms

The Windows port audit found 13 parsers that use `split('\n')` on command output, plus discovery code that assumes macOS command formats. On Windows they would produce wrong results **without throwing**.

## 2. Diagnostic Traces & Evidence

| Command | macOS | Windows |
|:---|:---|:---|
| Line ending | `\n` | `\r\n`, so `split('\n')` leaves a trailing `\r` on every line |
| PATH lookup | `which adb` prints one path | `where adb.exe` may print **several** paths |
| ARP table | `arp -an`: `? (192.168.1.3) at 7c:fd:... on en0` | `arp -a`: `  192.168.1.3   7c-fd-...   dynamic` |
| ARP headers | none | `Interface: 192.168.1.10 --- 0x5` contains the **host** IP |
| Unresolved ARP | `(incomplete)` | `00-00-00-00-00-00 invalid` |
| Open / reveal file | `open` exits `0` on success | `explorer.exe` exits **`1` even on success** |

A trailing `\r` breaks equality checks such as `line == 'device'` and serial matching.

## 3. Root Cause Analysis

The parsers were written and tested only against macOS output, so the fixtures encoded macOS formats.

## 4. Architectural Solution

- `String.splitLines()` (`core/extensions/line_split_extension.dart`) wraps `LineSplitter`, which handles `\n`, `\r\n`, and `\r`.
- `AdbBinaryLocator` and `AaptPathResolver` take the **first** line of the lookup output.
- `ArpTableParser` is format-agnostic: it takes the first IPv4 token per line and skips known header and invalid markers. It does not branch on the OS.
- Command names and arguments come from `HostToolchain`, not from literals in data sources.
- `WindowsHostFileLauncher` ignores the `explorer.exe` exit code; only a failure to start the process is an error.
- Tests feed the same logical data in both formats and expect identical results.

## 5. Prevention & Reusability Checklist

- [ ] Never call `split('\n')` on process output; use `splitLines()`.
- [ ] Every parser test includes a CRLF fixture.
- [ ] Treat lookup commands as returning *zero or more* lines.
- [ ] Prefer one format-agnostic parser over per-OS parsers when the data is the same.
- [ ] Check the exit-code convention of every new Windows tool before treating non-zero as failure.
