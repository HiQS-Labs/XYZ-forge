---
gh_issue: 149
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149
title: "marathon-drive --require-clean self-trips on its own .relay-driver.lock/ inside a linked worktree"
status: Triaged 2026-07-16 during a recent-issues sweep — still present in current code, confirmed
  by direct read; no fix has landed since the issue was filed (2026-07-06).
created: 2026-07-06
updated: 2026-07-16
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not touching relay-drive.sh's own require-clean/lock handling — this lane is marathon-drive.sh only
related:
  - relay-automation/marathon-drive.sh
  - marathon-require-clean-worktree-selftrip (memory: known workaround is firing without
    --require-clean after manually verifying clean; this lane removes the need for that workaround)
goal: >
  Make marathon-drive.sh's --require-clean clean-check resolve its own driver lock outside the
  worktree's porcelain view, so a linked worktree's own .relay-driver.lock no longer trips its own
  cleanliness gate.
roadmap_exempt: false
---

# GH-149 · marathon-drive --require-clean self-trip in a linked worktree

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved). `relay-automation/marathon-drive.sh` now resolves the driver lock via `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git` is a file (linked worktree), placing it in the real `.git/` dir instead of `$ROOT/.relay-driver.lock` — outside the worktree's own `git status --porcelain` view. Falls back to the original hidden-lock-beside-scripts behavior for a vendored `.xyz/` copy where `git-common-dir` can't resolve. New regression case added to `test/marathon-drive.sh` (+31 lines). Full `bash test/marathon-drive.sh` green: 105/105. | Closed out — nothing further for this lane. |

## Findings

`marathon-drive.sh`'s lock-path selection doesn't account for a linked worktree's `.git` being a
file (a gitdir pointer) rather than the directory it is in a normal clone — so the driver's own lock
lands inside the worktree tree, where its own `--require-clean` check then sees it as untracked
dirt and refuses to proceed. This is exactly the failure mode this repo has been working around
manually (fire without `--require-clean` after eyeballing `git status`); this lane removes the need
for that workaround.

## Phase 0 — Fix and regression-verify

### Checklist

- [x] Resolved the driver lock path via `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git`
      is a file (linked worktree), so the lock lands outside the worktree's own
      `git status --porcelain` view (falls back to the original hidden-lock behavior when
      `git-common-dir` can't resolve, e.g. a vendored `.xyz/` copy)
- [x] Added a regression case to `test/marathon-drive.sh` proving `--require-clean` no longer
      self-trips on its own lock from inside a linked worktree
- [x] Full `bash test/marathon-drive.sh` green: 105/105

### QA checklist — Phase 0

- [x] Fix scoped to the lock-path resolution only — no unrelated marathon-drive.sh changes
- [x] Regression test added to `test/marathon-drive.sh` is additive (new test case), not a rewrite of
      existing cases

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-drive.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "git-common-dir" }
  ],
  "artifacts": [ "relay-automation/marathon-drive.sh", "test/marathon-drive.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist in this doc" },
  "lanes": { "agy_safe": [ "relay-automation/marathon-drive.sh", "test/marathon-drive.sh" ], "orchestrator_only": [] }
}
```
