#!/usr/bin/env python3
"""scan_clones.py — Discover and inspect Git checkouts, worktrees, and clones.

Strictly follows WORKTREE-SAFETY.md:
- Component-aware containment checking (safe roots vs protected roots).
- Differentiates linked worktrees (.git is a file) from standalone clones (.git is a directory).
- Verifies active locks (.git/relay-driver.lock), active processes, git status, stashes, and unpushed refs.
"""

import os
import sys
import json
import subprocess
import shutil
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

DEFAULT_SAFE_ROOTS = [
    Path.home() / "Documents" / "GH Repos",
    Path.home() / "agent-workspaces",
    Path.home() / "Documents" / "agent-workspaces",
]

DEFAULT_NEVER_DELETE = {
    Path.home(),
    Path.home() / "Documents",
    Path.home() / "Desktop",
    Path.home() / "Downloads",
    Path("/"),
    Path("/System"),
    Path("/usr"),
    Path("/Library"),
}


def _within(child: Path, parent: Path) -> bool:
    """True only if child is STRICTLY inside parent (rejects child == parent)."""
    if child == parent:
        return False
    try:
        child.relative_to(parent)
        return True
    except ValueError:
        return False


def is_safe_deletable_path(path: Path, safe_roots: Optional[List[Path]] = None, never_delete: Optional[set] = None) -> Tuple[bool, str]:
    """Verifies that a path is safe to delete according to WORKTREE-SAFETY.md §16.1."""
    if safe_roots is None:
        safe_roots = DEFAULT_SAFE_ROOTS
    if never_delete is None:
        never_delete = DEFAULT_NEVER_DELETE

    try:
        p = path.resolve()
    except Exception as exc:
        return False, f"Failed to resolve path: {exc}"

    resolved_never_delete = {r.resolve() for r in never_delete if r.exists()}
    if p in resolved_never_delete:
        return False, f"Refusing: path is in NEVER_DELETE protected roots ({p})"

    resolved_safe_roots = [r.resolve() for r in safe_roots if r.exists()]
    if not any(_within(p, r) for r in resolved_safe_roots):
        return False, f"Refusing: path is not strictly within SAFE_ROOTS ({p})"

    return True, "OK"


def run_git(cwd: Path, args: List[str]) -> subprocess.CompletedProcess:
    """Runs a git command in the target directory."""
    return subprocess.run(
        ["git", "-C", str(cwd)] + args,
        capture_output=True,
        text=True,
        check=False
    )


def is_pid_alive(pid: int) -> bool:
    """Checks if a process ID is currently alive."""
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def inspect_driver_lock(repo_path: Path) -> Dict[str, Any]:
    """Inspects .git/relay-driver.lock or .relay-driver.lock."""
    lock_candidates = [
        repo_path / ".git" / "relay-driver.lock",
        repo_path / ".relay-driver.lock",
    ]
    # In a linked worktree, .git is a file, so .git/relay-driver.lock doesn't exist directly,
    # but the parent common dir might have one.
    git_file = repo_path / ".git"
    if git_file.is_file():
        res = run_git(repo_path, ["rev-parse", "--git-common-dir"])
        if res.returncode == 0 and res.stdout.strip():
            common_dir = Path(res.stdout.strip())
            if not common_dir.is_absolute():
                common_dir = (repo_path / common_dir).resolve()
            lock_candidates.append(common_dir / "relay-driver.lock")

    for lock in lock_candidates:
        if lock.is_file():
            try:
                content = lock.read_text().strip()
                pid = None
                for line in content.splitlines():
                    if line.startswith("pid="):
                        try:
                            pid = int(line.split("=", 1)[1])
                        except ValueError:
                            pass
                    elif line.isdigit():
                        pid = int(line)
                
                alive = is_pid_alive(pid) if pid else True
                return {
                    "locked": True,
                    "lock_path": str(lock),
                    "pid": pid,
                    "alive": alive,
                    "content": content
                }
            except Exception as exc:
                return {"locked": True, "lock_path": str(lock), "error": str(exc), "alive": True}

    return {"locked": False}


def inspect_tick_claims(repo_path: Path) -> Dict[str, Any]:
    """Inspects .tick/STATE.md or .tick/locks/ for active claims."""
    state_file = repo_path / ".tick" / "STATE.md"
    if state_file.is_file():
        try:
            content = state_file.read_text()
            if "## Claimed" in content:
                claimed_section = content.split("## Claimed", 1)[1].split("##", 1)[0].strip()
                if claimed_section and not claimed_section.startswith("- (none)") and claimed_section != "- none":
                    return {"has_claims": True, "details": claimed_section.splitlines()[0]}
        except Exception:
            pass

    locks_dir = repo_path / ".tick" / "locks"
    if locks_dir.is_dir():
        try:
            locks = [f for f in locks_dir.iterdir() if f.is_file()]
            if locks:
                return {"has_claims": True, "details": f"{len(locks)} active lock file(s) in .tick/locks"}
        except Exception:
            pass

    return {"has_claims": False}


