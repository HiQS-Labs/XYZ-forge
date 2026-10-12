#!/usr/bin/env python3
"""Prior-Art Reconnaissance Scanner for /start-task and /marathon-triage (GH-777).

Bounded, read-only probe that checks:
1. Open PRs, plus PRs merged in the last `--since-days` days (`gh pr list`), in the current
   repository and any `--repo OWNER/NAME` siblings. With `--query`, GitHub search matches
   titles and bodies, so `Fixes #N` links and PR descriptions count.
2. Issues in any state (`gh issue list --state all`) for the same repositories (GH-1025).
3. Active and queued items in the PRS Roadmap ledger (`releases.db`).
4. Existing helpers across `utils/py/`, `src/`, `lib/`, and `scripts/` to prevent duplicate utility generation.

Merged PRs and issues closed as completed are reported as `existing_fix_candidates`: work that may
already solve the ask, which /start-task must resolve before planning. Outputs a structured JSON
and markdown prior-art summary. Reports UNKNOWN gracefully if offline or tools missing.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import date, timedelta
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def _run_gh(cmd: list[str], repo_root: Path) -> tuple[Any, str | None]:
    """Run one bounded gh call and parse its JSON output."""
    try:
        res = subprocess.run(["gh", *cmd], cwd=str(repo_root), capture_output=True, text=True, timeout=10)
    except Exception as e:
        return None, str(e)
    if res.returncode != 0:
        return None, f"gh exit {res.returncode}: {res.stderr.strip()[:200]}"
    return (json.loads(res.stdout) if res.stdout.strip() else []), None


def _matches(query: str, *texts: str | None) -> bool:
    """Every query word appears in the title or body, like GitHub search's implicit AND."""
    haystack = " ".join(t or "" for t in texts).lower()
    return all(word in haystack for word in query.lower().split())


def _rest_list(kind: str, repo_root: Path, repo: str | None, state: str, query: str,
               since: str) -> tuple[list[dict[str, Any]], str | None]:
    """Repository-scoped REST fallback for hosts that refuse `gh pr|issue list` (GraphQL).

    Reads one page of the 100 most recently updated items and filters locally."""
    path = f"repos/{repo or '{owner}/{repo}'}/"
    if kind == "issue":
        path += "issues?state=all&sort=updated&direction=desc&per_page=100"
    else:
        rest_state = "open" if state == "open" else "closed"
        path += f"pulls?state={rest_state}&sort=updated&direction=desc&per_page=100"
    raw, err = _run_gh(["api", path], repo_root)
    if err:
        return [], err
    rows = []
    for item in raw:
        if kind == "issue" and "pull_request" in item:
            continue
        if state == "merged" and not (item.get("merged_at") or "") >= since:
            continue
        if query and not _matches(query, item.get("title"), item.get("body")):
            continue
        rows.append({
            "number": item.get("number"),
            "title": item.get("title", ""),
            "url": item.get("html_url", ""),
            "state": "MERGED" if item.get("merged_at") else (item.get("state") or "").upper(),
            "headRefName": (item.get("head") or {}).get("ref", ""),
            "mergedAt": item.get("merged_at"),
            "stateReason": (item.get("state_reason") or "").upper() or None,
        })
    return rows[:30], None


def _gh_list(kind: str, repo_root: Path, repo: str | None, state: str, query: str,
             since: str = "") -> tuple[list[dict[str, Any]], str | None]:
    """List PRs or issues via `gh <kind> list`, falling back to repository-scoped REST."""
    if not shutil.which("gh"):
        return [], "gh CLI not found on PATH"
    fields = "number,title,url,state," + ("headRefName,mergedAt" if kind == "pr" else "stateReason")
    search = f"{query} merged:>={since}".strip() if state == "merged" else query
    cmd = [kind, "list", "--state", state, "--json", fields, "--limit", "30"]
    if search:
        cmd += ["--search", search]
    if repo:
        cmd += ["--repo", repo]
    rows, err = _run_gh(cmd, repo_root)
    if err:
        rows, rest_err = _rest_list(kind, repo_root, repo, state, query, since)
        if rest_err:
            return [], f"{err}; REST fallback: {rest_err}"
    for row in rows:
        row["repo"] = repo or "current"
    return rows, None


