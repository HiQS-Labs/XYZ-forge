# GH-1261 — plan-draft Phase 2B

- **Source:** `f0bb7db9` on `feat/XYZ-forge-gh1261-plan-draft-phase-2b-2026-10-30`, stacked on the GH-1248 branch (`b1dd41a8`, Phase 2A merged)
- **Where:** disposable full clone `XYZ-forge-gh1261-plan-draft-phase-2b-2026-10-30-verify`
- **Platform:** macOS 15.6.1 arm64, Python 3.14.7, `/usr/bin/sandbox-exec`
- **Result:** the loop now drafts issues with no ledger row and resolves bare and `.xyz/` file names. On 20 real issues (10 ledger, 10 unregistered) every request produced a brief, the planner's own waves are unchanged, and the repository ledger stayed byte-identical. #216 now cites its real files and left wave 1. All manual controls pass, including two red controls.

## Pilot (`pilot-3/`)

`init --from-prs --limit 10 --unregistered 10`, then slots 1–22 (`run.txt`: 22/22 completed; slots 21–22 idle).

| Measure | Phase 2A (10 ledger) | Phase 2B (10 ledger + 10 unregistered) |
|---|---|---|
| Briefs | 3 ready, 3 draft, 4 needs-recon | ledger: 3 ready, 7 draft · unregistered: 5 draft, 4 missing-scope, 1 needs-recon |
| Planner waves | 6 lanes / 2 waves | 6 lanes / 2 waves (unchanged) |
| Provisional waves | 9 lanes / 4 waves | 18 lanes / 7 waves; held 5 |
| Ledger | byte-identical | byte-identical; retained receipt in `ledger-identity.txt` (rerun with 3+3 issues: `releases.db` a0c9a6d1…, `releases.sql` b6922bba… before = after) |

The four Phase 2A needs-recon ledger issues all became drafts: their write sets came from bare or `.xyz/` names that now resolve.

**#216** (`slot_004.md`): write set `utils/py/wave_reconcile.py`, `utils/py/_marathon_plan.py` (from `.xyz/utils/py/_marathon_plan.py`), `utils/marathon-plan.sh` (from the capture doc's `.xyz/utils/marathon-plan.sh`) and `PROJECT/PDDA.md`. Unresolved: `marathon-plan.sh` (2 tracked files) and `ROADMAP.md` (72). It moved from wave 1 to wave 2; wave packing is write-disjoint, so no lane in its wave writes any of those paths.

## Controls (`controls.txt`; scripts `gh1261-controls.sh`, `gh1261-controls.py`)

| Control | Result |
|---|---|
| Bare name, one tracked match vs two | resolved to `utils/marathon-plan.sh` vs unresolved with `matches: 2` |
| `.xyz/` path, stripped target in listing vs not | resolved vs dropped |
| Red: #216 issue body without the file index | no paths (the Phase 2A under-count) |
| 25+ resolved citations plus a capture-doc path | 26 paths kept, `PROJECT/PDDA.md` retained; a rival lane writing PDDA lands in a different wave |
| Dependent on a seeded issue that is held / pending | dependent unplaced, held as unmet dependency |
| Same, prerequisite admitted | prerequisite wave 2, dependent wave 7 |
| Red: lookup limited to admitted lanes, prerequisite pending | dependent packed (the R2 bug the fix prevents) |
| Verifier, brief without `unresolved_names` | refused: `plan-draft brief missing keys: unresolved_names` |
| `--unregistered 1` with the issue listing refused (gh shim) | init exits 2, `open issue list failed`, no `state.db` |
| `--unregistered 0` | exits 0, zero `gh issue list` calls |
| `--unregistered 0` vs Phase 2A base harness (`b1dd41a8`), same ledger | identical request issues and order: 418, 1201, 1204, 216, 223, 446, 478, 1205, 670, 722 |

## Smoke (GH-1088)

Main path: the pilot above. Adjacent path (`smoke.txt`): rerunning completed slots 5 and 22 returned their stored `completed` status and changed no file under the run root (tree digest 79f59842… before = after); `status` showed no quarantined ids, lock free, last receipt `slot_022` completed.

## Gate

`./validate.sh` (route=full) on `7bc1742d` in the verify clone: rc=0 in 894s, **409/409** passed; HEAD, origin and clean status identical before and after (`gate.txt`, `gate-7bc1742d.log`). Code diff reviewed: `harness-b1dd41a8..f0bb7db9.diff`. Receipts: `provenance.jsonl`.

## Limits

- Ambiguous names still under-count (`marathon-plan.sh` from an issue body). They are listed in the brief rather than guessed.
- A dependency on an issue that is neither in the ledger nor seeded is still treated as resolved, as the planner does today.
- Unregistered issues are taken most-recently-updated first; umbrella and audit issues land as drafts when they cite files, which mostly pushes them to later waves.
