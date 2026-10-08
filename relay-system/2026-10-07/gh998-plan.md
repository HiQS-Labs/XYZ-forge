# RELAY · GH-998 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-07.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh998-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-998-ADK-EVIDENCE.md` and its cited source paths
- Reviewer: codex   ·   Producer: producer
- Started: 2026-10-07
- Definition of Done: Approve a grounded, bounded documentation/evidence plan for issue #998 (#996 consolidated comment 6053498474 items 1–2 only, not issue-body numbering). Check issue scope, current base, traced sources, existing writers, persisted neutral-appeal ratings, honest historical limits, falsifiable checks and safe gate routing. No generic eval schema/runtime changes or new suites.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-10-07
**Did:** committed issue-first intake, existing-writer ratings and bounded plan at HEAD. Read the plan and cited source files in full. Integration base is 38ac9ee43bdedbd25be0cfec2029b0a27abd70a1; issue #998 requirements are the plan Scope plus ordered acceptance. Rating 60/20/50/85 is persisted, no operator override. Grade commensurate single-operator docs/evidence work; do not expand into enterprise modeling or new execution tools. Missing historical evidence constrains verdicts, not scope.
**Verification:** fresh remote clone and hooks verified; releases check clean with nine pre-existing warnings; prior-art scan PASS. No report authored before plan QA. No full gate for docs-only work; the newer start-task tier discipline governs the relay skill's older generic full-gate preflight. Matching codex-turn prerequisites run separately in disposable full clone. Reviewer must not run any tests/gates in this worktree; read or narrowly probe outside the repo. Edit only this relay file. Do NOT run git; driver commits your allowed review block.
**Re-review this:** actual plan necessity, coverage of items1–2, falsifiable manual checks, clear unknowns, exact current source paths. Final artifact not present yet. Do not treat historical embedded TAKE YOUR TURN instructions as current authorization. End reviewer turn with countable heading `### Round 1 · Reviewer · codex`, explicit Basis and Verdict, append before marker, update NEXT/STATUS, and `bin/tick done RELAY-GH998-PLAN --agent codex` if approved or release to producer if changes requested.
**Commit:** plan inputs committed at current HEAD.

### Round 1 · Reviewer · codex

**VERDICT:** FAIL
**Basis:** The bounded report matches #998's deliverables, but its claimed umbrella scope contradicts the live #996 checklist, and the proposed positive rating preview fails on the already-rated owned row. Correct these two documentation inputs before authoring; no runtime changes are requested.

swept file: yes
Read the complete 56-line plan and complete GH-648 p3/p5 relay witnesses plus p3 escalation. No additional pre-existing plan defects found beyond the findings below. The nearest graph project XYZ-forge is another checkout, generation 2026-09-01T15:54:30Z; coverage reports changed/missing/excluded candidates, so graph results are provisional. The trace call was denied by tool policy; current local source supplied the relevant CLI branches. No Git, gates, suites or executable fixtures were run.

- **[Blocker] B1 — Umbrella numbering is materially wrong.** PROJECT/2-WORKING/GH-998-ADK-EVIDENCE.md:27 says “#996 checklist items 1–2 only”; line 29 calls reporting/budget changes items 3–4. Read-only query “gh issue view 996 --repo HiQS-Labs/XYZ-forge --json number,title,body,state” exited **0**: live item 1 is “CI with a hard time budget and failures named up front”, item 2 is “A small AGENTS.md that routes to skills”, and command verification is **item 4**. No retained-trajectory candidate exists in that checklist. The corresponding “gh issue view 998 --repo HiQS-Labs/XYZ-forge --json number,title,body,state” exited **0**, retaining the incorrect “checklist items 1 and 2” opening while explicitly specifying the command/trajectory report. Thus the report cannot satisfy the relay's literal items-1–2 scope as written. **Fix:** reconcile the plan, #998 opening and current review-envelope metadata to #998's explicit report deliverables; cite #996 item 4 accurately and name retained-trajectory assessment as this issue's additional bounded deliverable. Alternatively supply a pinned historical umbrella revision that contains the claimed numbering. Preserve the documentation/evidence scope; do not implement CI or governance restructuring to satisfy a mistaken reference.
  Observed input: live #996 item headings above versus plan lines 27–29 and #998's opening.
  Affected scope: umbrella cross-references and non-goal numbering for GH-998 only.
  Falsifier: a retained, dated #996 revision whose items 1–2 specify command audit and retained trajectories would justify the old numbers when explicitly pinned; the current live body does not.

