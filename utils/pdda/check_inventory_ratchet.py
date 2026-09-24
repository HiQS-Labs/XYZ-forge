#!/usr/bin/env python3
"""Shrink-only inventory ratchet for scripts, gateways, and clients (GH-777).

Freezes the inventory of loose scripts, direct database connections, and unvetted
subsystem callers to prevent architectural sprawl and parallel subsystem accretion.

Rules:
- Compares live tree against an exact baseline (inventory_ratchet_baseline.json).
- New additions fail: new CLI verbs must route through existing entry points or subcommands.
- Direct SQLite connects must use canonical gateways (releases_app.py, flightdeck connectors).
- Shrinks fail until baseline is updated (--update-baseline), locking in permanent reductions.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BASELINE_PATH = Path(__file__).with_name("inventory_ratchet_baseline.json")

SCRIPT_EXTS = {".sh", ".py"}
PRUNED_DIRS = {
    ".git",
    ".venv",
    ".xyz",
    "node_modules",
    "__pycache__",
    ".tick",
    "test",
    "fixtures",
    "temp",
    "TESTS-RESULTS",
    "relay-system",
    "PARKED",
}

SQLITE_CONNECT_RE = re.compile(r"sqlite3\.connect\(|sqlite3\s+[\"\']?(\$|releases\.db|harnesses\.db)")

def scan_scripts(root: Path) -> list[str]:
    scripts = []
    for dir_name in ("utils", "scripts", "bin"):
        d = root / dir_name
        if not d.exists():
            continue
        for p in d.rglob("*"):
            if p.is_file() and p.suffix in SCRIPT_EXTS:
                if any(part in PRUNED_DIRS for part in p.parts):
                    continue
                rel = str(p.relative_to(root))
                scripts.append(rel)
    return sorted(scripts)

def scan_sqlite_bypasses(root: Path) -> list[str]:
    bypasses = []
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix not in SCRIPT_EXTS:
            continue
        if any(part in PRUNED_DIRS for part in p.parts):
            continue
        rel = str(p.relative_to(root))
        try:
            for line_no, line in enumerate(p.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                if SQLITE_CONNECT_RE.search(line):
                    bypasses.append(f"{rel}:{line_no}")
        except Exception:
            continue
    return sorted(bypasses)

def main() -> int:
    parser = argparse.ArgumentParser(description="Inventory ratchet scanner.")
    parser.add_argument("--check", action="store_true", help="Exit 1 if new debt is added.")
    parser.add_argument("--update-baseline", action="store_true", help="Update baseline file to lock reductions.")
    args = parser.parse_args()

    live_scripts = scan_scripts(REPO_ROOT)
    live_bypasses = scan_sqlite_bypasses(REPO_ROOT)

    if args.update_baseline or not BASELINE_PATH.exists():
        data = {
            "total_scripts": len(live_scripts),
            "scripts": live_scripts,
            "sqlite_bypasses_count": len(live_bypasses),
            "sqlite_bypasses": live_bypasses,
        }
        BASELINE_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(f"inventory_ratchet: updated baseline ({len(live_scripts)} scripts, {len(live_bypasses)} bypasses)")
        return 0

    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    baseline_scripts = set(baseline.get("scripts", []))
    current_scripts = set(live_scripts)
    baseline_bypasses = set(baseline.get("sqlite_bypasses", []))
    current_bypasses = set(live_bypasses)

    added_scripts = current_scripts - baseline_scripts
    removed_scripts = baseline_scripts - current_scripts
    added_bypasses = current_bypasses - baseline_bypasses
    removed_bypasses = baseline_bypasses - current_bypasses

    errors = []
    if added_scripts:
        for s in sorted(added_scripts):
            errors.append(f"NEW script added ({s}) — loose scripts prohibited (GH-777).")
    if removed_scripts:
        errors.append(f"REDUCTION detected ({len(removed_scripts)} script(s) retired) — re-run with --update-baseline to lock in progress.")

    if added_bypasses:
        for b in sorted(added_bypasses):
            errors.append(f"NEW SQLite connect site added ({b}) — must use canonical gateway (GH-777).")
    if removed_bypasses:
        errors.append(f"REDUCTION detected ({len(removed_bypasses)} SQLite connect site(s) eliminated) — re-run with --update-baseline to lock in progress.")

    if errors:
        for e in errors:
            print(f"inventory_ratchet: ERROR: {e}")
        return 1 if args.check else 0

    print("inventory_ratchet: clean (matches baseline, 0 new scripts/connects)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
