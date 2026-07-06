---
gh_issue: 140
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/140
title: "Containment: rtl_worktree_end's non-atomic cp -R can corrupt a live-executing marathon-drive.sh/relay-drive.sh, wiping the repo"
status: "Shipped (`f64a051`)"
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: bugfix
goal: >
  Make rtl_worktree_end's artifact copyback atomic so a lane whose own artifacts include the
  actively-executing marathon-drive.sh/relay-drive.sh can never corrupt the live interpreter
  mid-script -- without changing copyback semantics for any other caller.
complexity: 2
risk: 3
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - Not a change to WHICH paths get copied back (the allowlist/off-lane logic is untouched) -- only
    HOW an existing destination file is replaced.
  - Not a fix for the separate concurrent-peer-edit race found immediately afterward while reviewing
    this fix (a live session hand-editing an off-allowlist path mid-turn) -- that is GH-141, a
    structurally different hazard, filed separately and deliberately not bundled here.
related:
  - relay-automation/relay-turn-lib.sh
  - utils/telemetry/append-xyz-completion.sh
  - test/worktree-isolation.sh
  - test/shim-worktree.sh
  - test/agy-turn.sh
  - PROJECT/3-COMPLETED/GH-96-XYZ-JSON-EMIT-CONTRACT-HEARTBEAT.md
---

## Status

| What was just completed | What's next |
|---|---|
| **Shipped 2026-07-05 (`f64a051`)**, fixed directly (kernel zone — same Opus-direct convention as other `relay-turn-lib.sh` changes, not a marathon-built lane). Found while dogfooding the GH-96 Seam #1 marathon: the first build attempt built+approved cleanly (codex → agy Approved, 2 turns) but `marathon-drive.sh` itself then crashed with a garbled `syntax error` immediately after relay-approval, and the repo's local working tree + `.git` internals were wiped down to a handful of surviving dot-directories (`origin/main` completely unaffected — confirmed via `git ls-remote`, recovered by re-cloning). Regression: `test/worktree-isolation.sh` 31/31, `test/shim-worktree.sh` 32/32, `test/agy-turn.sh` 27/27, full `validate.sh` green. Re-fired the identical GH-96 lane on a temp branch with close, active monitoring — completed cleanly end-to-end (no crash, no repeat of the wipe), confirming the fix. Independently reviewed via `/relay-xyz` with agy afterward (thread `relay-system/2026-07-05/gh-96-seam-1-gh-140-containment-fix-review.md`) — **Approved**, 2 `[Pass]` findings specifically on this fix (atomic-copyback mechanism, file-vs-directory branch and symlink handling). | Nothing outstanding. The concurrent-peer-edit race found while reviewing this fix is tracked separately as **#141** (not built here, by design). |

## Problem (grounded in the current code)

`relay-turn-lib.sh`'s `rtl_worktree_end()` copies each allowlisted artifact back from a turn's
isolated worktree into the main repo root (`$RTL_ROOT`) via a **non-atomic, in-place** `cp -R`:

```bash
if [[ -e "$wt/$a" ]]; then
  mkdir -p "$RTL_ROOT/$(dirname "$a")"
  cp -R "$wt/$a" "$RTL_ROOT/$a"
```

`cp` (without `--remove-destination`) truncates and rewrites an existing destination file's bytes
**in place, at the same inode** — it does not unlink+recreate. When the artifact being copied back
is a script that is *itself currently executing* — here, `marathon-drive.sh`, the live outer driver,
and `relay-drive.sh`, its live subprocess, both legitimate copyback targets for a GH-96 Seam
#1-style lane that wires new hooks into them — the running bash interpreter, which reads a script
incrementally off disk rather than fully buffering it upfront, can read a mix of old and new bytes
once the file underneath it is rewritten mid-execution. This produced exactly the observed
"syntax error near unexpected token" symptom, and in the worst realization a garbled parse (e.g. a
heredoc/quote boundary shifted by the old/new size delta) executed bytes that were never meant to
run as a command — plausibly the destructive sequence that wiped the working tree here.

This is a narrow but real hazard class: any marathon/relay lane whose `--artifact` list includes
`relay-automation/marathon-drive.sh` or `relay-automation/relay-drive.sh` themselves risks this
self-modification corruption. Other harness scripts (e.g. `swarm-preflight.sh`) are not at risk
today since nothing sources/execs them live while they are simultaneously an editable artifact in
the same run.

## Fix

Make the copyback atomic: write to a temp path beside the destination (`$RTL_ROOT/$(dirname
"$a")/.rtl-copyback.$$.$(basename "$a")`), then atomically rename it into place — the same
`os.replace()` pattern `utils/telemetry/append-xyz-completion.sh` already uses for the identical
reason. A process with an existing open fd on the old `$RTL_ROOT/$a` keeps reading the old inode's
bytes until it closes; it never observes a half-written script.

Files and directories need different handling since `rename(2)` can atomically clobber an existing
**file** destination directly, but cannot atomically replace a non-empty **directory**:

- **Regular file / symlink:** `mv -f "$_tmp" "$RTL_ROOT/$a"` — one atomic rename, no window where
  the path is missing.
- **Directory:** `rm -rf "$RTL_ROOT/$a"` then `mv "$_tmp" "$RTL_ROOT/$a"` — a narrow window where
  the path doesn't exist, acceptable since no live process reads a directory as an executing script.

## Definition of done

- [x] `rtl_worktree_end()`'s copyback writes to a temp path beside the destination, then atomically
      renames into place, instead of an in-place `cp -R`.
- [x] File/symlink and directory destinations handled correctly (file: direct atomic `mv -f`;
      directory: `rm -rf` + `mv`, since `rename(2)` can't clobber a non-empty directory).
- [x] `test/worktree-isolation.sh` 31/31 (no regression to existing copyback/off-lane behavior).
- [x] `test/shim-worktree.sh` 32/32.
- [x] `test/agy-turn.sh` 27/27.
- [x] `bash validate.sh` green.
- [x] Live-fire confirmation: the exact GH-96 Seam #1 lane that originally hit this bug (artifacts
      including `marathon-drive.sh`/`relay-drive.sh` themselves) re-ran end-to-end post-fix with no
      crash and no repeat of the wipe.
- [x] Independent review (`/relay-xyz` with agy): Approved, no findings against this fix.

## Reversibility & blast radius

**Higher than usual — this is the containment kernel.** `relay-turn-lib.sh` is sourced by every
turn-taker shim; a mistake here is repo-wide, not lane-scoped. The change is narrowly scoped to
*how* an existing destination is replaced (mechanism only) — it does not change *which* paths get
copied back, the allowlist, or the off-lane detection logic at all, which keeps the actual blast
radius small despite the file's sensitivity. Fixed directly (not via a marathon-built lane) given
the severity and kernel location, same convention as other direct `relay-turn-lib.sh` fixes.

## Provenance

Found live while dogfooding [GH-96 Seam #1](GH-96-XYZ-JSON-EMIT-CONTRACT-HEARTBEAT.md)'s marathon
build — the first attempt built and was approved cleanly, then the outer driver crashed and the
local repo's working tree + `.git` internals were wiped (origin unaffected; recovered via re-clone,
zero remote data lost). Root-caused by reading `rtl_worktree_end()` directly rather than guessing.
Reviewing this fix itself (via `/relay-xyz` with agy) surfaced a second, structurally different
containment hazard — a concurrent peer session's uncommitted edit landing mid-turn getting wrongly
reverted as off-lane — filed separately as **#141**, deliberately not fixed here.
