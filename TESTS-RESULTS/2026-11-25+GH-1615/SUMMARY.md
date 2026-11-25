# GH-1615 verification summary (manual checks; no new tests, GH-831)

Change: `LedgerFixture.setUp` in `test/gh534_phase_b_tests.py` now starts a scoped patch of
`merge_cleanup.gate_unwired_reason` (returns `""`) and registers its `stop` with `addCleanup`
(8 added lines including the comment, no deletions). Base `d3b238ed5`; candidate `1a9cf2823`.

Evidence is `provenance.jsonl` (one row per check, each with command, revision, exit status and decisive
output). `run_stubbed_phase_b.py` / `run_stubbed_phase_c.py` are the experiment runners, `collect_count.py`
the collection counter, `failures-at-base.txt` the path-scrubbed failing-test lists.

## What was wrong, and what the premise really was

| | Base `d3b238ed5` | Candidate `1a9cf2823` |
|---|---|---|
| `python3 test/gh534_phase_b_tests.py` | 39 run, **14 failures, 1 error** | 39 run, **OK** |
| `python3 test/gh534_phase_c_tests.py` (imports phase B's fixture and classes) | 111 run, **32 failures, 1 error** | 111 run, **OK** |
| `bash test/gh436-merge-cleanup.sh` (the registered gate entry point; `import *` of phases A, B, C) | 227 run, OK | 227 run, **OK** (changed fixture now runs inside the gate) |
| `python3 test/gh534_phase_a_tests.py` | 46 run, OK | not affected (builds no landing clones) |

- **One cause, shown by experiment:** applying only the one-line stub `gh436` applies (from a runner outside the repo) turns phase B 39/39 and phase C 111/111 green, so all 15 + 33 red results were the same GH-1576 wiring refusal (`githooks/install.sh is missing`), hidden in most failure messages (rows `EXP-1-B`, `EXP-1-C`, `REPORT-VISIBILITY`).
- **The issue's premise was wrong:** the gate already collects and runs all 39 phase B tests through `gh436` (rows `COLLECTION`, `GATED-BASE-green`); it stayed green because `gh436` stubs the check inside its own process only. The defect is that the **standalone** entry points of phases B and C were red. Earlier statements that no gate covers the B1 repair path (issue #1615, and the GH-1606 evidence merged in #1614) were overstated and are corrected here, not rewritten.

## Controls on the candidate

| Row | Result |
|---|---|
| `CAND-B-green`, `CAND-C-green`, `CAND-GATED-green` | 39 OK, 111 OK, 227 OK |
| `MUT-A-rejected` | Production mutant A (the `--prs` allowlist stops deferring unlisted PRs): the pinned test fails on its own assertion (`3 != 0`, the unlisted PR was processed); green on the unmutated candidate |
| `MUT-B-rejected` | Production mutant B (the remote-head-moved refusal disabled): the pinned test fails on its purpose-built assertion (`'remote head moved' not found`); green unmutated |
| `IMPORTER-DRIVER` | The GH-1606 driver, which imports `LedgerFixture`, passes 18 of 18 rows against the candidate |
| `PINS-4-green` | The four skill-table pinned tests pass individually |
| `SMOKE-adjacent` | `python3 -m unittest test.gh534_phase_b_tests` and a run from a different working directory: 39 OK each |
| `SCOPE` | One existing test file changed; no `validate.sh`, `ci-local.sh`, CI, `gh436`, production or new test file |

## Notes and limits (stated, not hidden)

- The stub removes the wiring probe from every `LedgerFixture` test. Neither suite asserts on wiring (grep), the refusal has its own evidence (`TESTS-RESULTS/2026-11-21+GH-1576/`), and the mutants show the suites still fail on real regressions.
- Other shims that live only in an aggregator were not traced.
- `gh436`'s own module-level stub is now redundant for the fixture and is left alone on purpose (a gated suite stays out of this diff).
- The raw 400 KB baseline logs were not kept (absolute temp paths); the receipts keep the decisive lines and counts.
- The first review round was counted by the driver as a stall because the reviewer used sub-headings; the content was a real review (verdict FAIL, one finding, closed by these receipts).
- Operator decisions left open: none required.
- Not yet run at the time of this summary: the repository qualification gate for the pushed commit and the final independent review.
