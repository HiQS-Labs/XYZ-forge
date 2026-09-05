#!/usr/bin/env python3
"""domain_oracles.py — GH-299 Gen 4 Phase 1: the four semantic domain invariant oracles.

$0-compute, deterministic, <5ms-to-classify invariants that protect developer machines and
CI from state corruption. Each oracle runs a command and proves one thing:

  zero-state       the working tree is byte-identical afterwards (SHA-256 tree digest,
                   excluding __pycache__/.DS_Store) and nothing leaked a file descriptor
                   or a lock handle under the tree (lsof).
  containment      the HOST repo's identity never moved: `.git/config` bytes, `core.bare`,
                   the remote table, HEAD's symbolic ref and its tip are unchanged, and no
                   file under the host root was written while the command ran (GH-564/567).
  idempotence      running the command N times yields identical exit codes, identical
                   output digests, an identical tree digest, and zero duplicate receipts.
  crash-recovery   a holder that is SIGKILLed mid-flight leaves a state the next acquirer
                   can recover from: the recover command exits 0 and every JSONL it owns is
                   line-level valid (no torn writes).

Reuses the Gen 3 primitives (`metamorphic_oracle.check_zero_mutation`, `check_idempotence`,
`check_realpath_containment`) rather than forking them; the Gen 4 additions are the tree
digest, the lsof sweep, the host-identity snapshot, receipt counting and the kill/recover
choreography. Results are emitted as `telemetry_schema.TelemetryEvent` rows (phase="oracle").

CLI:
  domain_oracles.py --mode suite                       # self-test: 4 positive + 4 negative controls
  domain_oracles.py --mode zero-state --cmd "..." --cwd DIR
  domain_oracles.py --mode containment --cmd "..." --cwd WORK --host-root HOSTREPO
  domain_oracles.py --mode idempotence --cmd "..." --cwd DIR [--repetitions 3] [--receipts FILE]
  domain_oracles.py --mode crash-recovery --hold-cmd "..." --recover-cmd "..." --cwd DIR [--jsonl FILE ...]
  domain_oracles.py --mode all --cmd "..." --cwd DIR --host-root HOSTREPO
Add --telemetry-out FILE to append one TelemetryEvent per oracle; --json for a machine result.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from typing import Any, Dict, List, Optional, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from metamorphic_oracle import check_idempotence, check_realpath_containment, check_zero_mutation  # noqa: E402
from telemetry_schema import (  # noqa: E402
    TelemetryEvent,
    append_jsonl,
    event_from_completed,
    new_run_id,
    validate_jsonl,
)

ORACLES = ("zero-state", "containment", "idempotence", "crash-recovery")

# Paths that legitimately churn without meaning the tree changed. `.git/index` is refreshed by
# plain `git status`; the rest are caches. Anything else under `.git/` IS tracked by the digest,
# because a suite that rewrites refs or config has corrupted the clone (GH-45).
DEFAULT_EXCLUDES = ("__pycache__", ".DS_Store", ".pyc", ".git/index", ".git/FETCH_HEAD", ".git/ORIG_HEAD", ".git/logs", ".fuzz_corpus")


# ---- helpers ---------------------------------------------------------------------------------
def _excluded(rel: str, excludes: Tuple[str, ...]) -> bool:
    parts = rel.split("/")
    for ex in excludes:
        if ex.startswith("."):
            if ex.startswith(".git/"):
                if rel == ex or rel.startswith(ex + "/"):
                    return True
            elif rel.endswith(ex) or ex in parts:
                return True
        elif ex in parts:
            return True
    return False


def tree_digest(root: str, excludes: Tuple[str, ...] = DEFAULT_EXCLUDES) -> Tuple[str, int]:
    """SHA-256 over (relative path, mode, content) of every regular file under root, sorted."""
    h = hashlib.sha256()
    count = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        rel_dir = os.path.relpath(dirpath, root)
        rel_dir = "" if rel_dir == "." else rel_dir
        # prune excluded directories early
        dirnames[:] = [d for d in dirnames if not _excluded((rel_dir + "/" + d).lstrip("/"), excludes)]
        for fn in sorted(filenames):
            rel = (rel_dir + "/" + fn).lstrip("/")
            if _excluded(rel, excludes):
                continue
            full = os.path.join(dirpath, fn)
            if os.path.islink(full):
                h.update(f"L {rel} {os.readlink(full)}\n".encode("utf-8", "replace"))
                count += 1
                continue
            if not os.path.isfile(full):
                continue
            try:
                st = os.stat(full)
                h.update(f"F {rel} {oct(st.st_mode & 0o777)}\n".encode("utf-8", "replace"))
                with open(full, "rb") as fh:
                    for chunk in iter(lambda: fh.read(1 << 16), b""):
                        h.update(chunk)
                h.update(b"\n")
                count += 1
            except OSError:
                h.update(f"E {rel}\n".encode("utf-8", "replace"))
    return h.hexdigest(), count


def _run(cmd: List[str], cwd: str, env: Optional[Dict[str, str]], timeout: int) -> Dict[str, Any]:
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    t0 = time.monotonic()
    try:
        res = subprocess.run(cmd, cwd=cwd, env=full_env, capture_output=True, text=True, timeout=timeout)
        rc, out, err = res.returncode, res.stdout, res.stderr
    except subprocess.TimeoutExpired as exc:
        rc = 124
        out = (exc.stdout or b"").decode("utf-8", "replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        err = (exc.stderr or b"").decode("utf-8", "replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        err += f"\n[timeout after {timeout}s]"
    except FileNotFoundError as exc:
        rc, out, err = 127, "", f"command not found: {exc}"
    return {"rc": rc, "stdout": out, "stderr": err, "duration_ms": (time.monotonic() - t0) * 1000.0}


def _git(root: str, *args: str) -> str:
    try:
        return subprocess.run(["git", "-C", root, *args], capture_output=True, text=True, timeout=30).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def lsof_leaks(root: str, extra_paths: Optional[List[str]] = None, timeout: int = 20) -> Dict[str, Any]:
    """Open handles that survive the command: any process holding root, a lock-ish file, or extras.

    Bounded on purpose — `lsof +D` over a whole clone is minutes, so we check the root dir,
    every `*lock*` path within 3 levels, and any caller-supplied paths.
    """
    lsof = shutil.which("lsof")
    if not lsof:
        return {"ok": True, "skipped": "lsof not installed", "holders": []}
    targets = [root]
    for dirpath, dirnames, filenames in os.walk(root):
        depth = os.path.relpath(dirpath, root).count(os.sep)
        if depth >= 3:
            dirnames[:] = []
        for name in list(dirnames) + filenames:
            if "lock" in name.lower():
                targets.append(os.path.join(dirpath, name))
    targets.extend(extra_paths or [])
    targets = [t for t in targets if os.path.exists(t)][:200]
    try:
        res = subprocess.run([lsof, "-n", "-P", "-F", "pcn", "--", *targets], capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"ok": True, "skipped": f"lsof failed: {exc}", "holders": []}
    # Ignore ourselves, our ancestors (the shell that launched us holds root as its cwd) and the
    # lsof children themselves; a leak is a *stranger* holding a handle under the tree, or any
    # process at all holding a lock-ish path.
    ignore = set()
    pid = os.getpid()
    while pid > 1:
        ignore.add(pid)
        try:
            pid = int(subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)], capture_output=True, text=True, timeout=5).stdout.strip() or 0)
        except (OSError, ValueError, subprocess.TimeoutExpired):
            break
    holders: List[Dict[str, str]] = []
    cur: Dict[str, str] = {}
    root_real = os.path.realpath(root)
    for line in res.stdout.splitlines():
        if not line:
            continue
        tag, val = line[0], line[1:]
        if tag == "p":
            cur = {"pid": val}
        elif tag == "c":
            cur["cmd"] = val
        elif tag == "n":
            try:
                hp = int(cur.get("pid", "0"))
            except ValueError:
                continue
            if hp in ignore or cur.get("cmd") == "lsof":
                continue
            is_lock = "lock" in os.path.basename(val).lower()
            if os.path.realpath(val) == root_real and not is_lock:
                continue  # a cwd hold on the root dir by an unrelated process is not a leak
            holders.append({**cur, "path": val})
    return {"ok": not holders, "holders": holders, "targets_checked": len(targets)}


# ---- oracle 1: zero-state --------------------------------------------------------------------
def check_zero_state(
    cmd: List[str],
    cwd: str,
    env: Optional[Dict[str, str]] = None,
    timeout: int = 120,
    excludes: Tuple[str, ...] = DEFAULT_EXCLUDES,
    lsof_paths: Optional[List[str]] = None,
) -> Dict[str, Any]:
    before, n_before = tree_digest(cwd, excludes)
    run = _run(cmd, cwd, env, timeout)
    after, n_after = tree_digest(cwd, excludes)
    leaks = lsof_leaks(cwd, lsof_paths)
    git_view = check_zero_mutation(cmd=["true"], cwd=cwd, timeout=10) if os.path.isdir(os.path.join(cwd, ".git")) else None
    digest_ok = before == after
    reasons: List[str] = []
    if not digest_ok:
        reasons.append(f"tree digest changed ({n_before} -> {n_after} files)")
    if not leaks["ok"]:
        reasons.append(f"{len(leaks['holders'])} leaked handle(s): " + ", ".join(f"pid {h['pid']} {h.get('cmd','?')} {h['path']}" for h in leaks["holders"][:5]))
    return {
        "oracle": "zero-state",
        "passed": digest_ok and leaks["ok"],
        "reasons": reasons,
        "digest_before": before,
        "digest_after": after,
        "files": n_after,
        "lsof": leaks,
        "git_status_clean": None if git_view is None else git_view.get("passed"),
        "run": run,
    }


# ---- oracle 2: host containment ---------------------------------------------------------------
def host_identity(host_root: str) -> Dict[str, Any]:
    cfg = os.path.join(host_root, ".git", "config")
    cfg_hash = ""
    if os.path.isfile(cfg):
        with open(cfg, "rb") as fh:
            cfg_hash = hashlib.sha256(fh.read()).hexdigest()
    return {
        "config_sha256": cfg_hash,
        "core_bare": _git(host_root, "config", "--get", "core.bare"),
        "remotes": _git(host_root, "remote", "-v"),
        "head_ref": _git(host_root, "symbolic-ref", "-q", "HEAD"),
        "head_tip": _git(host_root, "rev-parse", "-q", "--verify", "HEAD"),
        "branches": _git(host_root, "for-each-ref", "--format=%(refname) %(objectname)", "refs/heads", "refs/remotes"),
    }


def _files_modified_since(root: str, since: float, excludes: Tuple[str, ...]) -> List[str]:
    hits: List[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root)
        rel_dir = "" if rel_dir == "." else rel_dir
        dirnames[:] = [d for d in dirnames if not _excluded((rel_dir + "/" + d).lstrip("/"), excludes)]
        for fn in filenames:
            rel = (rel_dir + "/" + fn).lstrip("/")
            if _excluded(rel, excludes):
                continue
            try:
                if os.lstat(os.path.join(dirpath, fn)).st_mtime >= since:
                    hits.append(rel)
            except OSError:
                continue
            if len(hits) >= 50:
                return hits
    return hits


def check_host_containment(
    cmd: List[str],
    work_root: str,
    host_root: str,
    env: Optional[Dict[str, str]] = None,
    timeout: int = 120,
    excludes: Tuple[str, ...] = DEFAULT_EXCLUDES,
    declared_paths: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Run cmd inside work_root and prove host_root's identity and content never moved."""
    reasons: List[str] = []
    # A work root that *is* the host, or sits inside it, cannot prove containment — refuse loudly.
    rh, rw = os.path.realpath(host_root), os.path.realpath(work_root)
    if rw == rh or rw.startswith(rh.rstrip(os.sep) + os.sep):
        return {"oracle": "containment", "passed": False, "reasons": [f"work root {rw} is not disjoint from host root {rh}"], "run": None}
    for p in declared_paths or []:
        ok, why = check_realpath_containment(p, work_root)
        if not ok:
            reasons.append(f"declared path escapes work root: {why}")
    before = host_identity(host_root)
    digest_before, _ = tree_digest(host_root, excludes)
    t_start = time.time()
    run = _run(cmd, work_root, env, timeout)
    after = host_identity(host_root)
    digest_after, _ = tree_digest(host_root, excludes)
    for key in before:
        if before[key] != after[key]:
            reasons.append(f"host {key} changed")
    touched: List[str] = []
    if digest_before != digest_after:
        touched = _files_modified_since(host_root, t_start, excludes)
        reasons.append("host tree digest changed" + (f" — written during run: {', '.join(touched[:5])}" if touched else ""))
    return {
        "oracle": "containment",
        "passed": not reasons,
        "reasons": reasons,
        "host_before": before,
        "host_after": after,
        "host_touched": touched,
        "run": run,
    }