def check_prs(repo_root: Path, repo: str | None, query: str, since_days: int
              ) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    """Open PRs and recently merged PRs matching the query (titles and bodies)."""
    since = (date.today() - timedelta(days=since_days)).isoformat()
    open_prs, open_err = _gh_list("pr", repo_root, repo, "open", query)
    merged_prs, merged_err = _gh_list("pr", repo_root, repo, "merged", query, since)
    return open_prs, merged_prs, [e for e in (open_err, merged_err) if e]


def check_issues(repo_root: Path, repo: str | None, query: str) -> tuple[list[dict[str, Any]], str | None]:
    """Issues in any state matching the query; without a query, the issue search is skipped."""
    if not query:
        return [], None
    return _gh_list("issue", repo_root, repo, "all", query)


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
    parser.add_argument("--repo", action="append", default=[], metavar="OWNER/NAME",
                        help="Also scan this sibling repository (repeatable).")
    parser.add_argument("--since-days", type=int, default=30,
                        help="How far back to look for merged PRs (default 30).")
    parser.add_argument("--json", action="store_true", help="Output JSON envelope.")
    args = parser.parse_args()

    open_prs: list[dict[str, Any]] = []
    merged_prs: list[dict[str, Any]] = []
    issues: list[dict[str, Any]] = []
    gh_errors: list[str] = []
    for repo in [None, *args.repo]:
        repo_open, repo_merged, pr_errs = check_prs(REPO_ROOT, repo, args.query, args.since_days)
        repo_issues, issue_err = check_issues(REPO_ROOT, repo, args.query)
        open_prs += repo_open
        merged_prs += repo_merged
        issues += repo_issues
        gh_errors += [f"{repo or 'current'}: {e}" for e in pr_errs + ([issue_err] if issue_err else [])]
    # Without a query the merged list is just recent history, not a match for the ask.
    fix_candidates = (merged_prs if args.query else []) + [
        i for i in issues if i.get("state") == "CLOSED" and i.get("stateReason") == "COMPLETED"
    ]

    active_roadmap, roadmap_error = check_releases_roadmap(REPO_ROOT, args.query)
    helpers = scan_existing_helpers(REPO_ROOT, args.query)

    errors = []
    errors += [f"GitHub discovery: {e}" for e in gh_errors]
    if roadmap_error:
        errors.append(f"Roadmap discovery: {roadmap_error}")

    status = "UNKNOWN" if (gh_errors and roadmap_error) else ("WARN" if errors else "PASS")

    payload = {
        "status": status,
        "query": args.query,
        "open_prs_count": len(open_prs),
        "open_prs": open_prs,
        "merged_prs_count": len(merged_prs),
        "merged_prs": merged_prs,
        "issues_count": len(issues),
        "issues": issues,
        "existing_fix_candidates_count": len(fix_candidates),
        "existing_fix_candidates": fix_candidates,
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
        if fix_candidates:
            print(f"- ⛔ **Possible existing fix**: {len(fix_candidates)} merged PR(s) or completed issue(s) "
                  "match. Confirm before planning new work.")
            for c in fix_candidates[:5]:
                print(f"  - {c.get('repo')} #{c.get('number', '?')}: {c.get('title', '')} ({c.get('url', '')})")
        print(f"- **Open PRs Found**: {len(open_prs)}")
        for pr in open_prs[:5]:
            print(f"  - {pr.get('repo')} #{pr.get('number', '?')}: {pr.get('title', '')} (`{pr.get('headRefName', '')}`)")
        print(f"- **Merged PRs (last {args.since_days} days)**: {len(merged_prs)}")
        for pr in merged_prs[:5]:
            print(f"  - {pr.get('repo')} #{pr.get('number', '?')}: {pr.get('title', '')}")
        print(f"- **Matching Issues (any state)**: {len(issues)}")
        for i in issues[:5]:
            print(f"  - {i.get('repo')} #{i.get('number', '?')}: {i.get('title', '')} [{i.get('state', '')}]")
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
