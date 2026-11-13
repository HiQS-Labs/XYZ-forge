# RELAY · GH-1452 final QA: merge-cleanup plan-ahead landing forecast
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1452-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (the IMPLEMENTATION, committed on this branch; base `6c0c76bb5`): review `git diff 6c0c76bb5..HEAD` limited to `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`, plus `CHANGELOG.md`, the working doc `PROJECT/2-WORKING/GH-1452-MERGE-CLEANUP-PLAN-AHEAD.md` and the evidence folder `TESTS-RESULTS/2026-11-13+GH-1452/` (README.md maps every scenario to its red control). You have no `git` in your sandbox if a command is refused: read the files at HEAD and use the Plan, Acceptance and Blast radius sections of the working doc as the diff map (the base text of each function is quoted there by `file:line`).
- Plan under review was Approved: `relay-system/2026-11-13/gh1452-plan-qa.md` (Codex, round 2). Settled findings S1-S3 and nits are not to be reopened without new evidence.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-13
- Operational envelope: a local, advisory conflict forecast printed by an operator CLI. Grade against the stated requirements and commensurate complexity, not multi-tenant or enterprise machinery. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new test file or registry entry in the diff is itself a finding, and you must not ask for one. Verification is the existing suite (`test/gh436-merge-cleanup.py`, 227 tests, OK) plus the retained manual scenarios. The final qualifying gate (`ci-local.sh`, route full) runs once after your approval; do not run it, `validate.sh`, `test/*.sh` or pytest.
- Definition of Done: GH-1452 is satisfied: a dry run over 3 or more `--prs` prints and stores the forecast; `unknown` withholds the recommendation; the forecast never supplies the GH-1158 decision or reason; `pin_selection` stays the single atomic writer; `set_landing_plan` is extended, not duplicated; SKILL.md states the planning-time contract; old pin files and old callers keep working; checks substantiate the claims.

## Questions for the Reviewer (answer each with `file:line`)

1. Is each Acceptance item in the working doc satisfied by the code and the retained evidence? For each item name the code site and the evidence line (`TESTS-RESULTS/2026-11-13+GH-1452/manual-check-run.log` `EVIDENCE` lines, README scenario map).
2. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Check that the red controls (S1 broken classifier, S10 naive read-modify-write, S13 base-commit `TypeError`, S7 control) are real and that the Preflight absence probes are only admission evidence.
3. Do the actual code paths match the plan: `landing_forecast` receives a prepared clone (no network, no import of the main script); `build_landing_forecast` owns the clone and the `pull/<N>/head` fetches and verifies each against the pin; `unknown` takes precedence over the direct/group rule; the fold stops at the first conflict; the recommendation text and `"conditional"` handling match SKILL.md?
4. Did a duplicate subsystem or writer slip in? Specifically: `ledger_repair_paths` is shared with the B1 resolver (behavior unchanged for `resolve_ledger_conflict`); `pin_selection` is still the only writer of the selection file; `set_landing_plan` is the only writer of `landing_plan`.
5. Is the GH-1158 contract intact? The refusal at the early checkpoint still exits 5 before any mutation, the forecast only annotates, `--landing-reason` is the operator's own, and an override is recorded rather than blocked.
6. Concurrency and failure handling in `pin_selection`: lock scope (temp-write and replace only), timeout reported as a failure to publish, behavior with `--scan-only`, `--prs-only`, no `--prs`, and inline `N@sha` pins. Any defect with a concrete failing input?
7. `forecast_comparison` base-drift check uses `git ls-remote` at the early checkpoint (before any fetch). Is a bounded read-only network call there acceptable under the GH-1158 "before any mutation" rule, and does a failed lookup correctly make no drift claim?
8. Is anything over-engineered for an advisory forecast? Name machinery to cut. Is the batch issue line (`Forecast (GH-1452)`) proportionate?
9. Are the PRS ratings still supported (pri 55, sev 40, appeal 50 neutral, effort 40), and does the CHANGELOG entry and doc status tell the truth about what was and was not verified (the real downstream queue and forks were not run, with reasons in the README)?
10. Pre-existing defects in the touched files are in scope: read `merge_cleanup.py` around `pin_selection`, `verify_selection`, the early checkpoint and `build_landing_forecast`, and `ledger_merge.py` around `resolve_ledger_conflict`; report any real defect you can demonstrate.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix. Every `[Blocker]` or `[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Include the literal line `swept file: yes` or `swept file: no`. Set a VERDICT (PASS, FAIL or PARKED) and Basis. Read-only probes only, output under `.relay-scratch/`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
