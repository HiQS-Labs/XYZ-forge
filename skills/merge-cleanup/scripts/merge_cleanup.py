#!/usr/bin/env python3
"""merge_cleanup.py — Master orchestrator for the /merge-cleanup skill.

Implements the 6-phase ladder:
1. Discover & Inventory checkouts.
2. Active Process & Session Inspection.
3. Git Safety & Worktree Verification.
4. PR Matrix & Topological Sorting.
5. Safe Execution & Post-Merge Reconciliation.
6. Safe Teardown conforming strictly to WORKTREE-SAFETY.md.
"""

import os
import sys
import argparse
import subprocess
import shutil
from pathlib import Path
from typing import List, Dict, Any, Optional

from scan_clones import (
    DEFAULT_SAFE_ROOTS,
    DEFAULT_NEVER_DELETE,
    is_safe_deletable_path,
    scan_directories,
    format_scan_table,
    run_git
)
from toposort_prs import (
    fetch_open_prs,
    toposort_prs,
    format_pr_table
)


def log(msg: str):
    print(f"merge-cleanup: {msg}")


def log_warn(msg: str):
    print(f"merge-cleanup: WARNING — {msg}", file=sys.stderr)


def log_err(msg: str):
    print(f"merge-cleanup: ERROR — {msg}", file=sys.stderr)


def execute_pr_merge(pr_num: int, repo_path: Path, strategy: str = "squash", dry_run: bool = True) -> bool:
    """Merges a pull request via gh CLI."""
    if dry_run:
        log(f"[DRY RUN] Would merge PR #{pr_num} via `gh pr merge {pr_num} --{strategy} --delete-branch`")
        return True

    log(f"Merging PR #{pr_num} via `gh pr merge {pr_num} --{strategy} --delete-branch`...")
    cmd = ["gh", "pr", "merge", str(pr_num), f"--{strategy}", "--delete-branch"]
    res = subprocess.run(cmd, cwd=str(repo_path), capture_output=True, text=True, check=False)
    if res.returncode == 0:
        log(f"✅ Successfully merged PR #{pr_num}")
        return True
    else:
        log_err(f"Failed to merge PR #{pr_num}: {res.stderr.strip()}")
        return False


def run_post_merge_reconcile(pr_num: int, repo_path: Path, dry_run: bool = True) -> bool:
    """Executes wave_reconcile.py, RELEASES DB generation/check, and pdda issue-doc-sync."""
    if dry_run:
        log(f"[DRY RUN] Would run wave_reconcile.py --pr {pr_num} and RELEASES DB sync")
        return True

    log(f"Running post-merge reconciliation for PR #{pr_num} in {repo_path}...")

    # 1. wave_reconcile.py
    reconcile_script = repo_path / "utils" / "py" / "wave_reconcile.py"
    if reconcile_script.exists():
        r_cmd = [sys.executable, str(reconcile_script), "--pr", str(pr_num)]
        r_res = subprocess.run(r_cmd, cwd=str(repo_path), capture_output=True, text=True, check=False)
        if r_res.returncode == 0:
            log(f"✅ wave_reconcile for PR #{pr_num} passed")
        else:
            log_warn(f"wave_reconcile warning for PR #{pr_num}: {r_res.stderr.strip() or r_res.stdout.strip()}")

    # 2. releases_app.py gen & check
    releases_app = repo_path / "utils" / "py" / "releases_app.py"
    if releases_app.exists():
        subprocess.run([sys.executable, str(releases_app), "gen"], cwd=str(repo_path), capture_output=True, check=False)
        c_res = subprocess.run([sys.executable, str(releases_app), "check"], cwd=str(repo_path), capture_output=True, text=True, check=False)
        if c_res.returncode == 0:
            log("✅ RELEASES DB check passed")
        else:
            log_warn(f"RELEASES DB check warnings: {c_res.stdout.strip()}")

    # 3. pdda.sh issue-doc-sync
    pdda_sh = repo_path / "utils" / "pdda" / "pdda.sh"
    if pdda_sh.exists():
        p_res = subprocess.run(["bash", str(pdda_sh), "issue-doc-sync"], cwd=str(repo_path), capture_output=True, text=True, check=False)
        if p_res.returncode == 0:
            log("✅ pdda issue-doc-sync clean")
        else:
            log_warn(f"pdda issue-doc-sync output: {p_res.stdout.strip()}")

    return True


