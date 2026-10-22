# Ascii-Encoding README Rewrite Clobbers UTF-8 Content

> Case study: the first successful run of `scripts/deploy.ps1` rewrote `README.md` through `Set-Content -Encoding Ascii`, replacing every emoji, em dash, and arrow in the repository landing page with literal `?` characters, and pushed the damaged file to `origin/main`.

---

## 1. Context & Symptoms

- **Scope:** Step 7 ("Documentation Synchronization") of the Windows release pipeline, right after the first-ever successful parse of `deploy.ps1` (see [powershell-bash-escape-unterminated-string.md](powershell-bash-escape-unterminated-string.md)).
- **Symptoms:** Immediately after the deploy commit landed, README lines rendered as `# ?????? Azdroid ??? High-Performance ...`, `???? Why Azdroid?`, and `More info ??? Run anyway`. A scan counted **361 `?` characters and 0 non-ASCII characters** in a file that previously carried 150+ emoji and typographic symbols.

## 2. Diagnostic Traces & Evidence

```powershell
$cur = [System.IO.File]::ReadAllText('E:\projects\desk-droid\README.md')
[regex]::Matches($cur, '[^\x00-\x7F]').Count   # 0  (expected: 150+)
[regex]::Matches($cur, '\?').Count             # 361
```

- The deploy log showed Step 7 completing normally — no error, because encoding loss is silent.
- Line-level scan located `?` clusters exactly where the original file had emoji (`⚡️`, `🚀`), em dashes (`—`), arrows (`→`), and middle dots (`·`).
- Root lines in `deploy.ps1`:

```powershell
$readmeContent = Get-Content -Path $ReadmePath -Raw            # ANSI decode (PS 5.1 default)
$readmeContent | Set-Content -Path $ReadmePath -Encoding Ascii # '?'-collapse on write
```

## 3. Root Cause Analysis

Two stacked encoding faults, both silent:

1. **Read side:** Windows PowerShell 5.1 `Get-Content` without `-Encoding` decodes files using the system **ANSI codepage** (no BOM detection for UTF-8). Multi-byte UTF-8 emoji decode as garbage ANSI characters.
2. **Write side:** `Set-Content -Encoding Ascii` maps every character above `U+007F` — including the garbage from step 1 and every legitimately non-ASCII character that survived — to a literal `?` byte. The information is **unrecoverable** from the output file.

The combination is destructive in exactly one round trip, produces zero warnings, and only manifests visually after being pushed. Scripts authored on macOS (UTF-8 everywhere, `Set-Content` equivalents lossless) do not exhibit this, so the bug survived until the pipeline first ran on Windows.

## 4. Architectural Solution

1. **Restore from the last good blob** and re-apply only the intended edits:

   ```powershell
   git checkout ae19680 -- README.md   # pristine macOS-release blob
   $t = [System.IO.File]::ReadAllText($path)                    # UTF-8 aware
   $t = [regex]::Replace($t, '<windows-badge-pattern>', '<new>')  # 3 targeted edits
   [System.IO.File]::WriteAllText($path, $t,
     (New-Object System.Text.UTF8Encoding($false)))             # byte-faithful write
   ```

2. **Harden the pipeline:** `deploy.ps1` Step 7 now reads with `[System.IO.File]::ReadAllText` and writes with `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))` — both encoding-explicit, codepage-independent, and lossless for the repository's UTF-8 content.
3. **Diff as a safety gate:** after any scripted rewrite of shared docs, require `git diff --stat` to show **only the intended line ranges** (here: exactly 2 lines). A wider diff means silent corruption.
4. `Update-ReleaseReadme` keeps `Set-Content` only for `RELEASE/README.md`, whose template is ASCII-only by construction.

## 5. Prevention & Reusability Checklist

- [ ] Never use `Get-Content`/`Set-Content` without explicit `-Encoding` on files shared across platforms; prefer `[System.IO.File]::ReadAllText` / `WriteAllText` with an explicit `UTF8Encoding`.
- [ ] `Set-Content -Encoding Ascii` on any user-facing Markdown is a data-destroying operation — ban it in release tooling.
- [ ] Treat "silent success" from documentation-rewrite steps with suspicion: verify content invariants (non-ASCII counts, spot-check headings) after scripted edits.
- [ ] Restore corrupted text files from the last good commit (`git checkout <ref> -- <file>`) instead of hand-repairing; re-apply scripted edits deterministically on top.
- [ ] Keep the parse-gate and encoding rules from [powershell-bash-escape-unterminated-string.md](powershell-bash-escape-unterminated-string.md) together: both classes of bug only surface when the Windows pipeline finally executes end-to-end.
- [ ] When a previously-never-executed code path runs for the first time (here: the first successful `deploy.ps1` run), audit its side effects on shared files immediately after the run.
