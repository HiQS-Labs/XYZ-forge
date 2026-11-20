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
