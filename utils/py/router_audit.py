#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts ## Role split contains ROADMAP-DASHBOARD.md and notes ROADMAP.md is frozen / legacy / DB source of truth.
  - Asserts ## Startup sequence points to ROADMAP-DASHBOARD.md / releases DB and notes ROADMAP.md is frozen / legacy.
- If in legacy mode:
  - Asserts ## Role split does not contain ROADMAP-DASHBOARD.md or declare ROADMAP.md frozen/legacy.
  - Asserts ## Startup sequence directs agents to active ROADMAP.md and does not reference ROADMAP-DASHBOARD.md.
- In --fix mode:
  - Safely and cleanly updates bounded ## Role split and ## Startup sequence blocks to match the active mode.
  - Re-audits the result to guarantee the fixed state is clean before reporting success.
- Report-only by default (exit 0 if clean, exit 1 if drift or unreadable on --check).
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


def extract_sections(content):
    """Parses markdown content into sections bounded by ## headers."""
    lines = content.splitlines()
    sections = []  # list of dicts: {"heading": str or None, "heading_raw": str, "lines": [str], "start": int, "end": int}
    cur_heading = None
    cur_raw = None
    cur_lines = []
    cur_start = 0

    for idx, line in enumerate(lines):
        m = re.match(r"^##\s+(.+)$", line)
        if m:
            if cur_heading is not None or cur_lines:
                sections.append({
                    "heading": cur_heading,
                    "heading_raw": cur_raw,
                    "lines": cur_lines,
                    "start": cur_start,
                    "end": idx - 1,
                })
            cur_raw = line
            cur_heading = m.group(1).strip()
            cur_lines = []
            cur_start = idx
        else:
            cur_lines.append(line)

    if cur_heading is not None or cur_lines:
        sections.append({
            "heading": cur_heading,
            "heading_raw": cur_raw,
            "lines": cur_lines,
            "start": cur_start,
            "end": len(lines) - 1,
        })

    return lines, sections


