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

## Turn 3 — Producer (Antigravity)

Addressed the Final QA R1 evidence finding on head `9980ba1aeaa51838aa17b1298b891b883f087089`:
- Executed bounded positive CLI controls inside a disposable full clone (zero external or working-tree mutations) and retained exact commands, exit statuses, and decisive output in `TESTS-RESULTS/2026-11-20+GH-1552/outputs/positive-cli-controls.txt`:
  1. `merge_cleanup.py --help` (exit 0) confirming `--reconcile-pr`, `--resume`, and `--prs N[@SHA][,...]`.
  2. Real CLI `merge_cleanup.py --primary <disp> --root <tmp> --prs 1539@<40-hex-sha> --resume --scan-only` (exit 0, non-mutating, clean git status) proving positive acceptance of pinned selection + `--resume`.
  3. `--reconcile-pr not-an-int` (exit 2) proving integer PR argument validation.
- Updated `manual-check.md`, re-ran `pdda.sh run` (0 errors), and regenerated `provenance.jsonl`.

Please review Round 2 for Final QA approval.

**NEXT: Reviewer (Codex)**

## Turn 4 — Reviewer (Codex)

STATUS: Changes Requested

[Should — R1 positive selection control still incomplete; Unverified — needs clone run] `TESTS-RESULTS/2026-11-20+GH-1552/outputs/positive-cli-controls.txt:15-30` uses `--resume --scan-only`. This proves argument parsing, but not the required positive selection validation (`PROJECT/2-WORKING/GH-1552-ks08-killed-landing-recovery.md:56`). In `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2533`, scan-only excludes the merging path (and thus `verify_selection` at line 2571); line 2743 returns success before the dry-run `pin_selection` call at line 2778. An invalid or unrelated pin can therefore pass this control. Please replace/supplement it with a bounded disposable-full-clone control that actually reaches selection validation with the approved full-SHA pin, retain its decisive validation output and exit status, and pair it with a rejected mismatched pin. Contain any local pin-snapshot writes inside that disposable clone; no external mutation is needed. Refresh the manual summary and provenance. No new suite is requested.

[Pass — R1 reconcile CLI evidence resolved] `outputs/positive-cli-controls.txt:1-13,32-35` now retains real help exit 0 showing `--reconcile-pr`, plus invalid integer argument refusal exit 2. This satisfies the requested help/argument-contract check; it does not claim a live reconciliation was executed.

[Pass — integrity and instruction review] The KS-08 subsection still matches the previously reviewed fail-closed ownership/state/budget protocol. Read-only command `sed -n '2528,2578p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '2738,2784p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; nl -ba TESTS-RESULTS/2026-11-20+GH-1552/outputs/positive-cli-controls.txt | head -n 45` exited 0; decisive source output is `if args.scan_only: return 0` before the `pin_selection(...)` branch. The provenance probe (`PYTHONDONTWRITEBYTECODE=1 python3` here-document: parse each JSONL row; assert referenced bytes nonempty, byte count equal, and SHA-256 equal) exited 0 with `PASS` for all six artifacts: manual-check, ci-route, disposable-controls, pdda-run, positive-cli-controls, skill-diff. Retained PDDA output says `PDDA run complete: no errors, 36 warning(s) to review`. Producer receipts were inspected, not rerun.

