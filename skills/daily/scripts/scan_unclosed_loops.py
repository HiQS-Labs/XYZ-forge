#!/usr/bin/env python3
"""
scan_unclosed_loops.py — Deterministic Scanner for Unmerged Work, Un-PRed Branches,
and Open Pull Requests across the Operator's Repositories.

Supports two modes:
1. --mode daily (default): Maintained for /daily skill and temp/close-the-loop.md.
2. --mode shutdown: Two-pass discovery and liveness-based exclusion scanner for
   end-of-day triage and next-session handoff without modifying repositories.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
import zoneinfo


KNOWN_ACTIVE_ROOTS = (
    Path("/Users/noelsaw/Documents/GH Repos"),
    Path("/Users/noelsaw/Local Sites"),
    Path("/Users/noelsaw/marathon-clones"),
)

PRIMARY_WATCHED_REPOS = [
    "HiQS-Labs/rebalanceOS",
    "HiQS-Labs/XYZ-forge",
    "HiQS-Labs/AEGIS-Sleuth-Slackbot",
    "HiQS-Labs/Model-catalog",
    "NeochromeTeam/mac-buyers-guide-2.0",
    "NeochromeTeam/mac-buyers-guide-soc-families",
    "HiQS-Labs/LTVERA-PANDAS",
]

DEFAULT_EXCLUSIONS = [
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    "vendor",
    ".git",
    "Pods",
    "Carthage",
]


def run_cmd(cmd: list[str], cwd: Path | None = None, timeout: int = 10) -> tuple[int, str]:
    try:
        res = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return res.returncode, res.stdout.rstrip("\r\n")
    except Exception as e:
        return 1, str(e)


def find_repo_root(start_dir: Path | None = None) -> Path | None:
    cur = (start_dir or Path.cwd()).resolve()
    for p in [cur, *cur.parents]:
        if (p / ".git").exists() or (p / "pyproject.toml").exists():
            return p
    return None


def load_shutdown_config(config_arg: str | None = None) -> dict[str, Any]:
    resolved_path: Path | None = None
    if config_arg:
        resolved_path = Path(config_arg).expanduser().resolve()
    elif os.environ.get("REBALANCE_CONFIG"):
        resolved_path = Path(os.environ["REBALANCE_CONFIG"]).expanduser().resolve()
    else:
        root = find_repo_root()
        if root and (root / "temp" / "rbos.config").exists():
            resolved_path = root / "temp" / "rbos.config"

    cfg_dict: dict[str, Any] = {}
    if resolved_path and resolved_path.exists():
        try:
            cfg_dict = json.loads(resolved_path.read_text(encoding="utf-8"))
        except Exception:
            cfg_dict = {}

    shutdown_sec = cfg_dict.get("shutdown", {}) if isinstance(cfg_dict.get("shutdown"), dict) else {}

    raw_roots = shutdown_sec.get("scan_roots") or cfg_dict.get("repo_scan_roots") or cfg_dict.get("focus5_scan_roots")
    if isinstance(raw_roots, list) and raw_roots:
        scan_roots = [Path(r).expanduser().resolve() for r in raw_roots if Path(r).expanduser().exists()]
    else:
        scan_roots = [r for r in KNOWN_ACTIVE_ROOTS if r.exists()]

    exclusions = shutdown_sec.get("exclusions") or DEFAULT_EXCLUSIONS
    tz_str = shutdown_sec.get("timezone") or cfg_dict.get("pulse_timezone") or "America/New_York"
    output_home = shutdown_sec.get("output_home") or "temp/daily-log/shutdown"

    return {
        "config_path": str(resolved_path) if resolved_path else None,
        "scan_roots": scan_roots,
        "exclusions": list(set(exclusions + DEFAULT_EXCLUSIONS)),
        "timezone": tz_str,
        "output_home": output_home,
        "runtime_enabled": bool(shutdown_sec.get("runtime_enabled", False)),
    }


def compute_calendar_window(days: int = 3, tz_name: str = "America/New_York") -> dict[str, Any]:
    try:
        tz = zoneinfo.ZoneInfo(tz_name)
    except Exception:
        tz = timezone.utc

    now_local = datetime.now(tz)
    # days=3 means today + previous 2 calendar days -> subtract (days - 1)
    start_date = now_local.date() - timedelta(days=max(0, days - 1))
    start_local = datetime(start_date.year, start_date.month, start_date.day, 0, 0, 0, tzinfo=tz)

    start_utc = start_local.astimezone(timezone.utc)
    end_utc = now_local.astimezone(timezone.utc)

    return {
        "timezone": str(tz),
        "days": days,
        "start_local": start_local.isoformat(),
        "end_local": now_local.isoformat(),
        "start_utc": start_utc.isoformat(),
        "end_utc": end_utc.isoformat(),
        "start_epoch": int(start_utc.timestamp()),
        "end_epoch": int(end_utc.timestamp()),
    }


def discover_git_repos(
    roots: list[Path] | None = None,
    exclusions: list[str] | None = None,
    max_age_days: float | None = None,
    max_depth: int = 5,
) -> list[Path]:
    """Discover git repositories (.git dir or gitfile) across configured roots."""
    if roots is None:
        roots = [r for r in KNOWN_ACTIVE_ROOTS if r.exists()]
    if exclusions is None:
        exclusions = DEFAULT_EXCLUSIONS

    excl_set = set(exclusions)
    found: list[Path] = []
    cutoff = (time.time() - (max_age_days * 86400)) if max_age_days is not None else None

    for root in roots:
        if not root.exists():
            continue

        # Check if root itself is a git repo
        if (root / ".git").exists():
            if cutoff is None or (root.stat().st_mtime >= cutoff):
                found.append(root)

        root_depth = str(root.resolve()).count(os.sep)

        try:
            for dirpath, dirs, _ in os.walk(root, followlinks=False):
                p = Path(dirpath)
                cur_depth = str(p.resolve()).count(os.sep) - root_depth
                if cur_depth > max_depth:
                    dirs.clear()
                    continue

                # Prune excluded directories
                dirs[:] = [d for d in dirs if d not in excl_set and not d.startswith(".git")]

                if (p / ".git").exists() and p != root:
                    if cutoff is not None:
                        try:
                            if p.stat().st_mtime < cutoff:
                                continue
                        except OSError:
                            pass
                    found.append(p)
                    # Do not recurse into child repositories
                    dirs.clear()
        except OSError:
            pass

    return sorted(list(set(found)), key=lambda p: str(p))


def extract_canonical_remote(remote_url: str) -> str:
    if not remote_url:
        return ""
    clean = remote_url.strip()
    m = re.search(r"[:/]([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+?)(?:\.git)?$", clean)
    if m:
        return m.group(1)
    return clean


def inspect_git_repo(
    repo_path: Path,
    window: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Comprehensive inspection of local git state across all branches and working trees."""
    # Current branch
    _, branch = run_cmd(["git", "branch", "--show-current"], cwd=repo_path)
    branch = branch or "detached"

    # Canonical remote URL
    _, remote_url = run_cmd(["git", "config", "--get", "remote.origin.url"], cwd=repo_path)
    canonical_remote = extract_canonical_remote(remote_url) if remote_url else repo_path.name

    # Git common dir (resolves shared worktrees)
    code_comm, comm_dir_out = run_cmd(["git", "rev-parse", "--git-common-dir"], cwd=repo_path)
    if code_comm == 0 and comm_dir_out:
        common_dir = str(Path(comm_dir_out if os.path.isabs(comm_dir_out) else (repo_path / comm_dir_out)).resolve())
    else:
        common_dir = str((repo_path / ".git").resolve())

    # Full status porcelain v1
    code_s, s_out = run_cmd(["git", "status", "--porcelain=v1", "-uall"], cwd=repo_path)
    status_lines = [line for line in s_out.splitlines() if line.strip()] if code_s == 0 else []

    staged_files = []
    unstaged_files = []
    untracked_files = []
    deleted_files = []

    for line in status_lines:
        if len(line) < 3:
            continue
        code_xy = line[:2]
        filepath = line[3:].strip()
        if " -> " in filepath:
            filepath = filepath.split(" -> ")[1].strip()
        if code_xy[0] in "MADRC":
            staged_files.append(filepath)
        if code_xy[1] in "MD":
            unstaged_files.append(filepath)
        if code_xy == "??":
            untracked_files.append(filepath)
        if "D" in code_xy:
            deleted_files.append(filepath)

    dirty_count = len(status_lines)

    # Branches inspection
    code_refs, refs_out = run_cmd(
        [
            "git",
            "for-each-ref",
            "--format=%(refname:short)|%(upstream:short)|%(objectname)|%(committerdate:raw)",
            "refs/heads/",
        ],
        cwd=repo_path,
    )
    branches_info = []
    unpushed_branches = []
    unpred_branches = []

    if code_refs == 0 and refs_out:
        for ref_line in refs_out.splitlines():
            parts = ref_line.split("|")
            if len(parts) >= 4:
                b_name, b_upstream, b_sha = parts[0], parts[1], parts[2]
                ahead, behind = 0, 0
                upstream_status = "present" if b_upstream else "missing"

                if b_upstream:
                    c_ab, ab_out = run_cmd(
                        ["git", "rev-list", "--left-right", "--count", f"{b_upstream}...{b_name}"],
                        cwd=repo_path,
                    )
                    if c_ab == 0 and len(ab_out.split()) == 2:
                        p_ab = ab_out.split()
                        behind, ahead = int(p_ab[0]), int(p_ab[1])
                else:
                    c_cnt, cnt_out = run_cmd(["git", "rev-list", "--count", b_name], cwd=repo_path)
                    ahead = int(cnt_out) if (c_cnt == 0 and cnt_out.isdigit()) else 1

                b_dict = {
                    "branch": b_name,
                    "upstream": b_upstream,
                    "upstream_status": upstream_status,
                    "sha": b_sha,
                    "ahead": ahead,
                    "behind": behind,
                }
                branches_info.append(b_dict)

                if ahead > 0:
                    unpushed_branches.append(
                        {
                            "repo": repo_path.name,
                            "canonical_remote": canonical_remote,
                            "branch": b_name,
                            "ahead": ahead,
                            "upstream": b_upstream,
                        }
                    )

                if b_name not in ("main", "master", "development") and ahead > 0:
                    unpred_branches.append(
                        {
                            "repo": repo_path.name,
                            "canonical_remote": canonical_remote,
                            "branch": b_name,
                            "ahead": ahead,
                        }
                    )

    # Worktrees
    _, wt_out = run_cmd(["git", "worktree", "list", "--porcelain"], cwd=repo_path)
    worktrees = []
    current_wt: dict[str, str] = {}
    for line in wt_out.splitlines():
        if line.startswith("worktree "):
            if current_wt:
                worktrees.append(current_wt)
            current_wt = {"path": line[9:].strip()}
        elif line.startswith("branch "):
            current_wt["branch"] = line[7:].strip().replace("refs/heads/", "")
        elif line.startswith("bare"):
            current_wt["bare"] = "true"
        elif line.startswith("detached"):
            current_wt["detached"] = "true"
    if current_wt:
        worktrees.append(current_wt)

    # Commits within window
    recent_commits = []
    if window:
        start_iso = window.get("start_utc", "")
        end_iso = window.get("end_utc", "")
        code_log, log_out = run_cmd(
            [
                "git",
                "log",
                f"--since={start_iso}",
                f"--until={end_iso}",
                "--all",
                "--format=%H|%ct|%s|%an",
                "-n",
                "50",
            ],
            cwd=repo_path,
        )
        if code_log == 0 and log_out:
            for log_line in log_out.splitlines():
                lp = log_line.split("|")
                if len(lp) >= 4:
                    recent_commits.append(
                        {
                            "sha": lp[0],
                            "epoch": int(lp[1]) if lp[1].isdigit() else 0,
                            "message": lp[2],
                            "author": lp[3],
                        }
                    )

    # Recent reflog
    recent_reflog = []
    if window:
        start_iso = window.get("start_utc", "")
        code_rf, rf_out = run_cmd(
            ["git", "reflog", f"--since={start_iso}", "-n", "10", "--format=%gd|%gs|%ct"],
            cwd=repo_path,
        )
        if code_rf == 0 and rf_out:
            for rf_line in rf_out.splitlines():
                lp = rf_line.split("|")
                if len(lp) >= 3:
                    recent_reflog.append({"ref": lp[0], "action": lp[1], "epoch": int(lp[2]) if lp[2].isdigit() else 0})

    # Age of HEAD commit
    _, log_epoch = run_cmd(["git", "log", "-1", "--format=%ct"], cwd=repo_path)
    age_days = (time.time() - int(log_epoch)) / 86400 if log_epoch.isdigit() else 999.0

    # Active lock files
    git_dir = Path(common_dir)
    known_locks = ["index.lock", "HEAD.lock", "relay-driver.lock", "releases-app.lock"]
    active_locks = [lock_name for lock_name in known_locks if (git_dir / lock_name).exists()]

    # Undated unresolved classification
    is_undated_unresolved = False
    if (dirty_count > 0 or len(unpushed_branches) > 0) and not recent_commits and age_days > 3.0:
        is_undated_unresolved = True

    git_error = code_s != 0 or code_refs != 0

    return {
        "path": str(repo_path),
        "name": repo_path.name,
        "canonical_remote": canonical_remote,
        "common_dir": common_dir,
        "branch": branch,
        "dirty_count": dirty_count,
        "dirty_sample": status_lines[:5],
        "staged_files": staged_files,
        "unstaged_files": unstaged_files,
        "untracked_files": untracked_files,
        "deleted_files": deleted_files,
        "branches": branches_info,
        "unpushed_branches": unpushed_branches,
        "unpred_branches": unpred_branches,
        "worktrees": worktrees,
        "recent_commits": recent_commits,
        "recent_reflog": recent_reflog,
        "age_days": round(age_days, 1),
        "active_locks": active_locks,
        "is_undated_unresolved": is_undated_unresolved,
        "git_error": git_error,
    }


