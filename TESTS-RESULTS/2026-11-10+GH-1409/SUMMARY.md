# GH-1409 — vendored-smoke judge pinning: verification receipt

Tested head: `69030ddab` (ci.yml pin step plus quoting fix). All runs used a disposable full clone of the task
branch, with origin repointed to a nonexistent path and HOME sandboxed. The clone's identity (HEAD, bare flag,
clean status) was unchanged after every run. There is no new suite or registry entry (GH-831).

## Manual controls

Each control is a constructed `--no-ff` merge with `HEAD^1` = base and `HEAD^2` = a throwaway PR commit. The
vendored-smoke step bodies are extracted verbatim from `.github/workflows/ci.yml`. Procedure:
`controls-procedure.md`; decisive lines: `control-results.txt`; machine record: `provenance.jsonl`.

| Control | Mutation | Expected | Observed |
|---|---|---|---|
| Red 1 | dummy script added to the baseline | pin step fails | exit 1, "baseline grew … utils/zz-dummy.sh" |
| Red 1b | extra distinct bypass location, declared count unchanged | pin step fails | exit 1, "baseline grew … bypass count" |
| Red 2 | marker moved to a new `sqlite3.connect(` line | pin step fails | exit 1, "new SQLITE-*-OK suppression marker added" |
| Red 3 | gh396 replaced by `exit 0`, vendored `TICK_REPO_ROOT` broken | vendored suites fail | the restored base gh396 FAILs on the exact regression; exit 1 |
| Green | one `utils/` script retired plus `--update-baseline` | all pass | pin 0, ratchet 0, vendored suites 0 |
| Label | Red 1 with stubbed `judge-change` label | warning, pin skipped | warning, exit 0 (proves the branch only) |
| Label + Red 3 | discriminator: Red 3 without the pin | neutered suite passes | vendored suites 0, so the pin is what catches Red 3 |

The green control's first run, at `5311011bf`, caught a real defect. A single-quoted literal inside the inline
Python closed the `bash -c` quote, so every PR would have failed the step. It is fixed in `69030ddab`.

## Existing focused suites

- `test/ci-workflow.sh`: rc 0 (failed 0, skipped 0)
- `test/gh308-frozen-twin-guard.sh`: rc 0 (38 pass, 0 fail)

## Smoke (GH-1088)

- **Main path:** this PR's own hosted `vendored-smoke` run, which logs the base, PR head and merge SHAs and
  runs the pinned judges. The receipt is the PR's check run.
- **Adjacent path:** the label branch and the legitimate-shrink path (the Label and Green rows above).

## Not verified here

- Live `gh pr view` label lookup under `contents: read`, and re-run-after-labelling. These need a hosted run.
