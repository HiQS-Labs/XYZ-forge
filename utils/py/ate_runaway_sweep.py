#!/usr/bin/env python3
"""
ate_runaway_sweep.py — find (and, only on an explicit flag, stop) orphaned ATE
engine processes on this machine (GH-478).

On 2026-09-03 an ATE engine call (`python -c "... from utils.py.adaptive_ate
import generate_pairwise ..."`) hung for 2d21h at ~98% duty cycle, invisible to
its session. The in-suite guard (test/lib/runaway-guard.sh) caps and reaps
inside guarded suites; this sweep is the machine-wide backstop for everything
else — orphaned marathons, crashed sessions, a future hang of any origin.

Matching is TOKEN-AWARE, never a raw substring (GH-478 plan QA round 2,
finding 4) — on one `ps -axo pid=,ppid=,uid=,etime=,lstart=,command=` snapshot:

  Shape A  a token whose basename is exactly `adaptive_ate.py`, preceded by an
           interpreter-ish token (basename starting with `python`); tokens
           AFTER the script token are free (flags/args are normal) — the
           `python3 .../utils/py/adaptive_ate.py --mode ...` CLI shape.
  Shape B  an interpreter token, then `-c`, with the embedded code importing
           `utils.py.adaptive_ate` — the `python -c` shape the incident ran.

A bare `adaptive_ate` substring (greps, editors, `my_adaptive_ate.py`,
`adaptive_ate.py.bak`) matches nothing.

Scope: current UID only; the sweep itself and its ancestors are always excluded.
Age: ps etime >= --max-age-minutes (default 30 — unit-scale ATE calls are
minutes; the incident ran days). `--max-age-minutes 0` sweeps everything.

DESTRUCTIVE PATH: dry-run is the default and only reports. `--kill` is the
explicit flag; before any signal the candidate's identity is RECHECKED against
a fresh `ps -p`: uid and lstart must match exactly — lstart carries whole-second
precision, so this rules out all but a same-second PID reuse — and the snapshot
command must still be CONTAINED in the fresh command (a shim re-exec legitimately
grows the interpreter prefix; containment with a different lstart is refused).
Then TERM, a `--grace-seconds` window (default 5), then KILL. Every signal is
logged with a timestamp, pid, and command. The sweep signals matched ATE leaders
only — descendant cleanup outside guarded suites is the in-suite guard's job and
stays deliberately out of scope here (plan rev 3).
"""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import time
from datetime import datetime
from typing import Any, Optional

# Negative-control seams (GH-478): the suite sed-mutates these on a COPY of this
# file and requires the mutated copy to go red; see
# test/baselines/GH-478-negative-control.md. Do not inline or rename.
MATCH_BASENAME_EXACT = True
REQUIRE_ARGV_AFTER_SCRIPT = False

SCRIPT_BASENAME = "adaptive_ate.py"
MODULE_MARK = "utils.py.adaptive_ate"
PS_COMMAND = ["ps", "-axo", "pid=,ppid=,uid=,etime=,lstart=,command="]


def parse_ps_duration(text: str) -> Optional[float]:
    """Parse ps etime `[[dd-]hh:]mm:ss` into seconds; None when unparseable."""
    raw = text.strip()
    if not raw:
        return None
    days = 0.0
    if "-" in raw:
        day_part, _, raw = raw.partition("-")
        if not day_part.isdigit():
            return None
        days = float(day_part) * 86400
    parts = raw.split(":")
    if len(parts) > 3 or not all(p.strip() for p in parts):
        return None
    try:
        seconds = float(int(parts[-1]))
        minutes = float(int(parts[-2])) if len(parts) >= 2 else 0.0
        hours = float(int(parts[-3])) if len(parts) >= 3 else 0.0
    except ValueError:
        return None
    if seconds < 0 or minutes < 0 or hours < 0:
        return None
    return days + hours * 3600 + minutes * 60 + seconds


def matches_ate(command: str) -> bool:
    """Token-aware ATE-engine signature on the ps command column (shapes A and B).

    ps does NOT preserve argv boundaries, so tokenization is a documented heuristic,
    not an argv reconstruction. macOS renders `python3 script.py` inconsistently:
    the Homebrew build shows the interpreter token (`.../MacOS/Python script.py`),
    the CLT shim shows the SCRIPT as the first token with the interpreter suppressed
    — shape A accepts both. Shape B (the 2026-09-06 incident shape,
    `python -c "... from utils.py.adaptive_ate import ..."`): a python-ish
    interpreter immediately before `-c`, and the REMAINDER of the command (joined,
    whitespace-normalized — the marker lands in a later token once ps has split the
    quoted code block) containing the module mark.
    """
    tokens = command.split()
    basenames = [os.path.basename(tok) for tok in tokens]
    for i, base in enumerate(basenames):
        base_ok = base == SCRIPT_BASENAME if MATCH_BASENAME_EXACT else SCRIPT_BASENAME in base
        if base_ok:
            preceded_by_python = i > 0 and basenames[i - 1].lower().startswith("python")
            if i == 0 or preceded_by_python:
                if REQUIRE_ARGV_AFTER_SCRIPT and i == len(tokens) - 1:
                    continue
                return True
    for i, tok in enumerate(tokens):
        # The interpreter token before -c may be SUPPRESSED by the CLT shim's ps
        # rendering (argv[0] gone entirely), so `-c` as the first token also counts.
        if tok == "-c" and (i == 0 or basenames[i - 1].lower().startswith("python")):
            remainder = " ".join(tokens[i + 1:])
            if MODULE_MARK in remainder:
                return True
    return False


