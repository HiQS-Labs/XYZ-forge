# RELAY · GH-508 pulse projection spike QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-09.
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
6. **Commit only the relay file** (`relay(gh508-spike-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-508-GIT-PULSE-SKILLS.md` (commits eb706bee + 60677adc on feat/gh508-pulse-projection-spike; `git diff origin/development..HEAD --stat` shows the full docs+ledger diff)
- Supporting context: issue #508 (acceptance checklist), `skills/skills-army-hq/scripts/intake.py` (digest contract, source validation), `skills/skills-army-hq/SKILL.md`.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-09
- Definition of Done: the spike report's six PASS claims are each backed by concrete recorded evidence (digests, commits, paths) with no overclaim; the findings section distinguishes demonstrated properties from structural arguments; no machinery was added to skills-army-hq; the doc honestly states what was NOT verified (no full hourly-writer cycle observed).  [Unverified — no citation]

## Review questions — adjudicate each, cite file:line or quoted span

1. **Evidence grounding:** does each row of the "Spike results" table cite reproducible evidence (commit SHAs, digests, paths) rather than assertions? Name any row whose evidence is thinner than its PASS claim.
2. **Honesty of limits:** the writer-coexistence claim rests on the pathspec staging list plus precedent commits (`chore(sleuth)`), not on observing a full hourly cycle — is that limitation stated clearly enough in the doc?
3. **Bytes-vs-refs finding:** is the conclusion ("bytes beat refs at skill scale") supported by the recorded operator-step counts and the offline argument, or overclaimed?
4. **Scope discipline:** confirm the repo diff adds NO new verb/daemon/DB to skills-army-hq — docs + ledger only.
5. **#506 handoff:** is the recommendation (smallest stdlib `import-projection` verb belongs in #506) stated with its cost basis (7 commands @ 3 skills, ~19 @ 15)?
6. **Whole-file sweep (GH-268):** pre-existing defects in the doc are in scope — declare `swept file: yes|no`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- GH-529 mitigation: no trailing marker — append the next block at the very end of the file -->

### Turn 1: agy (Reviewer)

**Verdict:** Changes requested

swept file: yes

- `[Pass]` **Evidence grounding (Q1):** The Spike results table cites reproducible evidence (commits like `2a200a72`, `d1ed5fe0`, HEAD `277a339f` and digests like `0ea0342209bb`). No overclaims found. (Lines 98-103)
- `[Blocker]` **Honesty of limits (Q2):** The doc structurally justifies writer coexistence via pathspecs and precedent (Line 100: "The writer stages only..."), but fails to explicitly disclose that no full hourly-writer cycle was observed. The DoD explicitly requires this. **Fix:** Add a sentence to Row 3 of the Spike results or the Recon addendum clearly stating this limitation.
- `[Pass]` **Bytes-vs-refs finding (Q3):** The conclusion is firmly supported by the step count comparison (7 vs ~19 commands) and the demonstrated offline capability. (Lines 107-116)
- `[Pass]` **Scope discipline (Q4):** Verified via `git diff` that the repo diff contains no new verb, daemon, or DB for `skills-army-hq` (docs and ledger only).
- `[Pass]` **#506 handoff (Q5):** The recommendation for `import-projection` is clearly stated and backed by the explicit cost basis of 7 commands at 3 skills vs ~19 at 15. (Lines 113-116)
- `[Nit]` **Whole-file sweep (Q6):** The six checkboxes under "Acceptance criteria" (Lines 45-52) are still unchecked (`- [ ]`), despite the Status and Spike results declaring them all PASS. **Fix:** Check them (`- [x]`).

### System · claude-a (coordinator) — 2026-09-09

Round 1's turn content stands as review record, but the turn failed structural validation
(exit 8): the verdict line was written as `**Verdict:** Changes requested` (markdown bold)
where the validator requires the literal `VERDICT:` prefix. No content was altered; the
block is preserved verbatim above.

### Turn 2: claude-a (Producer)

- `[Blocker]` Honesty of limits (Q2) — **Implemented.** Row 3 of the results table now carries an explicit **Limit:** sentence: no full hourly-writer cycle was observed; coexistence is argued structurally (pathspec staging) plus precedent, not by watching a run land.
- `[Nit]` Acceptance checkboxes (Q6) — **Implemented.** All six `- [ ]` boxes in the doc are now `- [x]` (they paraphrase the issue's checklist; the GH issue body's own boxes stay for the maintainer to tick at merge).
- Format note for the reviewer's next block (template/validator mismatch, being filed): end the block with BOTH the validator's vocabulary — `VERDICT: PASS` (or FAIL/PARKED) and a non-empty `Basis:` line — AND set the header `STATUS: Approved` if approving. The scaffold's 'Approved | Changes requested | Blocked' wording alone is rejected by bin/validate-relay-block.

handing off to Reviewer — go to the agy lane and take your turn

