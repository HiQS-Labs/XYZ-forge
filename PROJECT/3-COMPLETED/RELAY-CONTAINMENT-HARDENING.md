---
complexity: high
risk: high
effort: medium
ratings_provisional: false
title: "Relay containment-guard hardening — concurrent-commit safety + no agent self-commit"
status: Complete (3-COMPLETED)
created: 2026-06-23
updated: 2026-06-29
closed: 2026-06-29
owner: Noel (operator) · Claude (producer)
doc_type: bugfix
goal: >
  Harden the relay containment core (relay-automation/relay-turn-lib.sh) so a headless turn can't
  destroy work: (1) the commit-bypass guard must never orphan a CONCURRENT peer commit (GH-13), and
  (2) the turn agent must not self-commit mid-turn (GH-14). Both surfaced when a driven agy
  re-review orphaned a peer's commit on 2026-06-23.
---

# Relay containment-guard hardening

> Active build record for [issue #13](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/13)
> + [issue #14](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/14).
> Surfaced by the relay session reviewing `ARCHITECTURE.md` (2026-06-23); captured straight to
> `2-WORKING` (execution starting now), per `PROJECT/PDDA.md` → "GitHub issue intake".

## Status

| What was just completed | What's next |
|---|---|
| **#13 + #14 ROOT-CAUSE fixed (2026-06-29).** The GH-13 worktree-preserve branch was **dead code in the real shims**: `rtl_worktree_begin` runs in a `wt="$(…)"` subshell, so the `RTL_WT_USED=1` it set was LOST before `rtl_enforce` — so every codex/agy worktree turn whose ROOT `HEAD` moved hit the **in-ROOT reset + exit-6** path and **discarded the build** (the 2026-06-29 codex Phase-4 marathon, reproduced 2×). `relay-concurrent-commit.sh` (7/7) passed only because it drives the lib in-shell, never through a shim's subshell. **Fix:** `rtl_worktree_end` (runs in the caller's shell, always before `rtl_enforce`) re-asserts `RTL_WT_USED=1` → a moved ROOT HEAD during a worktree turn is **preserved** + the turn commits its allowlist on top. New **shim-level** regression in `test/worktree-isolation.sh` (test 4: concurrent ROOT commit mid worktree-turn → exit 0, peer preserved, allowlist copied back). Also **GH-42 stale-lock self-heal**: `marathon-drive`/`relay-drive` reclaim a dead-holder lock via a PID check instead of blocking forever (`test/driver-lock.sh` 4/4). **`validate.sh` 56/56.** | **✅ DONE + CLOSED 2026-06-29.** Confirmed end-to-end by **two independent marathons** — the GH-46 Phase-4 dogfood **and** the GH-37 dogfood (this session): codex/agy worktree turns with concurrent ROOT commits ran with **no reset+exit-6**. Fix is on `main` (`c992e68` + `939b871`); `validate.sh` 60/60. #13 + #14 closed. **Deferred optional follow-up (not blocking, low risk):** a prevent-level `git` PATH-shadow in the shims (block `commit`/`add`/`push`, pass reads) so a self-commit is *prevented*, not just absorbed — defense-in-depth on top of the shipped absorb-and-recover guarantee. Open a fresh issue if/when pursued. |

## Problem

`rtl_enforce`'s commit-bypass guard runs `git reset --hard <RTL_BEFORE_HEAD>` on **any** HEAD
movement during a turn, on the assumption that the only thing that can move HEAD is the turn agent's
forbidden commit. That assumption breaks with concurrent agents on one clone:

- **#13 (data-loss bug):** a peer agent's commit to ROOT during the turn is indistinguishable from
  the turn agent's, so the reset discards it. Worktree isolation does not help — the reset targets
  ROOT. Bit us twice (2026-06-23 `82f2db7`; a prior RECAP-commit incident in `snapshot.md`).
- **#14 (trigger):** the turn agent (agy) ran `git commit` itself, which is what tripped the guard.
  Reducing agent self-commits shrinks #13's blast radius.

## Plan

- **#13 — `rtl_enforce` (relay-turn-lib.sh):** before resetting, confirm the moved HEAD is exactly
  one commit whose parent is `RTL_BEFORE_HEAD` (the shape of "the agent added one commit"). If the
  movement doesn't match (multiple commits / different ancestor / peer commit), abort the turn loudly
  **without** `git reset --hard` so a human reconciles. Preserve current behavior for the genuine
  single-agent-commit case.
- **#14 — `rtl_turn_prompt` + shims:** explicit no-`git add/commit/push` contract in the prompt;
  evaluate a `git`-commit PATH-shadow during the turn (mirrors `claude-turn.sh` command-shadowing).
- **Tests:** `test/` cases for (a) a concurrent commit landing mid-turn → peer commit preserved,
  (b) an agent self-commit → contained without collateral. Keep the shim suites + `validate.sh` green.

## Verification

- `bash -n` clean on `relay-turn-lib.sh` + the new test.
- `test/relay-concurrent-commit.sh` **7/7**: (1) in-ROOT self-commit → exit 6 + reset (unchanged);
  (2) worktree turn + concurrent peer commit → exit 0, **peer commit preserved + reachable from HEAD**,
  turn commits the relay file on top.
- Full suite **`validate.sh` 38/38** (was 37; +1 new test) — existing shim commit-bypass tests
  (`agy/codex/claude-turn`) still green, so the in-ROOT path is unchanged.
- #14 prompt change is wording-only (no behavior/test impact); the enforcement-level shadow is the
  open follow-up.

### 2026-06-29 — root-cause completion (the prior fix was dead code in the shims)

- **Bug:** `RTL_WT_USED=1` was set inside `rtl_worktree_begin`'s `wt="$(…)"` subshell and lost, so
  `rtl_enforce` always read `RTL_WT_USED=0` for the command-substitution shims (codex/agy/claude) →
  the GH-13 "preserve a moved ROOT HEAD" branch never ran in real turns; a worktree builder whose ROOT
  HEAD moved was reset + exit-6, discarding the build (2026-06-29 codex Phase-4 marathon, ×2).
- **Fix:** persist `RTL_WT_USED=1` in `rtl_worktree_end` (runs in the caller's shell, always before
  `rtl_enforce`). One line; in-ROOT/attended path unchanged.
- **GH-42 stale-lock self-heal:** `marathon-drive` / `relay-drive` now write the holder PID into the
  lock and **reclaim it when the holder is dead** (`kill -0`), instead of a crashed driver leaving a
  stale lock that blocks every later run until a manual `rmdir`.
- **Tests:** `test/worktree-isolation.sh` +3 (shim-level concurrent-commit preserve) → 15/15;
  `test/driver-lock.sh` NEW (stale-reclaim + live-refuse) 4/4; **`validate.sh` 56/56**.