def get_repo_fingerprint(
    repo_path: Path,
    max_file_bytes: int = 10 * 1024 * 1024,
    max_repo_bytes: int = 100 * 1024 * 1024,
) -> dict[str, Any]:
    """Compute a quick bounded fingerprint of a repository to detect active concurrent edits."""
    code_head, head_sha = run_cmd(["git", "rev-parse", "HEAD"], cwd=repo_path)
    code_status, status_raw = run_cmd(["git", "status", "--porcelain=v1", "-uall"], cwd=repo_path)
    code_refs, refs_raw = run_cmd(
        ["git", "for-each-ref", "--format=%(refname) %(objectname)", "refs/heads/"], cwd=repo_path
    )
    _, stash_raw = run_cmd(["git", "rev-parse", "-q", "--verify", "refs/stash"], cwd=repo_path)

    git_error = code_status != 0 or code_refs != 0 or code_head != 0
    uncertain = git_error

    dirty_files_meta: list[tuple[str, int, int, str]] = []
    total_bytes_hashed = 0

    if code_status == 0:
        for line in status_raw.splitlines():
            if len(line) >= 3:
                filepath = line[3:].strip()
                if " -> " in filepath:
                    filepath = filepath.split(" -> ")[1].strip()
                fpath = repo_path / filepath
                try:
                    if fpath.is_file():
                        st = fpath.stat()
                        content_hash = ""
                        remaining = max(0, max_repo_bytes - total_bytes_hashed)
                        read_len = min(st.st_size, max_file_bytes, remaining)
                        if read_len > 0:
                            try:
                                with open(fpath, "rb") as f:
                                    chunk = f.read(read_len)
                                content_hash = hashlib.sha256(chunk).hexdigest()
                                total_bytes_hashed += len(chunk)
                            except OSError:
                                uncertain = True
                        dirty_files_meta.append((filepath, st.st_size, int(st.st_mtime), content_hash))
                except OSError:
                    uncertain = True

    # Check lock files
    git_dir = repo_path / ".git"
    if git_dir.is_file():
        try:
            content = git_dir.read_text(encoding="utf-8").strip()
            if content.startswith("gitdir: "):
                git_dir = Path(content[8:].strip())
        except OSError:
            pass

    locks = []
    for lock_name in ["index.lock", "HEAD.lock", "relay-driver.lock", "releases-app.lock"]:
        if (git_dir / lock_name).exists():
            locks.append(lock_name)

    hasher = hashlib.sha256()
    hasher.update(head_sha.encode())
    hasher.update(status_raw.encode())
    hasher.update(refs_raw.encode())
    hasher.update(stash_raw.encode())
    for item in sorted(dirty_files_meta):
        hasher.update(f"{item[0]}:{item[1]}:{item[2]}:{item[3]}".encode())
    for lock_name in sorted(locks):
        hasher.update(lock_name.encode())

    return {
        "path": str(repo_path),
        "head_sha": head_sha,
        "status_count": len([line for line in status_raw.splitlines() if line.strip()]),
        "refs_raw": refs_raw,
        "stash_raw": stash_raw,
        "dirty_files_meta": dirty_files_meta,
        "locks": locks,
        "hash": hasher.hexdigest(),
        "git_error": git_error,
        "uncertain": uncertain,
    }


