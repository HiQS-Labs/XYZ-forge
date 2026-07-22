---
gh_issue: 247
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/247
title: "marathon-triage: bare utils/ paths break in vendored .xyz/ installs"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 95c3e12, merged PR #252)."
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
goal: >
  Make skills/marathon-triage/SKILL.md's utils/ references resolve inside a vendored .xyz/ install
  by locating the harness root the same way other skills already self-locate .xyz, instead of
  assuming bare utils/ paths from the repo root.
roadmap_exempt: false
---

# GH-247 · marathon-triage vendored .xyz/ path resolution

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: `skills/marathon-triage/SKILL.md` still hardcodes bare `utils/swarm-preflight.sh` / `utils/marathon-plan.sh` paths at lines 9, 61, 68, 69, 80 (confirmed via grep 2026-07-19). **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |
| **2026-07-21:** shipped via commit `95c3e12`, merged PR [#252](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/252); issue #247 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Problem
`skills/marathon-triage/SKILL.md` hardcodes bare `utils/swarm-preflight.sh` and `utils/marathon-plan.sh` paths (lines ~9, 61, 68, 69, 80), assuming the skill always runs from a repo root where `utils/` sits directly under the working directory. In a vendored `.xyz/` install (this repo's tooling embedded as a subdirectory of a host repo), those bare paths don't resolve — the skill can't find its own preflight/plan scripts.

## Fix direction
Resolve `utils/` relative to the harness root rather than the invocation's current working directory, mirroring how other skills already self-locate `.xyz` in a vendored install. Replace the 5 bare-path references with the resolved-root form.

**Shares an edit surface with GH-250** — both this issue and GH-250 edit `skills/marathon-triage/SKILL.md`. Do not run them in the same concurrent wave; serialize.

## Definition of done
- [ ] All `utils/swarm-preflight.sh` / `utils/marathon-plan.sh` references in `skills/marathon-triage/SKILL.md` resolve correctly whether the skill runs from the bare repo root or a vendored `.xyz/` install.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "skills/marathon-triage/SKILL.md", "pattern": "utils/swarm-preflight.sh" }
  ],
  "artifacts": [ "skills/marathon-triage/SKILL.md" ],
  "remediation": {
    "source": "issue#247",
    "criteria": "skills/marathon-triage/SKILL.md resolves utils/swarm-preflight.sh and utils/marathon-plan.sh relative to the harness root so they work in a vendored .xyz/ install, not just a bare repo root."
  },
  "lanes": { "agy_safe": [ "skills/marathon-triage/SKILL.md" ], "orchestrator_only": [] }
}
```
