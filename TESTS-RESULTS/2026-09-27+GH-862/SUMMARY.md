# CI Suite Audit — Sample Validation Summary (GH-862)

- **Audit Date:** 2026-09-27
- **Registry SHA:** f84f711c
- **Target Branch:** `feat/gh862-ci-suite-audit` (branched from `staging/stabilize-2026-10`)
- **Analysis Mode:** In-checkout (read-only, disk tools + multi-source telemetry)
- **Total Registered Suites:** 411
- **Sampled Suites Evaluated:** 30 (seed `20261008`)
- **Median Full-Gate Runtime:** 2918.5 s (~50 min)
- **Gate Yield:** **6 of 30 suites (20.0%)** proposed to leave the PR gate (QUARANTINE, TURN-OFF, MERGE).

### Committed Telemetry Receipts Loaded
- `TESTS-RESULTS/2026-09-27+GH-591/wave-030ab5ba0b8d375f3a5aad87246a4288333ed656/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-0cdda91a8f6d741b93d96fcb9837d8810e4a9ef9/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-12cccb93806ad79923dc14b7e0f29fd644fe3739/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-1eef93a36887d407868319c7a2d925821a782a52/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-73fc2e3214459e7000df142896ddcbff75e4a0ca/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-8ecaa8af013c0e0f45cf15bfc516145285872c4a/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-ad923412a2f23684a2d6abc8462041798ce24f21/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-d469343d117e241e407b142395a95c7eefe98ae3/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-e53939d68f9b7f01c4b7fa87139c2232ccad2e41/validation.jsonl`

---

## Pre-Flight Calibration Results (GH-831 Turn-Offs)

| Suite | Prose Ratio | Verdict | Calibration Status |
|---|---|---|---|
| `gh578-ci-optimize-skill.sh` | 1.00 | TURN-OFF | PASS |
| `gh778-review-code-skill.sh` | 1.00 | TURN-OFF | PASS |
| `gh798-status-skill.sh` | 1.00 | TURN-OFF | PASS (wording-only classified) |
| `gh779-radar-ci-health.sh` | 1.00 | TURN-OFF | PASS |
| `gh781-wam-radar-seed.sh` | 1.00 | TURN-OFF | PASS |
| `gh615-start-task-reinforce.sh` | 1.00 | TURN-OFF | PASS |
| `gh616-start-task-commensurate-envelope.sh` | 1.00 | TURN-OFF | PASS |
| `gh617-relay-xyz-commensurate-review.sh` | 1.00 | TURN-OFF | PASS |

*Calibration Verdict:* **8 of 8 suites evaluated as TURN-OFF.** Pre-flight calibration passed cleanly.

---

## Detector Coverage Summary (D1–D9)

| Detector | Coverage (Evaluated / Total Sample) | Status |
|---|---|---|
| **D1: Runtime Profiling** | 30 / 30 | 100% evaluated |
| **D2: Failure History & Taxonomy** | 30 / 30 | 100% evaluated |
| **D3: Touch-Set Overlap & Duplicate Analysis** | 30 / 30 | 100% evaluated |
| **D4: Sibling Coverage** | 30 / 30 | 100% evaluated |
| **D5: Prose & Non-Core Text Check** | 30 / 30 | 100% evaluated |
| **D6: Junk Pattern Detection** | 30 / 30 | 100% evaluated |
| **D7: Can-It-Fail Verification** | 30 / 30 | 100% evaluated |
| **D8: Fixed-at-HEAD Verification** | 30 / 30 | 100% evaluated |
| **D9: Four-Question Gate (OpenClaw)** | 30 / 30 | 100% evaluated |

---

## Verdict Summary