def fetch_prs_for_remotes(
    remotes: list[str],
    timeout: int = 10,
    max_prs_per_remote: int = 1000,
) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    """Fetch open and recent PRs for discovered remotes with bounded timeouts."""
    prs_by_remote: dict[str, list[dict[str, Any]]] = {}
    errors: list[dict[str, Any]] = []

    for remote in sorted(list(set(remotes))):
        if not remote or "/" not in remote:
            continue
        code, out = run_cmd(
            [
                "gh",
                "pr",
                "list",
                "--repo",
                remote,
                "--state",
                "all",
                "--limit",
                str(max_prs_per_remote),
                "--json",
                "number,title,headRefName,baseRefName,updatedAt,url,author,isDraft,state,mergedAt",
            ],
            timeout=timeout,
        )
        if code == 0 and out:
            try:
                items = json.loads(out)
                for it in items:
                    it["repo"] = remote
                prs_by_remote[remote] = items
            except Exception as e:
                errors.append({"remote": remote, "error": f"JSON decode error: {e}"})
        elif code != 0:
            errors.append({"remote": remote, "error": out or "gh pr list non-zero exit"})

    return prs_by_remote, errors


def run_two_pass_scan(
    roots: list[Path],
    exclusions: list[str],
    window: dict[str, Any],
    delay_seconds: float = 30.0,
) -> dict[str, Any]:
    """Execute Snapshot A, wait delay, execute Snapshot B, and compute exclusions."""
    # Snapshot A
    repos_A = discover_git_repos(roots=roots, exclusions=exclusions)
    fingerprints_A = {str(r): get_repo_fingerprint(r) for r in repos_A}
    inspections_A = {str(r): inspect_git_repo(r, window=window) for r in repos_A}

    if delay_seconds > 0:
        time.sleep(delay_seconds)

    # Snapshot B
    repos_B = discover_git_repos(roots=roots, exclusions=exclusions)
    fingerprints_B = {str(r): get_repo_fingerprint(r) for r in repos_B}
    inspections_B = {str(r): inspect_git_repo(r, window=window) for r in repos_B}

    set_A = set(fingerprints_A.keys())
    set_B = set(fingerprints_B.keys())

    active_paths: set[str] = set()
    activity_reasons: dict[str, list[str]] = {}

    disappeared = set_A - set_B
    newly_created = set_B - set_A
    for p in disappeared:
        active_paths.add(p)
        activity_reasons.setdefault(p, []).append("Repo disappeared between snapshots (concurrent delete/move)")
    for p in newly_created:
        active_paths.add(p)
        activity_reasons.setdefault(p, []).append("Repo appeared between snapshots (concurrent clone/create)")

    for p in set_A & set_B:
        f_a = fingerprints_A[p]
        f_b = fingerprints_B[p]
        reasons = []

        if f_a.get("git_error") or f_b.get("git_error") or f_a.get("uncertain") or f_b.get("uncertain"):
            reasons.append("Failed Git command or unreadable repository state during scan pass")

        if f_a["hash"] != f_b["hash"]:
            if f_a["head_sha"] != f_b["head_sha"]:
                reasons.append(f"HEAD changed: {f_a['head_sha'][:7]} -> {f_b['head_sha'][:7]}")
            if f_a["refs_raw"] != f_b["refs_raw"]:
                reasons.append("Local branch refs modified")
            if f_a["status_count"] != f_b["status_count"]:
                reasons.append(f"Dirty status line count changed ({f_a['status_count']} -> {f_b['status_count']})")
            if f_a["dirty_files_meta"] != f_b["dirty_files_meta"]:
                reasons.append("Dirty/untracked file content, mtime, or size changed (content edit)")
            if not reasons:
                reasons.append("Fingerprint hash divergence between snapshots")

        locks = f_b.get("locks", [])
        if locks:
            reasons.append(f"Active lock files detected: {', '.join(locks)}")

        insp_b = inspections_B.get(p)
        if insp_b and insp_b.get("git_error"):
            reasons.append("Failed Git command during repository inspection")

        if reasons:
            active_paths.add(p)
            activity_reasons[p] = reasons

    active_remotes: set[str] = set()
    active_commondirs: set[str] = set()
    for p in active_paths:
        insp = inspections_B.get(p) or inspections_A.get(p)
        if insp:
            if insp.get("canonical_remote"):
                active_remotes.add(insp["canonical_remote"])
            if insp.get("common_dir"):
                active_commondirs.add(insp["common_dir"])

    excluded_repos: list[dict[str, Any]] = []
    stable_repos: list[dict[str, Any]] = []

    for p in sorted(list(set_B)):
        insp = inspections_B[p]
        remote = insp.get("canonical_remote", "")
        cdir = insp.get("common_dir", "")

        is_group_active = (p in active_paths) or (remote in active_remotes) or (cdir in active_commondirs)

        repo_entry = dict(insp)
        repo_entry["is_active"] = is_group_active
        reasons = activity_reasons.get(p, [])
        if not reasons and is_group_active:
            reasons = [f"Sibling clone or worktree is active ({remote or cdir})"]
        repo_entry["activity_reasons"] = reasons

        if is_group_active:
            excluded_repos.append(repo_entry)
        else:
            stable_repos.append(repo_entry)

    return {
        "snapshot_a_count": len(set_A),
        "snapshot_b_count": len(set_B),
        "delay_seconds": delay_seconds,
        "active_paths": sorted(list(active_paths)),
        "stable_repos": stable_repos,
        "excluded_repos": excluded_repos,
        "all_inspections": inspections_B,
    }


