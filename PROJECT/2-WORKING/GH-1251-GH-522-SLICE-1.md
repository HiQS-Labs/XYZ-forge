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
3. **The no-progress wave fallback** (`:1163-1168`): when nothing in `pending` can be placed, every deferred lane is appended as **one** wave. The demonstrated triggers are a ready dependency cycle (resolution allows ready deps at `:1061`, but neither is in `placed_issue` at packing, `:1145-1151`) and a zero zone cap. Ordinary collisions and positive caps do not trigger it, because the first lane always enters an empty wave.

Held states feed the exit code at `:1194-1203` (`held` → 5).

## Plan (one phase)
All changes are in `utils/py/_marathon_plan.py`:
1. **Deep delegation:** add `elif code == 3: state "needs-contract"` with the reason "swarm-preflight --dry-run → invalid contract (exit 3)". Then add `elif code != 0: state "preflight-error"` with a flag naming the code ("unknown/failed preflight exit N — hold; rerun swarm-preflight directly").
2. **Missing dependency:** in the resolution loop, treat a dep with no ledger row (`not dep`) as blocking. `blocked_by` includes it, so the dependent becomes `blocked-dep`. The existing `dep-not-found` flag keeps its message.
3. **No-progress fallback:** replace the packing at `:1163-1168` with holding. Each remaining deferred lane gets the held state `unplaceable`, with a flag ("could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave"). Then `break`. After packing, recompute `active` (captured at `:1131`) as the lanes actually placed, so the summary counts (`:1262-1274`) and the scoring table (`:1373`) do not report a lane as both active and held.
4. **Held set and rendering:**
   - add `"preflight-error"` and `"unplaceable"` to the `held` tuple (`:1196-1197`);
   - add them to the existing "⚠️ Not yet sequenceable" bucket at `:1425-1432`, since it has explicit buckets rather than generic rendering;
   - keep exit precedence: drift (4) still outranks held (5), so exit 5 is expected only when there is no drift.

**Phase 0 inside the lane** (record findings in a `## Phase 0` section of the lane's `smoke.md` before building; the orchestrator copies them into this doc):
- grep the planner fixtures for missing-dependency and cycle cases. Plan QA found that scenario G covers a present-but-held dependency (`test/marathon-plan.sh:234`), not a missing row, and that scenario T has neither a cycle nor deep delegation (`:629-685`), so its parity should not change;
- update only an assertion that truly pins the old behaviour, adding no scenario (GH-831);
- do not broaden the GH-698 rendered-table skip (`:688-697`) to hide any other failure.

Write-set:
- `utils/py/_marathon_plan.py`;
- existing planner test files only where Phase 0 shows an assertion pins old behaviour;
- the evidence bundle, `TESTS-RESULTS/2026-10-29+GH-1251/smoke.md` and `provenance.jsonl`;

This doc (Phase 0 findings copied from `smoke.md`, and the Status row) is updated by the orchestrator.

Full route.

## Acceptance

- [ ] A deep-preflight exit other than 0, 4, 5, 6 or 7 (including 1, 2, 3, 127 and signals) holds the item with a named reason and planner exit 5 instead of leaving it ready.
- [ ] A dependency that is not in the ledger holds the dependent item (`blocked-dep`) instead of only warning.
- [ ] When no ready lane can be placed in a wave, the remaining lanes are held with a named reason instead of being packed together into one wave.
- [ ] Existing planner suites stay green, changed only where they pin the old advisory behaviour, and a manual smoke receipt under `TESTS-RESULTS/` shows each seam with a base red control; no new tests (GH-831).

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
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/_marathon_plan.py",
      "pattern": "preflight-error"
    },
    {
      "type": "grep_absent",
      "path": "utils/py/_marathon_plan.py",
      "pattern": "unplaceable"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/_marathon_plan.py",
    "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1251",
    "criteria": "Unknown deep-preflight exits hold (preflight-error), missing deps block, no-progress lanes hold (unplaceable); held feeds exit 5."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/_marathon_plan.py",
      "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
      "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```
