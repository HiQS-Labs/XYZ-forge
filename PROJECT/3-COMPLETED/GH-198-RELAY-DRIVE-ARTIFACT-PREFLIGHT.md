---
gh_issue: 198
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198
title: "relay-drive.sh headless turn: file-scoped commit ignores pathspec (sweeps pre-existing staged changes); uncommitted-artifact review fails opaquely"
status: Fixed and verified 2026-07-17 — Bug 2 via the GH208-154-149-198 marathon (merged to
  `development`); Bug 1 already fixed separately (commit bee1abf). Issue #198 closed. See the
  Status table below for detail.
created: 2026-07-11
updated: 2026-07-17
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not Bug 1 — already fixed and tested (commit bee1abf, test/relay-commit-pathspec.sh)
  - Not a rewrite of --artifact-file handling (which already has its own preflight check and test,
    test/relay-artifact-file.sh) — this covers only the Setup-referenced-artifact case
related:
  - relay-automation/relay-drive.sh
  - test/relay-artifact-file.sh
goal: >
  Add a fail-fast preflight check to relay-drive.sh so a relay thread whose Setup section
  references an artifact path that doesn't exist in the target worktree fails immediately with a
  clear message, instead of the reviewer turn failing opaquely deep inside its own run.
roadmap_exempt: false
---

# GH-198 · relay-drive.sh: no preflight check for a missing Setup-referenced artifact (Bug 2)

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved). `relay-automation/relay-drive.sh` gained `preflight_setup_artifact_paths()`, called before each turn dispatch: it scans the relay file's `Setup` section for an "Artifact under review:" line, extracts candidate paths (backtick/bold-wrapped tokens), filters out URLs/`.relay-artifacts/`-seeded paths/"embedded below" markers, and `die`s with a message containing `artifact path not found in worktree: <path>` if a real candidate doesn't resolve. New cases in `test/relay-artifact-file.sh`: "missing Setup artifact path reports the clear GH-198 message" and "missing Setup artifact path blocks agent dispatch". Full `bash test/relay-artifact-file.sh` green: 13/13 (up from 11). | Closed out — nothing further for this lane. |

## Findings

`relay-automation/relay-drive.sh` already fails fast for a missing `--artifact-file` (an explicit
CLI flag, used for seeding external/cross-repo artifacts read-only). It has no equivalent check for
the more common case — a relay thread's `Setup` section naming a path the reviewer is meant to open
directly from the target repo/worktree. When that path is missing (typo, wrong branch, doc moved),
the failure currently surfaces opaquely deep inside the reviewer's own turn instead of at dispatch
time.

## Phase 0 — Fix and regression-verify

### Checklist

- [x] Added `preflight_setup_artifact_paths()` in `relay-automation/relay-drive.sh`, called before
      dispatching a turn — resolves any artifact path referenced in the relay file's `Setup`
      section against the worktree, fails fast with `artifact path not found in worktree: <path>`
- [x] Extended `test/relay-artifact-file.sh` with 2 cases exercising this new preflight path
- [x] Full `bash test/relay-artifact-file.sh` green: 13/13

### QA checklist — Phase 0

- [x] Fix scoped to the new preflight check only — does not touch the existing `--artifact-file`
      check (line 270) or Bug 1's already-fixed commit-scoping logic
- [x] New test cases are additive to `test/relay-artifact-file.sh`, not a rewrite

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/relay-artifact-file.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-drive.sh", "pattern": "artifact path not found in worktree" }
  ],
  "artifacts": [ "relay-automation/relay-drive.sh", "test/relay-artifact-file.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist in this doc" },
  "lanes": { "agy_safe": [ "relay-automation/relay-drive.sh", "test/relay-artifact-file.sh" ], "orchestrator_only": [] }
}
```