def inspect_checkout(repo_path: Path, primary_repo_path: Optional[Path] = None, exclude_patterns: Optional[List[str]] = None) -> Dict[str, Any]:
    """Inspects a single git checkout for status, locks, stashes, and disposition."""
    path = repo_path.resolve()
    name = path.name
    res: Dict[str, Any] = {
        "path": str(path),
        "name": name,
        "is_git": False,
        "checkout_type": "unknown",
        "current_branch": "",
        "head_sha": "",
        "is_clean": False,
        "dirty_count": 0,
        "dirty_files": [],
        "stash_count": 0,
        "unpushed_branches": [],
        "has_unpushed": False,
        "linked_worktrees": [],
        "parent_clone": None,
        "driver_lock": {"locked": False},
        "tick_claims": {"has_claims": False},
        "safe_deletable": False,
        "safe_deletable_reason": "",
        "disposition": "UNKNOWN",
        "disposition_reason": "",
    }

    git_entry = path / ".git"
    if not git_entry.exists():
        res["disposition"] = "NOT_A_GIT_REPO"
        res["disposition_reason"] = "Directory does not contain .git"
        return res

    res["is_git"] = True
    if git_entry.is_file():
        res["checkout_type"] = "linked_worktree"
        common_res = run_git(path, ["rev-parse", "--git-common-dir"])
        if common_res.returncode == 0:
            p_dir = Path(common_res.stdout.strip())
            if not p_dir.is_absolute():
                p_dir = (path / p_dir).resolve()
            res["parent_clone"] = str(p_dir.parent if p_dir.name == ".git" else p_dir)
    elif git_entry.is_dir():
        res["checkout_type"] = "standalone_clone"
    else:
        res["checkout_type"] = "unusual"

    # Check deletable boundary
    is_safe, safe_msg = is_safe_deletable_path(path)
    res["safe_deletable"] = is_safe
    res["safe_deletable_reason"] = safe_msg

    # Current branch and HEAD
    b_res = run_git(path, ["branch", "--show-current"])
    res["current_branch"] = b_res.stdout.strip() if b_res.returncode == 0 else ""
    head_res = run_git(path, ["rev-parse", "HEAD"])
    res["head_sha"] = head_res.stdout.strip()[:8] if head_res.returncode == 0 else ""

    # Status check
    st_res = run_git(path, ["status", "--porcelain"])
    if st_res.returncode == 0:
        lines = [l for l in st_res.stdout.splitlines() if l.strip()]
        res["dirty_count"] = len(lines)
        res["dirty_files"] = lines[:10]  # sample
        res["is_clean"] = (len(lines) == 0)
    else:
        res["is_clean"] = False
        res["dirty_count"] = -1

    # Stash check
    stash_res = run_git(path, ["stash", "list"])
    if stash_res.returncode == 0:
        slines = [l for l in stash_res.stdout.splitlines() if l.strip()]
        res["stash_count"] = len(slines)

    # Unpushed refs across all local branches
    refs_res = run_git(path, ["for-each-ref", "--format=%(refname:short)|%(upstream:short)|%(upstream:track)", "refs/heads"])
    if refs_res.returncode == 0:
        for line in refs_res.stdout.splitlines():
            if not line.strip():
                continue
            parts = line.strip().split("|")
            b_name = parts[0]
            upstream = parts[1] if len(parts) > 1 else ""
            track = parts[2] if len(parts) > 2 else ""
            if not upstream:
                # Check if commit exists on origin/development or origin/main
                verify_res = run_git(path, ["branch", "-r", "--contains", b_name])
                if not verify_res.stdout.strip():
                    res["unpushed_branches"].append(f"{b_name} (local only, not on origin)")
            elif "[ahead" in track:
                res["unpushed_branches"].append(f"{b_name} ({track})")

    res["has_unpushed"] = len(res["unpushed_branches"]) > 0

    # Linked worktrees (if standalone clone)
    if res["checkout_type"] == "standalone_clone":
        wt_res = run_git(path, ["worktree", "list", "--porcelain"])
        if wt_res.returncode == 0:
            current_wt = ""
            for line in wt_res.stdout.splitlines():
                if line.startswith("worktree "):
                    wt_path = line[len("worktree "):].strip()
                    if Path(wt_path).resolve() != path:
                        res["linked_worktrees"].append(wt_path)

    # Driver lock check
    res["driver_lock"] = inspect_driver_lock(path)

    # Check exclusions
    if exclude_patterns:
        for pat in exclude_patterns:
            if pat in name or pat in str(path):
                res["disposition"] = "PRESERVED_USER_EXCLUDE"
                res["disposition_reason"] = f"Matches user exclusion pattern: '{pat}'"
                return res

    # Primary checkout check
    if primary_repo_path and path == primary_repo_path.resolve():
        res["disposition"] = "PRIMARY_CHECKOUT"
        res["disposition_reason"] = "This is the active primary repository checkout"
        return res

    # Check .wiki repository
    if name.endswith(".wiki"):
        res["disposition"] = "PRESERVE_WIKI"
        res["disposition_reason"] = "GitHub wiki repository"
        return res

    # Check active lock
    if res["driver_lock"].get("locked") and res["driver_lock"].get("alive"):
        res["disposition"] = "ACTIVE_LOCKED"
        res["disposition_reason"] = f"Active relay/marathon driver lock held by PID {res['driver_lock'].get('pid')}"
        return res

    # Check active tick claims
    if res["tick_claims"].get("has_claims"):
        res["disposition"] = "ACTIVE_TICK_CLAIM"
        res["disposition_reason"] = f"Active task claim in .tick: {res['tick_claims'].get('details')}"
        return res

    # Check safety violations
    if not res["is_clean"]:
        res["disposition"] = "PRESERVE_DIRTY"
        res["disposition_reason"] = f"Working tree is dirty ({res['dirty_count']} modified/untracked files)"
        return res

    if res["stash_count"] > 0:
        res["disposition"] = "PRESERVE_STASH"
        res["disposition_reason"] = f"Checkout has {res['stash_count']} unpopped stash entries"
        return res

    if res["has_unpushed"]:
        res["disposition"] = "PRESERVE_UNPUSHED"
        res["disposition_reason"] = f"Has unpushed branches: {', '.join(res['unpushed_branches'])}"
        return res

    if res["checkout_type"] == "standalone_clone" and len(res["linked_worktrees"]) > 0:
        res["disposition"] = "PRESERVE_PARENT_CLONE"
        res["disposition_reason"] = f"Has {len(res['linked_worktrees'])} linked worktree(s) depending on it"
        return res

    if not res["safe_deletable"]:
        res["disposition"] = "PRESERVE_UNSAFE_ROOT"
        res["disposition_reason"] = res["safe_deletable_reason"]
        return res

    # If all safe:
    if res["checkout_type"] == "linked_worktree":
        res["disposition"] = "SAFE_REMOVE_WORKTREE"
        res["disposition_reason"] = "Clean linked worktree, safe to remove via `git worktree remove`"
    elif res["checkout_type"] == "standalone_clone":
        res["disposition"] = "SAFE_REMOVE_CLONE"
        res["disposition_reason"] = "100% clean standalone clone (0 dirty, 0 stashes, 0 unpushed, 0 dependent worktrees)"

    return res


