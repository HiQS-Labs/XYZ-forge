#!/usr/bin/env python3
"""scan_clones.py — Discover and inspect Git checkouts, worktrees, and clones.

Strictly follows WORKTREE-SAFETY.md:
- Component-aware containment checking (safe roots vs protected roots).
- Differentiates linked worktrees (.git is a file) from standalone clones (.git is a directory).
- Verifies active locks (.git/relay-driver.lock), active processes, git status, stashes, and unpushed refs.
"""

import os
import re
import sys
import json
import subprocess
import shutil
import tempfile
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

# GH-534 A.1: this list is the SAME list WORKTREE-SAFETY.md §16.1 shows as `SAFE_ROOTS`, and a
# test pins the parity. `~/marathon-clones` is where /start-task, /jog and the marathon flows
# create task clones (skills/10days, skills/marathon-triage); leaving it out meant the one
# directory the repo's own workflow fills was the one this skill could never clean.
DEFAULT_SAFE_ROOTS = [
    Path.home() / "Documents" / "GH Repos",
    Path.home() / "agent-workspaces",
    Path.home() / "Documents" / "agent-workspaces",
    Path.home() / "marathon-clones",
]

# Optional test seams. Production callers never set these; fixtures use them to substitute a
# stub `gh` / `lsof` / `tick` without patching module internals (the same shape as
# RELEASES_GH_BIN in releases_app.py).
GH_BIN_ENV = "MERGE_CLEANUP_GH_BIN"
LSOF_BIN_ENV = "MERGE_CLEANUP_LSOF_BIN"
TICK_BIN_ENV = "MERGE_CLEANUP_TICK_BIN"
LSOF_TIMEOUT_S = 120

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
    """Runs a git command in the target directory.

    Callers treat a non-zero return code as "git said no". A git that cannot be LAUNCHED at all
    (missing binary, unreadable cwd, OS refusal) is the same answer as far as they are concerned,
    so it is reported the same way rather than escaping as an exception (R1-F5).
    """
    try:
        return subprocess.run(
            ["git", "-C", str(cwd)] + args,
            capture_output=True,
            text=True,
            check=False
        )
    except OSError as exc:
        return subprocess.CompletedProcess(args=args, returncode=127, stdout="", stderr=f"{exc}")


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


def coordination_root(repo_path: Path) -> Optional[Path]:
    """The checkout whose `.tick/` governs `repo_path`.

    A linked worktree's `.tick/` is its parent clone's: the event log lives beside the git
    common dir, so the worktree must be judged by the parent's claims. Returns None when git
    cannot answer — the caller treats that as an unverifiable session (fail closed).
    """
    res = run_git(repo_path, ["rev-parse", "--git-common-dir"])
    if res.returncode != 0 or not res.stdout.strip():
        return None
    common = Path(res.stdout.strip())
    if not common.is_absolute():
        common = (repo_path / common).resolve()
    return common.parent if common.name == ".git" else common


def _tick_binary() -> Optional[str]:
    """The harness's own `bin/tick`, then PATH. Never the audited checkout's copy."""
    override = os.environ.get(TICK_BIN_ENV)
    if override:
        return override
    own = Path(__file__).resolve().parents[3] / "bin" / "tick"
    if own.is_file() and os.access(own, os.X_OK):
        return str(own)
    return shutil.which("tick")


