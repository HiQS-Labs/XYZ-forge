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
import time
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

from scan_clones import (
    DEFAULT_SAFE_ROOTS,
    DEFAULT_NEVER_DELETE,
    is_safe_deletable_path,
    scan_directories,
    inspect_checkout,
    inspect_primary_landing,
    format_primary_landing,
    format_scan_table,
    run_git
)
from toposort_prs import (
    fetch_open_prs,
    toposort_prs,
    format_pr_table
)
from scan_clones import GH_BIN_ENV
from ledger_merge import (
    LEDGER_DUMP,
    pre_merge_ledger_gate,
    resolve_ledger_conflict,
)
import json
import tempfile

# Labels that mean "do not land this" (#444): the merge loop never touches a PR carrying one.
HOLD_LABEL_TOKENS = ("hold", "do not merge", "do-not-merge", "blocked", "wip")


def _gh_bin() -> str:
    return os.environ.get(GH_BIN_ENV) or "gh"


def _gh(args: List[str], cwd: Path, timeout: int = 180) -> subprocess.CompletedProcess:
    try:
        return subprocess.run([_gh_bin()] + args, cwd=str(cwd), capture_output=True, text=True, check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(args=args, returncode=127, stdout="", stderr=str(exc))


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
    res = _gh(["pr", "merge", str(pr_num), f"--{strategy}", "--delete-branch"], repo_path, timeout=600)
    if res.returncode != 0:
        log_err(f"Failed to merge PR #{pr_num}: {res.stderr.strip()}")
        return False
    # E: a zero exit is not a landing (#510 class). The remote must say MERGED.
    for _ in range(6):
        info = refresh_pr(pr_num, repo_path)
        if info.get("state") == "MERGED" and (info.get("mergeCommit") or {}).get("oid"):
            log(f"✅ PR #{pr_num} is MERGED as {info['mergeCommit']['oid'][:10]}")
            return True
        time.sleep(2)
    log_err(f"PR #{pr_num}: `gh pr merge` exited 0 but the PR does not read MERGED on re-query — treating as failed")
    return False


def refresh_pr(pr_num: int, repo_path: Path) -> Dict[str, Any]:
    """Live PR state, re-fetched before every decision (E). Any failure -> {"error": ...}."""
    res = _gh(["pr", "view", str(pr_num), "--json",
               "number,state,mergeable,headRefOid,headRefName,baseRefName,labels,mergeCommit,url"], repo_path)
    if res.returncode != 0:
        return {"error": f"gh pr view #{pr_num} failed: {res.stderr.strip() or 'no diagnostic'}"}
    try:
        info = json.loads(res.stdout)
        assert isinstance(info, dict) and info.get("number") == pr_num
    except (ValueError, AssertionError) as exc:
        return {"error": f"gh pr view #{pr_num} returned unusable output: {exc}"}
    return info


def hold_label(info: Dict[str, Any]) -> Optional[str]:
    for lab in info.get("labels") or []:
        name = (lab.get("name") if isinstance(lab, dict) else str(lab)) or ""
        low = name.lower()
        if any(tok in low for tok in HOLD_LABEL_TOKENS):
            return name
    return None


def origin_url(repo_path: Path) -> Optional[str]:
    r = run_git(repo_path, ["remote", "get-url", "origin"])
    return r.stdout.strip() if r.returncode == 0 and r.stdout.strip() else None


def prepare_landing_clone(pr: Dict[str, Any], primary_repo: Path, integration_branch: str,
                          workdir: Path) -> Dict[str, Any]:
    """A disposable full clone at the PR head with `git merge origin/<branch>` attempted (E.6/B1).

    Returns {"clone": Path|None, "merge_rc": int|None, "error": str}. merge_rc 0 = clean."""
    url = origin_url(primary_repo)
    if not url:
        return {"clone": None, "merge_rc": None, "error": "primary has no origin remote"}
    clone = Path(tempfile.mkdtemp(prefix=f"pr-{pr['number']}-{pr['headRefOid'][:8]}-", dir=str(workdir)))
    clone.rmdir()  # git clone wants to create it
    r = run_git(workdir, ["clone", "--quiet", url, str(clone)])
    if r.returncode != 0:
        return {"clone": None, "merge_rc": None, "error": f"git clone failed: {r.stderr.strip()[:300]}"}
    for k, v in (("user.name", "merge-cleanup"), ("user.email", "merge-cleanup@local")):
        run_git(clone, ["config", k, v])
    r = run_git(clone, ["fetch", "--quiet", "origin", f"pull/{pr['number']}/head", integration_branch])
    if r.returncode != 0:
        # Some remotes (a bare fixture) have no pull/N/head; the branch name is the fallback.
        r = run_git(clone, ["fetch", "--quiet", "origin", pr.get("headRefName") or "", integration_branch])
        if r.returncode != 0:
            return {"clone": clone, "merge_rc": None, "error": f"fetch of PR #{pr['number']} head failed: {r.stderr.strip()[:300]}"}
    r = run_git(clone, ["checkout", "--quiet", "--detach", pr["headRefOid"]])
    if r.returncode != 0:
        return {"clone": clone, "merge_rc": None, "error": f"checkout {pr['headRefOid'][:10]} failed: {r.stderr.strip()[:300]}"}
    # --no-commit keeps MERGE_HEAD on a clean merge, which the three-way ledger read and the
    # resolver's generation floor both need (E.6). A squash would drop it; so would a commit.
    m = run_git(clone, ["merge", "--no-ff", "--no-commit", f"origin/{integration_branch}"])
    return {"clone": clone, "merge_rc": m.returncode, "error": "", "merge_stderr": m.stderr.strip()}


def validate_head_in_second_clone(primary_repo: Path, source_clone: Path, sha: str, workdir: Path) -> Tuple[bool, str]:
    """B1.5: the resolved head must check clean in a SECOND disposable clone whose identity is
    verified before and after (origin URL unchanged, HEAD is the sha we fetched)."""
    url = origin_url(primary_repo)
    second = workdir / f"verify-{sha[:8]}"
    r = run_git(workdir, ["clone", "--quiet", url or "", str(second)])
    if r.returncode != 0:
        return False, f"second clone failed: {r.stderr.strip()[:200]}"
    ident_before = origin_url(second)
    r = run_git(second, ["fetch", "--quiet", str(source_clone), sha])
    if r.returncode != 0:
        return False, f"fetch of {sha[:10]} into the second clone failed: {r.stderr.strip()[:200]}"
    r = run_git(second, ["checkout", "--quiet", "--detach", sha])
    if r.returncode != 0:
        return False, f"checkout in the second clone failed: {r.stderr.strip()[:200]}"
    chk = subprocess.run([sys.executable, str(second / "utils" / "py" / "releases_app.py"), "--root", str(second), "check"],
                         capture_output=True, text=True, check=False)
    if chk.returncode != 0:
        return False, "releases check red in the second clone: " + (chk.stderr.strip() or chk.stdout.strip())[-300:]
    head_after = run_git(second, ["rev-parse", "HEAD"]).stdout.strip()
    if origin_url(second) != ident_before or head_after != sha:
        return False, "second clone identity drifted during validation"
    return True, "clean in a second clone"


def push_resolved_head(pr: Dict[str, Any], clone: Path, sha: str, primary_repo: Path) -> Tuple[bool, str]:
    """Push the B1 result to the PR branch only if the remote head is still the SHA we resolved."""
    live = refresh_pr(pr["number"], primary_repo)
    if live.get("error"):
        return False, live["error"]
    if live.get("headRefOid") != pr["headRefOid"]:
        return False, f"remote head moved from {pr['headRefOid'][:10]} to {str(live.get('headRefOid'))[:10]} during resolution — not pushing"
    r = run_git(clone, ["push", "origin", f"{sha}:refs/heads/{pr['headRefName']}"])
    if r.returncode != 0:
        return False, f"push refused: {r.stderr.strip()[-400:]}"
    return True, f"pushed {sha[:10]} to {pr['headRefName']}"


def run_post_merge_reconcile(pr_num: int, repo_path: Path, dry_run: bool = True) -> bool:
    """Executes wave_reconcile.py, RELEASES DB generation/check, and pdda issue-doc-sync."""
    if dry_run:
        log(f"[DRY RUN] Would run wave_reconcile.py --pr {pr_num} and RELEASES DB sync")
        return True

    log(f"Running post-merge reconciliation for PR #{pr_num} in {repo_path}...")

    # E: "Governed Landing" is enforced, not advisory. Every step here is gating; a failure
    # returns False and the orchestrator stops all downstream mutation.
    ok = True

    # 1. wave_reconcile.py
    reconcile_script = repo_path / "utils" / "py" / "wave_reconcile.py"
    if reconcile_script.exists():
        r_cmd = [sys.executable, str(reconcile_script), "--pr", str(pr_num)]
        r_res = subprocess.run(r_cmd, cwd=str(repo_path), capture_output=True, text=True, check=False)
        if r_res.returncode == 0:
            log(f"✅ wave_reconcile for PR #{pr_num} passed")
        else:
            log_err(f"wave_reconcile FAILED for PR #{pr_num} (exit {r_res.returncode}): {(r_res.stderr.strip() or r_res.stdout.strip())[-600:]}")
            ok = False

    # 2. releases_app.py gen & check
    releases_app = repo_path / "utils" / "py" / "releases_app.py"
    if releases_app.exists():
        g_res = subprocess.run([sys.executable, str(releases_app), "gen"], cwd=str(repo_path), capture_output=True, text=True, check=False)
        if g_res.returncode != 0:
            log_err(f"RELEASES gen FAILED (exit {g_res.returncode}): {(g_res.stderr.strip() or g_res.stdout.strip())[-400:]}")
            ok = False
        c_res = subprocess.run([sys.executable, str(releases_app), "check"], cwd=str(repo_path), capture_output=True, text=True, check=False)
        if c_res.returncode == 0:
            log("✅ RELEASES DB check passed")
        else:
            log_err(f"RELEASES DB check FAILED (exit {c_res.returncode}): {(c_res.stdout.strip() or c_res.stderr.strip())[-400:]}")
            ok = False

    # 3. pdda.sh issue-doc-sync
    pdda_sh = repo_path / "utils" / "pdda" / "pdda.sh"
    if pdda_sh.exists():
        p_res = subprocess.run(["bash", str(pdda_sh), "issue-doc-sync"], cwd=str(repo_path), capture_output=True, text=True, check=False)
        if p_res.returncode == 0:
            log("✅ pdda issue-doc-sync clean")
        else:
            log_err(f"pdda issue-doc-sync FAILED (exit {p_res.returncode}): {(p_res.stdout.strip() or p_res.stderr.strip())[-400:]}")
            ok = False

    return ok


# Dispositions that are never re-inspected for teardown: the operator's own tree, an explicit
# exclusion, and wiki clones. Everything else — including a scan-time PRESERVE_* — is
# re-inspected fresh in Phase 6, because a PR landing in Phase 5 can turn PRESERVE_UNPUSHED into
# eligible, and anything that changed since the scan can turn eligible into preserved (A.5).
TEARDOWN_EXEMPT = ("PRIMARY_CHECKOUT", "PRESERVED_USER_EXCLUDE", "PRESERVE_WIKI")


def refresh_for_teardown(checkouts: List[Dict[str, Any]], primary_repo: Path,
                         excludes: Optional[List[str]] = None,
                         integration_branch: str = "development") -> List[Dict[str, Any]]:
    """Re-run inspect_checkout on EVERY non-exempt checkout; the fresh verdict is the only one
    teardown may act on. The scan-time disposition is kept under `scan_disposition` for display."""
    fresh: List[Dict[str, Any]] = []
    for c in checkouts:
        if c["disposition"] in TEARDOWN_EXEMPT:
            continue
        info = inspect_checkout(Path(c["path"]), primary_repo_path=primary_repo, exclude_patterns=excludes,
                                integration_branch=integration_branch)
        info["scan_disposition"] = c["disposition"]
        if info["disposition"] != c["disposition"]:
            log(f"{info['name']}: {c['disposition']} at scan time -> {info['disposition']} now ({info['disposition_reason']})")
        fresh.append(info)
    return fresh


def teardown_checkout(checkout: Dict[str, Any], dry_run: bool = True) -> bool:
    """Safely tears down a worktree or standalone clone in strict compliance with WORKTREE-SAFETY.md.

    `checkout` must be a FRESH inspection from refresh_for_teardown(); a scan-time record is
    refused so a stale SAFE_REMOVE_* can never be acted on (A.5).
    """
    path = Path(checkout["path"]).resolve()
    c_type = checkout["checkout_type"]
    disp = checkout["disposition"]

    if "scan_disposition" not in checkout:
        log_err(f"Refusing to tear down {path.name}: not a fresh Phase 6 inspection")
        return False

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


# Agent homes whose `skills/` directories hold symlinked skill installs. Each entry is
# GLOBBED, not hardcoded one level down: a fixed list silently skipped
# ~/.gemini/antigravity-cli/skills (a real install dir that simply was not in the list),
# leaving dangling links behind while the run reported a clean prune.
SKILL_SEARCH_GLOBS = [
    (".claude", ["skills", "*/skills"]),
    (".codex", ["skills", "*/skills"]),
    (".gemini", ["skills", "*/skills", "*/*/skills"]),
]


def _iter_skill_dirs():
    """Yield every existing skills/ directory across the agent homes, glob-discovered."""
    seen = set()
    for home_rel, patterns in SKILL_SEARCH_GLOBS:
        base = Path.home() / home_rel
        if not base.is_dir():
            continue
        for pattern in patterns:
            for d in base.glob(pattern):
                # Never descend through a symlinked skills/ dir — that would walk into the
                # source repo and delete real links there rather than the install stubs.
                if d.is_dir() and not d.is_symlink() and d not in seen:
                    seen.add(d)
                    yield d


def prune_dangling_skill_symlinks(dry_run: bool = True):
    """Remove dangling symlinks under every agent home's skills/ directories.

    Walks each skills/ tree recursively rather than only its top level: a dangling link
    can sit INSIDE a real skill directory (e.g. ~/.claude/skills/front-door/SKILL.md ->
    a deleted repo path), which a depth-1 `iterdir()` scan cannot see.
    """
    for d in _iter_skill_dirs():
        try:
            touched_parents = set()
            # rglob does not follow symlinked directories, so the walk stays inside this
            # install tree and cannot wander into the repos the links point at.
            for item in d.rglob("*"):
                if item.is_symlink() and not item.exists():
                    target = os.readlink(item)
                    if dry_run:
                        log(f"[DRY RUN] Would remove dangling skill symlink: {item} -> {target}")
                    else:
                        item.unlink()
                        log(f"✅ Removed dangling skill symlink: {item}")
                    if item.parent != d:
                        touched_parents.add(item.parent)

            # A skill dir whose only content was the dead link is now an empty stub that
            # still advertises itself as an installed skill. Clear it, deepest first, and
            # never the skills root itself.
            for parent in sorted(touched_parents, key=lambda p: len(p.parts), reverse=True):
                if parent == d or d not in parent.parents:
                    continue
                if dry_run:
                    if parent.is_dir() and not any(parent.iterdir()):
                        log(f"[DRY RUN] Would remove empty skill directory: {parent}")
                elif parent.is_dir() and not any(parent.iterdir()):
                    parent.rmdir()
                    log(f"✅ Removed empty skill directory: {parent}")
        except Exception as exc:
            log_warn(f"Error checking skill dir {d}: {exc}")


def land_prs(ordered_prs: List[Dict[str, Any]], primary_repo: Path, args, dry_run: bool) -> int:
    """E + E.6 + B1: the Phase 5 feedback loop. Every PR is re-fetched before any decision, gated
    in a disposable clone against the CURRENT integration head, merged only on green, verified
    MERGED on re-query, then reconciled (gating). The first failure stops everything."""
    branch = args.integration_branch
    workdir = Path(tempfile.mkdtemp(prefix="merge-cleanup-"))
    keep_workdir = False
    try:
        for pr in ordered_prs:
            p_num = pr["number"]
            info = refresh_pr(p_num, primary_repo)
            if info.get("error"):
                log_err(f"PR #{p_num}: {info['error']} — stopping; a PR whose state is unknown is never merged")
                return 2
            label = hold_label(info)
            if label:
                log(f"PR #{p_num}: carries hold label '{label}' — skipped (#444)")
                continue
            if info.get("state") != "OPEN":
                log(f"PR #{p_num}: state is {info.get('state')} — skipped")
                continue
            if (info.get("baseRefName") or "") != branch:
                log_err(f"PR #{p_num} targets '{info.get('baseRefName')}', not '{branch}' — stopping")
                return 2
            mergeable = info.get("mergeable")
            if mergeable not in ("MERGEABLE", "CONFLICTING"):
                log_err(f"PR #{p_num}: mergeable is {mergeable!r} — GitHub has not decided; stopping rather than guessing")
                return 2

            # Simulate this landing against the integration head fetched NOW.
            prep = prepare_landing_clone(info, primary_repo, branch, workdir)
            if prep["error"]:
                log_err(f"PR #{p_num}: {prep['error']} — stopping")
                keep_workdir = True
                return 2
            clone = prep["clone"]

            if prep["merge_rc"] != 0:
                log(f"PR #{p_num}: landing merge conflicts (GitHub said {mergeable}) — routing to B1")
                b1 = resolve_ledger_conflict(clone, execute=not dry_run)
                for line in b1["log"]:
                    log(f"  B1: {line}")
                if b1["handoff"]:
                    log_err(f"PR #{p_num}: HANDOFF — {b1['reason']}")
                    log_err(f"  conflict set: {', '.join(b1['conflict_set']) or '(none extracted)'}")
                    keep_workdir = True
                    return 3
                if not b1["resolved"]:
                    log_err(f"PR #{p_num}: B1 stopped — {b1['reason']} (clone kept at {clone})")
                    keep_workdir = True
                    return 2 if not dry_run else 0
                ok, why = validate_head_in_second_clone(primary_repo, clone, b1["commit"], workdir)
                if not ok:
                    log_err(f"PR #{p_num}: resolved head failed validation — {why}; NOT pushed")
                    keep_workdir = True
                    return 2
                ok, why = push_resolved_head(info, clone, b1["commit"], primary_repo)
                if not ok:
                    log_err(f"PR #{p_num}: {why}")
                    keep_workdir = True
                    return 2
                log(f"PR #{p_num}: {why}; re-fetching and re-gating the new head")
                info = refresh_pr(p_num, primary_repo)
                if info.get("error") or info.get("mergeable") != "MERGEABLE":
                    log_err(f"PR #{p_num}: after resolution the PR reads {info.get('mergeable') or info.get('error')} — stopping")
                    return 2
                prep = prepare_landing_clone(info, primary_repo, branch, workdir)
                if prep["error"] or prep["merge_rc"] != 0:
                    log_err(f"PR #{p_num}: the resolved head still does not merge cleanly — stopping ({prep['error'] or 'merge rc ' + str(prep['merge_rc'])})")
                    keep_workdir = True
                    return 2
                clone = prep["clone"]

            # E.6: the ledger gate on the simulated landing.
            gate = pre_merge_ledger_gate(clone, gh_bin=_gh_bin(), integration_branch=branch)
            for d in gate["diagnostics"]:
                log(f"  gate: {d}")
            if not gate["green"]:
                log_err(f"PR #{p_num}: pre-merge ledger gate RED — not merged:")
                for f in gate["failures"]:
                    log_err(f"  - {f}")
                keep_workdir = True
                return 2
            log(f"PR #{p_num}: pre-merge ledger gate green on {info['headRefOid'][:10]} + origin/{branch}")

            if dry_run:
                log(f"[DRY RUN] Would merge PR #{p_num} via `gh pr merge {p_num} --{args.strategy} --delete-branch`")
                continue
            if not execute_pr_merge(p_num, primary_repo, strategy=args.strategy, dry_run=False):
                return 2
            # Land it locally, then reconcile — both gating, before the next PR is even looked at.
            fetched = run_git(primary_repo, ["fetch", "origin", branch])
            if fetched.returncode != 0:
                log_err(f"post-merge fetch failed: {fetched.stderr.strip()} — stopping")
                return 2
            ff = run_git(primary_repo, ["merge", "--ff-only", f"origin/{branch}"])
            if ff.returncode != 0:
                log_err(f"fast-forward to origin/{branch} FAILED: {ff.stderr.strip() or 'git refused'}")
                log_err("PR is merged remotely but the primary did not advance — reconcile by hand.")
                return 2
            if not run_post_merge_reconcile(p_num, primary_repo, dry_run=False):
                log_err(f"PR #{p_num}: post-merge reconciliation FAILED — stopping before the next PR")
                return 2
        return 0
    finally:
        if keep_workdir:
            log(f"Landing clones kept for inspection under {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)


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
    parser.add_argument("--integration-branch", default="development", help="Branch PRs land on and the primary must be able to fast-forward (default: development)")
    parser.add_argument("--allow-unready-primary", action="store_true", help="Merge even though the primary checkout cannot receive the landing (records the blockers and proceeds)")
    parser.add_argument("--execute", action="store_true", help="Execute mutations (default is safe dry-run)")

    args = parser.parse_args()

    try:
        primary_repo = Path(args.primary).expanduser().resolve() if args.primary else Path.cwd().resolve()
    except (OSError, RuntimeError) as exc:
        log_err(f"cannot resolve the primary path {args.primary!r}: {exc}")
        return 2
    search_roots = [Path(r).expanduser().resolve() for r in args.root] if args.root else DEFAULT_SAFE_ROOTS
    dry_run = not args.execute

    log(f"Operating on primary repo: {primary_repo}")
    if dry_run:
        log("Running in SAFE DRY-RUN mode. Pass --execute to apply changes.")

    # Phase 0: the primary on-disk checkout, before ANY other mode dispatches. It receives every
    # merge and runs every reconciliation, so its readiness is a precondition of the run, not a
    # detail discovered at merge time. This must stay above --reconcile-pr: that mode launches
    # governance writers straight into this tree, and used to do so with no verdict computed at
    # all (R1-F2).
    primary_landing = inspect_primary_landing(primary_repo, integration_branch=args.integration_branch)
    print("\n" + "=" * 80)
    print("PHASE 0: PRIMARY ON-DISK CHECKOUT")
    print("=" * 80 + "\n")
    print(format_primary_landing(primary_landing) + "\n")

    def _primary_blocks(action: str) -> bool:
        """True when `action` must be refused because the primary cannot receive it."""
        if primary_landing["landing_ready"] or args.allow_unready_primary or dry_run:
            return False
        log_err(f"REFUSING to {action}: the primary checkout cannot receive the landing.")
        for b in primary_landing["blockers"]:
            log_err(f"  - {b}")
        log_err("Fix the primary first, or pass --allow-unready-primary to proceed anyway.")
        return True

    # Reconcile specific PR directly if requested
    if args.reconcile_pr > 0:
        if _primary_blocks("reconcile"):
            return 2
        return 0 if run_post_merge_reconcile(args.reconcile_pr, primary_repo, dry_run=dry_run) else 2

    # Phase 1..3: Scan & Audit checkouts
    checkouts = scan_directories(search_roots, prefix_filter=args.prefix, primary_repo=primary_repo, excludes=args.exclude, integration_branch=args.integration_branch)
    print("\n" + "=" * 80)
    print(f"PHASE 1-3: CHECKOUT AUDIT & SAFETY STATUS ({len(checkouts)} found)")
    print("=" * 80 + "\n")
    print(format_scan_table(checkouts) + "\n")

    if args.scan_only:
        return 0

    # Phase 4: Open PR Sequencing
    prs = fetch_open_prs(str(primary_repo))
    ordered_prs: List[Dict[str, Any]] = []
    if prs:
        ordered_prs, _, warnings = toposort_prs(prs)
        print("=" * 80)
        print(f"PHASE 4: TOPOLOGICAL PR SEQUENCE ({len(ordered_prs)} open PRs)")
        print("=" * 80 + "\n")
        print(format_pr_table(ordered_prs) + "\n")
        if not primary_landing["landing_ready"]:
            log_warn(
                "This sequence is NOT executable as things stand: the primary checkout cannot "
                "receive the landing (see PHASE 0). --execute would refuse."
            )
        if warnings:
            print("Ordering Notes:")
            for w in warnings:
                print(f"  - {w}")
            print()
    else:
        log("No open PRs found for this repository.")

    if args.prs_only:
        return 0

    # Phase 5: Execute Merges & Post-Merge Reconciliation (if not teardown-only)
    # Gate on Phase 0. Merging is remote and effectively irreversible; landing into a tree that
    # cannot fast-forward leaves the repo half-landed with reconciliation unrun. Refuse first.
    if not args.teardown_only and ordered_prs and args.execute:
        # The Phase 0 verdict above was computed against whatever origin/* this clone had cached.
        # Re-establish it against the live remote before the first irreversible merge (R1-F1).
        log("Refreshing remote refs before the first merge, then re-checking the primary...")
        fetched = run_git(primary_repo, ["fetch", "origin", args.integration_branch])
        if fetched.returncode != 0 and not args.allow_unready_primary:
            # Re-checking against the SAME cached origin/* the fetch failed to refresh would
            # certify stale evidence as current. Refuse instead (R2-1).
            log_err(
                f"REFUSING to merge: could not refresh origin/{args.integration_branch} — "
                f"{fetched.stderr.strip() or 'git fetch failed'}"
            )
            log_err("Phase 0's verdict is based on cached refs that may no longer match the remote.")
            log_err("Fix the remote access, or pass --allow-unready-primary to proceed on stale evidence.")
            return 2
        primary_landing = inspect_primary_landing(primary_repo, integration_branch=args.integration_branch)
        print(format_primary_landing(primary_landing) + "\n")
        if _primary_blocks("merge"):
            return 2

        # R2-2: the branch Phase 0 checked must be the branch these PRs actually land on. A PR
        # based elsewhere would merge into a tree whose readiness was never established.
        mismatched = [pr for pr in ordered_prs
                      if (pr.get("baseRefName") or "") != args.integration_branch]
        if mismatched:
            log_err(f"REFUSING to merge: {len(mismatched)} PR(s) do not target '{args.integration_branch}':")
            for pr in mismatched:
                log_err(f"  - #{pr['number']} targets '{pr.get('baseRefName') or 'unknown'}'")
            log_err("Phase 0 only vouches for the selected integration branch.")
            log_err(f"Re-run with --integration-branch <their base>, or exclude them.")
            return 2

    if not args.teardown_only and ordered_prs:
        print("=" * 80)
        print("PHASE 5: EXECUTING PR MERGES & RECONCILIATION")
        print("=" * 80 + "\n")
        rc = land_prs(ordered_prs, primary_repo, args, dry_run)
        if rc != 0:
            log_err("Phase 5 stopped; teardown and symlink pruning are NOT run after a failed landing.")
            return rc

    # Phase 6: Safe Teardown
    print("=" * 80)
    print("PHASE 6: SAFE TEARDOWN & RECOVERY PRUNING")
    print("=" * 80 + "\n")
    # A.5: the scan above is display. Every non-exempt checkout is inspected AGAIN, after a
    # fresh fetch, and only that verdict is acted on.
    log("Re-inspecting every non-exempt checkout before teardown...")
    fresh = refresh_for_teardown(checkouts, primary_repo, excludes=args.exclude, integration_branch=args.integration_branch)
    removable = [c for c in fresh if c["disposition"] in ("SAFE_REMOVE_WORKTREE", "SAFE_REMOVE_CLONE")]
    if not removable:
        log("No candidate checkouts qualify for safe removal (all are preserved or active).")
    else:
        for c in removable:
            teardown_checkout(c, dry_run=dry_run)

    # Prune dangling symlinks
    prune_dangling_skill_symlinks(dry_run=dry_run)
    print("\n" + "=" * 80)
    log("Merge cleanup run complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
