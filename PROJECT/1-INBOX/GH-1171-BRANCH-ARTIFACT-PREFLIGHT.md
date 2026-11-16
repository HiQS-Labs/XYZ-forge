---
gh_issue: 1171
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1171
title: "Relay preflight distinguishes existing branch refs from missing files"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
updated: 2026-11-11
owner: Codex Jog trial
doc_type: bugfix
goal: "Relay preflight distinguishes existing branch refs from missing files"
---

# Relay preflight distinguishes existing branch refs from missing files

## Status

| What was just completed | What's next |
|---|---|
| Open issue and live source inspected; no matching active doc or open PR found. | Independent plan QA, supported pickup/accepted-start, generated packet proof, then one bounded Jog run. |

## Plan

1. Recognize verified local or origin branch refs before path existence enforcement in the Python relay preflight. Keep genuine missing path rejection and URL/embedded-artifact handling. Do not change the frozen Bash twin. Record branch and missing-file manual controls; use existing relay coverage.
2. Run the declared existing focused gate in a disposable full clone, record final manual witnesses under TESTS-RESULTS with provenance, and obtain Agy review through Jog. No manual implementation by the trial owner.

## Acceptance

- [ ] An existing slash-containing local branch on Artifact under review passes preflight.
- [ ] A genuinely missing docs/gh1171-missing.md still fails with the existing diagnostic.
- [ ] Record manual regression controls with provenance; no new suite or gate.

## Acceptance — deviations from the issue

- [added] An existing slash-containing local branch on Artifact under review passes preflight. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.
- [added] A genuinely missing docs/gh1171-missing.md still fails with the existing diagnostic. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.
- [added] Record manual regression controls with provenance; no new suite or gate. — reason: Translate the issue prose into a machine-checkable checklist; manual regression evidence follows the repository no-new-tests rule.

## Scope and budget

Easy to revert as a targeted source commit. The relay change affects artifact admission; the migration change affects explicit legacy retirement only. Stop on containment, ownership, gate failure, or cap exhaustion. No merge, deployment, cleanup, new test suite, or configuration change. Independent of the other trial item. PRS proposal: rated 65/50/50/90.

Trial #1386 owns one invocation, max_tasks=2, Codex builder/Agy reviewer, round_cap=2 and LANE_MAX_ATTEMPTS=2. Hard end 2026-11-11T06:51:58Z; reserve ten minutes for closeout. No repeated dispatch or reset of history. Launch environment: RELAY_TURN_TIMEOUT_S=240, RELAY_TURN_IDLE_S=240, MARATHON_GATE_WALL_S=660, LANE_MAX_ATTEMPTS=2; inherited width overrides unset. Native timeout handoff recovery only; no manual second dispatch. Full gate runs serially on this host with default width and the existing test venv, only if time remains.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh376-relay-drive-lock-parity.sh",
  "round_cap": 2,
  "artifacts": [
    "utils/py/relay_drive.py",
    "TESTS-RESULTS/2026-11-11+GH-1171/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-11+GH-1171/manual_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#1171",
    "criteria": "Recognize verified local or origin branch refs before path existence enforcement in the Python relay preflight. Keep genuine missing path rejection and URL/embedded-artifact handling. Do not change the frozen Bash twin. Record branch and missing-file manual controls; use existing relay coverage."
  }
}
```
