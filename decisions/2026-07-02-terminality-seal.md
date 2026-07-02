---
title: Seal an authorized terminal — a task.done/circuit_break makes the token terminal; later claims are rejected (GH-41)
date: 2026-07-02
status: Decided
gh_issue: 41
related:
  - src/project.js                                   # foldWithMeta — terminal-selection + epoch fence
  - src/events.js                                    # event/verb vocabulary
  - test/fixtures/canary-token-reuse/verify-fixture.sh  # the read-only repro (oracle inverts on fix)
  - decisions/2026-06-18-epoch-fencing.md            # the prior fence this seals on top of
  - relay-system/2026-07-02/gh41-terminality-160149/ # the cross-model consult that decided it
---

# Seal an authorized terminal (GH-41)

**Decision — ship Option A (terminality-seal); defer Option B (`task.reopened`).**
In the projection kernel (`src/project.js` `foldWithMeta`), once a task has an **authorized terminal**
event (`task.done`/`task.circuit_break` emitted by the agent that was the legitimate owner at the
moment it was emitted), the token is **sealed**: any *later* `task.claimed` (or other mutation) on that
token — higher OR lower epoch — is **rejected** into `rejected.jsonl` with a new distinct reason
`claim-after-terminal`, never applied as a `done → claimed` status flip. Rework of a completed unit of
work uses a **fresh task id**, not the sealed token. No new verb is added.

**Option B (`task.reopened`) is explicitly deferred** — not built unless a concrete same-token reuse
workflow ever proves it worth a net-new verb + its replay/authorization semantics.

## The problem it solves (reproduced, read-only)

`src/project.js` elects the owner as the highest-epoch live claim, then authorizes terminals only from
that owner. So a *later, higher-epoch* `task.claimed` becomes the owner and the earlier authorized
`task.done` is no longer "authorized" — yet it isn't rejected either, because the stale-write guard
only logs mutations that land *after* the winner's claim ts. Net: `done → claimed`, **0 rejections, no
audit trace**. A terminal state is not terminal. Repro: `test/fixtures/canary-token-reuse/verify-fixture.sh`
(mutated stream folds to `claimed 0`; should be `done` + 1 rejection). Verified live in the consult by
folding the fixture (`status: claimed, rejections: []`).

## Why A, not B (decided by GUIDING-PRINCIPLES)

Cross-model `/consult` (Codex `gpt-5.4` + agy), GUIDING-PRINCIPLES as the tie-breaker, reached this
**unanimously** (transcripts in `relay-system/2026-07-02/gh41-terminality-160149/`):

- **#7 Least code that clears the bar** (the deciding principle) — A is a fold change with **zero**
  schema/verb additions; B adds a net-new `task.reopened` verb + authorization + replay-ordering
  surface for no proven gain.
- **#2 One canonical event log; projection is a pure function** — reusing a task id for a second unit
  of work merges two lifecycles into one event sequence, corrupting audit/metrics. A keeps one token =
  one lifecycle.
- **#6 Build durable, not band-aid** — A removes the root cause (terminal tokens stop being implicitly
  reusable); it is not a patch to be torn out.

Both advisors also flagged that the operator's "A vs B" was slightly misframed: **A is the fix; B is an
optional future feature**, not a peer alternative.

## Acceptance criteria (what the implementing lane must prove)

1. **Canary inverts:** `test/fixtures/canary-token-reuse/verify-fixture.sh` — mutated stream now folds
   to `status: done` **+ exactly one rejection** with reason `claim-after-terminal` (control stays
   `done`, 0). The canary's oracle is updated to assert the kernel now catches it (the canary was
   authored to fail once the kernel does — retire/invert it, don't leave it asserting the bug).
2. **No regression:** `validate.sh` green — especially the stale-writer cases (same-id reclaim
   *before* a terminal still works; the current owner can still finish; lower-epoch zombies still
   fenced as `stale-epoch`/`non-owner-agent`).
3. **Replay-determinism:** the same event set in any arrival order → identical projection AND identical
   `rejected.jsonl` (the fold stays a pure function of the event set).

## Contract details pinned

- **Rejection reason:** `claim-after-terminal` is a **new, distinct** reason — NOT folded into
  `stale-epoch`/`non-owner-agent` (those are ownership/epoch failures; this is a lifecycle violation).
  This is an additive `rejected.jsonl` audit-contract change.
- **"Authorized terminal" means** the terminal was emitted by the owner-at-terminal-time (the highest
  epoch claim up to that terminal's ts), not the global highest-epoch claim — fixing the root
  mis-selection. (agy's implementation nit: a single chronological pass that tracks owner + seal is
  cleaner than the current filter-and-reconcile and avoids retroactive-invalidation.)

## Reversibility

Costly (kernel projection + audit-contract change) but **Easy to revert** (localized to `foldWithMeta`
+ the canary oracle; no new verb, no schema migration). Behavior change is strictly *additive
rejections* — it never silently changes a currently-`done` task to anything but `done`.

## If Option B is ever revisited (parked, not decided)

The `decisions/` follow-up would need to pin: (a) authorization — narrowest enforceable rule is "only
the last authorized terminal owner may emit `task.reopened`, minting the next epoch" (agy would also
allow an explicit admin actor); (b) reason taxonomy — reuse the distinct-reason discipline;
(c) replay-determinism — a `task.reopened` needs an explicit causal anchor (`reopens_epoch` / terminal
reference) so a reopen that sorts *before* its terminal still folds deterministically (Codex),
rather than an arrival-order-sensitive "reject reopen-active-task" rule (agy).
