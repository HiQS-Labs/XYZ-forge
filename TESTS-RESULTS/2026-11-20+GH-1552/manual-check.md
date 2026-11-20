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

## Positive CLI Controls Added (Final QA R1 Follow-Up — `outputs/positive-cli-controls.txt`)
All three bounded controls executed inside a disposable full clone with zero remote or working-tree mutations (`git status` clean):
1. **`merge_cleanup.py --help` (`exit 0`):** verified `--reconcile-pr RECONCILE_PR`, `--resume`, and `--prs N[@SHA][,...]` CLI flags.
2. **Real CLI positive pinned `--prs 1539@<40-hex-sha> --resume --scan-only` (`exit 0`):** proved the real CLI accepts pinned full-SHA selection with `--resume` in non-mutating scan mode (paired against the negative missing-`--prs` refusal in Control C).
3. **`--reconcile-pr` argument validation (`exit 2` on invalid non-int `not-an-int`):** proved parser enforcement of integer PR numbers.
