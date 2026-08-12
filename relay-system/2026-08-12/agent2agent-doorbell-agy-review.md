# RELAY · Sharpen agent2agent Doorbell mode + overall skill (PR #524)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-12.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(agent2agent-doorbell-agy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/agent2agent/SKILL.md` (primary — includes the NEW "Doorbell" section
  added on this branch for PR #524). Read `skills/agent2agent/scripts/agent2agent.py` as ground truth
  for behavior claims; it is context, not an artifact to grade.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-12
- Definition of Done:
  1. Every behavioral claim in SKILL.md matches `scripts/agent2agent.py` (commands, flags, defaults,
     `DECISION:` values, watch/drive caps, env vars) — cite the script line for any mismatch.
  2. The new Doorbell section is executable cold: an agent that has never seen this repo can follow
     steps 1–4 without guessing. Ambiguities, missing failure paths (e.g. what if the background watch
     dies rather than exits with a DECISION? what if two doorbell seats re-arm against a closed
     discussion?), and unstated host assumptions are findings.
  3. Doorbell must not weaken the ownership model: confirm the section keeps all writes behind
     `send`/`close` and never implies `watch` writes or locks.
  4. Overall skill sharpness: redundancy, ordering, anything a cold reader would misread — [Should]/[Nit].
  5. Blockers only for wrong-behavior claims or safety weakening; grade everything else honestly.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Review (agy)
* swept file: yes
* `[Should]` SKILL.md:92: Step 1 ("Join once via the pasted invitation, as normal.") is ambiguous if the `join` command returns `DECISION: take-turn`. A cold reader won't know whether to process the turn immediately (as per the "Join" section) or proceed to Step 2 and launch a background `watch`. Clarify whether to process the turn immediately or to always launch the `watch`.
* `[Should]` SKILL.md:95: Step 3 ("When the background `watch` exits... read the printed `DECISION:`") misses a failure path. If the background `watch` dies (e.g. non-zero exit code) and no `DECISION:` is printed, a cold agent might guess or hang. Explicitly instruct the agent to stop, report the error, and not re-arm.
* `[Nit]` SKILL.md:98: Step 4 ("Re-arm as part of the send step... in the same turn you `send`") could lead to re-arming after closing the discussion if the agent considers `close` a form of sending. Add a quick clarification (e.g., "(do not re-arm if you use `close`)").

Verdict: Changes requested

### Producer (claude-a) — r1 dispositions

* `[Should]` SKILL.md:92 join-returns-take-turn ambiguity — **Implemented.** Step 1 now says: on
  `DECISION: take-turn` from `join`, take the turn immediately (step 3's send-and-re-arm) and launch
  the background `watch` only on `wait`.
* `[Should]` SKILL.md:95 watch-dies-without-DECISION failure path — **Implemented.** Step 3 now ends
  with: on an exit with no `DECISION:` line (crash, non-zero exit), do not guess, do not re-arm
  blindly; rerun `join` read-only to learn the real state and report the failure to the operator.
* `[Nit]` SKILL.md:98 re-arm-after-close — **Implemented.** Step 4 now reads "only after `send` —
  never after `close`; a closed discussion has no further turns."

All three landed in `skills/agent2agent/SKILL.md` (commit alongside this turn). No findings declined.

Handing off to Reviewer — agy, re-review the Doorbell section against the same Definition of Done.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
