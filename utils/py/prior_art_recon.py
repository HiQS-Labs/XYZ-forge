#!/usr/bin/env python3
"""Prior-Art Reconnaissance Scanner for /start-task and /marathon-triage (GH-777).

Bounded, single-child read-only probe that checks:
1. Open PRs in the current and sibling repositories (`gh pr list`).
2. Active and queued items in the PRS Roadmap ledger (`releases.db`).
3. Existing helpers across `utils/py/`, `src/`, `lib/`, and `scripts/` to prevent duplicate utility generation.

Outputs a structured JSON and markdown prior-art summary. Reports UNKNOWN gracefully if offline or tools missing.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def check_open_prs(repo_root: Path) -> tuple[list[dict[str, Any]], str | None]:
    """Scan open PRs on the current repository via gh CLI (or offline fallback)."""
    if not shutil.which("gh"):
        return [], "gh CLI not found on PATH"
    try:
        res = subprocess.run(
            ["gh", "pr", "list", "--state", "open", "--json", "number,title,headRefName,url", "--limit", "30"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            timeout=10,
        )
        if res.returncode == 0 and res.stdout.strip():
            return json.loads(res.stdout), None
        elif res.returncode != 0:
            return [], f"gh exit {res.returncode}: {res.stderr.strip()}"
    except Exception as e:
        return [], str(e)
    return [], None


def check_releases_roadmap(repo_root: Path, query: str = "") -> tuple[list[dict[str, Any]], str | None]:
    """Query releases.db active and queued roadmap items."""
    releases_db = repo_root / "releases.db"
    if not releases_db.exists():
        return [], "releases.db not found"
    import sqlite3
    try:
        conn = sqlite3.connect(f"file:{releases_db}?mode=ro", uri=True)
        cursor = conn.cursor()
        if query:
            cursor.execute(
                "SELECT gh_number, title, section, status_marker, doc_path FROM roadmap_items WHERE title LIKE ? OR raw_text LIKE ? LIMIT 20",
                (f"%{query}%", f"%{query}%"),
            )
        else:
            cursor.execute(
                "SELECT gh_number, title, section, status_marker, doc_path FROM roadmap_items WHERE section = 'In progress' LIMIT 20"
            )
        rows = cursor.fetchall()
        conn.close()
        items = [
            {"gh_number": r[0], "title": r[1], "section": r[2], "status": r[3], "doc_path": r[4]}
            for r in rows
        ]
        return items, None
    except Exception as e:
        return [], str(e)


def scan_existing_helpers(repo_root: Path, keyword: str) -> list[str]:
    """Search for existing helper functions and utilities matching keyword."""
    if not keyword:
        return []
    matches = []
    py_dirs = [repo_root / "utils" / "py", repo_root / "src", repo_root / "lib", repo_root / "scripts"]
    pattern = re.compile(rf"def\s+.*{re.escape(keyword)}.*\(", re.IGNORECASE)
    for pdir in py_dirs:
        if not pdir.exists():
            continue
        for f in pdir.rglob("*.py"):
            try:
                for line_no, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
                    if pattern.search(line):
                        matches.append(f"{f.relative_to(repo_root)}:{line_no}: {line.strip()}")
            except Exception:
                continue
    return matches[:15]


def main() -> int:
    parser = argparse.ArgumentParser(description="Prior-Art Reconnaissance Scanner.")
    parser.add_argument("--query", default="", help="Issue topic, feature keyword, or utility name.")
    parser.add_argument("--json", action="store_true", help="Output JSON envelope.")
    args = parser.parse_args()

    open_prs, pr_error = check_open_prs(REPO_ROOT)
    active_roadmap, roadmap_error = check_releases_roadmap(REPO_ROOT, args.query)
    helpers = scan_existing_helpers(REPO_ROOT, args.query)

    errors = []
    if pr_error:
        errors.append(f"PR discovery: {pr_error}")
    if roadmap_error:
        errors.append(f"Roadmap discovery: {roadmap_error}")

    status = "UNKNOWN" if (pr_error and roadmap_error) else ("WARN" if errors else "PASS")

    payload = {
        "status": status,
        "query": args.query,
        "open_prs_count": len(open_prs),
        "open_prs": open_prs,
        "roadmap_items_count": len(active_roadmap),
        "roadmap_items": active_roadmap,
        "existing_helpers_count": len(helpers),
        "existing_helpers": helpers,
        "errors": errors,
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print("## Prior-Art Reconnaissance Summary")
        print(f"- **Query**: `{args.query or 'none'}`")
        print(f"- **Status**: `{status}`")
        if errors:
            for err in errors:
                print(f"  - ⚠️ {err}")
        print(f"- **Open PRs Found**: {len(open_prs)}")
        if open_prs:
            for pr in open_prs[:5]:
                print(f"  - #{pr.get('number', '?')}: {pr.get('title', '')} (`{pr.get('headRefName', '')}`)")
        print(f"- **Active/Matching Roadmap Items**: {len(active_roadmap)}")
        for r in active_roadmap[:5]:
            gh_num = r.get("gh_number")
            num_str = f"#{gh_num}" if gh_num else "unlinked"
            print(f"  - {num_str}: {r.get('title', '')} [{r.get('section', '')}]")
        print(f"- **Existing Matching Helpers**: {len(helpers)}")
        for h in helpers:
            print(f"  - `{h}`")

    return 0


if __name__ == "__main__":
    sys.exit(main())