def inspect_tick_claims(repo_path: Path) -> Dict[str, Any]:
    """GH-534 A.4: active-session evidence from the tick EVENT LOG, never from STATE.md.

    `.tick/STATE.md` is a derived snapshot written by `tick project`; a readable-but-stale or
    missing one proves nothing about current claims (and the old parser here matched the wrong
    "none" spelling anyway). The authoritative fold is exposed read-only by `tick claims --json`,
    run with TICK_REPO_ROOT pinned to the coordination root so the verb can never resolve a
    different repo from the CWD.

    Returns {"has_claims": bool, "verified": bool, "details": str, "claims": [...]}.
    `verified` False means the question could not be answered — the caller must PRESERVE.
    """
    coord = coordination_root(repo_path)
    if coord is None:
        return {"has_claims": False, "verified": False,
                "details": "cannot resolve the git common dir to locate .tick/"}
    tick_dir = coord / ".tick"
    if not tick_dir.exists():
        # No coordination root at all: nothing can be claimed here. (A `.tick/` that exists
        # but cannot be read is the verified=False case below, not this one.)
        return {"has_claims": False, "verified": True, "details": "no .tick/ coordination root", "claims": []}

    # A lock directory entry of ANY shape counts — `os.mkdir` locks are directories.
    locks_dir = tick_dir / "locks"
    if locks_dir.exists():
        try:
            locks = sorted(p.name for p in locks_dir.iterdir())
        except OSError as exc:
            return {"has_claims": False, "verified": False, "details": f".tick/locks unreadable: {exc}"}
        if locks:
            return {"has_claims": True, "verified": True,
                    "details": f"{len(locks)} entr{'y' if len(locks) == 1 else 'ies'} in .tick/locks: {', '.join(locks)}",
                    "claims": []}

    tick = _tick_binary()
    if not tick:
        return {"has_claims": False, "verified": False, "details": "tick binary not found"}
    env = dict(os.environ)
    env["TICK_REPO_ROOT"] = str(coord)
    try:
        proc = subprocess.run([tick, "claims", "--json"], cwd=tempfile.gettempdir(), env=env,
                              capture_output=True, text=True, check=False, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"has_claims": False, "verified": False, "details": f"tick claims did not run: {exc}"}
    if proc.returncode != 0:
        return {"has_claims": False, "verified": False,
                "details": f"tick claims exit {proc.returncode}: {proc.stderr.strip() or 'no diagnostic'}"}
    try:
        payload = json.loads(proc.stdout)
        claims = payload["claimed"]
        assert isinstance(claims, list)
        for c in claims:
            assert isinstance(c["task"], str) and isinstance(c["agent"], str)
    except (ValueError, KeyError, TypeError, AssertionError) as exc:
        return {"has_claims": False, "verified": False, "details": f"tick claims output malformed: {exc}"}
    if claims:
        names = ", ".join(f"{c['task']} by {c['agent']}" for c in claims)
        return {"has_claims": True, "verified": True, "details": names, "claims": claims}
    return {"has_claims": False, "verified": True, "details": "no claimed tasks", "claims": []}


def _ancestor_pids() -> set:
    """This process and its ancestors: the probing shell is itself listed by an idle-dir lsof."""
    pids = {os.getpid()}
    pid = os.getppid()
    for _ in range(64):
        if pid <= 1 or pid in pids:
            break
        pids.add(pid)
        try:
            out = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)], capture_output=True, text=True, check=False).stdout.strip()
            pid = int(out) if out.isdigit() else 0
        except (OSError, ValueError):
            break
    return pids


