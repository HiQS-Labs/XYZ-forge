# RELAY · GH-537 /five skill — plan QA before implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-09.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh537-five-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-537-FIVE-SKILL.md (the implementation plan for issue #537, the "five" skill)
- Reference material (read for house-style comparison): `skills/ponytail/SKILL.md`, `skills/timbre/SKILL.md`, `ARCHITECTURE.md` (→ "Skills Index"), `PROJECT/1-INBOX/GH-514-KEEL-SKILL.md` (the rating-calibration analog)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-09
- Definition of Done: the capture doc's "Acceptance criteria" section — a zero-install `skills/five/SKILL.md` with folded block-scalar frontmatter and trigger-rich description; 5+5 contract, grounding rule, empty-input guard, no-filler rule, checksum-not-substitute boundary as hard rules; one-line ARCHITECTURE.md index row; zero new scripts; pdda.sh run clean after promotion.

## Questions for the Reviewer to adjudicate (answer each, with file:line citations)

1. Does the plan faithfully capture the operator's request: a skill callable during project planning/writing/implementation that outputs exactly 5 key highlights of the plan/feature/fix plus 5 things it explicitly does NOT do?
2. Are the four hard rules (grounding citation, empty-input guard, exactly-five-and-five with honest "nothing else load-bearing" markers instead of filler, checksum-not-substitute) the right and sufficient set to prevent the named failure mode — an agent returning marketing bullets instead of the load-bearing decisions? Anything missing, redundant, or overwrought?
3. Is the house-style read correct: a zero-install markdown skill in the shape of `skills/ponytail/SKILL.md` (behavioral lens, no scripts/runtime), with frontmatter per the folded block-scalar convention? Compare against the two reference skills.
4. Are the task's non-goals correct and complete (no scripts, no global symlinks, no wiring into existing skills, no ARCHITECTURE.md drift fix beyond its own row)? Any scope that should be in or out?
5. Are the acceptance criteria falsifiable and sufficient for a doc-only change? Is adding the one-line ARCHITECTURE.md → Skills Index row the right call given the index's known drift (timbre/unstuck/workhorse/merge-cleanup are missing from it — tracked separately under #453)?
6. Is the rating `rated 70/25/50/70` grounded against its stated calibration (GH-514 keel at 70/25/50/65) and the repo's four-axis vocabulary?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
