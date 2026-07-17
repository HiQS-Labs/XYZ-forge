---
gh_issue: 198
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198
title: "relay-drive.sh headless turn: file-scoped commit ignores pathspec (sweeps pre-existing staged changes); uncommitted-artifact review fails opaquely"
status: Triaged 2026-07-16 during a recent-issues sweep. Bug 1 (file-scoped commit ignoring
  pathspec) is ALREADY FIXED — commit bee1abf landed it in relay-turn-lib.sh, with its own
  regression test (test/relay-commit-pathspec.sh, 9/9). This doc re-scopes the issue to the
  remaining Bug 2 only (a UX gap, not a data-loss bug).
created: 2026-07-11
updated: 2026-07-16
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
| Confirmed live 2026-07-16: Bug 1 (file-scoped commit sweeping the whole index) is fixed — `relay-turn-lib.sh` now builds the commit from `_commit_paths`, cross-checked against `git diff --cached --name-only`, with its own regression test. Bug 2 remains: `relay-drive.sh` only validates the presence of a path passed via the `--artifact-file` CLI flag (line 270, `[[ -f "$ARTIFACT_FILE" ]] || die ...`) — there is no equivalent check for an artifact path referenced inside a relay thread's own `Setup` section (a different, more common path: a human or a prior turn writes "review `<path>`" directly into the thread body). | Add a preflight check that scans the relay file's Setup section for a referenced artifact path and fails fast (clear message) if it's missing from the worktree, before dispatching the turn. |

## Findings

`relay-automation/relay-drive.sh` already fails fast for a missing `--artifact-file` (an explicit
CLI flag, used for seeding external/cross-repo artifacts read-only). It has no equivalent check for
the more common case — a relay thread's `Setup` section naming a path the reviewer is meant to open
directly from the target repo/worktree. When that path is missing (typo, wrong branch, doc moved),
the failure currently surfaces opaquely deep inside the reviewer's own turn instead of at dispatch
time.

## Phase 0 — Fix and regression-verify

### Checklist

- [ ] Add a preflight check in `relay-automation/relay-drive.sh` that, before dispatching a turn,
      resolves any artifact path referenced in the relay file's `Setup` section against the
      worktree and fails fast with a message containing the literal string
      `artifact path not found in worktree` if it's missing
- [ ] Extend `test/relay-artifact-file.sh` with a case exercising this new preflight path (a
      Setup-referenced path that doesn't exist → fails fast with the clear message, not an opaque
      mid-turn failure)
- [ ] Full `bash test/relay-artifact-file.sh` still green

### QA checklist — Phase 0

- [ ] Fix scoped to the new preflight check only — does not touch the existing `--artifact-file`
      check (line 270) or Bug 1's already-fixed commit-scoping logic
- [ ] New test case is additive to `test/relay-artifact-file.sh`, not a rewrite

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
