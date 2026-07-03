---
gh_issue: 41
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/41
title: task.done not terminal against a higher-epoch reclaim (silent token resurrection)
status: Shipped (2026-07-03 — Plan A lane 1, PR #99)
created: 2026-06-28
updated: 2026-07-03
doc_type: bugfix
complexity: 4
risk: 4
effort: 3
related:
  - PROJECT/3-COMPLETED/GH-40-DOUBLE-BLIND-REVIEWER.md
  - decisions/2026-07-02-terminality-seal.md
---

# GH-41 · `task.done` not terminal against a higher-epoch reclaim

> **UNBLOCKED 2026-07-02 — decision recorded + spike-validated.** A `/consult` (Codex + agy,
> GUIDING-PRINCIPLES as tie-breaker) **unanimously** chose **Option A (terminality-seal)** over
> Option B (`task.reopened` verb) — decided by GP #7 (least code), reinforced by #2 and #6. Recorded in
> [decisions/2026-07-02-terminality-seal.md](../../decisions/2026-07-02-terminality-seal.md). A
> throwaway **de-risking spike** prototyped the sealed fold and passed **7/7**: canary inverts to
> `done` + exactly 1 `claim-after-terminal` rejection; control stays clean; reorder-determinism holds;
> "owner can still finish" + "post-terminal zombie sealed" regression shapes pass. **Option B is
> deferred** (not built unless a concrete same-token reuse workflow justifies the new verb). This is now
> a single **orchestrator-only kernel lane** (edits the projection); build it serialized, never
> parallel.

**Latent kernel gap** found by GH-40 Phase 2 canary #1. In `src/project.js` `foldWithMeta`, a
completed task (`task.done`) is silently resurrected by a later `task.claimed` at a higher epoch on the
same token: status flips `done`→`claimed` with **0 rejections logged** — no fence fires, no audit
trace. The epoch fence stops *lower*-epoch zombie writers but has no guard against a *higher*-epoch
reclaim of a terminal token.

## Repro (deterministic, read-only)

`bash test/fixtures/canary-token-reuse/verify-fixture.sh` — mutated stream folds to `claimed 0`
(silent resurrection), control to `done 0`. The canary stream is a ready-made regression test.

## Proposed fix (from the GH-40 double-blind Reviewer)

Terminality dominates the fence: once a task has an authorized terminal, seal it — later claims/mutations
are rejected into the log (`claim-after-terminal`); a legitimate reopen must be an explicit, audit-logged
`task.reopened` event, never an implicit `task.claimed` after `task.done`.

## Reversibility

Changes projection/fold (event/verb) semantics → **at least Costly** per `AGENTS.md`. Needs a regression
test (canary stream ready) + a `decisions/` record before landing. Decision record **landed**
([decisions/2026-07-02-terminality-seal.md](../../decisions/2026-07-02-terminality-seal.md)); Easy to
revert (localized to `foldWithMeta` + the canary oracle; no new verb).

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). **Orchestrator-only
kernel lane** — edits the projection `foldWithMeta` in `src/project.js`; build serialized, never
parallel. Decision recorded (Option A) + spike-validated (7/7). Gate = the existing kernel suite (the
canary fixture is wired into `validate.sh`); the canary oracle **inverts** as part of the fix.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "src/project.js", "pattern": "claim-after-terminal" } ],
  "artifacts":   [ "src/project.js", "test/fixtures/canary-token-reuse/verify-fixture.sh" ],
  "remediation": { "source": "decisions/2026-07-02-terminality-seal.md", "criteria": "In src/project.js foldWithMeta, judge a terminal (task.done/circuit_break) as authorized against the owner AT THE TERMINAL'S ts (highest-epoch live claim with ts<=terminal.ts), not the global highest-epoch claim; once an authorized terminal exists, SEAL the token — every later task.claimed is rejected into rejections[] with the NEW distinct reason 'claim-after-terminal' (never a done->claimed flip). Update test/fixtures/canary-token-reuse/verify-fixture.sh so its oracle asserts the kernel now catches it (mutated -> done + 1 rejection). Keep the fold a pure function of the event set (reorder-determinism). No new verb (Option B deferred). validate.sh green — no epoch-fence regression. GH-41 marker comment." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "src/project.js" ] }
}
```
