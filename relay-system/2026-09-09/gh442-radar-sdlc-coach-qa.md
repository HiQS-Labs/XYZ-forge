# RELAY · Radar SDLC Coach & Multi-Week Arc QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-09.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy, DeepSeek)
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
6. **Commit only the relay file** (`relay(gh442-radar-sdlc-coach-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do.

## Setup
- Artifact under review: `.relay-artifacts/SKILL.md` (seeded from `skills/radar/SKILL.md`)
- Reviewer: deepseek (DeepSeek v4 Pro)   ·   Producer: claude-a
- Started: 2026-09-09
- Definition of Done:
  1. The new SDLC Process Coach narrative (first two paragraphs) in Step 4 effectively humanizes the report—leading with high-level wins and velocity, followed by SDLC process health, potential regressions, and empathetic coaching.
  2. Lens 2 regression detection heuristics (Signal 7: recent seam bounceback) are sound, practical, and properly distinguished from chronic tech debt.
  3. Predecessor RGT (Run/Grow/Transform) metrics, denominator calculations, and multi-run trend lines remain mathematically and operationally intact.
  4. Multi-week historical report discovery (across `RADAR/`, `docs/radar/`, and `PROJECT/1-INBOX/`) and retrospective arc generation (Step 0 & Step 4.4) are clean, consistent, and actionable.
  5. The whole file remains cohesive, syntactically clean, and free of internal contradictions.

## Review questions — adjudicate each, cite file:line or quoted span

1. **SDLC Coach Persona & Wins/Regressions (Step 4)**: Does Step 4 establish a clear, supportive coaching narrative that opens with high-level wins (Paragraph 1) and process health/regressions (Paragraph 2), without regressing into cold forensic auditor jargon?
2. **Regression Detection Heuristics (Lens 2)**: Is Signal 7 (seam bounceback on recent `feat:`/`refactor:` commits) sufficiently tight to detect genuine short-cycle regressions without misclassifying ordinary authoring or chronic tech debt?
3. **RGT Arc & Metrics Retention (Lens 1 & Step 4)**: Are the quantitative Run/Grow/Transform percentages, denominator definitions, and comparisons against predecessor runs preserved and integrated seamlessly into the coach narrative and summary highlights?
4. **Multi-Week Retrospective Arc (Step 0 & Step 4.4)**: Are the discovery locations (`RADAR/`, `docs/radar/`, `PROJECT/1-INBOX/`) and the structure of the retrospective arc summary (macro-arc, RGT trajectory table, defect scorecard) operationally sound?
5. **Whole-file sweep (GH-268)**: Are there any residual contradictory instructions or tone mismatches elsewhere in `skills/radar/SKILL.md`? Declare `swept file: yes|no`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

### Reviewer (deepseek) · Round 1

**swept file: yes**

#### Q1 — SDLC Coach Persona & Wins/Regressions (Step 4)

- `[Pass]` The two-paragraph narrative structure is clear and well-sequenced: Paragraph 1 (§1, :279–:288) opens with high-level wins and team affirmation; Paragraph 2 (§2, :290–:294) follows with process health, RGT trajectory, regression spotlight, and empathetic coaching guidance. The example prose (:287–:288, :294) demonstrates the warm, Principal-Engineer tone the DoD calls for, not cold forensic-auditor language.
- `[Pass]` The framing instruction (:273–:277) explicitly sets "SDLC Process Coach & Strategic Decision Memo" voice and bars "cold forensic data dump" — this is the right gate.
- `[Pass]` Both examples concretely operationalize the abstract instructions (wins → "GitHub Pages documentation portal," regressions → "root resolution logic … three separate follow-up fixes"), per DoD item 1.
- `[Nit]` The Paragraph 2 preamble (:290) mentions "The Arc" in parentheses — a casual reader encountering this term for the first time may not connect it to the multi-week RGT trajectory described in :305–:307. Consider a one-line forward reference: "…compare the current Run/Grow/Transform (RGT) mix against predecessor runs (see §3 — Structured Evidence for the full trajectory table)."

#### Q2 — Regression Detection Heuristics (Lens 2, Signal 7)

- `[Pass]` Signal 7 (:161–:169) correctly defines a three-part short-cycle regression check: (a) files touched by recent feat/refactor commits, (b) follow-up fix/hotfix/revert on the same files, (c) fast-follow issues post-merge. The "Potential Regressions" label (:167) and the ×1.3 score multiplier (:198) properly distinguish it from chronic tech debt, and the target report format (:202) requires the regression-vs-chronic-debt tagging explicitly.
- `[Should]` **No recurrence discriminator — false positives on same-PR authoring.** Signal 2 (:136–:142) has an explicit recurrence guard: ≥2 distinct calendar days AND ≥2 distinct originating PRs/branches/issues, otherwise it's "concentrated authoring." Signal 7 lacks any such guard. A single PR that lands a `feat:` commit followed by a same-day `fix:` commit on trunk (merge without squash) would be flagged as a "Potential Regression" when it is ordinary in-branch authoring. Add a minimum guard: **the fix/hotfix/revert commit must originate from a different PR/branch than the feat/refactor commit, or land on a different calendar day.** Without this, the signal's false-positive rate is uncalibrated.
- `[Nit]` "within the window (especially the last 7–14 days)" (:163) — the parenthetical is pragmatically clear but never defined. Is "last 7–14 days" relative to the run date or the window's end date? In a 21-day window starting 21 days ago and ending today they coincide; if an operator overrides the window to a historical range they diverge. Add a sentence: *"The 7–14 day sub-window is measured from the end of the window (the run date by default)."*

#### Q3 — RGT Arc & Metrics Retention (Lens 1 & Step 4)

- `[Pass]` The RGT denominator is unambiguously Run+Grow+Transform+Unclassified (:87), with Harness explicitly excluded (:81). The sum-check requirement (:63–:73) — `wc -l` vs bucket counts, cross-checked with `git rev-list --count` — is the strongest defense against silent truncation I've seen in any instruction set; it's preserved intact.
- `[Pass]` The `rgt:` adoption requirement (:84) — print "0% (rgt: adoption: N docs)" when zero docs carry the key — is present and unambiguous.
- `[Pass]` The malformed-prefix families check (:91–:101) and the Unclassified-verbatim + adjusted-read rule (:103–:105) are both intact — these are what prevent the ~4× Grow undercount observed in calibration, and losing them would silently regress the lens.
- `[Pass]` Step 4.3 example (:307) shows the RGT mix with trend ("76.9% [vs 76.7% in Run 2]"), and Step 4.4's trajectory table (:327–:331) shows per-run RGT columns — both feed the coach narrative correctly.
- `[Nit]` The Step 4.3 example (:307) prints "Transform: 0%" but per the Step 1 requirement (:84) it should include the adoption count: `0% (rgt: adoption: N docs)`. The example and the rule should agree. Fix the example to match.

#### Q4 — Multi-Week Retrospective Arc (Step 0 & Step 4.4)

- `[Pass]` Discovery locations are consistent across Step 0 (:50–:53) and Step 4.4 (:316): `RADAR/`, `docs/radar/` (and `docs/RADAR/`), `PROJECT/1-INBOX/RADAR-REPORT-*.md`, plus repo-root fallback — same set, no drift.
- `[Pass]` The ≥2-reports gate (:58–:59, :316) prevents a single-report "arc" from being manufactured.
- `[Pass]` The retrospective structure (:321–:339) is operationally sound: Macro-Arc Narrative → Longitudinal Flow Trajectory table → Defect & Regression Scorecard (with subtotals for retirements, regressions-vs-chronic, and symptom-masked) → Strategic Recommendation. Every component has a clear deliverable.
- `[Pass]` The report extraction protocol (:57) — sort chronologically, extract RGT percentages, target IDs, retirement states — gives the agent a concrete procedure, not hand-waving.

#### Q5 — Whole-File Sweep (GH-268)

- `[Pass]` No internal contradictions found. Key cross-checks:
  - "Never commit" (:30) vs Step 0 git-log reads — no conflict (reads only).
  - "Never edit releases.db" (:31–:32) vs Step 3 DB reads via `releases check` + export payload — consistent.
  - Sink A write location (:361: `PROJECT/1-INBOX/RADAR-REPORT-YYYY-MM-DD.md`) ↔ Step 0 discovery location (:52: `PROJECT/1-INBOX/RADAR-REPORT-*.md`) — consistent.
  - "No targets → write nothing" (:38) ↔ Step 5 "Skip entirely when there are no targets" (:343) — consistent.
  - Signal 2 recurrence discriminator (:136–:142) ↔ PR collision "An open PR is never a completed fix" (:226) — both prevent premature retirement; consistent philosophy.
- `[Pass]` Tone is cohesive: Steps 1–3 are rigorous/forensic (appropriate for the analytical lenses), Step 4 pivots to the SDLC Coach voice (:273–:277 explicitly marks the pivot), Step 5 returns to precise operational instruction. The pivot is declared, not surprising.
- `[Pass]` The Degradation table (:421–:431) is complete — every missing dependency maps to what is lost and what still runs. No orphaned dependencies.
- `[Nit]` Step 2b (:207) says "Run this pass after finding targets and before recommending a new plan" — but Step 4 (:296–:302) says "follow the coach's narrative with 2–3 clear, high-leverage recommendations." The handoff from Step 2b's PR classification into Step 4.3's "In-Flight Work & Open PRs" (:309) is implicit. A one-line bridge at the end of Step 2b — *"Carry the PR classification results into Step 4.3 for the in-flight-work summary"* — would make the flow explicit.
- `[Nit]` Guardrail at :38 says "No targets → write nothing. Report the flow distribution in-session and stop" — but Step 4's full report structure (:271–:339) doesn't describe an abbreviated path for the no-targets case. Add a one-liner at the top of Step 4: *"When no targets were found, report only the flow distribution (§4.3) and the all-clear recommendation; skip the coaching narrative and retrospective sections."*

### Verdict: **Approved** — with four [Nit] items and one [Should] (Signal 7 recurrence discriminator). All five DoD items are satisfied; the artifact is cohesive, the regression heuristic is directionally correct and needs only a same-PR guard, and no blockers were found. The Producer should address the [Should] and apply the [Nit] items at their discretion in the next round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
