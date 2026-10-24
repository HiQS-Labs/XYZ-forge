# GH-1193 — manual check receipt (GH-1088 / GH-831: no new suite)

Change under test: `published_retirement_roots()` in `skills/2-daily/merge-cleanup/scripts/scan_clones.py`, used by
`retire_published_checkouts`, `inspect_checkout` (published path only) and `teardown_checkout` in
`merge_cleanup.py` (commit `f7d148ec`). Every run is a **preview** (no `--execute`); nothing was retired.
Provenance per artifact: `provenance.jsonl`.

| Check | Artifact | Result |
|---|---|---|
| **Red control** — base driver (`45eb73a7`) on the real PR #1190 preview | `red-control-base-45eb73a7.txt` | `Published retirement refused: Refusing: path is not strictly within SAFE_ROOTS (…XYZ-forge-gh809-jsonl-line-reader-2026-10-24)`, exit 2 |
| **Main path** — same command, this branch | `smoke-main-f7d148ec.txt` | No SAFE_ROOTS refusal. `-gate` helper → `SAFE_REMOVE_CLONE`, `[DRY RUN] Would remove verified standalone clone`. Task clone → `ACTIVE_PROCESS` (open `claude` handle, PID 94945): a real preservation reason, so exit 1. |
| **Adjacent A1** — NEVER_DELETE parent | `smoke-adjacent-f7d148ec.txt` | primaries under `~`, `~/Documents`, `~/Desktop` → `DEFAULT only`; `~/Documents/GitHub-Repos/XYZ-forge` → `DEFAULT + ~/Documents/GitHub-Repos` |
| **Adjacent A2** — same-origin checkout outside defaults and outside the primary's parent | same | still `Refusing: path is not strictly within SAFE_ROOTS`, exit 2 |
| **Adjacent A3** — `--checkout` = the primary | same | still `protected primary/ancestor or executing directory`, exit 2 |
| Focused suites in the disposable `-gate` clone | `focused-suites-f7d148ec.txt` | `gh534_phase_a_tests.py` exit 0 (includes the §16.1 parity pin) · `gh534_phase_c_tests.py` exit 0 · `gh436-merge-cleanup.sh` exit 0 (pins the sweep's `teardown_checkout(candidate, dry_run=...)` call) |
