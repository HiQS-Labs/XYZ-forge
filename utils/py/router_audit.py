#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts ROUTER.md notes ROADMAP.md is frozen / legacy and points to releases.db / releases.sql.
  - Asserts ROUTER.md lists ROADMAP-DASHBOARD.md in Role split and Startup sequence.
- If in legacy mode:
  - Asserts ROUTER.md does not mistakenly declare ROADMAP.md frozen or reference non-existent ROADMAP-DASHBOARD.md.
- In --fix mode:
  - Safely updates the Role split and Startup sequence blocks in ROUTER.md to match the active mode.
- Report-only by default (exit 0 if clean, exit 1 if drift on --check).
"""

import argparse
import os
import re
import sys


def is_releases_mode(root):
    """A repo is in releases mode if releases.db exists or .pdda-mode declares ROADMAP_SOURCE=releases."""
    if os.path.exists(os.path.join(root, "releases.db")):
        return True
    pdda_mode = os.path.join(root, ".pdda-mode")
    if os.path.exists(pdda_mode):
        try:
            with open(pdda_mode, "r", encoding="utf-8", errors="replace") as f:
                if "ROADMAP_SOURCE=releases" in f.read():
                    return True
        except OSError:
            pass
    return False


def audit_router(root):
    """Audit ROUTER.md in root. Returns a dict:
    {
      "root": root,
      "router_path": path,
      "exists": bool,
      "releases_mode": bool,
      "drift": bool,
      "reasons": [str],
      "fixes_available": bool,
    }
    """
    router_path = os.path.join(root, "ROUTER.md")
    releases_mode = is_releases_mode(root)
    result = {
        "root": root,
        "router_path": router_path,
        "exists": os.path.exists(router_path),
        "releases_mode": releases_mode,
        "drift": False,
        "reasons": [],
        "fixes_available": False,
    }

    if not result["exists"]:
        return result

    try:
        with open(router_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except OSError as e:
        result["reasons"].append(f"could not read ROUTER.md: {e}")
        return result

    if releases_mode:
        # Check Role split for ROADMAP-DASHBOARD.md and frozen ROADMAP.md
        has_dashboard = "ROADMAP-DASHBOARD.md" in content
        # Check if ROADMAP.md is marked as frozen / legacy
        roadmap_lines = [
            line for line in content.splitlines()
            if re.search(r"-\s+`?ROADMAP\.md`?\s*=", line)
        ]
        has_frozen_roadmap = any(
            re.search(r"\b(frozen|legacy|releases\.db|releases\.sql)\b", line, re.IGNORECASE)
            for line in roadmap_lines
        )

        # Check startup sequence
        stale_startup = False
        for line in content.splitlines():
            # e.g., "3. Read ROADMAP.md to find..." without noting legacy or dashboard
            if re.search(r"^\s*\d+\.\s+Read\s+`?ROADMAP\.md`?", line) and not re.search(
                r"\b(frozen|legacy|ROADMAP-DASHBOARD\.md)\b", line, re.IGNORECASE
            ):
                stale_startup = True

        if not has_dashboard:
            result["drift"] = True
            result["reasons"].append("ROUTER.md does not reference ROADMAP-DASHBOARD.md in releases mode")
        if roadmap_lines and not has_frozen_roadmap:
            result["drift"] = True
            result["reasons"].append("ROUTER.md describes ROADMAP.md as active rather than frozen/legacy")
        if stale_startup:
            result["drift"] = True
            result["reasons"].append("ROUTER.md startup sequence directs agents to read ROADMAP.md without frozen/legacy notice")
        if result["drift"]:
            result["fixes_available"] = True
    else:
        # Legacy mode repo
        has_dashboard = "ROADMAP-DASHBOARD.md" in content
        if has_dashboard and not os.path.exists(os.path.join(root, "ROADMAP-DASHBOARD.md")):
            result["drift"] = True
            result["reasons"].append("ROUTER.md references ROADMAP-DASHBOARD.md but repo is in legacy mode without releases.db")
            result["fixes_available"] = True

    return result


def fix_router(root, dry_run=False):
    """Applies targeted updates to ROUTER.md for releases mode or legacy mode."""
    audit = audit_router(root)
    if not audit["exists"]:
        return False, "ROUTER.md does not exist"
    if not audit["drift"]:
        return True, "ROUTER.md already in sync with repo mode"

    router_path = audit["router_path"]
    with open(router_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    lines = content.splitlines()
    new_lines = []
    i = 0
    n = len(lines)

    if audit["releases_mode"]:
        # 1. Update or inject ROADMAP-DASHBOARD.md and frozen ROADMAP.md in Role split
        in_role_split = False
        dashboard_added = False
        roadmap_updated = False

        while i < n:
            line = lines[i]
            if re.match(r"^##\s+Role\s+split\b", line, re.IGNORECASE):
                in_role_split = True
                new_lines.append(line)
                i += 1
                continue

            if in_role_split:
                if re.match(r"^##\s+", line):
                    # Exiting role split; ensure dashboard was added if missing
                    if not dashboard_added:
                        new_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_added = True
                    in_role_split = False
                    new_lines.append(line)
                    i += 1
                    continue

                if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", line):
                    dashboard_added = True
                    new_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                    i += 1
                    continue

                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", line):
                    if not dashboard_added:
                        new_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_added = True
                    new_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
                    roadmap_updated = True
                    i += 1
                    continue

            # Check startup sequence line
            # e.g., "3. Read ROADMAP.md to find the active effort..."
            m_seq = re.match(r"^(\s*\d+\.\s+Read\s+)(`?ROADMAP\.md`?)(.*)$", line)
            if m_seq and not re.search(r"ROADMAP-DASHBOARD\.md", line):
                prefix = m_seq.group(1)
                new_lines.append(f"{prefix}`ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")
                i += 1
                continue

            new_lines.append(line)
            i += 1

        new_content = "\n".join(new_lines)
        if content.endswith("\n"):
            new_content += "\n"

        if dry_run:
            return True, "dry-run: planned updates to ROUTER.md"

        tmp_path = router_path + f".tmp.{os.getpid()}"
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        os.replace(tmp_path, router_path)
        return True, "updated ROUTER.md to reflect releases mode"
    else:
        # Legacy mode fix: revert frozen roadmap descriptions if dashboard is not present
        while i < n:
            line = lines[i]
            if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", line):
                i += 1
                continue
            if re.search(r"-\s+`?ROADMAP\.md`?\s*=\s*LEGACY", line, re.IGNORECASE):
                new_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")
                i += 1
                continue
            if re.search(r"Read\s+`?ROADMAP-DASHBOARD\.md`?", line):
                new_lines.append("3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")
                i += 1
                continue
            new_lines.append(line)
            i += 1

        new_content = "\n".join(new_lines)
        if content.endswith("\n"):
            new_content += "\n"

        if dry_run:
            return True, "dry-run: planned legacy updates to ROUTER.md"

        tmp_path = router_path + f".tmp.{os.getpid()}"
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        os.replace(tmp_path, router_path)
        return True, "updated ROUTER.md to reflect legacy roadmap mode"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Audit and remediate ROUTER.md roadmap declarations.")
    parser.add_argument("root", nargs="?", default=".", help="Target repository directory (default: current directory)")
    parser.add_argument("--check", action="store_true", help="Exit 1 if drift detected, 0 if clean")
    parser.add_argument("--fix", action="store_true", help="Remediate detected ROUTER.md drift")
    parser.add_argument("--dry-run", action="store_true", help="Report planned remediation without writing")
    parser.add_argument("--json", action="store_true", help="Output audit result as JSON")

    args = parser.parse_args(argv)
    root = os.path.abspath(args.root)

    audit = audit_router(root)

    if args.fix:
        success, msg = fix_router(root, dry_run=args.dry_run)
        if args.json:
            import json
            print(json.dumps({"success": success, "message": msg, "audit": audit_router(root)}))
        else:
            print(f"router-audit fix: {msg}")
        sys.exit(0 if success else 1)

    if args.json:
        import json
        print(json.dumps(audit))
    else:
        if not audit["exists"]:
            print(f"ROUTER.md not found in {root}")
        elif audit["drift"]:
            mode_str = "releases" if audit["releases_mode"] else "legacy"
            print(f"ROUTER DRIFT in {audit['router_path']} (mode: {mode_str}):")
            for r in audit["reasons"]:
                print(f"  • {r}")
            print(f"Remediation available: run `python3 utils/py/router_audit.py --fix {root}`")
        else:
            mode_str = "releases" if audit["releases_mode"] else "legacy"
            print(f"ok    {audit['router_path']} (in sync with {mode_str} mode)")

    if args.check and audit["drift"]:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
