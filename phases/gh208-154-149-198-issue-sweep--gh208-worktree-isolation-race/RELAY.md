# Marathon Phase gh208-worktree-isolation-race
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "Phase brief: GH-208 flaky worktree-isolation race (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh208-worktree-isolation
  phase — not itself an active-doc capture; the canonical capture doc is
  GH-208-WORKTREE-ISOLATION-RACE.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon. |

## Phase: gh208-worktree-isolation-race — fix the flaky moved-ROOT-HEAD preserve-case race

Full context: [GH-208-WORKTREE-ISOLATION-RACE.md](../GH-208-WORKTREE-ISOLATION-RACE.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/208

### The bug

`test/worktree-isolation.sh` case 6 (the GH-13/#14 "moved ROOT HEAD is preserved" guard) is flaky:
9 local runs at current HEAD produced 8 failures (`FAIL: regressed: worktree turn reset on a moved
ROOT HEAD (rc=6)`) and 1 pass. All other 30 assertions in the file pass every run. This is a timing
race, not a permanent environment break — most likely the peer's `git commit --allow-empty` landing
concurrently with `relay-automation/relay-turn-lib.sh`'s `rtl_worktree_end` HEAD-moved check.

### What to do

1. Instrument the case-6 scenario with `RTL_TRACE=1` (already supported — grep for it in
   `relay-turn-lib.sh`) to find the exact race window in `rtl_worktree_begin`/`rtl_worktree_end`
   (look around lines 246, 474, 489-498, 751 in the current file — line numbers may drift).
2. Fix the race. Likely direction: the HEAD-moved check needs to re-verify right before acting, not
   rely on a single point-in-time read taken before the peer's commit could land. Prefer the
   narrowest fix that closes the window (e.g. re-check-after-lock) over restructuring the function.
3. Do NOT touch anything outside `rtl_worktree_begin`/`rtl_worktree_end` and their direct
   helpers — this file is kernel-sensitive (orchestrator_only per the harness's own lane
   conventions); a narrow, well-understood fix only.

### Acceptance / done means

- Run `test/worktree-isolation.sh` **5 times in a row** — all 5 must pass (was 8/9 fail before the
  fix). A single green run is not sufficient evidence for this bug.
- Full `bash validate.sh` shows no new regressions.
- Leave a one-line status update in `GH-208-WORKTREE-ISOLATION-RACE.md`'s Status table describing
  the root cause found and the fix.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent codex --paths "phases/gh208-154-149-198-issue-sweep--gh208-worktree-isolation-race/RELAY.md,relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh208-154-149-198-issue-sweep--gh208-worktree-isolation-race/RELAY.md and relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,test/worktree-isolation.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh208-154-149-198-issue-sweep--gh208-worktree-isolation-race/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
