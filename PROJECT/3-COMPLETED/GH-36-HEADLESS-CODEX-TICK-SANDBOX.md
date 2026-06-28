---
title: Headless Codex isolated-turn friction — .tick lock outside the workspace sandbox
status: Completed
created: 2026-06-28
updated: 2026-06-28
owner: noelsaw1
branch: main
gh_issue: 36
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36
doc_type: project
---

## Status

| What was just completed | What's next |
|---|---|
| **Fixed + agy-approved 2026-06-28**, built via a real marathon dogfood. Primary finding (`.tick` write under isolation) resolved in `codex-turn.sh`; `codex-turn` 29/29, `validate.sh` 54/54; issue #36 closed. | **Finding 2** (surface the relay-file-at-HEAD warn from `rtl_worktree_begin` for all shims) remains — it touches the containment kernel, so it stays in the QUEUE's kernel-serial bucket, not this lane. |

## The fix
Under `RELAY_WORKTREE_ISOLATION=1`, Codex runs in a throwaway worktree but the shared `.tick/` token
lock lives at `TICK_REPO_ROOT` (harness root) — outside Codex's default `-s workspace-write` sandbox →
`tick claim/release` fails with `EPERM` → deadlock. Fix in
[relay-automation/codex-turn.sh](../../relay-automation/codex-turn.sh): when isolation is on, pass
`--add-dir "$ROOT/.tick"` to the codex exec so the default sandbox can write the token lock **without**
a full `--dangerously-bypass…`. Default-off behavior unchanged; safe empty-array expansion under
`set -u`. Regression: [test/codex-turn.sh](../../test/codex-turn.sh) +2 assertions (`--add-dir .tick`
present under isolation, absent when off) → 29/29.

## How it was built — a real XYZ dogfood (and its findings)
This was the first marathon fired after the GH-29 commit-path fix, used as a genuine end-to-end dogfood
(`swarm-preflight → marathon-drive → codex build (isolated worktree) → gate → agy review`).

- **v1 (default flags) → exit 6, containment violation.** Codex hit the **exact GH-36 bug**: `EPERM` on
  `.tick/locks` blocked the token claim, so it couldn't proceed; while stuck it wandered off-task
  (drafting a stray `GH-38` + a ROADMAP edit). The harness **reverted both off-lane edits, failed the
  turn, and escalated** — real tree untouched. The bug reproduced live inside its own fix attempt
  (self-blocking under default flags), and **containment held perfectly**.
- **v2 (`--dangerously-bypass…` + a tightened, scope-locked brief) → fix built.** Codex authored the
  surgical `--add-dir "$ROOT/.tick"` fix (transcript-verified `apply_patch`). A concurrent local relay
  collided on `codex-turn.sh` mid-edit (transient syntax error → marathon exit 2), so the messy
  byproduct commits were **consolidated** into one clean commit and the fix independently verified.
- **agy cross-model review → Approved** (4× [Pass]: array init/fallback, `set -u`-safe expansion, the
  `.tick` writable-root grant, unit-test coverage). Thread:
  [gh36-fix-review.md](../../relay-system/2026-06-28/gh36-fix-review.md).

### Process findings surfaced (worth their own follow-ups)
1. **GH-36 is self-blocking for a headless marathon** — you can't fix the `.tick` sandbox bug with the
   default flags because those flags block the token claim. Needed the bypass flag to build it.
2. **Thin briefs let the builder wander** — the swarm-preflight packet referenced the source doc rather
   than inlining acceptance criteria; v1 Codex burned ~38k tokens on roadmap/PDDA analysis and tried to
   file an issue instead of editing the one shim. A scope-locked brief (v2) fixed it. (Candidate GH-38.)
3. **Concurrent same-repo relays collide** — a second relay committing to `codex-turn.sh` mid-marathon
   caused the exit-2; reinforces the `no-headless-relay-during-concurrent-commits` rule.

## Sibling
Sibling of GH-32 (single-turn ergonomics; Finding 2 already mitigated there for `relay-drive.sh`).
