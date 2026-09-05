# GH-299 Gen 4 ATE — 3-Hour Unattended Soak Evidence (Agy)

**Verdict:** Phase 5 gate: MET

- **Date:** 2026-09-04
- **Branch:** `feat/gh299-gen4-ate`
- **Host Repo:** `/Users/noelsaw/marathon-clones/gh299-gen4`
- **Sandbox Root:** `/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T//gen4-soak-2026-09-04/clone` (disposable full clone)
- **Evidence Path:** `TESTS-RESULTS/2026-09-04+GH-299/soak-agy/`

---

## 0. Step 0 Suite Verification (Pre-Flight)

All 6 module test suites executed and passed cleanly before launching the soak:

| Suite | Command | Result |
|---|---|---|
| Telemetry Contract | `python3 utils/py/telemetry_schema.py --mode suite` | `SUITE_RESULT=PASS (0 failures)` |
| Domain Oracles (P1) | `python3 utils/py/domain_oracles.py --mode suite` | `SUITE_RESULT=PASS (9/9)` |
| Adaptive ATE (P2) | `python3 utils/py/adaptive_ate.py --mode suite` | `SUITE_RESULT=PASS (15/15)` |
| Fuzz Engine (P3) | `python3 utils/py/fuzz_engine.py --mode suite` | `SUITE_RESULT=PASS (17/17)` |
| Repro Synthesizer (P4) | `python3 utils/py/repro_synth.py --mode suite` | `SUITE_RESULT=PASS (15/15)` |
| Campaign Runner (P5) | `python3 utils/py/gen4_campaign.py --mode suite` | `SUITE_RESULT=PASS (12/12)` |

---

## 1. Phase 5 Gate Bars & Metrics

| Bar / Metric | Required | Actual | Verdict |
|---|---|---|---|
| **Mutations Executed** | $\ge 10,000$ | **14,825** (593 batches, 89.8/min, 9,900.4s) | **MET** |
| **Zero Host Violations** | `True` (0 violations) | **True** (0 violations: `.git/config`, `core.bare`, remotes, HEAD, refs untouched) | **MET** |
| **Zero False Positives** | `True` (0 false pos) | **True** (0 false positives: 3/3 synthesized suites replay defect with 100% fidelity) | **MET** |
| **Telemetry Line Valid** | `True` (0 bad lines) | **True** (14,825 valid JSONL lines in `telemetry.jsonl`, 0 bad lines) | **MET** |
| **Non-Parity Anomaly Rate** | $< 5.0\%$ ($>95\%$ classified) | **2.04%** (303 non-parity anomalies / 14,825 mutations) | **MET** |

- **Tier-1 Execution Counts:** `{'pass': 617, 'fail': 12761, 'anomaly': 1447}`
- **Handled Rejections:** 12,672
- **Raw Counterexamples:** 1,455

---

## 2. Cluster Triage Table

| Digest | Members | Rep RC | Classification | Root Cause / One-Line Why | Suite RC |
|---|---|---|---|---|---|
| `e3b0c44298fc1c14` | 1405 | 0 | `parity` / `harness-artifact` | 1,144 cross-twin parity divergences (rc=0 vs twin rc=2) + 261 slow durations (>30s timeout bucket) on heavy `pdda-frontmatter` tree walks; empty stderr digest | N/A (skipped, not a defect) |
| `738c4aa1f77b7a53` | 123 | 4 | `handled-but-noisy` / `harness-artifact` | `marathon_plan.py` ran default action when flags stripped, emitted `wrote PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md` to stderr and exited rc=4 | 0 (`PASS`, reproduced rc=4) |
| `9553f3b817475f28` | 5 | 1 | `real-defect` | `adaptive_ate.py` unhandled `IsADirectoryError` crash when `--grid` receives a directory path (`utils/`) instead of a file | 0 (`PASS`, reproduced rc=1) |
| `67702091c1b3d906` | 3 | 1 | `real-defect` | `domain_oracles.py` unhandled `ValueError: No closing quotation` from `shlex.split` when `--cmd` contains unmatched quote | 0 (`PASS`, reproduced rc=1) |

---

## 3. Parity Divergence Analysis

- **Total Parity Divergences:** `1,144`
  - `agy-turn-twins`: `576`
  - `codex-turn-twins`: `568`
