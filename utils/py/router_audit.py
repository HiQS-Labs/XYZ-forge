#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring prefixed custom sections like '## Role split rationale').
  - Asserts ## Role split affirmatively declares ROADMAP-DASHBOARD.md as generated view of roadmap ledger (rejecting 'not generated', 'lives elsewhere', 'historical archive', 'do not read', 'obsolete').
  - Asserts ## Role split declares ROADMAP.md frozen/legacy AND points to releases.db/releases.sql (rejecting active/current/priority claims or negated frozen/legacy in any clause/marker/prose/colon).
  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md for current work/state (rejecting 'historical reference only', 'do not read') and forbids active ROADMAP.md directives in any clause (supporting valid negations like 'do not use ROADMAP.md').
- If in legacy mode:
  - Asserts exactly one exact ## Role split and ## Startup sequence section exists.
  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger and forbids frozen/legacy/releases-source tokens in any clause.
  - Asserts ## Startup sequence directs to active ROADMAP.md in a non-negated clause (supporting '-', '*', numbered lists, markdown links, rejecting affirmative frozen/legacy clauses).
- In --fix mode:
  - Deduplicates and safely splices exact bounded ## Role split and ## Startup sequence sections while preserving untouched custom sections and line endings byte-for-byte.
  - Replaces all marker variants ('-', '*', '+', numbered, colons, prose) with canonical format.
  - Collapses duplicate roadmap directives in Startup to exactly one canonical step.
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
ROADMAP_MENTION_RE = r"(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))"
DASHBOARD_MENTION_RE = r"(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))"


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


def split_clauses(line):
    """Splits a line into clauses by punctuation, conjunctions, or sentence boundaries."""
    return [c.strip() for c in re.split(r";|,|\s+(?:and|or|nevertheless|however|but|although|yet)\s+|\.\s+(?=[A-Z0-9\(])", line, flags=re.IGNORECASE) if c.strip()]


def is_active_roadmap_startup_directive(line):
    """Returns True if a Startup sequence line directs the reader to use ROADMAP.md for active/current work."""
    if not re.search(ROADMAP_MENTION_RE, line, re.IGNORECASE):
        return False

    for clause in split_clauses(line):
        if not re.search(r"(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\)|(?:use|read|consult|open|check|inspect)\s+it\b)", clause, re.IGNORECASE):
            continue

        # Explicit negations
        if re.search(r"\b(?:do\s+not\s+(?:use|read|edit)|never\s+(?:use|read|edit)|not\s+to\s+be\s+used)\b", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy)(?:\s+(?:file|ledger))?|obsolete|historical|frozen\s+since|frozen\s+legacy)\b", clause, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", clause, re.IGNORECASE):
            continue

        # Active directive verbs or current-work terms
        if re.search(r"\b(read|open|consult|see|check|inspect|use|follow)\b", clause, re.IGNORECASE):
            return True
        if re.search(r"\b(current\s+work|active\s+effort|active\s+tasks|current\s+tasks|current\s+priorities)\b", clause, re.IGNORECASE):
            return True
        if re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", clause, re.IGNORECASE):
            return True

    return False


def is_affirmative_dashboard_role_line(line):
    """Returns True if a Role split line affirmatively declares ROADMAP-DASHBOARD.md as the generated view."""
    if not re.search(DASHBOARD_MENTION_RE, line, re.IGNORECASE):
        return False

    m = re.search(r"(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))\s*(?:=|:|-|\s)\s*(.*)$", line, re.IGNORECASE)
    desc = m.group(1) if m else line

    # Denylist with polarity (e.g. 'not generated', 'lives elsewhere')
    if re.search(r"\b(do\s+not\s+read|do\s+not\s+use|obsolete|deprecated|not\s+active|not\s+used|historical\s+archive|historical\s+context|not\s+the\s+source|not\s+generated|not\s+current|lives\s+elsewhere)\b", desc, re.IGNORECASE):
        return False
    if re.search(r"\b(generated|human-readable|view\s+of\s+the\s+roadmap|roadmap\s+ledger)\b", desc, re.IGNORECASE):
        return True
    return False


