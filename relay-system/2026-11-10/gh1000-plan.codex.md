# RELAY · GH-1000 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1000-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1000-EVIDENCE-LINKED-CONSOLIDATION.md` (the plan; Phases 1–4 are intentionally still "Pending plan QA")
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-10
- Definition of Done: see "Plan QA brief" below.

### Plan QA brief

**Goal.** Pre-implementation QA of the plan for umbrella issue #1000 (https://github.com/HiQS-Labs/XYZ-forge/issues/1000; read it with `gh issue view 1000 --repo HiQS-Labs/XYZ-forge` if network is available, otherwise the "Asks" are restated in the plan's Scope and Acceptance map). The issue follows #996 checklist item 6: connect execution ID, invocation ID, token, transcript, gate receipt, result receipt and attestation so one failed or resumed phase can be reconstructed from a single starting record, without a second task-state store or event writer.

**Operational envelope.** A documentation-only PR in a single-operator local developer toolkit. Grade against the issue's stated requirements and commensurate complexity. Do not ask for new tests, suites, gates or scripts (AGENTS.md "No new tests", GH-831), and do not ask for enterprise or multi-tenant machinery. The issue itself withholds authorization for migration, deletion, deployment and merging of prototypes.

**Read.** The plan in full; `AGENTS.md` (No new tests, Verified beats plausible); and spot-check the plan's Phase 0 claims against the source: `utils/py/releases_app.py` (`load_work_evidence`, `work_events`, `_record_work_event`, `cmd_work_status`), `utils/py/jog_run.py` (execution id creation, `publish_jog_receipt`), `utils/py/marathon_drive.py` (`write_terminal_result`, `save_transcript`), `MACHINE-CONTRACTS.md`, `utils/py/board_sync.py`, `utils/py/work_connectors/`, `src/flightdeck/`, `addons/paperclip-dashboard/`, and the GH-1254 records under `TESTS-RESULTS/2026-11-08+GH-1254/`, `TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/` and `relay-system/2026-11-08/marathon-gh-1254-*.md`.

**Questions.**
1. Are the Phase 0 recon claims true in the actual paths? In particular: (a) one shared reader `load_work_evidence` consumed by board policy, labels connector, Flightdeck and Paperclip; (b) the execution ID is absent from committed `work_events` payloads; (c) `marathon-drive/result@1` carries no transcript path and the only join is `head_sha` = transcript commit; (d) only approved results are copied into `TESTS-RESULTS/`. Cite file:line for anything wrong.
2. Is any requirement of issue #1000 missing from the Acceptance map, or mapped to the wrong phase? Is deferring the checklist section 4 interface demonstration and the "add only missing references" work to follow-on issues a defensible reading of "Scope now", or does the issue require them in this PR?
3. Does the plan extend the existing subsystems (PDDA plan doc, RELEASES CLI writer, `TESTS-RESULTS/` manual check) without adding a second reader, writer, store or scheduler?
4. Are the proposed dispositions in the Plan table supported by the recon, and is any of them a decision the plan should not pre-empt (for example retiring GH-402 Phase 2, or freezing Paperclip)? They are recommendations for the operator, not actions.
5. Is the verification falsifiable? Step 2's walk must be able to report MISSING, and step 3's red control (GH-1064, no execution records) must fail a walk that reports success on empty input. Is GH-1254 a sound worked example, and is the stated caveat about its unusually complete records sufficient?
6. Is the rating `45/35/50/55` grounded (appeal neutral 50 with no operator value; severity not inflated; recurrence correctly stated as not applicable)?
7. Blast radius, ordering and rollback: anything understated for a docs + one-roadmap-row change?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered, with file:line. Set STATUS to Approved if the plan can proceed.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
