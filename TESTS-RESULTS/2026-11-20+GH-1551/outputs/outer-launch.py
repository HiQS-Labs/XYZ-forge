#!/usr/bin/env python3
"""KS-07 Outer Host-Native Detached Launcher + Red/Green Synthetic Probe.
Launches:
  1) RED arm: foreground 600s timeout cap kills a 605s synthetic workload (TimeoutExpired -> rc=-9/SIGKILL).
  2) GREEN arm: detached outer subprocess.Popen(..., start_new_session=True, stdin=DEVNULL)
     running a 605s synthetic workload, watched via OS os.waitpid(pid, 0) (never capped at 600s),
     writing real outer launch invocation, PID, PGID/SID, UTC start/end timestamps, OS waitpid status,
     and exit code to /tmp/ks07-outer-probe/outer-receipt.json.
Runs both arms concurrently so wall-clock is ~605s total (zero external/repo mutations).
"""
import concurrent.futures, json, os, signal, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

OUT = Path("/tmp/ks07-outer-probe")
now_utc = lambda: datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def run_red():
    t0_utc, t0 = now_utc(), time.monotonic()
    cmd = [sys.executable, "-c", "import time; time.sleep(605)"]
    try:
        p = subprocess.run(cmd, timeout=600, capture_output=True, text=True)
        return {"arm": "red_fg_600s_cap", "cmd": cmd, "started_utc": t0_utc, "ended_utc": now_utc(),
                "elapsed_s": round(time.monotonic() - t0, 2), "timed_out": False, "returncode": p.returncode}
    except subprocess.TimeoutExpired as exc:
        return {"arm": "red_fg_600s_cap", "cmd": cmd, "started_utc": t0_utc, "ended_utc": now_utc(),
                "elapsed_s": round(time.monotonic() - t0, 2), "timed_out": True,
                "error": f"TimeoutExpired after {exc.timeout}s (process killed by foreground timeout)"}

def run_green():
    t0_utc, t0 = now_utc(), time.monotonic()
    log_file = OUT / "green-workload.log"
    cmd = [sys.executable, "-c",
           "import os, time; print(f'START pid={os.getpid()} pgid={os.getpgrp()} sid={os.getsid(0)}', flush=True); "
           "time.sleep(605); print('DONE_605S', flush=True)"]
    with log_file.open("w", encoding="utf-8") as lf:
        proc = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=lf, stderr=subprocess.STDOUT,
                                start_new_session=True, close_fds=True)
        child_pid = proc.pid
        child_pgid = os.getpgid(child_pid)
        child_sid = os.getsid(child_pid)
        # Reap via real OS waitpid(child_pid, 0) — no 600s cap
        waited_pid, raw_status = os.waitpid(child_pid, 0)
        exited = os.WIFEXITED(raw_status)
        exit_code = os.WEXITSTATUS(raw_status) if exited else -os.WTERMSIG(raw_status)
        proc.returncode = exit_code
    t1_utc, elapsed = now_utc(), round(time.monotonic() - t0, 2)
    return {
        "arm": "green_detached_start_new_session",
        "launcher_pid": os.getpid(),
        "launcher_sid": os.getsid(0),
        "child_pid": child_pid,
        "child_pgid": child_pgid,
        "child_sid": child_sid,
        "detached_new_session": (child_sid == child_pid and child_sid != os.getsid(0)),
        "cmd": cmd,
        "started_utc": t0_utc,
        "ended_utc": t1_utc,
        "elapsed_s": elapsed,
        "waitpid_pid": waited_pid,
        "waitpid_raw_status": raw_status,
        "wifexited": exited,
        "os_exit_code": exit_code,
        "workload_log": log_file.read_text(encoding="utf-8").strip(),
    }

outer_start = now_utc()
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
    f_red = ex.submit(run_red)
    f_green = ex.submit(run_green)
    red_res = f_red.result()
    green_res = f_green.result()

receipt = {
    "synthetic_workload": True,
    "u7_boundary": "Synthetic 605s sleep workload; zero repo, git, or GitHub mutations.",
    "outer_launcher_cmd": [sys.executable, str(OUT / "outer-launch.py")],
    "outer_launcher_pid": os.getpid(),
    "outer_started_utc": outer_start,
    "outer_completed_utc": now_utc(),
    "red_arm": red_res,
    "green_arm": green_res,
    "assertions_passed": bool(red_res["timed_out"] and green_res["wifexited"] and green_res["os_exit_code"] == 0 and green_res["elapsed_s"] >= 605.0 and green_res["detached_new_session"]),
}
(OUT / "outer-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
(OUT / "outer.rc").write_text("0\n" if receipt["assertions_passed"] else "1\n", encoding="utf-8")
