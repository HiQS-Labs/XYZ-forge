#!/usr/bin/env python3
"""router_audit.py — Audit and remediate ROUTER.md roadmap declarations across repos.

Contract:
- Checks if a target repository is in releases mode (releases.db present or anchored ROADMAP_SOURCE=releases in .pdda-mode).
- If in releases mode:
  - Asserts exactly one exact ## Role split and ## Startup sequence section exists (ignoring prefixed custom sections like '## Role split rationale').
  - Asserts ## Role split affirmatively declares ROADMAP-DASHBOARD.md as generated view of the roadmap ledger (rejecting 'generated deployment manifest', 'not a generated view', 'lives elsewhere', 'historical archive', 'do not read', 'obsolete').
  - Asserts ## Role split declares ROADMAP.md frozen/legacy AND affirmatively declares the releases DB (releases.db / releases.sql) as the source of truth (rejecting 'releases.db is present for compatibility', 'not the source of truth', active/current/priority claims or negated frozen/legacy in owned ROADMAP.md entries, while preserving non-owned entries like PROJECT/PDDA.md).
  - Asserts ## Startup sequence directs to ROADMAP-DASHBOARD.md for current work/state/active effort (rejecting purpose-free reads like 'for deployment instructions', 'not current state', 'historical reference only', 'do not read') and forbids active ROADMAP.md directives in all clauses (supporting valid negations like 'do not use ROADMAP.md', while preserving custom steps and historical reads like 'Read ROADMAP.md only for historical reference').
- If in legacy mode:
  - Asserts exactly one exact ## Role split and ## Startup sequence section exists.
  - Asserts ## Role split affirmatively declares active ROADMAP.md pointer ledger of current/active work in its own clause (rejecting 'pointer ledger for deployment policy', 'archived', 'frozen', 'legacy', 'releases.db', while preserving unrelated legacy entries like OLD-API.md).
  - Asserts ## Startup sequence directs to active ROADMAP.md for active effort/current work/tasks/intake in the candidate directive clause itself (rejecting 'for deployment instructions; do not use ROADMAP.md for current work', 'historical reference only', ignoring unrelated legacy entries).
- In --fix mode:
  - Deduplicates and safely splices exact bounded ## Role split and ## Startup sequence sections while preserving custom entries (like PROJECT/PDDA.md, OLD-API.md), custom startup steps, historical reads, custom sections, duplicate lines, and verbatim line endings (mixed LF/CRLF).
  - Ensures clean structural newlines between sections even if the previous section was empty.
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

# Matches lines where ROADMAP.md or ROADMAP-DASHBOARD.md is the declared subject
OWNED_ROADMAP_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP\.md`?\s*(?:=|:|—|-)\s*(.*)$"
OWNED_DASHBOARD_DECL_RE = r"^\s*(?:[-*+]|\d+\.)?\s*`?ROADMAP-DASHBOARD\.md`?\s*(?:=|:|—|-)\s*(.*)$"


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
    return [c.strip() for c in re.split(r";|,|\s+(?:and|or|nevertheless|however|but|although|yet|while|whereas)\s+|\.\s+(?=[A-Z0-9\(])", line, flags=re.IGNORECASE) if c.strip()]


def split_lines_preserving_endings(text):
    """Splits text into lines while preserving each line's trailing newline characters (\r\n, \n, or empty)."""
    result = []
    lines = text.splitlines(True)
    for l in lines:
        if l.endswith("\r\n"):
            result.append((l[:-2], "\r\n"))
        elif l.endswith("\n"):
            result.append((l[:-1], "\n"))
        else:
            result.append((l, ""))
    return result


