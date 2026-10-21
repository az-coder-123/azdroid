# A Smoke Test That Passed Without Running Anything

## 1. Context & Symptoms

While verifying the precompiled MCP server inside a release build, a shell smoke test reported `exit=0` but printed **no** JSON-RPC replies. The parser printed nothing either, so at first glance the run looked clean.

```bash
printf '...' | (cd / && env -i ... perl -e 'alarm 30; exec @ARGV' "$PWD/$APP/Contents/MacOS/azdroid-mcp")
# exit=0, stdout 0 bytes, stderr 0 bytes
```

## 2. Diagnostic Traces & Evidence

- `wc -c` showed both output files were empty.
- `$PWD` was expanded **inside** the subshell, after `cd /`, so the path became `/build/macos/...`, which does not exist.
- `perl -e 'exec @ARGV'` returns false when exec fails. The one-liner then ends normally, with exit code **0** and no message.
- Rerunning with an absolute path computed beforehand, plus `exec @ARGV or die`, gave the expected replies (`initialize`, 58 tools, a real device listed).

## 3. Root Cause Analysis

The check trusted the **exit code** of a wrapper whose failure mode is silent success. It never asserted that the expected output was present. Two small shell details (variable expansion after `cd`, exec without `or die`) combined into a false pass.

## 4. Architectural Solution

- `scripts/build_release.sh` asserts on content: it fails unless the reply to `tools/list` contains `"tools"`.
- Manual smoke tests compute absolute paths before changing directory and use `exec @ARGV or die`.

## 5. Prevention & Reusability Checklist

- [ ] Every smoke test asserts on expected output, not only on the exit code.
- [ ] Treat empty output as a failure unless emptiness is the expected result.
- [ ] Resolve paths before `cd` in subshells.
- [ ] Wrappers that `exec` must fail loudly (`exec ... or die`).
