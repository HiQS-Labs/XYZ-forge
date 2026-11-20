# Manual Check — GH-1551 (KS-07: Long Operations Background-Only)

- **Issue:** #1551 (KS-07 from #1541)
- **Date:** 2026-11-20
- **Branch:** `feat/XYZ-forge-gh1551-ks07-bg-long-ops-2026-11-20`
- **Route:** `docs` (18-file diff: rule 6 in `skills/1-hourly/kickstart/SKILL.md`, this evidence folder, the working doc and the GH-1551 ledger row; PR #1572)
- **Workload Classification:** Synthetic 605s/3s probes on Antigravity and a synthetic 660s probe on Claude Code (U8). Real >10-minute production/run-2 landing or gate completion consumed exactly once (U7) remains **explicitly uncredited until run 2**.

## 1. Host-Native Background Capability Probe (`outputs/native-bg-host-capability-probe.json`)
- **Sub-600s native completion (`task-1290`):** Launched `run_command(WaitMsBeforeAsync=500)` sleeping 3s (`pid=35815`, `10:28:00Z`). Host delivered a real completion-triggered `SYSTEM_MESSAGE` at `10:28:03Z` with `exit_code=0` and `KS07_NATIVE_BG_3S_DONE`.
- **Over-600s native probe (`task-1226`):** Launched `run_command(WaitMsBeforeAsync=500)` sleeping 605s (`pid=11951`, `10:14:57Z`). Host killed the command at exactly 600s (`10:24:57Z`) with verbatim error:
  `Command timed out, needed to complete in 600s. This timeout applies to all commands.`
- **Honest Host-Limitation & Transition 3 Finding:** This host (Antigravity ACP) supports native completion-triggered background commands for `<600s`, but enforces a hard 600s wall-clock cap on all `run_command` invocations. Therefore, this host **cannot** natively prove >600s completion-triggered background execution; it triggers the KS-07 **Transition 3** unsupported-host boundary for >600s operations.

## 2. Paired Detached-OS Survival vs 600s Timeout Control (`outputs/outer-launch.py`, `outputs/launch-event.json`, `outputs/outer-receipt.json`, `outputs/outer.rc`)
- **Red arm:** `subprocess.run(..., timeout=600)` killed at `600.01s` (`TimeoutExpired`).
- **Green arm (detached OS survival only):** `subprocess.Popen(..., start_new_session=True)` survived `605.04s` (`pid=37143`, `pgid=37143`, `sid=37143`, kernel `os.waitpid` `waitpid_raw_status=0`, `os_exit_code=0`).
- **Timer caveat (`outputs/native-launch-and-wakeup-receipt.json`):** `schedule(DurationSeconds=620, TimerCondition="never")` (`task-1113`) is explicitly documented as a **fixed-time reminder**, NOT a completion-triggered notification.

## 3. >600s Host Check (`outputs/host-bg-600s-claude-code.md`)
- **Host without the 600s ceiling:** Claude Code `Bash run_in_background` (`timeout 900000`) ran `sleep 660` from `2026-11-20T21:03:35Z` to `21:14:35Z`, exit 0, with a native completion notification delivered (task `buwc0oaro`). Contrasts with the Antigravity 600s kill in section 1. Closes the Final QA hold that the mechanism needed a >600s-capable host (operator "proceed", 2026-11-20). U7 (real run-2 operation) remains uncredited until run 2.

## 4. Governance & Evidence Integrity
- `outputs/ks07-skill.patch`: full `origin/development` vs `HEAD` diff of `skills/1-hourly/kickstart/SKILL.md` (rule 6, including the hard-600s-kill Transition 3 clarification; regenerated after merging `origin/development`).
- `outputs/pdda-run.log`: `./utils/pdda/pdda.sh run` — 0 errors.
- `provenance.jsonl`: exact SHA-256 and byte-size ledger verified for every artifact. The superseded first-draft `outputs/skill-diff.patch` was removed; `ks07-skill.patch` is the single skill diff.