def is_role_stray_active_roadmap_line(line):
    """Returns True if any clause on a Role split line (not an owned declaration) claims ROADMAP.md is active."""
    if re.search(OWNED_ROADMAP_DECL_RE, line, re.IGNORECASE):
        return False
    if not re.search(ROADMAP_MENTION_RE, line, re.IGNORECASE):
        return False

    for clause in split_clauses(line):
        if not re.search(ROADMAP_MENTION_RE, clause, re.IGNORECASE):
            continue
        if re.search(r"\b(?:governs\s+the|contract|frozen\s+since|historical\s+archive)\b", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(used\s+for\s+current|active\s+effort|active\s+tasks|current\s+priorities|active\s+pointer|current\s+work|active\s+items)\b", clause, re.IGNORECASE):
            if not re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy))\b", clause, re.IGNORECASE):
                return True
    return False


def is_owned_startup_roadmap_directive(line):
    """Returns True if a Startup line is the primary directive to read ROADMAP.md or ROADMAP-DASHBOARD.md for current work."""
    # Excludes purely historical reference reads like "Read ROADMAP.md only for historical reference"
    # But if the line ALSO contains an affirmative active directive clause, it is an active directive needing replacement
    if is_active_roadmap_startup_directive(line):
        return True
    if re.search(r"\b(?:only\s+for\s+historical|for\s+historical\s+reference|historical\s+reference\s+only)\b", line, re.IGNORECASE):
        return False

    m = re.match(r"^\s*(?:\d+\.|\-|\*|\+)?\s*(?:Read|Consult|Open|Check|See|Inspect|Use)\s+(`?[^`\s]+`?|\[[^\]]+\]\([^)]+\))", line, re.IGNORECASE)
    if not m:
        if re.search(r"^\s*(?:\d+\.|\-|\*|\+)?\s*(?:Read|Consult|Open|Check|See|Inspect|Use)\s+(?:`?ROADMAP(?:-DASHBOARD)?\.md`?|\[[^\]]*\]\([^)]*ROADMAP(?:-DASHBOARD)?\.md[^)]*\))", line, re.IGNORECASE):
            return True
        return False
    target = m.group(1)
    if re.search(r"\bROADMAP(?:-DASHBOARD)?\.md\b", target, re.IGNORECASE):
        return True
    return False


def is_active_roadmap_startup_directive(line):
    """Returns True if any clause on a Startup sequence line directs the reader to use ROADMAP.md for active/current work."""
    if not re.search(ROADMAP_MENTION_RE, line, re.IGNORECASE):
        return False

    for clause in split_clauses(line):
        if not re.search(ROADMAP_MENTION_RE, clause, re.IGNORECASE):
            continue
        # If this clause is explicitly historical only, it's not active
        if re.search(r"\b(?:only\s+for\s+historical|for\s+historical\s+reference|historical\s+reference\s+only)\b", clause, re.IGNORECASE):
            continue
        # If this clause is explicitly negated, it's not active
        if re.search(r"\b(?:do\s+not\s+(?:use|read|edit|consult|open)|never\s+(?:use|read|edit|consult|open)|not\s+to\s+be\s+used)\b", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", clause, re.IGNORECASE):
            return True

        # Check for un-negated read/open/consult/use verb in this clause
        if re.search(r"\b(?:read|open|consult|see|check|inspect|use|follow)\s+(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\)|it\b)", clause, re.IGNORECASE):
            if not re.search(r"\b(?:do\s+not|never|not\s+to\s+be)\b", clause, re.IGNORECASE):
                # If clause is explicitly frozen legacy, it's safe
                if not re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy)|obsolete|frozen\s+since)\b", clause, re.IGNORECASE):
                    return True

        # Check for current work terms in this clause
        if re.search(r"\b(current\s+work|active\s+effort|active\s+tasks|current\s+tasks|current\s+priorities|active\s+items)\b", clause, re.IGNORECASE):
            if not re.search(r"\b(?:is\s+(?:the\s+)?(?:frozen|legacy)|obsolete|frozen\s+since)\b", clause, re.IGNORECASE):
                return True

    return False