def snapshot() -> dict:
    """pid -> {ppid, uid, etime_s, lstart, command} for every process on the machine."""
    res = subprocess.run(PS_COMMAND, capture_output=True, text=True, timeout=15)
    if res.returncode != 0:
        raise RuntimeError(f"ps failed: {res.stderr.strip()[:200]}")
    procs: dict = {}
    for line in res.stdout.splitlines():
        tokens = line.split(None, 10)
        if len(tokens) < 11:
            continue
        pid_s, ppid_s, uid_s, etime_s = tokens[:4]
        lstart = " ".join(tokens[4:9])
        command = tokens[10].rstrip("\n").strip()
        if not pid_s.isdigit() or not ppid_s.isdigit():
            continue
        try:
            uid = int(uid_s)
        except ValueError:
            continue
        elapsed = parse_ps_duration(etime_s)
        if elapsed is None:
            continue
        procs[int(pid_s)] = {
            "ppid": int(ppid_s),
            "uid": uid,
            "etime_s": elapsed,
            "lstart": lstart,
            "command": command,
        }
    return procs


def ancestor_pids(procs: dict, pid: int) -> set:
    """pid and every transitive ancestor (ppid walk to init) — always excluded."""
    chain = set()
    current: Any = pid
    while current in procs and current not in chain:
        chain.add(current)
        current = procs[current]["ppid"]
    return chain


def candidates(procs: dict, now_uid: int, excluded: set, max_age_seconds: float) -> list:
    found = []
    for pid, info in procs.items():
        if pid in excluded:
            continue
        if info["uid"] != now_uid:
            continue
        if info["etime_s"] < max_age_seconds:
            continue
        if not matches_ate(info["command"]):
            continue
        found.append({"pid": pid, **info})
    return sorted(found, key=lambda item: item["pid"])


def identity_recheck(pid: int, expected: dict) -> bool:
    """Fresh ps must confirm the same living process — a recycled PID is refused.

    Contract (plan rev 3, R4 — revised from naive full-command equality): uid and
    lstart are the LOAD-BEARING identity pair and must match exactly; lstart is
    immutable for a living process, so equal uid+lstart rules out PID recycling.
    The command is a containment sanity check, not an equality: shim-launched
    interpreters re-exec between the snapshot and the reexec, so the fresh command
    legitimately GROWS the interpreter prefix — require the snapshot command to
    still be contained in the fresh one.
    """
    res = subprocess.run(
        ["ps", "-p", str(pid), "-o", "uid=,lstart=,command="],
        capture_output=True, text=True, timeout=10,
    )
    if res.returncode != 0:
        return False
    tokens = res.stdout.split(None, 6)
    if len(tokens) < 7:
        return False
    try:
        uid = int(tokens[0])
    except ValueError:
        return False
    lstart = " ".join(tokens[1:6])
    command = tokens[6].rstrip("\n").strip()
    return uid == expected["uid"] and lstart == expected["lstart"] and expected["command"] in command


def log(message: str) -> None:
    print(f"{datetime.now().astimezone().strftime('%Y-%m-%d %H:%M:%S %Z')} ate-sweep: {message}", flush=True)


def kill_process(pid: int, command: str, grace: float) -> None:
    log(f"KILL: sending SIGTERM to pid {pid}: {command}")
    try:
        os.kill(pid, signal.SIGTERM)
    except (ProcessLookupError, PermissionError, OSError) as exc:
        log(f"SKIP: pid {pid} could not be signalled ({exc})")
        return
    deadline = time.monotonic() + grace
    while time.monotonic() < deadline:
        try:
            os.kill(pid, 0)
        except (ProcessLookupError, PermissionError, OSError):
            log(f"pid {pid} exited on SIGTERM")
            return
        time.sleep(0.1)
    try:
        os.kill(pid, signal.SIGKILL)
        log(f"ESCALATE: pid {pid} ignored SIGTERM for {grace}s — SIGKILL sent: {command}")
    except (ProcessLookupError, PermissionError, OSError):
        log(f"pid {pid} exited on SIGTERM")


def main() -> int:
    parser = argparse.ArgumentParser(description="Find (and only with --kill, stop) orphaned ATE engine processes")
    parser.add_argument("--kill", action="store_true", help="actually signal matched processes (default: report only)")
    parser.add_argument("--max-age-minutes", type=float, default=30.0,
                        help="minimum ps etime for a candidate (default 30; 0 sweeps everything)")
    parser.add_argument("--grace-seconds", type=float, default=5.0,
                        help="SIGTERM window before SIGKILL escalation on --kill (default 5)")
    parser.add_argument("--limit-pids", default="",
                        help="comma-separated pids the run may consider (containment lever for "
                             "suites: candidates outside this list are ignored; signature, age, "
                             "uid, and identity-recheck rules still apply)")
    args = parser.parse_args()

    limit = {int(p) for p in args.limit_pids.split(",") if p.strip().isdigit()} if args.limit_pids else None
    procs = snapshot()
    excluded = ancestor_pids(procs, os.getpid())
    found = candidates(procs, os.getuid(), excluded, args.max_age_minutes * 60)
    if limit is not None:
        found = [item for item in found if item["pid"] in limit]

    if not found:
        print("ate-sweep: no orphaned ATE engine processes")
        return 0

    for item in found:
        tag = "KILL" if args.kill else "candidate"
        log(f"{tag}: pid={item['pid']} elapsed={item['etime_s']:.0f}s: {item['command']}")

    if not args.kill:
        log(f"dry run: {len(found)} candidate(s) reported, nothing signalled")
        return 0

    for item in found:
        # Identity recheck against a FRESH ps: a recycled PID must never be signalled.
        if not identity_recheck(item["pid"], item):
            log(f"SKIP: pid {item['pid']} identity changed between snapshot and kill — recycled PID?")
            continue
        kill_process(item["pid"], item["command"], args.grace_seconds)
    return 0


if __name__ == "__main__":
    sys.exit(main())
