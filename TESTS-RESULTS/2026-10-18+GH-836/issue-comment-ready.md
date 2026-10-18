## Isolated #836 spike result — CONTINUE the small fixture change

On the Mac Studio, the existing gh549 focused suite fell from **234.95 s median to 75.00 s**, saving **159.95 s (68.1%) per isolated invocation**. All four runs passed **125/125**, without retries, rescues or skips.

| Same-base pair | Baseline | Candidate | Saving |
|---|---:|---:|---:|
| 1 | 236.80 s | 75.58 s | 161.22 s |
| 2 | 233.10 s | 74.42 s | 158.68 s |

Observed range: **3.70 s baseline / 1.16 s candidate**; only two samples each. This establishes a local focused-suite payoff, not hosted/whole-pipeline performance or release qualification.

**Current base / prior art.** Both full clones came from canonical development at `655bc340b9e64056645a75f340e842c79371df3f`, including #1123. #838 already removed gh436's parity double execution and earlier gh549 race/dispatch costs; #848 already moved gh436 to Large. Those changes were recorded, not rebuilt or counted again. No other #836 writer/open PR was found in the checked siblings, processes, threads and PR inventory; the stopped batch was not resumed.

**Candidate `4197743824f4a08abf00658029048cd6e617f9e3`.** Only three existing setup lines in `test/gh549-work-events.sh` change, plus comments. FXD, FXI and FXR7 now use the existing `releases init --slug XYZ-forge` instead of copying the live ledger (377 roadmap rows / 835 events / 1,987 receipts). The two empty interleave databases no longer inherit a cursor from the unrelated live ledger. No helper, product/routing change, shared mutable fixture, new CI case/assertion/parameter or coverage removal.

**Coverage retained.** FXD builds the same five mapping rows, four eligible for backfill; FXI builds its 9920 interleave and 9903 Completed/open-PR scenarios; FXR7 independently builds 9920. Separate copied race/mutation databases, real concurrent processes, rendezvous, receipt joins, nonempty checks and every existing assertion remain. Normal migration/round-trip/connector fixtures still read the live ledger. Both candidate positive races were **4=4**; both existing broken-transaction controls duplicated **7>4**, with racer exits 0/0. Existing interleave red controls all passed. All 125 success labels match A/B after numeric normalization; raw logs retain actual count/exit differences and unchanged final exit logic.

**gh436 is already solved for this ask.** Current `parity_failures` has no nested behavioral runner. Its **seven existing parity checks passed in 1.83 s**, including missing-reference detection. The 180-test collection contains all **18 current required named methods exactly once**. No full current gh436 behavioral run or new gh436 speedup is claimed. Historical #836 witnesses retain deleted-row/forced-behavior-failure controls and staggered races, with their invalid first injection explicitly excluded.

**Reproduction / limits.** Ordered A1/B1/A2/B2, serial, same frozen ledger/runtime, independent temporary state, default caches. Exact command: `/usr/bin/time -p bash test/gh549-work-events.sh`. Mac13,1 / M1 Max / 10 cores / 64 GiB; macOS 15.6.1; Python 3.14.7, Bash 3.2.57, Git 2.50.1, SQLite 3.43.2. Four timed runs cost 619.90 s; setup/review costs were not separately timed. No suite failed. Setup/edit/parser refusals and the invalid first collection parser are retained and explained, rather than counted as passing evidence.

Local evidence: `TESTS-RESULTS/2026-10-18+GH-836/` on `fix/XYZ-forge-gh836-gate-hotspots-2026-10-18`, mirrored in the task workspace, with raw logs, exact patch, reproduction scripts, identities, environment, fixture inventory and SHA-256 provenance. Evidence and candidate are **local only**, not yet published. Full report: `GH-836-spike-report.md` in the task workspace.

**Review:** Plan and final independent Codex QA both Approved in round 1/3; final reviewed head `530d3b307b376a3daf41cd11b8267887ef0da7d1`, attested at `a6aa2034`. No cap reset or extension.

**Recommendation:** CONTINUE with this surgical candidate; PARK additional parity de-duplication work because the requested fix already exists. No full-suite campaign, policy change, parallel qualification, broader rollout, push, PR or merge was performed. [#1131](https://github.com/HiQS-Labs/XYZ-forge/issues/1131)'s cadence decision and separately approved implementation remain distinct; neither parallel qualification nor a broad CI rollout is a prerequisite for this hotspot result. Stop this spike here.
