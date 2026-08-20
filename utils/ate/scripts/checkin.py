#!/usr/bin/env python3
"""
Universal Telemetry & Inspection CLI (GH-102).
Parses and summarizes structured JSONL telemetry across deterministic Fuzzing
(utils/fuzzing/fuzz-loop.sh) and stochastic ATE Variation runs (utils/ate/scripts/run_variations.py).

Usage:
  python3 checkin.py --log error_log.jsonl              # Human-readable summary table
  python3 checkin.py --log error_log.jsonl --tail 20    # Tail summary of last 20 records
  python3 checkin.py --log error_log.jsonl --json       # Raw JSON summary
  python3 checkin.py --compare fuzz.jsonl ate.jsonl     # Side-by-side comparative summary
  python3 checkin.py --abort "reason text"              # Write abort signal to control.json
  python3 checkin.py --continue                         # Clear control.json
"""
from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional


def load_records(log_path: Path, tail: Optional[int] = None) -> List[Dict[str, Any]]:
    if not log_path.exists():
        return []
    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    if tail and tail > 0:
        lines = lines[-tail:]
    records = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return records


def summarize_records(records: List[Dict[str, Any]]) -> Dict[str, Any]:
    if not records:
        return {
            "n_records": 0,
            "engine": "empty",
            "passed": 0,
            "failed": 0,
            "pass_rate_pct": 0.0,
            "durations": {},
            "tokens": {"total": 0, "sources": []},
            "statuses": {},
            "categories": {},
            "top_causes": [],
            "drift_detected": False,
            "suspicious_pass_count": 0,
        }

    engines = Counter(r.get("engine", "unknown") for r in records)
    primary_engine = engines.most_common(1)[0][0] if len(engines) == 1 else "mixed"

    # Status extraction (top-level or classification.status)
    statuses = Counter()
    for r in records:
        st = r.get("status") or (r.get("classification") or {}).get("status") or ("pass" if r.get("exit_code") == 0 else "fail")
        statuses[st] += 1

    passed_count = statuses.get("pass", 0)
    failed_count = sum(v for k, v in statuses.items() if k != "pass")
    pass_rate = round((passed_count / len(records)) * 100, 1)

    # Durations in ms
    durations = [float(r["duration_ms"]) for r in records if "duration_ms" in r and r["duration_ms"] is not None]
    if not durations:
        # Fallback to wall_seconds if duration_ms missing
        durations = [float(r["wall_seconds"]) * 1000 for r in records if "wall_seconds" in r and r["wall_seconds"] is not None]

    dur_stats = {}
    if durations:
        sorted_dur = sorted(durations)
        n = len(sorted_dur)
        # Nearest-rank percentile calculation
        p50 = sorted_dur[max(0, int(math.ceil(n * 0.50)) - 1)]
        p95 = sorted_dur[max(0, int(math.ceil(n * 0.95)) - 1)]
        dur_stats = {
            "min_ms": round(min(durations), 1),
            "avg_ms": round(statistics.mean(durations), 1),
            "p50_ms": round(p50, 1),
            "p95_ms": round(p95, 1),
            "max_ms": round(max(durations), 1),
        }

    # Token telemetry
    total_tokens = sum(r.get("total_tokens") or 0 for r in records if r.get("total_tokens") is not None)
    prompt_tokens = sum(r.get("prompt_tokens") or 0 for r in records if r.get("prompt_tokens") is not None)
    completion_tokens = sum(r.get("completion_tokens") or 0 for r in records if r.get("completion_tokens") is not None)
    token_sources = sorted(list(set(r.get("tokens_source", "unsupported") for r in records)))

    # Classifications / Categories
    categories = Counter()
    causes = Counter()
    for r in records:
        cls = r.get("classification") or {}
        cat = cls.get("category")
        if cat:
            categories[cat] += 1
        cause = cls.get("likely_cause")
        if cause:
            causes[cause] += 1

    # Drift signal: same failure likely_cause 3+ times in a row at the tail
    drift = False
    if len(records) >= 3:
        last_3 = records[-3:]
        failed_tail = [
            (r.get("classification") or {}).get("likely_cause")
            for r in last_3
            if (r.get("status") or (r.get("classification") or {}).get("status")) != "pass"
        ]
        drift = len(failed_tail) == 3 and len(set(failed_tail)) == 1 and failed_tail[0] is not None

    # Suspicious passes
    suspicious = [
        r for r in records
        if (r.get("status") == "pass" or (r.get("classification") or {}).get("status") == "pass")
        and (r.get("exit_code") not in (0, None) or "Traceback" in (r.get("stderr") or ""))
    ]

    return {
        "n_records": len(records),
        "engine": primary_engine,
        "passed": passed_count,
        "failed": failed_count,
        "pass_rate_pct": pass_rate,
        "durations": dur_stats,
        "tokens": {
            "prompt": prompt_tokens,
            "completion": completion_tokens,
            "total": total_tokens,
            "sources": token_sources,
        },
        "statuses": dict(statuses),
        "categories": dict(categories.most_common(5)),
        "top_causes": causes.most_common(5),
        "tool_modes": dict(Counter(r.get("tool_mode") for r in records if r.get("tool_mode"))),
        "drift_detected": drift,
        "suspicious_pass_count": len(suspicious),
    }


