---
gh_issue: 1251
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1251
title: "GH-522 slice 1: marathon planner fails closed on unknown preflight exits, missing dependencies and unplaceable lanes"
status: Active
created: 2026-10-29
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
goal: "Every planner outcome that is not a positive readiness signal holds the item with a named reason; nothing unknown, unresolved or unplaceable is packed into an active wave."
non_goals:
  - "#522's model spike, hourly monitor, plan-in-GitHub gate and automatic membership writes."
  - "The frozen Bash planner twin (GH-362); Python is authoritative."
related:
  - "Parent umbrella #522 (stays open; this slice Refs it)"
  - "Marathon umbrella #1250 (lane L4)"
  - "GH-1175 Phase 0 evidence: ledger fields admitted 5 issues that all failed live checks"
---

# GH-1251: marathon planner fails closed (GH-522 slice 1)

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L4) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (development 93f41cb8, `utils/py/_marathon_plan.py`)

1. **Deep delegation** (`:1021-1048`) maps preflight exits 4 to already-landed, 5 to not-ready, and 6/7 to blocked. Any other nonzero exit (1 from `OSError`, 2 usage, 3 invalid contract, 127, signals) leaves `state == "ready"`, so the item is waved.
2. **A dependency not in the ledger** (`:1052-1057`) gets only an info flag, `dep-not-found`. The dependent stays ready because the resolution loop skips a missing dep (`:1061`, `if not dep … continue`), and so does wave packing (`:1147`).
3. **The no-progress wave fallback** (`:1163-1168`): when nothing in `pending` can be placed, every deferred lane is appended as **one** wave, including lanes deferred for write-set collisions or zone caps.

Held states feed the exit code at `:1194-1203` (`held` → 5).

## Plan (one phase)

All changes are in `utils/py/_marathon_plan.py`:
1. **Deep delegation:** add `elif code == 3: state "needs-contract"` with the reason "swarm-preflight --dry-run → invalid contract (exit 3)". Then add `elif code != 0: state "preflight-error"` with a flag naming the code ("unknown/failed preflight exit N — hold; rerun swarm-preflight directly"). Add `"preflight-error"` to the `held` tuple (`:1196-1197`).
2. **Missing dependency:** in the resolution loop, treat a dep with no ledger row (`not dep`) as blocking. `blocked_by` includes it, so the dependent becomes `blocked-dep`. The existing `dep-not-found` flag keeps its message.
3. **No-progress fallback:** replace the packing at `:1163-1168` with holding. Each remaining deferred lane gets a new held state, `unplaceable`, with a flag ("could not be placed in any wave (collision / zone cap / unmet dependency) — hold, do not co-wave"). Then `break`. Add `"unplaceable"` to `held`.
4. **Rendering:** confirm the new state names render in the held/flags sections (they use the generic `_flag`). There is no new section.

**Phase 0 inside the lane** (record findings in this doc before building):
- grep the planner fixtures (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`) for scenarios hitting `dep-not-found` or the fallback;
- update any assertion that pins the old advisory behaviour, without adding a scenario (GH-831);
- if scenario T's Bash/Python parity diverges, follow the GH-698 precedent: keep the frozen twin and record the intentional divergence in the existing skip reason.

Write-set: `utils/py/_marathon_plan.py`, plus existing planner test files only where the Phase 0 grep shows an assertion pins old behaviour. Full route.

## Acceptance

- A deep-preflight exit other than 0, 4, 5, 6 or 7 (including 1, 2, 3, 127 and signals) holds the item with a named reason and planner exit 5 instead of leaving it ready.
- A dependency that is not in the ledger holds the dependent item (`blocked-dep`) instead of only warning.
- When no ready lane can be placed in a wave, the remaining lanes are held with a named reason instead of being packed together into one wave.
- Existing planner suites stay green, changed only where they pin the old advisory behaviour, and a manual smoke receipt under `TESTS-RESULTS/` shows each seam with a base red control; no new tests (GH-831).

## Verification

- **Existing suites:** `test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh308-frozen-twin-guard.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`, and the routed full gate, in a disposable full clone.
- **Manual smoke** (`TESTS-RESULTS/<date>+GH-1251/`): run `marathon_plan.py --dry-run --deep` against a fixture ledger with three cases, on the fix and at base `93f41cb8`:
  - a stub `SWARM_PREFLIGHT` exiting 2, then 3, then 127: held with a named reason and exit 5 on the fix; at base the item is waved;
  - a dependency on a missing issue: held on the fix; waved at base;
  - two ready items that depend on each other (a cycle), so neither can ever be placed first: held as `unplaceable` on the fix; co-waved in one wave at base.

Rollback: revert one commit. The planner returns to advisory behaviour.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {"type": "grep_absent", "path": "utils/py/_marathon_plan.py", "pattern": "preflight-error"},
    {"type": "grep_absent", "path": "utils/py/_marathon_plan.py", "pattern": "unplaceable"}
  ],
  "artifacts": ["utils/py/_marathon_plan.py"],
  "remediation": {"source": "issue#1251", "criteria": "Unknown deep-preflight exits hold (preflight-error), missing deps block, no-progress lanes hold (unplaceable); held feeds exit 5."},
  "lanes": {"agy_safe": ["utils/py/_marathon_plan.py"], "orchestrator_only": []}
}
```
