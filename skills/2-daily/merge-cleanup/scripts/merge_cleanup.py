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

import json
import re
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
    format_completion_and_followup_summary,
    format_issue_marker_body,
    resolve_canonical_issue,
    run_git
)
from toposort_prs import (
    fetch_open_prs,
    toposort_prs,
    format_pr_table,
    FetchError,
)
from scan_clones import GH_BIN_ENV
import attempt_record
import ledger_merge
from ledger_merge import (
    LEDGER_DUMP,
    pre_merge_ledger_gate,
    resolve_ledger_conflict,
    tool_path,
)
import json
import tempfile

# Labels that mean "do not land this" (#444): the merge loop never touches a PR carrying one.
HOLD_LABEL_TOKENS = ("hold", "do not merge", "do-not-merge", "blocked", "wip")
HOSTED_WAIT_ENV = "MERGE_CLEANUP_HOSTED_WAIT_S"
HOSTED_POLL_ENV = "MERGE_CLEANUP_HOSTED_POLL_S"
# GH-629: the run for a just-pushed head can take a few seconds to appear in `gh run list`; an
# empty answer inside this window is "not yet", not "no hosted workflow". Only after it elapses
# does an empty list select the local writer.
HOSTED_GRACE_ENV = "MERGE_CLEANUP_HOSTED_GRACE_S"


def _gh_bin() -> str:
    return os.environ.get(GH_BIN_ENV) or "gh"


