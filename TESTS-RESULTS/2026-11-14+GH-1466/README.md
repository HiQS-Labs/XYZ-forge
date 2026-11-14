# GH-1466 evidence: `xyz-vendor.sh --ledger-only`

These are manual checks (AGENTS.md *No new tests*, GH-831), plus existing suites. Nothing is added to any suite. The runner scripts are kept as `.sh.txt` only as a record of the exact commands; they are not test infrastructure.

**Setup**
- Candidate `af858405d`; base `e0586fc30` (`origin/development` at branch cut).
- Every check runs in throwaway host repos under a temp directory with its own `XYZ_REGISTRY`, `HQ_XYZ_REGISTRY` and `HQ_SEARCH_ROOTS`.
- Ledger fixtures are built with the CLI (`releases init`, `add`, `roadmap add`, `roadmap move`).
- Each red control swaps in **only the base copy of the file under test**, on the same host shape.
- Machine paths in the logs are replaced with `<harness>`, `<work>`, `<scratch>` and `<home>`.

| Check | Result | Red control (base or removed file) |
|---|---|---|
| M1 inventory | PASS: 52 files, `tier=ledger`; no `bin/ src/ skills/ test/ relay-automation/` | — |
| M2 missing manifest source | PASS: dies naming `utils/leaderboard.sh`; no `.xyz/` created | scratch harness copy with `utils/leaderboard.sh` removed |
| M3 import check | PASS: dies naming `device_config`; existing `.xyz/` byte-identical | scratch harness with `device_config.py` removed from the manifest |
| M4 vendored PDDA | PASS: `PDDA_MODE=full` frontmatter check on the host doc missing `updated:` exits 1, naming the host path; `releases-current` lists release 9.9.0 from the host DB | base `pdda-lib.sh` → exit 0, no host finding; base `pdda.sh` → "RELEASES.md not found" |
| M5 sticky tier | PASS: `xyz-sync update` keeps `tier=ledger` (52 files) | base `xyz-sync`/`xyz-vendor` on the same shape → `tier=2` (1713 files) |
| M6 flags | PASS: conflict exits 2 with "mutually exclusive"; upgrade → `tier=2` full inventory; downgrade → ledger inventory with `relay-system/` state preserved | base → "unknown option" |
| M7 drift check | PASS: ledger row reports `ok` with no guard warning; a Tier 2 row without relay-drive.sh still warns | base `xyz-sync check` warns on the ledger row |
| M8 hq | PASS: ledger host is Tier B, and `hq fire` refuses with "is not Tier A"; a Tier 2 host is Tier A | base `hq-lib.sh` → ledger host Tier A |
| M9 jog | PASS: `jog run`, `resume` and `land` exit 2 with the message, no traceback | base `releases_app.py` → `ModuleNotFoundError: jog_run` for all three |
| M10 smoke (main path) | PASS: in a ledger-only host with no host tool copies and adopted views: `check` 0; `roadmap add` + `rate` with no `ModuleNotFoundError`; a non-dry-run `wave_reconcile --pr 5291 --offline` exits 0, moves the doc to 3-COMPLETED and the row to Completed, runs the planner, regenerates the preview and `LEADERBOARD.md` (hashes in `M10-views.txt`), and runs the vendored PDDA gate | fresh host without `timeline/RELEASES.html` → rc 6 (template read); fresh host without `marathon-plan.sh` (no fingerprint, planner selected) → rc 6; base `wave_reconcile.py` → rc 7 at the PDDA gate |
| M11 smoke (adjacent path) | PASS: re-vendor with no flags keeps `tier=ledger`. A real two-branch ledger merge conflicts on `releases.db`, `releases.sql` is union-resolved by the documented procedure (`test/gh53` `union_dump`), and `releases-merge-resolve.sh` exits 0 with both sides' releases in the DB and the adopted views regenerated | without `leaderboard.sh` → resolver exits 1 at the leaderboard step |
| Existing suites | PASS: 25/25, listed in `provenance.jsonl` | — |

**Notes**
- `wave_reconcile.py` does not commit; it leaves the reconcile changes for the caller to commit. That is existing behaviour.
- On the system Python 3.9 the planner cannot import (`_marathon_plan.py:122` uses `X | None` syntax). The vendor warns and proceeds. M10/M11 put Python 3.13 first on `PATH`, as an operator must for the planner step on any tier.
