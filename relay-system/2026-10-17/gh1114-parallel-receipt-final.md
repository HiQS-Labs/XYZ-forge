# RELAY · GH-1114 final QA: implementation of parallel hosted qualification + receipt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh1114-parallel-receipt-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/wave_reconcile.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/wave_reconcile.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.** Approved plan: `PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` (plan relay `relay-system/2026-10-17/gh1114-parallel-receipt-plan.md`, Approved r2). Review the committed diff `git diff 6a05e45f..HEAD -- utils/py/wave_reconcile.py test/gh425-gate-provenance-pr.sh skills/2-daily/merge-cleanup/scripts/batch_record.py` against the canonical files (not `.relay-artifacts`), plus the evidence folder `TESTS-RESULTS/2026-10-17+GH-1114/` (reader-controls.py.txt + .log.txt, three suite logs, provenance.jsonl).

**Operational envelope (unchanged from plan QA):** operator decisions not under review: parallel is the standard form, rescued first-attempt failures do not block but are recorded, sequential stays accepted, `ci.yml:203` untouched, no new test files/cases, no validate.sh change.

**Claims to verify (cite file:line):**
1. `qualification_summary` (`wave_reconcile.py:487-555`): the only relaxation versus base is the `red()` carve-out (executed-lane row rc≠0 iff same-name retry row rc==0). Every base check listed in plan S1 is still present: mode set, identity/run binding, executed count AND unique-name count == registered, non-suite rows never carved out, summary/envelope/run-set/registered/`suite_events_match`, required probes, Small path.
2. Callers: `:585` (receipt replay, tuple ignored) and `:707` (tuple unpacked; `summary["run"]`, `summary["passed"]`, `summary["total"]` still read from the summary dict). `test/gh425-gate-provenance-pr.sh:406` calls the function only for a raise.
3. Glob `:704` `validate-*-{pgid}.jsonl` keeps exact-one-file and run-id binding (`:705-709`).
4. Receipt additive keys `mode/width/first_attempt_failures/retries` (`:725-735`); `ACCEPTED_GATES` at `:561` keeps legacy sequential receipts valid.
5. Evidence: manual controls (a)–(i) in the log are the ones the plan names; (f2) and (g2) were added beyond the plan as extra negatives (not test cases; harness lines). State whether any control is vacuous. Note (i) evaluates the writer's `entry = dict(...)` expression with the reader's meta rather than an end-to-end emitted file; gh425 exercises the writer end-to-end (sequential) and the first hosted run after merge is the first real parallel receipt. Is that an acceptable evidence boundary for a PR, with that limitation stated in the PR body?
6. Pre-existing defects in the touched regions of `wave_reconcile.py` (sweep the file).

Changed-path route: `utils/ci-route.sh push` → tier=3 (test file changed). The pre-push hook decides the local gate at push; hosted reconcile runs the new parallel gate on merge.

Please end with VERDICT and a `swept file: yes|no` line.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