| Verdict | Count | Share | Proposed PR Gate Status |
|---|---|---|---|
| **KEEP** | 19 | 63.3% | Retained in `TESTS` |
| **KEEP-FIX** | 4 | 13.3% | Retained in `TESTS` (tracked under #853 / #812) |
| **QUARANTINE** | 3 | 10.0% | **Leaves PR gate** (moved to gh306 `EXEMPT`) |
| **TURN-OFF** | 2 | 6.7% | **Leaves PR gate** (moved to gh306 `EXEMPT` / unpinned) |
| **MERGE** | 1 | 3.3% | **Leaves PR gate** (folded into surviving keeper) |
| **SPLIT** | 1 | 3.3% | Retains behavioral core; splits prose |
| **NIGHTLY (candidate)** | 0 | 0.0% | Remains in `TESTS` (0 candidates qualified) |
| **UNKNOWN / INVESTIGATE** | 0 | 0.0% | Retained in `TESTS` pending telemetry |

---

## D3 Shared Entry-Point Clusters

| Entry Point / Subsystem | Overlapping Suites in Sample | Overlap Details | Action / Resolution |
|---|---|---|---|
| `validate.sh` | `gh251-validate-pytest-skip.sh`, `gh378-gate-requires-green-suite.sh`, `gh365-tier-fail-closed.sh` | Nested gate invocations & green-gate assertions | `gh378` nominated for **MERGE** into `ci-route.sh` test suite |
| `utils/py/releases_app.py` | `gh32-releases-app.sh`, `gh57-releases-fuzz.sh`, `releases-skill.sh` | Release app mutations, fuzzing, and skill docs | `releases-skill.sh` nominated for **SPLIT** |
| `utils/py/marathon_drive.py` | `marathon-drive.sh`, `gh280-jog-marathon-adapter.sh` | Marathon planning and driver execution | Retained (**KEEP**); distinct entry verbs and adapter layers |
| `utils/py/merge_cleanup.py` | `gh436-merge-cleanup.sh`, `gh674-merge-cleanup-hosted-lookup.sh` | Merge cleanup core vs hosted lookup | `gh436` protected (**KEEP** regression-caught); `gh674` **KEEP-FIX** |

---

## Heavy Suites & NIGHTLY Evaluation

| Heavy Suite | Rank | Duration | Cond 1 (No Regressions) | Cond 2 (Superset Sibling) | Cond 3 (Sibling ≤20% Dur) | Cond 4 (Guards Contract) | Nearest Sibling | Sibling Med | Candidate Verdict |
|---|---|---|---|---|---|---|---|---|---|
| `gh436-merge-cleanup.sh` | 1 | 182.7s | FAIL (#812 caught) | FAIL | FAIL | N/A | `gh674` | 0.2s | **KEEP** (PR gate protected) |
| `gh549-work-events.sh` | 2 | 152.5s | PASS | FAIL | FAIL | N/A | None | - | **KEEP** (heavy, no PR sibling) |
| `marathon-drive.sh` | 3 | 115.7s | PASS | FAIL | FAIL | N/A | None | - | **KEEP** (heavy, no PR sibling) |
| `gh251-validate-pytest-skip.sh` | 7 | 79.2s | PASS | FAIL | FAIL | N/A | None | - | **KEEP** (high-leverage heavy; optimize nested runs) |

---

## SPLIT Ratio Band Verification (0.20 – 0.60)

| Suite | Prose Ratio | Total Assertions | Doc Greps | Ratio Band Status | Action |
|---|---|---|---|---|---|
| `releases-skill.sh` | 0.35 | 43 | 15 | **PASS (0.20 ≤ 0.35 ≤ 0.60)** | Retain installer test; drop doc wording greps |

---

## Actionable Proposals Table (Non-KEEP Suites)

| Suite | Tier | Duration | Failure History | Proposed Action | Evidence & Citations | Confidence |
|---|---|---|---|---|---|---|
| `gh610-claude-subscription.sh` | Large | 37.9s | 4 of 14 (flake) | Move to `gh306` `EXEMPT` | Unresolved flake across multiple runs with no fix at HEAD | **HIGH** |
| `gh123-lock-progress-bound.sh` | Large | 8.2s | 1 of 14 (flake) | Move to `gh306` `EXEMPT` | Unresolved flake across multiple runs with no fix at HEAD | **HIGH** |
| `registry-lock-concurrency.sh` | Large | 4.1s | 1 of 14 (flake) | Move to `gh306` `EXEMPT` | Unresolved flake across multiple runs with no fix at HEAD | **HIGH** |
| `gh798-status-skill.sh` | Large | UNKNOWN | UNKNOWN | Move to `gh306` `EXEMPT` | 25/25 doc assertions; skill-text suite turned off under #831 | **MED** |
| `synthetic/synthetic-pi-model-unset.sh` | Large | 0.1s | 0 of 14 | Remove from `TESTS` / unpin `gh141` | Fully covered by `test/pi-turn.sh` (exit 5, clean tree, no commit) | **HIGH** |
| `gh378-gate-requires-green-suite.sh` | Large | 7.8s | 0 of 14 | Fold into `ci-route` suite & turn off | Duplicate contract check on validate.sh green requirement | **HIGH** |
| `releases-skill.sh` | Small | 0.2s | 0 of 14 | Split prose checks from installer test | Mixed assertions (prose ratio 0.35); split wording checks | **HIGH** |
| `agent-chorus-bridge.sh` | Large | 6.7s | 2 of 14 (host) | Retain in `TESTS`; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh492-idle-kill.sh` | Large | 7.7s | 2 of 14 (host) | Retain in `TESTS`; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh620-skills-army-mini-sync.sh` | Large | 10.2s | 2 of 14 (host) | Retain in `TESTS`; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh674-merge-cleanup-hosted-lookup.sh` | Small | 0.2s | 7 of 14 (coupling) | Retain in `TESTS`; coupled in #812 | Coupled hosted lookup failure in #812 cluster | **HIGH** |

---

## 8-Point Acceptance Checklist

- [x] **1. Calibration Passed:** Calibration against the 8 suites turned off by #831 passed (8 of 8 scored TURN-OFF, `gh798` scored wording-only/TURN-OFF).
- [x] **2. Target Branch Pinned:** Audit ran on `feat/gh862-ci-suite-audit` (staging base), not `main`.
- [x] **3. Honest Metrics:** Unmeasured suites report UNKNOWN metrics with zero keep-by-default fallbacks.
- [x] **4. Multi-Source Failures:** Failure signals combine hosted CI logs, local validation receipts, and #853 tracking.
- [x] **5. Flakes Quarantined:** Unresolved flakes without a landed fix (`gh610-claude-subscription`, `gh123-lock-progress-bound`, `registry-lock-concurrency`) receive QUARANTINE.
- [x] **6. Heavy Suites Profiled:** High-leverage heavy suites (including `gh251` ~22% gate, `gh436`, `gh549`, `marathon-drive`) profiled with 4-condition NIGHTLY breakdown.
- [x] **7. Redundant Suites Merged:** Duplicate contract suites (`gh378-gate-requires-green-suite`) receive MERGE.
- [x] **8. Sibling Skills Triggered:** `radar` triggered for #812 trunk-red cluster ($(0+1)/4 = 25%$ share); `whack-a-mole` triggered for #853 runner port/host cluster (≥3 suites).

---

## Sibling Skill Recommendations

- **radar:** trigger met (trunk-red cluster in window: `gh436` and `gh674` red together in 7 of 14 runs in #812; evaluates broad SDLC churn)
- **whack-a-mole:** trigger met (3 suites share runner host environment sensitivity in #853; points to existing #853 umbrella)