def audit_router(root):
    """Audit ROUTER.md in root. Returns a dict:
    {
      "root": root,
      "router_path": path,
      "exists": bool,
      "readable": bool,
      "releases_mode": bool,
      "drift": bool,
      "error": bool,
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
        "readable": True,
        "releases_mode": releases_mode,
        "drift": False,
        "error": False,
        "reasons": [],
        "fixes_available": False,
    }

    if not result["exists"]:
        return result

    try:
        with open(router_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        result["readable"] = False
        result["error"] = True
        result["reasons"].append(f"could not read ROUTER.md: {e}")
        return result

    lines, sections = extract_sections(content)

    role_section = None
    startup_section = None

    for s in sections:
        if s["heading"] and re.match(r"^Role\s+split\b", s["heading"], re.IGNORECASE):
            role_section = s
        elif s["heading"] and re.match(r"^Startup\s+sequence\b", s["heading"], re.IGNORECASE):
            startup_section = s

    if releases_mode:
        # Releases Mode Expectations:
        # 1. Role split must exist and contain ROADMAP-DASHBOARD.md and frozen ROADMAP.md
        if role_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Role split' section")
        else:
            role_text = "\n".join(role_section["lines"])
            has_dashboard = any(
                re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l)
                for l in role_section["lines"]
            )
            roadmap_role_lines = [
                l for l in role_section["lines"]
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l)
            ]
            has_frozen_roadmap = any(
                re.search(r"\b(frozen|legacy|releases\.db|releases\.sql)\b", l, re.IGNORECASE)
                for l in roadmap_role_lines
            )

            if not has_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split does not declare ROADMAP-DASHBOARD.md")
            if not roadmap_role_lines:
                result["drift"] = True
                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
            elif not has_frozen_roadmap:
                result["drift"] = True
                result["reasons"].append("Role split describes ROADMAP.md as active rather than frozen/legacy")

        # 2. Startup sequence must exist and reference ROADMAP-DASHBOARD.md and note ROADMAP.md frozen
        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
        else:
            startup_lines = startup_section["lines"]
            has_dashboard_startup = any(
                "ROADMAP-DASHBOARD.md" in l for l in startup_lines
            )
            has_active_roadmap_startup = any(
                re.search(r"^\s*\d+\.\s+Read\s+`?ROADMAP\.md`?", l) and not re.search(r"\b(frozen|legacy|ROADMAP-DASHBOARD\.md)\b", l, re.IGNORECASE)
                for l in startup_lines
            )

            if not has_dashboard_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence does not reference ROADMAP-DASHBOARD.md")
            if has_active_roadmap_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence directs agents to read ROADMAP.md without frozen/legacy note")

        if result["drift"]:
            result["fixes_available"] = True

    else:
        # Legacy Mode Expectations:
        # 1. Role split must not contain ROADMAP-DASHBOARD.md or frozen ROADMAP.md
        if role_section is not None:
            has_dashboard = any(
                "ROADMAP-DASHBOARD.md" in l for l in role_section["lines"]
            )
            roadmap_role_lines = [
                l for l in role_section["lines"]
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l)
            ]
            has_frozen_roadmap = any(
                re.search(r"\b(frozen|legacy|releases\.db|releases\.sql)\b", l, re.IGNORECASE)
                for l in roadmap_role_lines
            )

            if has_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split references ROADMAP-DASHBOARD.md in a legacy-mode repo")
            if has_frozen_roadmap:
                result["drift"] = True
                result["reasons"].append("Role split describes ROADMAP.md as frozen/legacy in a legacy-mode repo")

        # 2. Startup sequence must not reference ROADMAP-DASHBOARD.md
        if startup_section is not None:
            has_dashboard_startup = any(
                "ROADMAP-DASHBOARD.md" in l for l in startup_section["lines"]
            )
            if has_dashboard_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence references ROADMAP-DASHBOARD.md in a legacy-mode repo")

        if result["drift"]:
            result["fixes_available"] = True

    return result


def fix_router(root, dry_run=False):
    """Applies targeted updates to ROUTER.md for releases mode or legacy mode, and verifies clean state."""
    audit = audit_router(root)
    if not audit["exists"]:
        return False, "ROUTER.md does not exist"
    if not audit["readable"]:
        return False, f"ROUTER.md is unreadable: {'; '.join(audit['reasons'])}"
    if not audit["drift"]:
        return True, "ROUTER.md already in sync with repo mode"

    router_path = audit["router_path"]
    with open(router_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    _, sections = extract_sections(content)

    role_split_idx = None
    startup_idx = None
    for idx, s in enumerate(sections):
        if s["heading"] and re.match(r"^Role\s+split\b", s["heading"], re.IGNORECASE):
            role_split_idx = idx
        elif s["heading"] and re.match(r"^Startup\s+sequence\b", s["heading"], re.IGNORECASE):
            startup_idx = idx

    if audit["releases_mode"]:
        # Build corrected Role split lines
        if role_split_idx is not None:
            s = sections[role_split_idx]
            new_role_lines = []
            dashboard_seen = False
            roadmap_seen = False

            for l in s["lines"]:
                if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l):
                    new_role_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                    dashboard_seen = True
                elif re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    if not dashboard_seen:
                        new_role_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                    new_role_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
                    roadmap_seen = True
                else:
                    new_role_lines.append(l)

            if not dashboard_seen and not roadmap_seen:
                new_role_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                new_role_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
            elif not dashboard_seen:
                new_role_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
            elif not roadmap_seen:
                new_role_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")

            s["lines"] = new_role_lines
        else:
            # Create Role split section after the first section (header)
            new_section = {
                "heading": "Role split",
                "heading_raw": "## Role split",
                "lines": [
                    "",
                    "- `ROUTER.md` = startup order and canonical entry points",
                    "- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof",
                    "- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)",
                    "- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file",
                    "- `CHANGELOG.md` = the end-of-iteration running log",
                    "- `RELEASES.md` = forward-looking release-planning ledger (optional milestone planning aid)",
                    "",
                ],
            }
            insert_pos = 1 if len(sections) > 0 else 0
            sections.insert(insert_pos, new_section)
            # Recompute startup_idx
            for idx, s in enumerate(sections):
                if s["heading"] and re.match(r"^Startup\s+sequence\b", s["heading"], re.IGNORECASE):
                    startup_idx = idx

        # Build corrected Startup sequence lines
        if startup_idx is not None:
            s = sections[startup_idx]
            new_startup_lines = []
            roadmap_step_seen = False

            for l in s["lines"]:
                m = re.match(r"^(\s*\d+\.\s+)(.*)$", l)
                if m:
                    num_prefix = m.group(1)
                    rest = m.group(2)
                    if re.search(r"Read\s+`?ROADMAP", rest, re.IGNORECASE) or re.search(r"Read\s+`?ROADMAP-DASHBOARD", rest, re.IGNORECASE):
                        new_startup_lines.append(f"{num_prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")
                        roadmap_step_seen = True
                        continue
                new_startup_lines.append(l)

            if not roadmap_step_seen:
                new_startup_lines.append("3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")

            s["lines"] = new_startup_lines
        else:
            # Create Startup sequence section
            new_section = {
                "heading": "Startup sequence",
                "heading_raw": "## Startup sequence",
                "lines": [
                    "",
                    "1. Read `ROUTER.md` to understand the repo's operating order and canonical files.",
                    "2. Read `AGENTS.md` before making recommendations or edits.",
                    "3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)",
                    "4. Read the linked `PROJECT/**` document that owns the work you are touching.",
                    "",
                ],
            }
            sections.append(new_section)

    else:
        # Legacy mode remediation
        if role_split_idx is not None:
            s = sections[role_split_idx]
            new_role_lines = []
            roadmap_seen = False
            for l in s["lines"]:
                if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l):
                    continue
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    new_role_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")
                    roadmap_seen = True
                else:
                    new_role_lines.append(l)
            if not roadmap_seen:
                new_role_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")
            s["lines"] = new_role_lines

        if startup_idx is not None:
            s = sections[startup_idx]
            new_startup_lines = []
            for l in s["lines"]:
                m = re.match(r"^(\s*\d+\.\s+)(.*)$", l)
                if m:
                    num_prefix = m.group(1)
                    rest = m.group(2)
                    if re.search(r"Read\s+`?ROADMAP-DASHBOARD\.md`?", rest, re.IGNORECASE) or (re.search(r"Read\s+`?ROADMAP\.md`?", rest, re.IGNORECASE) and re.search(r"frozen|legacy", rest, re.IGNORECASE)):
                        new_startup_lines.append(f"{num_prefix}Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")
                        continue
                new_startup_lines.append(l)
            s["lines"] = new_startup_lines

    # Reconstruct document
    out_lines = []
    for s in sections:
        if s.get("heading_raw"):
            out_lines.append(s["heading_raw"])
        for l in s["lines"]:
            out_lines.append(l)

    new_content = "\n".join(out_lines)
    if content.endswith("\n"):
        new_content += "\n"

    if dry_run:
        return True, "dry-run: planned updates to ROUTER.md"

    # Atomic write preserving permissions
    stat = os.stat(router_path)
    tmp_path = router_path + f".tmp.{os.getpid()}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    os.chmod(tmp_path, stat.st_mode)
    os.replace(tmp_path, router_path)

    # Re-verify that post-fix audit is clean
    post_audit = audit_router(root)
    if post_audit["drift"] or post_audit["error"]:
        return False, f"post-fix verification failed: {'; '.join(post_audit['reasons'])}"

    return True, "updated ROUTER.md to reflect repository roadmap mode"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Audit and remediate ROUTER.md roadmap declarations.")
    parser.add_argument("root", nargs="?", default=".", help="Target repository directory (default: current directory)")
    parser.add_argument("--check", action="store_true", help="Exit 1 if drift or error detected, 0 if clean")
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
        elif not audit["readable"]:
            print(f"ERROR reading ROUTER.md in {root}:")
            for r in audit["reasons"]:
                print(f"  • {r}")
        elif audit["drift"]:
            mode_str = "releases" if audit["releases_mode"] else "legacy"
            print(f"ROUTER DRIFT in {audit['router_path']} (mode: {mode_str}):")
            for r in audit["reasons"]:
                print(f"  • {r}")
            print(f"Remediation available: run `python3 utils/py/router_audit.py --fix {root}`")
        else:
            mode_str = "releases" if audit["releases_mode"] else "legacy"
            print(f"ok    {audit['router_path']} (in sync with {mode_str} mode)")

    if args.check and (audit["drift"] or audit["error"]):
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
