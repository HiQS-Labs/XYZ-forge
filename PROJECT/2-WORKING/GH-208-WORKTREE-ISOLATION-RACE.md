---
gh_issue: 208
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208
title: "worktree-isolation.sh: moved-ROOT-HEAD preserve case (GH-13/#14 guard) fails on this machine — env-dependent, blocks validate.sh-as-gate"
status: Triaged 2026-07-16 during a recent-issues sweep — reproduces as a genuine timing race (not a
  permanent environment break). 8/9 local repeated runs of `test/worktree-isolation.sh` failed the
  same assertion (case 6, rc=6); 1/9 passed. All other 30 assertions in the file pass every time.
created: 2026-07-15
updated: 2026-07-16
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not a rewrite of worktree isolation — narrow fix to the GH-13/#14 preserve-case race only
related:
  - relay-automation/relay-turn-lib.sh
  - test/worktree-isolation.sh
goal: >
  Fix the flaky "moved ROOT HEAD preserve" case in test/worktree-isolation.sh (case 6, GH-13/#14
  guard) so validate.sh can be used as a hard marathon gate without an intermittent false red.
roadmap_exempt: false
---

# GH-208 · worktree-isolation.sh flaky preserve-case race

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved). Root cause was NOT a race in `relay-turn-lib.sh`'s HEAD-moved check (that logic is correct and untouched) — it was a **test-fixture timing bug**: case (5)'s non-isolated turn produces a deliberate async write (`offlane-async.txt`) that lands ~1s later, and the fixture's cleanup ran before that write landed, so it bled into case (6)'s assertion and looked like a worktree-isolation regression. Fix: `test/worktree-isolation.sh` now sleeps 2s before cleanup to let the async write land first (3 lines changed, no source-code change needed). Verified 8/8 clean repeated runs post-fix (was 8/9 fail before). `bash validate.sh`: 113/114 (only the unrelated, already-tracked `relay-pkg-freshness.sh` staleness, fixed separately by rebuilding the tarball). | Closed out — nothing further for this lane. |

## Findings

`relay-automation/relay-turn-lib.sh` — `rtl_worktree_end` restores/resets a worktree's HEAD at
turn-close, guarding against a peer's concurrent commit changing ROOT's HEAD mid-turn (the original
GH-13/#14 fix). The guard itself is present but its detection window appears to race against the
peer commit landing: most runs correctly preserve the moved HEAD (rc != 6), but a minority reset it
(rc=6) as if the peer commit hadn't been seen yet at the check point.

## Phase 0 — Fix and regression-verify

### Checklist

- [x] Instrumented/root-caused the case-6 scenario — found it's a test-fixture timing bug, not a
      `relay-turn-lib.sh` race (see Status)
- [x] Fixed: `test/worktree-isolation.sh` now waits for case (5)'s async write to land before
      cleanup, rather than a source-code change to `rtl_worktree_end`
- [x] Confirmed 8/8 repeated clean runs of `test/worktree-isolation.sh` (was 8/9 fail before the fix)
- [x] Full `validate.sh` green: 113/114 (only the separately-fixed `relay-pkg-freshness.sh`
      staleness, unrelated to this lane)

### QA checklist — Phase 0

- [x] Fix is scoped to the test fixture only — `relay-turn-lib.sh` was correctly left untouched
      once the real root cause was found
- [x] Verified across repeated runs (8x), not a single green run

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/worktree-isolation.sh",
  "fix_probes": [
    { "type": "command", "cmd": "for i in 1 2 3 4 5; do bash test/worktree-isolation.sh || exit 1; done", "expect_nonzero": true }
  ],
  "artifacts": [ "relay-automation/relay-turn-lib.sh", "test/worktree-isolation.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist in this doc" },
  "lanes": { "agy_safe": [ "relay-automation/relay-turn-lib.sh", "test/worktree-isolation.sh" ], "orchestrator_only": [] }
}
```

Note: the fix_probe runs the test 5x rather than once, since a single run can pass by chance (the
race is intermittent, ~1/9 clean in triage) — a single-run probe would risk a false "already landed"
verdict.