def teardown_checkout(checkout: Dict[str, Any], dry_run: bool = True) -> bool:
    """Safely tears down a worktree or standalone clone in strict compliance with WORKTREE-SAFETY.md."""
    path = Path(checkout["path"]).resolve()
    c_type = checkout["checkout_type"]
    disp = checkout["disposition"]

    if disp not in ("SAFE_REMOVE_WORKTREE", "SAFE_REMOVE_CLONE"):
        log(f"Skipping {path.name}: disposition is {disp} ({checkout['disposition_reason']})")
        return False

    is_safe, msg = is_safe_deletable_path(path)
    if not is_safe:
        log_err(f"Safety violation on {path}: {msg}")
        return False

    if c_type == "linked_worktree":
        parent_clone = checkout.get("parent_clone")
        if not parent_clone or not Path(parent_clone).exists():
            log_err(f"Cannot remove linked worktree {path}: parent clone not found")
            return False

        parent_path = Path(parent_clone)
        if dry_run:
            log(f"[DRY RUN] Would remove linked worktree via `git -C {parent_path} worktree remove {path}` + prune + repair")
            return True

        log(f"Removing linked worktree {path} from parent {parent_path}...")
        rem_res = run_git(parent_path, ["worktree", "remove", str(path)])
        if rem_res.returncode != 0:
            log_warn(f"`git worktree remove` failed ({rem_res.stderr.strip()}), retrying with prune...")

        run_git(parent_path, ["worktree", "prune"])
        run_git(parent_path, ["worktree", "repair"])
        log(f"✅ Cleaned linked worktree metadata for {path.name}")
        return True

    elif c_type == "standalone_clone":
        if dry_run:
            log(f"[DRY RUN] Would remove verified standalone clone: {path}")
            return True

        log(f"Removing verified clean standalone clone: {path}...")
        try:
            # Prefer Trash if available
            trash_dir = Path.home() / ".Trash"
            if trash_dir.exists() and trash_dir.is_dir():
                trash_target = trash_dir / f"{path.name}-{os.getpid()}"
                shutil.move(str(path), str(trash_target))
                log(f"✅ Moved clone {path.name} to Trash ({trash_target})")
            else:
                shutil.rmtree(path)
                log(f"✅ Removed clone directory {path}")
            return True
        except Exception as exc:
            log_err(f"Failed to remove clone directory {path}: {exc}")
            return False

    return False


def prune_dangling_skill_symlinks(dry_run: bool = True):
    """Scans ~/.claude/skills/ and ~/.gemini/**/skills/ for dangling symlinks."""
    search_dirs = [
        Path.home() / ".claude" / "skills",
        Path.home() / ".codex" / "skills",
        Path.home() / ".gemini" / "config" / "skills",
        Path.home() / ".gemini" / "antigravity" / "skills",
    ]

    for d in search_dirs:
        if not d.exists() or not d.is_dir():
            continue
        try:
            for item in d.iterdir():
                if item.is_symlink() and not item.exists():
                    target = os.readlink(item)
                    if dry_run:
                        log(f"[DRY RUN] Would remove dangling skill symlink: {item} -> {target}")
                    else:
                        item.unlink()
                        log(f"✅ Removed dangling skill symlink: {item}")
        except Exception as exc:
            log_warn(f"Error checking skill dir {d}: {exc}")


