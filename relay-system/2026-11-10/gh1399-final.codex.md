# RELAY · GH1399 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1399-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Review the full diff origin/development...HEAD for issue1399, its active task/recon docs, and committed TESTS-RESULTS/2026-11-10+GH-1399 evidence. First paraphrase the operator contract: fail-closed entry using existing accounting, preserved consumed rounds and admin behavior, no new suites/framework. Read all changed runtime files, not only hunks. Production controls run in disposable full clones; do not execute test/validate from your reviewer worktree. Read-only probes allowed. Scope limits: native explicit bypass and operator local-file tampering are not a security boundary; a reservation covers one caller-owned repair episode, not automatic inference of every raw shell command. Frozen Bash fallbacks unchanged; default Python producers integrated. Source skill instruction changes only, no deployment. Final full pre-push and hosted checks will run after approval; do not claim them yet. Missing runtime behavior with a concrete failing input is a finding. Do not prescribe new suites or gate frameworks.

- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
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
Basis: The inherited merge-repair accounting path can enter a counted relay but cannot complete its approval path. Full-file review coverage also remains incomplete; this is not final sign-off.
swept file: no

Operator contract: fail closed at existing qualification boundaries using existing accounting, preserve consumed rounds and administrative behavior, and add no suites/framework. Native bypasses and deliberate local-file tampering remain outside the boundary; one reservation covers one caller-owned repair episode.

- [Should] **Do not send a merge-repair reservation to the lane-only writer on approval.** `utils/py/relay_drive.py:259` accepts a nested counted reservation with state `in_progress`; `utils/py/gate_receipt.py:133` explicitly supports `kind=merge-repair`. With that context in `XYZ_ATTEMPT_CONTEXT`, `relay_drive.py:766` attaches it to the approval, then `relay_drive.py:776` unconditionally invokes `lane_attempt_finish`. That writer rejects every canonical merge-cleanup record path before doing any IO (`utils/py/rtl.py:148`), so the enclosing catch returns `attest-publish-failed` after the reviewer already approved and the trailer/approval were written. This conflicts with parent-context reuse in `skills/1-hourly/start-task/SKILL.md:252`.
  Observed input: `{"kind":"merge-repair","record":"/primary/.tick/merge-cleanup/HiQS-Labs-XYZ-forge/pr-1399.json","index":0}` passed to `lane_attempt_finish(context, "active", "a"*40, attestation="/primary/.git/approval.json")` raises `ValueError: archived attempt bytes are immutable`. The path follows the canonical shape in `skills/2-daily/merge-cleanup/scripts/attempt_record.py:49`; rejection precedes checking record contents.
  Affected scope: non-review-once relay approvals inheriting an explicitly supplied, valid merge-repair `XYZ_ATTEMPT_CONTEXT`, with `LANE_ATTEMPT_COUNTED=1`. The admission branch already permits this state; this is not a request to admit failed/resolved reservations as active builders.
  Falsifier: in a disposable full clone, run an approving nested relay under a valid in-progress canonical merge-repair context. It must finish without `attest-publish-failed`, preserve the parent's repair count and lifecycle ownership, and avoid allocating a lane budget. If it already does, this finding is wrong.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `sys.path.insert(0, "utils/py"); from rtl import lane_attempt_finish` and the exact call above, catching/printing `ValueError`. Exit status **0** (exception caught); decisive output **`ValueError: archived attempt bytes are immutable`**. No Git invocation, lock, record read or write occurred. This establishes the callee mismatch; end-to-end reproduction remains **[Unverified — needs clone run]**.
  Fix: dispatch approval binding according to reservation kind and retain merge-repair ownership with its existing writer/caller. Do not invoke the lane JSONL writer for a merge-repair JSON record or book a replacement lane merely to make approval pass. Verify with a retained manual clone control, not a new suite.

- [Pass] Admission precedes docs routing and full-receipt reuse in `githooks/pre-push:90`, and legacy green recording in `utils/gate-record.sh:81`. This is source inspection, not an independently executed gate.
- [Pass] Legacy timestamp lines still consume count in `utils/py/rtl.py:86`, and archive preservation uses rename in `utils/py/rtl.py:215`. Recorded managed controls include transcript-only acceptance, unrelated-candidate refusal and two retained lines in `TESTS-RESULTS/2026-11-10+GH-1399/implementation/gate/managed-results.json`. These are producer receipts, not a fresh reviewer execution.
- [Unverified — needs clone run] Full pre-push/hosted qualification remains outstanding as Setup explicitly permits. No validate, test suite, pytest, executable fixture or Git command was run in this turn.
- [Unverified — review coverage] Reconstructed the base-to-HEAD changed-path list and diff by reading Git object bytes without invoking Git; reviewed the task/recon docs, admission module, lane accounting changes, relay driver, boundary integrations and retained evidence. The complete pre-existing bodies of marathon_drive, merge_cleanup, scan_clones and every changed gate/test/skill have not all been swept. No claim of absence of pre-existing defects is made. Complete that sweep before final approval.

Handing off to Producer (codex-parent) — correct/disposition the lifecycle mismatch, retain its clone evidence, and return for the remaining full-file review; go to the Producer window and say 'take your turn'.

### Producer · Round 2

Implemented the observed lifecycle mismatch: only a managed lane context receives the lane approval binding. Inherited manual/merge-repair contexts remain owned by their parent; the relay neither finishes nor archives them. Retained real driver + real isolated shim controls under implementation/final-controls use a stub reviewer, explicitly synthetic. Replaying the old condition fails approval; the fixed version exits0 with exactly one still-in-progress parent repair and no lane budget. Administrative normal push passed in74s; completed proof passed from a separate full clone. These final manual receipts are retained with provenance. Full qualification/hosted checks remain pending approval. Please complete the remaining whole-file sweep and review this fix; no suites may run in the review worktree.

Handing off to Reviewer (codex) for round2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
