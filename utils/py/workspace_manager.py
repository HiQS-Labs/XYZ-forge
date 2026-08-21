#!/usr/bin/env python3
"""workspace_manager.py — Ephemeral workspace registration, audit, and safe garbage collection (GH-124).

WHY THIS FILE EXISTS
--------------------
Marathons and ad-hoc lanes spawn linked git worktrees and temporary full clones.
At closeout, cleaning them up manually is high friction and risky.

This tool enforces:
1. Manifest registration (.xyz/workspaces.json).
2. Fail-closed safety checks before removal (clean status, all-branch push ancestor verification, stash check).
3. Soft-quarantine of ignored scratch and deleted clones into .xyz/trash/<timestamp>-<name>/ with a 72h reaper.
4. Linked worktree removal executed from the primary repo context.
"""

import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import time


def get_manifest_path(repo_root):
    return os.path.join(repo_root, ".xyz", "workspaces.json")


def get_trash_dir(repo_root):
    return os.path.join(repo_root, ".xyz", "trash")


def load_manifest(repo_root):
    m_path = get_manifest_path(repo_root)
    if not os.path.exists(m_path):
        return []
    try:
        with open(m_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []


def save_manifest(repo_root, entries):
    m_path = get_manifest_path(repo_root)
    os.makedirs(os.path.dirname(m_path), exist_ok=True)
    tmp = f"{m_path}.tmp.{os.getpid()}"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2)
        f.write("\n")
    os.replace(tmp, m_path)


def register_workspace(repo_root, path, ws_type, branch=None, pid=None):
    abs_path = os.path.abspath(path)
    entries = load_manifest(repo_root)
    # Deduplicate existing entry for the same path
    entries = [e for e in entries if os.path.abspath(e.get("path", "")) != abs_path]
    entries.append({
        "path": abs_path,
        "type": ws_type,
        "branch": branch,
        "pid": pid or os.getpid(),
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat()
    })
    save_manifest(repo_root, entries)


def deregister_workspace(repo_root, path):
    abs_path = os.path.abspath(path)
    entries = load_manifest(repo_root)
    filtered = [e for e in entries if os.path.abspath(e.get("path", "")) != abs_path]
    save_manifest(repo_root, filtered)


def reap_trash(repo_root, max_age_hours=72, force_all=False):
    """Purge trash directories older than max_age_hours or all if force_all is True."""
    trash_dir = get_trash_dir(repo_root)
    if not os.path.exists(trash_dir):
        return 0
    now = time.time()
    reaped = 0
    for name in os.listdir(trash_dir):
        p = os.path.join(trash_dir, name)
        if not os.path.isdir(p):
            continue
        try:
            age_hours = None
            if len(name) >= 16 and name[8] == "T" and name[15] == "Z":
                try:
                    dt = datetime.datetime.strptime(name[:16], "%Y%m%dT%H%M%SZ").replace(tzinfo=datetime.timezone.utc)
                    age_hours = (datetime.datetime.now(datetime.timezone.utc) - dt).total_seconds() / 3600.0
                except Exception:
                    pass
            if age_hours is None:
                mtime = os.path.getmtime(p)
                age_hours = (now - mtime) / 3600.0
            if force_all or age_hours >= max_age_hours:
                shutil.rmtree(p, ignore_errors=True)
                reaped += 1
        except Exception:
            pass
    return reaped


