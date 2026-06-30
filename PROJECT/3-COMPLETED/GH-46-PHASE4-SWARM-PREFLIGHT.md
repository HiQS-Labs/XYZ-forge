---
title: Phase 4 swarm-preflight contract + cross-model hands-free marathon dogfood
status: Complete (3-COMPLETED)
created: 2026-06-28
updated: 2026-06-29
closed: 2026-06-29
owner: noelsaw1
branch: main
gh_issue: 46
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/46
parent_issue: 33
doc_type: project
complexity: high
risk: high
effort: high
ratings_provisional: true
goal: >
  Hold the AUTHORITATIVE Phase 4 swarm-preflight contract (unify Path A/B so cross-model relay turns
  advance unattended) and drive its marathon dogfood. Split out of #33 so the runnable contract gets
  its own issue number and attention instead of being buried in the 6-phase epic.
---

## Status

| What was just completed | What's next |
|---|---|
| **✅ Phase 4 SHIPPED 2026-06-29 via the marathon dogfood** (codex builder, agy reviewer). After 2 runs failed at the #14 codex-self-commit reset, the #14 fix landed and the 3rd run succeeded: codex built `relay-loop.sh --background --cross-model-cmd` (cross-model shim dispatch on `nudge-cross-model`, degrade-to-nudge fallback, pidfile single-turn lock) + 4 `test/relay-loop.sh` cases; agy approved. End-to-end #14 confirmation. `validate.sh` 56/56 (the marathon's gate-fail was a non-hermetic `driver-lock.sh` test, fixed). | **✅ CLOSED 2026-06-29.** #46 reconciled to `3-COMPLETED`; all acceptance criteria verified delivered (README row, `--cross-model-cmd` impl, 4 test cases, `validate.sh` green). Optional follow-ups live in #33 (Phase 5 lifecycle / Phase 6 docs) — not required for the cross-model-hands-free win, which is done. |

## Why this doc exists (relationship to #33)

- **#33 / [GH-33-LOOP-SKILL-INTEGRATION.md](GH-33-LOOP-SKILL-INTEGRATION.md)** owns the Phase 4 *design*
  and the full phase ledger (Phases 0–6). It stays the place to read *why* and *how* Phase 4 fits the
  Path A/B unification.
- **This doc / #46** owns the *runnable* Phase 4 preflight contract + the marathon dogfood that lands
  it. The contract lives here so `swarm-preflight --gh-issue 46` (or `--project-doc` on this file) is
  executable, and so the execution work is tracked under its own issue number rather than getting lost
  inside the epic.

If the scope below ever drifts from GH-33's Phase 4 section, **this doc wins for execution** and GH-33's
section should be reconciled to match (it carries only a pointer now, not a second contract copy).

## Asks (acceptance criteria) — ✅ all delivered (verified 2026-06-29)

- [x] `swarm-preflight --gh-issue 46` reaches `ready` (or `BLOCKED` only on a dirty tree), never `contract missing/invalid`.
- [x] `relay-loop.sh --background --cross-model-cmd …` dispatches the cross-model shim on `DECISION: nudge-cross-model`; the pidfile single-turn lock holds (no double-dispatch).
- [x] Cross-model CLI absent → degrades to the existing human nudge, no dispatch (never a silent stall); `--claude-agents` semantics preserved.
- [x] Containment + token correctness identical to Path A: `relay-turn-lib.sh` untouched, no widened allowlist, no orphaned cross-repo commit (GH-29 hazard). `poll.sh` stays a pure oracle. `relay-drive.sh` (deterministic mode) unchanged.
- [x] `test/relay-loop.sh` extended: (a) `nudge-cross-model` + `--background` + `--cross-model-cmd` → BG-DISPATCH of the shim, single-dispatch lock holds; (b) cross-model CLI absent → degrades to nudge, no dispatch. (4 `--cross-model-cmd` cases present.)
- [x] `relay-automation/README.md` row updated; `bash validate.sh` green.

## Swarm Preflight Contract

> **Active target: Phase 4** (unify Path A/B — cross-model turns advance unattended).
> Phase 3 (background dispatch) shipped 2026-06-28; its probes now read `already-landed`. This contract
> supersedes it for the next fire (the marathon dogfood). Authoritative copy — see #33 for design context.

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-loop.sh", "pattern": "cross-model-cmd", "note": "Phase 4 adds a --cross-model-cmd flag so --background launches the cross-model shim on nudge-cross-model; the flag is absent today → fix still required" },
    { "type": "grep_absent", "path": "test/relay-loop.sh", "pattern": "cross-model-cmd", "note": "Phase 4 adds a --cross-model-cmd background-dispatch test case; absent today → fix still required" }
  ],
  "artifacts": [
    "relay-automation/relay-loop.sh",
    "relay-automation/poll.sh",
    "test/relay-loop.sh",
    "relay-automation/README.md"
  ],
  "remediation": "Unify Path A/B in relay-loop.sh --background: on DECISION: nudge-cross-model, launch the cross-model turn shim (codex-turn.sh / agy-turn.sh) as a DETACHED background process — reuse the Phase 3 bg_launch + pidfile single-turn lock — instead of printing a human nudge, so a Codex/agy turn advances unattended. Add a --cross-model-cmd flag (mirror --runner-cmd) for the command to run for a cross-model turn; if it is unset OR the agent's CLI is not on PATH, DEGRADE to the existing human-nudge (never a silent stall) — preserve --claude-agents semantics. Containment + token correctness MUST be identical to Path A: do NOT modify relay-turn-lib.sh, do NOT widen any allowlist (the backgrounded shim already enforces the boundary). Keep poll.sh a pure oracle. Extend test/relay-loop.sh with: (a) nudge-cross-model + --background + --cross-model-cmd -> BG-DISPATCH of the shim, single-dispatch lock holds; (b) cross-model CLI absent -> degrades to nudge, no dispatch. Update the relay-loop.sh README row. SCOPE LOCK: edit ONLY the four artifacts; verify with `bash test/relay-loop.sh` ONLY — do NOT run the full validate.sh yourself (it can create files that trip containment and discard your whole turn); the harness runs the gate after your turn.",
  "lanes": {
    "orchestrator_only": ["relay-automation/relay-loop.sh", "relay-automation/poll.sh"],
    "note": "supervisor zone — serialize; one kernel lane per wave. relay-turn-lib.sh / bin/tick are OUT of scope (containment must stay byte-identical)."
  }
}
```

## Pointers

- Parent design / phase ledger: #33 → [GH-33-LOOP-SKILL-INTEGRATION.md](GH-33-LOOP-SKILL-INTEGRATION.md) (Phase 4 + QA checklist).
- Planner: [utils/swarm-preflight.sh](../../utils/swarm-preflight.sh) — `swarm-preflight --gh-issue 46`.
- Executor: [relay-automation/marathon-drive.sh](../../relay-automation/marathon-drive.sh) (fired by the operator from the emitted packet).
