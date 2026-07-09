#!/usr/bin/env python3
"""
Frontier-model (Claude) check-in script. Run this every ~5 minutes while
run_variations.py is running in the background.

Usage:
  python3 checkin.py --tail 20                  # just print a summary
  python3 checkin.py --abort "reason text"       # summary + write abort to control.json
  python3 checkin.py --continue                  # explicitly clear any prior abort
"""
import argparse
import json
import time
from collections import Counter
from pathlib import Path


def load_tail(log_path: Path, n: int) -> list[dict]:
    if not log_path.exists():
        return []
    lines = log_path.read_text().splitlines()[-n:]
    records = []
    for line in lines:
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return records


def summarize(records: list[dict]) -> dict:
    statuses = Counter((r.get("classification") or {}).get("status") for r in records)
    severities = Counter((r.get("classification") or {}).get("severity") for r in records)
    causes = Counter((r.get("classification") or {}).get("likely_cause") for r in records)

    # drift signal: same likely_cause 3+ times in a row at the tail
    drift = False
    if len(records) >= 3:
        last_causes = [(r.get("classification") or {}).get("likely_cause") for r in records[-3:]]
        drift = len(set(last_causes)) == 1 and last_causes[0] is not None

    # suspicious pass: marked pass but nonzero exit code or traceback-like stderr
    suspicious = [
        r for r in records
        if (r.get("classification") or {}).get("status") == "pass"
        and (r.get("exit_code") not in (0, None) or "Traceback" in (r.get("stderr") or ""))
    ]

    return {
        "n_records": len(records),
        "statuses": dict(statuses),
        "severities": dict(severities),
        "top_causes": causes.most_common(5),
        "drift_detected": drift,
        "suspicious_pass_count": len(suspicious),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", default="error_log.jsonl")
    ap.add_argument("--control", default="control.json")
    ap.add_argument("--tail", type=int, default=20, help="how many recent records to summarize")
    ap.add_argument("--abort", metavar="REASON", help="write an abort signal to control.json")
    ap.add_argument("--continue", dest="cont", action="store_true",
                     help="clear control.json / explicitly signal continue")
    args = ap.parse_args()

    log_path = Path(args.log)
    control_path = Path(args.control)

    records = load_tail(log_path, args.tail)
    summary = summarize(records)
    # checkin.py holds no state across invocations, so it can't detect "no new
    # lines for N cycles" on its own — this timestamp lets the supervisor (you)
    # compare against what it saw last check-in to spot a hung worker.
    summary["log_last_modified_seconds_ago"] = (
        round(time.time() - log_path.stat().st_mtime, 1) if log_path.exists() else None
    )

    print(json.dumps(summary, indent=2))

    if summary["drift_detected"]:
        print("\n⚠ DRIFT: last 3 records share the same likely_cause — "
              "worker may be stuck. Consider --abort.")
    if summary["suspicious_pass_count"] > 0:
        print(f"\n⚠ {summary['suspicious_pass_count']} record(s) marked 'pass' but show "
              "a nonzero exit code or traceback — classification may be unreliable.")

    if args.abort:
        control_path.write_text(json.dumps({"action": "abort", "reason": args.abort}))
        print(f"\n[checkin] wrote abort to {control_path}: {args.abort}")
    elif args.cont:
        control_path.write_text(json.dumps({"action": "continue"}))
        print(f"\n[checkin] wrote continue to {control_path}")


if __name__ == "__main__":
    main()
