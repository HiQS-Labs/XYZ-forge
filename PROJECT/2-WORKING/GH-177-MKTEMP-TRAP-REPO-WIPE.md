---
gh_issue: 177
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177
title: "CRITICAL: test/hq-hardening.sh (+2 siblings) rm -rf'd the entire repo when mktemp -d failed under sandbox"
status: "reopened 2026-07-17 — recurrence, original fix never landed"
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: bugfix
complexity: 1
risk: 3
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a general audit of every temp-file/trap pattern in the repo — scoped to the
    mktemp-into-destructive-EXIT-trap shape that has now bitten twice
  - Not changing how validate.sh's sandbox interacts with mktemp itself (e.g. forcing
    TMPDIR) — the fix is to make the test scripts fail loud instead of silently
    resolving to the repo root, not to make mktemp succeed under every sandbox
related:
  - WORKTREE-SAFETY.md
  - test/hq-hardening.sh
  - test/hq-promote.sh
  - test/hq-locator.sh
  - test/mktemp-trap-guard.sh
  - test/marathon-root-audit.sh
  - validate.sh
goal: >
  Apply the guard the original GH-177 report already specified (mktemp exit-status +
  non-empty + is-directory check before any $TMP is wired into a destructive EXIT trap)
  to all 3 affected files, and add a permanent static-audit regression test so the same
  or an equivalent unguarded pattern fails validate.sh before it can ever delete a repo
  again.
roadmap_exempt: false
---

# GH-177 · mktemp-into-destructive-trap repo wipe (recurrence)

## Status

| What was just completed | What's next |
|---|---|
| Fixed all 3 files (guarded exit-status + non-empty + is-directory check before the destructive `EXIT` trap). Added `test/mktemp-trap-guard.sh`, wired into `validate.sh`. Verified with disposable scratch files that it fails on both the inline (`cd "$(mktemp ...)"`) and split-line (`X="$(mktemp -d)"` then `X="$(cd "$X" && pwd)"`) shapes of the bug, and passes clean (191 files, 0 findings) against the fixed repo. | Land this on `development` via a normal commit; no further action needed unless a future script reintroduces the pattern, in which case `validate.sh` now fails loud instead of deleting anything. |

## What happened (2nd occurrence)

**First occurrence (2026-07-07, GH-177 filed):** running `test/hq-hardening.sh` under a sandboxed
shell destroyed the primary checkout. Root cause fully diagnosed in the issue body (see below).
Issue was closed 2026-07-08 — but the code was never actually patched, only documented.

**Second occurrence (2026-07-17):** `validate.sh` (which runs `test/hq-hardening.sh` as part of its
suite) was executed via a sandboxed Claude Code `Bash` tool call (no `dangerouslyDisableSandbox`)
during an unrelated `/front-door` onboarding audit. Same trigger, same mechanism, same damage
signature: working tree wiped down to `.claude/`, `.git/`, `.pytest_cache/`, `.vscode/`; `.git`
itself missing `HEAD`/`objects`/`refs`/`index` while `hooks/`, `worktrees/`, `config` survived
(the sandbox's own permission rules happened to protect those specific paths from the `rm -rf`,
both times).

Recovered without data loss: `git init` (safe re-run, fills in missing skeleton only) → `git fetch
origin` (additive) → `git read-tree origin/development` + diff-before-touching-anything → `git
checkout-index -a -f` to materialize the 19 tracked files that differed → branch ref rewired to
`origin/development` (`4fb2746`) → `git fsck` clean → stale `.git/worktrees/marathon-e-build` stub
pruned. A parallel Time Machine restore recovered the working-tree files by the time the git-level
recovery ran; a handful of stray untracked pre-move duplicates from that restore were deleted after
confirming their canonical, tracked versions were intact elsewhere.

A concurrent theory (that a different repo's, LTVera-Pandas's, Codex relay-turn session on a vendored
`.xyz/` install had somehow reached into this repo) was investigated and **ruled out**: the XYZ
install registry correctly scopes LTVera-Pandas's `TICK_REPO_ROOT` to its own path, its vendored
`bin/tick` is a real file (not a symlink back to this repo), and the other session's own root cause
(`find-harness.sh --env` exporting `TICK_REPO_ROOT` one directory too deep, at `.xyz/` instead of the
git top level) never referenced this repo's path at all. That's a real, separate bug worth its own
issue in this repo (affects every vendored `.xyz` install), not filed yet.

## Root cause (unchanged from the original report — never fixed)

`test/hq-hardening.sh`, `test/hq-promote.sh`, and `test/hq-locator.sh` all set up their scratch dir
identically:

```bash
TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
```

Under a sandboxed shell, bare `mktemp -d` (no `-p "$TMPDIR"`) tries to create a directory under the
system default temp root, which the sandbox doesn't allow. `mktemp` fails and prints to stderr, but
returns **empty stdout**. `cd ""` then **succeeds** in bash (it does not error) and simply leaves the
working directory unchanged — so `TMP` silently becomes wherever the script was invoked from (the
repo root), not a scratch dir. The `trap 'rm -rf "$TMP"' EXIT` then deletes that directory — the
entire repository — when the script exits. No line anywhere checks that `mktemp` succeeded, that
`$TMP` is non-empty, or that `$TMP` isn't the repo root/`$HOME`/`/` before it's wired into a
destructive `EXIT` trap.

## Fix

1. Replace the unguarded one-liner in all 3 files with an explicit exit-status + non-empty +
   is-directory check before the `trap` is installed, and only canonicalize (`cd "$TMP" && pwd -P`,
   for the macOS `/tmp` → `/private/tmp` symlink case) as a **second** step, after `$TMP` is already
   verified real — exactly as the original issue's "Recommended fix" specifies.
2. Add `test/mktemp-trap-guard.sh` — a static-audit test (same style as
   `test/marathon-root-audit.sh`) that scans every `.sh` file under `test/`, `utils/`,
   `relay-automation/`, `skills/`, `bin/` for (a) the exact historical idiom
   (`cd "$(mktemp` anywhere), which is unsafe by shape regardless of what follows, and (b) the more
   general pattern of a `mktemp`-derived variable reaching a destructive `rm -rf "$VAR"` (especially
   inside an `EXIT` trap) without an intervening non-empty/is-directory guard. Either match fails the
   test. Wired into `validate.sh` so it runs on every future invocation.

## QA gate

- [x] All 3 files use the guarded pattern (exit-status + non-empty + is-directory check, trap
      installed only after, canonicalize as a separate step afterward).
- [x] `test/mktemp-trap-guard.sh` exists, is added to `validate.sh`'s `TESTS` array, and — verified
      against disposable scratch files reconstructing both the inline and split-line shapes of the
      bug — actually fails on the historical pattern (not just passes trivially on a clean tree).
- [x] `test/mktemp-trap-guard.sh` passes cleanly against the fixed repo (191 `.sh` files audited, 0
      findings).
