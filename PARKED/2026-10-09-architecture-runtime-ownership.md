# Architecture runtime ownership — observed during GH-1007 QA

`ARCHITECTURE.md:138–173` describes the current stack as shell-only and says nobody
imports anybody; `:208` and `:238` name Bash containment ownership. The entry shims
`relay-automation/codex-turn.sh:9,18` and `relay-automation/relay-drive.sh:9,18` default
to Python. The final QA reviewer traced imports in `utils/py/codex-turn.py:7` and
`utils/py/relay_drive.py:17`, with `rtl.before()`/`rtl.enforce()` at Codex lines 72/136.

This is a pre-existing runtime-documentation mismatch outside GH-1007's SWE catalog
sentence and instruction revision. It does not block SWE acceptance. No matching parked
note or open issue titled architecture/Python was found in the bounded check. Next triage:
verify the affected architecture sections against Python owners, then qualify the legacy
`XYZ_PYTHON=0` account. Do not expand this into a runtime refactor or new test suite.

Source: `relay-system/2026-10-09/gh1007-final.codex.md`, Round 1 F1. Observation only;
not admitted work, a GitHub issue, or a competing plan.
