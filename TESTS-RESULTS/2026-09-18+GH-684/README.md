# GH-684 / GH-686 evidence — hosted reconcile lane and the gh53 fixture

Source: `fix/gh684-hosted-reconcile-lane` at the SHA in `provenance.jsonl`. Every run below was
executed in a **disposable full clone** (`/tmp/xyz-gh684-probe`), never in the task clone
(AGENTS.md: no `test/*.sh` from a clone whose state matters). Mutations for the red controls were
applied there and undone with `git reset --hard` before the next control; the clone's tracked
diff was empty at the end (`summary.txt`, last line). No operator source, ledger, workflow run or
deployed skill was touched.

## Positive

- `gh421.log` — `test/gh421-auto-wave-reconcile.sh`: 31 tests, exit 0. Includes the four GH-684
  cases: mixed batch with a defective backlog doc (skipped, reported once, other item lands,
  retried with its receipt present, ships after repair); explicit landing with the same doc
  still exits 5 with full rollback; planner `already-closed` drift for a skipped issue is
  *unrelated*; the same drift for a reconciled issue is fatal; workflow pins.
- `gh684-report.log` — `test/gh684-hosted-lane-report.sh`: 8 tests, exit 0, with a recording `gh`
  stub. The omitted-run-URL mutant is an in-suite case and is caught.
- `gh53-head-10x.log` — `test/gh53-releases-merge-resolve.sh` ten times at the PR head: 10/10.
- `neighbour-*.log`, `gh308-guard.log` — reconciler neighbours (`gh496`, `gh202`, `gh232`,
  `wave-reconcile.sh`, `gh358`) and the frozen-twin guard against `ba1f58e8`: all green.
- `validate-full.log` — the complete `validate.sh` gate in the disposable clone (see its tail for
  the summary and any baseline-red suites; compare with `TESTS-RESULTS/2026-09-17+GH-681/`).

## Red controls (single-site mutations, each restored)

| control | mutation | expected red | witnessed |
|---|---|---|---|
| 1 | S2's `if ll_err:` → `if False and ll_err:` (the skip only) | gh421 (a) skip case, (c) unrelated case | yes — both red, (b) explicit fail-closed green |
| 2 | `reconciled_issues.discard(issue_num)` → `pass` | gh421 (c) planner drift for a skipped issue | yes — (c) red, (a) green |
| 3 | `wave-reconcile.yml` reverted to `ba1f58e8` | gh421 `test_report_step_and_permissions` | yes |
| 4 | gh53 `union_dump` settings-row dedupe removed (sleep + timestamp assert kept) | `union kept 2 generation settings rows` | yes, deterministically |

## Witness of the pre-fix flake

`gh53-base-40x.log` — the same suite forty times at unmodified `ba1f58e8`: **33 pass / 7 fail**
(17.5 %). Same machine, same session, minutes apart from the 10/10 at the PR head.

Not claimed: the hosted runner. The workflow is disabled (#684); the post-merge dispatch is the
hosted proof and is recorded on #684 when it runs.
