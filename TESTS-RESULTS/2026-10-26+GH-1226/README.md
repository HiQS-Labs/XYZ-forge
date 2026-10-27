# GH-1226 manual smoke — merge-cleanup `--prs` allowlist + required-check gate

`smoke.py` drives the real `merge_cleanup.py` CLI against the phase-B fixture (a bare origin plus
the suite's `gh` stub). It covers the main path and the adjacent operator paths. `smoke.log` is the
output, with fixture paths redacted. `provenance.jsonl` names the commit.

| # | Path | Expected | Observed |
|---|---|---|---|
| 1 | merging `--execute`, no `--prs` | refuse rc 2, before any mutation | rc 2 |
| 2 | dry run `--prs 1` | pins #1's head; #2 `not in --prs` | rc 0, pinned |
| 3 | `--execute --prs 1,3` (#3 opened after the dry run) | refuse: #3 not pinned | rc 2 |
| 4 | **main**: `--execute --prs 1` with #2 and #3 open | only #1 lands; merged ⊆ list | rc 0; #2 and #3 OPEN |
| 5 | dry run `--prs 2` | pins #2; #3 `not in --prs` | rc 0, pinned |
| 6 | head moved after the dry run | refuse: head moved | rc 2 |
| 7 | re-pin after the move | pins the new head | rc 0, pinned |
| 8 | required check `pytest db fast` pending | defer, not merged | rc 3; #2 OPEN |
| 9 | rerun after the check passed (same pin, `--resume`) | lands | rc 0; #2 MERGED, #3 OPEN |

Verdict: pass. The B1-repaired-head deferral is exercised by the existing suite
(`TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it`, now a
two-step run → re-pin → `--resume`).

## Full gate (`./validate.sh`, route=full) on the final commit

Run once in a disposable full clone at `db2f6e8`, rc 1. Seven suites failed:

- **`gh436-merge-cleanup`:** one test failed, `test_iv_unreadable_event_log_preserves`. The container
  runs as root, so the chmod-000 event log is still readable. It fails the same way at `origin/development`.
- **`gh478`, `gh518`, `gh409`, `gh544`, `gh648`, `gh123`:** process-group reaping, worktree setup,
  lock timing and the pre-push merge-base fixture. Each fails the same way at `origin/development`
  in this Linux container, which is not the macOS shipping platform.

The six other suites do not cover merge-cleanup; the one `gh436-merge-cleanup` failure is the
root-only test that fails identically on the baseline. A qualifying run on macOS is still owed.
