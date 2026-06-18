# Marathon Phase 1
STATUS: Open
NEXT: claude

<!-- marathon-drive: task=MARATHON-G4-TURN builder=claude reviewer=codex-reviewer round-cap=6 -->

## Phase Brief

## Build `test/chaos-concurrent-pollers.sh` — Part B G4 (concurrent pollers)

### Goal
Write a NEW bash test at `test/chaos-concurrent-pollers.sh` proving the coordination
kernel's **concurrent-poller safety**: when two eligible pollers race to act on the SAME
available turn token, **exactly one acts** and the other stands down — every time, across
many trials.

### Why it matters
Two poller loops (two terminal windows, or a window + cron) can both observe "it's my turn
/ a task is parked" and both try to take it → double-claim, double-execution, double-commit.
The real guard is the tick claim mutex (`src/lock.js` `withClaimLock` + the atomic next+claim
`tick take`), NOT the timer. This test must demonstrate that guard holds under a genuine race.

### Acceptance criteria (the test MUST)
1. Source the shared harness: `source "$(dirname "$0")/_setup.sh" chaos-concurrent-pollers`
   — it provides `$TICK`, `$WORK`, `$A`, `tick_a`/`tick_in`, and `pass`/`fail`. Put ALL
   fixtures under `$WORK` (mktemp); NEVER write into the repo tree.
2. Run N=20 trials. Each trial:
   a. Seed exactly ONE claimable/available task in a fresh state (unclaimed).
   b. Launch TWO claimers CONCURRENTLY as two different agents (background subshells with `&`,
      then `wait`) — a genuine race; start them as close together as possible.
   c. Assert EXACTLY ONE succeeded in claiming that task and the other got nothing
      (no double-claim). Record each trial's winner.
3. Exit 0 only if all N trials had exactly one actor; non-zero on ANY double-claim.
4. Mirror the existing tests — study `test/concurrent-claim.sh` (closest prior art),
   `test/_setup.sh`, and `relay-automation/poll.sh`. Lean on `tick take` / `tick claim`
   (whichever the poller uses) as the mutex.
5. Deterministic + self-contained: no network, no real model CLIs, minimal sleeps, clean
   teardown (the `_setup.sh` EXIT trap removes `$WORK`).

### Constraints (containment)
- Edit ONLY `test/chaos-concurrent-pollers.sh` (plus your relay build block). Do NOT modify
  `validate.sh`, `poll.sh`, or anything under `src/`. If the kernel cannot pass this test,
  SAY SO in your build block instead of changing the kernel — a failing test is a real finding.
- The harness runs your test as the approval gate: it must exit 0 on success.

---

▶ TAKE YOUR TURN (claude — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): test/chaos-concurrent-pollers.sh
2. Append a build block to this relay file: `### Round N · Builder · claude` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-G4-TURN --agent claude --paths "phases/p1/RELAY.md,test/chaos-concurrent-pollers.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-G4-TURN --agent claude
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-G4-TURN --agent claude --to codex-reviewer
4. Edit ONLY these paths: phases/p1/RELAY.md and test/chaos-concurrent-pollers.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex-reviewer — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: test/chaos-concurrent-pollers.sh.
1. Append a review block: `### Round N · Reviewer · codex-reviewer` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-G4-TURN --agent codex-reviewer --to claude
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-G4-TURN --agent codex-reviewer
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
