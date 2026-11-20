# Manual Check — GH-1551 (KS-07: Long Operations Background-Only)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; no new test suite per GH-831).

## Paired Real >10-Minute Red/Green Probe (`outputs/red-green-probe.txt`)
Both sides executed the exact same 605-second (>10 min) workload in parallel (`2026-11-20T09:14:12Z` -> `09:24:17Z`):

- **Red Control (Foreground 600s Tool Timeout — reproducing #1539):**
  - `timeout_s: 600`, `elapsed_s: 600.0`, `killed: true`, `marker_state: "started"`, `completed_reached: false`.
  - Confirmed that a >10-min operation launched under a 600s foreground/tool timeout is killed mid-flight before reaching completion.
- **Green Control (Background Execution Beyond 10 Minutes):**
  - Launched in a detached background session (`start_new_session=True`, explicit PID + exit-code receipt, surviving the host shell's 600s cap), completing in `605.04s` with `returncode: 0`, `marker_state: "started\ncompleted"`, `completed_reached: true`.
- **U7 / U8 Credit Boundaries:** This milestone satisfies capability rubrics R1–R3 via the real >10-min paired red/green probe without manufacturing a production incident (U8); full U7 run-2 acceptance (at least one real run-2 operation >10 min completing in background with its result consumed exactly once) remains uncredited until Run 2 executes.

## PDDA & Route Verification
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
