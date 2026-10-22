# Two Machines Committing to `main` Diverge the Branch (Process Lesson)

## 1. Context & Symptoms

On 2026-10-22, after the macOS v1.4.0 release, the Windows release ran on a Windows PC (5 commits pushed: `deploy.ps1` fixes, the Windows package, README links) while the Mac kept committing (4 commits: Cline docs, backlog, a logging fix). `git push` on the Mac was rejected: `main...origin/main [ahead 4, behind 5]`.

## 2. Diagnostic Traces & Evidence

```bash
git fetch origin && git status -sb          # ahead 4, behind 5
git log HEAD..origin/main                    # Windows release commits
git log origin/main..HEAD                    # Mac commits
comm -12 <(git diff --name-only $(git merge-base HEAD origin/main) HEAD | sort) \
         <(git diff --name-only $(git merge-base HEAD origin/main) origin/main | sort)   # empty: no shared files
```

## 3. Root Cause Analysis

The release flow is split by platform (macOS on the Mac, Windows on a PC), and both machines commit straight to `main`. Neither side fetched before starting, so each built on an old `main`.

## 4. Architectural Solution

Rebase the local commits onto `origin/main` (no shared files, so no conflicts), run `flutter analyze` and `flutter test` on the result, then push normally: never `--force`, which would have deleted the Windows release commits. Verified afterwards: README still UTF-8, both download links (macOS and Windows v1.4.0) return HTTP 200.

## 5. Prevention & Reusability Checklist

- [ ] `git pull --rebase` before starting work on either machine, and again before pushing.
- [ ] After a platform release on the other machine, pull before the next change.
- [ ] On a rejected push: fetch, list both sides, check for shared files, rebase, test, push. Never force-push `main`.