# ---- oracle 3: idempotence & monotonicity -----------------------------------------------------
def _count_lines(path: Optional[str]) -> int:
    if not path or not os.path.exists(path):
        return 0
    with open(path, "rb") as fh:
        return sum(1 for ln in fh if ln.strip())


def check_idempotence_oracle(
    cmd: List[str],
    cwd: str,
    repetitions: int = 3,
    env: Optional[Dict[str, str]] = None,
    timeout: int = 120,
    receipts: Optional[str] = None,
    excludes: Tuple[str, ...] = DEFAULT_EXCLUDES,
) -> Dict[str, Any]:
    """Gen 3 idempotence (rc + output digests) plus Gen 4 tree-digest equality and receipt monotonicity.

    Receipt rule: the FIRST run may append (it may legitimately record its own work); every
    subsequent identical run must append nothing — a duplicate receipt is a bug.
    """
    reasons: List[str] = []
    first = _run(cmd, cwd, env, timeout)
    digest_1, _ = tree_digest(cwd, excludes)
    receipts_1 = _count_lines(receipts)
    inner = check_idempotence(cmd=cmd, repetitions=max(1, repetitions - 1), cwd=cwd, env=env, timeout=timeout)
    digest_n, _ = tree_digest(cwd, excludes)
    receipts_n = _count_lines(receipts)
    if not inner.get("passed", False):
        reasons.append("exit code / output digest diverged across repetitions")
    if digest_1 != digest_n:
        reasons.append("tree digest diverged after repeated runs")
    if receipts and receipts_n != receipts_1:
        reasons.append(f"duplicate receipts: {receipts_1} after run 1, {receipts_n} after run {repetitions}")
    for r in inner.get("results", []) if isinstance(inner.get("results"), list) else []:
        if isinstance(r, dict) and r.get("rc") != first["rc"]:
            reasons.append("exit code differs from first run")
            break
    return {
        "oracle": "idempotence",
        "passed": not reasons,
        "reasons": reasons,
        "repetitions": repetitions,
        "receipts_after_1": receipts_1,
        "receipts_after_n": receipts_n,
        "inner": {k: v for k, v in inner.items() if k != "results"},
        "run": first,
    }