def is_affirmative_dashboard_role_line(line):
    """Returns True if a Role split line affirmatively declares ROADMAP-DASHBOARD.md as the generated view of the roadmap ledger."""
    m = re.search(OWNED_DASHBOARD_DECL_RE, line, re.IGNORECASE)
    if not m:
        return False
    desc = m.group(1)

    if re.search(r"\b(do\s+not\s+read|do\s+not\s+use|obsolete|deprecated|not\s+active|not\s+used|historical\s+archive|historical\s+context|not\s+the\s+source|not\s+(?:a\s+)?generated|not\s+current|lives\s+elsewhere)\b", desc, re.IGNORECASE):
        return False
    if (re.search(r"\b(?:generated|human-readable)\b.*?\b(?:view\s+of\s+(?:the\s+)?roadmap|roadmap\s+ledger|view\s+of\s+the\s+ledger)\b", desc, re.IGNORECASE)
            or re.search(r"\b(?:view\s+of\s+(?:the\s+)?roadmap|roadmap\s+ledger)\b.*?\b(?:generated|human-readable)\b", desc, re.IGNORECASE)):
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
        if re.search(r"\b(?:historical\s+(?:reference|archive|context)|only\s+for\s+historical|obsolete|not\s+current|not\s+for\s+current)\b", clause, re.IGNORECASE):
            continue
        if re.search(r"\b(active\s+effort|parked\s+intake|current\s+state|active\s+tasks|current\s+work|find\s+(?:the\s+)?active|active\s+work|roadmap\s+ledger)\b", line, re.IGNORECASE) or re.search(r"\b(?:find\s+(?:the\s+)?active|to\s+find)\b", clause, re.IGNORECASE):
            if not re.search(r"\bnot\s+current\b", line, re.IGNORECASE):
                return True
    return False


