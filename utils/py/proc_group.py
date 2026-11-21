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
import threading
import time
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Optional, Tuple

TIMEOUT_RC = 124
RSS_KILL_RC = 108
GATE_RSS_MB_DEFAULT = 8192


class Cancelled(KeyboardInterrupt):
    """CLI cancellation retaining the conventional signal exit status."""
    def __init__(self, signum: int):
        self.signum = signum
        super().__init__(f"interrupted by signal {signum}")


@contextmanager
def cancellation_signals():
    """CLI/main-thread boundary only; repeated signals cannot interrupt cleanup."""
    signals = (signal.SIGINT, signal.SIGTERM)
    previous = {sig: signal.getsignal(sig) for sig in signals}

    def cancel(signum, _frame):
        for sig in signals:
            signal.signal(sig, signal.SIG_IGN)
        raise Cancelled(signum)

    try:
        for sig in signals:
            signal.signal(sig, cancel)
        yield
    finally:
        for sig, handler in previous.items():
            signal.signal(sig, handler)


@dataclass
class BoundedResult:
    rc: Optional[int]  # None when the group was killed on expiry (no exit code exists)
    stdout: str
    stderr: str
    timed_out: bool
    pgid: int  # the child's pid; == its process group id (start_new_session)
    wall_seconds: float
    rss_killed: bool = False
    peak_rss_mb: Optional[int] = None


def group_rss_mb(pgid: int, *, run=subprocess.run) -> Tuple[Optional[int], Optional[str]]:
    """Summed RSS of a process group in MB as (mb, None), or (None, reason) when unreadable."""
    try:
        res = run(["ps", "-axo", "pgid=,rss="], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return None, "ps-failed"
    if res.returncode != 0 or not res.stdout.strip():
        return None, "ps-failed"
    total_kb = 0
    matched = False
    for line in res.stdout.splitlines():
        parts = line.split()
        if len(parts) != 2:
            continue
        try:
            if int(parts[0]) == pgid:
                total_kb += int(parts[1])
                matched = True
        except ValueError:
            continue
    if not matched:
        return None, "group-missing"
    return total_kb // 1024, None


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
    max_rss_mb: Optional[int] = None,
    rss_poll_s: float = 1.0,
) -> BoundedResult:
    """Run argv in its own process group under a wall-clock ceiling (and optional group-RSS cap).

    Spawn errors (FileNotFoundError, OSError, ValueError) propagate to the caller —
    they mean the command could not be launched at all.
    """
    t0 = time.monotonic()
    proc = subprocess.Popen(
        argv, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        stdin=subprocess.DEVNULL, text=True, errors="replace", start_new_session=True,
    )
    rss_killed = False
    peak_rss_mb: Optional[int] = None
    rss_stop = threading.Event()
    rss_thread: Optional[threading.Thread] = None

    def _communicate_tail(wait_timeout: Optional[float]) -> Tuple[str, str]:
        if getattr(proc, "stdout", None) is None or getattr(proc, "stderr", None) is None:
            return proc.communicate(timeout=wait_timeout)
        tails = {"stdout": "", "stderr": ""}

        def _read_tail(name: str, stream) -> None:
            tail = ""
            while True:
                chunk = stream.read(8192)
                if not chunk:
                    break
                tail = (tail + chunk)[-65536:]
            tails[name] = tail

        readers = [
            threading.Thread(target=_read_tail, args=("stdout", proc.stdout), daemon=True),
            threading.Thread(target=_read_tail, args=("stderr", proc.stderr), daemon=True),
        ]
        for reader in readers:
            reader.start()
        try:
            proc.wait(timeout=wait_timeout)
        except BaseException:
            for reader in readers:
                reader.join(timeout=0.1)
            raise
        for reader in readers:
            reader.join()
        return tails["stdout"], tails["stderr"]

    if max_rss_mb is not None and max_rss_mb > 0:
        poll_interval = max(0.05, float(rss_poll_s))

        def _watch_rss() -> None:
            nonlocal rss_killed, peak_rss_mb
            while not rss_stop.is_set():
                # The launcher may exit while a group member still holds an output pipe.
                rss_mb, reason = group_rss_mb(proc.pid)
                if reason == "group-missing":
                    return
                if rss_mb is not None:
                    peak_rss_mb = rss_mb if peak_rss_mb is None else max(peak_rss_mb, rss_mb)
                    if rss_mb >= max_rss_mb:
                        rss_killed = True
                        kill_existing(proc.pid, grace=grace)
                        return
                if rss_stop.wait(poll_interval):
                    return

        rss_thread = threading.Thread(target=_watch_rss, daemon=True)
        rss_thread.start()
    try:
        try:
            out, err = _communicate_tail(timeout)
            if rss_thread is not None:
                rss_stop.set()
                # A TERM/KILL sequence already in progress must finish before we return.
                rss_thread.join()
            return BoundedResult(proc.returncode, out or "", err or "", False, proc.pid,
                                 time.monotonic() - t0, rss_killed=rss_killed,
                                 peak_rss_mb=peak_rss_mb)
        except subprocess.TimeoutExpired:
            if rss_thread is not None:
                rss_stop.set()
            kill_existing(proc.pid, grace=grace)
            try:
                out, err = _communicate_tail(grace + 5)
            except subprocess.TimeoutExpired:
                out, err = "", ""
                proc.stdout.close()
                proc.stderr.close()
            if rss_thread is not None:
                rss_thread.join()
            return BoundedResult(None, out or "", err or "", True, proc.pid,
                                 time.monotonic() - t0, rss_killed=rss_killed,
                                 peak_rss_mb=peak_rss_mb)
    except BaseException:
        rss_stop.set()
        kill_existing(proc.pid, grace=grace)
        try:
            proc.wait(timeout=grace + 5)
        finally:
            proc.stdout.close()
            proc.stderr.close()
            if rss_thread is not None:
                rss_thread.join()
        raise


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
    if args.timeout is None:
        parser.error("--timeout is required unless --kill-pgid is used")
    try:
        proc = subprocess.Popen(cmd, start_new_session=True)
    except (FileNotFoundError, OSError, ValueError) as exc:
        print(f"proc_group: spawn failed: {exc}", file=sys.stderr)
        return 127
    try:
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
    except BaseException:
        kill_existing(proc.pid, grace=args.grace)
        proc.wait(timeout=args.grace + 5)
        raise



if __name__ == "__main__":
    try:
        with cancellation_signals():
            sys.exit(main())
    except Cancelled as exc:
        sys.exit(128 + exc.signum)