def scan_directories(search_roots: List[Path], prefix_filter: Optional[str] = None, primary_repo: Optional[Path] = None, excludes: Optional[List[str]] = None) -> List[Dict[str, Any]]:
    """Scans root directories for candidate git checkouts."""
    results = []
    seen = set()

    for root in search_roots:
        if not root.exists() or not root.is_dir():
            continue

        try:
            for entry in sorted(root.iterdir()):
                if not entry.is_dir():
                    continue
                if prefix_filter and prefix_filter.lower() not in entry.name.lower():
                    continue
                resolved = entry.resolve()
                if resolved in seen:
                    continue
                seen.add(resolved)

                info = inspect_checkout(resolved, primary_repo_path=primary_repo, exclude_patterns=excludes)
                if info.get("is_git"):
                    results.append(info)
        except PermissionError:
            continue

    return results


def format_scan_table(checkouts: List[Dict[str, Any]]) -> str:
    """Formats checkout audit as a readable markdown table."""
    lines = [
        "| Directory | Type | Branch | Clean | Stashes | Unpushed | Disposition | Reason |",
        "|---|---|---|:---:|:---:|:---:|---|---|",
    ]
    for c in checkouts:
        clean_str = "✅" if c["is_clean"] else f"❌ ({c['dirty_count']})"
        stash_str = "0" if c["stash_count"] == 0 else f"⚠️ {c['stash_count']}"
        unpushed_str = "0" if not c["has_unpushed"] else f"⚠️ {len(c['unpushed_branches'])}"
        lines.append(
            f"| `{c['name']}` | {c['checkout_type']} | `{c['current_branch']}` | {clean_str} | {stash_str} | {unpushed_str} | **{c['disposition']}** | {c['disposition_reason']} |"
        )
    return "\n".join(lines)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Scan and audit Git worktrees and clones.")
    parser.add_argument("--root", action="append", help="Root directory to scan (defaults to standard repo roots)")
    parser.add_argument("--prefix", default="", help="Filter checkouts by name prefix/substring")
    parser.add_argument("--primary", default=None, help="Path to the primary working repo")
    parser.add_argument("--exclude", action="append", default=[], help="Pattern to exclude from teardown")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")

    args = parser.parse_args()

    search_roots = [Path(r).expanduser() for r in args.root] if args.root else DEFAULT_SAFE_ROOTS
    primary_repo = Path(args.primary).expanduser() if args.primary else Path.cwd()

    checkouts = scan_directories(search_roots, prefix_filter=args.prefix, primary_repo=primary_repo, excludes=args.exclude)

    if args.json:
        print(json.dumps(checkouts, indent=2))
    else:
        print(f"### Git Checkout Audit ({len(checkouts)} found)\n")
        print(format_scan_table(checkouts))


if __name__ == "__main__":
    main()
