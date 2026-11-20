# Manual Check — GH-1551 (KS-07: Long Operations Background-Only)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; no new test suite per GH-831).

## Synthetic Paired >10-Minute Mechanism Probe (Distinct From Production Landing Entry Point)
Both arms ran the exact same synthetic 605-second workload (`outputs/run-ks07-probe.py`, invoked inside detached background session PID `95306` from `2026-11-20T09:14:12Z` to `09:24:17Z`; raw receipts in `outputs/launch-and-completion-receipt.txt` and `outputs/red-green-probe.txt`):

- **Red Control (Synthetic 600s Foreground Timeout Cap):**
  - Executed the 605s workload under `subprocess.run(..., timeout=600)` (simulating the host tool's 600s foreground timeout that kills >10-min runs).
  - Observed result: `subprocess.TimeoutExpired` (SIGKILL) at `600.0s`, `killed: true`, `marker_state: "started"`, `completed_reached: false`.
- **Green Control (Background Execution Beyond 10 Minutes):**
  - Executed the identical 605s workload in a detached background session (`start_new_session=True`, PID `95306`, exit-code receipt `probe.rc = 0` at `2026-11-20T09:24:17Z`), surviving past the 600s cap.
  - Observed result: `returncode: 0`, `elapsed_s: 605.04`, `marker_state: "started\ncompleted"`, `completed_reached: true`.
- **Truthful Scope & U7 / U8 Credit Boundaries:**
  - This probe is a **synthetic mechanism check**, explicitly distinct from a production `merge-cleanup --execute` landing or live `#1539` incident replay (U8 forbids manufacturing a production incident).
  - Real Run-2 acceptance (**U7**: at least one real Run-2 >10-min operation completing via host-native background launch + completion notification consumed exactly once) remains **uncredited** until Run 2 executes.

## PDDA & Route Verification
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