def main():
    parser = argparse.ArgumentParser(
        description="/merge-cleanup — Consolidate checkouts, sequence PRs, reconcile docs, and tear down safely."
    )
    parser.add_argument("--primary", default=None, help="Path to primary working repo (default: current directory)")
    parser.add_argument("--root", action="append", help="Root directory to search for checkouts")
    parser.add_argument("--prefix", default="", help="Filter checkouts by repo name substring")
    parser.add_argument("--exclude", action="append", default=[], help="Pattern or branch to exclude from cleanup")
    parser.add_argument("--strategy", choices=["squash", "merge", "rebase"], default="squash", help="PR merge strategy")
    parser.add_argument("--scan-only", action="store_true", help="Only audit and list checkouts")
    parser.add_argument("--prs-only", action="store_true", help="Only list and sequence open PRs")
    parser.add_argument("--teardown-only", action="store_true", help="Only perform checkout teardown (skip PR merges)")
    parser.add_argument("--reconcile-pr", type=int, default=0, help="Run post-merge reconcile on a specific PR number")
    parser.add_argument("--execute", action="store_true", help="Execute mutations (default is safe dry-run)")

    args = parser.parse_args()

    primary_repo = Path(args.primary).expanduser().resolve() if args.primary else Path.cwd().resolve()
    search_roots = [Path(r).expanduser().resolve() for r in args.root] if args.root else DEFAULT_SAFE_ROOTS
    dry_run = not args.execute

    log(f"Operating on primary repo: {primary_repo}")
    if dry_run:
        log("Running in SAFE DRY-RUN mode. Pass --execute to apply changes.")

    # Reconcile specific PR directly if requested
    if args.reconcile_pr > 0:
        run_post_merge_reconcile(args.reconcile_pr, primary_repo, dry_run=dry_run)
        return

    # Phase 1..3: Scan & Audit checkouts
    checkouts = scan_directories(search_roots, prefix_filter=args.prefix, primary_repo=primary_repo, excludes=args.exclude)
    print("\n" + "=" * 80)
    print(f"PHASE 1-3: CHECKOUT AUDIT & SAFETY STATUS ({len(checkouts)} found)")
    print("=" * 80 + "\n")
    print(format_scan_table(checkouts) + "\n")

    if args.scan_only:
        return

    # Phase 4: Open PR Sequencing
    prs = fetch_open_prs(str(primary_repo))
    ordered_prs: List[Dict[str, Any]] = []
    if prs:
        ordered_prs, _, warnings = toposort_prs(prs)
        print("=" * 80)
        print(f"PHASE 4: TOPOLOGICAL PR SEQUENCE ({len(ordered_prs)} open PRs)")
        print("=" * 80 + "\n")
        print(format_pr_table(ordered_prs) + "\n")
        if warnings:
            print("Ordering Notes:")
            for w in warnings:
                print(f"  - {w}")
            print()
    else:
        log("No open PRs found for this repository.")

    if args.prs_only:
        return

    # Phase 5: Execute Merges & Post-Merge Reconciliation (if not teardown-only)
    if not args.teardown_only and ordered_prs:
        print("=" * 80)
        print("PHASE 5: EXECUTING PR MERGES & RECONCILIATION")
        print("=" * 80 + "\n")
        for pr in ordered_prs:
            p_num = pr["number"]
            merged = execute_pr_merge(p_num, primary_repo, strategy=args.strategy, dry_run=dry_run)
            if merged:
                run_post_merge_reconcile(p_num, primary_repo, dry_run=dry_run)

        # Pull latest development into primary repo
        if not dry_run:
            log("Updating primary repo development branch...")
            run_git(primary_repo, ["fetch", "origin"])
            run_git(primary_repo, ["merge", "--ff-only", "origin/development"])

    # Phase 6: Safe Teardown
    print("=" * 80)
    print("PHASE 6: SAFE TEARDOWN & RECOVERY PRUNING")
    print("=" * 80 + "\n")
    removable = [c for c in checkouts if c["disposition"] in ("SAFE_REMOVE_WORKTREE", "SAFE_REMOVE_CLONE")]
    if not removable:
        log("No candidate checkouts qualify for safe removal (all are preserved or active).")
    else:
        for c in removable:
            teardown_checkout(c, dry_run=dry_run)

    # Prune dangling symlinks
    prune_dangling_skill_symlinks(dry_run=dry_run)
    print("\n" + "=" * 80)
    log("Merge cleanup run complete.")


if __name__ == "__main__":
    main()
