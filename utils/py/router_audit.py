#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts ## Role split contains ROADMAP-DASHBOARD.md and declares ROADMAP.md frozen/legacy AND points to releases.db/releases.sql.
  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md / releases DB and forbids active ROADMAP.md reading directives.
- If in legacy mode:
  - Asserts ## Role split and ## Startup sequence exist.
  - Asserts ## Role split declares active ROADMAP.md (pointer ledger) and forbids ROADMAP-DASHBOARD.md or frozen/legacy/releases.db declarations.
  - Asserts ## Startup sequence directs to active ROADMAP.md and forbids ROADMAP-DASHBOARD.md or frozen/legacy directives.
- In --fix mode:
  - Safely splices bounded ## Role split and ## Startup sequence sections while preserving untouched document bytes and metadata.
  - Re-audits the result to guarantee the fixed state is genuinely clean before reporting success.
- Report-only by default (exit 0 if clean, exit 1 if drift or error on --check).
"""

import argparse
import os
import re
import sys


def parse_pdda_mode(root):
    """Checks .pdda-mode for anchored ROADMAP_SOURCE=releases.
    Returns (is_releases_mode: bool, error_msg: str or None)
    """
    pdda_mode_path = os.path.join(root, ".pdda-mode")
    if not os.path.exists(pdda_mode_path):
        return False, None
    try:
        with open(pdda_mode_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for line in lines:
            line_clean = line.strip()
            if not line_clean or line_clean.startswith("#"):
                continue
            m = re.match(r"^\s*ROADMAP_SOURCE\s*=\s*releases\s*(?:#.*)?$", line)
            if m:
                return True, None
        return False, None
    except Exception as e:
        return False, f"could not read .pdda-mode: {e}"


def get_repo_mode(root):
    """Returns (is_releases_mode: bool, error_msg: str or None)"""
    if os.path.exists(os.path.join(root, "releases.db")):
        return True, None
    return parse_pdda_mode(root)


def find_sections(content):
    """Finds all '## <heading>' sections and their byte/character spans in content.
    Returns list of dicts:
    {
      "heading": str,
      "heading_raw": str,
      "start": int,         # index where '## heading' starts
      "body_start": int,    # index where section body starts (after newline)
      "end": int,           # index where next section starts, or len(content)
      "body": str,          # body text
    }
    """
    matches = list(re.finditer(r"^(##\s+[^\r\n]+)", content, re.MULTILINE))
    sections = []
    n = len(content)

    for i, m in enumerate(matches):
        h_raw = m.group(1)
        h_clean = re.sub(r"^##\s+", "", h_raw).strip()
        start = m.start()
        # Find newline after header
        nl_pos = content.find("\n", start)
        body_start = nl_pos + 1 if nl_pos != -1 else len(content)
        end = matches[i + 1].start() if i + 1 < len(matches) else n
        body = content[body_start:end]
        sections.append({
            "heading": h_clean,
            "heading_raw": h_raw,
            "start": start,
            "body_start": body_start,
            "end": end,
            "body": body,
        })

    return sections


def audit_router(root):
    """Audit ROUTER.md in root. Returns a dict."""
    router_path = os.path.join(root, "ROUTER.md")
    releases_mode, mode_err = get_repo_mode(root)

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

    if mode_err:
        result["error"] = True
        result["reasons"].append(mode_err)
        return result

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

    sections = find_sections(content)
    role_section = next((s for s in sections if re.match(r"^Role\s+split\b", s["heading"], re.IGNORECASE)), None)
    startup_section = next((s for s in sections if re.match(r"^Startup\s+sequence\b", s["heading"], re.IGNORECASE)), None)

    if releases_mode:
        # Releases Mode Validation
        if role_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Role split' section")
        else:
            role_lines = role_section["body"].splitlines()
            has_dashboard = any(
                re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l)
                for l in role_lines
            )
            roadmap_lines = [
                l for l in role_lines
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l)
            ]

            if not has_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split does not declare ROADMAP-DASHBOARD.md")
            if not roadmap_lines:
                result["drift"] = True
                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
            else:
                for r_line in roadmap_lines:
                    # Must declare frozen or legacy
                    is_frozen = bool(re.search(r"\b(frozen|legacy)\b", r_line, re.IGNORECASE))
                    # Must reference releases DB/SQL as source of truth
                    has_db_ref = bool(re.search(r"\b(releases\.db|releases\.sql|ROADMAP_SOURCE=releases)\b", r_line, re.IGNORECASE))
                    # Must NOT declare active pointer ledger
                    is_active = bool(re.search(r"\b(active|the pointer ledger)\b", r_line, re.IGNORECASE) and not is_frozen)

                    if is_active or not (is_frozen and has_db_ref):
                        result["drift"] = True
                        result["reasons"].append("Role split describes ROADMAP.md as active or lacks frozen & releases DB source-of-truth declaration")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
        else:
            startup_lines = startup_section["body"].splitlines()
            has_dashboard_startup = any(
                "ROADMAP-DASHBOARD.md" in l for l in startup_lines
            )
            # Check for any directive telling the agent to read ROADMAP.md without frozen/legacy notice
            has_active_roadmap_read = False
            for l in startup_lines:
                if re.search(r"\bRead\s+`?ROADMAP\.md`?\b", l, re.IGNORECASE):
                    # If it directs to read ROADMAP.md without clarifying it's frozen legacy / do not read
                    if not re.search(r"\b(frozen|legacy|do not read)\b", l, re.IGNORECASE):
                        has_active_roadmap_read = True

            if not has_dashboard_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence does not reference ROADMAP-DASHBOARD.md")
            if has_active_roadmap_read:
                result["drift"] = True
                result["reasons"].append("Startup sequence directs agents to read ROADMAP.md without frozen/legacy notice")

        if result["drift"]:
            result["fixes_available"] = True

    else:
        # Legacy Mode Validation
        if role_section is None:
            result["drift"] = True
            result["reasons"].append("Legacy ROUTER.md missing '## Role split' section")
        else:
            role_lines = role_section["body"].splitlines()
            has_dashboard = any(
                "ROADMAP-DASHBOARD.md" in l for l in role_lines
            )
            roadmap_lines = [
                l for l in role_lines
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l)
            ]
            has_frozen = any(
                re.search(r"\b(frozen|legacy|releases\.db|releases\.sql)\b", l, re.IGNORECASE)
                for l in roadmap_lines
            )

            if has_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split references ROADMAP-DASHBOARD.md in a legacy-mode repo")
            if not roadmap_lines:
                result["drift"] = True
                result["reasons"].append("Role split missing active ROADMAP.md declaration in a legacy-mode repo")
            elif has_frozen:
                result["drift"] = True
                result["reasons"].append("Role split declares ROADMAP.md as frozen/legacy in a legacy-mode repo")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("Legacy ROUTER.md missing '## Startup sequence' section")
        else:
            startup_lines = startup_section["body"].splitlines()
            has_dashboard = any(
                "ROADMAP-DASHBOARD.md" in l for l in startup_lines
            )
            has_frozen_startup = any(
                re.search(r"\b(ROADMAP\.md.*(?:frozen|legacy)|(?:frozen|legacy).*ROADMAP\.md)\b", l, re.IGNORECASE)
                for l in startup_lines
            )
            has_active_roadmap_read = any(
                re.search(r"\bRead\s+`?ROADMAP\.md`?\b", l, re.IGNORECASE)
                for l in startup_lines
            )

            if has_dashboard:
                result["drift"] = True
                result["reasons"].append("Startup sequence references ROADMAP-DASHBOARD.md in a legacy-mode repo")
            if has_frozen_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence declares ROADMAP.md frozen in a legacy-mode repo")
            if not has_active_roadmap_read:
                result["drift"] = True
                result["reasons"].append("Startup sequence missing active ROADMAP.md read instruction in a legacy-mode repo")

        if result["drift"]:
            result["fixes_available"] = True

    return result


def fix_router(root, dry_run=False):
    """Applies targeted updates to ROUTER.md by splicing sections in-place, preserving byte integrity of custom text."""
    audit = audit_router(root)
    if not audit["exists"]:
        return False, "ROUTER.md does not exist"
    if not audit["readable"] or audit["error"]:
        return False, f"ROUTER.md cannot be audited: {'; '.join(audit['reasons'])}"
    if not audit["drift"]:
        return True, "ROUTER.md already in sync with repo mode"

    router_path = audit["router_path"]
    with open(router_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Detect line ending (CRLF vs LF)
    crlf = "\r\n" if "\r\n" in content else "\n"

    sections = find_sections(content)
    role_s = next((s for s in sections if re.match(r"^Role\s+split\b", s["heading"], re.IGNORECASE)), None)
    startup_s = next((s for s in sections if re.match(r"^Startup\s+sequence\b", s["heading"], re.IGNORECASE)), None)

    if audit["releases_mode"]:
        # Build new Role split body
        if role_s is not None:
            r_lines = role_s["body"].splitlines()
            new_r_lines = []
            dashboard_seen = False
            roadmap_seen = False

            for l in r_lines:
                if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l):
                    new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                    dashboard_seen = True
                elif re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    if not dashboard_seen:
                        new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                    new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
                    roadmap_seen = True
                else:
                    new_r_lines.append(l)

            if not dashboard_seen and not roadmap_seen:
                new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
            elif not dashboard_seen:
                new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
            elif not roadmap_seen:
                new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")

            new_role_body = crlf.join(new_r_lines)
            if role_s["body"].endswith("\n") or role_s["body"].endswith("\r\n"):
                new_role_body += crlf
        else:
            new_role_body = crlf.join([
                "",
                "- `ROUTER.md` = startup order and canonical entry points",
                "- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof",
                "- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)",
                "- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file",
                "- `CHANGELOG.md` = the end-of-iteration running log",
                "- `RELEASES.md` = forward-looking release-planning ledger (optional milestone planning aid)",
                "",
            ]) + crlf

        # Build new Startup sequence body
        if startup_s is not None:
            st_lines = startup_s["body"].splitlines()
            new_st_lines = []
            roadmap_step_seen = False

            for l in st_lines:
                m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", l)
                if m:
                    prefix = m.group(1)
                    rest = m.group(2)
                    if re.search(r"Read\s+`?ROADMAP", rest, re.IGNORECASE) or re.search(r"Read\s+`?ROADMAP-DASHBOARD", rest, re.IGNORECASE):
                        new_st_lines.append(f"{prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")
                        roadmap_step_seen = True
                        continue
                new_st_lines.append(l)

            if not roadmap_step_seen:
                new_st_lines.append("3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")

            new_startup_body = crlf.join(new_st_lines)
            if startup_s["body"].endswith("\n") or startup_s["body"].endswith("\r\n"):
                new_startup_body += crlf
        else:
            new_startup_body = crlf.join([
                "",
                "1. Read `ROUTER.md` to understand the repo's operating order and canonical files.",
                "2. Read `AGENTS.md` before making recommendations or edits.",
                "3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)",
                "4. Read the linked `PROJECT/**` document that owns the work you are touching.",
                "",
            ]) + crlf

    else:
        # Legacy mode remediation
        if role_s is not None:
            r_lines = role_s["body"].splitlines()
            new_r_lines = []
            roadmap_seen = False

            for l in r_lines:
                if re.search(r"-\s+`?ROADMAP-DASHBOARD\.md`?\s*=", l):
                    continue
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    new_r_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")
                    roadmap_seen = True
                else:
                    new_r_lines.append(l)

            if not roadmap_seen:
                new_r_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")

            new_role_body = crlf.join(new_r_lines)
            if role_s["body"].endswith("\n") or role_s["body"].endswith("\r\n"):
                new_role_body += crlf
        else:
            new_role_body = crlf.join([
                "",
                "- `ROUTER.md` = startup order and canonical entry points",
                "- `AGENTS.md` = behavioral rules, decision quality, reversibility, blast radius, proof",
                "- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work",
                "- `CHANGELOG.md` = the end-of-iteration running log",
                "",
            ]) + crlf

        if startup_s is not None:
            st_lines = startup_s["body"].splitlines()
            new_st_lines = []
            roadmap_seen = False

            for l in st_lines:
                m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", l)
                if m:
                    prefix = m.group(1)
                    rest = m.group(2)
                    if re.search(r"Read\s+`?ROADMAP", rest, re.IGNORECASE) or re.search(r"Read\s+`?ROADMAP-DASHBOARD", rest, re.IGNORECASE):
                        new_st_lines.append(f"{prefix}Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")
                        roadmap_seen = True
                        continue
                new_st_lines.append(l)

            if not roadmap_seen:
                new_st_lines.append("3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")

            new_startup_body = crlf.join(new_st_lines)
            if startup_s["body"].endswith("\n") or startup_s["body"].endswith("\r\n"):
                new_startup_body += crlf
        else:
            new_startup_body = crlf.join([
                "",
                "1. Read `ROUTER.md` to understand the repo's operating order and canonical files.",
                "2. Read `AGENTS.md` before making recommendations or edits.",
                "3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.",
                "4. Read the linked `PROJECT/**` document that owns the work you are touching.",
                "",
            ]) + crlf

    # Perform slice replacements in reverse order of appearance to keep indices stable
    splices = []  # list of (start_idx, end_idx, new_text)

    if startup_s is not None:
        splices.append((startup_s["body_start"], startup_s["end"], new_startup_body))
    if role_s is not None:
        splices.append((role_s["body_start"], role_s["end"], new_role_body))

    # Apply existing section splices from back to front
    splices.sort(key=lambda x: x[0], reverse=True)
    patched = content
    for start_idx, end_idx, new_text in splices:
        patched = patched[:start_idx] + new_text + patched[end_idx:]

    # If role_s was missing, inject it after the first section (or top)
    if role_s is None:
        re_sections = find_sections(patched)
        if re_sections:
            insert_at = re_sections[0]["start"]
            role_block = f"## Role split{crlf}{new_role_body}"
            patched = patched[:insert_at] + role_block + patched[insert_at:]
        else:
            patched = patched + f"{crlf}## Role split{crlf}{new_role_body}"

    # If startup_s was missing, inject it at the end (or after role split)
    if startup_s is None:
        startup_block = f"{crlf}## Startup sequence{crlf}{new_startup_body}"
        patched = patched + startup_block

    if dry_run:
        return True, "dry-run: planned updates to ROUTER.md"

    # Atomic write preserving permissions
    stat = os.stat(router_path)
    tmp_path = router_path + f".tmp.{os.getpid()}"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(patched)
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
        elif not audit["readable"] or audit["error"]:
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
