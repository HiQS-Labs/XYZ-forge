---
gh_issue: 249
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/249
title: "Marathon gate enforces 'existing tests pass', not new-test presence — brief acceptance criteria are advisory prose"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit c1b3b6d;
  Python port commit 4418122)."
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: enhancement
complexity: 3
risk: 3
effort: 3
phases: 1
ratings_provisional: true
goal: >
  Add an optional new-test-presence gate to the marathon pre-advance check — a requires_test
  contract field plus a test-delta check — so a lane's brief acceptance criteria can be enforced,
  not just left as advisory prose.
roadmap_exempt: false
---

# GH-249 · marathon gate: enforce new-test presence, not just existing-test pass

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: no `requires_test` mechanism exists anywhere in `relay-automation/*.sh` or `utils/*.sh` today (confirmed via grep 2026-07-19). **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |
| **2026-07-21:** shipped via commit `c1b3b6d`; Python port shipped commit `4418122`; issue #249 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Problem
The marathon pre-advance gate (`relay-automation/marathon-drive.sh`) only checks that existing tests still pass. It never enforces that a lane actually *added* a test covering its fix. As a result, brief acceptance criteria that call for test coverage stay advisory prose — a lane can pass the gate and advance without ever having proven its fix with a new test.

## Fix direction
Add an optional new-test-presence gate:
- A `requires_test` contract field a lane's brief can set to demand test-delta enforcement.
- A test-delta check in the pre-advance gate (e.g. diff the test file set / test count before vs. after the lane's commit(s)) that fails the gate when `requires_test` is set and no new test was added.
- Keep it optional/opt-in so lanes that genuinely have no test surface (docs-only, config-only) aren't forced into a false requirement.

## Definition of done
- [ ] `relay-automation/marathon-drive.sh` (or its called helpers) supports a `requires_test` contract field.
- [ ] Pre-advance gate fails when `requires_test` is set and no test-delta is detected.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "requires_test" }
  ],
  "artifacts": [ "relay-automation/marathon-drive.sh" ],
  "remediation": {
    "source": "issue#249",
    "criteria": "relay-automation/marathon-drive.sh supports an optional requires_test contract field and a test-delta check in its pre-advance gate, failing the gate when requires_test is set and no new test was added."
  },
  "lanes": { "agy_safe": [ "relay-automation/marathon-drive.sh" ], "orchestrator_only": [] }
}
```
