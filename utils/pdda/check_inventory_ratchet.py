#!/usr/bin/env python3
"""Shrink-only inventory ratchet for scripts, gateways, and clients (GH-777).

Freezes the inventory of loose scripts, direct database connections, and unvetted
subsystem callers to prevent architectural sprawl and parallel subsystem accretion.

Rules:
- Compares live tree against an exact baseline (inventory_ratchet_baseline.json).
- New additions fail: new CLI verbs must route through existing entry points or subcommands.
- Direct SQLite connects must use canonical gateways (releases_app.py, flightdeck connectors).
- Shrinks fail until baseline is updated (--update-baseline), locking in permanent reductions.
- Updates cannot approve growth: --update-baseline fails if debt grew.
"""
from __future__ import annotations

import argparse
import json
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

# Regex to find direct sqlite connections
SQLITE_CONNECT_RE = re.compile(r"sqlite3\.connect\s*\(|sqlite3\s+[\"\']?(\$|releases\.db|harnesses\.db)")

# Canonical gateway files exempted from bypass debt
CANONICAL_GATEWAYS = {
    "utils/py/releases_app.py",
}


def scan_scripts(root: Path) -> list[str]:
    scripts = []
    for dir_name in ("utils", "scripts", "bin"):
        d = root / dir_name
        if not d.exists():
            continue
        for p in d.rglob("*"):
            if p.is_file() and p.suffix in SCRIPT_EXTS:
                rel = p.relative_to(root)
                if any(part in PRUNED_DIRS for part in rel.parts):
                    continue
                scripts.append(str(rel))
    return sorted(scripts)


def scan_sqlite_bypasses(root: Path) -> list[str]:
    """Scan for direct SQLite connects outside canonical gateways."""
    bypasses = []
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix not in SCRIPT_EXTS:
            continue
        rel = p.relative_to(root)
        if any(part in PRUNED_DIRS for part in rel.parts):
            continue
        rel_str = str(rel)
        if rel_str in CANONICAL_GATEWAYS:
            continue
        try:
            for line_no, line in enumerate(p.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                if "SQLITE-GATEWAY-OK:" in line or "SQLITE-BYPASS-OK:" in line:
                    continue
                if SQLITE_CONNECT_RE.search(line):
                    bypasses.append(f"{rel_str}:{line_no}")
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

    if not BASELINE_PATH.exists():
        if args.check:
            print("inventory_ratchet: ERROR: Baseline file missing — cannot run in --check mode.", file=sys.stderr)
            return 1
        data = {
            "total_scripts": len(live_scripts),
            "scripts": live_scripts,
            "sqlite_bypasses_count": len(live_bypasses),
            "sqlite_bypasses": live_bypasses,
        }
        BASELINE_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(f"inventory_ratchet: initialized baseline ({len(live_scripts)} scripts, {len(live_bypasses)} bypasses)")
        return 0

    baseline = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    baseline_scripts = set(baseline.get("scripts", []))
    current_scripts = set(live_scripts)

    # For bypasses, compare normalized file-level occurrences or set
    baseline_bypasses = set(baseline.get("sqlite_bypasses", []))
    current_bypasses = set(live_bypasses)

    # Allow line shifts in the same file if occurrence count didn't grow
    baseline_files = {b.split(":")[0] for b in baseline_bypasses}
    current_files = {b.split(":")[0] for b in current_bypasses}

    added_scripts = current_scripts - baseline_scripts
    removed_scripts = baseline_scripts - current_scripts
    added_files = current_files - baseline_files
    removed_files = baseline_files - current_files

    if args.update_baseline:
        if added_scripts or added_files or len(current_bypasses) > len(baseline_bypasses):
            print(
                f"inventory_ratchet: ERROR: Cannot update baseline when debt has grown ({len(added_scripts)} scripts added, {len(added_files)} bypass files added).",
                file=sys.stderr,
            )
            return 1
        data = {
            "total_scripts": len(live_scripts),
            "scripts": live_scripts,
            "sqlite_bypasses_count": len(live_bypasses),
            "sqlite_bypasses": live_bypasses,
        }
        BASELINE_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(f"inventory_ratchet: updated baseline ({len(live_scripts)} scripts, {len(live_bypasses)} bypasses)")
        return 0

    errors = []
    if added_scripts:
        for s in sorted(added_scripts):
            errors.append(f"NEW script added ({s}) — loose scripts prohibited (GH-777).")
    if removed_scripts:
        errors.append(f"REDUCTION detected ({len(removed_scripts)} script(s) retired) — re-run with --update-baseline to lock in progress.")

    if added_files:
        for f in sorted(added_files):
            errors.append(f"NEW SQLite connect file added ({f}) — must use canonical gateway (GH-777).")
    elif len(current_bypasses) > len(baseline_bypasses):
        errors.append(f"NEW SQLite connect site(s) added — count grew from {len(baseline_bypasses)} to {len(current_bypasses)} (GH-777).")

    if len(current_bypasses) < len(baseline_bypasses) or removed_files:
        errors.append("REDUCTION detected (SQLite connect site(s) eliminated) — re-run with --update-baseline to lock in progress.")

    if errors:
        for e in errors:
            print(f"inventory_ratchet: ERROR: {e}")
        return 1 if args.check else 0

    print("inventory_ratchet: clean (matches baseline, 0 new scripts/connects)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