- **Root Cause:** The authoritative Python entry points (`utils/py/agy_turn.py`, `utils/py/codex_turn.py`) parse and display `--help` cleanly (`rc=0`), whereas the legacy Bash twin fallbacks (`XYZ_PYTHON=0`) enforce a mandatory `RELAY_AGENT` environment variable pre-check before evaluating argument flags, rejecting with `rc=2`.
- **Top Twin Stderr Heads:**
  1. `[576]` `agy-turn: RELAY_AGENT required\n` (rc=2, digest `e7a00bd8`)
  2. `[568]` `codex-turn: RELAY_AGENT required\n` (rc=2, digest `d3ccac31`)

---

## 4. Target Breakdown

| Target | Batches | Mutations | Counterexamples | Parity Divergences |
|---|---:|---:|---:|---:|
| `ci-route` | 66 | 1650 | 0 | 0 |
| `releases-roadmap` | 66 | 1650 | 0 | 0 |
| `releases-check` | 66 | 1650 | 0 | 0 |
| `pdda-frontmatter` | 66 | 1650 | 180 | 0 |
| `domain-oracles-cli` | 66 | 1650 | 3 | 0 |
| `adaptive-ate-cli` | 66 | 1650 | 5 | 0 |
| `codex-turn-twins` | 66 | 1650 | 568 | 568 |
| `agy-turn-twins` | 66 | 1650 | 576 | 576 |
| `marathon-plan` | 65 | 1625 | 123 | 0 |

---

## 5. Contamination Events & Errors (Verbatim)

### Errors
`[]`

### Contamination Events (Sandbox Tree Drift — Caught & Reset, Host Pristine)
- `round 18 target marathon-plan seed 20260922: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 27 target marathon-plan seed 20260931: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 36 target marathon-plan seed 20260940: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 45 target marathon-plan seed 20260949: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 54 target marathon-plan seed 20260958: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 63 target marathon-plan seed 20260967: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 72 target marathon-plan seed 20260976: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 81 target marathon-plan seed 20260985: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 90 target marathon-plan seed 20260994: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 99 target marathon-plan seed 20261003: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 108 target marathon-plan seed 20261012: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 117 target marathon-plan seed 20261021: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 126 target marathon-plan seed 20261030: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 135 target marathon-plan seed 20261039: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 144 target marathon-plan seed 20261048: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 153 target marathon-plan seed 20261057: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 162 target marathon-plan seed 20261066: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 180 target marathon-plan seed 20261084: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 189 target marathon-plan seed 20261093: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 198 target marathon-plan seed 20261102: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 207 target marathon-plan seed 20261111: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 234 target marathon-plan seed 20261138: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 243 target marathon-plan seed 20261147: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 252 target marathon-plan seed 20261156: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 261 target marathon-plan seed 20261165: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 270 target marathon-plan seed 20261174: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 279 target marathon-plan seed 20261183: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 297 target marathon-plan seed 20261201: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 306 target marathon-plan seed 20261210: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 315 target marathon-plan seed 20261219: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 324 target marathon-plan seed 20261228: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 333 target marathon-plan seed 20261237: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 342 target marathon-plan seed 20261246: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 351 target marathon-plan seed 20261255: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 360 target marathon-plan seed 20261264: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 369 target marathon-plan seed 20261273: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 378 target marathon-plan seed 20261282: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 387 target marathon-plan seed 20261291: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 396 target marathon-plan seed 20261300: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 405 target marathon-plan seed 20261309: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 414 target marathon-plan seed 20261318: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 423 target marathon-plan seed 20261327: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 432 target marathon-plan seed 20261336: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 441 target marathon-plan seed 20261345: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 450 target marathon-plan seed 20261354: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 459 target marathon-plan seed 20261363: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 477 target marathon-plan seed 20261381: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 486 target marathon-plan seed 20261390: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 495 target marathon-plan seed 20261399: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 504 target marathon-plan seed 20261408: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 513 target marathon-plan seed 20261417: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 522 target marathon-plan seed 20261426: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 531 target marathon-plan seed 20261435: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 540 target marathon-plan seed 20261444: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 558 target marathon-plan seed 20261462: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 567 target marathon-plan seed 20261471: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
- `round 585 target marathon-plan seed 20261489: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']`
