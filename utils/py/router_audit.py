#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts ## Role split contains ROADMAP-DASHBOARD.md, declares ROADMAP.md frozen/legacy AND points to releases.db/releases.sql, and forbids active/current/pointer-ledger claims.
  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md / releases DB and forbids active/current ROADMAP.md directives (even if 'frozen' is mentioned with negation like 'not frozen').
- If in legacy mode:
  - Asserts ## Role split and ## Startup sequence exist.
  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger (forbidding 'not active', 'obsolete', 'frozen', 'legacy', or releases tokens).
  - Asserts ## Startup sequence directs to active ROADMAP.md (forbidding 'do not read', 'frozen', 'legacy', or releases tokens).
  - Forbids all releases-source tokens (ROADMAP-DASHBOARD.md, releases.db, releases.sql, ROADMAP_SOURCE=releases) in both sections.
- In --fix mode:
  - Safely splices bounded ## Role split and ## Startup sequence sections while preserving untouched document bytes (including CRLF/LF line endings) and metadata.
  - Collapses multiple duplicate roadmap directives in Startup to exactly one canonical step.
  - Validates candidate file BEFORE replacing live target; rolls back on failure so original is never corrupted.
  - Uses safe atomic temporary files with fsync, chmod, and cleanup.
- Report-only by default (exit 0 if clean, exit 1 if drift, missing, or error on --check).
"""

import argparse
import os
import re
import sys
import tempfile


RELEASES_TOKENS = r"\b(ROADMAP-DASHBOARD\.md|releases\.db|releases\.sql|ROADMAP_SOURCE=releases|ROADMAP_SOURCE\s*=\s*releases)\b"


def parse_pdda_mode(root):
    """Checks .pdda-mode for anchored ROADMAP_SOURCE=releases.
    Returns (is_releases_mode: bool, error_msg: str or None)
    """
    pdda_mode_path = os.path.join(root, ".pdda-mode")
    if not os.path.exists(pdda_mode_path):
        return False, None
    try:
        with open(pdda_mode_path, "r", newline="", encoding="utf-8") as f:
            lines = f.readlines()
        for line in lines:
            line_clean = line.strip()
            if not line_clean or line_clean.startswith("#"):
                continue
            m = re.match(r"^\s*ROADMAP_SOURCE\s*=\s*releases\s*(?:#.*)?$", line_clean)
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
    """Finds all '## <heading>' sections and their byte/character spans in content."""
    matches = list(re.finditer(r"^(##\s+[^\r\n]+)", content, re.MULTILINE))
    sections = []
    n = len(content)

    for i, m in enumerate(matches):
        h_raw = m.group(1)
        h_clean = re.sub(r"^##\s+", "", h_raw).strip()
        start = m.start()
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


def is_active_roadmap_startup_directive(line):
    """Returns True if a Startup sequence line directs the reader to use ROADMAP.md for active work."""
    # Look for ROADMAP.md (raw or backticked or in markdown link)
    if not re.search(r"(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))", line, re.IGNORECASE):
        return False

    # Check for negated frozen phrases like "not frozen", "isn't frozen", "is not frozen"
    if re.search(r"\b(?:not|isn't|never)\s+frozen\b", line, re.IGNORECASE):
        return True

    # If the line explicitly instructs that ROADMAP.md is frozen legacy / do not read / legacy file
    if re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy)(?:\s+(?:file|ledger))?|do\s+not\s+read|never\s+edit|frozen\s+since|frozen\s+legacy)\b", line, re.IGNORECASE):
        return False
    if re.search(r"\b(?:do\s+not\s+read|never\s+read|obsolete|historical)\s+`?ROADMAP\.md`?", line, re.IGNORECASE):
        return False

    # If it has action verbs or directives to use/read/consult/open
    if re.search(r"\b(read|open|consult|see|check|inspect|use|follow)\b", line, re.IGNORECASE):
        return True
    if re.search(r"\b(current\s+work|active\s+effort|active\s+tasks|current\s+tasks)\b", line, re.IGNORECASE):
        return True

    return False


def is_legacy_active_role_line(line):
    """Returns True if a Role split line affirmatively declares ROADMAP.md as the active pointer ledger."""
    if not re.search(r"-\s+`?ROADMAP\.md`?\s*=", line):
        return False
    # Forbid negative / obsolete / releases tokens
    if re.search(r"\b(not\s+active|obsolete|frozen|legacy|historical|releases\.db|releases\.sql|ROADMAP_SOURCE)\b", line, re.IGNORECASE):
        return False
    # Require affirmative pointer ledger or current/active work declaration
    if re.search(r"\b(?:the\s+pointer\s+ledger|pointer\s+ledger\s+of\s+current|active\s+pointer|ledger\s+of\s+current)\b", line, re.IGNORECASE):
        return True
    return False


def audit_router(root, content_override=None):
    """Audit ROUTER.md in root (or content_override if provided). Returns a dict."""
    router_path = os.path.join(root, "ROUTER.md")
    releases_mode, mode_err = get_repo_mode(root)

    result = {
        "root": root,
        "router_path": router_path,
        "exists": os.path.exists(router_path) if content_override is None else True,
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
        result["error"] = True
        result["reasons"].append("ROUTER.md does not exist")
        return result

    if content_override is not None:
        content = content_override
    else:
        try:
            with open(router_path, "r", newline="", encoding="utf-8") as f:
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
                    is_frozen = bool(re.search(r"\b(frozen|legacy)\b", r_line, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+frozen\b", r_line, re.IGNORECASE))
                    has_db_ref = bool(re.search(r"\b(releases\.db|releases\.sql|ROADMAP_SOURCE=releases)\b", r_line, re.IGNORECASE))
                    has_contradictory_active = bool(re.search(r"\b(active\s+pointer|the\s+pointer\s+ledger\s+of\s+current|active\s+effort|current\s+work\s+ledger|current\s+work)\b", r_line, re.IGNORECASE))

                    if has_contradictory_active or not (is_frozen and has_db_ref):
                        result["drift"] = True
                        result["reasons"].append("Role split describes ROADMAP.md with contradictory active terms or lacks explicit frozen/legacy + releases DB source-of-truth declaration")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
        else:
            startup_lines = startup_section["body"].splitlines()
            has_dashboard_startup = any(
                "ROADMAP-DASHBOARD.md" in l for l in startup_lines
            )
            has_active_roadmap_read = any(
                is_active_roadmap_startup_directive(l)
                for l in startup_lines
            )

            if not has_dashboard_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence does not reference ROADMAP-DASHBOARD.md")
            if has_active_roadmap_read:
                result["drift"] = True
                result["reasons"].append("Startup sequence contains active ROADMAP.md directive without frozen/legacy note")

        if result["drift"]:
            result["fixes_available"] = True

    else:
        # Legacy Mode Validation
        if role_section is None:
            result["drift"] = True
            result["reasons"].append("Legacy ROUTER.md missing '## Role split' section")
        else:
            role_lines = role_section["body"].splitlines()
            has_rel_tokens = any(
                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in role_lines
            )
            has_positive_active_role = any(
                is_legacy_active_role_line(l) for l in role_lines
            )

            if has_rel_tokens:
                result["drift"] = True
                result["reasons"].append("Role split references releases-mode tokens (ROADMAP-DASHBOARD.md/releases.db) in a legacy-mode repo")
            if not has_positive_active_role:
                result["drift"] = True
                result["reasons"].append("Role split missing affirmative active ROADMAP.md pointer ledger declaration in a legacy-mode repo")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("Legacy ROUTER.md missing '## Startup sequence' section")
        else:
            startup_lines = startup_section["body"].splitlines()
            has_rel_tokens_startup = any(
                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in startup_lines
            )
            has_frozen_startup = any(
                re.search(r"\b(ROADMAP\.md.*(?:frozen|legacy)|(?:frozen|legacy).*ROADMAP\.md)\b", l, re.IGNORECASE)
                for l in startup_lines
            )
            has_valid_active_read = False
            for l in startup_lines:
                if re.search(r"\b(Read|Consult|Open|Check|Use)\s+(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))\b", l, re.IGNORECASE):
                    if not re.search(r"\b(do\s+not|never|frozen|legacy|obsolete|not\s+to\s+be)\b", l, re.IGNORECASE):
                        has_valid_active_read = True

            if has_rel_tokens_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence references releases-mode tokens in a legacy-mode repo")
            if has_frozen_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence declares ROADMAP.md frozen in a legacy-mode repo")
            if not has_valid_active_read:
                result["drift"] = True
                result["reasons"].append("Startup sequence missing non-negated active ROADMAP.md directive in a legacy-mode repo")

        if result["drift"]:
            result["fixes_available"] = True

    return result


def fix_router(root, dry_run=False):
    """Applies targeted updates to ROUTER.md by splicing sections in-place, preserving byte integrity of custom text and line endings."""
    audit = audit_router(root)
    if not audit["exists"]:
        return False, "ROUTER.md does not exist"
    if not audit["readable"] or audit["error"]:
        return False, f"ROUTER.md cannot be audited: {'; '.join(audit['reasons'])}"
    if not audit["drift"]:
        return True, "ROUTER.md already in sync with repo mode"

    router_path = audit["router_path"]
    with open(router_path, "r", newline="", encoding="utf-8") as f:
        content = f.read()

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
                    if not dashboard_seen:
                        new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                elif re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    if not dashboard_seen:
                        new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                    if not roadmap_seen:
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

        # Build new Startup sequence body (collapsing multiple roadmap directives to exactly ONE)
        if startup_s is not None:
            st_lines = startup_s["body"].splitlines()
            new_st_lines = []
            dashboard_step_seen = False

            for l in st_lines:
                if is_active_roadmap_startup_directive(l) or "ROADMAP-DASHBOARD.md" in l or re.search(r"\bROADMAP\.md\b", l):
                    if not dashboard_step_seen:
                        m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", l)
                        num_prefix = m.group(1) if m else "3. "
                        new_st_lines.append(f"{num_prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")
                        dashboard_step_seen = True
                    # Drop subsequent duplicate roadmap directives
                    continue
                new_st_lines.append(l)

            if not dashboard_step_seen:
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
                # Strip releases tokens
                if re.search(RELEASES_TOKENS, l, re.IGNORECASE):
                    continue
                if re.search(r"-\s+`?ROADMAP\.md`?\s*=", l):
                    if not roadmap_seen:
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
                # Strip standalone releases token lines
                if re.search(RELEASES_TOKENS, l, re.IGNORECASE) and not re.search(r"ROADMAP\.md", l):
                    continue
                m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", l)
                if m and (re.search(r"(?:ROADMAP-DASHBOARD\.md|ROADMAP\.md)", m.group(2), re.IGNORECASE) or re.search(RELEASES_TOKENS, m.group(2), re.IGNORECASE)):
                    if not roadmap_seen:
                        prefix = m.group(1)
                        new_st_lines.append(f"{prefix}Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")
                        roadmap_seen = True
                    continue
                elif re.search(r"\b(?:ROADMAP-DASHBOARD\.md|ROADMAP\.md)\b", l, re.IGNORECASE):
                    if not roadmap_seen:
                        new_st_lines.append("3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")
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

    # Perform slice replacements in reverse order of appearance
    splices = []
    if startup_s is not None:
        splices.append((startup_s["body_start"], startup_s["end"], new_startup_body))
    if role_s is not None:
        splices.append((role_s["body_start"], role_s["end"], new_role_body))

    splices.sort(key=lambda x: x[0], reverse=True)
    patched = content
    for start_idx, end_idx, new_text in splices:
        patched = patched[:start_idx] + new_text + patched[end_idx:]

    if role_s is None:
        re_sections = find_sections(patched)
        if re_sections:
            insert_at = re_sections[0]["start"]
            role_block = f"## Role split{crlf}{new_role_body}"
            patched = patched[:insert_at] + role_block + patched[insert_at:]
        else:
            patched = patched + f"{crlf}## Role split{crlf}{new_role_body}"

    if startup_s is None:
        startup_block = f"{crlf}## Startup sequence{crlf}{new_startup_body}"
        patched = patched + startup_block

    # Pre-validation of patched candidate BEFORE touching disk
    candidate_audit = audit_router(root, content_override=patched)
    if candidate_audit["drift"] or candidate_audit["error"]:
        return False, f"pre-write validation failed: {'; '.join(candidate_audit['reasons'])}"

    if dry_run:
        return True, "dry-run: planned updates to ROUTER.md"

    # Robust atomic write with rollback on error
    stat = os.stat(router_path)
    dir_name = os.path.dirname(os.path.abspath(router_path))
    fd, tmp_path = tempfile.mkstemp(prefix="router_audit_", dir=dir_name)
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as f:
            f.write(patched)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp_path, stat.st_mode)
        os.replace(tmp_path, router_path)
    except Exception as e:
        if os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except OSError:
                pass
        return False, f"failed to write updated ROUTER.md: {e}"

    return True, "updated ROUTER.md to reflect repository roadmap mode"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Audit and remediate ROUTER.md roadmap declarations.")
    parser.add_argument("root", nargs="?", default=".", help="Target repository directory (default: current directory)")
    parser.add_argument("--check", action="store_true", help="Exit 1 if drift, missing, or error detected, 0 if clean")
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

    if args.check and (not audit["exists"] or audit["drift"] or audit["error"]):
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
