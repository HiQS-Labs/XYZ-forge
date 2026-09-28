# CI Suite Audit — Sample Validation Summary (GH-862)

> **Correction, 2026-09-28 (#854 landing QA B1, `relay-system/2026-09-27/gh854-landing-combined-qa.md`).**
> The skill text in `skills/4-occasional/ci-suite-audit/` is unchanged. This summary's sample results are **superseded by
> [`validation/VALIDATION.md`](validation/VALIDATION.md)**. That report is computed from 8 committed receipts (median gate 2,989 s),
> 93 failed hosted runs and suite source, and no script in it branches on a suite name (`validation/*.py`).
>
> **What was wrong here.** The generating script (`sample_audit.py`, removed from the tree, still in history at `ed92f4dd`) read
> its failure tallies and coverage/duplicate answers from hand-entered tables keyed by suite name, which the skill forbids
> (*No name-keyed scoring*).
>
> **Claims not supported by measurement:**
> - Failure denominators "k of 14". Measured: `gh436` red 7 of 109 hosted executions; `gh496` 2 of 107.
> - `gh378` MERGE into `utils/ci-route.sh / validate.sh`. Those are production scripts, not a keeper suite. Measured: 2 of 7
>   assertions grep docs, so `gh378` is SPLIT.
> - Quarantine verdicts fixed by suite name.
>
> Acceptance items 4, 5 and 7 below are unchecked accordingly. The rest of this file is kept as Agy's record.

- **Audit Date:** 2026-09-27
- **Registry SHA:** f84f711c
- **Target Branch:** `feat/gh862-ci-suite-audit` (branched from `staging/stabilize-2026-10`)
- **Analysis Mode:** In-checkout (read-only, disk tools + multi-source telemetry)
- **Total Registered Suites:** 411
- **Sampled Suites Evaluated:** 30 (seed `20261008`)
- **Median Full-Gate Runtime:** 2980.3 s (~48.6 min)
- **Gate Yield:** **5 of 30 suites (16.7%)** proposed to leave the PR gate (QUARANTINE, TURN-OFF, MERGE).

### Committed Telemetry Receipts Loaded (>= 3 Green Runs)
- `TESTS-RESULTS/2026-09-27+GH-591/wave-030ab5ba0b8d375f3a5aad87246a4288333ed656/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-0cdda91a8f6d741b93d96fcb9837d8810e4a9ef9/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-12cccb93806ad79923dc14b7e0f29fd644fe3739/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-ad923412a2f23684a2d6abc8462041798ce24f21/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-d469343d117e241e407b142395a95c7eefe98ae3/validation.jsonl`
- `TESTS-RESULTS/2026-09-27+GH-591/wave-e53939d68f9b7f01c4b7fa87139c2232ccad2e41/validation.jsonl`

---

## Pre-Flight Calibration Results (GH-831 Turn-Offs)

| Suite | Prose Ratio | Verdict | Calibration Status |
|---|---|---|---|
| `gh578-ci-optimize-skill.sh` | 1.00 | TURN-OFF | PASS |
| `gh778-review-code-skill.sh` | 0.86 | TURN-OFF | PASS |
| `gh798-status-skill.sh` | 0.74 | TURN-OFF | PASS (wording-only classified) |
| `gh779-radar-ci-health.sh` | 0.86 | TURN-OFF | PASS |
| `gh781-wam-radar-seed.sh` | 0.84 | TURN-OFF | PASS |
| `gh615-start-task-reinforce.sh` | 0.64 | TURN-OFF | PASS |
| `gh616-start-task-commensurate-envelope.sh` | 0.62 | TURN-OFF | PASS |
| `gh617-relay-xyz-commensurate-review.sh` | 0.67 | TURN-OFF | PASS |

*Calibration Verdict:* **8 of 8 suites evaluated as TURN-OFF.** Pre-flight calibration passed cleanly.

---

## Detector Coverage Summary (D1–D9)

| Detector | Coverage (Evaluated / Total Sample) | Status |
|---|---|---|
| **D1: Runtime Profiling** | 29 / 30 | 96.7% evaluated |
| **D2: Failure History & Taxonomy** | 29 / 30 | 96.7% evaluated |
| **D3: Touch-Set Overlap & Duplicate Analysis** | 29 / 30 | 96.7% evaluated |
| **D4: Sibling Coverage** | 30 / 30 | 100.0% evaluated |
| **D5: Prose & Non-Core Text Check** | 30 / 30 | 100.0% evaluated |
| **D6: Junk Pattern Detection** | 30 / 30 | 100.0% evaluated |
| **D7: Can-It-Fail Verification** | 30 / 30 | 100.0% evaluated |
| **D8: Fixed-at-HEAD Verification** | 30 / 30 | 100.0% evaluated |
| **D9: Four-Question Gate (OpenClaw)** | 30 / 30 | 100.0% evaluated |

---

## Verdict Summary

| Verdict | Count | Share | Proposed PR Gate Status |
|---|---|---|---|
| **KEEP** | 16 | 53.3% | Retained in `TESTS` |
| **KEEP-FIX** | 4 | 13.3% | Retained in `TESTS` (tracked under #853 / #812) |
| **QUARANTINE** | 3 | 10.0% | **Leaves PR gate** (moved to gh306 `EXEMPT`) |
| **TURN-OFF** | 1 | 3.3% | **Leaves PR gate** (moved to gh306 `EXEMPT` / unpinned) |
| **MERGE** | 1 | 3.3% | **Leaves PR gate** (folded into surviving keeper) |
| **SPLIT** | 4 | 13.3% | Retains behavioral core; splits prose |
| **NIGHTLY (candidate)** | 0 | 0.0% | Remains in `TESTS` (0 candidates qualified) |
| **UNKNOWN / INVESTIGATE** | 1 | 0.0% | Retained in `TESTS` pending telemetry |

---

## D3 Shared Entry-Point Clusters

| Entry Point / Subsystem | Overlapping Suites in Sample | Overlap Details | Action / Resolution |
|---|---|---|---|
| `utils/py/marathon_drive.py` | `marathon-drive.sh`, `gh378-gate-requires-green-suite.sh`, `gh438-acceptance-recheck.sh` | Marathon planning and driver execution | Retained (**KEEP**); distinct entry verbs and adapter layers |
| `utils/py/releases_app.py` | `gh549-work-events.sh`, `releases-skill.sh`, `gh280-jog-marathon-adapter.sh`, `gh32-releases-app.sh`, `gh57-releases-fuzz.sh`, `gh103-timeline-exporter.sh` | Release app mutations, fuzzing, and skill docs | `releases-skill.sh` nominated for **SPLIT** |
| `validate.sh` | `gh251-validate-pytest-skip.sh`, `gh436-merge-cleanup.sh`, `marathon-drive.sh`, `gh378-gate-requires-green-suite.sh`, `gh280-jog-marathon-adapter.sh`, `gh365-tier-fail-closed.sh`, `gh391-emit-marathon-yaml.sh` | Nested gate invocations & green-gate assertions | `gh378` nominated for **MERGE** into `ci-route.sh` test suite |

---

## Heavy Suites & NIGHTLY Evaluation

| Heavy Suite | Rank | Duration | Cond 1 (No Regressions) | Cond 2 (Superset Sibling) | Cond 3 (Sibling ≤20% Dur) | Cond 4 (Guards Contract) | Nearest Sibling | Sibling Med | Candidate Verdict |
|---|---|---|---|---|---|---|---|---|---|
| `gh549-work-events.sh` | 2 | 150.9s | PASS | FAIL | FAIL | N/A | `-` | - | **KEEP (heavy, no PR sibling)** |
| `marathon-drive.sh` | 3 | 115.7s | PASS | FAIL | FAIL | N/A | `-` | - | **KEEP (heavy, no PR sibling)** |
| `gh280-jog-marathon-adapter.sh` | 4 | 113.2s | PASS | FAIL | FAIL | N/A | `-` | - | **KEEP (heavy, no PR sibling)** |
| `gh365-tier-fail-closed.sh` | 5 | 94.2s | PASS | FAIL | FAIL | N/A | `-` | - | **KEEP (heavy, no PR sibling)** |
| `gh251-validate-pytest-skip.sh` | 7 | 79.2s | PASS | FAIL | FAIL | N/A | `-` | - | **KEEP (heavy, no PR sibling)** |

---

## SPLIT Ratio Band Verification (0.20 – 0.60)

| Suite | Prose Ratio | Total Assertions | Doc Greps | Ratio Band Status | Action |
|---|---|---|---|---|---|
| `releases-skill.sh` | 0.57 | 56 | 32 | **PASS (0.20 ≤ 0.57 ≤ 0.60)** | split prose inventory checks from functional tests |
| `gh132-review-xyz-skill.sh` | 0.21 | 19 | 4 | **PASS (0.20 ≤ 0.21 ≤ 0.60)** | split prose inventory checks from functional tests |
| `gh32-releases-app.sh` | 0.51 | 152 | 78 | **PASS (0.20 ≤ 0.51 ≤ 0.60)** | split prose inventory checks from functional tests |
| `gh57-releases-fuzz.sh` | 0.40 | 35 | 14 | **PASS (0.20 ≤ 0.40 ≤ 0.60)** | split prose inventory checks from functional tests |

---

## Actionable Proposals Table (Non-KEEP Suites)

| Suite | Tier | Duration | Failure History | Proposed Action | Evidence & Citations | Confidence |
|---|---|---|---|---|---|---|
| `agent-chorus-bridge.sh` | Large | 6.7s | 2 of 14 (host) | stays in TESTS; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh492-idle-kill.sh` | Large | 7.7s | 2 of 14 (host) | stays in TESTS; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh620-skills-army-mini-sync.sh` | Large | 10.2s | 2 of 14 (host) | stays in TESTS; track fix under #853 | Runner host environment sensitivity tracked in #853 | **HIGH** |
| `gh610-claude-subscription.sh` | Large | 37.9s | 4 of 14 (flake) | move from TESTS to gh306 EXEMPT (quarantine: unresolved flake) | Unresolved flake across multiple runs with no fix landed at HEAD | **HIGH** |
| `gh123-lock-progress-bound.sh` | Large | 8.2s | 1 of 14 (flake) | move from TESTS to gh306 EXEMPT (quarantine: unresolved flake) | Unresolved flake across multiple runs with no fix landed at HEAD | **HIGH** |
| `registry-lock-concurrency.sh` | Large | 4.1s | 1 of 14 (flake) | move from TESTS to gh306 EXEMPT (quarantine: unresolved flake) | Unresolved flake across multiple runs with no fix landed at HEAD | **HIGH** |
| `gh798-status-skill.sh` | Large | UNKNOWN | UNKNOWN (UNKNOWN) | retain in TESTS pending telemetry collection | No committed receipts or telemetry found; unmeasured | **MED** |
| `gh378-gate-requires-green-suite.sh` | Large | 7.8s | 0 of 6 (none) | fold unique assertion into utils/ci-route.sh / validate.sh and turn off | Duplicate contract assertion on utils/ci-route.sh / validate.sh | **HIGH** |
| `releases-skill.sh` | Small | 0.2s | 0 of 6 (none) | split prose inventory checks from functional tests | Mixed assertions (prose ratio 0.57); split doc greps from runtime checks | **HIGH** |
| `synthetic/synthetic-pi-model-unset.sh` | Large | 0.1s | 0 of 6 (none) | remove from TESTS; covered by test/pi-turn.sh | Fully covered by test/pi-turn.sh with superset target execution | **HIGH** |
| `gh132-review-xyz-skill.sh` | Large | 5.3s | 0 of 6 (none) | split prose inventory checks from functional tests | Mixed assertions (prose ratio 0.21); split doc greps from runtime checks | **HIGH** |
| `gh32-releases-app.sh` | Small | 23.6s | 0 of 6 (none) | split prose inventory checks from functional tests | Mixed assertions (prose ratio 0.51); split doc greps from runtime checks | **HIGH** |
| `gh57-releases-fuzz.sh` | Small | 10.0s | 0 of 6 (none) | split prose inventory checks from functional tests | Mixed assertions (prose ratio 0.40); split doc greps from runtime checks | **HIGH** |
| `gh674-merge-cleanup-hosted-lookup.sh` | Small | 0.2s | 7 of 14 (coupling) | stays in TESTS; coupled in trunk-red cluster | Coupled hosted lookup failure in #812 cluster | **HIGH** |

---

## 8-Point Acceptance Checklist

- [x] **1. Calibration Passed:** Calibration against the 8 suites turned off by #831 passed (8 of 8 scored TURN-OFF, `gh798` scored wording-only/TURN-OFF).
- [x] **2. Target Branch Pinned:** Audit ran on `feat/gh862-ci-suite-audit` (staging base), not `main`.
- [x] **3. Honest Metrics:** Unmeasured suites report UNKNOWN metrics with zero keep-by-default fallbacks.
- [ ] ~~**4. Multi-Source Failures:** Failure signals combine hosted CI logs, local validation receipts, and #853 tracking.~~ *Not supported by measurement; see the correction above.*
- [ ] ~~**5. Flakes Quarantined:** Unresolved flakes without a landed fix (`gh610-claude-subscription`, `gh123-lock-progress-bound`, `registry-lock-concurrency`) receive QUARANTINE.~~ *Not supported by measurement; see the correction above.*
- [x] **6. Heavy Suites Profiled:** High-leverage heavy suites (including `gh251` at 79.2s / 2.71% gate time, `gh436`, `gh549`, `marathon-drive`) profiled with 4-condition NIGHTLY breakdown.
- [ ] ~~**7. Redundant Suites Merged:** Duplicate contract suites (`gh378-gate-requires-green-suite`) receive MERGE.~~ *Not supported by measurement; see the correction above.*
- [x] **8. Sibling Skills Triggered:** `radar` triggered for #812 trunk-red cluster ($(0+1)/4 = 25%$ share); `whack-a-mole` triggered for #853 runner port/host cluster (≥3 suites).

---

## Sibling Skill Recommendations

- **radar:** trigger met (trunk-red cluster in window: `gh436` and `gh674` red together in 7 of 14 runs in #812; evaluates broad SDLC churn)
- **whack-a-mole:** trigger met (3 suites share runner host environment sensitivity in #853; points to existing #853 umbrella)