def inspect_open_handles(repo_path: Path) -> Dict[str, Any]:
    """GH-534 A.4: process evidence via `lsof -F pcn +D <checkout>` — three outcomes, not two.

    Probed on macOS 2026-09-09: `lsof +D` exits 1 in EVERY case (idle, held, missing path,
    unreadable subdir), so the exit code cannot separate idle from held. It can separate "ran"
    from "did not finish", which is all it is used for here:
      1. absent binary / timeout / launch failure            -> incomplete
      2. not a normal exit with return code 0 or 1           -> incomplete (signal-killed etc.)
      3. anything on stderr (`lsof: WARNING: can't opendir`) -> incomplete: the tree was not covered
      4. completed + empty stderr -> parse records; keep `n` paths strictly within the checkout,
         drop our own PID and ancestors; matches -> ACTIVE_PROCESS, none -> verified idle.
    Returns {"verified": bool, "active": bool, "details": str, "holders": [{"pid","command","paths"}]}.
    """
    lsof = os.environ.get(LSOF_BIN_ENV) or shutil.which("lsof")
    if not lsof:
        return {"verified": False, "active": False, "details": "lsof not found", "holders": []}
    try:
        proc = subprocess.run([lsof, "-F", "pcn", "+D", str(repo_path)], cwd=tempfile.gettempdir(),
                              capture_output=True, text=True, check=False, timeout=LSOF_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        return {"verified": False, "active": False, "details": f"lsof timed out after {LSOF_TIMEOUT_S}s", "holders": []}
    except OSError as exc:
        return {"verified": False, "active": False, "details": f"lsof did not run: {exc}", "holders": []}
    if proc.returncode not in (0, 1):
        how = f"killed by signal {-proc.returncode}" if proc.returncode < 0 else f"exit {proc.returncode}"
        return {"verified": False, "active": False, "details": f"lsof did not complete ({how})", "holders": []}
    if proc.stderr.strip():
        first = proc.stderr.strip().splitlines()[0]
        return {"verified": False, "active": False, "details": f"lsof enumeration incomplete: {first}", "holders": []}

    skip = _ancestor_pids()
    # lsof reports canonical paths (/private/var/... for a /var/... checkout on macOS); compare
    # against both the given and the resolved checkout path.
    try:
        resolved_repo = repo_path.resolve()
    except OSError:
        resolved_repo = repo_path
    holders: Dict[int, Dict[str, Any]] = {}
    pid = None
    cmd = ""
    for line in proc.stdout.splitlines():
        if not line:
            continue
        tag, val = line[0], line[1:]
        if tag == "p":
            pid = int(val) if val.isdigit() else None
            cmd = ""
        elif tag == "c":
            cmd = val
        elif tag == "n" and pid is not None and pid not in skip:
            if _within(Path(val), repo_path) or _within(Path(val), resolved_repo):
                holders.setdefault(pid, {"pid": pid, "command": cmd, "paths": []})["paths"].append(val)
    if holders:
        names = ", ".join(f"PID {h['pid']} ({h['command'] or '?'})" for h in holders.values())
        return {"verified": True, "active": True, "details": names, "holders": list(holders.values())}
    return {"verified": True, "active": False, "details": "no open handles", "holders": []}


# --- GH-534 A.2: provenance of every local ref -----------------------------------------------

_merged_pr_cache: Dict[str, Dict[str, Any]] = {}


def _gh_bin() -> str:
    return os.environ.get(GH_BIN_ENV) or "gh"


def _normalize_remote(url: str) -> str:
    """owner/repo for any GitHub URL form; otherwise the URL itself minus `.git` and slashes."""
    u = url.strip().rstrip("/")
    if u.endswith(".git"):
        u = u[:-4]
    m = re.search(r"github\.com[:/]([^/]+/[^/]+)$", u)
    return m.group(1).lower() if m else u


def merged_pr_index(repo_path: Path, integration_branch: str) -> Dict[str, Any]:
    """Merged PRs of the repo `origin` points at, keyed by headRefOid. Cached per origin URL.

    {"ok": bool, "reason": str, "by_head": {sha: pr}, "truncated": bool}
    Identity is bound: the clone's origin URL must name the repo `gh` answered for.
    """
    origin = run_git(repo_path, ["remote", "get-url", "origin"])
    if origin.returncode != 0 or not origin.stdout.strip():
        return {"ok": False, "reason": "no origin remote", "by_head": {}, "truncated": False}
    key = _normalize_remote(origin.stdout)
    if key in _merged_pr_cache:
        return _merged_pr_cache[key]
    result: Dict[str, Any] = {"ok": False, "reason": "", "by_head": {}, "truncated": False}
    try:
        view = subprocess.run([_gh_bin(), "repo", "view", "--json", "url"], cwd=str(repo_path),
                              capture_output=True, text=True, check=False, timeout=120)
        if view.returncode != 0:
            result["reason"] = f"gh repo view failed: {view.stderr.strip() or 'no diagnostic'}"
            return result
        answered = _normalize_remote(json.loads(view.stdout)["url"])
        if answered != key:
            result["reason"] = f"gh answered for {answered}, origin is {key}"
            return result
        limit = 500
        lst = subprocess.run([_gh_bin(), "pr", "list", "--state", "merged", "--base", integration_branch,
                              "--json", "number,state,headRefOid,mergeCommit,baseRefName", "--limit", str(limit)],
                             cwd=str(repo_path), capture_output=True, text=True, check=False, timeout=180)
        if lst.returncode != 0:
            result["reason"] = f"gh pr list failed: {lst.stderr.strip() or 'no diagnostic'}"
            return result
        prs = json.loads(lst.stdout)
        if not isinstance(prs, list):
            raise ValueError("pr list is not a list")
        for pr in prs:
            if pr.get("state") != "MERGED" or pr.get("baseRefName") != integration_branch:
                continue
            mc = (pr.get("mergeCommit") or {}).get("oid")
            head = pr.get("headRefOid")
            if isinstance(head, str) and isinstance(mc, str) and head and mc:
                result["by_head"][head] = {"number": pr.get("number"), "mergeCommit": mc}
        result["truncated"] = len(prs) >= limit
        result["ok"] = True
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError, TypeError) as exc:
        result["reason"] = f"gh output unusable: {exc}"
        result["by_head"] = {}
        result["ok"] = False
    _merged_pr_cache[key] = result
    return result


