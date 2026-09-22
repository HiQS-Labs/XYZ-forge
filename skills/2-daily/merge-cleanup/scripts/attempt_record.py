#!/usr/bin/env python3
"""GH-534 Phase C — the durable per-PR attempt record and its lock.

One record per (origin, PR) at ONE pinned coordinator: `<primary>/.tick/merge-cleanup/<owner>-<repo>/pr-<N>.json`.
The script (B1) and the caller's repair rungs both write it, so the two-repair ceiling is enforced across
clones, restarts and heads. Every writer holds `fcntl.flock(LOCK_EX)` on `<record>.lock` for the whole
read → reserve → write sequence. This lock is deliberately NOT the driver's mkdir lock: a worker started
under a running driver must still be able to reserve.

Rules pinned by test/gh534_phase_c_tests.py:
- only repair attempts count; `note` (diagnosis/recon) never consumes budget;
- the ceiling is per PR whatever the head — a failed repair's new head mints nothing;
- a lock timeout STOPS the attempt (it is never counted as "skipped");
- a worker without MERGE_CLEANUP_RECORD, or with an unreadable/malformed record, STOPS — it never
  derives a record root from its own CWD.
"""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

RECORD_ENV = "MERGE_CLEANUP_RECORD"
LOCK_TIMEOUT_ENV = "MERGE_CLEANUP_LOCK_TIMEOUT_S"
MAX_REPAIRS = 2
RUNGS = ("B1", "debug-mantra", "recon", "ponytail", "start-task", "unstuck")
REPAIR_RUNGS = ("B1", "ponytail", "start-task")  # rungs that change files; the others are notes


class RecordError(Exception):
    """The record cannot be used: missing variable, unreadable, malformed, or lock timeout."""


def repo_slug(origin: str) -> str:
    """`<owner>-<repo>` from a GitHub URL; the last two path components otherwise."""
    s = origin.strip().rstrip("/")
    s = re.sub(r"\.git$", "", s)
    m = re.search(r"[:/]([^/:]+)/([^/]+)$", s)
    parts = (m.group(1), m.group(2)) if m else (Path(s).parent.name or "local", Path(s).name or "repo")
    return "-".join(re.sub(r"[^A-Za-z0-9_.-]", "_", p) for p in parts)


def record_path(primary: Path, origin: str, pr: int) -> Path:
    # ponytail: the coordinator is the explicit --primary, resolved once by the caller. Never Path.cwd().
    return Path(primary).resolve() / ".tick" / "merge-cleanup" / repo_slug(origin) / f"pr-{pr}.json"


def _timeout() -> float:
    try:
        return float(os.environ.get(LOCK_TIMEOUT_ENV, "5"))
    except ValueError:
        return 5.0


class RecordLock:
    """Blocking-with-timeout exclusive lock on `<record>.lock`. Timeout raises RecordError."""

    def __init__(self, record: Path, timeout_s: Optional[float] = None):
        self.record = Path(record)
        self.lock_path = self.record.with_name(self.record.name + ".lock")
        self.timeout_s = _timeout() if timeout_s is None else timeout_s
        self.fd: Optional[int] = None

    def __enter__(self) -> "RecordLock":
        self.lock_path.parent.mkdir(parents=True, exist_ok=True)
        self.fd = os.open(str(self.lock_path), os.O_RDWR | os.O_CREAT, 0o644)
        deadline = time.monotonic() + self.timeout_s
        while True:
            try:
                fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return self
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    os.close(self.fd)
                    self.fd = None
                    raise RecordError(f"lock-timeout: {self.lock_path} held by another writer for >{self.timeout_s}s — attempt STOPPED (not counted, not skipped)")
                time.sleep(0.05)

    def __exit__(self, *exc) -> None:
        if self.fd is not None:
            fcntl.flock(self.fd, fcntl.LOCK_UN)
            os.close(self.fd)
            self.fd = None


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S%z")


def new_record(pr: int, origin: str, base_sha: str = "", merge_base: str = "") -> Dict[str, Any]:
    return {"schema": 1, "pr": pr, "repo": origin, "base_sha": base_sha, "merge_base": merge_base,
            "attempts": [], "conflict_files": [], "last_side_touched": {}, "pre_repair": {}}


