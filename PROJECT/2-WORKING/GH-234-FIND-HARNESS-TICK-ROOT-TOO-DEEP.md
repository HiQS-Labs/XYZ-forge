---
gh_issue: 234
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/234
title: "find-harness.sh --env exports TICK_REPO_ROOT one directory too deep (found during GH-177 wipe investigation, never filed)"
status: "captured 2026-07-19 (auto-drafted by /10days)"
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
goal: >
  Fix find-harness.sh --env so TICK_REPO_ROOT points at the actual repo root, not the vendored
  .xyz harness subdirectory one level below it.
roadmap_exempt: false
---

# GH-234 · find-harness.sh TICK_REPO_ROOT too deep

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: `skills/relay-xyz/find-harness.sh:178` still exports `TICK_REPO_ROOT` set to `$HARNESS` (the vendored `.xyz` path) rather than the repo root, on `development` today. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |

## Problem
`find-harness.sh --env` exports `TICK_REPO_ROOT` pointing at the harness directory itself (e.g. `$CALLER_ROOT/.xyz`), which is one directory deeper than the actual repo root that `bin/tick` and tick-consuming shims expect. This was found during the GH-177 wipe investigation but never filed as its own issue at the time.

## Fix direction
In `skills/relay-xyz/find-harness.sh` (~line 178, `printf 'export TICK_REPO_ROOT=%q\n' "$HARNESS"`), export the actual repo root (e.g. the caller's `git rev-parse --show-toplevel`, already resolved elsewhere in the script as `_caller`) instead of `$HARNESS`, so `TICK_REPO_ROOT` matches what `bin/tick` and tick-consuming shims expect.

## Definition of done
- [ ] `find-harness.sh --env`'s `TICK_REPO_ROOT` points at the repo root, not the vendored `.xyz` harness subdirectory.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "skills/relay-xyz/find-harness.sh", "pattern": "export TICK_REPO_ROOT=%q" }
  ],
  "artifacts": [ "skills/relay-xyz/find-harness.sh" ],
  "remediation": {
    "source": "issue#234",
    "criteria": "find-harness.sh --env exports TICK_REPO_ROOT as the actual repo root (not the vendored .xyz harness subdirectory), matching what bin/tick and tick-consuming shims expect. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ "skills/relay-xyz/find-harness.sh" ], "orchestrator_only": [] }
}
```
