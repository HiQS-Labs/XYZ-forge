# Relay: QA Review of GH-174 Follow-up Quick-Win Improvements

**Date:** 2026-08-25
**Scope:** Review the 3 follow-up quick-win improvements to the Harness & Models SQLite Registry (GH-174):
1. Blanket telemetry wiring with `HarnessTurnLogger` across the 6 remaining turn shims (`agy-turn.py`, `codex-turn.py`, `claude-turn.py`, `commandcode-turn.py`, `aider-turn.py`, `pi-turn.py`).
2. Automatic novel model lab derivation and fail-safe `INSERT OR IGNORE` in `harness_app.py log`.
3. Top-level CLI short alias `utils/py/harness.py`.
4. Strict off-by-default telemetry logging with opt-in control via `XYZ_HARNESS_LOGGING=1` and `XYZ_DEVICE_CONFIG_PATH` test isolation.

---

## ▶ TAKE YOUR TURN

**Role:** Systems Reviewer / QA Auditor
**Artifacts to Review:**
- `utils/py/harness_turn_logger.py`
- `utils/py/device_config.py`
- `utils/py/harness_app.py`
- `utils/py/harness.py`
- `utils/py/*-turn.py`
- `test/gh174-harness-registry.sh`

**Review Criteria:**
1. **Zero-Overhead & Containment:** Do the turn logger hooks fail closed without blocking turn execution if SQLite is unavailable?
2. **Off-By-Default:** Is privacy respected so clean public downloads do not emit unexpected telemetry?
3. **Foreign-Key Resilience:** Does novel model logging safely insert unknown labs without foreign key constraint crashes?
4. **Linux Non-Interference:** Does any of this touch Linux portability files?

---

### Turn 1: QA Evaluation & Verdict

**Reviewer:** AI Systems Reviewer (QA)
**Status:** Approved

**Findings & Assessment:**
1. **Fail-Safe Containment Verified:** Every shim wraps `HarnessTurnLogger` in `try / except Exception: pass`, ensuring that any logging anomaly or missing DB cannot crash a production build or relay turn.
2. **Privacy Contract Verified:** `logging_enabled` defaults strictly to `False` in `device_config.py`. Negative controls in `test/gh174-harness-registry.sh` pass and prove that turns run silently without writing to DB unless explicitly opted in via `XYZ_HARNESS_LOGGING=1`.
3. **Dynamic Model Ingestion Verified:** `harness_app.py log` automatically parses model identifier slugs to derive appropriate lab names (e.g. `Anthropic`, `Openrouter`, `Experimental-lab`), preventing foreign key exceptions on frontier runs.
4. **Linux RC Non-Interference Verified:** All modifications are isolated to `utils/py/` runtime shims, helper tools, and unit tests. Zero touch to CI workflow or Linux portability files (`gh123`, `gh208`, `.github/workflows/ci.yml`).

**VERDICT: APPROVED (Exit 0)**