# ---- oracle 4: crash & stale-lock recovery ----------------------------------------------------
def check_crash_recovery(
    hold_cmd: List[str],
    recover_cmd: List[str],
    cwd: str,
    env: Optional[Dict[str, str]] = None,
    ready_file: Optional[str] = None,
    hold_delay: float = 1.0,
    timeout: int = 120,
    jsonl_paths: Optional[List[str]] = None,
    kill_signal: int = signal.SIGKILL,
) -> Dict[str, Any]:
    """Start hold_cmd, SIGKILL it once it is 'in flight', then prove recover_cmd succeeds."""
    reasons: List[str] = []
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    proc = subprocess.Popen(hold_cmd, cwd=cwd, env=full_env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, start_new_session=True)
    deadline = time.monotonic() + max(hold_delay, 0.05)
    if ready_file:
        while time.monotonic() < deadline + timeout and not os.path.exists(ready_file):
            if proc.poll() is not None:
                break
            time.sleep(0.02)
    else:
        while time.monotonic() < deadline and proc.poll() is None:
            time.sleep(0.02)
    exited_early = proc.poll() is not None
    if exited_early:
        reasons.append(f"holder exited before it could be killed (rc={proc.returncode}) — control is vacuous")
    else:
        try:
            os.killpg(proc.pid, kill_signal)
        except ProcessLookupError:
            pass
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            reasons.append("holder survived SIGKILL wait")
    holder_rc = proc.returncode
    rec = _run(recover_cmd, cwd, env, timeout)
    if rec["rc"] != 0:
        reasons.append(f"recover command failed rc={rec['rc']}: {rec['stderr'].strip()[:200]}")
    jsonl_results: Dict[str, Any] = {}
    for p in jsonl_paths or []:
        v = validate_jsonl(p)
        jsonl_results[p] = v
        if not v["ok"]:
            reasons.append(f"{p}: {v['bad']} invalid JSONL line(s)")
    return {
        "oracle": "crash-recovery",
        "passed": not reasons,
        "reasons": reasons,
        "holder_rc": holder_rc,
        "killed": not exited_early,
        "jsonl": jsonl_results,
        "run": rec,
    }