def is_legacy_active_role_line(line):
    """Returns True if a Role split line affirmatively declares ROADMAP.md as the active pointer ledger of current work."""
    m = re.search(OWNED_ROADMAP_DECL_RE, line, re.IGNORECASE)
    if not m:
        return False
    desc = m.group(1)

    if re.search(r"\b(not\s+active|obsolete|frozen|legacy|historical|archived|releases\.db|releases\.sql|ROADMAP_SOURCE)\b", desc, re.IGNORECASE):
        return False
    for clause in split_clauses(desc):
        if re.search(r"\b(?:the\s+pointer\s+ledger\s+of\s+current|pointer\s+ledger\s+of\s+current|active\s+pointer|ledger\s+of\s+current|current,\s+completed|pointer\s+ledger\s+of\s+active)\b", clause, re.IGNORECASE):
            return True
        if re.search(r"\b(?:the\s+pointer\s+ledger|pointer\s+ledger)\b", clause, re.IGNORECASE) and re.search(r"\b(?:current\s+work|active\s+effort|completed,\s+attempted|current\s+tasks)\b", clause, re.IGNORECASE):
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
            owned_roadmap_lines = [
                l for l in all_role_lines
                if re.search(OWNED_ROADMAP_DECL_RE, l, re.IGNORECASE)
            ]

            if not has_affirmative_dashboard:
                result["drift"] = True
                result["reasons"].append("Role split does not affirmatively declare ROADMAP-DASHBOARD.md as the generated roadmap view")
            if not owned_roadmap_lines:
                result["drift"] = True
                result["reasons"].append("Role split does not contain a ROADMAP.md declaration")
            else:
                for r_line in owned_roadmap_lines:
                    clauses = split_clauses(r_line)
                    is_frozen_clause = any(
                        re.search(r"\b(frozen|legacy)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE)
                        for c in clauses
                    )
                    has_affirmative_db_clause = any(
                        (re.search(r"\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE) and re.search(r"\b(?:is\s+(?:the\s+)?source|source\s+of\s+truth)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|never)\s+(?:the\s+)?source\b", c, re.IGNORECASE))
                        or (re.search(r"\b(?:the\s+)?(?:releases\s+db|source\s+of\s+truth)\b", c, re.IGNORECASE) and re.search(r"\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE) and not re.search(r"\b(?:not|never)\s+(?:the\s+)?source\b", c, re.IGNORECASE))
                        or re.search(r"\b(?:ROADMAP_SOURCE=releases)\b", c, re.IGNORECASE)
                        for c in clauses
                    )
                    has_negated_db_clause = any(
                        re.search(r"\b(?:releases\.db|releases\.sql)\b.*?\b(?:not\s+(?:the\s+)?source)\b", c, re.IGNORECASE)
                        or re.search(r"\b(?:not\s+(?:the\s+)?source)\b.*?\b(?:releases\.db|releases\.sql)\b", c, re.IGNORECASE)
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

                    if has_active_clause or has_negated_frozen_clause or has_negated_db_clause or not (is_frozen_clause and has_affirmative_db_clause):
                        result["drift"] = True
                        result["reasons"].append("Role split describes ROADMAP.md with active terms or lacks explicit frozen/legacy + releases DB source-of-truth declaration")

            for l in all_role_lines:
                if is_role_stray_active_roadmap_line(l):
                    result["drift"] = True
                    result["reasons"].append("Role split contains stray prose active ROADMAP.md statement")

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
                    if re.search(ROADMAP_MENTION_RE, c, re.IGNORECASE) and re.search(r"\b(?:frozen|legacy)\b", c, re.IGNORECASE):
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
                    if re.search(ROADMAP_MENTION_RE, c, re.IGNORECASE) and re.search(r"\b(?:frozen|legacy)\b", c, re.IGNORECASE):
                        if not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", c, re.IGNORECASE):
                            has_affirmative_frozen_startup = True

            has_valid_active_read = False
            for l in all_startup_lines:
                for clause in split_clauses(l):
                    if re.search(r"\b(?:Read|Consult|Open|Check|Use)\s+(?:`?ROADMAP\.md`?|\[[^\]]*\]\([^)]*ROADMAP\.md[^)]*\))", clause, re.IGNORECASE):
                        is_negated = bool(re.search(r"\b(do\s+not|never|obsolete|not\s+to\s+be|historical\s+reference\s+only|only\s+for\s+historical)\b", clause, re.IGNORECASE))
                        is_frozen = bool(re.search(r"\b(frozen|legacy)\b", clause, re.IGNORECASE) and not re.search(r"\b(?:not|isn't|never)\s+(?:frozen|legacy)\b", clause, re.IGNORECASE))
                        has_active_purpose = bool(re.search(r"\b(active\s+effort|current\s+work|current\s+tasks|active\s+tasks|current\s+priorities|find\s+(?:the\s+)?active|parked\s+intake)\b", clause, re.IGNORECASE))
                        if not is_negated and not is_frozen and has_active_purpose:
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

    # Line-level extraction preserving original terminators per line
    merged_role_lines = []
    for s in role_sections:
        merged_role_lines.extend(split_lines_preserving_endings(s["body"]))

    merged_startup_lines = []
    for s in startup_sections:
        merged_startup_lines.extend(split_lines_preserving_endings(s["body"]))

    if audit["releases_mode"]:
        # Build new Role split body
        new_r_pieces = []
        dashboard_seen = False
        roadmap_seen = False

        if primary_role_s is not None and primary_role_s["body"].strip():
            for line_text, term in merged_role_lines:
                eff_term = term if term else crlf
                if re.search(OWNED_DASHBOARD_DECL_RE, line_text, re.IGNORECASE):
                    if not dashboard_seen:
                        new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){eff_term}")
                        dashboard_seen = True
                elif re.search(OWNED_ROADMAP_DECL_RE, line_text, re.IGNORECASE):
                    if not dashboard_seen:
                        new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){eff_term}")
                        dashboard_seen = True
                    if not roadmap_seen:
                        new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{eff_term}")
                        roadmap_seen = True
                elif is_role_stray_active_roadmap_line(line_text):
                    continue
                else:
                    new_r_pieces.append(f"{line_text}{term}")

            if not dashboard_seen and not roadmap_seen:
                new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){crlf}")
                new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{crlf}")
            elif not dashboard_seen:
                new_r_pieces.append(f"- `ROADMAP-DASHBOARD.md` = the generated, human-readable view of the roadmap ledger (read this; regenerate with `utils/roadmap-dashboard.sh` or `.xyz/utils/roadmap-dashboard.sh`){crlf}")
            elif not roadmap_seen:
                new_r_pieces.append(f"- `ROADMAP.md` = LEGACY pointer ledger, frozen since the `ROADMAP_SOURCE=releases` flip — the RELEASES DB (`releases.db` via `releases.sql`) is the source of truth; write via `releases roadmap add`, never by editing this file{crlf}")

            new_role_body = "".join(new_r_pieces)
            if not new_role_body.endswith("\n") and not new_role_body.endswith("\r\n"):
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
        new_st_pieces = []
        dashboard_step_seen = False

        if primary_startup_s is not None and primary_startup_s["body"].strip():
            for line_text, term in merged_startup_lines:
                eff_term = term if term else crlf
                if is_owned_startup_roadmap_directive(line_text):
                    if not dashboard_step_seen:
                        m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", line_text)
                        num_prefix = m.group(1) if m else "3. "
                        new_st_pieces.append(f"{num_prefix}Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.){eff_term}")
                        dashboard_step_seen = True
                    continue
                new_st_pieces.append(f"{line_text}{term}")

            if not dashboard_step_seen:
                new_st_pieces.append(f"3. Read `ROADMAP-DASHBOARD.md` (or `python3 utils/py/releases_app.py roadmap list` / `.xyz/utils/py/releases_app.py roadmap list`) to find the active effort or parked intake. -> expect links outward to the canonical `PROJECT/**` docs; the roadmap is a pointer ledger, not a plan body. (`ROADMAP.md` is the frozen legacy file — do not read it for current state or edit it.){crlf}")

            new_startup_body = "".join(new_st_pieces)
            if not new_startup_body.endswith("\n") and not new_startup_body.endswith("\r\n"):
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
        new_r_pieces = []
        roadmap_seen = False

        if primary_role_s is not None and primary_role_s["body"].strip():
            for line_text, term in merged_role_lines:
                eff_term = term if term else crlf
                if re.search(OWNED_DASHBOARD_DECL_RE, line_text, re.IGNORECASE) or re.search(RELEASES_TOKENS, line_text, re.IGNORECASE):
                    continue
                if re.search(r"\bROADMAP\.md.*(?:frozen|legacy)\b", line_text, re.IGNORECASE) and not re.search(OWNED_ROADMAP_DECL_RE, line_text, re.IGNORECASE):
                    continue
                if re.search(OWNED_ROADMAP_DECL_RE, line_text, re.IGNORECASE):
                    if not roadmap_seen:
                        new_r_pieces.append(f"- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work{eff_term}")
                        roadmap_seen = True
                else:
                    new_r_pieces.append(f"{line_text}{term}")

            if not roadmap_seen:
                new_r_pieces.append(f"- `ROADMAP.md` = the pointer ledger of current, completed, attempted, and deferred work{crlf}")

            new_role_body = "".join(new_r_pieces)
            if not new_role_body.endswith("\n") and not new_role_body.endswith("\r\n"):
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

        new_st_pieces = []
        roadmap_seen = False

        if primary_startup_s is not None and primary_startup_s["body"].strip():
            for line_text, term in merged_startup_lines:
                eff_term = term if term else crlf
                if is_owned_startup_roadmap_directive(line_text):
                    if not roadmap_seen:
                        m = re.match(r"^(\s*(?:\d+\.|\-|\*)\s+)(.*)$", line_text)
                        prefix = m.group(1) if m else "3. "
                        new_st_pieces.append(f"{prefix}Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.{eff_term}")
                        roadmap_seen = True
                    continue
                new_st_pieces.append(f"{line_text}{term}")

            if not roadmap_seen:
                new_st_pieces.append(f"3. Read `ROADMAP.md` to find the active effort or parked intake. -> expect links outward to canonical `PROJECT/**` docs.{crlf}")

            new_startup_body = "".join(new_st_pieces)
            if not new_startup_body.endswith("\n") and not new_startup_body.endswith("\r\n"):
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
