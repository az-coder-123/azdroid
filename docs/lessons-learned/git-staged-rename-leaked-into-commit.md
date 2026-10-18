# Staged Rename Leaked Into an Unrelated Commit

## 1. Context & Symptoms

A large refactor was split into four commits (`fix`, `refactor`, `chore(lint)`, `docs`). The first commit was created with an explicit file list:

```bash
git add <4 aapt files> && git commit
```

The final tree was correct, but checking out the first commit alone produced **200 analyzer errors**, all `uri_does_not_exist` for `features/discovery/domain/entities/device_entity.dart`.

## 2. Diagnostic Traces & Evidence

- Earlier in the session the entity was moved with `git mv`, which **stages the rename immediately**.
- `git add <paths>` adds to the index; it does not clear what is already staged.
- The first commit therefore contained the rename, while the importers were updated only in the second commit.
- The problem was found by analyzing each commit in a throwaway worktree:

```bash
git worktree add /tmp/wt-<sha> <sha> && (cd /tmp/wt-<sha> && flutter pub get && flutter analyze)
git worktree remove --force /tmp/wt-<sha>
```

## 3. Root Cause Analysis

The commit was assumed to contain only the files named in `git add`. In fact, a commit always contains **the whole index**. Commands that stage as a side effect (`git mv`, `git rm`, `git add -A` in an earlier step) leave entries behind.

## 4. Architectural Solution

The branch had not been pushed yet, so it was rebuilt safely:

1. Save the final commit SHA.
2. `git reset --mixed <base>` to keep the working tree and clear the index.
3. Re-create each commit from a clean index, checking `git diff --cached --name-status` before every commit.
4. Confirm `git diff <saved-sha> HEAD` is empty.
5. Analyze every intermediate commit in a worktree before pushing.

**Recurrence (screen-off change):** `git mv` moved `scrcpy_control_message.dart` to `core` early in the work. The first commit of the split series staged only the channel files by path, but the earlier renames were already in the index and went along (shown as `0` lines in `--stat`, easy to miss). The commit would not have compiled. It was caught before pushing because `--stat` was printed, then redone from a clean index (`git reset --soft <base> && git reset`) and every commit was tested in a worktree.

## 5. Prevention & Reusability Checklist

- [ ] Run `git diff --cached --name-status` before every commit in a split series; a rename with 0 changed lines still changes the build.
- [ ] Start a split series from an empty index (`git reset`), because `git mv` stages immediately.
- [ ] Prefer a plain `mv` + `git add` at commit time over `git mv` during exploratory work.
- [ ] Before pushing a split series, analyze (and ideally test) every commit, not only `HEAD`.
- [ ] Rewrite history only while the branch is unpushed.
