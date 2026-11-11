# RELAY · GH1399 attempt qualification plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
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
6. **Commit only the relay file** (`relay(gh1399-attempt-qualification-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh1399-plan-packet.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh1399-plan-packet.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-parent
- Started: 2026-11-10
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The design is appropriately bounded, but its archive/context lifecycle needs one concrete decision before implementation. This is plan QA, not a claim of a demonstrated runtime regression.
swept file: yes

- [Should] Specify the reservation-reference transition across archive/reset and post-approve candidate evolution. The proposed context references an absolute canonical record, but successful reset moves that record; the plan also requires exact final-candidate matching for completed records while the existing post-approve path can move HEAD after reset. Merely listing an archived/post-approve smoke check leaves the producer choosing between a missing reference, a stale completed SHA, or modifying the supposedly byte-preserved archive. Cheapest correction: state the precise completion/archive ordering, how the returned archive path reaches later qualification/publication, and which reservation remains active while post-approve may change the candidate. Preserve consumed rounds and immutable archived bytes; do not book another attempt for closeout. If ordering changes, explicitly retain post-approve failure/recovery semantics.
  Observed input: `utils/py/rtl.py:23-25` renames the live file and returns its archive path; `utils/py/marathon_drive.py:1286-1300` logs that path without returning it; `utils/py/marathon_drive.py:2857-2867` calls reset before post-approve and explicitly says “the hook may move HEAD”. Read-only command `sed -n '2840,2900p' utils/py/marathon_drive.py` exited 0; decisive output: `lane_attempt_reset(get_env("TICK_REPO_ROOT", root), lane_state_key)` precedes `post_approve_exit = run_post_approve_cmd()` and `candidate, record = bind_candidate(...)`.
  Affected scope: a successful managed lane that archives its live record, then qualifies/publishes during or after post-approve, including an allowed candidate change and a failed closeout resumed without another fire.
  Falsifier: a stated source-to-archive reference transition plus a manual clone control showing same-candidate publication after archive, allowed post-approve candidate evolution, and failed/resumed closeout all use the original consumed reservation without changing archived bytes or increasing/resetting the count. A later unrelated candidate must refuse. Runtime measurement is [Unverified — needs clone run].
- [Pass] The accounting authority stays surgical: packet “Keep the current counter file and count semantics” and “No automatic cap reset or retrospective uncounted binding” preserve legacy consumption; delegated `gate_receipt` commands reuse the lane writer rather than introducing another budget ledger. No new suite or registry entry is proposed (ordered steps 2, 3, 6).
- [Pass] Completed B1 is correctly distinguished from active work: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1581-1583` finishes `resolved` with `commit=b1["commit"]` before second-clone validation. Packet exact-final-candidate semantics and steps 3/5 cover that compatibility requirement. Nested ownership, standalone booking, external record transfer, per-pushed-ref identity and explicit hosted/admin exemptions are addressed as implementation obligations, not claimed runtime evidence.
- [Pass] Entry coverage includes successful shortcuts and legacy evidence: `githooks/pre-push:258-263` returns on docs success, `:289-308` reuses receipts, and `utils/gate-record.sh:80-106` writes legacy green evidence before JSON. Packet step 4 places admission before these routes, including the install fallback; a JSON-writer-only fix is expressly rejected.
- [Unverified — no citation] Rating rationale is proportionate as a proposal: packet “Appeal50 is neutral” and “Coverage limited; trend unknown, not zero” avoid inflating appeal or treating sparse observations as a trend. The source review supports broader lifecycle effort than a hook-only edit; original remote issue/history and operator scoring were not independently queried this turn.

Whole packet and both committed candidate documents read. No additional pre-existing plan defect identified in the reviewed scope. No source/artifact edits, git commands, fixtures, tests or validate runs performed. Approval remains pending; production behavior and the planned red/green controls are unverified.

Handing off to Producer (codex-parent) — resolve the lifecycle decision above and take the next turn.

### Producer · Round 2
Accepted the lifecycle Should. The canonical plan now names the source-to-archive reference transition, binds the existing protected attestation to the consumed reservation, reuses candidate_ok for existing transcript-only post-approve evolution, preserves archive-before-post-approve/failure semantics, and restores that same reference for gate-only resume without another fire. Archives remain immutable. Exact completed B1/manual commits remain distinct. No new budget store, helper executable, suite, or speculative threat model.
Handing off to Codex for the second plan review. Please check the corrected protocol against the cited existing candidate_ok and completion paths; production implementation remains unstarted.

### Reviewer · Round 2

VERDICT: PASS
Basis: Approve the implementation plan. The round-1 lifecycle ambiguity is resolved using existing approval authority and archive handling; this verdict does not approve an implementation or claim runtime controls have passed.
swept file: yes

- [Pass] The archive protocol now specifies the missing transition: “Return the archive path from lane_attempt_reset” and “replace the propagated qualification reference with that actual archive path plus the matching attestation reference.” It preserves archive-before-post-approve, refuses failed rename advancement, and retains the original reservation for failed/resumed closeout without another fire. This addresses the ordering actually present at `utils/py/marathon_drive.py:2857-2878` and the byte-preserving rename at `utils/py/rtl.py:11-25`.
- [Pass] Attestation reuse fits the existing candidate contract rather than inventing a broader completed-receipt exception. `utils/py/relay_attest.py:395-432` requires reviewed ancestry and excludes only existing transcript/relay/phase-record paths from the endpoint diff; it refuses non-isolated and seeded-artifact reviews. The corrected plan explicitly retains these exclusions and restrictions, requires matching reservation/target identity and current target HEAD, and keeps completed manual/B1 records exact-commit. `utils/py/relay_attest.py:435-449` already validates the final candidate before extending phase completion. The proposed reservation/archive reference fields remain implementation work, not existing behavior.
- [Pass] Whole-plan coverage remains proportionate: “No automatic cap reset or retrospective uncounted binding,” nested ownership, external canonical-record references for full gate clones, detached context, per-pushed-ref identity, direct qualification, docs/receipt shortcuts, legacy green writing and explicit hosted/admin exemptions all have implementation and manual-control obligations. The observed shortcut sites remain `githooks/pre-push:258-263`, `:289-308` and `utils/gate-record.sh:80-106`; completed B1 remains `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1581-1583`. No new suite, registry entry or second budget authority is proposed.
- [Pass] Rating is stated as a proposal with an appropriate evidence limit: “Appeal50 is neutral” and “Coverage limited; trend unknown, not zero.” This approves the rationale's restraint, not an independent verification of remote issue history or operator scoring.
- [Unverified — needs clone run] Production behavior, original red admission control, archive hash/count preservation, allowed transcript evolution, failed/resumed closeout and unrelated-source refusal require the disposable-clone evidence specified in the plan. No tests, validate, pytest, executable fixtures or git commands ran in this review. Read-only source inspection commands exited 0; decisive inspected span: `candidate_ok` rejects `artifact_sha256` and non-isolated records before its ancestry and endpoint-diff checks.

Read the whole seeded packet, both canonical candidate documents, and the relevant existing archive, candidate/completion, lane, receipt and publication seams. No additional pre-existing plan defect identified in that scope. Implementation and final QA remain outstanding.

Relay closed (Approved), no further turn needed. Producer (codex-parent) may proceed with the approved plan and its required clone controls.


### Attestation · relay-drive — 2026-11-11T05:29:11Z
task: GH1399-PLAN-20261110
reviewer: codex
status: Approved
reviewed-head: ebeaae250a55a172f1b2ea5b926e430f18818039
added-range: 11013+3462
added-sha256: 3f93f22e8cde37ecd5a6526b4640701c54fbdf11fb4becc3ed25ca83d8a3c493
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
