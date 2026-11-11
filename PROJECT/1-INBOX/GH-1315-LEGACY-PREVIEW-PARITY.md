---
gh_issue: 1315
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1315
title: "Legacy migration preview refuses unadopted skill retirement"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
updated: 2026-11-11
owner: Codex Jog trial
doc_type: bugfix
goal: "Legacy migration preview refuses unadopted skill retirement"
---

# Legacy migration preview refuses unadopted skill retirement

## Status

| What was just completed | What's next |
|---|---|
| Open issue and live source inspected; no matching active doc or open PR found. | Independent plan QA, supported pickup/accepted-start, generated packet proof, then one bounded Jog run. |

## Plan

1. Require the existing retirement ownership eligibility before retire_legacy archives or stages anything, shared by preview/apply. Return an adoption remedy through the existing errors path. Preserve valid recorded-skill migration and receipt-only adoption. Do not broaden retirement authorization or change deployed configuration. Record isolated preview/apply controls and use the existing skills-army-hq suite.
2. Run the declared existing focused gate in a disposable full clone, record final manual witnesses under TESTS-RESULTS with provenance, and obtain Agy review through Jog. No manual implementation by the trial owner.

## Acceptance

- [ ] An unadopted real legacy directory is refused by preview and apply with an adoption remedy.
- [ ] Refusal creates no backup, staging retirement, or link and preserves the directory.
- [ ] Recorded-skill migration remains supported; verify in isolated fixtures only.

## Acceptance — deviations from the issue

- [added] An unadopted real legacy directory is refused by preview and apply with an adoption remedy. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.
- [added] Refusal creates no backup, staging retirement, or link and preserves the directory. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.
- [added] Recorded-skill migration remains supported; verify in isolated fixtures only. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.

## Scope and budget

Easy to revert as a targeted source commit. The relay change affects artifact admission; the migration change affects explicit legacy retirement only. Stop on containment, ownership, gate failure, or cap exhaustion. No merge, deployment, cleanup, new test suite, or configuration change. Independent of the other trial item. PRS proposal: rated 60/45/50/85.

Trial #1386 owns one invocation, max_tasks=2, Codex builder/Agy reviewer, round_cap=2 and LANE_MAX_ATTEMPTS=2. Hard end 2026-11-11T06:51:58Z; reserve ten minutes for closeout. No repeated dispatch or reset of history. Launch environment: RELAY_TURN_TIMEOUT_S=240, RELAY_TURN_IDLE_S=240, MARATHON_GATE_WALL_S=660, LANE_MAX_ATTEMPTS=2; inherited width overrides unset. Native timeout handoff recovery only; no manual second dispatch. Full gate runs serially on this host with default width and the existing test venv, only if time remains.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/skills-army-hq.sh",
  "round_cap": 2,
  "artifacts": [
    "skills/3-weekly/skills-army-hq/scripts/sync.py",
    "TESTS-RESULTS/2026-11-11+GH-1315/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-11+GH-1315/manual_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#1315",
    "criteria": "Require the existing retirement ownership eligibility before retire_legacy archives or stages anything, shared by preview/apply. Return an adoption remedy through the existing errors path. Preserve valid recorded-skill migration and receipt-only adoption. Do not broaden retirement authorization or change deployed configuration. Record isolated preview/apply controls and use the existing skills-army-hq suite."
  }
}
```
