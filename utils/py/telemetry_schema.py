#!/usr/bin/env python3
"""telemetry_schema.py — GH-299 Gen 4 shared telemetry contract.

One dataclass, `TelemetryEvent`, is the interchange record between every Gen 4 pillar:
domain oracles (Phase 1), the adaptive pairwise ATE (Phase 2), the mutational fuzz engine
(Phase 3), the clustered reproducer synthesizer (Phase 4) and the campaign runner (Phase 5).
Every pillar writes it as one JSON object per line (JSONL) and reads it back with
`read_jsonl`, so no pillar needs to know another pillar's internals.

Also home to the three normalizers the contract depends on, so they are defined once:

  normalize_stderr(text)      strip paths, pids, timestamps, hex ids -> stable text
  stderr_digest(text)         sha256(normalize_stderr(text))[:16]
  duration_bucket(ms)         coarse latency class used by the feedback vector

Plain stdlib; importable from any pillar via `sys.path.insert(0, <utils/py>)`.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import time
import uuid
from dataclasses import asdict, dataclass, field, fields
from typing import Any, Dict, Iterator, List, Optional

SCHEMA_VERSION = "1.0"
PHASES = ("oracle", "pairwise", "fuzz", "repro", "campaign")
VERDICTS = ("pass", "fail", "anomaly")

# Buckets are closed on the left and named so a human can read the corpus.
DURATION_BUCKETS = (
    (100.0, "fast_<100ms"),
    (1000.0, "fast_<1s"),
    (5000.0, "medium_<5s"),
    (30000.0, "slow_<30s"),
    (float("inf"), "slow_>=30s"),
)

_NORMALIZERS = (
    (re.compile(r"/(?:private/)?(?:tmp|var/folders)/[^\s'\"]+"), "<TMP>"),
    (re.compile(r"/Users/[^/\s'\"]+"), "/Users/<USER>"),
    (re.compile(r"/home/[^/\s'\"]+"), "/home/<USER>"),
    (re.compile(r"\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?\b"), "<TS>"),
    (re.compile(r"\bpid[= ]\d+\b", re.IGNORECASE), "pid=<PID>"),
    (re.compile(r"\b[0-9a-f]{12,64}\b"), "<HEX>"),
    (re.compile(r"\b0x[0-9a-fA-F]+\b"), "<ADDR>"),
    (re.compile(r"line \d+", re.IGNORECASE), "line <N>"),
    (re.compile(r"[ \t]+"), " "),
)


def normalize_stderr(text: str) -> str:
    """Collapse machine-specific noise so the same root cause hashes the same everywhere."""
    out = text or ""
    for pattern, repl in _NORMALIZERS:
        out = pattern.sub(repl, out)
    lines = [ln.strip() for ln in out.splitlines()]
    return "\n".join(ln for ln in lines if ln).strip()


def stderr_digest(text: str) -> str:
    """Stable 16-hex cluster key for a stderr blob."""
    return hashlib.sha256(normalize_stderr(text).encode("utf-8", "replace")).hexdigest()[:16]


def input_hash(argv: List[str], env: Optional[Dict[str, str]] = None) -> str:
    """sha256 of the command under test, including the env overrides that shaped it."""
    payload = json.dumps({"argv": list(argv), "env": dict(sorted((env or {}).items()))}, sort_keys=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def duration_bucket(duration_ms: float) -> str:
    for ceiling, label in DURATION_BUCKETS:
        if duration_ms < ceiling:
            return label
    return DURATION_BUCKETS[-1][1]


def new_run_id() -> str:
    return str(uuid.uuid4())


@dataclass
class TelemetryEvent:
    schema_version: str = SCHEMA_VERSION
    phase: str = "oracle"            # one of PHASES
    run_id: str = ""                 # UUID of the enclosing run
    input_hash: str = ""             # sha256 of command/flags under test
    exit_code: int = 0
    signal: int = 0                  # >0 when the process died by signal
    stderr_digest: str = ""          # sha256(stderr_normalized)[:16]
    duration_ms: float = 0.0
    oracle_results: Dict[str, bool] = field(default_factory=dict)   # oracle_name -> passed
    tier_1_verdict: Optional[str] = None                             # "pass" | "fail" | "anomaly"
    # Optional, non-contract extras that pillars may attach (argv, stderr sample, corpus id...).
    # Kept in one bag so adding a field never breaks an older reader.
    extra: Dict[str, Any] = field(default_factory=dict)

    # ---- derived helpers -------------------------------------------------------------
    @property
    def duration_bucket(self) -> str:
        return duration_bucket(self.duration_ms)

    @property
    def feedback_vector(self) -> tuple:
        """The Pillar-1 feedback tuple <exit_code, signal, stderr_digest, duration_bucket>."""
        return (self.exit_code, self.signal, self.stderr_digest, self.duration_bucket)

    @property
    def all_oracles_passed(self) -> bool:
        return all(self.oracle_results.values()) if self.oracle_results else True

    # ---- (de)serialisation -----------------------------------------------------------
    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        d["duration_bucket"] = self.duration_bucket
        return d

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), sort_keys=True, separators=(",", ":"))

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TelemetryEvent":
        known = {f.name for f in fields(cls)}
        kwargs = {k: v for k, v in data.items() if k in known}
        # Tolerate the legacy Phase-3.5 shape ({"cmd": ..., "stderr": ...}) by folding it into extra.
        extra = dict(kwargs.get("extra") or {})
        for k, v in data.items():
            if k not in known and k != "duration_bucket":
                extra[k] = v
        kwargs["extra"] = extra
        ev = cls(**kwargs)
        ev.validate()
        return ev

    def validate(self) -> None:
        if self.schema_version != SCHEMA_VERSION:
            raise ValueError(f"telemetry schema_version {self.schema_version!r} != {SCHEMA_VERSION!r}")
        if self.phase not in PHASES:
            raise ValueError(f"telemetry phase {self.phase!r} not in {PHASES}")
        if self.tier_1_verdict is not None and self.tier_1_verdict not in VERDICTS:
            raise ValueError(f"tier_1_verdict {self.tier_1_verdict!r} not in {VERDICTS}")
        if not isinstance(self.exit_code, int) or not isinstance(self.signal, int):
            raise ValueError("exit_code and signal must be integers")
        if self.duration_ms < 0:
            raise ValueError("duration_ms must be >= 0")


def event_from_completed(
    phase: str,
    argv: List[str],
    exit_code: int,
    stderr: str,
    duration_ms: float,
    run_id: str = "",
    env: Optional[Dict[str, str]] = None,
    **extra: Any,
) -> TelemetryEvent:
    """Build an event from a finished subprocess. Negative returncodes are POSIX signals.

    The argv is always recorded in `extra["argv"]` so a reader can replay the case.
    """
    signal_no = -exit_code if exit_code < 0 else 0
    extra = {"argv": list(argv), **extra}
    return TelemetryEvent(
        phase=phase,
        run_id=run_id or new_run_id(),
        input_hash=input_hash(argv, env),
        exit_code=exit_code if exit_code >= 0 else 128 + signal_no,
        signal=signal_no,
        stderr_digest=stderr_digest(stderr),
        duration_ms=float(duration_ms),
        extra=dict(extra),
    )


# ---- JSONL I/O ------------------------------------------------------------------------
def append_jsonl(path: str, event: TelemetryEvent) -> None:
    os.makedirs(os.path.dirname(os.path.abspath(path)) or ".", exist_ok=True)
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(event.to_json() + "\n")


def read_jsonl(path: str) -> Iterator[TelemetryEvent]:
    with open(path, "r", encoding="utf-8") as fh:
        for lineno, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                yield TelemetryEvent.from_dict(json.loads(line))
            except (ValueError, TypeError) as exc:
                raise ValueError(f"{path}:{lineno}: invalid telemetry line: {exc}") from exc


def validate_jsonl(path: str) -> Dict[str, Any]:
    """Line-level validity check: every non-empty line is one complete JSON object.

    Used by the crash-recovery oracle: a SIGKILL mid-write must never leave a torn line.
    """
    good = bad = 0
    errors: List[str] = []
    if not os.path.exists(path):
        return {"ok": True, "lines": 0, "bad": 0, "errors": ["missing (treated as empty)"]}
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for lineno, raw in enumerate(fh, 1):
            if not raw.strip():
                continue
            if not raw.endswith("\n"):
                bad += 1
                errors.append(f"line {lineno}: unterminated (torn write)")
                continue
            try:
                obj = json.loads(raw)
                if not isinstance(obj, dict):
                    raise ValueError("not an object")
                good += 1
            except ValueError as exc:
                bad += 1
                errors.append(f"line {lineno}: {exc}")
    return {"ok": bad == 0, "lines": good + bad, "bad": bad, "errors": errors}


# ---- self-test -------------------------------------------------------------------------
def _suite() -> int:
    failures: List[str] = []

    def check(cond: bool, msg: str) -> None:
        if not cond:
            failures.append(msg)

    a = stderr_digest("error at /private/tmp/abc123/x.py line 42 pid=9981 2026-09-04T10:11:12Z")
    b = stderr_digest("error at /tmp/zzz999/x.py   line 7 pid=1 2026-01-01 00:00:00")
    check(a == b, "normalizer must erase paths/pids/timestamps/line numbers")
    check(stderr_digest("boom") != stderr_digest("bang"), "distinct errors must not collide")
    check(duration_bucket(3) == "fast_<100ms" and duration_bucket(999) == "fast_<1s", "bucket edges")
    check(duration_bucket(30000) == "slow_>=30s", "top bucket")

    ev = event_from_completed("fuzz", ["x", "--y"], -9, "killed", 12.5, sample="killed")
    check(ev.signal == 9 and ev.exit_code == 137, "negative rc maps to signal + 128")
    check(ev.feedback_vector == (137, 9, stderr_digest("killed"), "fast_<100ms"), "feedback vector")
    rt = TelemetryEvent.from_dict(json.loads(ev.to_json()))
    check(rt == ev, "json round trip must be lossless")

    try:
        TelemetryEvent(phase="bogus").validate()
        check(False, "invalid phase must be rejected")
    except ValueError:
        pass
    try:
        TelemetryEvent(tier_1_verdict="maybe").validate()
        check(False, "invalid verdict must be rejected")
    except ValueError:
        pass

    import tempfile
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, "t.jsonl")
        append_jsonl(p, ev)
        append_jsonl(p, TelemetryEvent(phase="oracle", oracle_results={"zero_state": True}))
        check(len(list(read_jsonl(p))) == 2, "jsonl read back count")
        check(validate_jsonl(p)["ok"], "clean jsonl validates")
        with open(p, "a") as fh:
            fh.write('{"schema_version": "1.0", "phase": "or')  # torn write, no newline
        v = validate_jsonl(p)
        check(not v["ok"] and v["bad"] == 1, "torn line must be flagged")

    legacy = TelemetryEvent.from_dict({"schema_version": "1.0", "cmd": "x --bad", "exit_code": 2, "stderr": "err"})
    check(legacy.extra.get("cmd") == "x --bad" and legacy.extra.get("stderr") == "err", "legacy shape folds into extra")

    for f in failures:
        print(f"  FAIL: {f}")
    print(f"SUITE_RESULT={'PASS' if not failures else 'FAIL'} ({len(failures)} failures)")
    return 0 if not failures else 1


def main() -> int:
    import argparse

    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--mode", choices=["suite", "validate", "digest"], default="suite")
    p.add_argument("--path", help="JSONL path for --mode validate")
    p.add_argument("--text", help="stderr text for --mode digest (or stdin)")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    if a.mode == "suite":
        return _suite()
    if a.mode == "validate":
        if not a.path:
            print("--path required", file=sys.stderr)
            return 2
        res = validate_jsonl(a.path)
        print(json.dumps(res) if a.json else f"{'OK' if res['ok'] else 'BAD'} lines={res['lines']} bad={res['bad']}")
        return 0 if res["ok"] else 1
    text = a.text if a.text is not None else sys.stdin.read()
    print(stderr_digest(text))
    return 0


if __name__ == "__main__":
    sys.exit(main())
