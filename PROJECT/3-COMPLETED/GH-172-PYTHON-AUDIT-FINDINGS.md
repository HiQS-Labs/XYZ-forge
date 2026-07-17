---
title: "GH-172 Python audit findings"
status: completed
created: 2026-07-17
updated: 2026-07-17
owner: codex
goal: >
  Record the Phase 2 audit of the remaining Python entry points against GH-172's vendored-root and
  hardened-Bash contract, including the one Bash-mirror fix in consult.py, the relay-drive warning
  parity fix, and the clean verdicts for the other scoped files.
roadmap_exempt: true
---

# GH-172 Python audit findings

## Status

| What was just completed | What's next |
|---|---|
| Phase 2 audit of the remaining Python entry points against GH-172's root contract and the Bash findings doc; gaps found and fixed in `utils/py/consult.py` (tick-root routing) and `utils/py/relay_drive.py` (warning parity), every other scoped file at parity. | Phase 3 (vendored E2E) adds regression coverage for the fixes recorded here and in the Bash findings doc. |

Reference Bash audit: [GH-172-BASH-AUDIT-FINDINGS.md](GH-172-BASH-AUDIT-FINDINGS.md).

## utils/py/marathon_drive.py

Checked: vendored `.xyz` detection, split between harness install root (`xyz_harness`), target/work
root (`root`), the default tick binary path, and the nested relay-driver handoff via
`os.environ["TICK_REPO_ROOT"] = root`.

Verdict: clean.

Cross-reference to Bash findings: matches the clean `relay-automation/marathon-drive.sh` verdict. I
did not find a Python-only GH-172 gap in root selection, tick-binary separation, or the nested
relay seeding path.

## utils/py/relay_drive.py

Checked: harness-local tick resolution, attempt-counter anchoring off `TICK_REPO_ROOT`, default
`RELAY_WORKTREE_ISOLATION=1`, and the uncommitted-relay-file visibility warning for same-repo versus
cross-repo/archive-routed relay files.

Verdict: gap found and fixed.

Fix: ported the current Bash warning split. Same-repo uncommitted relay files now emit the softer
`NOTE` explaining that worktree seeding usually makes the file visible anyway; only relay files that
live in a different repo than the turn-taker root keep the stronger invisibility `WARNING`.

Cross-reference to Bash findings: this was not one of the July 17, 2026 Bash findings-doc fixes, but
it was still required for `XYZ_PYTHON=1` to match the hardened Bash relay contract now documented in
`relay-automation/relay-drive.sh`.

Verification:
- `python3 -m py_compile utils/py/relay_drive.py`
- `XYZ_PYTHON=1 bash test/poll-relay.sh` -> 12 pass, 0 fail
- Targeted smoke on 2026-07-17: a same-repo uncommitted relay under `--target-root` emitted `NOTE`
  and still reached dry-run; a cross-repo absolute relay path emitted `WARNING` and still reached
  dry-run.

## utils/py/rtl.py

Checked: `resolve_tick_bin`, `claim_task_or_exit`, `make_tick_env`, and the `RelayTurnLib` bridge
that passes `TICK_REPO_ROOT` into `relay-turn-lib.sh` instead of re-deriving coordination state from
the editable root.

Verdict: clean.

Cross-reference to Bash findings: already at parity with `relay-automation/relay-turn-lib.sh` for
the GH-172 seams. The Bash-side ownership-before-launch hardening is already present here via
`claim_task_or_exit`.

## utils/py/aider-turn.py

Checked: ownership-before-launch through `claim_task_or_exit`, separation of `AIDER_TURN_ROOT` from
`TICK_REPO_ROOT`, and preservation of the pinned coordination root inside worktree-isolated runs.

Verdict: clean.

Cross-reference to Bash findings: already matches the clean `relay-automation/aider-turn.sh` verdict.
The Phase 1 Bash ownership guard has a direct Python equivalent here.

## utils/py/consult.py

Checked: `CONSULT_ROOT` versus coordination-root routing for Gemini JSON cost capture, specifically
the old `${CONSULT_ROOT}/bin/tick` fallback that the Bash audit fixed on July 17, 2026.

Verdict: gap found and fixed.

Fix: imported the shared tick-root and tick-binary resolvers from `rtl.py`, resolved the cost-capture
tick path against `TICK_REPO_ROOT` (or the harness-local fallback) instead of `CONSULT_ROOT`, and
ran the `cost` subprocess with `TICK_REPO_ROOT` pinned in its child environment.

Cross-reference to Bash findings: this is the Python-side match for the one real fix in
`relay-automation/consult.sh`.

Verification:
- `python3 -m py_compile utils/py/consult.py`
- Targeted root-split smoke on 2026-07-17: `CONSULT_ROOT` pointed at a foreign git repo,
  `TICK_REPO_ROOT` pointed at a separate coordination repo, `CONSULT_GEMINI_JSON=1`, and the Python
  port produced a `cost.tokens` event for `CONSULT-gh172` under the pinned coordination repo's
  `.tick`.
- `XYZ_PYTHON=1 bash test/consult.sh` is still red, but for a broader pre-existing parity gap that I
  did not touch here: the Python port still lacks the Bash degraded-panel
  `SINGLE-MODEL — NOT RECONCILED` stamping path. The GH-172 tick-root fix above was verified
  separately so that unrelated failure does not get misreported as this seam regressing.
