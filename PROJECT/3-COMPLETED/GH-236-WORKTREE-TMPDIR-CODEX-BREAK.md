---
gh_issue: 236
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/236
title: "Worktree isolation under $TMPDIR breaks codex turns in /tmp-rooted environments (and escalates as a false timeout)"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 36d9e62, merged PR #252)."
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: true
goal: >
  In /tmp-rooted environments, relay-turn-lib.sh's isolation worktree must not break codex turns
  or be mislabeled as a timeout — either relocate the worktree root off $TMPDIR, or correct the
  escalation-reason labeling so the real cause is visible.
roadmap_exempt: false
---

# GH-236 · worktree isolation under $TMPDIR breaks codex turns

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: `relay-automation/relay-turn-lib.sh:433` still creates the isolation worktree via `mktemp -d "${TMPDIR:-/tmp}/rtl-wt.XXXXXX"`. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |
| **2026-07-21:** shipped via commit `36d9e62`, merged PR [#252](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/252); issue #236 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Problem
`rtl_worktree_begin()` in `relay-automation/relay-turn-lib.sh` (~line 433) creates the isolation
worktree under `${TMPDIR:-/tmp}` via `mktemp -d "${TMPDIR:-/tmp}/rtl-wt.XXXXXX"`. In environments
where `$TMPDIR` is itself the effective repo/working root (/tmp-rooted environments), this breaks
codex turns run against that worktree, and the failure surfaces mislabeled as a turn timeout rather
than as the actual worktree-placement conflict — making it hard to diagnose from the escalation
message alone.

## Fix direction
Either relocate the isolation worktree root off `$TMPDIR` (e.g. under the repo's own `.git`
metadata directory or a dedicated non-tmp scratch root), or, if relocation isn't viable in all
cases, correct the escalation-reason labeling so a /tmp-rooted worktree conflict is reported as
what it is instead of as a false timeout.

## Definition of done
- [ ] Isolation worktree placement no longer breaks codex turns in a /tmp-rooted environment, or the
      escalation path correctly labels this failure mode instead of reporting it as a timeout.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "relay-automation/relay-turn-lib.sh", "pattern": "rtl-wt" }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh" ],
  "remediation": {
    "source": "issue#236",
    "criteria": "relay-turn-lib.sh's isolation worktree creation no longer roots under $TMPDIR in a way that breaks codex turns (relocated, or the /tmp-rooted conflict is correctly labeled instead of reported as a timeout). bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ "relay-automation/relay-turn-lib.sh" ], "orchestrator_only": [] }
}
```
