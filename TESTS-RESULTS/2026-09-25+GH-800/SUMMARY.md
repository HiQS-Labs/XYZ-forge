# GH-800 — Mac mini M6 full-suite trial 1

**Result:** full gate refused. This is a measured failure run, not a green performance baseline or a cross-device speed ranking.

| Field | Value |
|---|---|
| Source | `development` at `a08f30e9224219acef83be02a0a5bfe0af198849` |
| Device class | Mac mini M6; 12 CPU cores; 32 GB RAM |
| OS / toolchain | macOS 27.0; Python 3.9.6; Node 24.21.0; Apple Git 2.54.0; requests 2.32.5; PyYAML 6.0.3; pytest 8.4.2 |
| Command | `./validate.sh` in a disposable full clone, no tier or width override |
| Selected mode | parallel, 4 workers, full tier; 417 registered suites |
| UTC interval | 2026-09-25 01:02:00–01:20:03 |
| Wall time | **1,083 s (18m 03s)** |
| Verdict | exit 1; 416/420 passed, 4 failed; clone identity unchanged and working tree clean |
| Retry cost | 4 isolated reruns, 151.977 s total; all 4 stayed red |

The persistent failures were `gh777-inventory-ratchet.sh` (new loose script), `gh139-pipe-grep-guard.sh` (10 new pipe-to-`grep -q` sites), `gh674-merge-cleanup-hosted-lookup.sh` (`merge_cleanup` import failure), and `gh436-merge-cleanup.sh` (failed on isolated retry; final gate excerpt did not preserve its decisive assertion). These are observations at the pinned commit; this campaign does not attribute them to the M6.

The longest pooled suites were `gh251-validate-pytest-skip.sh` (590.721 s), `relay-self-sufficiency.sh` (267.276 s), and `gh549-work-events.sh` (241.360 s). These durations overlap across four workers and cannot be summed as wall time. `m6-trial-1-timings.jsonl` retains sanitized per-suite, retry, and stage durations. `provenance.jsonl` records the final result.

An earlier setup attempt was stopped after 678 s when Node was missing from that shell's PATH. It had no complete gate verdict and is excluded from timing comparison. The corrected trial explicitly verified Node and the Python imports before running. The setup attempt remains in provenance so the failed work is visible.

**Next:** Restore a green full-suite baseline on the pinned commit (or explicitly repin all three devices together), then complete repeated uncontended runs on each device and compare medians and ranges. No device ranking is justified by this single refused M6 run.
