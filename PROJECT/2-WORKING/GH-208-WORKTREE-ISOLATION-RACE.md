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
| Confirmed live 2026-07-16: ran `bash test/worktree-isolation.sh` 9x at HEAD (`33b77a2`, main) — 8 failures, all identical: `FAIL: regressed: worktree turn reset on a moved ROOT HEAD (rc=6)` at the case-6 assertion (line ~140). All other 30/31 assertions pass every run. Not env-unfixable as the issue title speculates — this is a timing-sensitive race, most likely the peer's `git commit --allow-empty` landing concurrently with `rtl_worktree_end`'s HEAD check. | Instrument with `RTL_TRACE=1` (per the issue's own suggested next step) to find the exact race window in `rtl_worktree_begin`/`rtl_worktree_end` (relay-turn-lib.sh ~lines 246, 474, 489-498, 751), then fix (likely a re-check-after-lock or serializing the HEAD read). |

## Findings

`relay-automation/relay-turn-lib.sh` — `rtl_worktree_end` restores/resets a worktree's HEAD at
turn-close, guarding against a peer's concurrent commit changing ROOT's HEAD mid-turn (the original
GH-13/#14 fix). The guard itself is present but its detection window appears to race against the
peer commit landing: most runs correctly preserve the moved HEAD (rc != 6), but a minority reset it
(rc=6) as if the peer commit hadn't been seen yet at the check point.

## Phase 0 — Fix and regression-verify

### Checklist

- [ ] Instrument the case-6 scenario with `RTL_TRACE=1` to pinpoint the exact race window between
      the peer's commit and `rtl_worktree_end`'s HEAD-moved check
- [ ] Fix the race (serialize/re-check rather than a single point-in-time read)
- [ ] Confirm 10x repeated clean runs of `test/worktree-isolation.sh` (was 8/9 fail before the fix)
- [ ] Full `validate.sh` still green (no regression to the other 30 assertions in this file, or any
      other gate)

### QA checklist — Phase 0

- [ ] Fix is scoped to `relay-turn-lib.sh`'s worktree-end HEAD-check path — no unrelated refactor
- [ ] Verified across repeated runs, not a single green run (this bug is flaky by nature)

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
