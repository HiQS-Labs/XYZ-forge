# Manual Check — GH-1552 (KS-08: Killed-Landing Self-Recovery Protocol)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` (docs route; no new test suite per GH-831).

## Controls Executed (Disposable Coordinator Clone + Real CLIs)
Output log: `outputs/disposable-controls.txt`

1. **Control A — Live Ownership Refusal (Red/Fail-Closed CLI Control):**
   - Seeded `<primary>/.tick/merge-cleanup/HiQS-Labs-XYZ-forge/pr-1501.json` with an `in_progress` attempt via `attempt_record.py reserve`.
   - Held an exclusive `flock` on `<record>.lock` simulating a live landing owner and attempted `attempt_record.py finish --index 0 --outcome aborted-killed`.
   - Result: refused with `rc=2` (lock timeout); `attempts[0]` remained `in_progress` untouched.
2. **Control B — OPEN Head-Unchanged Recovery + Real CLI Contracts + 2-Repair Ceiling:**
   - Verified `attempt_record.py finish --reason` is rejected by argparse (`rc=2`) — confirming `SKILL.md` documents the real CLI (`note --kind diagnosis --text ...` followed by `finish --index <idx> --outcome aborted-<cause>`).
   - Executed `note --kind diagnosis` + `finish --index 0 --outcome aborted-tool-timeout` (`rc=0`), verified diagnosis stored under `attempts[0].diagnosis` and repair count preserved (`len(attempts)==1`), verified 2nd reserve succeeds and 3rd reserve exhausts budget (`rc=3`).
   - Verified `merge_cleanup.py --resume --execute` without `--prs` refuses with `rc=2` — confirming `SKILL.md` requires passing `--prs <original-authorized-N@full-sha-list>` on resume.
3. **Control C — Remote-State Decision Table Walkthrough (MERGED / OPEN-unchanged / OPEN-changed / CLOSED / mixed-batch):**
   - Verified every branch maps deterministically to `--reconcile-pr <N> --execute`, `note+finish+resume(--prs)`, or `HOLD` (never retrying an unknown outcome or switching landing clones).

## PDDA & Route Verification
- `utils/ci-route.sh --base origin/development --head HEAD`: `route=docs`
- `./utils/pdda/pdda.sh run`: 0 errors (see `outputs/pdda-run.log`)

## Positive & Negative Pinned-Selection CLI Controls (`outputs/positive-cli-controls.txt`)
Executed inside a disposable full clone with isolated `HOME` and a read-only fake `gh` shim (answers `pr list` with fixture PR `#1539@37cd84e6...`, refuses any mutating subcommand; zero external/working-tree mutations; pin snapshot contained inside `<tmp-dir>`):
1. `merge_cleanup.py --help` (`rc=0`): confirms `--reconcile-pr`, `--resume`, and `--prs N[@SHA][,...]`.
2. **Real CLI dry-run reaching `pin_selection` (`L2778`, without `--scan-only`):** `merge_cleanup.py --primary <disp-clone> --root <tmp> --prs 1539@37cd84e6... --prs-only` (`rc=0`) validated `#1539`, wrote the pin snapshot inside `<tmp-dir>`, and printed `Pinned for --execute: --prs 1539@37cd84e6...`.
3. **Real CLI `--execute` reaching `verify_selection` (`L2571`) with mismatched pin:** `merge_cleanup.py --primary <disp-clone> --root <tmp> --prs 1539@00000000... --resume --execute --allow-unready-primary` exited non-zero (`rc=2`) logging `REFUSING to merge: the --prs selection no longer matches the dry run: - #1539 head moved 0000000000 -> 37cd84e670`.
4. **Paired `verify_selection` (`L667`) direct match vs mismatch proof:** matching pin returned `{1539: '37cd84e6...'}`; mismatched pin returned `None` with `REFUSING to merge`.
5. `--reconcile-pr not-an-int` (`rc=2`): confirms integer argument validation (`invalid int value: 'not-an-int'`).
