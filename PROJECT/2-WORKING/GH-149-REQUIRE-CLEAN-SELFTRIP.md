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
| Confirmed live 2026-07-16 by direct code read of `relay-automation/marathon-drive.sh`: lines 137-140 place the lock at `$ROOT/.relay-driver.lock` (inside the worktree) whenever `$ROOT/.git` is a file rather than a directory — exactly the linked-worktree case. Lines 405-411's `git status --porcelain` clean-check excludes only `^phases/` and `^\.tick/` via awk, not the lock path/dir, so `--require-clean` hard-stops (line 411) on the driver's own lock. No commits since 2026-07-06 touch this (`git log --since` for relay-automation/marathon-drive.sh shows only unrelated GH-212/205/206/207/162 work). | Resolve the lock via `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git` is a file, so the lock always lands in the real `.git/` dir outside the worktree's porcelain view (cleaner than widening the awk exclusion, which would need to track the exact lock filename forever). |

## Findings

`marathon-drive.sh`'s lock-path selection doesn't account for a linked worktree's `.git` being a
file (a gitdir pointer) rather than the directory it is in a normal clone — so the driver's own lock
lands inside the worktree tree, where its own `--require-clean` check then sees it as untracked
dirt and refuses to proceed. This is exactly the failure mode this repo has been working around
manually (fire without `--require-clean` after eyeballing `git status`); this lane removes the need
for that workaround.

## Phase 0 — Fix and regression-verify

### Checklist

- [ ] In `relay-automation/marathon-drive.sh`, resolve the driver lock path via
      `git rev-parse --git-common-dir "$ROOT"` when `$ROOT/.git` is a file (linked worktree), so the
      lock lands outside the worktree's own `git status --porcelain` view
- [ ] Add/extend a regression test (in `test/marathon-drive.sh`) that runs `marathon-drive.sh
      --require-clean` from inside a linked worktree and asserts it does NOT self-trip on its own lock
- [ ] Full `bash test/marathon-drive.sh` still green

### QA checklist — Phase 0

- [ ] Fix scoped to the lock-path resolution only — no unrelated marathon-drive.sh changes
- [ ] Regression test added to `test/marathon-drive.sh` is additive (new test case), not a rewrite of
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
