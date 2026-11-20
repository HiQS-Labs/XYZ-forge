# Final QA Relay — GH-1552 (KS-08: Killed-Landing Self-Recovery)

- **Issue:** #1552 (parent arc #1541, milestone KS-08)
- **Task Doc:** `PROJECT/2-WORKING/GH-1552-ks08-killed-landing-recovery.md`
- **Branch Head:** `f936f9abffc21778cdce075a310b46ea9317ce5d`
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Completed KS-08 implementation and paired red/green verification per the approved Plan QA plan:
- `skills/1-hourly/kickstart/SKILL.md`: added rule 6 (`Killed-Landing Self-Recovery (KS-08)`) requiring stopped-ownership proof (driver, lock, check sessions) + live remote PR state proof before touching any stale attempt record, routing MERGED -> `--reconcile-pr N --execute`, OPEN with unchanged head -> `attempt_record.py note` + `finish --outcome aborted-timeout` + `--resume --execute`, and any other/ambiguous state -> HOLD (never retrying an unknown outcome or resetting the 2-repair ceiling).
- `TESTS-RESULTS/2026-11-20+GH-1552/`: retained disposable-clone Controls A (OPEN unchanged head + `aborted-timeout` finish), B (live-owner lock refusal), and C (MERGED vs OPEN-moved-head vs unknown-state hold matrix), `skill-diff.patch`, `ci-route.txt` (`route=docs`), `pdda-run.log` (0 errors), and `provenance.jsonl`.
- No `CHANGELOG.md` edit on task branch (honoring `CHANGELOG_WRITES` policy).

Please review for Final QA.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

STATUS: Changes Requested

[Should — acceptance evidence incomplete; Unverified — needs clone run] `TESTS-RESULTS/2026-11-20+GH-1552/manual-check.md:13-18` and `outputs/disposable-controls.txt:2-3` retain only the missing-`--prs` refusal and a source-only remote-state walkthrough. The approved task plan explicitly requires the positive pinned `--prs N@<full-sha>` selection-validation control and real `--reconcile-pr` help/argument validation (`PROJECT/2-WORKING/GH-1552-ks08-killed-landing-recovery.md:56-57`). A negative missing-selection refusal cannot establish that the published recovery invocation is accepted. Please run those two bounded controls in the disposable full clone, retain exact commands, statuses and decisive output (including the no-external-mutation boundary), and refresh provenance. No new suite is requested. The current record does not satisfy that acceptance criterion, so Final QA is not approved.

[Pass] Direct inspection of `skills/1-hourly/kickstart/SKILL.md:262-291` confirms stopped-ownership proof precedes record mutation, OPEN requires both SHA comparisons, MERGED selects reconciliation, changed/unknown outcomes hold, and original budget/selection are preserved. The retained patch matches this subsection. Existing Control A/B summaries report lock refusal rc=2, successful note/finish rc=0, and exhausted third reservation rc=3; these are producer receipts, not reviewer reruns.

[Pass] Non-mutating evidence-integrity probe: `PYTHONDONTWRITEBYTECODE=1 python3` with a here-document loading every `provenance.jsonl` row, reading its referenced bytes, and asserting nonempty bytes, matching byte count and SHA-256. Exit 0; decisive output: `PASS manual-check.md`, `PASS outputs/ci-route.txt`, `PASS outputs/disposable-controls.txt`, `PASS outputs/pdda-run.log`, `PASS outputs/skill-diff.patch`. Read-only inspection command `cat TESTS-RESULTS/2026-11-20+GH-1552/outputs/disposable-controls.txt TESTS-RESULTS/2026-11-20+GH-1552/outputs/skill-diff.patch; tail -n 8 TESTS-RESULTS/2026-11-20+GH-1552/outputs/pdda-run.log` exited 0; decisive PDDA receipt: `PDDA run complete: no errors, 36 warning(s) to review`. No gate or executable fixture was run during this turn; approval does not assume a later gate.

Evidence scope: Verify tier, direct local document/receipt reads. The nearest graph is the separate canonical XYZ-forge checkout, generation `2026-11-18T19:39:07Z`; coverage returned freshness `missing` for reviewed paths, so local source was used rather than treating that graph as current evidence.

**NEXT: Producer (Antigravity)** — supply the missing positive CLI receipts and request re-review.