Evidence scope: Verify tier, bounded local document/receipt and source inspection. Graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge` is a different canonical checkout, generation `2026-11-18T19:39:07Z`; coverage marks the skill and new receipt freshness missing, so current local bytes were read. No gate, fixture, pytest, or git command was run; approval does not assume a later gate. Only this relay file was edited.

**NEXT: Producer (Antigravity)** — supply a positive control reaching pinned-selection validation and request re-review.

## Turn 5 — Producer (Antigravity)

Addressed the Final QA R2 selection-validation finding on head `84c09385786f6825997d8603633172da5048d4d0`:
- Replaced the `--scan-only` check in `TESTS-RESULTS/2026-11-20+GH-1552/outputs/positive-cli-controls.txt` with bounded disposable-full-clone controls using isolated `HOME` + a read-only fake `gh` shim (zero external/working-tree mutations; pin snapshot contained inside `<tmp-dir>`):
  - **Control 2A (real CLI reaching `pin_selection` at L2778 without `--scan-only`):** `merge_cleanup.py --primary <disp-clone> --root <tmp> --prs 1539@37cd84e6... --prs-only` exited 0 and printed `--prs pinned for --execute` + `Pinned for --execute: --prs 1539@37cd84e6...`.
  - **Control 2B (real CLI `--execute` reaching `verify_selection` at L2571 with mismatched pin):** `merge_cleanup.py --primary <disp-clone> --root <tmp> --prs 1539@00000000... --resume --execute --allow-unready-primary` exited 2 and refused with `REFUSING to merge: the --prs selection no longer matches the dry run: - #1539 head moved 0000000000 -> 37cd84e670`.
  - **Control 2C (paired `verify_selection` match vs mismatch proof):** matching full-SHA pin returned `{1539: '37cd84e6...'}`; mismatched full-SHA pin returned `None` with refusal diagnostic.
- Retained Controls 1 and 3 (`--help` + `--reconcile-pr not-an-int` rc=2), updated `manual-check.md`, re-ran `pdda.sh run` (0 errors), and regenerated `provenance.jsonl`.

Please review Round 3 for Final QA approval.

**NEXT: Reviewer (Codex)**

## Turn 6 — Reviewer (Codex)

STATUS: Approved

[Pass — R2 resolved] The replacement receipt reaches the previously bypassed branches. Control 2A runs the real CLI without `--scan-only` and records `--prs pinned for --execute` and the complete matching SHA (exit 0). Control 2B runs the real merging invocation with `--resume --execute` and a mismatched full SHA, returning 2 at `verify_selection` with `#1539 head moved 0000000000 -> 37cd84e670`. Control 2C records the matching full-SHA return map versus mismatched `None`. Together these establish positive pin creation and paired selection acceptance/refusal. Source inspection confirms the dry-run call reaches `pin_selection` and the execute refusal precedes landing preparation. These are inspected producer disposable-clone receipts, not reviewer reruns or a claim that a live merge/reconcile succeeded. The existing help/integer-validation evidence remains sufficient for the reconcile argument contract.

[Pass — scoped final review] The KS-08 text still requires stopped ownership before record mutation, both original/attempt SHA comparisons for OPEN recovery, reconciliation for MERGED, HOLD for changed/unknown outcomes, and preservation of selection and budgets. No outstanding blocking finding remains for this docs change. Retained PDDA output reports `PDDA run complete: no errors, 36 warning(s) to review`.

[Pass — receipt integrity] Reviewer command: `PYTHONDONTWRITEBYTECODE=1 python3` here-document importing `json, hashlib, pathlib.Path`, parsing the six provenance rows, asserting each referenced artifact is nonempty, its length equals `bytes`, and SHA-256 equals `sha256`. Exit 0; decisive output: `PASS manual-check.md`, `PASS outputs/ci-route.txt`, `PASS outputs/disposable-controls.txt`, `PASS outputs/pdda-run.log`, `PASS outputs/positive-cli-controls.txt`, `PASS outputs/skill-diff.patch`. Read-only inspection command `sed -n '260,295p' skills/1-hourly/kickstart/SKILL.md; sed -n '630,720p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '2525,2580p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '2738,2788p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; sed -n '45,75p' PROJECT/2-WORKING/GH-1552-ks08-killed-landing-recovery.md; tail -n 3 TESTS-RESULTS/2026-11-20+GH-1552/outputs/pdda-run.log` exited 0; decisive source output includes `args._pins = verify_selection(...)` followed by refusal on `None`, and the dry-run `pin_selection(...)` call.

Evidence scope: Verify tier, bounded local source and retained-receipt review. Graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge` refers to a separate checkout, generation `2026-11-18T19:39:07Z`; reviewed skill/receipt freshness is missing, so current local bytes were read. Only the relay file was edited. No git command, gate, pytest, or executable fixture was run. Approval is based on the inspected evidence and does not assume any later gate.

**NEXT: Relay complete** — Final QA approved; close RELAY-FINAL-QA with the done verb.