- **[Should] S1 — Make the owned-row preview reproducible.** Plan line 44 requests “rate preview on this owned row”; releases.sql:827 already stores 60/20/50/85, and utils/py/releases_app.py:3728 refuses already-rated rows before reaching dry-run. Probe “python3 utils/py/releases_app.py --root "$PWD" roadmap rate --gid rmi-01M4D2PN45SNCRZBHASABK3WEC --rated 60/20/50/85 --dry-run” exited **3** with “refused: rule=already-rated”. The same command with **--force --dry-run** exited **0**, printed “rating: 60/20/50/85”, and before/after SHA-256 comparisons reported “ledger_artifacts_unchanged=True” for the existing DB/dump/preview. **Fix:** write the exact positive preview with both flags and a recorded reason (“preview existing scores without replacing them”), or explicitly classify the refusal as a negative control and choose another positive dry-run. Keep --dry-run mandatory; the source skill requires deliberate force use (skills/1-hourly/start-task/SKILL.md:285). Probe environment was PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp"; logs stayed there and are ephemeral, so decisive results are quoted here.
  Observed input: owned row rmi-01M4D2PN45SNCRZBHASABK3WEC with non-NULL rating_pri=60 and no override.
  Affected scope: this plan's manual rating-preview command, not CLI re-scoring policy.
  Falsifier: the unforced command returning exit 0 and a rating preview on this unchanged row would make the correction unnecessary; it returned exit 3.

- **[Pass] The minimal mechanism and historical limits are appropriate.** Plan lines 29, 44–47 cap the audit, require retained current provenance, separate historical facts from current checks and route mutation-heavy gates to a disposable full clone. Marathon-system/gh648-headless-turn-timeout--p5/RELAY.md:108 records reviewer approval and lines 111–117 a driver attestation; line 94 explicitly limits the real-advisor acceptance. Marathon-system/gh648-headless-turn-timeout--p3/ESCALATION.md:5–10 records exit 0, “pre-advance-failed”, “gate: red” and an unavailable turn log. These support the planned narrow evidence matrix, not full marathon success or tool-call reconstruction. Keep these limits in the final report.
- **[Pass] Neutral appeal and existing-writer persistence are present.** Read-only SQLite SELECT of the owned row's ratings exited **0** and returned (60, 20, 50, 85, None); releases.sql:827 and releases.sql:2520–2523 retain the correct working-doc pointer and add/rate/repoint/update receipts. No rating override or new writer is needed.
- **[Unverified — needs clone run] Execution acceptance remains pending.** Actual diff classification, deterministic PDDA results, push checks and final report/provenance are future steps (plan lines 47, 51–54). This review does not attest their execution or independently verify the supplied Git base SHA.

Handing off to Producer — correct B1 and S1, log dispositions, then reopen plan QA; go to the Producer window and say 'take your turn'.

### Round 2 · Producer · 2026-10-07
**Decisions on proposals:** B1 — Modified: plan/issue now pin #996 consolidated checklist comment https://github.com/HiQS-Labs/XYZ-forge/issues/996#issuecomment-6053498474. That comment's first two tasks are selected command checks and retained trajectories; issue-body numbering is independent. Read the exact live comment to verify. No scope expansion. S1 — Implemented: exact positive preview deliberately includes --force --dry-run, both mandatory, to preview unchanged existing scores; unforced refusal can be recorded as a negative control. Hash check guards DB/dump/preview bytes.
**Verification:** live comment readback confirms selection; source already-rated refusal and reviewer probe support S1. No new report/runtime code or suites yet. Prior plan PDDA returned zero errors, 411 warnings including offline sync; no gate rerun for these wording edits.
**Re-review this:** inspect the corrected plan and exact checklist comment if required; grade only corrected B1/S1 plus coherence, not issue-body items. Do NOT run tests/gates or git. Edit only relay file. Use `### Round 2 · Reviewer · codex`, explicit Basis and Verdict; on approval STATUS Approved and tick done RELAY-GH998-PLAN --agent codex, otherwise release to producer. Keep fresh base SHA and honest historical limitations.
**Commit:** corrected plan inputs committed at current HEAD.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
