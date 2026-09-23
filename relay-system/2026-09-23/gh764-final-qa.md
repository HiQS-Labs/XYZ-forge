# RELAY · GH-764 final QA: baseline macOS gate repair
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
-->

NEXT: Producer
STATUS: Approved
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh764-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/work_connectors/__init__.py
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-23
- Review target: issue #764 implementation on `fix/gh764-baseline-gate` against `origin/development`; inspect the full changed files and plan at `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md`, plus `test/gh142-ate-exit-contract.sh`, `test/test_gh605_work_state.py`, `ROUTER.md`, and `CHANGELOG.md`.
- Operational envelope: local macOS gate repair. The focused suites ran in a separate disposable full clone after copying the changed code files: GH-142 30/30, GH-605 28/28, GH-549 124/124; separate missing-`requests` and missing-`yaml` environments each failed early by name. The complete qualifying full gate is scheduled after this final review. Do not run mutation-heavy suites in the relay worktree. Prefer a surgical result over new machinery.
- Definition of Done: decide if the implementation matches the approved plan and is ready for its full gate. Specifically check:
  1. Does the ATE preflight use the same interpreter and avoid the prior false-positive exit-code assertion for both missing imports?
  2. Does the WAL fixture truly create header-without-sidecars and still verify the production reader refuses without writes?
  3. Does clearing the closed stdin handle preserve child launch, concurrency, deadline behavior, error reporting, cursor bounds and cleanup? Look for a concrete regression input.
  4. Does the diff avoid unrelated changes or duplicate subsystems, keep the #764 rating/governance accurate, and keep the distinct pre-deadline payload stall parked rather than claiming it fixed?
  Give graded findings with file:line citations and `VERDICT: PASS` or `FAIL` plus `Basis:`. Approve only if no implementation blocker remains; leave full-gate qualification explicitly pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Pass] ATE setup now checks both imports with `python3` before making fixtures (`test/gh142-ate-exit-contract.sh:21-24`); the chain uses that interpreter and checks the child-failure line as well as exit 1 (`test/gh142-ate-exit-contract.sh:113-119`). This closes the import-error false positive without changing filing behavior.
- [Pass] The WAL fixture checkpoints and closes before removing both sidecars, asserts their absence, then checks refusal, unchanged DB bytes, and no recreated sidecars (`test/test_gh605_work_state.py:216-242`). The reader's WAL-header branch returns before SQLite open (`utils/py/releases_app.py:5266-5287`).
- [Pass] The connector clears `proc.stdin` only after sending and closing the payload (`utils/py/work_connectors/__init__.py:194-210`). All batches still launch before the shared deadline and collection (`utils/py/work_connectors/__init__.py:424-447`); collection retains timeout kill/reap, child-error reporting, and cursor bounds (`utils/py/work_connectors/__init__.py:224-269`). The focused GH-549 suite has explicit non-vacuous concurrent-window and cursor checks (`test/gh549-work-events.sh:365-421`, `test/gh549-work-events.sh:511-555`). No concrete regression input from this handoff change was found.
- [Nit] Pre-existing diagnostic mismatch in the swept connector file: `dispatch(..., window_s=2)` is an actual GH-549 input (`test/gh549-work-events.sh:380-383`), but the timeout text interpolates the default `CONNECTOR_WINDOW_S`, 5 seconds (`utils/py/work_connectors/__init__.py:41-42`, `utils/py/work_connectors/__init__.py:231-237`). If this message is revised later, report the effective window. This does not affect the deadline or cursor outcome and is outside the GH-764 fix.
- [Pass] Scope and governance stay aligned: the working doc rates the blocked gate without claiming a recurrence trend, records a Costly rollback, and leaves the final gate unchecked (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:44-55`, `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:70-75`, `PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:100-106`). `CHANGELOG.md:3-14` likewise says the full gate is pending. The distinct pre-deadline payload stall remains parked (`PARKED/2026-09-23-gh764-connector-window.md:3-14`).
- [Unverified — needs clone run] The qualifying complete macOS gate on the final commit remains pending (`PROJECT/2-WORKING/GH-764-BASELINE-GATE-FAILURES.md:94-106`). Focused pass counts are recorded there, but this relay turn did not rerun suites.

VERDICT: PASS
Basis: The implementation matches the approved bounded plan and has no observed implementation blocker. Approval is for proceeding to the separate full-clone gate; it is not gate qualification.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
