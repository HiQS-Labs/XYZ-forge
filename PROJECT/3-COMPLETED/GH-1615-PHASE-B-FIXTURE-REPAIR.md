---
title: "Make the merge-cleanup phase B suite green when run on its own; the gate already runs it (correct the 'ungated' premise)"
status: Complete
created: 2026-11-25
updated: 2026-11-26
owner: Noel Saw
gh_issue: 1615
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1615
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: d3b238ed5
non_goals:
  - registering `test/gh534_phase_b_tests.py` in `validate.sh`, `ci-local.sh`, CI or any suite registry (GH-831; and unnecessary, see Observed: the gated `gh436` entry point already collects it)
  - retiring or deleting the suite (the gated entry point imports it wholesale)
  - any change to `merge_cleanup.py`, `ledger_merge.py` or any production code (GH-1576's behaviour is correct)
  - editing `test/gh436-merge-cleanup.py` (gated; its module-level stub is left as is)
  - a new test file or a new test
related:
  - 1576
  - 1606
  - 831
  - 1614
goal: "Running `python3 test/gh534_phase_b_tests.py` (and phase C, which imports its classes) on a clean clone passes again, by moving the GH-1576 wiring stub from the one aggregator that has it into the shared fixture every entry point uses, with the gated run proven unchanged and the issue's wrong premise corrected on the record."
---

# GH-1615: Make the phase B suite green standalone (the gate already runs it)

## Status

| What was just completed | What's next |
|---|---|
| Plan approved by Codex on round 2 (round 1: one finding, retained receipts, closed). Implemented in `1a9cf2823`: phase B 39/39, phase C 111/111, gated wrapper 227 OK, both production mutants rejected, importer driver 18/18; evidence under `TESTS-RESULTS/2026-11-25+GH-1615/`. | Qualification gate and push from a disposable clone, ready PR (final Codex QA approved round 1, attested). Merge is the operator's. |

## Observed (measured at base `d3b238ed5`, not remembered)

| Claim | Command / source | Observed |
|---|---|---|
| The file is red when run on its own | `python3 test/gh534_phase_b_tests.py -v` in a disposable full clone, test venv first on PATH | `Ran 39 tests in 78s`, `FAILED (failures=14, errors=1)` |
| The red report hides its own cause for most tests | the end-of-run report parsed block by block | only 4 of 15 blocks print the wiring refusal (those tests pass `self.err` as the assertion message); the rest show `2 != 3`, `2 != 4`, `2 != 0`, `'OPEN' != 'MERGED'`, a missing-file error, or an empty-conflict-set handoff |
| **One cause explains all 15** (a falsification experiment that could have left residue) | the same file run from a runner outside the repo that applies ONLY the one-line stub `test/gh436-merge-cleanup.py:43` applies | `Ran 39 tests`, `failures=0 errors=0`, `OK` |
| The cause | `prepare_landing_clone` calls `gate_unwired_reason(clone, install=True)` (GH-1576); `LedgerFixture.setUp` (`test/gh534_phase_b_tests.py:175-204`) seeds a synthetic repo with no `githooks/` | `landing clone gate wiring failed: githooks/install.sh is missing ... (GH-1576)` before any repair, exit 2 |
| **The gate already runs these tests** (this overturns the issue) | `test/gh436-merge-cleanup.py:1380-1384`: `from gh534_phase_a_tests import *`, `from gh534_phase_b_tests import *`, `from gh534_phase_c_tests import *`, "one registered entry point (A.6)"; `validate.sh:96` registers `gh436-merge-cleanup.sh`; collection-only count | the gated entry point collects **227 tests = 95 own + 46 (A) + **39 (B)** + 47 (C)**; all 39 phase B tests, including the four skill-table pins, run in the gate |
| Why the gate stayed green | the same file `test/gh436-merge-cleanup.py:38-43` | it assigns `merge_cleanup.gate_unwired_reason = lambda ...` at module level, **inside its own process only**; entry points that bypass it get no stub |
| The gated run is green at this base | `python3 test/gh436-merge-cleanup.py -v` at `d3b238ed5` | `Ran 227 tests in 252s`, `OK` (exit 0). The 39 phase B tests are inside it: collected 39; 19 show an individual `ok` line in the verbose log, 20 have their status line interleaved with their own printed output, and no failure appears anywhere; the run's summary line is the authority |
| Phase C standalone | `python3 test/gh534_phase_c_tests.py` at `d3b238ed5` (it imports phase B's `LedgerFixture`, `TestE6Gate`, `TestPhase5EndToEnd`, line 34) | `Ran 111 tests in 197s`, `FAILED (failures=32, errors=1)`; its own classes (`TestCScript`, `TestGh623Resilience`) also derive from `LedgerFixture`. With **only the one-line stub** (experiment 1c, outside the repo): `Ran 111`, `failures=0 errors=0`, `OK`. Same single cause; the shared-fixture change repairs both suites |
| Phase A standalone | `python3 test/gh534_phase_a_tests.py` | `Ran 46 tests ... OK` (it builds no landing clones) |
| Fixture subclasses and setUp |  AST scan of phase B and C | all `LedgerFixture` subclasses inherit `setUp` or call `super().setUp()` first; the only reference to `gate_unwired_reason` in tests is `gh436:43` (row `SETUP-OVERRIDES`) |
| Other code reuses the fixture | `git grep LedgerFixture` | `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py`, `TESTS-RESULTS/2026-11-25+GH-1606/run_controls.py`, phase C |

**Retained receipts (plan QA R1-1).** Every run in the table above has a row in `TESTS-RESULTS/2026-11-25+GH-1615/provenance.jsonl` (rows `BASE-B-red`, `EXP-1-B`, `BASE-C-red`, `EXP-1-C`, `BASE-A-green`, `GATED-BASE-green`, `COLLECTION`, `REPORT-VISIBILITY`, `IMPORTERS`, `SKILL-PINS`, `SETUP-OVERRIDES`) with its command, revision, exit status and decisive output. The two experiment runners (`run_stubbed_phase_b.py`, `run_stubbed_phase_c.py`), the collection counter (`collect_count.py`) and the path-scrubbed failing-test lists (`failures-at-base.txt`, 15 for B and 33 for C, each reconciled to its run summary) sit beside it. The full raw logs were not kept (path-bearing, 400 KB).

### What the issue and earlier evidence got wrong (recorded, not hidden)

- Issue #1615 says "No automated gate runs it" and "dead coverage over a repair path". **Wrong:** the file is not registered *by name*, but the registered `gh436` entry point imports it with `import *`, so all 39 tests run in the gate.
- The #1606 evidence (`TESTS-RESULTS/2026-11-25+GH-1606/`, merged in #1614) said "no gated suite reaches the B1 reserve path" and "referenced by no gate". **Overstated for the same reason.** Those files are history and are not rewritten here; this plan, its summary, the PR body and the closeout comment carry the correction.
- Nothing in #1606's conclusions depends on it: its controls ran through its own driver, and the three gated suites it re-ran (which include these 39 tests) were green.

## Root cause vs proximate cause

- **Origin:** GH-1576 put its test shim in the one place that was its immediate concern, the `gh436` aggregator's module level, and not in the fixture that builds the landing clones. Every entry point that goes through the aggregator is protected; every entry point that does not (phase B alone, phase C alone) fails.
- **Fixed here:** that class for everything built on `LedgerFixture` (phase B, phase C, the two evidence drivers). The fix moves the shim to where the fixture is.
- **Not claimed:** that other shims never live only in the aggregator; not traced. The fix is at the origin of *this* failure, not a general guarantee.
- **Fix site = the fixture,** not production: GH-1576's refusal is correct and stays.

## Keep or retire (a recorded decision): KEEP, and retirement is not even available

`test/gh436-merge-cleanup.py` imports the file wholesale; removing it breaks the gated entry point and deletes 39 gated tests. The cost of keeping is one fixture change.

## Plan (smallest honest repair)

One change, in `test/gh534_phase_b_tests.py`, `LedgerFixture.setUp`: start a **scoped** patch of `merge_cleanup.gate_unwired_reason` returning `""` and register its `stop` with `addCleanup`, next to the existing environment patch in the same method. Comment: why (GH-1576; the synthetic seed has no `githooks/`; the subject is landing/repair/ledger, not hook wiring), where the refusal itself is witnessed (`TESTS-RESULTS/2026-11-21+GH-1576/`), and that `gh436` stubs it for its own process.

Why scoped and not `gh436`'s module-level assignment: the fixture is imported by phase C and two evidence drivers; a module-level assignment would change `merge_cleanup` for any process importing the file. A scoped patch changes it only while a fixture test runs and restores the previous value (inside `gh436` that value is `gh436`'s own stub, so it stacks and unwinds correctly).

## Alternatives considered (ranked)

| # | Alternative | Verdict |
|---|---|---|
| 1 | **Scoped patch in `LedgerFixture.setUp` (chosen)** | 4 lines; fixes B and C standalone through the one shared fixture; no leak; stacks under `gh436` |
| 2 | Module-level assignment like `gh436:43` | Rejected: leaks into every importer |
| 3 | Seed a stub `githooks/install.sh` so the real `gate_unwired_reason` runs | Rejected as smallest: breaks again the next time the check grows beyond the installer, which is how this broke |
| 4 | Retire the suite | Impossible without breaking the gated entry point; rejected |
| 5 | Register the file in a gate | Unnecessary (already gated through `gh436`) and forbidden by GH-831 without a decision; rejected |
| 6 | Do nothing (it is only a standalone-run problem) | Rejected: the standalone command is how this suite is cited in evidence and relay briefs, and a misleading red already produced wrong conclusions on the public record |

## Acceptance and red controls (no new tests: AGENTS.md *No new tests*, GH-831)

Evidence under `TESTS-RESULTS/2026-11-25+GH-1615/` with `provenance.jsonl`; runs in disposable full clones, never the primary.

| ID | Check | An unchanged / unfixed candidate fails because | Expected |
|---|---|---|---|
| AC-1 | Base, clean clone: `python3 test/gh534_phase_b_tests.py` | this is the red control | `Ran 39`, `failures=14`, `errors=1` (recorded) |
| AC-2 | Candidate, clean clone, same command | an unrepaired fixture leaves red tests | `Ran 39`, `failures=0`, `errors=0` |
| AC-3 | Candidate: phase C standalone | the shared fixture is not what phase C needs | C green (counts recorded against its base run) |
| AC-4 | **The gate path, which now executes the changed fixture:** `bash test/gh436-merge-cleanup.sh` on the candidate | the scoped patch interacts badly with `gh436`'s module-level stub | green, `Ran 227`, same as base |
| AC-5 | Not vacuous: two production mutants in scratch copies must turn the specific pinned test red on the candidate | a stub that over-masks, or a suite that cannot fail, stays green under a real regression | mutant A (`deferred_set = deferred_closure(all_ordered, eligible)` replaced by `deferred_set = set()`, so the `--prs` allowlist stops deferring unlisted PRs) makes `test_unlisted_pr_is_never_sequenced` red; mutant B (disable the remote-head-moved refusal in `push_resolved_head`) makes `test_remote_head_moved_during_resolution_is_not_pushed` red; each mutant verified to differ from the original, and each must fail on the test's **own assertion** (not an import, syntax or environment error) while the same test is green on the unmutated candidate |
| AC-6 | Importers: `run_controls.py` (GH-1606 driver) against the candidate | the scoped patch changes behaviour for importers | 18 of 18 driver rows pass |
| AC-7 | The four skill-table pinned tests pass standalone | they stay red | `ok` for `test_same_key_update_on_both_sides_is_handoff_and_nothing_is_overwritten`, `test_unknown_mergeable_settles_and_the_pr_lands`, `test_unlisted_pr_is_never_sequenced`, `TestE6Gate.test_gate_red_prevents_the_merge` |
| AC-8 | Scope: `git diff --name-only origin/development..HEAD` | a `validate.sh`, `ci-local.sh`, `.github/`, `gh436`, production or new `test/*` file in the diff | only `test/gh534_phase_b_tests.py`, this doc, `TESTS-RESULTS/2026-11-25+GH-1615/*`, relay threads, `releases.db`, `releases.sql` |

Guarantees touched and how each is attacked: the gated entry point (AC-4), the 24 tests that already passed standalone (AC-2), importers (AC-6, AC-3), and the suite's ability to fail (AC-5).

## Smoke (GH-1088)

Main path: the repaired file on a clean clone (AC-2). Adjacent path: the same suite run via `python3 -m unittest test.gh534_phase_b_tests` from the repo root (the other documented invocation) and from a different working directory; both 39/39.

## Risks and accepted limits

- **Masking:** the stub removes the wiring check from phase B/C fixtures. Accepted: neither suite asserts on wiring (grep), the refusal has its own evidence, `gh436` already stubs it, and AC-5 shows the suite still fails on real regressions.
- **Untraced:** whether other shims live only in an aggregator.
- **Unchanged by design:** `gh436`'s own module-level stub (now redundant for the fixture, harmless), left alone to keep the gated suite out of the diff.

## Operator decisions left open

None required. The question the issue posed ("should it run automatically?") is answered by the evidence: it already does, through `gh436`. Optional, no recommendation to act: whether to later delete `gh436`'s now-redundant stub.

## Per-issue rating (RELEASES vocabulary, 1-100)

`20/25/50/85` (pri/sev/appeal/effort), **re-rated with `--force`** from the `30/35/50/65` proposed in the issue and used at pickup, because the evidence changed what the defect is. Severity 25: no coverage is lost (the gate runs it); the defect is a misleading red on standalone runs of two suites, which has already put wrong claims on the public record. Priority 20: nothing is blocked. Effort = cheapness 85: four lines plus evidence. Appeal neutral. No operator override on the row.

## Lessons learned

NO_ENTRY at plan time.

## Recon ledger

- `prior_art_recon.py --query "gh534 phase B merge-cleanup suite red fixture githooks install GH-1576"`: 0 open PRs, 0 merged, no existing fix candidates; only #1615 matches.
- Baseline, grouping, experiment 1, importer search, history check: in the table above.
- **Two corrections to my own method, recorded:** (1) grouping the 15 failures by message revealed only 4 causes, so I stopped grouping and ran the falsification experiment; (2) the "gated" finding came from noticing that phase C imports phase B's classes, which led to `gh436:1380-1384`; it overturned the issue's premise and two statements I had helped put on the record.
