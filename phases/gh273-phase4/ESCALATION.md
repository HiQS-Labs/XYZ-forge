# ESCALATION — Marathon Phase gh273-phase4

phase: gh273-phase4
task: MARATHON-GH273-PHASE4-TURN
relay-drive-exit: 5
reason: timeout-gate-failed
relay-file: phases/gh273-phase4/RELAY.md

## Resolution (manual, 2026-07-21)

The relay itself timed out before an agy review turn happened, but Codex's single turn already
committed a complete, correct implementation (`4de1ec2`): `--post-approve-cmd` in both
`relay-automation/marathon-drive.sh` and `utils/py/marathon_drive.py`, symmetric to the existing
`--pre-advance-cmd`, default unset, fired only after `marathon.phase.approved` already logged and
green telemetry already emitted, failure preserves the approval and exits 9 with reason
`post-approve-failed`. Verified directly by reading the diff (not just trusting a gate): both
runtimes match line-for-line in structure, and 14 new `test/marathon-drive.sh` cases (7 per runtime:
help documents the flag, omitted-flag parity, passing-hook runs once, failing-hook exits 9 +
preserves approval + records the escalation reason) all pass standalone (126/126 full file).

Unlike Phases 0-3, the pre-advance gate failure here was **not** the known `xyz-harness-hooks.sh`
flake — it was two genuine, different findings, both fixed:

1. **`test/marathon-root-audit.sh` regression** — the new `--help` check in `test/marathon-drive.sh`
   (`XYZ_PYTHON="$runtime" bash "$DRIVER" --help`) invoked the driver directly instead of through the
   file's `run_driver()` wrapper (which sets `MARATHON_ROOT="$A"`), so it lacked the safety marker
   this repo's own audit requires on every driver invocation inside the test file. Fixed by adding
   `MARATHON_ROOT="$A"` to that one line, matching the file's established idiom. Re-verified: audit
   passes (18 real invocations, all rooted/fixture-local), full `test/marathon-drive.sh` still 126/126.
2. **`test/security-scan.sh` finding** — the new `eval "$POST_APPROVE_CMD"` line correctly tripped
   the scanner (`eval-unsanitized`), same class as the pre-existing, already-baselined
   `eval "$PRE_ADVANCE_CMD"` a few lines above it. Reviewed: identical trust model (an operator-
   supplied CLI flag value, not attacker input, per the baseline file's own header comment) — added
   a symmetric baseline entry rather than changing the code. Re-verified: `test/security-scan.sh`
   35/35.

A full `bash validate.sh` re-run after both fixes: exit 0, no failures. **Phase 4 — and GH-273's
entire 5-phase plan — is manually confirmed shipped.**
