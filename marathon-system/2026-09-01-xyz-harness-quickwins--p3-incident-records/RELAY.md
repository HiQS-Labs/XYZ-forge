# Marathon Phase p3-incident-records
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P3-INCIDENT-RECORDS-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "p3 brief — interrupted-phase tree snapshot (#371) + escalation root-cause tail (#372)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  When a phase dies mid-turn, the record must carry WHAT the tree looked like and WHY the
  turn failed — not just an exit code.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/371
  - https://github.com/HiQS-Labs/XYZ-forge/issues/372
---

# p3 — incident records

## Status

| What was just completed | What's next |
|---|---|
| Phase brief authored. | Marathon phase execution. |

Read the capture docs first: `PROJECT/2-WORKING/GH-371-INTERRUPT-SNAPSHOT-UNCOMMITTED-TREE.md`
and `PROJECT/2-WORKING/GH-372-ESCALATION-ROOT-CAUSE-TAIL.md`.

## #371 — snapshot the uncommitted tree on interruption

Where `PHASE-INTERRUPTED.md` is written (`utils/py/marathon_drive.py` interrupted-phase
path), append a `git status --porcelain` snapshot of the main repo AND the turn's
worktree (when worktree isolation was on and the dirs differ). Observed 2026-09-01: a
killed turn left 6 modified tracked files + 3 untracked tests in the MAIN repo with the
worktree clean; the record showed only the exit code, and the next gate silently
collected the half-finished tests. The snapshot is the recovery map AND the input for a
follow-on "tree unexpectedly dirty" warning at the next phase's Step 0 (the warning is
optional here; the snapshot is not).

Test: `test/gh371-interrupt-snapshot.sh` — drive a phase to interruption against a
fixture repo with a dirty tree; assert the interrupted-phase record contains the
porcelain lines.

## #372 — root-cause tail in ESCALATION.md

On turn failure/escalation, embed the last ~40 lines of the failing turn's log in a
collapsed block inside ESCALATION.md. If the turn's log file was never created, write
that explicitly — a missing log is itself diagnostic (observed: codex's "workspace out
of credits" surfaced only as `relay-failed-before-gate`; the log was not locatable from
the record). The turn log path is already resolved per-turn (`rtl_default_log`) — reuse
it; do not invent a second log-location scheme.

Test: `test/gh372-escalation-log-tail.sh` — force a turn failure with a fixture log;
assert ESCALATION.md contains the tail; assert the no-log case says so.

## Constraints

- Leave a `GH-371` marker in marathon_drive.py and a `GH-372` marker in relay_drive.py
  at the change sites (preflight probes key on them).
- These files are shared with p1/p2 — rebase-aware; do not revert their changes.
- Gate: `bash validate.sh`. In-turn, run only the two new tests plus files you edit.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py,utils/py/relay_drive.py,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick claim MARATHON-P3-INCIDENT-RECORDS-TURN --agent codex --paths "marathon-system/2026-09-01-xyz-harness-quickwins--p3-incident-records/RELAY.md,utils/py/marathon_drive.py,utils/py/relay_drive.py,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick ping MARATHON-P3-INCIDENT-RECORDS-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P3-INCIDENT-RECORDS-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/2026-09-01-xyz-harness-quickwins--p3-incident-records/RELAY.md and utils/py/marathon_drive.py,utils/py/relay_drive.py,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py,utils/py/relay_drive.py,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P3-INCIDENT-RECORDS-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick done MARATHON-P3-INCIDENT-RECORDS-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   Edit ONLY marathon-system/2026-09-01-xyz-harness-quickwins--p3-incident-records/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented both incident records.

- `utils/py/relay_drive.py` now resolves each dispatched shim's existing `rtl_default_log` path once,
  passes that exact path through the normal shim environment, and records its path plus main/worktree
  roots in the existing scratch handoff (`GH-371` / `GH-372`).
- `utils/py/marathon_drive.py` appends main and distinct worktree porcelain snapshots to
  `PHASE-INTERRUPTED.md`, and writes a collapsed 40-line tail (or an explicit no-log diagnosis) to
  `ESCALATION.md`.
- Added `test/gh371-interrupt-snapshot.sh` and `test/gh372-escalation-log-tail.sh`.

Verification: `bash test/gh371-interrupt-snapshot.sh` (2 pass, 0 fail) and
`bash test/gh372-escalation-log-tail.sh` (3 pass, 0 fail).
