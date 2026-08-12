# RELAY · Sharpen agent2agent Doorbell mode + overall skill (PR #524)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-12.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 4

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

### Review (agy)
* swept file: yes
* `[Pass]` DoD 1: Behavioral claims match `scripts/agent2agent.py`. Flags, defaults, and env vars align (e.g., `watch` and `drive` defaults match `agent2agent.py:651-661` and `678-693`; env vars match `agent2agent.py:539-546`).
* `[Pass]` DoD 2/3: The Doorbell failure paths and ownership model are addressed. Step 4 ("only after `send` — never after `close`", SKILL.md:103) and Step 3 ("On `closed` or a timeout, stop and report — do not re-arm", SKILL.md:98) perfectly handle a safe shutdown of both seats without weakening ownership.
* `[Should]` SKILL.md:99: Step 3 parenthetical says "(crash, non-zero exit)" when describing exiting without a `DECISION:`. This is slightly misleading because a timeout exit is non-zero (code 3, `agent2agent.py:445`) but *does* print `DECISION: timeout`. Change the parenthetical to something like "(e.g., a crash)" or "(non-zero exit other than timeout)" to avoid confusion.
* `[Should]` SKILL.md:143: The Send section states "Only send when `join` says `take-turn`." This technically excludes `watch`. Change to "Only send when `join` or `watch` says `take-turn`."
* `[Nit]` SKILL.md:94: Step 1 instructs to launch the background watch "only when `join` prints `wait`." It doesn't explicitly state what to do if `join` prints `closed` (though it correctly implies not to launch). Add a brief note (e.g., "if it prints `closed`, report and stop").
* `[Nit]` SKILL.md:79: The basic Watch section only mentions what to do on `DECISION: take-turn`. It would be helpful to briefly state what to do on `DECISION: closed` or `timeout` (e.g., stop and report) to match the clarity of the Doorbell section.

Verdict: Changes requested

Handing off to Producer — claude-a, go to the Producer window and say 'take your turn'

### Producer (claude-a) — r2 dispositions

* `[Should]` SKILL.md:99 misleading "(crash, non-zero exit)" — **Implemented.** Now reads "(a crash —
  don't key off the exit code alone: a timeout also exits non-zero but still prints
  `DECISION: timeout`)", which states the real discriminator: the absence of the `DECISION:` line.
* `[Should]` SKILL.md:143 Send gate excludes `watch` — **Implemented.** Now "Only send when `join`
  or `watch` says `take-turn`."
* `[Nit]` SKILL.md:94 `join` prints `closed` in step 1 — **Implemented.** Step 1 now ends
  "On `closed`, report and stop."
* `[Nit]` SKILL.md:79 basic Watch section silent on `closed`/`timeout` — **Implemented.** Now "on
  `DECISION: closed` or `timeout`, stop and report."

All four landed in `skills/agent2agent/SKILL.md` (committed alongside this turn). No findings declined.

Handing off to Reviewer — agy, final re-review against the same Definition of Done.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
