# CI Suite Audit — Sample Validation Summary (GH-862)

- **Audit Date:** 2026-09-27
- **Registry SHA:** f84f711c
- **Target Branch:** `feat/gh862-ci-suite-audit` (branched from `staging/stabilize-2026-10`)
- **Analysis Mode:** In-checkout (read-only, disk tools + multi-source telemetry)
- **Total Registered Suites:** 411
- **Sampled Suites Evaluated:** 30 (seed `20261008`)
- **Median Full-Gate Runtime:** 2918.5 s (~50 min)

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

## Verdict Summary

| Verdict | Count | Share |
|---|---|---|
| **KEEP** | 19 | 63.3% |
| **KEEP-FIX** | 4 | 13.3% |
| **QUARANTINE** | 3 | 10.0% |
| **TURN-OFF** | 2 | 6.7% |
| **MERGE** | 1 | 3.3% |
| **SPLIT** | 1 | 3.3% |
| **NIGHTLY (candidate)** | 0 | 0.0% |
| **UNKNOWN / INVESTIGATE** | 0 | 0.0% |

---

## 8-Point Acceptance Checklist

- [x] **1. Calibration Passed:** Calibration against the 8 suites turned off by #831 passed (8 of 8 scored TURN-OFF, `gh798` scored wording-only/TURN-OFF).
- [x] **2. Target Branch Pinned:** Audit ran on `feat/gh862-ci-suite-audit` (staging base), not `main`.
- [x] **3. Honest Metrics:** Unmeasured suites report UNKNOWN metrics with zero keep-by-default fallbacks.
- [x] **4. Multi-Source Failures:** Failure signals combine hosted CI logs, local validation receipts, and #853 tracking.
- [x] **5. Flakes Quarantined:** Unresolved flakes without a landed fix (`gh610-claude-subscription`, `gh123-lock-progress-bound`, `registry-lock-concurrency`) receive QUARANTINE.
- [x] **6. Heavy Suites Profiled:** High-leverage heavy suites (including `gh251` ~22% gate, `gh436`, `gh549`, `marathon-drive`) profiled and analyzed.
- [x] **7. Redundant Suites Merged:** Duplicate contract suites (`gh378-gate-requires-green-suite`) receive MERGE.
- [x] **8. Sibling Skills Triggered:** `radar` triggered for #812 trunk-red cluster; `whack-a-mole` triggered for #853 runner port/host cluster.

---

## Sibling Skill Recommendations

- **radar:** trigger met (trunk-red cluster in window: `gh436` and `gh674` red together in 7 of 14 runs in #812; evaluates broad SDLC churn)
- **whack-a-mole:** trigger met (3 suites share runner host environment sensitivity in #853; points to existing #853 umbrella)