def _raw_diff(repo_path: Path, a: str, b: str) -> Optional[List[Tuple[str, str, str, str]]]:
    """(path, status, new_mode, new_blob) for every path changed between a and b.

    Blob ids are exact content identity — whitespace, modes and binaries included — which is
    what "the branch's content is in the merge commit" has to mean. The OLD side is deliberately
    not compared: the integration branch legitimately moves under a PR between its merge-base
    and its landing, and that motion is not evidence the branch's own work was dropped.
    """
    d = run_git(repo_path, ["diff", "--raw", "--no-renames", "--full-index", "-z", a, b])
    if d.returncode != 0:
        return None
    fields = d.stdout.split("\0")
    out = []
    i = 0
    while i + 1 < len(fields) and fields[i]:
        meta = fields[i].split()
        if len(meta) != 5 or not fields[i].startswith(":"):
            return None
        _old_mode, new_mode, _old_blob, new_blob, status = meta
        out.append((fields[i + 1], status[0], new_mode, new_blob))
        i += 2
    return sorted(out)


def classify_local_refs(repo_path: Path, integration_branch: str = "development") -> Dict[str, Any]:
    """Every local ref tip is LANDED or UNLANDED, by provenance — or the query failed.

    Rule 1: reachable from origin/<integration_branch> -> landed.
    Rule 2: tip == headRefOid of a MERGED PR whose mergeCommit is reachable, AND the branch's
            aggregate raw diff (merge-base..tip) equals the merge commit's (parent..merge) —
            blob ids, modes, paths; whitespace is not normalised away -> landed.
    Rule 3: anything else -> unlanded, naming the ref, the commit and the reason.
    `git cherry` is not consulted: it drops whitespace, so its equality is not behavioural equality.
    Returns {"ok": bool, "failed_query": str, "unlanded": [str], "landed": [str]}.
    """
    out: Dict[str, Any] = {"ok": False, "failed_query": "", "unlanded": [], "landed": []}
    remote_ref = f"origin/{integration_branch}"
    fetched = run_git(repo_path, ["fetch", "--quiet", "origin", integration_branch])
    if fetched.returncode != 0:
        out["failed_query"] = f"git fetch origin {integration_branch}: {fetched.stderr.strip() or 'failed'}"
        return out

    refs = run_git(repo_path, ["for-each-ref", "--format=%(refname)%00%(objectname)", "refs/"])
    if refs.returncode != 0:
        out["failed_query"] = f"git for-each-ref: {refs.stderr.strip() or 'failed'}"
        return out
    tips: List[Tuple[str, str]] = []
    for line in refs.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split("\0")
        if len(parts) != 2 or not re.fullmatch(r"[0-9a-f]{40,64}", parts[1]):
            out["failed_query"] = f"git for-each-ref: malformed line {line!r}"
            return out
        name, sha = parts
        if name.startswith("refs/remotes/") or name == "refs/stash":
            continue
        tips.append((name, sha))
    sym = run_git(repo_path, ["symbolic-ref", "-q", "HEAD"])
    if sym.returncode != 0:  # detached HEAD is a local ref like any other
        head = run_git(repo_path, ["rev-parse", "HEAD"])
        if head.returncode != 0 or not re.fullmatch(r"[0-9a-f]{40,64}", head.stdout.strip()):
            out["failed_query"] = "git rev-parse HEAD (detached): failed"
            return out
        tips.append(("HEAD (detached)", head.stdout.strip()))

    index: Optional[Dict[str, Any]] = None
    for name, sha in tips:
        anc = run_git(repo_path, ["merge-base", "--is-ancestor", sha, remote_ref])
        if anc.returncode == 0:
            out["landed"].append(f"{name} @ {sha[:10]} (reachable from {remote_ref})")
            continue
        if anc.returncode != 1:
            out["failed_query"] = f"git merge-base --is-ancestor {sha[:10]} {remote_ref}: {anc.stderr.strip() or 'failed'}"
            return out
        if index is None:
            index = merged_pr_index(repo_path, integration_branch)
        if not index["ok"]:
            out["unlanded"].append(f"{name} @ {sha[:10]}: not reachable from {remote_ref}; merged-PR lookup unavailable ({index['reason']})")
            continue
        pr = index["by_head"].get(sha)
        if pr is None:
            why = "no merged PR has this head"
            if index["truncated"]:
                why += " within the first 500 merged PRs"
            out["unlanded"].append(f"{name} @ {sha[:10]}: not reachable from {remote_ref}; {why}")
            continue
        mc = pr["mergeCommit"]
        mc_anc = run_git(repo_path, ["merge-base", "--is-ancestor", mc, remote_ref])
        if mc_anc.returncode != 0:
            out["unlanded"].append(f"{name} @ {sha[:10]}: PR #{pr['number']} merge commit {mc[:10]} is not on {remote_ref}")
            continue
        mb = run_git(repo_path, ["merge-base", sha, f"{mc}^"])
        if mb.returncode != 0 or not mb.stdout.strip():
            out["unlanded"].append(f"{name} @ {sha[:10]}: PR #{pr['number']}: cannot compute the merge-base against {mc[:10]}^")
            continue
        branch_diff = _raw_diff(repo_path, mb.stdout.strip(), sha)
        merge_diff = _raw_diff(repo_path, f"{mc}^", mc)
        if branch_diff is None or merge_diff is None:
            out["unlanded"].append(f"{name} @ {sha[:10]}: PR #{pr['number']}: diff query failed")
            continue
        if branch_diff == merge_diff:
            out["landed"].append(f"{name} @ {sha[:10]} (squash-merged as PR #{pr['number']}, {mc[:10]}, content equal)")
        else:
            out["unlanded"].append(f"{name} @ {sha[:10]}: PR #{pr['number']} merged {mc[:10]} but its content differs from this branch — review before discarding")
    out["ok"] = True
    return out


