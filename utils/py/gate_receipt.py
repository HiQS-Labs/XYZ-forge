#!/usr/bin/env python3
"""gate_receipt.py — On-disk deterministic local gate receipt contract (GH-124).

WHY THIS FILE EXISTS
--------------------
Auto-PR (marathon-closeout.sh --auto-pr) and in-flight QA attestation comments require machine-checkable
proof that a commit passed the qualification gate before pushing or opening a PR.

This module provides a unified interface for writing and checking deterministic JSON receipts
stored at `.xyz/receipts/<SHA>.json`, while falling back to `.gate-evidence/<SHA>.txt` when present.
"""

import argparse
import datetime
import json
import os
import sys


def get_receipt_dir(repo_root):
    return os.path.join(repo_root, ".xyz", "receipts")


def get_receipt_path(repo_root, sha):
    return os.path.join(get_receipt_dir(repo_root), f"{sha}.json")


def write_receipt(repo_root, sha, gate, mode, exit_code, passed=None, total=None, duration_s=None, scope=None):
    """Write an on-disk JSON receipt for a qualified gate run."""
    receipt_dir = get_receipt_dir(repo_root)
    os.makedirs(receipt_dir, exist_ok=True)
    
    receipt_data = {
        "sha": sha,
        "gate": gate,
        "mode": mode,
        "exit_code": int(exit_code),
        "passed": int(passed) if passed is not None else None,
        "total": int(total) if total is not None else None,
        "duration_s": float(duration_s) if duration_s is not None else None,
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "host": f"{os.uname().sysname} {os.uname().release}" if hasattr(os, "uname") else "unknown"
    }
    if scope is not None:
        receipt_data["scope"] = str(scope)
    
    target_path = get_receipt_path(repo_root, sha)
    tmp_path = f"{target_path}.tmp.{os.getpid()}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(receipt_data, f, indent=2)
        f.write("\n")
    os.replace(tmp_path, target_path)
    return receipt_data


def valid_pass_receipt(data, sha):
    """The shared on-disk/committed-bundle pass predicate."""
    return (
        isinstance(data, dict)
        and bool(sha)
        and data.get("sha") == sha
        and not isinstance(data.get("exit_code"), bool)
        and data.get("exit_code") == 0
    )


def is_full_gate_receipt(data, sha):
    """Return True when data is a passing full-gate validate.sh receipt for sha (GH-1236)."""
    return (
        valid_pass_receipt(data, sha)
        and data.get("gate") == "validate.sh"
        and data.get("mode") != "marathon"
        and data.get("scope") == "full"
    )


def check_receipt(repo_root, sha, max_age_s=None, require_full_gate=False):
    """Check whether a valid pass receipt exists on-disk for the given SHA."""
    json_path = get_receipt_path(repo_root, sha)
    if os.path.exists(json_path):
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict):
                return False, f"Corrupt receipt JSON at {json_path}: expected JSON object"
            if valid_pass_receipt(data, sha):
                if require_full_gate and not is_full_gate_receipt(data, sha):
                    return False, (
                        f"Receipt for {sha} is not a full-gate validate.sh receipt "
                        f"(gate={data.get('gate')!r}, mode={data.get('mode')!r}, scope={data.get('scope')!r})"
                    )
                if max_age_s is not None and "timestamp" in data:
                    ts = datetime.datetime.fromisoformat(data["timestamp"])
                    if ts.tzinfo is None:
                        ts = ts.replace(tzinfo=datetime.timezone.utc)
                    age = (datetime.datetime.now(datetime.timezone.utc) - ts).total_seconds()
                    if age > max_age_s:
                        return False, f"Receipt expired (age: {age:.0f}s > max: {max_age_s}s)"
                return True, data
            if data.get("sha") != sha:
                return False, f"Receipt sha is {data.get('sha')}, expected {sha}"
            return False, f"Receipt exit_code is {data.get('exit_code')}, expected 0"
        except Exception as e:
            return False, f"Corrupt receipt JSON at {json_path}: {e}"

    if require_full_gate:
        return False, f"No full-gate receipt found for {sha}"

    # Fallback to legacy .gate-evidence/<sha>.txt
    txt_path = os.path.join(repo_root, ".gate-evidence", f"{sha}.txt")
    if os.path.exists(txt_path):
        try:
            with open(txt_path, "r", encoding="utf-8") as f:
                content = f.read()
            if f"commit: {sha}" in content and "result: green" in content:
                return True, {"sha": sha, "gate": "ci-local.sh", "mode": "sequential", "exit_code": 0, "source": "gate-evidence"}
            return False, "gate-evidence file exists but result is not green"
        except Exception as e:
            return False, f"Error reading {txt_path}: {e}"

    return False, f"No gate receipt found for {sha}"


def main():
    parser = argparse.ArgumentParser(description="Manage on-disk local gate receipts.")
    subparsers = parser.add_subparsers(dest="action", required=True)

    write_p = subparsers.add_parser("write")
    write_p.add_argument("--repo", default=".")
    write_p.add_argument("--sha", required=True)
    write_p.add_argument("--gate", required=True)
    write_p.add_argument("--mode", default="sequential")
    write_p.add_argument("--scope", default=None)
    write_p.add_argument("--exit-code", type=int, required=True)
    write_p.add_argument("--passed", type=int, default=None)
    write_p.add_argument("--total", type=int, default=None)
    write_p.add_argument("--duration", type=float, default=None)

    check_p = subparsers.add_parser("check")
    check_p.add_argument("--repo", default=".")
    check_p.add_argument("--sha", required=True)
    check_p.add_argument("--max-age-s", type=int, default=None)
    check_p.add_argument("--require-full-gate", action="store_true")

    args = parser.parse_args()
    repo_root = os.path.abspath(args.repo)

    if args.action == "write":
        receipt = write_receipt(
            repo_root=repo_root,
            sha=args.sha,
            gate=args.gate,
            mode=args.mode,
            exit_code=args.exit_code,
            passed=args.passed,
            total=args.total,
            duration_s=args.duration,
            scope=args.scope,
        )
        print(f"gate-receipt: wrote {get_receipt_path(repo_root, args.sha)}")
        sys.exit(0)

    elif args.action == "check":
        ok, res = check_receipt(
            repo_root,
            args.sha,
            max_age_s=args.max_age_s,
            require_full_gate=args.require_full_gate,
        )
        if ok:
            print(f"gate-receipt: valid pass receipt for {args.sha[:8]} ({res.get('gate', 'unknown')})")
            sys.exit(0)
        else:
            print(f"gate-receipt: REFUSED — {res}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
