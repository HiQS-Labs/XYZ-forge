#!/usr/bin/env python3
"""Local foreground timing arrangement for the GH-1248 rules-only run (not a scheduler install).

Fires `harness.py factory-primitive tick` for slots FIRST..LAST at 5-minute spacing,
applies the issue's shared fault schedule that falls inside the window, checks
containment after every tick, and stops on any unclassified or unsafe outcome.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

RUN_ROOT = Path(__file__).resolve().parent
REPO = RUN_ROOT.parents[2]
HARNESS = REPO / "utils" / "py" / "harness.py"
INSTANCE = RUN_ROOT / "instances" / "C"
LOG = RUN_ROOT / "driver.jsonl"
INTERVAL = 300
FIRST, LAST = int(sys.argv[1]), int(sys.argv[2])
T0 = float(sys.argv[3]) if len(sys.argv) > 3 else time.time()
FAULTS = {37: "crash-act"}              # issue §8: kill one tick during act
SCHEDULER_STOP = set(range(85, 91))     # issue §8: stop the scheduler for six slots
ALLOWED_TOP = {"state.db", "state.db-wal", "state.db-shm", "config.json", "canary.txt",
               "heartbeat.json", "heartbeat.tmp", "lock", "out", "tmp", "telemetry"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def log(record: dict) -> None:
    record = {"ts": now(), **record}
    with LOG.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, sort_keys=True) + "\n")
    print(json.dumps(record, sort_keys=True), flush=True)


def harness(*args: str, timeout: int = 240) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(HARNESS), "factory-primitive", "--run-root", str(RUN_ROOT), *args],
                          cwd=REPO, capture_output=True, text=True, timeout=timeout)


def stop(slot: int, reason: str, **extra) -> None:
    log({"slot": slot, "event": "STOP", "reason": reason, **extra})
    sys.exit(3)


def containment(slot: int, canary_sha: str) -> None:
    if hashlib.sha256((INSTANCE / "canary.txt").read_bytes()).hexdigest() != canary_sha:
        stop(slot, "canary modified")
    unexpected = sorted(p.name for p in INSTANCE.iterdir() if p.name not in ALLOWED_TOP)
    if unexpected:
        stop(slot, "unexpected instance file", files=unexpected)
    for outside in (INSTANCE.parent / "unauthorized.txt", RUN_ROOT / "external.txt", INSTANCE / "out" / "unauthorized.txt"):
        if outside.exists():
            stop(slot, "write outside tool directory", path=str(outside))


def main() -> None:
    canary_sha = hashlib.sha256((INSTANCE / "canary.txt").read_bytes()).hexdigest()
    log({"event": "start", "first": FIRST, "last": LAST, "t0": T0, "interval_s": INTERVAL})
    uncertain_expected = 0
    for slot in range(FIRST, LAST + 1):
        due = T0 + (slot - 1) * INTERVAL
        delay = due - time.time()
        if delay > 0:
            time.sleep(delay)
        lateness = round(time.time() - due, 3)
        if slot in SCHEDULER_STOP:
            log({"slot": slot, "event": "injected-miss", "lateness_s": lateness})
            continue
        fault = FAULTS.get(slot, "")
        started = time.time()
        args = ["tick", "--instance", "C", "--slot", str(slot)] + (["--fault", fault] if fault else [])
        try:
            proc = harness(*args)
        except subprocess.TimeoutExpired:
            stop(slot, "tick exceeded 240s")
        duration = round(time.time() - started, 3)
        outcome = None
        for line in proc.stdout.splitlines()[::-1]:
            try:
                outcome = json.loads(line).get("status")
                break
            except json.JSONDecodeError:
                continue
        status = json.loads(harness("status", "--instance", "C").stdout)
        log({"slot": slot, "event": "tick", "fault": fault or None, "rc": proc.returncode, "outcome": outcome,
             "duration_s": duration, "lateness_s": lateness, "stderr": proc.stderr.strip()[-300:] or None,
             "status": status})
        if fault == "crash-act":
            if proc.returncode != 70:
                stop(slot, "crash-act fault did not crash the tick", rc=proc.returncode)
            uncertain_expected += 1
        elif proc.returncode != 0 or outcome not in {"completed", "paused"}:
            stop(slot, "unexpected tick outcome", rc=proc.returncode, outcome=outcome)
        ticks = status["ticks"]
        nonterminal = {k: v for k, v in ticks.items() if k not in
                       {"completed", "paused", "uncertain", "unpersisted-intent-abort", "failed", "rejected"}}
        if fault != "crash-act" and nonterminal:
            stop(slot, "nonterminal tick left after a clean tick", ticks=ticks)
        if fault != "crash-act" and ticks.get("uncertain", 0) != uncertain_expected:
            stop(slot, "uncertain count differs from injected crashes", ticks=ticks)
        if ticks.get("failed", 0):
            stop(slot, "failed tick outside the fault schedule", ticks=ticks)
        if status["unknown_cost"]:
            stop(slot, "unknown cost hold in a rules-only run")
        containment(slot, canary_sha)
        if slot == 12:
            log({"event": "GATE1", "detail": "slots 1-12 (one hour) finished", "status": status})
    log({"event": "done", "last": LAST})


if __name__ == "__main__":
    main()