def load(record: Path, create: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Read the record. Missing + `create` given → that fresh record (not yet written). Else RecordError."""
    record = Path(record)
    if not record.exists():
        if create is not None:
            return create
        raise RecordError(f"record missing: {record} — a repair may not start without the coordinator's record")
    try:
        rec = json.loads(record.read_text())
    except (OSError, ValueError) as exc:
        raise RecordError(f"record unreadable/malformed: {record} ({exc})")
    if not isinstance(rec, dict) or not isinstance(rec.get("attempts"), list) or "pr" not in rec:
        raise RecordError(f"record malformed: {record} lacks pr/attempts")
    return rec


def save(record: Path, rec: Dict[str, Any]) -> None:
    record = Path(record)
    record.parent.mkdir(parents=True, exist_ok=True)
    tmp = record.with_name(record.name + ".tmp")
    tmp.write_text(json.dumps(rec, indent=1, sort_keys=True) + "\n")
    os.replace(tmp, record)


def repair_count(rec: Dict[str, Any]) -> int:
    return len(rec.get("attempts", []))


def reserve(record: Path, by: str, head_sha: str, rung: str, clone_path: str = "",
            create: Optional[Dict[str, Any]] = None, timeout_s: Optional[float] = None) -> Tuple[Optional[int], str]:
    """Reserve one repair slot under the lock. Returns (attempt index, reason) or (None, refusal)."""
    if rung not in REPAIR_RUNGS:
        raise RecordError(f"rung {rung!r} does not change files — use note(), it consumes no budget")
    with RecordLock(record, timeout_s):
        rec = load(record, create)
        n = repair_count(rec)
        if n >= MAX_REPAIRS:
            return None, (f"budget exhausted: {n} repair attempts already recorded for PR #{rec['pr']} "
                          f"(heads {', '.join(a['head_sha'][:10] for a in rec['attempts'])}) — refused; record {record}")
        rec["attempts"].append({"by": by, "head_sha": head_sha, "rung": rung, "started": _now(),
                                "outcome": "in_progress", "clone_path": clone_path})
        save(record, rec)
        return n, f"attempt {n + 1}/{MAX_REPAIRS} reserved ({by}, rung {rung}, head {head_sha[:10]})"


def finish(record: Path, index: int, outcome: str, timeout_s: Optional[float] = None, **fields: Any) -> None:
    with RecordLock(record, timeout_s):
        rec = load(record)
        rec["attempts"][index].update(outcome=outcome, finished=_now(), **fields)
        save(record, rec)


def note(record: Path, kind: str, data: Any, timeout_s: Optional[float] = None) -> None:
    """Attach diagnosis/recon to the in-progress attempt, else to `pre_repair`. Consumes no budget."""
    with RecordLock(record, timeout_s):
        rec = load(record)
        open_attempts = [a for a in rec["attempts"] if a.get("outcome") == "in_progress"]
        target = open_attempts[-1] if open_attempts else rec.setdefault("pre_repair", {})
        target.setdefault(kind, []).append({"at": _now(), "data": data})
        save(record, rec)


def set_conflicts(record: Path, files: list, create: Optional[Dict[str, Any]] = None, timeout_s: Optional[float] = None) -> None:
    with RecordLock(record, timeout_s):
        rec = load(record, create)
        rec["conflict_files"] = files
        save(record, rec)


def from_env() -> Path:
    """The caller-side entry: the record path MUST arrive via MERGE_CLEANUP_RECORD; CWD is never consulted."""
    p = os.environ.get(RECORD_ENV, "").strip()
    if not p:
        raise RecordError(f"{RECORD_ENV} is not set — a repair worker must be started with the coordinator's record path; STOPPED")
    if not os.path.isabs(p):
        raise RecordError(f"{RECORD_ENV}={p!r} is not absolute — STOPPED (a relative path would be resolved against this worker's CWD)")
    return Path(p)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="GH-534 Phase C attempt record (caller side). Reads $MERGE_CLEANUP_RECORD.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("reserve", help="reserve one repair slot (exit 0 = go, 3 = budget exhausted, 2 = stopped)")
    r.add_argument("--rung", required=True, choices=REPAIR_RUNGS)
    r.add_argument("--head", required=True, help="head SHA the repair will work on")
    r.add_argument("--clone", default="", help="path of the clone doing the repair")
    f = sub.add_parser("finish", help="record the outcome of a reserved attempt")
    f.add_argument("--index", type=int, required=True)
    f.add_argument("--outcome", required=True)
    n = sub.add_parser("note", help="attach diagnosis/recon (consumes no budget)")
    n.add_argument("--kind", required=True, choices=("diagnosis", "recon", "budget_exceeded"))
    n.add_argument("--text", required=True)
    sub.add_parser("show", help="print the record")
    a = ap.parse_args(argv)
    try:
        rec_path = from_env()
        if a.cmd == "reserve":
            idx, why = reserve(rec_path, by="caller", head_sha=a.head, rung=a.rung, clone_path=a.clone)
            print(why)
            if idx is None:
                return 3
            print(f"index={idx}")
            return 0
        if a.cmd == "finish":
            finish(rec_path, a.index, a.outcome)
            return 0
        if a.cmd == "note":
            note(rec_path, a.kind, a.text)
            return 0
        print(json.dumps(load(rec_path), indent=1, sort_keys=True))
        return 0
    except RecordError as exc:
        print(f"attempt-record: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
