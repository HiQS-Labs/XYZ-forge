---
gh_issue: 242
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/242
title: "agy S10: off-prompt-nonempty repro — deferred from #155, needs a controlled trigger"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 9c052f4)."
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 2
risk: 3
effort: 3
phases: 1
ratings_provisional: true
goal: >
  Establish a controlled, reproducible trigger for agy's off-prompt-nonempty (S10) condition —
  split out of #155 with no repro yet — and land a regression case for it in test/agy-turn.sh.
roadmap_exempt: false
---

# GH-242 · agy S10 off-prompt-nonempty repro

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: `test/agy-turn.sh` has zero matches for `S10` today — no repro or regression case exists yet; only the bookkeeping split commit (8784d08) is on record. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. **This is a SPIKE/discovery item — it may come back marathon-unready from preflight, and that is expected**: the deliverable is a controlled trigger, which may not be findable in a single bounded turn. |
| **2026-07-21:** shipped via commit `9c052f4`; issue #242 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Problem
agy S10 (`off-prompt-nonempty`) has no controlled reproduction. It was split out of #155 as its
own item, but nothing beyond the bookkeeping split commit (`8784d08`) exists — no trigger, no
regression case, no test coverage. Without a controlled repro, S10 cannot be fixed or verified as
fixed.

## Fix direction
This is discovery work, not a known-shape fix: find a deterministic (or reliably-reproducible)
trigger for the off-prompt-nonempty condition in agy's turn handling, document the trigger, and
then encode it as a regression case in `test/agy-turn.sh` (an `S10` case) so future changes can't
silently reintroduce it.

## Definition of done
- [ ] A controlled, documented trigger for agy S10 (off-prompt-nonempty) exists.
- [ ] `test/agy-turn.sh` has a regression case covering it.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "test/agy-turn.sh", "pattern": "off-prompt-nonempty" }
  ],
  "artifacts": [ "test/agy-turn.sh" ],
  "remediation": {
    "source": "issue#242",
    "criteria": "test/agy-turn.sh gains an S10 (off-prompt-nonempty) regression case built on a documented, controlled trigger. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ "test/agy-turn.sh" ], "orchestrator_only": [] }
}
```
