---
gh_issue: 56
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/56
title: marathon-drive — reconcile/fresh-id a leaked tick token before re-seed
status: Closed — Proposed (1-INBOX — not yet active)
created: 2026-07-02
doc_type: bug
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
related:
  - relay-automation/marathon-drive.sh
  - test/marathon-drive.sh
  - bin/tick
---

# GH-56 · marathon-drive: reconcile/fresh-id a leaked tick token before re-seed

**Why (reproduced live 2026-07-02):** the first GH-61 marathon run this session failed at seed time
with `tick: error: task MARATHON-P1-TURN is open — only the claiming agent can mutate it`. An aborted
prior run left an `open`/handed-off `MARATHON-<PHASE>-TURN` token in `.tick/` (gitignored, so it
survives `git reset`), and marathon-drive re-seeds the **same** default phase-id token
(`MARATHON-<PHASE_ID>-TURN`) → `task ... is open` / reuse refused. GH-43's pre-seed auto-reap only
covers a *claimed* stalled token, not an `open` handoff state. (Split from #51, defect 5 of 5.)

**Root cause:** `marathon-drive.sh` derives a deterministic token id from the phase-id and seeds it
unconditionally; there is no reconcile step for a leftover token in a non-claimed terminal/handoff
state before `task.created`.

**Fix direction (either is acceptable):**
1. Reconcile — before seeding, detect a leftover same-phase token and reap/terminate it
   (extending the GH-43 `tick reap --task` path to also close an `open` handoff), **or**
2. Fresh id — always derive a unique per-attempt token id (e.g. `MARATHON-<PHASE>-<short-uid>`), so a
   re-run never collides. (This is the manual workaround used this session: passing a fresh
   `--relay-task` per run.)

Additive/harness-level — `marathon-drive.sh` is **not** the containment kernel
(`relay-turn-lib.sh`/`bin/tick`/`relay-drive.sh`), so this is an independent lane. Bounded blast
radius (Easy to revert); the only care is not to reap a *live* claim (mirror GH-43's epoch-safe,
never-reap-a-live-claim guard).

## Acceptance
- [ ] Re-running the same phase-id after an aborted run seeds cleanly (no `task ... is open`) — either by reconciling/terminating the leftover `open`/handoff token before `task.created`, or by deriving a fresh per-attempt token id.
- [ ] A live claim of the same token is NEVER reaped (mirror GH-43's epoch-safe, never-reap-a-live-claim guard).
- [ ] The change carries a `GH-56` marker comment at the reconcile/fresh-id site in `relay-automation/marathon-drive.sh`.
- [ ] A regression case is added to `test/marathon-drive.sh` that reproduces the leaked-token collision (seed a token, leave it open/handed-off, re-seed the same phase-id) and asserts the clean re-seed; it fails without the fix and passes with it.
- [ ] `bash test/marathon-drive.sh` passes; no edit outside `relay-automation/marathon-drive.sh` + `test/marathon-drive.sh`.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`); the source + its test
both exist (a fix that extends them, not greenfield). Independent zone — `marathon-drive.sh` is not a
kernel path. Codex lane.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/marathon-drive.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "GH-56" } ],
  "artifacts":   [ "relay-automation/marathon-drive.sh", "test/marathon-drive.sh" ],
  "remediation": { "source": "GH-56#fix-direction", "criteria": "marathon-drive reconciles (reaps/terminates an open handoff) or fresh-ids a leftover same-phase MARATHON-<PHASE>-TURN token before re-seeding, so re-running a phase-id after an aborted run no longer fails with 'task ... is open'; a live claim is never reaped; regression case added to test/marathon-drive.sh; the change carries a GH-56 marker comment." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
