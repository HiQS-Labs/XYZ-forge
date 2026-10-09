#!/usr/bin/env python3
"""Finite marathon observations; the launcher alone writes this projection.

No dispatch, worker signals, coordination writes or outcome decisions live here.
Driver terminal receipts remain authoritative; missing evidence stays unknown.
"""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import tempfile
import threading
import time
import uuid


def utc():
    return datetime.now(timezone.utc).isoformat()


def bounded_read(path):
    """Reject special/symlink files and cap reads, including concurrently growing files."""
    fd = None
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
        meta = os.fstat(fd)
        if not stat.S_ISREG(meta.st_mode) or meta.st_size > 1024 * 1024:
            return None
        with os.fdopen(fd, "rb") as stream:
            fd = None
            data = stream.read(1024 * 1024 + 1)
        return data.decode("utf-8") if len(data) <= 1024 * 1024 else None
    except (OSError, UnicodeError, TypeError):
        return None
    finally:
        if fd is not None:
            os.close(fd)


def read_json(path):
    try:
        value = json.loads(bounded_read(path) or "null")
        return value if isinstance(value, dict) else {}
    except ValueError:
        return {}


def write_context(path, data):
    fd, temporary = tempfile.mkstemp(prefix=".marathon-progress.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(data, stream)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def git_value(root, *args):
    try:
        return subprocess.check_output(["git", "-C", root, *args], stderr=subprocess.DEVNULL,
                                       timeout=2, text=True).strip() or "unknown"
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def matching_receipt(context):
    phase = context.get("phase", {})
    result = read_json(phase.get("result_file"))
    target = result.get("target_repo")
    if not isinstance(target, dict):
        return {}
    if (result.get("schema") != "marathon-drive/result@1"
            or result.get("execution_id") != phase.get("execution_id")
            or result.get("phase") != phase.get("id")
            or result.get("lane") != phase.get("lane")
            or target.get("path") != context["product_root"]):
        return {}
    token = result.get("token")
    family = phase["token_family"]
    if not isinstance(token, str) or not (token == family or token.startswith(family + "-")):
        return {}
    return result


def qualified(result):
    gate = result.get("gate")
    acceptance = result.get("acceptance")
    return (result.get("outcome") == "approved" and result.get("exit_code") == 0
            and isinstance(gate, dict) and gate.get("result") == "green" and gate.get("exit") == 0
            and bool(re.fullmatch(r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_candidate"))))
            and bool(re.fullmatch(r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_head"))))
            and isinstance(result.get("attest_path"), str) and bool(result["attest_path"])
            and not (isinstance(acceptance, dict) and acceptance.get("checked")
                     and acceptance.get("unmet_count") != 0))


def heartbeat(context):
    beat = read_json(context["heartbeat_file"])
    phase = context.get("phase", {})
    if (not phase or beat.get("phase_id") != phase.get("id")
            or beat.get("pid") != phase.get("driver_pid")):
        return {"state": "unknown"}
    token = beat.get("relay_task")
    family = phase["token_family"]
    if not isinstance(token, str) or not (token == family or token.startswith(family + "-")):
        return {"state": "unknown"}
    try:
        stamp = datetime.fromisoformat(beat["updated_utc"].replace("Z", "+00:00"))
        started = datetime.fromisoformat(beat["started_utc"].replace("Z", "+00:00"))
        # Driver timestamps have whole-second resolution; PID/phase/token provide attribution.
        run_started = datetime.fromisoformat(context["started_utc"]).replace(microsecond=0)
        age = (datetime.now(timezone.utc) - stamp).total_seconds()
        if age < 0 or started < run_started or stamp < started:
            raise ValueError("foreign or future heartbeat")
        return {"state": "liveness only", "age_s": round(age, 1), "pid": beat.get("pid")}
    except (KeyError, TypeError, ValueError, AttributeError):
        return {"state": "unknown"}


def emit(context, kind, **extra):
    phase = context.get("phase", {})
    relay = bounded_read(phase.get("relay_file")) or ""
    fields = {}
    for line in relay.splitlines():
        if line.startswith(("STATUS:", "NEXT:")):
            key, value = line.split(":", 1)
            fields.setdefault(key, value.strip())
    result = matching_receipt(context) if phase else {}
    report = {
        "kind": kind, "observed_at": utc(), "run_id": context["run_id"],
        "plan": context["plan"], "harness_root": context["harness_root"],
        "coordination_root": context["root"], "product_root": context["product_root"],
        "initial_head": context["initial_head"], "initial_origin": context["initial_origin"],
        "phase": phase.get("id", "not started"), "phase_index": phase.get("index", 0),
        "role": fields.get("NEXT", "unknown"), "relay_status": fields.get("STATUS", "unknown"),
        "heartbeat": heartbeat(context), "returned_success": context["returned_success"],
        "verified_phases": context["verified_phases"], "total_phases": context["total"],
        "last_product_milestone": context["last_milestone"],
        "gate": result["gate"] if isinstance(result.get("gate"), dict) else "unknown",
        "reviewed_candidate": result.get("reviewed_candidate") if re.fullmatch(
            r"[0-9a-f]{40}(?:[0-9a-f]{24})?", str(result.get("reviewed_candidate"))) else "unknown",
        "result_file": phase.get("result_file"), "relay_file": phase.get("relay_file"),
        "run_log": context["run_log"], **extra,
    }
    print("marathon-progress: " + json.dumps(report, sort_keys=True), flush=True)


def due_slots(start, interval, count, emitted, now):
    """Consume overdue slots; only the latest gets a present-time snapshot."""
    latest = min(count, int((now - start) // interval))
    return range(emitted + 1, max(emitted, latest) + 1)


def observe(path):
    initial = read_json(path)
    owner = initial["owner"]
    start, interval, count = initial["started_monotonic"], initial["interval"], initial["count"]
    stopped = threading.Event()
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, lambda *_: stopped.set())
    emitted = 0
    while not stopped.is_set():
        context = read_json(path)
        if context.get("run_id") != initial["run_id"]:
            emit(initial, "observation-ended", reason="context unavailable or changed",
                 next_action="Inspect the original run log; execution status unknown")
            return
        if context.get("observation_stop"):
            return
        if os.getppid() != owner:
            emit(context, "owner-lost", execution_status="unknown", descendants="unknown",
                 next_action="Establish ownership and stopped descendants before any re-fire")
            return
        slots = list(due_slots(start, interval, count, emitted, time.monotonic()))
        for slot in slots:
            if slot != slots[-1]:
                print("marathon-progress: " + json.dumps({"kind": "missed-check", "run_id": initial["run_id"],
                                                        "check": slot, "count": count}), flush=True)
            else:
                emit(context, "check", check=slot, count=count)
            emitted = slot
        if emitted == count:
            emit(context, "observation-ended", execution_status="continues independently",
                 next_action="Inspect this run log or use marathon-detail.sh; no automatic retry")
            return
        stopped.wait(min(0.25, max(0, start + (emitted + 1) * interval - time.monotonic())))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("init", "phase", "driver", "finish", "observe", "terminal"))
    parser.add_argument("context", type=Path)
    for name in ("root", "product-root", "harness-root", "plan", "run-log", "phases-dir",
                 "heartbeat-file", "phase-id", "lane", "token-family", "execution-id", "result-file"):
        parser.add_argument("--" + name)
    for name in ("owner", "total", "interval", "count", "index", "exit-code", "driver-pid"):
        parser.add_argument("--" + name, type=int)
    args = parser.parse_args()
    if args.action == "observe":
        observe(args.context)
        return
    if args.action == "init":
        context = {"run_id": uuid.uuid4().hex, "owner": args.owner, "plan": str(Path(args.plan).resolve()),
                   "root": str(Path(args.root).resolve()), "product_root": str(Path(args.product_root).resolve()),
                   "harness_root": str(Path(args.harness_root).resolve()), "run_log": args.run_log,
                   "phases_dir": str(Path(args.phases_dir).resolve()), "heartbeat_file": args.heartbeat_file,
                   "initial_head": git_value(args.product_root, "rev-parse", "HEAD"),
                   "initial_origin": git_value(args.product_root, "remote", "get-url", "origin"),
                   "started_monotonic": time.monotonic(), "started_utc": utc(),
                   "interval": args.interval, "count": args.count,
                   "total": args.total, "returned_success": 0, "verified_phases": 0,
                   "milestones": [], "last_milestone": None}
        write_context(args.context, context)
        print(context["run_id"])
        return
    context = read_json(args.context)
    if args.action == "phase":
        context["phase"] = {"id": args.phase_id, "index": args.index, "lane": args.lane,
                            "token_family": args.token_family, "execution_id": args.execution_id,
                            "result_file": args.result_file,
                            "relay_file": str(Path(context["phases_dir"]) / args.lane / "RELAY.md")}
        write_context(args.context, context)
    elif args.action == "driver":
        context["phase"]["driver_pid"] = args.driver_pid
        write_context(args.context, context)
    elif args.action == "finish":
        context["phase"]["exit_code"] = args.exit_code
        result = matching_receipt(context)
        if args.exit_code == 0:
            context["returned_success"] += 1
        if args.exit_code == 0 and qualified(result):
            context["verified_phases"] += 1
            candidate = result["reviewed_candidate"]
            if (result.get("reason") != "already-satisfied" and candidate != context["initial_head"]
                    and candidate not in context["milestones"]):
                context["milestones"].append(candidate)
                context["last_milestone"] = {"phase": result["phase"], "candidate": candidate,
                                             "observed_at": utc(), "result_file": context["phase"]["result_file"]}
        write_context(args.context, context)
    else:
        context["observation_stop"] = True
        write_context(args.context, context)
        emit(context, "terminal", exit_code=args.exit_code, descendants="unknown",
             next_action="Inspect halt/repair evidence before any re-fire" if args.exit_code else "Review completed run evidence")


if __name__ == "__main__":
    main()
