#!/usr/bin/env python3
"""toposort_prs.py — Topological PR sequencing and dependency analysis.

Inspects open PRs, extracts explicit dependency annotations ("depends on #N", "blocked by #N"),
detects file collisions, and produces a safe merge order.
"""

import sys
import re
import json
import subprocess
from typing import List, Dict, Any, Set, Tuple, Optional


def fetch_open_prs(repo_path: Optional[str] = None) -> List[Dict[str, Any]]:
    """Fetches open PRs via GitHub CLI."""
    cmd = [
        "gh", "pr", "list",
        "--state", "open",
        "--json", "number,title,headRefName,baseRefName,labels,mergeable,statusCheckRollup,body,files,createdAt,url"
    ]
    cwd = repo_path or "."
    res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
    if res.returncode != 0:
        print(f"toposort_prs: gh pr list failed: {res.stderr.strip()}", file=sys.stderr)
        return []

    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError as exc:
        print(f"toposort_prs: JSON parse error: {exc}", file=sys.stderr)
        return []


def parse_pr_dependencies(body: str, title: str) -> Set[int]:
    """Extracts referenced PR dependencies from title and markdown body."""
    deps: Set[int] = set()
    text = f"{title}\n{body}"

    # Patterns like "depends on #123", "blocked by #456", "after #789", "requires #101"
    patterns = [
        r"(?:depends\s+on|blocked\s+by|after|requires|prerequisite:?)\s+(?:https://github\.com/[^/]+/[^/]+/pull/|#)(\d+)",
        r"(?:part\s+of\s+wave\s+after\s+#)(\d+)",
    ]

    for pat in patterns:
        for match in re.finditer(pat, text, re.IGNORECASE):
            try:
                deps.add(int(match.group(1)))
            except ValueError:
                pass

    return deps


def extract_touched_files(pr: Dict[str, Any]) -> Set[str]:
    """Extracts the set of touched file paths from a PR object."""
    files_obj = pr.get("files", [])
    paths = set()
    for f in files_obj:
        if isinstance(f, dict) and "path" in f:
            paths.add(f["path"])
        elif isinstance(f, str):
            paths.add(f)
    return paths


def toposort_prs(prs: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]], List[str]]:
    """Topologically sorts open PRs based on explicit dependencies and file collisions."""
    pr_by_num = {pr["number"]: pr for pr in prs}
    dep_graph: Dict[int, Set[int]] = {pr["number"]: set() for pr in prs}
    warnings: List[str] = []

    # 1. Build explicit dependencies
    for pr in prs:
        num = pr["number"]
        body = pr.get("body") or ""
        title = pr.get("title") or ""
        deps = parse_pr_dependencies(body, title)

        for d in deps:
            if d in pr_by_num:
                dep_graph[num].add(d)
            else:
                # Dependency is either already merged, closed, or external issue
                pass

    # 2. Analyze file overlap between PRs without explicit dependencies
    for i, pr1 in enumerate(prs):
        num1 = pr1["number"]
        files1 = extract_touched_files(pr1)
        if not files1:
            continue
        for pr2 in prs[i + 1:]:
            num2 = pr2["number"]
            files2 = extract_touched_files(pr2)
            if not files2:
                continue

            overlap = files1.intersection(files2)
            if overlap:
                # If no dependency exists, order by creation date (older first) or PR number
                if num2 not in dep_graph[num1] and num1 not in dep_graph[num2]:
                    created1 = pr1.get("createdAt", "")
                    created2 = pr2.get("createdAt", "")
                    if created1 <= created2:
                        dep_graph[num2].add(num1)
                        warnings.append(
                            f"File collision on {len(overlap)} file(s) between PR #{num1} and PR #{num2} — ordering #{num1} before #{num2}"
                        )
                    else:
                        dep_graph[num1].add(num2)
                        warnings.append(
                            f"File collision on {len(overlap)} file(s) between PR #{num2} and PR #{num1} — ordering #{num2} before #{num1}"
                        )

    # 3. Topological sort with cycle detection (Kahn's algorithm)
    in_degree = {num: 0 for num in pr_by_num}
    for num, deps in dep_graph.items():
        for d in deps:
            # edge is d -> num (d must be merged before num)
            in_degree[num] += 1

    queue = [num for num, deg in in_degree.items() if deg == 0]
    # Sort queue by PR number ascending for determinism
    queue.sort()

    ordered_nums: List[int] = []
    while queue:
        curr = queue.pop(0)
        ordered_nums.append(curr)

        for num, deps in dep_graph.items():
            if curr in deps:
                deps.remove(curr)
                in_degree[num] -= 1
                if in_degree[num] == 0:
                    queue.append(num)
                    queue.sort()

    # If cycle remains
    if len(ordered_nums) < len(prs):
        remaining = sorted(num for num in pr_by_num if num not in ordered_nums)
        warnings.append(f"Cycle or unresolved dependency detected among PRs: {remaining}. Appending in numerical order.")
        for r in remaining:
            ordered_nums.append(r)

    ordered_prs = [pr_by_num[num] for num in ordered_nums]
    return ordered_prs, prs, warnings


def format_pr_table(ordered_prs: List[Dict[str, Any]]) -> str:
    """Formats the ordered PR table in markdown."""
    lines = [
        "| Seq | PR # | Title | Branch | Base | Checks | Mergeable | Files |",
        "|:---:|:---:|---|---|---|:---:|:---:|:---:|",
    ]
    for idx, pr in enumerate(ordered_prs, 1):
        checks = "PASS"
        rollup = pr.get("statusCheckRollup") or []
        for c in rollup:
            if isinstance(c, dict):
                conclusion = c.get("conclusion") or c.get("state")
                if conclusion in ("FAILURE", "FAILED", "ERROR"):
                    checks = "FAIL"
                    break
                elif conclusion in ("PENDING", "IN_PROGRESS"):
                    checks = "PENDING"

        mergeable = pr.get("mergeable", "UNKNOWN")
        file_count = len(pr.get("files") or [])

        lines.append(
            f"| {idx} | [#{pr['number']}]({pr.get('url', '')}) | {pr.get('title', '')[:40]} | `{pr.get('headRefName', '')}` | `{pr.get('baseRefName', '')}` | {checks} | {mergeable} | {file_count} |"
        )
    return "\n".join(lines)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Topologically sort open GitHub PRs.")
    parser.add_argument("--repo", default=".", help="Target git repository path")
    parser.add_argument("--json", action="store_true", help="Output ordered PRs as JSON")

    args = parser.parse_args()

    prs = fetch_open_prs(args.repo)
    if not prs:
        print("No open PRs found.")
        return

    ordered, raw, warnings = toposort_prs(prs)

    if args.json:
        print(json.dumps(ordered, indent=2))
    else:
        print(f"### Recommended PR Merge Sequence ({len(ordered)} open PRs)\n")
        print(format_pr_table(ordered))
        if warnings:
            print("\n**Ordering Notes / Collision Alerts:**")
            for w in warnings:
                print(f"- {w}")


if __name__ == "__main__":
    main()