def inspect_checkout(repo_path: Path, primary_repo_path: Optional[Path] = None,
                     exclude_patterns: Optional[List[str]] = None,
                     integration_branch: str = "development") -> Dict[str, Any]:
    """Inspects a single git checkout for status, locks, stashes, and disposition.

    GH-534: every safety query FAILS CLOSED. A git/tick/lsof command that exits non-zero or
    returns something unparseable is recorded in `query_failures` and the checkout is preserved
    naming that query — never defaulted to "clean", "no stash", "no claims" or "idle".
    """
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
        "landed_refs": [],
        "has_unpushed": False,
        "linked_worktrees": [],
        "parent_clone": None,
        "driver_lock": {"locked": False},
        "tick_claims": {"has_claims": False, "verified": False},
        "open_handles": {"verified": False, "active": False},
        "query_failures": [],
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

    # Status check — the COMPLETE NUL-safe porcelain, every file named (A.3). No regenerable
    # allowance: harnesses.db carries invocation data, *.db.bak may be the last pre-rebuild copy.
    st_res = run_git(path, ["status", "--porcelain", "-z", "--untracked-files=all"])
    if st_res.returncode == 0:
        entries = [e for e in st_res.stdout.split("\0") if e]
        files = []
        i = 0
        while i < len(entries):
            e = entries[i]
            files.append(e)
            if len(e) > 1 and e[0] == "R":  # rename carries the source path as the next NUL field
                i += 1
            i += 1
        res["dirty_count"] = len(files)
        res["dirty_files"] = files
        res["is_clean"] = not files
    else:
        res["is_clean"] = False
        res["dirty_count"] = -1
        res["query_failures"].append(f"git status: {st_res.stderr.strip() or 'failed'}")

    # Stash check — a failed enumeration is NOT zero stashes.
    stash_res = run_git(path, ["stash", "list"])
    if stash_res.returncode == 0:
        res["stash_count"] = len([l for l in stash_res.stdout.splitlines() if l.strip()])
    else:
        res["stash_count"] = -1
        res["query_failures"].append(f"git stash list: {stash_res.stderr.strip() or 'failed'}")

    # Landed-vs-unlanded by provenance, after a verified fetch (A.2).
    prov = classify_local_refs(path, integration_branch=integration_branch)
    if prov["ok"]:
        res["unpushed_branches"] = prov["unlanded"]
        res["landed_refs"] = prov["landed"]
    else:
        res["query_failures"].append(prov["failed_query"])
    res["has_unpushed"] = len(res["unpushed_branches"]) > 0

    # Linked worktrees (if standalone clone) — a failed listing is NOT "no dependents".
    if res["checkout_type"] == "standalone_clone":
        wt_res = run_git(path, ["worktree", "list", "--porcelain"])
        if wt_res.returncode == 0:
            for line in wt_res.stdout.splitlines():
                if line.startswith("worktree "):
                    wt_path = line[len("worktree "):].strip()
                    if Path(wt_path).resolve() != path:
                        res["linked_worktrees"].append(wt_path)
        else:
            res["query_failures"].append(f"git worktree list: {wt_res.stderr.strip() or 'failed'}")

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

    # Session evidence (A.4): the tick event fold, then live file handles. Both binding.
    res["tick_claims"] = inspect_tick_claims(path)
    if res["tick_claims"].get("has_claims"):
        res["disposition"] = "ACTIVE_TICK_CLAIM"
        res["disposition_reason"] = f"Active task claim in .tick: {res['tick_claims'].get('details')}"
        return res
    if not res["tick_claims"].get("verified"):
        res["disposition"] = "PRESERVE_UNVERIFIED_SESSION"
        res["disposition_reason"] = f"Cannot verify tick claims: {res['tick_claims'].get('details')}"
        return res

    res["open_handles"] = inspect_open_handles(path)
    if res["open_handles"].get("active"):
        res["disposition"] = "ACTIVE_PROCESS"
        res["disposition_reason"] = f"Open file handles inside the checkout: {res['open_handles'].get('details')}"
        return res
    if not res["open_handles"].get("verified"):
        res["disposition"] = "PRESERVE_UNVERIFIED_SESSION"
        res["disposition_reason"] = f"Cannot verify the checkout is idle: {res['open_handles'].get('details')}"
        return res

    # Definite evidence first: a dirty tree is preserved as DIRTY whatever else failed.
    if res["is_clean"] is False and res["dirty_count"] > 0:
        res["disposition"] = "PRESERVE_DIRTY"
        res["disposition_reason"] = (f"Working tree is dirty ({res['dirty_count']} modified/untracked files): "
                                     + ", ".join(res["dirty_files"]))
        return res

    # Any safety query that could not answer preserves, naming the query (A.5).
    if res["query_failures"]:
        res["disposition"] = "PRESERVE_UNVERIFIED_QUERY"
        res["disposition_reason"] = "Safety query failed: " + "; ".join(res["query_failures"])
        return res

    if res["stash_count"] > 0:
        res["disposition"] = "PRESERVE_STASH"
        res["disposition_reason"] = f"Checkout has {res['stash_count']} unpopped stash entries"
        return res

    if res["has_unpushed"]:
        res["disposition"] = "PRESERVE_UNPUSHED"
        res["disposition_reason"] = "Unlanded local refs: " + "; ".join(res["unpushed_branches"])
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


