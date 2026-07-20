---
gh_issue: 250
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/250
title: "marathon-triage: emit a default recommendation per item, not symmetric options"
status: "captured 2026-07-19 (auto-drafted by /10days)"
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: enhancement
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
goal: >
  Add a RECOMMEND/BECAUSE/UNLESS framing to marathon-triage's per-item report so each triaged item
  carries a default call instead of a flat, symmetric list of options the operator must weigh
  unaided.
roadmap_exempt: false
---

# GH-250 · marathon-triage default recommendation framing

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: no `RECOMMEND:` framing exists anywhere in `skills/marathon-triage/SKILL.md` today (confirmed via grep 2026-07-19). **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |

## Problem
`skills/marathon-triage/SKILL.md`'s report step (`### 5. Report`) presents symmetric options per item — e.g. "archive, close, promote, contract, or unblock" — without a default call. The operator has to independently weigh each item from scratch instead of starting from a recommended default and only overriding when warranted.

## Fix direction
Add a `RECOMMEND:` / `BECAUSE:` / `UNLESS:` framing to the per-item report output: a default recommendation, the reasoning behind it, and the condition under which the operator should override it. Wire this into step 5 (`Report`) alongside the existing classification table.

**Shares an edit surface with GH-247** — both this issue and GH-247 edit `skills/marathon-triage/SKILL.md`. Do not run them in the same concurrent wave; serialize.

## Definition of done
- [ ] `skills/marathon-triage/SKILL.md`'s report step emits a `RECOMMEND:` / `BECAUSE:` / `UNLESS:` line per triaged item.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "skills/marathon-triage/SKILL.md", "pattern": "RECOMMEND:" }
  ],
  "artifacts": [ "skills/marathon-triage/SKILL.md" ],
  "remediation": {
    "source": "issue#250",
    "criteria": "skills/marathon-triage/SKILL.md's report step emits a RECOMMEND:/BECAUSE:/UNLESS: framing per triaged item instead of a flat symmetric options list."
  },
  "lanes": { "agy_safe": [ "skills/marathon-triage/SKILL.md" ], "orchestrator_only": [] }
}
```