# ---- telemetry emission --------------------------------------------------------------------------
def result_to_event(result: Dict[str, Any], cmd: List[str], run_id: str, env: Optional[Dict[str, str]] = None) -> TelemetryEvent:
    run = result.get("run") or {"rc": 0, "stderr": "", "duration_ms": 0.0}
    ev = event_from_completed(
        "oracle", cmd, int(run.get("rc", 0)), run.get("stderr", ""), float(run.get("duration_ms", 0.0)),
        run_id=run_id, env=env, oracle=result["oracle"], reasons=result.get("reasons", []),
    )
    ev.oracle_results = {result["oracle"]: bool(result["passed"])}
    ev.tier_1_verdict = "pass" if result["passed"] else "fail"
    return ev


# ---- self-test: 4 positive controls + 4 negative (falsification) controls --------------------------
def _write(path: str, text: str, mode: int = 0o644) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(text)
    os.chmod(path, mode)


def run_suite(as_json: bool = False) -> int:
    checks: List[Tuple[str, bool, str]] = []

    def record(name: str, res: Dict[str, Any], expect_pass: bool) -> None:
        ok = bool(res["passed"]) == expect_pass
        checks.append((name, ok, "; ".join(res.get("reasons", [])) or "-"))

    with tempfile.TemporaryDirectory(prefix="gen4-oracles.") as td:
        # --- fixtures: a tiny "host" git repo and a disjoint "work" git clone
        host = os.path.join(td, "host")
        os.makedirs(host)
        subprocess.run(["git", "-C", host, "init", "-q", "-b", "main"], check=True)
        subprocess.run(["git", "-C", host, "config", "user.email", "t@t"], check=True)
        subprocess.run(["git", "-C", host, "config", "user.name", "t"], check=True)
        _write(os.path.join(host, "a.txt"), "hello\n")
        subprocess.run(["git", "-C", host, "add", "."], check=True)
        subprocess.run(["git", "-C", host, "commit", "-q", "-m", "init"], check=True)
        work = os.path.join(td, "work")
        subprocess.run(["git", "clone", "-q", host, work], check=True)
        run_id = new_run_id()

        # 1. zero-state: read-only command keeps digest; a writer breaks it
        record("zero-state (+) read-only ls", check_zero_state(["ls", "-la"], work), True)
        record("zero-state (-) writer detected", check_zero_state(["sh", "-c", "echo x >> a.txt"], work), False)
        subprocess.run(["git", "-C", work, "checkout", "-q", "--", "a.txt"], check=True)

        # 2. containment: work-local write is fine; touching the host's config is caught
        record("containment (+) write inside work root", check_host_containment(["sh", "-c", "echo w > local.tmp"], work, host), True)
        rogue = ["sh", "-c", f"git -C {shlex.quote(host)} config core.bare true"]
        record("containment (-) host core.bare flipped", check_host_containment(rogue, work, host), False)
        subprocess.run(["git", "-C", host, "config", "core.bare", "false"], check=True)

        # 3. idempotence: a receipt writer that de-dups passes; one that always appends fails
        receipts = os.path.join(work, "receipts.jsonl")
        dedup = ["sh", "-c", f"grep -q done {shlex.quote(receipts)} 2>/dev/null || echo '{{\"r\":\"done\"}}' >> {shlex.quote(receipts)}"]
        record("idempotence (+) de-duplicating receipt writer", check_idempotence_oracle(dedup, work, receipts=receipts), True)
        os.remove(receipts)
        dup = ["sh", "-c", f"echo '{{\"r\":\"again\"}}' >> {shlex.quote(receipts)}"]
        record("idempotence (-) duplicate receipts", check_idempotence_oracle(dup, work, receipts=receipts), False)
        os.remove(receipts)

        # 4. crash-recovery: holder takes a lock dir + writes JSONL; recover clears a stale lock
        lock = os.path.join(work, "state.lock")
        log = os.path.join(work, "events.jsonl")
        ready = os.path.join(work, "ready")
        holder = [sys.executable, "-c", (
            "import os,sys,time,json\n"
            f"lock={lock!r}; log={log!r}; ready={ready!r}\n"
            "os.mkdir(lock); open(os.path.join(lock,'pid'),'w').write(str(os.getpid()))\n"
            "for i in range(3): open(log,'a').write(json.dumps({'i':i})+'\\n')\n"
            "open(ready,'w').write('1')\n"
            "time.sleep(30)\n"
        )]
        recover_good = [sys.executable, "-c", (
            "import os,sys,shutil\n"
            f"lock={lock!r}\n"
            "pid=int(open(os.path.join(lock,'pid')).read())\n"
            "try: os.kill(pid,0); alive=True\n"
            "except OSError: alive=False\n"
            "if alive: sys.exit(3)\n"
            "shutil.rmtree(lock); os.mkdir(lock); open(os.path.join(lock,'pid'),'w').write(str(os.getpid())); shutil.rmtree(lock)\n"
        )]
        record("crash-recovery (+) stale lock reclaimed after SIGKILL",
               check_crash_recovery(holder, recover_good, work, ready_file=ready, jsonl_paths=[log]), True)
        for p in (ready, log):
            if os.path.exists(p):
                os.remove(p)
        # negative: recover refuses to break the lock even though the holder is dead
        recover_bad = [sys.executable, "-c", f"import os,sys; sys.exit(0 if not os.path.isdir({lock!r}) else 5)"]
        record("crash-recovery (-) naive acquirer blocked by stale lock",
               check_crash_recovery(holder, recover_bad, work, ready_file=ready, jsonl_paths=[log]), False)
        shutil.rmtree(lock, ignore_errors=True)

        # telemetry bridge sanity
        out = os.path.join(td, "oracles.jsonl")
        append_jsonl(out, result_to_event(check_zero_state(["true"], work), ["true"], run_id))
        checks.append(("telemetry row emitted", validate_jsonl(out)["ok"] and validate_jsonl(out)["lines"] == 1, "-"))

    failed = [c for c in checks if not c[1]]
    if as_json:
        print(json.dumps({"checks": [{"name": n, "ok": ok, "detail": d} for n, ok, d in checks], "passed": not failed}, indent=2))
    else:
        for n, ok, d in checks:
            print(f"  {'PASS' if ok else 'FAIL'}: {n}" + ("" if ok else f" — {d}"))
        print(f"SUITE_RESULT={'PASS' if not failed else 'FAIL'} ({len(checks) - len(failed)}/{len(checks)})")
    return 0 if not failed else 1


