---
complexity: high
risk: high
effort: medium
ratings_provisional: true
title: "Relay containment-guard hardening — concurrent-commit safety + no agent self-commit"
status: Active
created: 2026-06-23
updated: 2026-06-23
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
| **#13 fixed + tested.** `rtl_enforce`'s commit-bypass guard is now **worktree-aware** (`relay-turn-lib.sh`): `rtl_worktree_begin` sets `RTL_WT_USED=1`, and when a worktree-isolated turn (the default driven path) sees ROOT `HEAD` moved, the agent provably can't have caused it — so it's a **concurrent peer commit, preserved** (not `reset --hard`'d), and the turn commits on top. In-ROOT/attended behavior is byte-for-byte unchanged (HEAD move → reset + exit 6). New `test/relay-concurrent-commit.sh` (7/7) proves both; **`validate.sh` 38/38**. **#14 partial:** `rtl_turn_prompt` now emphatically forbids agent self-commit ("NEVER run git yourself … a self-commit FAILS your whole turn"). | **#14 enforcement-level:** a `git` PATH-shadow/wrapper in the shims that blocks `commit`/`add`/`push`/`reset` (passes reads through) so a self-commit is *prevented*, not just discouraged + caught. **Optional (#13 residual):** the in-ROOT (attended, non-default) path still resets on any HEAD move — a concurrent peer commit there would be reset (low risk; the driven path is isolated). Commit + push. |

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