def is_affirmative_dashboard_startup_directive(line):
    """Returns True if a Startup line affirmatively directs reading the dashboard for current work/state."""
    if not re.search(DASHBOARD_MENTION_RE, line, re.IGNORECASE):
        return False
    for clause in split_clauses(line):
        if not re.search(DASHBOARD_MENTION_RE, clause, re.IGNORECASE):
            continue
        if not re.search(r"\b(?:Read|Consult|Open|Check|See|Inspect|Use)\s+(?:`?ROADMAP-DASHBOARD\.md`?|\[[^\]]*\]\([^)]*ROADMAP-DASHBOARD\.md[^)]*\))", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(?:do\s+not|never)\s+(?:read|consult|open|check|use)\b", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(?:historical\s+(?:reference|archive|context)|only\s+for\s+historical|obsolete)\b", clause, re.IGNORECASE):
            continue
        return True
    return False


def is_legacy_active_role_line(line):
    """Returns True if a Role split line affirmatively declares ROADMAP.md as the active pointer ledger."""
    if not re.search(ROADMAP_MENTION_RE, line, re.IGNORECASE):
        return False
    if re.search(r"\b(not\s+active|obsolete|frozen|legacy|historical|releases\.db|releases\.sql|ROADMAP_SOURCE)\b", line, re.IGNORECASE):
        return False
    if re.search(r"\b(?:the\s+pointer\s+ledger|pointer\s+ledger\s+of\s+current|active\s+pointer|ledger\s+of\s+current|pointer\s+ledger)\b", line, re.IGNORECASE):
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
    role_sections = [s for s in sections if re.match(r"^Role\s+split$", s["heading"], re.IGNORECASE)]
    startup_sections = [s for s in sections if re.match(r"^Startup\s+sequence$", s["heading"], re.IGNORECASE)]

    if len(role_sections) > 1:
        result["drift"] = True
        result["reasons"].append(f"Duplicate '## Role split' sections detected ({len(role_sections)})")
    if len(startup_sections) > 1:
        result["drift"] = True
        result["reasons"].append(f"Duplicate '## Startup sequence' sections detected ({len(startup_sections)})")

    role_section = role_sections[0] if role_sections else None
    startup_section = startup_sections[0] if startup_sections else None

    all_role_lines = []
    for s in role_sections:
        all_role_lines.extend(s["body"].splitlines())

    all_startup_lines = []
    for s in startup_sections:
        all_startup_lines.extend(s["body"].splitlines())

    if releases_mode:
        # Releases Mode Validation
        if role_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Role split' section")
        else:
            has_affirmative_dashboard = any(
                is_affirmative_dashboard_role_line(l) for l in all_role_lines
            )
            roadmap_lines = [
                l for l in all_role_lines
                if re.search(ROADMAP_MENTION_RE, l, re.IGNORECASE)
            ]

            if not has_affirmative_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split does not affirmatively declare ROADMAP-DASHBOARD.md as the generated roadmap view")
            if not roadmap_lines:
                result["drift"] = True
                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
            else:
                for r_line in roadmap_lines:
                    # Check each clause in the line
                    clauses = split_clauses(r_line)
                    is_frozen_clause = any(
                        re.search(r"\b(frozen|legacy)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE)
                        for c in clauses
                    )
                    has_db_clause = any(
                        re.search(r"\b(releases\.db|releases\.sql|ROADMAP_SOURCE=releases)\b", c, re.IGNORECASE)
                        for c in clauses
                    )
                    has_active_clause = any(
                        (re.search(r"\b(active\s+pointer|active\s+ledger|current\s+work|current\s+priorities|the\s+pointer\s+ledger\s+of\s+current|active\s+effort|used\s+for\s+current)\b", c, re.IGNORECASE)
                         or re.search(r"(?:=|\b)\s*active\b", c, re.IGNORECASE))
                        and not re.search(r"\b(not\s+active|former\s+active)\b", c, re.IGNORECASE)
                        for c in clauses
                    )
                    has_negated_frozen_clause = any(
                        re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE)
                        for c in clauses
                    )

                    if has_active_clause or has_negated_frozen_clause or not (is_frozen_clause and has_db_clause):
                        result["drift"] = True
                        result["reasons"].append("Role split describes ROADMAP.md with active terms or lacks explicit frozen/legacy + releases DB source-of-truth declaration")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("ROUTER.md missing '## Startup sequence' section")
        else:
            has_affirmative_dashboard_startup = any(
                is_affirmative_dashboard_startup_directive(l) for l in all_startup_lines
            )
            has_active_roadmap_read = any(
                is_active_roadmap_startup_directive(l) for l in all_startup_lines
            )

            if not has_affirmative_dashboard_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence does not contain an affirmative directive to read ROADMAP-DASHBOARD.md for current work")
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
            has_rel_tokens = any(
                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in all_role_lines
            )
            has_affirmative_frozen_in_role = False
            for l in all_role_lines:
                for c in split_clauses(l):
                    if re.search(r"\b(ROADMAP\.md.*(?:frozen|legacy)|(?:frozen|legacy).*ROADMAP\.md|(?:is|remains)\s+(?:frozen|legacy))\b", c, re.IGNORECASE):
                        if not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE):
                            has_affirmative_frozen_in_role = True

            has_positive_active_role = any(
                is_legacy_active_role_line(l) for l in all_role_lines
            )

            if has_rel_tokens:
                result["drift"] = True
                result["reasons"].append("Role split references releases-mode tokens (ROADMAP-DASHBOARD.md/releases.db) in a legacy-mode repo")
            if has_affirmative_frozen_in_role:
                result["drift"] = True
                result["reasons"].append("Role split declares ROADMAP.md as frozen/legacy in a legacy-mode repo")
            if not has_positive_active_role:
                result["drift"] = True
                result["reasons"].append("Role split missing affirmative active ROADMAP.md pointer ledger declaration in a legacy-mode repo")

        if startup_section is None:
            result["drift"] = True
            result["reasons"].append("Legacy ROUTER.md missing '## Startup sequence' section")
        else:
            has_rel_tokens_startup = any(
                re.search(RELEASES_TOKENS, l, re.IGNORECASE) for l in all_startup_lines
            )
            has_affirmative_frozen_startup = False
            for l in all_startup_lines:
                for c in split_clauses(l):
                    if re.search(r"\b(ROADMAP\.md.*(?:frozen|legacy)|(?:frozen|legacy).*ROADMAP\.md|(?:is|remains)\s+(?:frozen|legacy))\b", c, re.IGNORECASE):
                        if not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE):
                            has_affirmative_frozen_startup = True

            has_valid_active_read = False
            for l in all_startup_lines:
                for clause in split_clauses(l):
                    if re.search(r"\b(?:Read|Consult|Open|Check|Use)\s+(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))", clause, re.IGNORECASE):
                        is_negated = bool(re.search(r"\b(do\s+not|never|obsolete|not\s+to\s+be)\b", clause, re.IGNORECASE))
                        is_frozen = bool(re.search(r"\b(frozen|legacy)\b", clause, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", clause, re.IGNORECASE))
                        if not is_negated and not is_frozen:
                            has_valid_active_read = True

            if has_rel_tokens_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence references releases-mode tokens in a legacy-mode repo")
            if has_affirmative_frozen_startup:
                result["drift"] = True
                result["reasons"].append("Startup sequence declares ROADMAP.md frozen in a legacy-mode repo")
            if not has_valid_active_read:
                result["drift"] = True
                result["reasons"].append("Startup sequence missing non-negated active ROADMAP.md directive in a legacy-mode repo")

        if result["drift"]:
            result["fixes_available"] = True

    return result


def fix_router(root, dry_run=False):
    """Applies targeted updates to ROUTER.md by splicing exact sections in-place, deduplicating sections, and preserving custom bytes."""
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
    role_sections = [s for s in sections if re.match(r"^Role\s+split$", s["heading"], re.IGNORECASE)]
    startup_sections = [s for s in sections if re.match(r"^Startup\s+sequence$", s["heading"], re.IGNORECASE)]

    primary_role_s = role_sections[0] if role_sections else None
    primary_startup_s = startup_sections[0] if startup_sections else None

    merged_role_lines = []
    for s in role_sections:
        merged_role_lines.extend(s["body"].splitlines())

    merged_startup_lines = []
    for s in startup_sections:
        merged_startup_lines.extend(s["body"].splitlines())

    if audit["releases_mode"]:
        # Build new Role split body
        new_r_lines = []
        dashboard_seen = False
        roadmap_seen = False

        if primary_role_s is not None:
            for l in merged_role_lines:
                if re.search(DASHBOARD_MENTION_RE, l, re.IGNORECASE):
                    if not dashboard_seen:
                        new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                elif re.search(ROADMAP_MENTION_RE, l, re.IGNORECASE):
                    if not dashboard_seen:
                        new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                        dashboard_seen = True
                    if not roadmap_seen:
                        new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
                        roadmap_seen = True
                else:
                    if l not in new_r_lines:
                        new_r_lines.append(l)

            if not dashboard_seen and not roadmap_seen:
                new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
                new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")
            elif not dashboard_seen:
                new_r_lines.append("- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`)")
            elif not roadmap_seen:
                new_r_lines.append("- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file")

            new_role_body = crlf.join(new_r_lines)
            if primary_role_s["body"].endswith("\n") or primary_role_s["body"].endswith("\r\n"):
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
        new_st_lines = []
        dashboard_step_seen = False

        if primary_startup_s is not None:
            for l in merged_startup_lines:
                if is_active_roadmap_startup_directive(l) or is_affirmative_dashboard_startup_directive(l) or "ROADMAP-DASHBOARD.md" in l or re.search(r"\bROADMAP\.md\b", l):
                    if not dashboard_step_seen:
                        m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", l)
                        num_prefix = m.group(1) if m else "3. "
                        new_st_lines.append(f"{num_prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")
                        dashboard_step_seen = True
                    continue
                if l not in new_st_lines:
                    new_st_lines.append(l)

            if not dashboard_step_seen:
                new_st_lines.append("3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.)")

            new_startup_body = crlf.join(new_st_lines)
            if primary_startup_s["body"].endswith("\n") or primary_startup_s["body"].endswith("\r\n"):
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
        new_r_lines = []
        roadmap_seen = False

        if primary_role_s is not None:
            for l in merged_role_lines:
                if re.search(RELEASES_TOKENS, l, re.IGNORECASE) or re.search(DASHBOARD_MENTION_RE, l, re.IGNORECASE):
                    continue
                if re.search(r"\b(?:ROADMAP\.md.*(?:frozen|legacy)|(?:frozen|legacy).*ROADMAP\.md)\b", l, re.IGNORECASE) and not re.search(ROADMAP_MENTION_RE, l, re.IGNORECASE):
                    continue
                if re.search(ROADMAP_MENTION_RE, l, re.IGNORECASE):
                    if not roadmap_seen:
                        new_r_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")
                        roadmap_seen = True
                else:
                    if l not in new_r_lines:
                        new_r_lines.append(l)

            if not roadmap_seen:
                new_r_lines.append("- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work")

            new_role_body = crlf.join(new_r_lines)
            if primary_role_s["body"].endswith("\n") or primary_role_s["body"].endswith("\r\n"):
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

        new_st_lines = []
        roadmap_seen = False

        if primary_startup_s is not None:
            for l in merged_startup_lines:
                if re.search(RELEASES_TOKENS, l, re.IGNORECASE) and not re.search(ROADMAP_MENTION_RE, l, re.IGNORECASE):
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
                if l not in new_st_lines:
                    new_st_lines.append(l)

            if not roadmap_seen:
                new_st_lines.append("3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.")

            new_startup_body = crlf.join(new_st_lines)
            if primary_startup_s["body"].endswith("\n") or primary_startup_s["body"].endswith("\r\n"):
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

    # Remove secondary duplicate sections and splice primary sections
    splices = []
    for dup in role_sections[1:]:
        splices.append((dup["start"], dup["end"], ""))
    for dup in startup_sections[1:]:
        splices.append((dup["start"], dup["end"], ""))

    if primary_startup_s is not None:
        splices.append((primary_startup_s["body_start"], primary_startup_s["end"], new_startup_body))
    if primary_role_s is not None:
        splices.append((primary_role_s["body_start"], primary_role_s["end"], new_role_body))

    splices.sort(key=lambda x: x[0], reverse=True)
    patched = content
    for start_idx, end_idx, new_text in splices:
        patched = patched[:start_idx] + new_text + patched[end_idx:]

    if primary_role_s is None:
        re_sections = find_sections(patched)
        if re_sections:
            insert_at = re_sections[0]["start"]
            role_block = f"## Role split{crlf}{new_role_body}"
            patched = patched[:insert_at] + role_block + patched[insert_at:]
        else:
            patched = patched + f"{crlf}## Role split{crlf}{new_role_body}"

    if primary_startup_s is None:
        startup_block = f"{crlf}## Startup sequence{crlf}{new_startup_body}"
        patched = patched + startup_block

    # Pre-validation of patched candidate BEFORE touching disk
    candidate_audit = audit_router(root, content_override=patched)
    if candidate_audit["drift"] or candidate_audit["error"]:
        return False, f"pre-write validation failed: {'; '.join(candidate_audit['reasons'])}"

    if dry_run:
        return True, "dry-run: planned updates to ROUTER.md"

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