# ---- CLI --------------------------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description="GH-299 Gen 4 semantic domain invariant oracles")
    p.add_argument("--mode", choices=["suite", "all", *ORACLES], default="suite")
    p.add_argument("--cmd", help="command under test (shell-split)")
    p.add_argument("--cwd", help="working directory (the WORK/sandbox root)")
    p.add_argument("--host-root", help="host repo whose identity must not move (containment/all)")
    p.add_argument("--env", action="append", default=[], help="KEY=VALUE override (repeatable)")
    p.add_argument("--repetitions", type=int, default=3)
    p.add_argument("--receipts", help="receipt JSONL whose line count must be monotonic (idempotence)")
    p.add_argument("--hold-cmd", help="crash-recovery: command that takes the lock and stays alive")
    p.add_argument("--recover-cmd", help="crash-recovery: command that must succeed after the kill")
    p.add_argument("--ready-file", help="crash-recovery: kill once this file appears (else after --hold-delay)")
    p.add_argument("--hold-delay", type=float, default=1.0)
    p.add_argument("--jsonl", action="append", default=[], help="crash-recovery: JSONL file(s) that must stay line-valid")
    p.add_argument("--lsof-path", action="append", default=[], help="extra path(s) for the leak sweep")
    p.add_argument("--timeout", type=int, default=120)
    p.add_argument("--telemetry-out", help="append one TelemetryEvent per oracle to this JSONL")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    if a.mode == "suite":
        return run_suite(as_json=a.json)

    env = dict(kv.split("=", 1) for kv in a.env if "=" in kv) or None
    cwd = os.path.abspath(a.cwd or os.getcwd())

    def parse_cmd(s: Optional[str], name: str) -> List[str]:
        if not s:
            return []
        try:
            return shlex.split(s)
        except ValueError as e:
            print(f"domain_oracles: invalid {name}: {e}", file=sys.stderr)
            sys.exit(2)

    cmd = parse_cmd(a.cmd, "--cmd")
    run_id = new_run_id()
    results: List[Dict[str, Any]] = []

    def need(cond: bool, msg: str) -> None:
        if not cond:
            print(f"domain_oracles: {msg}", file=sys.stderr)
            sys.exit(2)

    modes = list(ORACLES) if a.mode == "all" else [a.mode]
    if a.mode == "all":
        modes = [m for m in modes if m != "crash-recovery" or (a.hold_cmd and a.recover_cmd)]
        if not a.host_root:
            modes = [m for m in modes if m != "containment"]
    for m in modes:
        if m == "zero-state":
            need(bool(cmd), "--cmd required")
            results.append(check_zero_state(cmd, cwd, env, a.timeout, lsof_paths=a.lsof_path))
        elif m == "containment":
            need(bool(cmd) and bool(a.host_root), "--cmd and --host-root required")
            results.append(check_host_containment(cmd, cwd, os.path.abspath(a.host_root), env, a.timeout))
        elif m == "idempotence":
            need(bool(cmd), "--cmd required")
            results.append(check_idempotence_oracle(cmd, cwd, a.repetitions, env, a.timeout, receipts=a.receipts))
        elif m == "crash-recovery":
            need(bool(a.hold_cmd) and bool(a.recover_cmd), "--hold-cmd and --recover-cmd required")
            results.append(check_crash_recovery(parse_cmd(a.hold_cmd, "--hold-cmd"), parse_cmd(a.recover_cmd, "--recover-cmd"), cwd, env,
                                                a.ready_file, a.hold_delay, a.timeout, a.jsonl))

    if a.telemetry_out:
        for r in results:
            append_jsonl(a.telemetry_out, result_to_event(r, cmd or parse_cmd(a.recover_cmd, "--recover-cmd"), run_id, env))
    all_ok = all(r["passed"] for r in results)
    if a.json:
        slim = [{k: v for k, v in r.items() if k not in ("run",)} | {"rc": (r.get("run") or {}).get("rc")} for r in results]
        print(json.dumps({"run_id": run_id, "passed": all_ok, "results": slim}, indent=2, default=str))
    else:
        for r in results:
            print(f"{'PASS' if r['passed'] else 'FAIL'}: {r['oracle']}" + ("" if r["passed"] else " — " + "; ".join(r["reasons"])))
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
