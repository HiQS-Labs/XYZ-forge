# Manual contract verification — candidate 76ad7e4e

Source SHA: `76ad7e4e1ec64afe4b63383b3dc4e80cd9549a2d`.

The eight requested acceptance checks passed. See `results.json` for observations and
`provenance.jsonl` for source hashes, commands/API calls, and UTC receipts. Full
schema-1.0 spawn-error and SIGTERM/SIGINT rows were filtered from their fixture logs
to exclude the deliberately fake prior row before running `checkin.py --json` and
`compile_issue.py --dry-run`.

The separate `zero-budget-uncommitted.json` captures an additional observation:
with a zero-minute budget and a 0-commit disposable target, the runner returns 2 and
preserves the preexisting row, but writes the control file and creates the baseline
commit before the run loop notices that no variation was attempted. The approved
plan requires nonzero exit and no new invocation rows for this case; it does not
require empty-grid-style no-write admission. Treat this as initialization behavior
outside the acceptance scope, not a candidate defect.

All target Git operations used freshly initialized repositories inside this evidence
directory. No suite/gate ran, no network/service/GitHub operation was made, and no
candidate source file was edited. The timeout check used only bounded local Python
fixtures; the linked-worktree mutation was limited to its disposable host fixture.
