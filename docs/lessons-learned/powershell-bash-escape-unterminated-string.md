# PowerShell Script Bash-Style Escapes Break .ps1 Parsing

> Case study: `scripts/deploy.ps1` failed to parse on Windows PowerShell 5.1 because a string used bash-style escaping (`\``) instead of PowerShell escape semantics, leaving a string literal unterminated and corrupting quote parity for the rest of the file.

---

## 1. Context & Symptoms

- **Scope:** Windows release pipeline (`scripts/deploy.ps1`), executed per the release runbook as `powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1`.
- **Environment:** Windows PowerShell 5.1 (stock `powershell.exe`), repository on `main` at the freshly published macOS release tag.
- **Symptoms:** The script died instantly at startup — before any pipeline step ran — with parser errors:

```text
line 416: Unexpected token 'Azdroid' in expression or statement.
line 423: The string is missing the terminator: ".
```

- The confusion multiplier: the reported line numbers (416/423) contained **plain ASCII strings that looked syntactically perfect** (`Write-Host " Azdroid v$(...)"`), so the first instinct was an encoding problem, not a syntax problem.

## 2. Diagnostic Traces & Evidence

1. **Reproduce the parse statically** with the language parser API instead of executing:

   ```powershell
   $errs = $null
   $null = [System.Management.Automation.Language.Parser]::ParseFile(
     'E:\projects\desk-droid\scripts\deploy.ps1', [ref]$null, [ref]$errs)
   $errs | ForEach-Object { '{0}: {1}' -f $_.Extent.StartLineNumber, $_.Message }
   ```

   Result: 9 cascade errors anchored at lines 357, 411, 416, 423, and a dangling `try` block at 196.

2. **Encoding hypothesis test** (the file banner contains an em dash `—`):

   ```powershell
   $b = [System.IO.File]::ReadAllBytes($path)
   # First bytes: 3C 23 ... -> no UTF-8 BOM
   [regex]::Matches($text, '[^\x00-\x7F]')  # only the em dash
   ```

   Removing the em dash made the file pure ASCII — **but the exact same 9 parse errors remained**. Encoding was a red herring; the parser failure survived an ASCII-pure file.

3. **Root-cause anchor:** the *earliest* error line in the cascade is the real defect site. Line 357 (`Write-Ok "Updated ..."`) failed because the string opened there closed a *runaway* string that had been open since line 353:

   ```powershell
   # line 353 — broken (bash-brain escaping):
   $newInstall = "unzip \`$zipName\`"
   ```

## 3. Root Cause Analysis

PowerShell escape character is the **backtick**, never the backslash:

| Written | PowerShell 5.1 reading | Intended (bash-brain) |
|:---|:---|:---|
| `` \`$zipName `` | literal `\` + escaped literal `$zipName` | escaped `$` (literal dollar) |
| `` \`" `` | literal `\` + escaped `"` → **string does not close** | literal closing quote |

So in `"unzip \`$zipName\`"`:

1. The final `` \`" `` escapes the closing quote → the string **never terminates** on its line.
2. The string stays open, swallowing lines 354–356 (interpolating `$readmeContent`, `$ReadmePath` as variables on the way).
3. The next `"` in the file (line 357) **closes** the runaway string, flipping quote parity.
4. Every subsequent quote boundary is offset by one → `Unexpected token`, `Missing closing ')'`, and finally `The string is missing the terminator` at the last line of the file.

The bug is invisible to skimming because `\``  renders almost like `` ` `` in most fonts, and the failing lines reported by the parser are far away from the defective line.

The encoding angle still mattered for hygiene: a BOM-less UTF-8 `.ps1` with non-ASCII characters is mis-decoded under ANSI codepages, which is a *second*, independent way to corrupt parsing. It just was not the cause here.

## 4. Architectural Solution

1. **Correct escape semantics** — markdown backticks in the replacement text are produced with doubled backticks; the variable stays interpolated:

   ```powershell
   $newInstall = "unzip ``$zipName``"
   ```

2. **Keep release scripts ASCII-pure.** Em dash `—` in comments/banners replaced with `-`, so every `.ps1` in `scripts/` parses identically under any codepage, with or without a BOM.
3. **Parse-gate before executing long pipelines.** A 2-second static parse check now precedes any deploy attempt:

   ```powershell
   $errs = $null
   $null = [System.Management.Automation.Language.Parser]::ParseFile(
     (Resolve-Path scripts\deploy.ps1), [ref]$null, [ref]$errs)
   if ($errs.Count -gt 0) { throw 'deploy.ps1 does not parse' }
   ```

4. **Trust error-line anchoring correctly:** parser errors point *near* the defect, and the first (smallest line number) error in a cascade marks the true defect site; later lines are victims of the shifted quote state.

## 5. Prevention & Reusability Checklist

- [ ] Never port bash/Perl escaping instincts into `.ps1` strings: only `` ` `` escapes; `\` is a literal character everywhere in PowerShell.
- [ ] To emit a literal backtick inside a double-quoted string, write two: `` `` ``.
- [ ] To emit a literal `$var` name (no expansion), write `` `$var `` — one backtick, no backslash.
- [ ] Keep shared `.ps1` scripts ASCII-only (or save UTF-8 **with BOM**) so Windows PowerShell 5.1 decoding never depends on the host codepage.
- [ ] Before running any multi-minute deployment/build script, run the zero-cost `Parser::ParseFile` check and require 0 errors.
- [ ] When parser errors quote perfectly valid-looking lines, hunt for an **earlier unterminated string** (usually an escaped quote or unbalanced backtick), not for an encoding fault.
- [ ] Apply the same checklist to any future PowerShell entry points added under `scripts/` (the parse check covered `build_release.ps1` and `test_in_windows_sandbox.ps1` too: 0 errors each).