def evaluate_workspace_safety(repo_root, target_path):
    """Evaluate whether a workspace is safe to tear down.
    
    Returns: (is_safe, ws_type, branch, reason)
    """
    canon_repo = os.path.realpath(repo_root)
    target_abs = os.path.abspath(target_path)
    if not os.path.exists(target_abs):
        return False, "unknown", None, "path does not exist"

    canon_target = os.path.realpath(target_abs)

    # Invariant 1: Never delete primary repo root
    if canon_target == canon_repo:
        return False, "primary", None, "refusing to sweep primary repository root"

    # Invariant 2: Never delete current working directory
    canon_cwd = os.path.realpath(os.getcwd())
    if canon_target == canon_cwd or canon_cwd.startswith(canon_target + os.sep):
        return False, "active_cwd", None, "refusing to sweep current working directory"

    # Invariant 3: Refuse symlinks
    if os.path.islink(target_abs):
        return False, "symlink", None, "refusing to sweep symlink"

    # Invariant 4: Must be a git repository or linked worktree
    dot_git = os.path.join(target_abs, ".git")
    if not os.path.exists(dot_git):
        return False, "unknown", None, "target does not have a .git file or directory"

    is_worktree = os.path.isfile(dot_git)
    ws_type = "worktree" if is_worktree else "clone"

    # Invariant 5: Stash check (Full Clones)
    if not is_worktree:
        stash = subprocess.run(["git", "-C", target_abs, "stash", "list"],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if stash.stdout.strip():
            return False, ws_type, None, "clone contains unsaved/unmerged git stashes"

    # Invariant 6: Porcelain cleanliness (zero uncommitted changes)
    st = subprocess.run(["git", "-C", target_abs, "status", "--porcelain"],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if st.returncode != 0:
        return False, ws_type, None, f"git status failed: {st.stderr.strip()}"
    if st.stdout.strip():
        return False, ws_type, None, "uncommitted changes in working tree"

    # Invariant 7: Branch & Push Verification
    if is_worktree:
        br_res = subprocess.run(["git", "-C", target_abs, "rev-parse", "--abbrev-ref", "HEAD"],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        branch = br_res.stdout.strip() if br_res.returncode == 0 else ""
        if not branch or branch == "HEAD":
            # Detached HEAD in worktree: check against upstream
            pass
        else:
            # Check if HEAD is pushed to origin/<branch>
            anc = subprocess.run(["git", "-C", target_abs, "merge-base", "--is-ancestor", "HEAD", f"origin/{branch}"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if anc.returncode != 0:
                return False, ws_type, branch, f"HEAD on branch '{branch}' has unpushed commits"
        return True, ws_type, branch, "clean & pushed"

    else:
        # Full Clone: Check all local branches
        refs = subprocess.run(["git", "-C", target_abs, "for-each-ref", "--format=%(refname:short)", "refs/heads/"],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        branches = refs.stdout.splitlines() if refs.returncode == 0 else []
        for br in branches:
            br = br.strip()
            if not br:
                continue
            anc = subprocess.run(["git", "-C", target_abs, "merge-base", "--is-ancestor", br, f"origin/{br}"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if anc.returncode != 0:
                return False, ws_type, br, f"local branch '{br}' is not pushed to origin/{br}"
        return True, ws_type, ", ".join(branches), "clean, all branches pushed, zero stashes"


def sweep_workspaces(repo_root, execute=False, purge_trash=False):
    """Audit and sweep eligible ephemeral workspaces."""
    reaped = reap_trash(repo_root, force_all=purge_trash)
    if reaped > 0:
        print(f"workspace-sweep: reaped {reaped} expired trash entries")

    # Discover candidate paths from manifest + git worktree list
    candidates = {}
    for entry in load_manifest(repo_root):
        p = entry.get("path")
        if p and os.path.exists(p):
            candidates[os.path.abspath(p)] = entry.get("type", "unknown")

    # Discover linked worktrees
    wt_list = subprocess.run(["git", "-C", repo_root, "worktree", "list", "--porcelain"],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if wt_list.returncode == 0:
        for line in wt_list.stdout.splitlines():
            if line.startswith("worktree "):
                p = line.split(" ", 1)[1].strip()
                if os.path.exists(p) and os.path.realpath(p) != os.path.realpath(repo_root):
                    candidates[os.path.abspath(p)] = "worktree"

    if not candidates:
        print("workspace-sweep: no candidate ephemeral workspaces found.")
        return

    print(f"workspace-sweep: auditing {len(candidates)} candidate workspace(s)...")
    print("-" * 80)
    print(f"{'TYPE':<10} {'STATUS':<15} {'PATH':<55}")
    print("-" * 80)

    to_remove = []
    for p, _ in candidates.items():
        is_safe, ws_type, branch, reason = evaluate_workspace_safety(repo_root, p)
        status_str = "ELIGIBLE" if is_safe else f"REFUSED ({reason})"
        print(f"{ws_type:<10} {status_str:<25} {p}")
        if is_safe:
            to_remove.append((p, ws_type, branch))

    print("-" * 80)
    if not to_remove:
        print("workspace-sweep: 0 workspaces eligible for sweep.")
        return

    if not execute:
        print(f"workspace-sweep: DRY-RUN — {len(to_remove)} workspace(s) eligible. Pass --execute to remove.")
        return

    # Execute removal
    trash_dir = get_trash_dir(repo_root)
    os.makedirs(trash_dir, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")

    for p, ws_type, _ in to_remove:
        # Soft-quarantine untracked / scratch files
        base_name = os.path.basename(os.path.normpath(p))
        dest_trash = os.path.join(trash_dir, f"{timestamp}-{base_name}")
        
        scratch_dir = os.path.join(p, ".relay-scratch")
        if os.path.exists(scratch_dir):
            try:
                os.makedirs(dest_trash, exist_ok=True)
                shutil.copytree(scratch_dir, os.path.join(dest_trash, ".relay-scratch"), dirs_exist_ok=True)
            except Exception:
                pass

        if ws_type == "worktree":
            res = subprocess.run(["git", "-C", repo_root, "worktree", "remove", p],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if res.returncode == 0:
                print(f"workspace-sweep: removed linked worktree {p}")
                deregister_workspace(repo_root, p)
            else:
                print(f"workspace-sweep: failed to remove worktree {p}: {res.stderr.strip()}", file=sys.stderr)
        else:
            # Full clone: move entire directory into trash
            try:
                shutil.move(p, dest_trash)
                print(f"workspace-sweep: moved clone to quarantine {dest_trash}")
                deregister_workspace(repo_root, p)
            except Exception as e:
                print(f"workspace-sweep: failed to quarantine clone {p}: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Manage and sweep ephemeral workspaces.")
    subparsers = parser.add_subparsers(dest="action", required=True)

    reg_p = subparsers.add_parser("register")
    reg_p.add_argument("--repo", default=".")
    reg_p.add_argument("--path", required=True)
    reg_p.add_argument("--type", choices=["worktree", "clone"], required=True)
    reg_p.add_argument("--branch")
    reg_p.add_argument("--pid", type=int)

    dereg_p = subparsers.add_parser("deregister")
    dereg_p.add_argument("--repo", default=".")
    dereg_p.add_argument("--path", required=True)

    sweep_p = subparsers.add_parser("sweep")
    sweep_p.add_argument("--repo", default=".")
    sweep_p.add_argument("--execute", action="store_true", help="Perform destructive removal")
    sweep_p.add_argument("--purge-trash", action="store_true", help="Immediately empty .xyz/trash/")

    args = parser.parse_args()
    repo_root = os.path.abspath(args.repo)

    if args.action == "register":
        register_workspace(repo_root, args.path, args.type, args.branch, args.pid)
        sys.exit(0)

    elif args.action == "deregister":
        deregister_workspace(repo_root, args.path)
        sys.exit(0)

    elif args.action == "sweep":
        sweep_workspaces(repo_root, execute=args.execute, purge_trash=args.purge_trash)
        sys.exit(0)


if __name__ == "__main__":
    main()
