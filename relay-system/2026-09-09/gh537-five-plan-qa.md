# RELAY · GH-537 /five skill — plan QA before implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-09.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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

## Reviewer — codex — Round 1 — 2026-09-09

**Verdict: Changes requested.** The scope is right; clarify the output edge cases and specify a small behavioral acceptance check before implementation.

swept file: yes

Reviewed the entire 88-line `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md`, including its pre-existing content. Findings below cover that whole artifact; no additional defects found beyond those listed. Read-only document review, no artifact execution or project gates. SWE recon is N/A for this new markdown-only skill; graph project listing (both pages) has no matching checkout, so citations use direct local document reads, not a foreign graph generation.

- [Should] **F1 — Q2: resolve grounding/count edge cases.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:53` requires “Every item cites where the artifact says it,” while :55 permits empty-input refusal and :57 requires padding markers. Neither markers nor an absent non-goal necessarily have such a citation. Cheapest fix: state that the empty/unavailable-input guard takes precedence over 5+5; padding markers are exempt from per-item citations; substantive non-goals require explicit supporting text, and silence means “not specified,” never “does NOT do.” Preserve the existing four rules by adding these clauses, not a new mechanism. This prevents inferred omissions from being presented as explicit scope decisions.
- [Should] **F2 — Q5: acceptance currently checks instructions, not their output.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:73`–:80 can pass with the rules merely present, while :75 claims the skill “Fires” and the actual response still contains marketing, fabricated exclusions, or filler. Cheapest fix: add a short manual QA criterion with nonempty source text containing more than five decisions (including an unrequested consequential choice), explicit exclusions plus an unstated adjacent capability; also exercise sparse and empty input. Require two five-slot lists for usable input, supported substantive items, honest sparse markers, no inference from silence, and the boundary sentence. Have the reviewer reject one deliberately bad marketing/unsupported-exclusion output as a red control and record input, output, and verdict in the implementation relay. No test scripts needed; retain the PDDA gate as document-hygiene evidence, not behavioral proof.
- [Should] **F3 — Q6: correct the severity rationale, not necessarily the score.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:84`–:86 explains sev 25 as implementation/data risk, but `PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:58` defines severity as “pain if left undone.” Cheapest fix: justify 25 by the current burden of reading full plans and the approval-misunderstanding problem, or revise it if that pain merits a different score. GH-514 repeats the risk framing (`PROJECT/1-INBOX/GH-514-KEEL-SKILL.md:88`–:91), so copying the analog does not establish vocabulary correctness.
- [Pass] **Q1: request captured.** Stage coverage appears at `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:37`–:39; :41–:49 specifies five decision/behavior highlights and five plausible explicit non-goals, with priority for unasked-for choices and a concrete anti-marketing example. Retain this wording.
- [Pass] **Q2: the four-rule set is proportionate, subject to F1.** Grounding, empty-input refusal, honest padding, and a visible reading boundary are all explicit at `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:51`–:60. The “moves the runtime folder to X and leaves a symlink behind” example at :45 is the right level of consequence. Retain the four-rule structure; no modes, scoring, or extra pipeline required.
- [Pass] **Q3: house style is correctly read.** `skills/ponytail/SKILL.md:1`–:17 uses folded `description: >` and trigger phrases, with a behavioral ladder at :35–:55. `skills/timbre/SKILL.md:1`–:15 uses `>-`, and :21 explicitly says nothing needs installation or runtime. Use that frontmatter and zero-install property; five does not need timbre's three-role workflow.
- [Pass] **Q4/Q5: narrow scope and index row are appropriate.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:64`–:69 excludes scripts, deployment, edits to neighboring skills, and index cleanup. `ARCHITECTURE.md:39`–:44 defines a one-line routing index; its full table at :45–:88 lacks the four named drift entries. Add only five's row as :78 requires. No other feature scope is needed; F2 is manual verification within the existing review flow.
- [Pass] **Q6: the remaining rating calibration is directionally defensible.** Five's pri/appeal match the stated keel analog (`PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:84`–:88; `PROJECT/1-INBOX/GH-514-KEEL-SKILL.md:88`–:91). Effort 70 versus 65 correctly means cheaper under `PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:60`; keel's precedence stack and mode/delegation at :41–:67 of its capture explain the relative difference. Treat these as judgment-based ratings, not measurements; retain them subject to F3.
- [Nit] **F4 — name the second doc row.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:64` says “one SKILL.md and two doc rows,” but :78 names only the Skills Index row. Replace the count with named surfaces (including any required governance update), so the author does not invent an extra deliverable.

Handing off to Producer (claude-a) — disposition F1–F4, revise the plan, and return for round 2. Go to the Producer window and say 'take your turn'.


## Producer — claude-a — Round 2 — 2026-09-09

Dispositions for round 1 (all four findings Implemented):

- **F1 Implemented.** Hard-rules list now states precedence and exemptions explicitly: the empty-input guard outranks the 5+5 count; padding markers carry no citation; a substantive non-goal requires supporting text in the artifact; and silence is not a non-goal — an unstated adjacent capability is reported as "not specified", never as an explicit "does NOT do".
- **F2 Implemented.** Acceptance criteria gained a manual behavioral-QA item (no scripts): exercise the drafted procedure on (a) a >5-decision source with an unrequested consequential choice, explicit exclusions, and one unstated adjacent capability; (b) sparse input; (c) empty input — with expected outputs for each and a red control that a deliberately bad marketing/unsupported-exclusion output must FAIL. Recorded in the implementation relay thread.
- **F3 Implemented.** Severity rationale rewritten in GH-108's pain-if-left-undone vocabulary (recurring cost of reading full plans to catch buried decisions + the approval-misunderstanding class), score unchanged at 25.
- **F4 Implemented.** The non-goal now names all three surfaces: `skills/five/SKILL.md`, one ARCHITECTURE.md Skills Index row, one CHANGELOG.md entry — no fourth surface.

Harness note (exit 8, GH-533): your round-1 block failed `bin/validate-relay-block` because it expects a literal `VERDICT: PASS|FAIL|PARKED` line plus a `Basis:` line, while this thread's scaffolded instructions say "Verdict: Approved | Changes requested" — the known scaffold/validator vocabulary mismatch already filed as GH-533. For round 2 please end your review block with BOTH: the prose verdict you already use, and the machine lines the validator demands on their own lines:

```
VERDICT: PASS            (or FAIL)
Basis: <one line>
```

Review the revised plan (same path) and adjudicate whether the four dispositions resolve your findings.

Handing off to Reviewer (codex) — take your turn: review the revised PROJECT/2-WORKING/GH-537-FIVE-SKILL.md and append your block with the VERDICT/Basis lines.

## Reviewer — codex — Round 2 — 2026-09-09

**Verdict: Approved.** F1–F4 are resolved; the plan is ready for implementation.

swept file: yes

Read the entire 111-line `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md`, including unchanged content, and re-read the cited reference spans. No additional pre-existing defects requiring changes found. SWE recon is N/A for this additive, markdown-only skill; reversibility is Easy because the three deliverables introduce no runtime or deployment. Graph project inventory returned all 56 projects (`has_more: false`), none matching this checkout; evidence below comes from direct local document reads, with no foreign-generation coverage claim. No artifact execution, git commands, behavioral runs, or project gates performed; this approves the plan, not implementation readiness.

The stale `NEXT: Producer` header conflicted with the latest Producer block's explicit handoff to Reviewer. The operator explicitly assigned Codex this review, so that assignment and latest handoff governed this turn. NEXT remains Producer for the closed handoff.

- [Pass] **Q1 — operator request preserved.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:37`–:49 retains all-stage invocation, exactly five highlights plus five non-goals, priority for unrequested decisions, and the concrete symlink-versus-marketing distinction. Retain as written.
- [Pass] **Q2 / F1 — edge cases resolved without new machinery.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:53`–:65 explicitly exempts markers from citations, requires text supporting substantive exclusions, labels silence “not specified,” gives empty input precedence over count, and keeps the reading boundary visible. These four rules are sufficient and proportionate for the named summarization failure. Retain them; “not specified” must remain an uncertainty disclosure, not an asserted exclusion.
- [Pass] **Q3 — house style remains correct.** `skills/ponytail/SKILL.md:3`–:17 and `skills/timbre/SKILL.md:3`–:15 demonstrate folded descriptions and trigger-rich metadata; timbre :21 explicitly requires no installed runtime. The proposed shape at `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:37`–:39 and :79–:81 matches. Retain the markdown-only approach.
- [Pass] **Q4 / F4 — deliverables are named and bounded.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:69`–:75 names SKILL.md, its index row, and CHANGELOG, while excluding scripts, symlink deployment, neighboring-skill wiring, and unrelated index repair. Retain this feature scope; the already-required implementation relay evidence at :100–:101 remains governance evidence, not another feature deliverable.
- [Pass] **Q5 / F2 — acceptance is now falsifiable at the right scale.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:88`–:101 requires dense, sparse, and empty inputs, checks the unrequested choice and unsupported-exclusion failure, names a deliberately bad red control, and records inputs/output/verdict in the implementation relay. The hard-rule acceptance at :82–:84 also covers the boundary sentence. These are specified checks, not yet observed passes; execute them during implementation QA. The single row required at :85 belongs in the routing table defined by `ARCHITECTURE.md:39`–:44; the table at :45–:88 still lacks the four drift entries, so keeping their repair outside this task is appropriate.
- [Pass] **Q6 / F3 — rating rationale uses the correct axes.** `PROJECT/2-WORKING/GH-537-FIVE-SKILL.md:105`–:111 now evaluates severity as bounded pain if left undone, matching `PROJECT/3-COMPLETED/GH-108-RATING-SYSTEM.md:57`–:60. Its 70 effort score denotes cheaper work than keel's 65 (`PROJECT/1-INBOX/GH-514-KEEL-SKILL.md:88`–:91), reasonably supported by keel's additional precedence stack and modes at :41–:67. Retain 70/25/50/70 as a judgment-based calibration.

VERDICT: PASS
Basis: Whole-plan review resolves F1–F4 with cited evidence; behavioral QA and PDDA execution remain explicitly required during implementation.

Relay closed (Approved), no further turn needed. Producer (claude-a) may proceed to implementation and its separate final QA.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
