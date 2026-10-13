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

# GH-800 — MacBook Pro 14-inch M4 Pro, trials 1–3

**Result:** two green trials and one refused trial at a **different commit** from the M6 trial. This is a proposed repin, not matched cross-device data.

| Field | Value |
|---|---|
| Source | `development` at `0ae3452a5774c6e72b633dd61648137e80516e6b`, after #801 and #794 fixed the four suites that were red on the M6 at `a08f30e9` |
| Device class | MacBook Pro 14-inch, Apple M4 Pro; 12 CPU cores; 24 GB RAM |
| OS / toolchain | macOS 15.6; Python 3.14.7 (venv); Node 26.0.0; Apple Git 2.39.5; PHP 8.5.6; requests 2.34.2; PyYAML 6.0.3; pytest 9.1.1 |
| Command | `./validate.sh` in one disposable full clone, no tier or width override; `--print-mode` recorded before trials 2 and 3 |
| Selected mode | parallel, 4 workers (12 cores → cores/2, cap 4), full tier, workers under `nice -n 10`; 417 registered suites |
| Contention | no other gate, relay or poller; trials run back to back with a 60 s cooldown |

| Trial | UTC interval | Wall time | Verdict | Retries |
|---|---|---:|---|---|
| 1 | 02:51:05–03:06:17 | **912 s** | exit 0; 420/420 | none |
| 2 | 03:13:56–03:29:06 | **910 s** | exit 0; 420/420 | none |
| 3 | 03:30:06–03:46:10 | **964 s** | exit 1; 419/420 (refused) | 1 suite, 0.609 s; stayed red |

**All three trials:** median 912 s, range 910–964 s. **Green trials only (n=2):** 910 s and 912 s. Clone identity (HEAD, `core.bare`, origin, clean tree) was unchanged before and after every trial.

Trial 3 failed `gh496-telemetry-isolation.sh` in its concurrency case: one of ten parallel `harness_app.py log` workers exited non-zero against a fresh database, and the case failed again on the isolated rerun. The test discards worker stderr. A standalone repro of the same ten-worker block, run with stderr kept, failed 1 round in 30 with `sqlite3.OperationalError: database is locked` at `PRAGMA journal_mode = WAL` in `harness_app.init_db`. That makes this an intermittent product/test race, not a device fault. The trial stays counted as refused.

`gh251-validate-pytest-skip.sh` was the longest suite in every trial (639.5 s, 640.2 s, 644.0 s). It sets the floor for wall time, as it did on the M6 (590.7 s). `m4pro-trial-{1,2,3}-timings.jsonl` keep sanitized suite, stage and retry timings in the M6 field set.

**Next:** Run the M6 and M1 Max at `0ae3452a` to finish the repin, then compare medians. No device ranking is justified yet.