def _gh(args: List[str], cwd: Path, timeout: int = 180) -> subprocess.CompletedProcess:
    try:
        return subprocess.run([_gh_bin()] + args, cwd=str(cwd), capture_output=True, text=True, check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(args=args, returncode=127, stdout="", stderr=str(exc))


# --- GH-623: network resilience — bounded calls, transient-only retry, defer instead of stop ----
# The incident run lost 3 of 7 PRs to one DNS failure and never retried anything. The contract,
# pinned by TestGh623Resilience: a TRANSIENT network failure is retried 3 times total (sleeps of
# 2s then 4s between the three calls) and, at the two pre-decision call sites, DEFERS that one PR
# while the rest of the queue continues; anything non-transient stops exactly as before. A hung
# call reaches this machinery because every retry-site git call is bounded in time (_net_git).

RETRY_ATTEMPTS = 3
RETRY_BACKOFF_S = (2, 4)      # sleeps BETWEEN attempts: 3 calls, 2 sleeps
MERGEABLE_POLL_ATTEMPTS = 6   # UNKNOWN mergeability right after a landing: poll up to 6 × 15s
MERGEABLE_POLL_S = 15
NET_TIMEOUT_S = 180           # bound for network git calls (_gh bounds its own subprocess)

TRANSIENT_RE = re.compile(
    r"could not resolve host|connection refused|connection timed out|timed out|TLS|SSL|rate limit",
    re.I,
)

_sleep = time.sleep  # module alias so tests can record the schedule without waiting for it


def _transient(err: str) -> bool:
    return bool(TRANSIENT_RE.search(err or ""))


def _net_git(cwd: Path, args: List[str], timeout: float = NET_TIMEOUT_S) -> subprocess.CompletedProcess:
    """run_git with a finite timeout for network call sites. A hung git call becomes the same
    non-zero failure shape as any other error (rc 124, "timed out" diagnostic) so the retry
    loop can classify it; a plain run_git call with no timeout stays unbounded by default."""
    try:
        return run_git(cwd, args, timeout=timeout)
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(args=args, returncode=124, stdout="",
                                           stderr=f"timed out after {timeout}s: git {' '.join(args)}")


def _retry_call(attempt_fn, describe: str):
    """Run `attempt_fn() -> CompletedProcess` up to RETRY_ATTEMPTS times, sleeping
    RETRY_BACKOFF_S between attempts, retrying only transient failures. Returns the last
    CompletedProcess; callers keep their existing non-zero handling."""
    result = None
    for attempt in range(RETRY_ATTEMPTS):
        result = attempt_fn()
        if result.returncode == 0:
            return result
        if not _transient(result.stderr):
            return result
        if attempt < RETRY_ATTEMPTS - 1:
            wait = RETRY_BACKOFF_S[min(attempt, len(RETRY_BACKOFF_S) - 1)]
            log(f"{describe}: transient network failure ({result.stderr.strip()[:120]}) — "
                f"retry {attempt + 2}/{RETRY_ATTEMPTS} in {wait}s")
            _sleep(wait)
    return result


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


def refresh_pr_with_retry(pr_num: int, repo_path: Path) -> Dict[str, Any]:
    """refresh_pr, retried on transient network failures (GH-623). A transient failure that
    survives the retries is still an {"error": ...} — the caller decides (pre-decision sites
    defer; anything non-transient stops as before)."""
    info: Dict[str, Any] = {"error": "not attempted"}
    for attempt in range(RETRY_ATTEMPTS):
        info = refresh_pr(pr_num, repo_path)
        err = info.get("error") or ""
        if not err or not _transient(err):
            return info
        if attempt < RETRY_ATTEMPTS - 1:
            wait = RETRY_BACKOFF_S[min(attempt, len(RETRY_BACKOFF_S) - 1)]
            log(f"PR #{pr_num}: transient refresh failure ({err[:120]}) — "
                f"retry {attempt + 2}/{RETRY_ATTEMPTS} in {wait}s")
            _sleep(wait)
    return info


def fetch_open_prs_with_retry(repo_path: str) -> List[Dict[str, Any]]:
    """Phase 4 discovery, retried on transient network failures (GH-623). Raises toposort
    FetchError after the retries are exhausted; an empty list now can only mean EMPTY."""
    last: Optional[FetchError] = None
    for attempt in range(RETRY_ATTEMPTS):
        try:
            return fetch_open_prs(repo_path)
        except FetchError as exc:
            last = exc
            if not _transient(str(exc)):
                raise
            if attempt < RETRY_ATTEMPTS - 1:
                wait = RETRY_BACKOFF_S[min(attempt, len(RETRY_BACKOFF_S) - 1)]
                log(f"PR discovery: transient network failure ({str(exc)[:120]}) — "
                    f"retry {attempt + 2}/{RETRY_ATTEMPTS} in {wait}s")
                _sleep(wait)
    raise last  # type: ignore[misc]


def hold_label(info: Dict[str, Any]) -> Optional[str]:
    for lab in info.get("labels") or []:
        name = (lab.get("name") if isinstance(lab, dict) else str(lab)) or ""
        low = name.lower()
        if any(tok in low for tok in HOLD_LABEL_TOKENS):
            return name
    return None


def post_issue_marker(repo_path: Path, issue_num: int, body: str, dry_run: bool = True) -> bool:
    """Posts a status marker comment to the specified GitHub issue."""
    if dry_run:
        log(f"[DRY RUN] Would post status marker comment to GitHub issue #{issue_num}")
        return True
    log(f"Posting status marker comment to GitHub issue #{issue_num}...")
    res = _gh(["issue", "comment", str(issue_num), "--body", body], repo_path, timeout=60)
    if res.returncode == 0:
        log(f"✅ Posted status marker to GH-#{issue_num}")
        return True
    else:
        log_warn(f"Failed to post marker to GH-#{issue_num}: {res.stderr.strip()}")
        return False


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
    # GH-623: clone and fetches are network calls — bounded and retried on transient failures.
    r = _retry_call(lambda: _net_git(workdir, ["clone", "--quiet", url, str(clone)]), f"PR #{pr['number']} clone")
    if r.returncode != 0:
        return {"clone": None, "merge_rc": None, "error": f"git clone failed: {r.stderr.strip()[:300]}"}
    for k, v in (("user.name", "merge-cleanup"), ("user.email", "merge-cleanup@local")):
        run_git(clone, ["config", k, v])
    r = _retry_call(lambda: _net_git(clone, ["fetch", "--quiet", "origin", f"pull/{pr['number']}/head", integration_branch]),
                    f"PR #{pr['number']} fetch")
    if r.returncode != 0:
        # Some remotes (a bare fixture) have no pull/N/head; the branch name is the fallback.
        r = _retry_call(lambda: _net_git(clone, ["fetch", "--quiet", "origin", pr.get("headRefName") or "", integration_branch]),
                        f"PR #{pr['number']} fetch (branch fallback)")
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
    chk = subprocess.run([sys.executable, str(tool_path(second, "releases_app.py")), "--root", str(second), "check"],
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


CLOSES_RE = re.compile(r"\b(?:closes|fixes|resolves)\s+#(\d+)", re.I)


def linked_issues(pr):
    """Issue numbers a PR closes, from its own body and title.

    Local on purpose: merge_cleanup does not import wave_reconcile, and a merge report must not
    acquire a new cross-module dependency to name its issue.
    """
    text = "%s\n%s" % (pr.get("title") or "", pr.get("body") or "")
    seen, out = set(), []
    for m in CLOSES_RE.finditer(text):
        n = int(m.group(1))
        if n not in seen:
            seen.add(n)
            out.append(n)
    return out


def emit_pr_merged(repo_path, pr, dry_run=False):
    """GH-549: report a merge this process actually WITNESSED.

    Placed here, and only here, for a reason the plan review made explicit: a completed roadmap
    marker does not prove a PR merged, and neither does a generic reconcile. The only honest
    source for `merged` is a `gh pr merge` that returned 0, which is the caller's `if merged:`.

    Deliberately NOT emitted from --reconcile-pr, which never verifies merge state at all; that
    path is covered by `releases work reconcile`.

    Keyed on the issues the PR closes, not the PR number — the board tracks issues, so emitting
    a PR number would create a card for something that is not on the board. A PR that closes
    nothing emits nothing, which is correct: there is no work item whose state changed.

    Never blocks and never fails the merge: the merge has already happened by the time this
    runs, so a reporting failure must not be mistaken for a merge failure.
    """
    if dry_run or not pr:
        return 0
    app = str(tool_path(Path(repo_path), "releases_app.py"))
    if not os.path.isfile(app):
        return 0
    emitted = 0
    for issue in linked_issues(pr):
        try:
            r = subprocess.run(
                [sys.executable, app, "--root", repo_path, "work", "emit",
                 "--event", "pr_merged", "--gh-number", str(issue),
                 "--payload-json", json.dumps({"pr": pr.get("number"),
                                               "base": pr.get("baseRefName")})],
                capture_output=True, text=True, timeout=60, check=False)
            if r.returncode == 0:
                emitted += 1
            else:
                print(f"  (work event not recorded for #{issue}: {r.stderr.strip()[:120]})")
        except Exception as exc:
            print(f"  (work event not recorded for #{issue}: {exc})")
    return emitted


def _seconds_from_env(name: str, default: float) -> float:
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        value = float(raw)
        if value < 0:
            raise ValueError
        return value
    except ValueError:
        log_warn(f"Ignoring invalid {name}={raw!r}; using {default:g}s")
        return default


def wait_for_hosted_reconcile(merged_head: str, repo_path: Path,
                              integration_branch: str) -> str:
    """Return success, fallback, or active_timeout for this merge head's hosted run.

    `--commit` is the identity boundary: an older successful run must never satisfy a newer
    landing. An observed active run is polled to completion and is never raced by the local
    writer. Empty/unavailable results mean the hosted workflow does not exist for this repo and
    select the local fallback.
    """
    wait_s = _seconds_from_env(HOSTED_WAIT_ENV, 1800)
    poll_s = _seconds_from_env(HOSTED_POLL_ENV, 30)
    grace_s = _seconds_from_env(HOSTED_GRACE_ENV, 60)
    started = time.monotonic()
    deadline = started + wait_s
    query = [
        "run", "list", "--workflow", "wave-reconcile.yml",
        "--branch", integration_branch, "--commit", merged_head,
        "--json", "databaseId,status,conclusion", "--limit", "5",
    ]

    while True:
        res = _gh(query, repo_path, timeout=60)
        if res.returncode != 0:
            log_warn(
                "Hosted wave-reconcile lookup unavailable; using local reconciliation: "
                + (res.stderr.strip() or f"gh exited {res.returncode}")
            )
            return "fallback"
        try:
            runs = json.loads(res.stdout or "[]")
            if not isinstance(runs, list):
                raise ValueError("expected a JSON array")
        except (TypeError, ValueError) as exc:
            log_warn(f"Hosted wave-reconcile lookup returned unusable JSON ({exc}); using local reconciliation")
            return "fallback"
        if not runs:
            grace_left = grace_s - (time.monotonic() - started)
            if grace_left > 0:
                log(f"No hosted wave-reconcile run listed yet for {merged_head[:10]}; "
                    f"waiting up to {grace_left:.0f}s more before assuming there is none")
                time.sleep(min(poll_s, grace_left) or 0.1)
                continue
            log(f"No hosted wave-reconcile run found for {merged_head[:10]}; using local reconciliation")
            return "fallback"

        run = runs[0]
        status = str(run.get("status") or "").lower()
        conclusion = str(run.get("conclusion") or "").lower()
        run_id = run.get("databaseId") or "unknown"
        if status == "completed":
            if conclusion == "success":
                log(f"✅ Hosted wave-reconcile run #{run_id} succeeded for {merged_head[:10]}")
                return "success"
            log_warn(
                f"Hosted wave-reconcile run #{run_id} completed as {conclusion or 'unknown'}; "
                "using local reconciliation"
            )
            return "fallback"

        remaining = deadline - time.monotonic()
        if remaining <= 0:
            log_err(
                f"Hosted wave-reconcile run #{run_id} is still {status or 'active'} after "
                f"{wait_s:g}s; refusing to start the local reconciler while it is in flight"
            )
            return "active_timeout"
        log(f"Hosted wave-reconcile run #{run_id} is {status or 'active'}; waiting")
        time.sleep(min(poll_s, remaining))


def run_local_wave_reconcile(pr_num: int, repo_path: Path) -> bool:
    """Run the local writer after hosted reconciliation is known absent or completed red."""
    reconcile_script = tool_path(repo_path, "wave_reconcile.py")
    if not reconcile_script.exists():
        return True
    r_cmd = [sys.executable, str(reconcile_script), "--root", str(repo_path), "--pr", str(pr_num)]
    # Older / vendored reconcilers do not know --force-local-reconcile; pass it only when advertised.
    helptext = subprocess.run([sys.executable, str(reconcile_script), "--help"], cwd=str(repo_path),
                              capture_output=True, text=True, check=False).stdout
    if "--force-local-reconcile" in helptext:
        r_cmd.append("--force-local-reconcile")
    r_res = subprocess.run(r_cmd, cwd=str(repo_path), capture_output=True, text=True, check=False)
    if r_res.returncode == 0:
        log(f"✅ local wave_reconcile for PR #{pr_num} passed")
        return True
    log_err(
        f"wave_reconcile FAILED for PR #{pr_num} (exit {r_res.returncode}): "
        f"{(r_res.stderr.strip() or r_res.stdout.strip())[-600:]}"
    )
    return False


def run_post_merge_reconcile(pr_num: int, repo_path: Path,
                             integration_branch: str = "development",
                             dry_run: bool = True) -> bool:
    """Wait for hosted reconciliation (or fall back locally), then run governance checks."""
    if dry_run:
        log(f"[DRY RUN] Would wait for hosted reconciliation or run wave_reconcile.py --pr {pr_num}")
        return True

    log(f"Running post-merge reconciliation for PR #{pr_num} in {repo_path}...")

    # E: "Governed Landing" is enforced, not advisory. Every step here is gating; a failure
    # returns False and the orchestrator stops all downstream mutation.
    ok = True

    # 1. The merge fast-forward immediately before this call pins the workflow lookup to the
    # exact triggering head. Hosted success is authoritative; only an absent/completed-red run
    # selects the local writer. An active timeout stops instead of racing that writer.
    head = run_git(repo_path, ["rev-parse", "HEAD"])
    if head.returncode != 0 or not head.stdout.strip():
        log_err(f"Cannot identify the merged head before reconciliation: {head.stderr.strip()}")
        return False
    hosted = wait_for_hosted_reconcile(head.stdout.strip(), repo_path, integration_branch)
    if hosted == "active_timeout":
        return False
    if hosted == "success":
        fetched = run_git(repo_path, ["fetch", "origin", integration_branch])
        if fetched.returncode != 0:
            log_err(f"Hosted reconciliation succeeded but fetch of origin/{integration_branch} failed: {fetched.stderr.strip()}")
            return False
        ff = run_git(repo_path, ["merge", "--ff-only", f"origin/{integration_branch}"])
        if ff.returncode != 0:
            log_err(f"Fast-forward onto hosted reconciliation commit failed: {ff.stderr.strip() or 'git refused'}")
            return False
    elif not run_local_wave_reconcile(pr_num, repo_path):
        ok = False

    # 2. releases_app.py check
    releases_app = tool_path(repo_path, "releases_app.py")
    if releases_app.exists():
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


def commit_and_push_phase5_writes(pr_num: int, repo_path: Path, integration_branch: str) -> bool:
    """Commit, push, and verify every primary-side write made after a PR lands."""
    status = run_git(repo_path, ["status", "--porcelain", "--untracked-files=all"])
    if status.returncode != 0:
        log_err(f"PR #{pr_num}: cannot inspect post-merge writes: {status.stderr.strip()}")
        return False

    if status.stdout.strip():
        added = run_git(repo_path, ["add", "-A"])
        if added.returncode != 0:
            log_err(f"PR #{pr_num}: could not stage post-merge writes: {added.stderr.strip()}")
            return False
        committed = run_git(repo_path, ["commit", "-m", f"chore: reconcile after PR #{pr_num}"])
        if committed.returncode != 0:
            log_err(f"PR #{pr_num}: could not commit post-merge writes: {committed.stderr.strip()}")
            return False

    pushed = run_git(repo_path, ["push", "origin", f"HEAD:{integration_branch}"])
    if pushed.returncode != 0:
        log_err(f"PR #{pr_num}: could not push post-merge writes: {pushed.stderr.strip()}")
        return False
    fetched = run_git(repo_path, ["fetch", "origin", integration_branch])
    if fetched.returncode != 0:
        log_err(f"PR #{pr_num}: could not verify pushed integration head: {fetched.stderr.strip()}")
        return False

    clean = run_git(repo_path, ["status", "--porcelain", "--untracked-files=all"])
    local = run_git(repo_path, ["rev-parse", "HEAD"])
    remote = run_git(repo_path, ["rev-parse", f"origin/{integration_branch}"])
    if (clean.returncode != 0 or clean.stdout.strip() or
            local.returncode != 0 or remote.returncode != 0 or
            local.stdout.strip() != remote.stdout.strip()):
        log_err(f"PR #{pr_num}: post-merge durability check failed — primary must be clean and match origin/{integration_branch}")
        return False
    log(f"✅ PR #{pr_num} post-merge writes committed; primary is clean at origin/{integration_branch}")
    return True


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
            # Trash is the ONLY removal path (plan: "where Trash is unavailable the skill must
            # refuse, not rmtree"). A wrong eligibility verdict is recoverable from Trash and from
            # nowhere else.
            trash_dir = Path.home() / ".Trash"
            if not (trash_dir.exists() and trash_dir.is_dir()):
                log_err(f"REFUSING to remove {path}: {trash_dir} is unavailable and rmtree is not a permitted removal path")
                return False
            trash_target = trash_dir / f"{path.name}-{os.getpid()}"
            shutil.move(str(path), str(trash_target))
            log(f"✅ Moved clone {path.name} to Trash ({trash_target})")
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
    origin = origin_url(primary_repo) or ""
    if getattr(args, "resume", False):
        # GH-623 (Antigravity review): say up front what resume does and does not trust. The
        # live refresh stays authoritative — counts are only known per-PR as the loop reaches
        # them, never pre-skipped from records alone.
        coordinator = attempt_record.record_path(primary_repo, origin, 0).parent
        log(f"Resume mode: attempt records under {coordinator} are consulted only after each "
            f"PR's live refresh; a repaired, now-mergeable PR still lands.")
    # C: runtime map of predecessor outcomes. toposort only ORDERS; a dependent of a parked or
    # handed-off PR must not be attempted at all.
    failed: Dict[int, str] = {}
    try:
        for pr in ordered_prs:
            p_num = pr["number"]
            # C + GH-623: only HARD dependencies (explicit "depends on #N") block a PR on a
            # failed predecessor. Collision edges (`_soft_deps`) decide sequence only — a
            # dependent is attempted anyway and the landing simulation decides; a genuinely
            # conflicting successor hands off on its own merits instead of never being tried.
            blocked_by = [d for d in pr.get("_hard_deps", []) if d in failed]
            soft_blocked_by = [d for d in pr.get("_soft_deps", []) if d in failed]
            if soft_blocked_by and not blocked_by:
                why_soft = ", ".join(f"#{d} ({failed[d]})" for d in soft_blocked_by)
                log_err(f"PR #{p_num}: soft predecessor(s) {why_soft} did not land — "
                        f"attempting anyway; the landing simulation decides")
            if blocked_by:
                why = ", ".join(f"#{d} ({failed[d]})" for d in blocked_by)
                log_err(f"PR #{p_num}: NOT attempted — depends on {why}")
                failed[p_num] = f"blocked by {', '.join('#%d' % d for d in blocked_by)}"
                continue
            # E + GH-623: live refresh, retried on transient failures. A TRANSIENT failure that
            # survives the retries defers this PR and the queue continues (the incident's S4:
            # one DNS failure aborted #604/#607/#614 which were never attempted). A failure we
            # cannot attribute to the network still stops the run: unknown state is never merged.
            info = refresh_pr_with_retry(p_num, primary_repo)
            if info.get("error"):
                if _transient(info["error"]):
                    log_err(f"PR #{p_num}: DEFERRED — network unavailable after {RETRY_ATTEMPTS} attempts: "
                            f"{info['error']}")
                    failed[p_num] = f"deferred: network ({info['error'][:120]})"
                    continue
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
            # GitHub recomputes mergeability after every landing on the base; the PR right after
            # a merge reads UNKNOWN for a few seconds. Poll (bounded) before treating it as unknown
            # state — a stop here is a timing artifact, not an unknowable PR.
            polls = 0
            while mergeable not in ("MERGEABLE", "CONFLICTING") and polls < MERGEABLE_POLL_ATTEMPTS:
                polls += 1
                log(f"PR #{p_num}: mergeable is {mergeable!r} — waiting {MERGEABLE_POLL_S}s for GitHub "
                    f"to decide ({polls}/{MERGEABLE_POLL_ATTEMPTS})")
                _sleep(MERGEABLE_POLL_S)
                again = refresh_pr_with_retry(p_num, primary_repo)
                if again.get("error"):
                    break
                info = again
                mergeable = info.get("mergeable")
            if mergeable not in ("MERGEABLE", "CONFLICTING"):
                log_err(f"PR #{p_num}: mergeable is {mergeable!r} — GitHub has not decided; stopping rather than guessing")
                return 2

            # Simulate this landing against the integration head fetched NOW.
            prep = prepare_landing_clone(info, primary_repo, branch, workdir)
            if prep["error"]:
                if _transient(prep["error"]):
                    log_err(f"PR #{p_num}: DEFERRED — network unavailable after {RETRY_ATTEMPTS} attempts: "
                            f"{prep['error']}")
                    failed[p_num] = f"deferred: network ({prep['error'][:120]})"
                    continue
                log_err(f"PR #{p_num}: {prep['error']} — stopping")
                keep_workdir = True
                return 2
            clone = prep["clone"]

            if prep["merge_rc"] != 0:
                log(f"PR #{p_num}: landing merge conflicts (GitHub said {mergeable}) — routing to B1")
                # GH-623 --resume: the LIVE state above is authoritative — a PR whose last repair
                # resolved and now merges cleanly never reaches this branch. Only when a repair
                # is actually NEEDED (the landing still conflicts) does the record decide: at the
                # ceiling, skip as previously parked instead of re-running the B1 machinery.
                # reserve() below remains the under-lock authority without --resume.
                if args.resume:
                    record_path = attempt_record.record_path(primary_repo, origin, p_num)
                    rec = None
                    if record_path.exists():
                        try:
                            rec = attempt_record.load(record_path)
                        except attempt_record.RecordError as exc:
                            log_warn(f"PR #{p_num}: unreadable attempt record ({exc}) — proceeding; "
                                     f"reserve() still gates the ceiling")
                    if rec is not None and attempt_record.repair_count(rec) >= attempt_record.MAX_REPAIRS \
                            and not any(a.get("outcome") == "in_progress" for a in rec["attempts"]):
                        log_err(f"PR #{p_num}: PARKED (resume) — the landing still conflicts and the record "
                                f"already shows {attempt_record.MAX_REPAIRS} repairs")
                        log_err(f"  export {attempt_record.RECORD_ENV}={record_path}  # caller ladder: /unstuck")
                        failed[p_num] = "previously parked (resume)"
                        continue
                # C: one durable attempt record at the pinned coordinator (the --primary path),
                # shared with the caller's repair rungs. B1 is a repair: it needs a slot.
                record = attempt_record.record_path(primary_repo, origin, p_num)
                fresh = attempt_record.new_record(p_num, origin, base_sha=info.get("headRefOid", ""))
                log(f"PR #{p_num}: attempt record {record}")
                try:
                    if dry_run:
                        idx, why = None, "dry run: no slot reserved"
                        if attempt_record.repair_count(attempt_record.load(record, fresh)) >= attempt_record.MAX_REPAIRS:
                            why = "budget exhausted (dry run would park)"
                    else:
                        idx, why = attempt_record.reserve(record, by="script", head_sha=info["headRefOid"], rung="B1",
                                                          clone_path=str(clone), create=fresh)
                except attempt_record.RecordError as exc:
                    log_err(f"PR #{p_num}: {exc} — stopping")
                    keep_workdir = True
                    return 2
                if idx is None and why.startswith("budget exhausted"):
                    log_err(f"PR #{p_num}: PARKED — {why}")
                    log_err(f"  export {attempt_record.RECORD_ENV}={record}  # then /unstuck; the record already shows {attempt_record.MAX_REPAIRS} repairs")
                    failed[p_num] = "parked: repair budget exhausted"
                    continue
                log(f"PR #{p_num}: {why}")
                b1 = resolve_ledger_conflict(clone, execute=not dry_run)
                for line in b1["log"]:
                    log(f"  B1: {line}")
                if not dry_run:
                    attempt_record.set_conflicts(record, b1.get("conflict_set", []))
                if b1["handoff"]:
                    if idx is not None:
                        attempt_record.finish(record, idx, "handoff", reason=b1["reason"])
                    log_err(f"PR #{p_num}: HANDOFF — {b1['reason']}")
                    log_err(f"  conflict set: {', '.join(b1['conflict_set']) or '(none extracted)'}")
                    log_err(f"  export {attempt_record.RECORD_ENV}={record}  # caller ladder: /debug-mantra → /recon → /ponytail → /start-task → /unstuck")
                    failed[p_num] = "handoff"
                    keep_workdir = True
                    continue
                if not b1["resolved"]:
                    if idx is not None:
                        attempt_record.finish(record, idx, "stopped", reason=b1["reason"])
                    log_err(f"PR #{p_num}: B1 stopped — {b1['reason']} (clone kept at {clone})")
                    keep_workdir = True
                    return 2 if not dry_run else 0
                if idx is not None:
                    attempt_record.finish(record, idx, "resolved", commit=b1["commit"])
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
                info = refresh_pr_with_retry(p_num, primary_repo)
                polls = 0
                while info.get("mergeable") not in ("MERGEABLE", "CONFLICTING") and polls < MERGEABLE_POLL_ATTEMPTS:
                    polls += 1
                    log(f"PR #{p_num}: mergeable is {info.get('mergeable')!r} — waiting {MERGEABLE_POLL_S}s for GitHub to decide ({polls}/{MERGEABLE_POLL_ATTEMPTS})")
                    _sleep(MERGEABLE_POLL_S)
                    again = refresh_pr_with_retry(p_num, primary_repo)
                    if again.get("error"):
                        break
                    info = again
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
            # Land it locally before anything writes into the primary. In particular, emitting
            # pr_merged before this fast-forward dirties releases.sql and can block the landing
            # (GH-624). GH-623: the fetch is bounded and retried on transient network failures.
            fetched = _retry_call(lambda: _net_git(primary_repo, ["fetch", "origin", branch]),
                                  f"post-merge fetch for PR #{p_num}")
            if fetched.returncode != 0:
                log_err(f"post-merge fetch failed: {fetched.stderr.strip()} — stopping")
                return 2
            ff = run_git(primary_repo, ["merge", "--ff-only", f"origin/{branch}"])
            if ff.returncode != 0:
                log_err(f"fast-forward to origin/{branch} FAILED: {ff.stderr.strip() or 'git refused'}")
                log_err("PR is merged remotely but the primary did not advance — reconcile by hand.")
                return 2
            if not run_post_merge_reconcile(p_num, primary_repo, integration_branch=branch, dry_run=False):
                log_err(f"PR #{p_num}: post-merge reconciliation FAILED — stopping before the next PR")
                return 2
            # GH-549/GH-624: report only after the merge, primary fast-forward, and reconcile
            # (including any fast-forward performed by reconciliation) all succeeded. `pr` rather
            # than `info` because the emitter reads the body for `Closes #N`.
            emit_pr_merged(primary_repo, pr, dry_run=False)
            if not commit_and_push_phase5_writes(p_num, primary_repo, branch):
                log_err(f"PR #{p_num}: post-merge writes were not made durable — stopping before the next PR")
                return 2
        # GH-623: deferrals count as non-landed outcomes too — a deferred PR blocks only its
        # HARD dependents; soft dependents were attempted above. Exit 3 keeps the shape
        # "the queue completed but not everything landed"; 2 remains a hard stop.
        if failed:
            deferred = [n for n, w in failed.items() if w.startswith("deferred:")]
            resumed_parked = [n for n, w in failed.items() if w == "previously parked (resume)"]
            other = len(failed) - len(deferred) - len(resumed_parked)
            log_err(f"{len(failed)} PR(s) did not land "
                    f"({len(deferred)} deferred by network, {len(resumed_parked)} parked on resume, "
                    f"{other} handed off or parked): "
                    + ", ".join(f"#{n} ({w})" for n, w in failed.items()))
            return 3
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
    # C: the primary is the coordinator of the attempt record and the target of every landing.
    # It is never inferred from the CWD — a disposable clone running this script would otherwise
    # mint its own record root and its own landing target.
    parser.add_argument("--primary", required=True, help="Path to the primary working repo (required; never inferred from the CWD)")
    parser.add_argument("--root", action="append", help="Root directory to search for checkouts")
    parser.add_argument("--prefix", default="", help="Filter checkouts by repo name substring")
    parser.add_argument("--exclude", action="append", default=[], help="Pattern or branch to exclude from cleanup")
    parser.add_argument("--strategy", choices=["squash", "merge", "rebase"], default="squash", help="PR merge strategy")
    parser.add_argument("--scan-only", action="store_true", help="Only audit and list checkouts")
    parser.add_argument("--prs-only", action="store_true", help="Only list and sequence open PRs")
    parser.add_argument("--teardown-only", action="store_true", help="Only perform checkout teardown (skip PR merges)")
    parser.add_argument("--reconcile-pr", type=int, default=0, help="Run post-merge reconcile on a specific PR number")
    parser.add_argument("--integration-branch", default="development", help="Branch PRs land on and the primary must be able to fast-forward (default: development)")
    parser.add_argument("--marker", action="store_true", help="Post status marker comments to linked canonical GitHub issues for active/incomplete checkouts")
    parser.add_argument("--allow-unready-primary", action="store_true", help="Explicitly defer primary-checkout cleanup and proceed even though the primary cannot receive the landing")
    parser.add_argument("--execute", action="store_true", help="Execute mutations (default is safe dry-run)")
    parser.add_argument("--resume", action="store_true", help="Continue a previous run: consult each PR's attempt record and skip one that is already parked (the live refresh stays authoritative — a PR whose repair resolved and now merges cleanly still lands)")

    args = parser.parse_args()

    try:
        primary_repo = Path(args.primary).expanduser().resolve()
        ledger_merge.TOOL_FALLBACK_ROOT = primary_repo
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
        return 0 if run_post_merge_reconcile(
            args.reconcile_pr, primary_repo,
            integration_branch=args.integration_branch, dry_run=dry_run,
        ) else 2

    # Phase 1..3: Scan & Audit checkouts
    checkouts = scan_directories(search_roots, prefix_filter=args.prefix, primary_repo=primary_repo, excludes=args.exclude, integration_branch=args.integration_branch)
    print("\n" + "=" * 80)
    print(f"PHASE 1-3: CHECKOUT AUDIT & SAFETY STATUS ({len(checkouts)} found)")
    print("=" * 80 + "\n")
    print(format_scan_table(checkouts) + "\n")

    summary = format_completion_and_followup_summary(checkouts)
    if summary:
        print(summary)

    if args.marker:
        print("=" * 80)
        print("CANONICAL GITHUB ISSUE STATUS MARKERS")
        print("=" * 80 + "\n")
        marked = 0
        for c in checkouts:
            issue_num = c.get("canonical_issue")
            if issue_num and c.get("disposition") != "PRIMARY_CHECKOUT":
                body = format_issue_marker_body(c)
                if post_issue_marker(primary_repo, issue_num, body, dry_run=dry_run):
                    marked += 1
        if marked == 0:
            log("No linked canonical issues found for candidate checkouts.")
        print()

    if args.scan_only:
        return 0

    # Phase 4: Open PR Sequencing
    # GH-623: discovery is retried on transient failures, and a FAILED discovery is never read
    # as an empty queue — an empty list and an error are different facts. Exhaustion exits 2
    # BEFORE Phase 6: rolling into teardown on a false "no PRs" would report success while the
    # queue was silently skipped.
    try:
        prs = fetch_open_prs_with_retry(str(primary_repo))
    except FetchError as exc:
        log_err(f"PR discovery failed after {RETRY_ATTEMPTS} attempts: {exc} — refusing to continue; "
                f"the queue cannot be verified empty")
        return 2
    ordered_prs: List[Dict[str, Any]] = []
    # `--exclude <N>` (a bare PR number) drops that PR from the queue, as SKILL.md's example 6
    # documents; other patterns still apply to checkouts only.
    excluded_prs = {int(x) for x in (args.exclude or []) if str(x).isdigit()}
    if excluded_prs:
        skipped = [p for p in prs if int(p.get("number", 0)) in excluded_prs]
        prs = [p for p in prs if int(p.get("number", 0)) not in excluded_prs]
        for p in skipped:
            log(f"PR #{p['number']}: excluded by --exclude; not sequenced this run")
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
        # GH-623: transient failures are retried (bounded) first. Exhaustion keeps today's
        # refusal — merging on a stale Phase 0 verdict is the pinned hazard (R2-1) — and the
        # existing --allow-unready-primary override still applies unchanged.
        fetched = _retry_call(lambda: _net_git(primary_repo, ["fetch", "origin", args.integration_branch]),
                              "pre-merge refresh")
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

    # GH-595: executing cleanup is one operation, even when there are no PRs or the caller chose
    # teardown-only. The operator — not the skill — owns any decision to leave the primary
    # unready. Refuse before the first Phase 5/6 mutation unless that deferral is explicit.
    if _primary_blocks("execute cleanup"):
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