def scan_directories(search_roots: List[Path], prefix_filter: Optional[str] = None, primary_repo: Optional[Path] = None, excludes: Optional[List[str]] = None, integration_branch: str = "development") -> List[Dict[str, Any]]:
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

                info = inspect_checkout(resolved, primary_repo_path=primary_repo, exclude_patterns=excludes, integration_branch=integration_branch)
                if info.get("is_git"):
                    results.append(info)
        except PermissionError:
            continue

    # Phase 0: the primary on-disk checkout is inspected because it IS the primary, never
    # because a --prefix or a SAFE_ROOT happened to sweep it up. It is the checkout every PR
    # lands into and every reconciliation runs in, so a scan that silently omits it reports a
    # clean audit for the one tree whose state can break the landing. A primary living outside
    # SAFE_ROOTS, or in a directory whose name does not match --prefix, used to vanish here
    # while Phase 5 went on merging into it.
    if primary_repo:
        try:
            resolved_primary = primary_repo.resolve()
        except OSError:
            resolved_primary = None
        if resolved_primary is not None:
            existing = [c for c in results if Path(c["path"]) == resolved_primary]
            if existing:
                # Discovered by the walk too — promote it, do not duplicate it. Appending in
                # root/name order left a sibling repo above the operator's own tree (R1-F4).
                results.remove(existing[0])
                results.insert(0, existing[0])
            else:
                info = inspect_checkout(resolved_primary, primary_repo_path=primary_repo, exclude_patterns=excludes, integration_branch=integration_branch)
                if info.get("is_git"):
                    results.insert(0, info)

    return results


