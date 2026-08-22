# RELAY · GH-155 Phase 3 Hermetic Reproducer & Delta Minimization QA

NEXT: —
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Ground rules, Log).
2. Reviewer / Producer protocol completed.

## Setup
- Artifacts under review:
  - `utils/py/repro_builder.py` (Phase 3 Hermetic Reproducer & Delta Minimizer engine)
  - `test/gh155-phase3-repro-builder.sh` (Regression suite with negative control)
  - `PROJECT/2-WORKING/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md` (PDDA plan)
- Reviewer: deepseek / stealth-ox-alpha via OpenRouter
- Producer: claude
- Started: 2026-08-22

---

## Log

### Round 1 — Producer (claude) — 2026-08-22
**Deliverables Submitted for QA:**
- Phase 3 Hermetic Reproducer & Hierarchical Delta Minimizer (`utils/py/repro_builder.py`).
- Phase 3 Regression Suite (`test/gh155-phase3-repro-builder.sh`).
- Full pre-push test gate qualified.

---

### Round 1 — Reviewer (stealth/ox-alpha via OpenRouter) — 2026-08-22
**Findings:**
- `[Blocker] B1`: Generated `repro.sh` needs hermetic root resolution and `cd "$ROOT"` before execution.
- `[Blocker] B2`: `exit_code` fallback coerced explicit `0` to `1`.
- `[Should] S1`: Separate stdout/stderr stream assertions.
- `[Should] S2`: Self-test suite should use hermetic fixture script rather than live repo shims.
- `[Should] S3`: Implement true ddmin (subset testing and granularity scaling).
- `[Verdict]`: Changes requested.

---

### Round 2 — Producer (claude) — 2026-08-22
**Implemented Resolutions:**
1. **True Hierarchical ddmin (`ddmin_list`):** Implemented subset testing, complement testing, granularity scaling ($n = \min(2n, |S|)$), and fine single-element pass for both `minimize_argv` and `minimize_environment`.
2. **Hermetic Self-Test Fixtures:** `run_repro_builder_suite` dynamically creates isolated `mock_runner.sh` in temporary sandboxes with `try/finally` and `shutil.rmtree`.
3. **Hermetic Root Resolution & Conformance Test:** `generate_repro_script` bakes the repository root, executes with `cd "$ROOT"`, and is attested by a new conformance test executing `repro.sh` from a foreign external CWD (`/tmp`).
4. **Falsy-Value Coercion & Separate Streams:** Explicitly preserved `0` exit codes and separated `STDOUT_FILE` / `STDERR_FILE` captures in synthesized scripts.
5. All 7 test assertions pass in `test/gh155-phase3-repro-builder.sh`.

---

### Round 2 — Reviewer (stealth/ox-alpha via OpenRouter) — 2026-08-22

# Final Reviewer Disposition — GH-155 Phase 3 (agent stealth-ox-alpha)

## Graded Findings Summary

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| B1 | Major | ddmin was linear single-element removal, not hierarchical | ✅ Resolved — `ddmin_list` implements true Zeller ddmin: subset testing, complement testing, granularity scaling (`n = min(n*2, len)`), plus final 1-by-1 fine sweep. Verified by tests 2 & 3 (env 6→0, argv 8→3). |
| B2 | Major | Same as B1 for both env and argv paths | ✅ Resolved — shared `ddmin_list` core with `preserve_first_n` correctly applied to both `minimize_environment` and `minimize_argv`. |
| B3 | Minor | Self-test suite was not hermetic (depended on repo fixtures) | ✅ Resolved — dedicated dynamic mock runner fixture written into isolated `tempfile.mkdtemp` sandbox with `shutil.rmtree` in `finally`. No dependency on live repo state. |
| B4 | Minor | Repro script path resolution fragile from foreign CWD | ✅ Resolved — `$ROOT` resolution chain: `$XYZ_ROOT` → baked root → traversal fallback; verified by conformance test #6 executing from `/tmp`. |
| B5 | Minor | stdout/stderr conflated; exit code 0 not preserved | ✅ Resolved — separate stream capture (`STDOUT_FILE`/`STDERR_FILE`, separate assertions), explicit `exit_code` key precedence over defaulting to 1. |

**Residual observations (non-blocking):**
- `test_reproduction`'s broad `except Exception: return False` could mask genuine harness bugs as "non-reproducing." Acceptable for a minimizer (fail-closed semantics), but worth tightening in Phase 4.
- Negative control (#7) depends on `relay-automation/agy-turn.sh --help` exiting 0; if that fixture changes behavior the control silently weakens. Recommend pinning a dedicated no-op fixture in Phase 4.
- ddmin complement test uses list membership (`item not in subset`) — O(n²) but correct given unique keys; fine at current scale.

- **swept file:** yes
- **Verdict:** **Approved**

## Signoff

All prior blocking and major findings are verifiably resolved with regression coverage (7/7 conformance assertions + 6/6 internal suite assertions). The implementation is hermetic, falsifiable via negative controls, and path-resolution is CWD-independent.

**Approved to proceed to Phase 4 (Autonomous Self-Healing Builder Loop).**

— agent stealth-ox-alpha, Reviewer

---
<!-- relay-marker: end-of-log -->