def update_close_the_loop_ledger(
    ledger_path: Path, local_issues: list[dict[str, Any]], open_prs: list[dict[str, Any]]
) -> None:
    """Update temp/close-the-loop.md with latest in-flight loops while preserving manual triage."""
    now_str = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %Z")

    content = [
        "# Close-the-Loop Ledger (Active & Pending Loops)",
        "",
        f"_Last updated: {now_str}_",
        "",
        "This ledger tracks all unmerged branches, dangling worktree commits, unlanded PRs, and cleanup tasks across all active and legacy repositories.",
        "",
        "---",
        "",
        "## 🚨 Tier 1: Active In-Flight Work (Current Sprint / Today)",
        "",
        "| Repo | Item / Branch | Status / Blocker | Next Immediate Action |",
        "|---|---|---|---|",
    ]

    for item in local_issues:
        content.append(f"| **`{item['repo']}`** | `{item['branch_or_wt']}` | {item['status']} | {item['action']} |")

    content.extend(
        [
            "",
            "---",
            "",
            "## ⏳ Tier 2: Open & Pending Pull Requests (Primary Watched Repos)",
            "",
        ]
    )

    if open_prs:
        for pr in open_prs:
            content.append(
                f"- [ ] [{pr['repo']}#{pr['number']}]({pr['url']}) — `{pr['headRefName']}`: {pr['title']} (Updated: {pr['updatedAt'][:10]})"
            )
    else:
        content.append("_No open pull requests currently pending on primary watched repositories._")

    content.extend(
        [
            "",
            "---",
            "",
            "## 🧹 Maintenance Discipline (How to Keep This Clear)",
            "1. **Never leave a branch un-PRed**: As soon as a worktree commit lands (`/relay-xyz` QA pass), open the PR immediately.",
            "2. **Post-Merge Cleanup**: When a PR merges, run `/merge-cleanup` to remove stale worktrees and isolated clone folders.",
            "3. **Daily Sweep**: During `/daily` cycles, surface items that have been open for $\\ge 4$ cycles ($>60\\text{m}$).",
            "",
        ]
    )

    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    ledger_path.write_text("\n".join(content), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan and report unclosed loops across repositories")
    parser.add_argument(
        "--mode", choices=["daily", "shutdown"], default="daily", help="Operating mode: daily (default) or shutdown"
    )
    parser.add_argument("--json", action="store_true", help="Output raw JSON analysis")
    parser.add_argument("--summary-line", action="store_true", help="Output the 1-line markdown summary")
    parser.add_argument("--update-ledger", action="store_true", default=False, help="Update temp/close-the-loop.md")
    parser.add_argument("--no-ledger-write", action="store_true", help="Force no-ledger-write invariant")
    parser.add_argument("--config", type=str, help="Explicit path to configuration file (e.g. temp/rbos.config)")
    parser.add_argument(
        "--output-dir",
        "--output-home",
        dest="output_dir",
        type=str,
        help="Override output directory for shutdown handoff artifacts",
    )
    parser.add_argument(
        "--days", type=int, default=3, help="Calendar day window (default 3: today + 2 previous local days)"
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=None,
        help="Delay between snapshots in seconds (default 30 for shutdown, 0 for daily)",
    )
    args = parser.parse_args()

    cfg = load_shutdown_config(args.config)
    if args.output_dir:
        cfg["output_home"] = args.output_dir
    window = compute_calendar_window(days=args.days, tz_name=cfg["timezone"])

    if args.mode == "shutdown":
        # Shutdown mode: two-pass scan, no ledger write ever
        delay = args.delay if args.delay is not None else 30.0
        two_pass = run_two_pass_scan(
            roots=cfg["scan_roots"],
            exclusions=cfg["exclusions"],
            window=window,
            delay_seconds=delay,
        )

        all_inspections = two_pass["stable_repos"] + two_pass["excluded_repos"]
        discovered_remotes = [insp["canonical_remote"] for insp in all_inspections if insp.get("canonical_remote")]
        prs_by_remote, pr_errors = fetch_prs_for_remotes(discovered_remotes)
        pr_error_remotes = {e.get("remote") for e in pr_errors if e.get("remote")}

        # Build grouped project representation
        projects_map: dict[str, dict[str, Any]] = {}
        for insp in all_inspections:
            r_name = insp.get("canonical_remote") or insp["name"]
            if r_name not in projects_map:
                all_prs = prs_by_remote.get(r_name, [])
                open_prs = [p for p in all_prs if p.get("state", "OPEN").upper() == "OPEN"]
                projects_map[r_name] = {
                    "canonical_remote": r_name,
                    "physical_clones": [],
                    "is_active": False,
                    "activity_reasons": [],
                    "branches": [],
                    "dirty_files_count": 0,
                    "recent_commits": [],
                    "open_prs": open_prs,
                    "all_prs": all_prs,
                    "is_undated_unresolved": False,
                }
            proj = projects_map[r_name]
            proj["physical_clones"].append(insp["path"])
            if insp["is_active"]:
                proj["is_active"] = True
                proj["activity_reasons"].extend(insp.get("activity_reasons", []))
            proj["dirty_files_count"] += insp["dirty_count"]

            # Deduplicate recent commits by SHA
            existing_shas = {c["sha"] for c in proj["recent_commits"]}
            for c in insp.get("recent_commits", []):
                if c["sha"] not in existing_shas:
                    proj["recent_commits"].append(c)
                    existing_shas.add(c["sha"])

            if insp.get("is_undated_unresolved"):
                proj["is_undated_unresolved"] = True

            for b in insp.get("branches", []):
                existing_branch_names = {eb["branch"] for eb in proj["branches"]}
                if b["branch"] in existing_branch_names:
                    continue

                matched_pr = next((p for p in proj.get("all_prs", []) if p.get("headRefName") == b["branch"]), None)
                b_augmented = dict(b)
                if matched_pr:
                    pr_state = matched_pr.get("state", "OPEN").upper()
                    if pr_state == "MERGED":
                        b_augmented["pr_status"] = "merged"
                    elif pr_state == "CLOSED":
                        b_augmented["pr_status"] = "closed"
                    else:
                        b_augmented["pr_status"] = "open"
                    b_augmented["pr_number"] = matched_pr["number"]
                    b_augmented["pr_url"] = matched_pr["url"]
                    if matched_pr.get("mergedAt"):
                        b_augmented["merged_at"] = matched_pr["mergedAt"]
                elif r_name in pr_error_remotes:
                    b_augmented["pr_status"] = "unknown"
                elif b["branch"] in ("main", "master", "development"):
                    b_augmented["pr_status"] = "integration_branch"
                else:
                    b_augmented["pr_status"] = "unpred"
                proj["branches"].append(b_augmented)

        shutdown_payload = {
            "mode": "shutdown",
            "generated_at": datetime.now().astimezone().isoformat(),
            "config_path": cfg["config_path"],
            "output_home": cfg["output_home"],
            "window": window,
            "summary": {
                "discovered_clones": len(all_inspections),
                "stable_repos_count": len(two_pass["stable_repos"]),
                "excluded_active_count": len(two_pass["excluded_repos"]),
                "active_paths": two_pass["active_paths"],
            },
            "projects": list(projects_map.values()),
            "stable_repos": two_pass["stable_repos"],
            "excluded_repos": two_pass["excluded_repos"],
            "pr_query_errors": pr_errors,
            "coverage_limits": [
                "Read events without journal not recoverable",
                "Ignored files (.gitignore) not tracked",
                "Transient edits between pass A and B only detected by size/mtime/sha diff",
            ],
        }

        print(json.dumps(shutdown_payload, indent=2))
        return 0

    # Daily mode (backward-compatible)
    repos = discover_git_repos(roots=cfg["scan_roots"], exclusions=cfg["exclusions"], max_age_days=7.0)
    repo_stats = [inspect_git_repo(r, window=window) for r in repos]

    open_prs = []
    prs_by_remote, _ = fetch_prs_for_remotes(PRIMARY_WATCHED_REPOS)
    for r_prs in prs_by_remote.values():
        for p in r_prs:
            if p.get("state", "OPEN").upper() == "OPEN":
                open_prs.append(p)

    unpred_branches: list[dict[str, str]] = []
    unpushed_branches: list[dict[str, str]] = []
    dirty_repos: list[dict[str, Any]] = []
    active_worktrees: list[dict[str, str]] = []

    for r in repo_stats:
        linked_worktrees = r["worktrees"][1:] if len(r["worktrees"]) > 1 else []
        for wt in linked_worktrees:
            active_worktrees.append({"repo": r["name"], "wt": wt.get("path", "")})
            if wt.get("branch"):
                unpred_branches.append({"repo": r["name"], "branch": wt["branch"], "wt_desc": str(wt)})

        for up in r["unpushed_branches"]:
            unpushed_branches.append(up)

        if r["dirty_count"] > 0 and r["age_days"] <= 3.0:
            dirty_repos.append({"repo": r["name"], "count": r["dirty_count"]})

    local_issues = []
    for item in unpred_branches:
        local_issues.append(
            {
                "repo": item["repo"],
                "branch_or_wt": item["branch"],
                "status": "Linked worktree active; verify if PR is open",
                "action": "Push & cut PR or run /merge-cleanup if merged",
            }
        )
    for item in unpushed_branches:
        local_issues.append(
            {
                "repo": item["repo"],
                "branch_or_wt": item["branch"],
                "status": f"{item.get('ahead', 1)} unpushed commit(s) ahead of origin",
                "action": "Push commits to remote origin",
            }
        )

    should_update_ledger = args.update_ledger and not args.no_ledger_write
    ledger_file = Path(find_repo_root() or Path.cwd()) / "temp" / "close-the-loop.md"
    if should_update_ledger:
        update_close_the_loop_ledger(ledger_file, local_issues, open_prs)

    unpred_count = len(unpred_branches)
    open_pr_count = len(open_prs)
    unpushed_count = len(unpushed_branches)

    parts = []
    if unpred_count > 0:
        names = ", ".join(f"`{x['repo']}:{x['branch']}`" for x in unpred_branches[:2])
        parts.append(f"{unpred_count} un-PRed branch{'es' if unpred_count > 1 else ''} ({names})")
    else:
        parts.append("0 un-PRed branches")

    if open_pr_count > 0:
        sample_prs = ", ".join(f"`{p['repo']}#{p['number']}`" for p in open_prs[:2])
        parts.append(f"{open_pr_count} open PR{'s' if open_pr_count > 1 else ''} ({sample_prs})")
    else:
        parts.append("0 open PRs")

    if unpushed_count > 0:
        parts.append(f"{unpushed_count} unpushed branch{'es' if unpushed_count > 1 else ''}")
    else:
        parts.append("0 unpushed commits")

    summary_line = f"- **Unclosed Loops**: {', '.join(parts)} `[Details: temp/close-the-loop.md]`"

    if args.json:
        payload = {
            "summary_line": summary_line,
            "counts": {
                "unpred_branches": unpred_count,
                "open_prs": open_pr_count,
                "unpushed_branches": unpushed_count,
                "active_worktrees": len(active_worktrees),
                "dirty_repos": len(dirty_repos),
            },
            "unpred_branches": unpred_branches,
            "open_prs": open_prs,
            "unpushed_branches": unpushed_branches,
            "ledger_path": str(ledger_file),
        }
        print(json.dumps(payload, indent=2))
    else:
        print(summary_line)

    return 0


if __name__ == "__main__":
    sys.exit(main())