def inspect_primary_landing(primary_repo: Path, integration_branch: str = "development") -> Dict[str, Any]:
    """Phase 0: can the primary on-disk checkout actually RECEIVE the landing?

    Phase 5 merges PRs remotely and then fast-forwards this tree and runs reconciliation in it.
    Every one of those steps assumes a checkout that is on the integration branch, clean, free of
    a half-finished git operation, and provably an ancestor of the remote tip. None of that was
    ever asserted, so the failure mode was to merge every PR, then discover the local tree could
    not be fast-forwarded and the reconciliation commands were running over uncommitted work.

    Readiness is affirmative: every fact must be positively established. A git query that FAILS
    is unknown state, never a pass — a checkout with no `origin/<branch>` at all used to satisfy
    every condition and be declared ready (R1-F1).

    Never raises. A bad path, an unreadable directory, or a git that will not launch is reported
    as not-ready with the reason (R1-F5).
    """
    res: Dict[str, Any] = {
        "path": str(primary_repo),
        "integration_branch": integration_branch,
        "current_branch": "",
        "is_clean": False,
        "dirty_count": 0,
        "on_integration_branch": False,
        "unpushed_on_integration": 0,
        "can_ff": False,
        "operation_in_progress": "",
        "operation_evidence_ok": True,
        "evidence_complete": False,
        "landing_ready": False,
        "blockers": [],
    }
    try:
        path = Path(primary_repo).expanduser().resolve()
    except (OSError, RuntimeError) as exc:  # ~unknown-user raises RuntimeError, not OSError (R2-4)
        res["blockers"].append(f"cannot resolve primary path {primary_repo}: {exc}")
        return res

    if not (path / ".git").exists():
        res["blockers"].append(f"{path} is not a git checkout")
        return res

    remote_ref = f"origin/{integration_branch}"

    branch = run_git(path, ["rev-parse", "--abbrev-ref", "HEAD"])
    if branch.returncode != 0:
        res["blockers"].append(f"cannot read the current branch: {branch.stderr.strip() or 'git failed'}")
        return res
    res["current_branch"] = branch.stdout.strip()
    res["on_integration_branch"] = res["current_branch"] == integration_branch
    if not res["on_integration_branch"]:
        res["blockers"].append(
            f"on '{res['current_branch'] or 'unknown'}', not the integration branch '{integration_branch}' — "
            f"`git merge --ff-only {remote_ref}` will not land here"
        )

    status = run_git(path, ["status", "--porcelain"])
    if status.returncode != 0:
        res["blockers"].append(f"cannot read working-tree status: {status.stderr.strip() or 'git failed'}")
    else:
        dirty = [ln for ln in status.stdout.splitlines() if ln.strip()]
        res["dirty_count"] = len(dirty)
        res["is_clean"] = not dirty
        if dirty:
            res["blockers"].append(
                f"{len(dirty)} uncommitted path(s) — commit, park, or stash them before landing; "
                "reconciliation would otherwise run over unsaved work"
            )

    # A half-finished merge/rebase/cherry-pick can leave porcelain empty while the operation is
    # still open, and the next merge will refuse. Fail closed; never abort it for the operator.
    for marker, label in (
        ("MERGE_HEAD", "merge"),
        ("REBASE_HEAD", "rebase"),
        ("CHERRY_PICK_HEAD", "cherry-pick"),
        ("REVERT_HEAD", "revert"),
        ("BISECT_LOG", "bisect"),
    ):
        probe = run_git(path, ["rev-parse", "--git-path", marker])
        if probe.returncode != 0:
            # Failing open here would let an unfinished operation ride through as READY (R2-3).
            res["operation_evidence_ok"] = False
            res["blockers"].append(
                f"cannot check for an in-progress {label} ({marker}): "
                f"{probe.stderr.strip() or 'git failed'} — readiness is unknown"
            )
            continue
        marker_path = Path(probe.stdout.strip())
        if not marker_path.is_absolute():
            marker_path = path / marker_path
        if marker_path.exists():
            res["operation_in_progress"] = label
            res["blockers"].append(
                f"an unfinished {label} is in progress ({marker} present) — finish or abort it yourself; "
                "the landing merge will refuse while it is open"
            )
            break

    # Local commits the remote does not have would be silently skipped by a squash-merge landing.
    # A FAILED count is unknown state, not zero.
    ahead = run_git(path, ["rev-list", "--count", f"{remote_ref}..{integration_branch}"])
    ref_evidence = ahead.returncode == 0 and ahead.stdout.strip().isdigit()
    if ref_evidence:
        res["unpushed_on_integration"] = int(ahead.stdout.strip())
        if res["unpushed_on_integration"]:
            res["blockers"].append(
                f"{res['unpushed_on_integration']} local commit(s) on '{integration_branch}' are not on origin — "
                "push or explicitly abandon them first"
            )
    else:
        res["blockers"].append(
            f"cannot compare '{integration_branch}' against '{remote_ref}' — the landing target could not be "
            "resolved, so readiness is unknown (fetch the remote, or check that the branch and remote exist)"
        )

    # Positive ancestry proof against the tip we would fast-forward to.
    ff = run_git(path, ["merge-base", "--is-ancestor", "HEAD", remote_ref])
    res["can_ff"] = ff.returncode == 0
    if not res["can_ff"] and ref_evidence and not res["unpushed_on_integration"]:
        res["blockers"].append(
            f"HEAD is not an ancestor of {remote_ref} — `git merge --ff-only` would refuse"
        )

    res["evidence_complete"] = bool(ref_evidence and res["can_ff"] and res["operation_evidence_ok"])
    res["landing_ready"] = bool(
        res["on_integration_branch"]
        and res["is_clean"]
        and not res["unpushed_on_integration"]
        and not res["operation_in_progress"]
        and res["evidence_complete"]
    )
    return res


