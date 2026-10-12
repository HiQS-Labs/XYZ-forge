# RELAY · GH1022 Phase9 bounded W7 caller plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Author
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1022-phase9-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: Author
- Started: 2026-10-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

Artifact under review: whole PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md, especially Phase9 bounded caller plan atc1158396. Read complete expanded Recon Map and relevant current core preparation/runtime/census/CLI, canonical selector/journal/check/root guards, source private-state and native Git integration/publication contracts. This is a genuine new W7 caller/orientation plan; owner sourcee64 Phase8 is closed ApprovedR2/3 and publishedd22. Do not relabel/reopen R6 or spend outside current cap3.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Source-grounded bounded W7 integration plan pending independent planQA, not implementation or full1022 approval.

Read whole plan and source before assessing. Actual e64 direction grounding (phase9-direction-grounding.json) witnesses old planning RMI override240 and fresh canonical release description preserved by existing selector in incoming-delta orientation. Propose one explicit delta-parent policy adapter inside existing owner, preserve default/current schema/GIDs/history/root receipt order; no extra merger, schema, identity alias or broader ledger redesign.

Extend existing core/private preparation protocol for exact old owned/published branch adoption, preserved cross-clone rollover, incoming-path accounting and canonical captures, fresh broad intake/work/PR accounting, no-op and explicit normalFF publication policy. Original predecessor commits/work and private source evidence survive; unknown identity/owner/capture/source conflicts hold. A native ours merge must first prove complete preservation, never bypass conflict. Actual this-task validation isolated/localbare only; onlyimplementationbranchmaypush. Normal hook IO budget must be explicit (oldprepare60s vsmeasuredgate326s). No new store/runner/gate/tests/scheduler/consent or cost framework.

Audit plan honesty and preservation/partial-state/read-only distinctions; do not ask to implement unrelated W8–11/auth/budget infrastructure under this plan. Concrete behavior findings need observed input/scope/falsifier. Whole-source review accurately states bounds; read relevant sources in paged chunks without truncated claims. No source/artifact edits, new agents, executable suites/fixtures, network/connectors/live actions or Git commands/writes except this relay; harmless in-memory source probes permitted. No new CI tests/cases/parameters/registrations or cap allowance. EarlierclosedR6FAIL6/6Medium1028, Phase6/7, Phase8 and1027unapproved remain immutable. Handing off to Reviewer(codex)—take bounded Phase9 plan Round1.

### Reviewer · Round 1

VERDICT: PASS
Basis: Approved for the bounded Phase9 plan only. The proposed caller extends the existing preparation and canonical owner seams, requires exact preservation before ancestry/publication, and keeps unsupported state held. No implementation, runtime qualification, W7 completion, W8–W11 delivery, live action, or new review/test allowance is approved.
swept file: yes

- [Pass] Whole 1,289-line `PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md` swept, including pre-existing sections and immutable review history; complete expanded Recon Map read. No additional blocking pre-existing plan defect found. Existing R6 FAIL6/6 / Medium GH1028 title-grammar limitation and GH1027 unapproved tests remain explicit (`:764–789`, `:1265–1289`). Source review covered the complete 1,485-line core and 369-line intake module, current canonical inventory (`utils/py/releases_app.py:4603–4805`) and preservation/admission/root/recovery/apply/staged-builder seams (`:6489–7016`), not an exhaustive new audit of every release command or downstream driver.
- [Pass] The orientation premise matches the seeded owner. `select_ledger_merge` refuses non-roadmap local table changes (`utils/py/releases_app.py:6610–6619`); root inputs remain ordered base/root HEAD/supplied target (`:6647–6670`), and recovery/selection-applied bind that physical root digest (`:6703–6707`, `:6768–6769`). Phase9 explicitly requires an opt-in adapter retaining those bindings and defaults (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:1217–1225`, `:1233–1239`), rather than simply swapping parent arguments in the CLI. Read-only probe command: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `import hashlib,json; from pathlib import Path; p=Path('utils/py/releases_app.py'); e=json.loads(Path('TESTS-RESULTS/2026-10-11+GH-1022/phase9-direction-grounding.json').read_text()); h=hashlib.sha256(p.read_bytes()).hexdigest(); print(h); print(h==e['source_sha256'])`, then `PY`. Exit 0; decisive output `e64c273dabf2697c815e2afc68ab2827b49656d02501d8b12d66c2668b5ea004`, `True`. The recorded fixture reports `unsupported local table change: releases` and reversed selection retaining owner description/override, 1776 receipts and 703 events. Those runtime observations remain producer evidence; I did not re-execute that fixture.
- [Pass] Preservation requirements cover the actual caller gaps: current preparation checks exact two-field private ownership before its local lock, holds target advance and existing remote branch, then commits before a complete checkpoint (`planner_core.py:1013–1029`, `:1122–1133`, `:1155–1187`, `:1338–1355`). Phase9 requires a stopped-owner transfer intent that also blocks older/default writers, exact committed intake/private evidence, full incoming-path accounting, conflict refusal before an ours ancestry record, and explicit adoption/ordinary FF policy (`plan:1240–1275`). These are implementation obligations, not claims that the existing code already supplies cross-clone handoff.
- [Pass] Costly recovery and proof boundaries are explicit: preserve predecessor work and original receipts, recover exact durable operations without restoring over later owner data (`plan:1227–1231`); negative/drift/conflict/recovery controls, no-op and existing-suite/ephemeral proof precede final independent QA and normal gated implementation publication (`:1276–1284`). Census completeness remains separate from idle/criterion/dispatch proof (`:1247–1249`, `:1266–1275`). No second ledger/merger/runner, schema expansion or CI addition is proposed.
- [Nit] The near-top next-action cell repeats the coordination/R6/GH1027 text and says “W7 preservation planQA ApprovedR1/3” without naming Phase8 (`plan:21`), while Phase9 correctly says not yet approved (`:1206–1208`). On the next normal producer update, remove the duplicate and identify the approved prerequisite as Phase8, then record this Phase9 plan verdict separately. This is clarity only; no source behavior change requested.
- [Unverified — needs clone run] Cross-clone stopped-owner interleavings (including a default writer that read ownership before waiting for the lock), interrupted transfer/bootstrap/native integration, delta-mode journal recovery/root digest order, no-op after integration, current-target owner changes, and hook-budgeted FF publication have not run in this reviewer turn. Step6 must retain source-bound red/green controls and final gate evidence for these requirements. The recorded 326s hook is historical subsystem evidence, not a guaranteed future publication ceiling; Step5 must select and disclose a budget appropriate to the actual classified hook. No validate/test/pytest/fixture, network or Git command was run here.

Graph evidence: Verify tier attempted; no indexed project matches this review worktree/task clone. Nearest `XYZ-forge` graph is the primary checkout, coverage generation `2026-09-01T15:54:30Z`; planner search returned 0, with coverage reporting core not-tracked, intake missing and owner metadata-changed. It cannot establish this candidate's structure/freshness. Direct candidate source reads above are the evidence; no negative completeness claim relies on that graph. No artifact/source edits or additional agents.

Relay closed (Approved), no further review turn needed. Handing the completed plan verdict to Author for bounded implementation and later independent final QA within existing authority.


### Attestation · relay-drive — 2026-10-12T10:28:16Z
task: GH1022-PHASE9-PLAN
reviewer: codex
status: Approved
reviewed-head: 836e7813f3d91e3dc45852f993e68ead3dba41b0
added-range: 7782+5484
added-sha256: 2e8b56e194bd815f3e2055ef513313402064cc6aea50ccd6da592480dd0b7309
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
