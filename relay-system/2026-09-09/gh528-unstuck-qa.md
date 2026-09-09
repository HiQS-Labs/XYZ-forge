# RELAY · GH-528 unstuck hardening QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-09.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh528-unstuck-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/unstuck/SKILL.md` (commit 7fe9b1f0, branch feat/gh528-unstuck-queued-tripwire; the diff vs origin/development is 13 inserted lines — `git diff origin/development..HEAD -- skills/unstuck/SKILL.md`)
- Supporting context: `PROJECT/2-WORKING/GH-528-UNSTUCK-QUEUED-TRIPWIRE.md` (plan + acceptance), `skills/workhorse/SKILL.md` (the ladder the tripwire hands off to), issue #528.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-09
- Definition of Done: the three edits satisfy issue #528 (fan disposition / recurrence tripwire / receipt line) without adding execution machinery, triggering changes, or blurring the routing boundary; wording is airtight against the two known misuse modes below; the whole file still reads as a one-page interrupt.

## Review questions — adjudicate each, cite file:line or quoted span

1. **Fan disposition (Rung 3 addition):** does "rank by critical path, act on the first, route the rest to existing durable intake" actually prevent the 2026-09-09 failure (four genuine blockers, three with no durable home, operator had to say "file issues yourself")? Could a model still legitimately skip filing the queued items?
2. **Queued vs parked:** is the queued/parked distinction load-bearing and unambiguous, or could "queued" be read as permission to drop real blockers?
3. **Recurrence tripwire (Rung 4 addition):** does "second same-class occurrence ⇒ /workhorse handoff or labeled bounded bridge" actually break the symptom-relief loop? Is "class of blocker" defined tightly enough that a model can't widen or narrow it opportunistically?
4. **Routing boundary:** do the additions make unstuck *do* engineering work (which belongs to workhorse), or do they only classify and route? Check against the Routing boundary section and workhorse's escape hatches.
5. **Receipt:** does the new `Queued:` line fit the receipt's evidence contract (one line, observable state)?
6. **Whole-file sweep (GH-268):** pre-existing defects in `skills/unstuck/SKILL.md` are in scope — declare `swept file: yes|no`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
**agy (Reviewer) — Round 1**

swept file: yes

* `[Should]` **Fan disposition (Q1):** The word "route" in Rung 3 (line 95: "route the rest to the work's existing durable intake") is ambiguous and an LLM might interpret it as just categorizing the blocker without writing it down, leading to the same failure. Fix: change "route the rest to" to "file or record the rest into".
* `[Pass]` **Queued vs parked (Q2):** The distinction is unambiguous on lines 96-97: "queued items are real outstanding work with a recorded home; parked items are cogs or polish that may never be done."
* `[Pass]` **Recurrence tripwire (Q3):** Tying the definition of class to documented evidence (lines 110-111: "If the ledger, changelog, or issue history shows this blocker's class was narrowly fixed before") is tight enough to prevent opportunistic redefinition.
* `[Pass]` **Routing boundary (Q4):** Lines 111-112 correctly maintain the boundary by explicitly commanding a handoff ("hand the thread to `/workhorse` for the durable root-cause fix") rather than executing engineering work in-place.
* `[Pass]` **Receipt (Q5):** Line 139 (`Queued: <genuine blockers routed to durable intake, or none>`) fits the single-line observable evidence contract. Note: if Q1 is fixed, you should also update line 139 to say "genuine blockers filed to durable intake".
* `[Pass]` **Whole-file sweep (Q6):** Swept the rest of `skills/unstuck/SKILL.md`; found no pre-existing defects.

**VERDICT:** FAIL
**Basis:** Rung 3 language is ambiguous.
handing off to Producer — go to the claude-a window and say 'take your turn'

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