def format_primary_landing(info: Dict[str, Any]) -> str:
    """One-glance Phase 0 verdict for the primary checkout."""
    verdict = "READY" if info["landing_ready"] else "NOT READY"
    lines = [
        f"Primary checkout: {info['path']}",
        f"  branch: {info['current_branch'] or '(unknown)'}  (integration: {info['integration_branch']})",
        "  clean: " + ("yes" if info["is_clean"] else f"no ({info['dirty_count']} path(s))"),
        f"  landing: {verdict}",
    ]
    for b in info["blockers"]:
        lines.append(f"    - {b}")
    return "\n".join(lines)


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
    parser.add_argument("--integration-branch", default="development", help="Branch local refs must have landed on (default: development)")

    args = parser.parse_args()

    search_roots = [Path(r).expanduser() for r in args.root] if args.root else DEFAULT_SAFE_ROOTS
    primary_repo = Path(args.primary).expanduser() if args.primary else Path.cwd()

    checkouts = scan_directories(search_roots, prefix_filter=args.prefix, primary_repo=primary_repo, excludes=args.exclude, integration_branch=args.integration_branch)

    if args.json:
        print(json.dumps(checkouts, indent=2))
    else:
        print(f"### Git Checkout Audit ({len(checkouts)} found)\n")
        print(format_scan_table(checkouts))


if __name__ == "__main__":
    main()
