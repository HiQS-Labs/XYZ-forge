# Manual Check — GH-1551 (KS-07: Long Operations Background-Only)

- **Issue:** #1551 (parent arc #1541, milestone KS-07)
- **Scope:** `skills/1-hourly/kickstart/SKILL.md` (rule 5: Long Operations Background-Only Execution)
- **Workload Classification:** **Synthetic mechanism check** (605-second sleep workload; zero repo, git, or GitHub mutations). Explicitly distinct from a production `merge-cleanup --execute` landing entry point. **U7 remains uncredited until Run 2.**
- **CI Route:** `route=docs`, `tier=1`, `full_required=false` (`outputs/ci-route.txt`)

## Exact Outer Launch & Native Completion Notification Receipts

1. **Outer Detached Launch (`outputs/launch-event.json` + `outputs/outer-launch.py`):**
   - Outer launch invoked via `run_command` calling `subprocess.Popen([sys.executable, '/tmp/ks07-outer-probe/outer-launch.py'], start_new_session=True, stdin=subprocess.DEVNULL)` at `2026-11-20T09:53:47Z`, spawning detached outer launcher PID `37102`.
   - Inside `outputs/outer-launch.py`, the **Green arm** launches the 605s workload in a new OS session (`start_new_session=True`, `stdin=DEVNULL`, `child_pid=37143`, `child_pgid=37143`, `child_sid=37143`, `detached_new_session=true`) and reaps its real kernel exit status via `os.waitpid(child_pid, 0)` (`waitpid_raw_status=0`, `os.WIFEXITED=true`, `os.WEXITSTATUS=0`), writing `outputs/outer-receipt.json` and `outputs/outer.rc` (`0`).
   - In parallel, the **Red arm** runs the identical 605s workload under a 600s foreground timeout (`subprocess.run(..., timeout=600)`), which is killed at `600.01s` (`TimeoutExpired after 600s`) at `2026-11-20T10:03:47Z` before completion.
2. **Host-Native Completion Notification (`outputs/native-launch-and-wakeup-receipt.json`):**
   - Armed Antigravity host-native `schedule(DurationSeconds=620, TimerCondition="never")` (`task-1113`, scheduled `2026-11-20T09:55:09.114516Z`) so the session waited asynchronously without polling.
   - Host delivered verbatim completion wakeup message at `2026-11-20T10:05:29Z`:
     `[Message] timestamp=2026-11-20T10:05:29Z sender=c3cb0a5e-3228-4f48-a9d6-d3596b2b6acf/task-1113 priority=MESSAGE_PRIORITY_HIGH content=KS-07 detached 605s outer probe (pid 37102) has reached 620s — collect /tmp/ks07-outer-probe/outer-receipt.json and finish KS-07 Final QA R3`
   - On wakeup, the session read `outputs/outer-receipt.json` confirming green arm finished cleanly at `2026-11-20T10:03:52Z` (`elapsed_s=605.04`, `os_exit_code=0`, stdout `START pid=37143 pgid=37143 sid=37143\nDONE_605S`).

## Paired Red/Green Summary

| Arm | Mechanism | Started UTC | Ended UTC | Elapsed | Result |
|---|---|---|---|---|---|
| **Red (foreground 600s cap)** | `subprocess.run(..., timeout=600)` on 605s workload | `2026-11-20T09:53:47Z` | `2026-11-20T10:03:47Z` | `600.01s` | **KILLED** (`TimeoutExpired` before completion) |
| **Green (detached + OS `waitpid` + host-native `schedule` wakeup)** | `start_new_session=True` (`pid=37143`, `pgid=37143`, `sid=37143`) + `os.waitpid` + native `schedule` `task-1113` wakeup | `2026-11-20T09:53:47Z` | `2026-11-20T10:03:52Z` (wakeup `10:05:29Z`) | `605.04s` | **PASS** (`waitpid_raw_status=0`, `os_exit_code=0`, `DONE_605S`) |

## Governance & Gate Checks
- `utils/ci-route.sh pull_request` (`outputs/ci-route.txt`): `route=docs`, `tier=1`, `full_required=false`.
- `env -u PDDA_LLM_BIN bash ./utils/pdda/pdda.sh run` (`outputs/pdda-run.log`): `0` errors.
- `outputs/skill-diff.patch`: exact 11-line diff to `skills/1-hourly/kickstart/SKILL.md`.
- `provenance.jsonl`: SHA-256 and byte counts for all retained artifacts under `TESTS-RESULTS/2026-11-20+GH-1551/`.
