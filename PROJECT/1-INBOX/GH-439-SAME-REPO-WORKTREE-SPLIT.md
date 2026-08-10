---
title: GH-11's foreign-repo split has no guard for a linked worktree of the same repo
status: Proposed (1-INBOX — not yet active)
created: 2026-08-07
owner: noel
gh_issue: 439
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/439
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 1e5eee4
non_goals:
  - Not changing GH-11's ROOT/target_root split — that design is correct and stays
  - Not touching relay-automation/marathon.sh — the orchestrator already handles this correctly
  - Not auto-setting MARATHON_ROOT by default; that changes documented behaviour (see Phase 0)
related:
  - GH-11 (defines --target-root as "the foreign repo the BUILD lands in") — CLOSED
  - GH-438 (separate marathon defect found in the same run)
goal: >
  When ROOT and --target-root are two checkouts of ONE repository, marathon-drive should say so
  — naming both branches — instead of silently committing the relay thread to one branch while
  the build lands on another. A warning is sufficient; refusing is acceptable.
---

# GH-439 — Same-repo worktree split has no guard

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

Driving a marathon phase directly with `--target-root <linked worktree>` and no `MARATHON_ROOT`
commits the relay thread and phase state to the **main checkout's** current branch while the
build lands on the **worktree's** branch. One logical unit of work, two branches of one
repository, no warning.

## This is a gap in an assumption, not a bug in the split

**GH-11's design is correct and is not being challenged.** `--target-root` is "the foreign git
repo the BUILD lands in", with the relay thread deliberately staying in `ROOT`
(`marathon-drive.sh:608, 643-644`). That is deliberate and should stay.

What GH-11 assumed is that `ROOT` and `target_root` are **different repositories**. With a
vendored `.xyz/`, `ROOT` defaults to the host repo itself (`marathon_drive.py:302-309` — if the
harness basename is `.xyz`, root is its parent). A linked worktree of that same repo therefore
produces one repository with two checkouts, which the design never contemplated.

Aggravating detail: `--target-root` is validated as though authoritative
(`marathon_drive.py:295-300`) and then does not root phase state (`:552`), so at the call site it
reads like a bug even though it is specified behaviour.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` — `source_commit=bd8451f`, `tick_version=0.2.0`)
- **Harness commit:** `1e5eee4`
- **Worker/CLI:** builder `codex`, reviewer `agy`
- **Runtime:** parity — `marathon-drive.sh:74-76, 679` mirrors `marathon_drive.py:302-309, 552`
- **Sandbox:** off

## Reproduction

1. In a repo with a vendored `.xyz/`, create a linked worktree: `git worktree add <wt> <branch>`.
2. From `<wt>`, invoke the driver directly with `--target-root "$PWD"` and **no** `MARATHON_ROOT`.

**Expected:** either the relay thread roots at the target, or the driver says the two roots are
one repository and names the branch each half would land on.
**Observed:** `marathon-drive: dry-run: relay file rendered at <main-checkout>/phases/<id>/RELAY.md`
— five phases rendered into the main checkout; in a non-dry run these are committed there
(`marathon_drive.py:1019, 1261-1267`).
**Frequency:** every time — deterministic.

## Not affected

`relay-automation/marathon.sh` is safe and needs no change: it sets `MARATHON_ROOT="$ROOT"` at
`:207,211` from `git -C "$PWD" rev-parse --show-toplevel` (`:54-58`), passes `--phases-dir`, and
never passes `--target-root`. **Only direct driver invocation hits this.**

## Impact

Low-moderate. Specified behaviour, a one-env-var mitigation, and the supported orchestrator is
unaffected. It earns a capture because the failure is **silent** and the end state is genuinely
confusing — half a unit of work committed onto an unrelated branch — and because worktree-per-issue
is a common workflow that makes this topology easy to reach.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist

- [ ] Confirm `git rev-parse --git-common-dir` is equal for a main checkout and its linked
      worktrees on the supported git versions, and unequal across genuinely separate clones
- [ ] Decide warn vs. die. Warning is the proposal; dying is defensible; **auto-setting
      `MARATHON_ROOT = target_root` changes documented GH-11 behaviour and needs its own call**
- [ ] Land it in both twins — this is parity, so a one-sided fix creates a divergence
- [ ] Check whether `relay-drive.sh` / `agy-turn.sh` / `codex-turn.sh` have the same blind spot
      when handed `RELAY_TARGET_ROOT` pointing at a sibling worktree
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0

- [ ] The repro is confirmed from the report, not assumed
- [ ] A regression test covers the failure path: same-repo worktree as `--target-root` produces
      the warning (negative control: a genuinely foreign repo must **not** warn — otherwise the
      guard fires on GH-11's intended use case and gets muted)
- [ ] The fix composes with the existing harness rather than adding a parallel root-resolution path
- [ ] `marathon.sh` remains untouched and its behaviour unchanged
