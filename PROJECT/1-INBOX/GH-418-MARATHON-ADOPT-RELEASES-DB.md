---
title: Marathon planner still reads the frozen ROADMAP.md — DB-parked items are invisible since the ROADMAP_SOURCE=releases flip
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 418
source: https://github.com/HiQS-Labs/XYZ-forge/issues/418
doc_type: bug
complexity: 2
risk: 3
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - Un-freezing or regenerating ROADMAP.md. It stays frozen; the planner moves to the DB.
  - Changing the executor. marathon.sh / marathon_drive.py consume a MARATHON.yaml and read neither source.
  - Retiring ROADMAP.md entirely — that is GH-269. This is the testable slice.
related:
  - GH-269 (full switchover to releases.db — this is its concrete first slice)
  - GH-169 / GH-238 / GH-239 (the flip itself, commit c97f6176, 2026-08-25)
  - GH-406 (umbrella — same class: a stated guarantee whose mechanism covers a narrower path)
goal: >
  Make the marathon planner read the ledger the repo actually designates as truth, so items parked
  through the documented `releases roadmap add` rail are plannable, and add the red control plus
  parity check that would have caught the divergence on day one.
---

# GH-418: the planner reads a file the repo froze

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## The finding, and the correction that produced it

An earlier claim in this arc — *"the marathon planner cannot see DB-parked items"* — was **too
broad and was corrected by measurement**. The planner is not blind in general: 69 of 106
`roadmap_items` rows are also in `ROADMAP.md`, and recent marathons used those. The precise defect
is narrower and worse.

`.pdda-mode` sets `ROADMAP_SOURCE=releases` (commit `c97f6176`, 2026-08-25) and states the DB is
the planning source of truth. `router_audit.py:597-660` enforces the same framing in prose:
*"ROADMAP.md is the frozen legacy file — do not read it for current state or edit it."*

`marathon_plan.py:126` reads `ROADMAP.md`. `git grep -c 'pdda-mode\|ROADMAP_SOURCE'` against
`marathon_plan.py` and `_marathon_plan.py` returns **0 in both**. The planner never learned about
the flip.

## Why nobody noticed

Two independent masks:

1. **The 69-item overlap.** Every marathon happened to use items present in both sources.
2. **The planner was not producing the work.** Every `MARATHON.yaml` on disk is hand-authored —
   `marathon_yaml_emit.py` has emitted none. GH-314 and GH-107 were marathoned while DB-only.
   The planner's one recommendation in the 08-27 → 09-01 window (`#123`) was cancelled, never built.

So "marathons work" and "the planner is stale" are both true and not in tension. The executor works
on hand-curated input; the planner that should remove that curation is wired to a frozen file.

## Proof it parses the stale file

`MARATHON-PLAN-2026-09-01.md` and `-09-02.md` surface `#349` and `#351`.
`select count(*) from roadmap_items where gh_number in (349,351)` → **0**. Those ids exist only in
`ROADMAP.md`. The planner could not have obtained them from the DB.

## Phases

1. **Source resolution.** Read `.pdda-mode` with the same resolver `releases_app.py` uses —
   releases-mode reads `roadmap_items`, legacy reads `ROADMAP.md`. Share the resolver; do not copy
   it. Keep `QUEUE_PLAN_ROADMAP` as a test-only override. Correct the generated header/footer,
   which currently hard-code *"Generated from ROADMAP.md (source of truth)"* — a false claim that
   is itself part of why this stayed invisible.
2. **Make it un-reintroducible.** Red control: an item parked only via `releases roadmap add` must
   appear in a fresh plan, and must fail against pre-fix code. Parity check: in releases-mode,
   fail if any shipped script reads `ROADMAP.md` for current state.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/_marathon_plan.py", "pattern": "ROADMAP_SOURCE" } ],
  "artifacts":   [
    "utils/py/marathon_plan.py",
    "utils/py/_marathon_plan.py",
    "test/gh418-planner-ledger-source.sh",
    "test/baselines/GH-418-negative-control.md"
  ],
  "remediation": { "source": "issue#418", "criteria": "in releases-mode the planner sources items from roadmap_items, legacy mode is unchanged, and the generated plan names its real source" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