def format_table_summary(summary: Dict[str, Any], title: str = "Telemetry Summary") -> str:
    lines = []
    lines.append(f"==================================================")
    lines.append(f" {title} (Engine: {summary.get('engine', 'unknown')})")
    lines.append(f"==================================================")
    lines.append(f"Total Runs:    {summary.get('n_records', 0)}")
    lines.append(f"Pass Rate:     {summary.get('pass_rate_pct', 0.0)}% ({summary.get('passed', 0)} passed / {summary.get('failed', 0)} failed)")
    
    dur = summary.get("durations") or {}
    if dur:
        lines.append(f"Duration:      avg={dur.get('avg_ms')}ms | p50={dur.get('p50_ms')}ms | p95={dur.get('p95_ms')}ms | max={dur.get('max_ms')}ms")
    
    tok = summary.get("tokens") or {}
    if tok.get("total", 0) > 0:
        lines.append(f"Tokens:        total={tok.get('total')} (prompt={tok.get('prompt')}, completion={tok.get('completion')}) [{','.join(tok.get('sources', []))}]")
    else:
        lines.append(f"Tokens:        sources: {','.join(tok.get('sources', ['unsupported']))}")

    cats = summary.get("categories") or {}
    if cats:
        lines.append(f"Categories:    " + ", ".join(f"{k}: {v}" for k, v in cats.items()))

    tool_modes = summary.get("tool_modes") or {}
    if tool_modes:
        lines.append(f"Tool Modes:    " + ", ".join(f"{k}: {v}" for k, v in tool_modes.items()))

    if summary.get("drift_detected"):
        lines.append(f"⚠ DRIFT:       Repeated failure cluster detected at tail.")
    if summary.get("suspicious_pass_count", 0) > 0:
        lines.append(f"⚠ SUSPICIOUS:  {summary['suspicious_pass_count']} record(s) marked 'pass' had non-zero exit or traceback.")

    lines.append(f"==================================================")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Universal Telemetry & Inspection CLI (GH-102)")
    ap.add_argument("--log", default="error_log.jsonl", help="Path to JSONL telemetry log file")
    ap.add_argument("--tail", type=int, default=None, help="Inspect last N records only")
    ap.add_argument("--json", action="store_true", help="Output summary as raw JSON")
    ap.add_argument("--compare", nargs=2, metavar=("FILE1", "FILE2"), help="Compare two JSONL telemetry files side-by-side")
    ap.add_argument("--control", default="control.json", help="Path to control.json for ATE run control")
    ap.add_argument("--abort", metavar="REASON", help="Write an abort signal to control.json")
    ap.add_argument("--continue", dest="cont", action="store_true", help="Clear control.json / signal continue")
    args = ap.parse_args()

    control_path = Path(args.control)
    if args.abort:
        control_path.write_text(json.dumps({"action": "abort", "reason": args.abort}))
        print(f"[checkin] wrote abort to {control_path}: {args.abort}")
        return 0
    elif args.cont:
        control_path.write_text(json.dumps({"action": "continue"}))
        print(f"[checkin] wrote continue to {control_path}")
        return 0

    if args.compare:
        f1, f2 = Path(args.compare[0]), Path(args.compare[1])
        if not f1.exists():
            print(f"[checkin] error: file 1 does not exist: {f1}", file=sys.stderr)
            return 2
        if not f2.exists():
            print(f"[checkin] error: file 2 does not exist: {f2}", file=sys.stderr)
            return 2
        rec1 = load_records(f1)
        rec2 = load_records(f2)
        sum1 = summarize_records(rec1)
        sum2 = summarize_records(rec2)
        
        if args.json:
            print(json.dumps({"file1": {str(f1): sum1}, "file2": {str(f2): sum2}}, indent=2))
        else:
            print(format_table_summary(sum1, title=f"File 1: {f1.name}"))
            print("")
            print(format_table_summary(sum2, title=f"File 2: {f2.name}"))
        return 0

    log_path = Path(args.log)
    if not log_path.exists():
        print(f"[checkin] error: log file does not exist: {log_path}", file=sys.stderr)
        return 2

    records = load_records(log_path, tail=args.tail)
    summary = summarize_records(records)
    summary["log_last_modified_seconds_ago"] = round(time.time() - log_path.stat().st_mtime, 1)

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(format_table_summary(summary, title=f"Log: {log_path.name}"))

    return 0


if __name__ == "__main__":
    sys.exit(main())
