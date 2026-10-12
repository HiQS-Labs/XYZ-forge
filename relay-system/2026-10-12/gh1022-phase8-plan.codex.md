# RELAY · GH1022 Phase8 canonical preservation transaction plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh1022-phase8-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase8; expanded GH-1022-WEEKLY-INTAKE/recon-integration-and-shared-boundaries.md; existing canonical releases_app.py writer/parser/loader/rebuild/recovery and existing fixture sources
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Review genuinely new W7 canonical GID/history-preserving local merge API plan against actual owner seams. Conservative supported threeway semantics, immutable Git/root/data guards, source validity and roundtrip, no replay/remint, staged builder reuse, journalled publication/recovery and untouched .bak/append-only triggers/legacy defaults; declared cursor/view limits and no readiness/approval/dispatch claim. Own previously authorized normal new-scope plan cap3, not new authority from status request; closed R6FAIL/Medium1028, Phase6/Phase7 unchanged. No implementation or full1022 approval.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: New canonical API plan is ready for independent QA; no source implementation.

Exact source35391f04; published census437/d09 verified full409+Python21 GREEN826s and smokeSUCCESS. Expanded recon ran four read-only lanes, field/backup/caller/cost cutoffs recorded. Read Phase8 current plan: ordinary clear/reload is NOT chosen. Actual in-memory current schema rejected op_receipts DELETE with append-only trigger and retained row (phase8-trigger-grounding.json). Existing perform_migration is also in-place, not a staged swap. New mode must factor/reuse _rebuild's staged canonical constructor and extend the existing owner journal/recovery for publication; no duplicate importer/orchestration/scorer/source of truth or trigger weakening. Existing fixed backups remain untouched. Current-schema/nullable/default/generation/labels/receipt-source/roundtrip guards must precede mutation; nonempty device-local cursors hold. Supplied target commit is not fresh remote/criterion/human evidence.  [Unverified — no citation]

Read whole plan and relevant existing owner/fixture sources before assessing. Missing/malformed/conflicting/deleted/unknown source shapes hold, no guessing. Confirm existing reanchor semantics, source-chain integrity, old/new generation and recovery identity; proposed dry localGit+memory preview has no root file/audit/DB/init/recovery/fetch/index/commit/push effects. Explicit apply is local owner data/journal/adopted-view effect and remains dispatchfalse. No new migration/event/test/gate/runner or self-authored approval authority.

No source edits, extra agents, executable suites/fixtures, network/connectors/paid/live actions or Git writes except this relay; harmless in-memory source probes permitted. Any behavior-change finding needs concrete input/scope/falsifier. Preserve R6FAIL6/6/Medium1028 and closed Phase6/7, no cap reset/relabel. This plan is genuinely new owner functionality, not a title-grammar corrective review. W7coordination/rollover and W8–11 remainactive. No individual CI test/case/param/registry approved. Handing off to Reviewer(codex)—take new-scope plan Round1.

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the bounded Phase8 plan, not implementation, publication or full GH1022 delivery. The plan puts conservative source admission and exact roundtrip ahead of journaled staged publication, keeps canonical ownership and legacy defaults, and leaves unsupported state held. No blocking defect observed in the reviewed plan.
swept file: yes

- [Pass] Whole 1,088-line intake document and complete expanded recon map read, including earlier dispositions. Closed R6/Medium1028 and Phase6/7 remain explicit; Phase8 grants no readiness, consent or dispatch (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:980`, `:1000`, `:1054`, `:1078`). No additional pre-existing actionable plan defect found beyond the documentation nits below. Source inspection was bounded to the relevant canonical serialization, writer, parser/loader, check/reanchor, rebuild and recovery seams and covering fixture sources; this is not an exhaustive audit of every unrelated CLI verb.
- [Pass] The chosen owner seam matches source: `utils/py/releases_app.py:6537` validates before load, `:6541` restores into the staged DB, `:6588` appends the scoped merge receipt, while `:6603`–`:6608` overwrite the fixed backup and swap before dump publication. Phase8 explicitly replaces only the new mode's publication boundary with journaled recovery, retains legacy defaults and rejects clear/reload (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:983`, `:1028`, `:1083`). Reusing the builder does not establish reuse of legacy publication as safe.
- [Pass] Source validity and preservation have falsifiable admission criteria rather than trusting the merge-damage validator: nonempty inputs, current identical schema, exact roundtrip, held deletions/conflicts, labels and generation floor (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:993`, `:1011`, `:1035`). This matters because `load_dump` defaults timestamps (`utils/py/releases_app.py:6307`), omits connector cursors (`:6485`) and serialization substitutes NULL for lease_pid (`:1271`). The cursor/live-lease cutoff is conservative and honest.
- [Pass] Pure preview is correctly separated from legacy check's effectful lock/recovery entry (`utils/py/releases_app.py:5921`, `:5946`; plan `:1019`). New publication requires exact before/after recovery identity and durable directory boundaries (`:1039`); existing recovery currently branches on generation alone (`utils/py/releases_app.py:1952`), so this approval does not credit unchanged recovery as sufficient for a swapped database. Existing crash/reanchor fixtures are suitable starting evidence, not proof of the new mode (`test/gh32-releases-app.sh:264`, `test/gh360-scoped-receipt-chain-rebuild.sh:156`).
- [Nit] Phase8 still says the 437 gate retry “is underway” (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:978`), contradicting the current status table at `:21`. Cheapest fix: label that sentence as historical or align it with the already recorded completion; do not infer a fresh gate from this review.
- [Nit] The Phase8 blast paragraph (`PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md:1002`) lacks its own explicit reversibility grade. Cheapest fix: label the shared writer/recovery extension Costly, distinguish code revert from interrupted-operation recovery, and state that an already durable merge is completed/reconciled rather than blindly replayed or restored over later owner writes. The existing preservation/recovery criteria already require that distinction; this is documentation clarity, not a new mechanism.
- [Unverified — needs clone run] New API determinism, no-write preview, concurrent-writer preservation, no-op idempotence and crash recovery remain unimplemented acceptance criteria. No validate.sh, test suite, pytest, executable fixture, Git command or live/provider action ran in this turn. No new test/case/parameter/registry or review-budget extension is approved.

Evidence method: graph project listing fully paginated; no index for this relay checkout. Nearest XYZ-forge graph generation 2026-09-01T15:54:30Z is a different root; coverage reports owner metadata changed and plan paths missing. Direct current source reads therefore supersede graph snippets. No runtime probe results claimed.

Relay closed (Approved), no further turn needed. Author may address the nits and proceed through the separately required implementation/final-QA/gate process within existing authority.


### Attestation · relay-drive — 2026-10-12T08:33:40Z
task: GH1022-PHASE8-PLAN-R1
reviewer: codex
status: Approved
reviewed-head: 5c276d7c411ad4cd2a4a5a69d8d648b0930b294a
added-range: 8106+4431
added-sha256: 3a30a99e070edd059df04ab776d2687003867353df5f59d92417e663e58c9c5c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
