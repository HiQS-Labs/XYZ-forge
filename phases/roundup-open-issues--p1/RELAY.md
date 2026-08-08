# Marathon Phase p1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-P1-TURN-2 builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

# p1 — GH-22: multiple assignees for one reminder

Release 1.4.270 "Roundup" · issue [#22] · plan:
`PROJECT/2-WORKING/GH-22-MULTIPLE-REMINDER-ASSIGNEES.md` (read it in full first — it is the
authority, this brief is the execution frame)

## The defect

A reminder naming two people is persisted and indexed for the **first mention only**, while its
confirmation message claims it was scheduled for **both**. The second person's `show-me` therefore
silently omits it. The user is told something happened that did not.

This is the only user-visible defect in the release. It goes first so that if the marathon halts
early, the thing users actually feel is already fixed.

## Shape of the fix

Per the plan doc: one **shared** reminder carrying additive `AssigneeIDs`, with legacy `AssigneeID`
retained for compatibility, membership-aware views/exports, and per-user Slack List fan-out.

Read the plan doc for the full design. Do not redesign it here.

## The constraint that dominates this phase

**`AssigneeID` is persisted on disk in every existing workspace's reminder store.** This is a
disk-format change on live data, so:

- `AssigneeIDs` is **additive**. Never remove or stop writing `AssigneeID`.
- A reminder written by the old code must load correctly under the new code — `AssigneeID` alone
  implies `AssigneeIDs: [AssigneeID]`.
- A reminder written by the new code must not crash the old code — keep `AssigneeID` populated with
  the first assignee.
- `AGENTS.md` §10 requires compatibility/backfill logic for disk-persisted data changes. This is
  exactly that case.

## The FSM constraint

Reminder state changes go through the three named write chokepoints
(`#MakeScheduledReminder`, `#TryScheduleRemindersAsync`, `#TransitionReminderState`) and are
mechanically checked by `scripts/validate-fsm-invariants.js`. Do not add a fourth write path.
Run `npm run validate:fsm` as well as the suite.

## Event-log consequence

`ReminderCreated` events carry assignee identity, and the P3 projection folds them. If the event
payload gains `AssigneeIDs`, old events still have only `AssigneeID` — the fold must handle both, or
historical summarize-week output changes silently. Check `src/summarize-week-projection.js` before
declaring done.

## Done when

- `tests/reminders-multiple-assignees.test.js` covers: two-assignee create; **both** users'
  `show-me` returning it; the confirmation text matching what was actually persisted; a legacy
  single-`AssigneeID` reminder loading correctly; per-user Slack List fan-out; and completion by one
  assignee behaving per the plan doc.
- A regression test that **fails against current code** for the original symptom — the second user's
  `show-me` omitting the reminder. If it passes before the fix, it is not testing the bug.
- `npm test` green (baseline 1513/93), `npm run build` clean, `npm run validate:fsm` clean.

## Out of scope

Anything in GH-25 or GH-26 — those are p2 and p3. No refactor of the reminder module beyond what
multiple assignees requires.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): src/reminders-module.js,src/reminders-display-utils.js,src/lists-module.js,tests/reminders-multiple-assignees.test.js
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P1-TURN-2 --agent codex --paths "phases/roundup-open-issues--p1/RELAY.md,src/reminders-module.js,src/reminders-display-utils.js,src/lists-module.js,tests/reminders-multiple-assignees.test.js"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-P1-TURN-2 --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN-2 --agent codex --to agy
4. Edit ONLY these paths: phases/roundup-open-issues--p1/RELAY.md and src/reminders-module.js,src/reminders-display-utils.js,src/lists-module.js,tests/reminders-multiple-assignees.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: src/reminders-module.js,src/reminders-display-utils.js,src/lists-module.js,tests/reminders-multiple-assignees.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN-2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-P1-TURN-2 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/roundup-open-issues--p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
