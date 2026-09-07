#!/usr/bin/env python3
"""
proc_group.py — the ONE shared process-group runner (GH-478).

Every place that runs a bounded command whose children must not survive a timeout
goes through this module. `start_new_session=True` makes the child a session leader
with PGID == PID — the only portable way to get a stable process group (macOS ships
no `setsid`, and a non-interactive shell puts background jobs in the caller's group).
The wall-clock expiry targets the WHOLE group: SIGTERM, a grace window, then
SIGKILL — so a TERM-resistant grandchild cannot outlive the cap. A witnessed
timeout is distinguishable from the child's own exit: `timed_out=True` on the API
result, exit code 124 from the CLI seam.

Factored from the two ATE callers that each maintained their own copy of this
plumbing (GH-478 plan QA round 2, finding 1):
  - utils/ate/scripts/run_variations.py:run_harness  (Popen + killpg SIGKILL)
  - utils/py/fuzz_engine.py:execute/_kill_group      (Popen + killpg SIGKILL, rc 124)
and consumed by the suite-layer guard (test/lib/runaway-guard.sh) via the CLI seam.

CLI seam for bash callers:

    python3 utils/py/proc_group.py --timeout N [--grace G] [--pgid-file F] -- cmd...

Exit codes: the child's own exit code, or 124 on a witnessed timeout. With
--pgid-file, the child's pid (== its PGID) is written there as soon as it exists —
the group stays a valid kill target even after the leader exits.
"""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import Optional

TIMEOUT_RC = 124


@dataclass
class BoundedResult:
    rc: Optional[int]  # None when the group was killed on expiry (no exit code exists)
    stdout: str
    stderr: str
    timed_out: bool
    pgid: int  # the child's pid; == its process group id (start_new_session)
    wall_seconds: float


def kill_existing(pgid: int, grace: float = 5.0) -> None:
    """TERM an ALREADY-RUNNING process group, wait out a grace window, then KILL.

    The seam the suite-layer reaper (test/lib/runaway-guard.sh) uses, so group
    killing exists exactly once (GH-478 round 3): killing is proc_group's job,
    detection (the liveness probe) stays with the caller.
    """
    try:
        os.killpg(pgid, signal.SIGTERM)
    except (ProcessLookupError, PermissionError, OSError):
        try:
            os.killpg(pgid, signal.SIGKILL)
        except OSError:
            return
    deadline = time.monotonic() + grace
    while time.monotonic() < deadline:
        try:
            os.killpg(pgid, 0)
        except (ProcessLookupError, PermissionError, OSError):
            return
        time.sleep(0.1)
    try:
        os.killpg(pgid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
        pass


def run_bounded(
    argv: list,
    *,
    cwd: Optional[str] = None,
    env: Optional[dict] = None,
    timeout: Optional[float] = None,
    grace: float = 5.0,
) -> BoundedResult:
    """Run argv in its own process group under a wall-clock ceiling.

    Spawn errors (FileNotFoundError, OSError, ValueError) propagate to the caller —
    they mean the command could not be launched at all.
    """
    t0 = time.monotonic()
    proc = subprocess.Popen(
        argv, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        stdin=subprocess.DEVNULL, text=True, errors="replace", start_new_session=True,
    )
    try:
        out, err = proc.communicate(timeout=timeout)
        return BoundedResult(proc.returncode, out or "", err or "", False, proc.pid,
                             time.monotonic() - t0)
    except subprocess.TimeoutExpired:
        kill_existing(proc.pid, grace=grace)
        try:
            out, err = proc.communicate(timeout=grace + 5)
        except subprocess.TimeoutExpired:
            out, err = "", ""
        return BoundedResult(None, out or "", err or "", True, proc.pid,
                             time.monotonic() - t0)


def main() -> int:
    argv = sys.argv[1:]
    if "--" in argv:
        split = argv.index("--")
        flags, cmd = argv[:split], argv[split + 1:]
    else:
        flags, cmd = argv, []  # e.g. the --kill-pgid seam takes no command
    parser = argparse.ArgumentParser(description="Run cmd in its own process group under a timeout")
    parser.add_argument("--timeout", type=float)
    parser.add_argument("--grace", type=float, default=5.0)
    parser.add_argument("--pgid-file")
    parser.add_argument("--ack-file",
                         help="two-phase startup handshake: after publishing the pgid, wait for "
                              "this file to appear; if the caller never acknowledges, the "
                              "just-started group is killed (fail closed)")
    parser.add_argument("--ack-wait", type=float, default=10.0)
    parser.add_argument("--kill-pgid", type=int,
                         help="kill an ALREADY-RUNNING process group (TERM, grace, KILL) and exit")
    args = parser.parse_args(flags)
    if args.kill_pgid is not None:
        kill_existing(args.kill_pgid, grace=args.grace)
        return 0
    if not cmd:
        parser.error("no command after '--' (or use --kill-pgid N)")
    try:
        proc = subprocess.Popen(cmd, start_new_session=True)
    except (FileNotFoundError, OSError, ValueError) as exc:
        print(f"proc_group: spawn failed: {exc}", file=sys.stderr)
        return 127
    if args.pgid_file:
        # Fail closed (GH-478 round 3): the bash caller tracks the group through this
        # file. If it cannot be published, kill the just-started group rather than
        # leave an untrackable child behind, and say so.
        try:
            with open(args.pgid_file, "w") as fh:
                fh.write(str(proc.pid))
        except OSError as exc:
            print(f"proc_group: pgid publication FAILED ({exc}) — killing the "
                  f"just-started group {proc.pid}", file=sys.stderr)
            kill_existing(proc.pid, grace=args.grace)
            try:
                proc.wait(timeout=args.grace + 5)
            except subprocess.TimeoutExpired:
                pass
            return 125
    if args.ack_file:
        # Two-phase startup (GH-478 round 4): the child stays killable-by-handshake —
        # if the caller never acknowledges a validated pgid, kill the group instead of
        # leaving it untracked. The child is already in its own session, so this works
        # no matter what the caller's shell did with the wrapper.
        ack_deadline = time.monotonic() + args.ack_wait
        acknowledged = False
        while time.monotonic() < ack_deadline:
            if os.path.exists(args.ack_file):
                acknowledged = True
                try:
                    os.remove(args.ack_file)  # consume it — the caller must not race a re-create
                except OSError:
                    pass
                break
            try:
                os.killpg(proc.pid, 0)
            except (ProcessLookupError, PermissionError, OSError):
                acknowledged = True  # child already exited on its own; nothing to guard
                break
            time.sleep(0.1)
        if not acknowledged:
            print(f"proc_group: pgid NEVER ACKNOWLEDGED — killing the just-started "
                  f"group {proc.pid}", file=sys.stderr)
            kill_existing(proc.pid, grace=args.grace)
            try:
                proc.wait(timeout=args.grace + 5)
            except subprocess.TimeoutExpired:
                pass
            return 125
    if args.timeout is None:
        parser.error("--timeout is required unless --kill-pgid is used")
    try:
        proc.wait(timeout=args.timeout)
    except subprocess.TimeoutExpired:
        print(f"proc_group: TIMEOUT after {args.timeout}s — killing process group of "
              f"pid {proc.pid}: {' '.join(cmd)}", file=sys.stderr)
        kill_existing(proc.pid, grace=args.grace)
        try:
            proc.wait(timeout=args.grace + 5)
        except subprocess.TimeoutExpired:
            pass
        return TIMEOUT_RC
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main())
