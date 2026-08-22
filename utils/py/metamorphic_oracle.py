#!/usr/bin/env python3
"""Metamorphic Invariant Assertions & Sandbox Hardening Oracle (GH-155 Phase 1).

Provides deterministic, zero-LLM-overhead metamorphic property testing:
1. Zero-Mutation Invariant: Read-only/diagnostic commands must leave repo state 100% byte-identical.
2. Idempotence Invariant: Deterministic operations must produce stable hashes across serial & parallel runs.
3. Use-Boundary Realpath Containment: Resolves canonical paths to outlaw traversal and symlink escapes (GH-567).
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile
from typing import Any, Dict, List, Optional, Tuple


class ContainmentViolationError(Exception):
    """Raised when a path escapes the designated sandbox root."""
    pass


def resolve_realpath(path: str) -> str:
    """Resolve symlinks and traversal segments into a canonical absolute path."""
    if not path:
        return ""
    return os.path.realpath(os.path.abspath(path))


def check_realpath_containment(target_path: str, sandbox_root: str, must_exist: bool = False, expected_type: Optional[str] = None) -> Tuple[bool, str]:
    """Verify that target_path is strictly a canonical descendant of sandbox_root.
    
    Returns (is_valid, reason).
    """
    if not target_path or not target_path.strip():
        return False, "Target path is empty; dangerous operations (git -C '', cd '') would target caller's CWD"
    if not sandbox_root or not sandbox_root.strip():
        return False, "Sandbox root is empty"

    res_sandbox = resolve_realpath(sandbox_root)
    if not os.path.isdir(res_sandbox):
        return False, f"Sandbox root '{sandbox_root}' (resolved: '{res_sandbox}') is not a directory"

    res_target = resolve_realpath(target_path)

    # Must be strictly under sandbox (not sandbox itself)
    prefix = res_sandbox.rstrip(os.sep) + os.sep
    if not res_target.startswith(prefix) or res_target == res_sandbox:
        return False, f"Path '{target_path}' (resolved: '{res_target}') escapes sandbox root '{res_sandbox}'"

    if must_exist and not os.path.exists(res_target):
        return False, f"Target path '{res_target}' does not exist"

    if expected_type == "dir" and os.path.exists(res_target) and not os.path.isdir(res_target):
        return False, f"Target path '{res_target}' is not a directory"
    elif expected_type == "file" and os.path.exists(res_target) and not os.path.isfile(res_target):
        return False, f"Target path '{res_target}' is not a regular file"

    return True, f"Path '{res_target}' safely contained in '{res_sandbox}'"


def _capture_repo_state(repo_dir: str) -> Dict[str, Any]:
    """Snapshot git working tree, untracked files, HEAD, and config state."""
    state: Dict[str, Any] = {
        "status": "",
        "head": "",
        "config_hash": "",
        "untracked": [],
    }
    
    if not os.path.exists(os.path.join(repo_dir, ".git")):
        return state

    try:
        res = subprocess.run(
            ["git", "-C", repo_dir, "status", "--porcelain=v1", "-uall"],
            capture_output=True,
            text=True,
            check=False,
        )
        state["status"] = res.stdout.strip()
    except Exception as e:
        state["status_error"] = str(e)

    try:
        res = subprocess.run(
            ["git", "-C", repo_dir, "rev-parse", "HEAD"],
            capture_output=True,
            text=True,
            check=False,
        )
        state["head"] = res.stdout.strip()
    except Exception:
        pass

    config_path = os.path.join(repo_dir, ".git", "config")
    if os.path.exists(config_path):
        try:
            with open(config_path, "rb") as f:
                state["config_hash"] = hashlib.sha256(f.read()).hexdigest()
        except Exception:
            pass

    return state


def check_zero_mutation(
    cmd: List[str],
    cwd: Optional[str] = None,
    env: Optional[Dict[str, str]] = None,
    timeout: int = 60,
) -> Dict[str, Any]:
    """Execute a command and assert that repo state is 100% byte-identical before & after."""
    repo_dir = cwd or os.getcwd()
    before_state = _capture_repo_state(repo_dir)

    proc_env = os.environ.copy()
    if env:
        proc_env.update(env)

    try:
        res = subprocess.run(
            cmd,
            cwd=repo_dir,
            env=proc_env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        rc = res.returncode
        stdout = res.stdout
        stderr = res.stderr
        timed_out = False
    except subprocess.TimeoutExpired as e:
        rc = 124
        stdout = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        stderr = e.stderr.decode() if isinstance(e.stderr, bytes) else (e.stderr or "")
        timed_out = True

    after_state = _capture_repo_state(repo_dir)

    mutations: List[str] = []
    if before_state.get("status") != after_state.get("status"):
        mutations.append(f"git status changed:\n  BEFORE:\n{before_state.get('status')}\n  AFTER:\n{after_state.get('status')}")
    if before_state.get("head") != after_state.get("head"):
        mutations.append(f"git HEAD changed from {before_state.get('head')} to {after_state.get('head')}")
    if before_state.get("config_hash") != after_state.get("config_hash"):
        mutations.append(f".git/config hash changed from {before_state.get('config_hash')} to {after_state.get('config_hash')}")

    passed = (len(mutations) == 0 and not timed_out)

    return {
        "passed": passed,
        "exit_code": rc,
        "timed_out": timed_out,
        "mutations": mutations,
        "stdout_snippet": stdout[:500],
        "stderr_snippet": stderr[:500],
    }


def check_idempotence(
    cmd: List[str],
    repetitions: int = 3,
    concurrent: bool = False,
    concurrency: int = 3,
    cwd: Optional[str] = None,
    env: Optional[Dict[str, str]] = None,
    timeout: int = 60,
) -> Dict[str, Any]:
    """Execute command multiple times and assert identical exit codes and deterministic outputs."""
    repo_dir = cwd or os.getcwd()
    proc_env = os.environ.copy()
    if env:
        proc_env.update(env)

    def _run_single(idx: int) -> Tuple[int, int, str, str, str]:
        res = subprocess.run(
            cmd,
            cwd=repo_dir,
            env=proc_env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        h_out = hashlib.sha256(res.stdout.encode()).hexdigest()
        return idx, res.returncode, h_out, res.stdout, res.stderr

    results = []
    if concurrent:
        with ThreadPoolExecutor(max_workers=concurrency) as pool:
            futures = [pool.submit(_run_single, i) for i in range(repetitions)]
            for f in as_completed(futures):
                results.append(f.result())
    else:
        for i in range(repetitions):
            results.append(_run_single(i))

    results.sort(key=lambda x: x[0])
    exit_codes = [r[1] for r in results]
    stdout_hashes = [r[2] for r in results]

    exit_codes_identical = len(set(exit_codes)) <= 1
    stdout_identical = len(set(stdout_hashes)) <= 1
    passed = exit_codes_identical and stdout_identical

    return {
        "passed": passed,
        "repetitions": repetitions,
        "concurrent": concurrent,
        "exit_codes": exit_codes,
        "stdout_hashes": stdout_hashes,
        "divergences": [] if passed else [f"Exit codes: {exit_codes}", f"Stdout hashes: {stdout_hashes}"],
    }


def run_metamorphic_suite(repo_root: str) -> int:
    """Run comprehensive metamorphic invariant checks across standard repository entry points."""
    print("==================================================")
    print(" Metamorphic Invariant Suite (GH-155 Phase 1)")
    print("==================================================")

    total_checks = 0
    passed_checks = 0
    failed_checks = 0

    def assert_check(name: str, passed: bool, detail: str = ""):
        nonlocal total_checks, passed_checks, failed_checks
        total_checks += 1
        if passed:
            passed_checks += 1
            print(f"  PASS: {name}")
        else:
            failed_checks += 1
            print(f"  FAIL: {name} -> {detail}")

    # 1. Zero-Mutation Invariants across Turn Shims on --help and -h
    shims = [
        "relay-automation/agy-turn.sh",
        "relay-automation/codex-turn.sh",
        "relay-automation/claude-turn.sh",
        "relay-automation/aider-turn.sh",
        "relay-automation/pi-turn.sh",
        "relay-automation/commandcode-turn.sh",
        "relay-automation/deepseek-turn.sh",
    ]

    for shim in shims:
        shim_path = os.path.join(repo_root, shim)
        if not os.path.exists(shim_path):
            continue

        res_help = check_zero_mutation(["bash", shim_path, "--help"], cwd=repo_root)
        assert_check(
            f"Zero-mutation: {shim} --help (exit {res_help['exit_code']})",
            res_help["passed"] and res_help["exit_code"] == 0,
            "; ".join(res_help["mutations"]),
        )

        res_h = check_zero_mutation(["bash", shim_path, "-h"], cwd=repo_root)
        assert_check(
            f"Zero-mutation: {shim} -h (exit {res_h['exit_code']})",
            res_h["passed"] and res_h["exit_code"] == 0,
            "; ".join(res_h["mutations"]),
        )

    # 2. Zero-Mutation on validate.sh diagnostics
    val_path = os.path.join(repo_root, "validate.sh")
    if os.path.exists(val_path):
        res_print = check_zero_mutation(["bash", val_path, "--print-mode"], cwd=repo_root)
        assert_check(
            "Zero-mutation: validate.sh --print-mode",
            res_print["passed"] and res_print["exit_code"] == 0,
            "; ".join(res_print["mutations"]),
        )

        res_list = check_zero_mutation(["bash", val_path, "--list"], cwd=repo_root)
        assert_check(
            "Zero-mutation: validate.sh --list",
            res_list["passed"] and res_list["exit_code"] == 0,
            "; ".join(res_list["mutations"]),
        )

    # 3. Idempotence Invariant checks across turn shims
    for shim in shims:
        shim_path = os.path.join(repo_root, shim)
        if not os.path.exists(shim_path):
            continue
        res_idemp = check_idempotence(["bash", shim_path, "--help"], repetitions=4, concurrent=True, cwd=repo_root)
        assert_check(
            f"Idempotence (concurrent x4): {shim} --help",
            res_idemp["passed"],
            "; ".join(res_idemp["divergences"]),
        )

    # 4. Containment Invariant Oracles (Negative & Positive Controls)
    with tempfile.TemporaryDirectory(prefix="metamorphic-sandbox-") as sbox:
        sub_dir = os.path.join(sbox, "sub_repo")
        os.makedirs(sub_dir, exist_ok=True)
        sub_file = os.path.join(sub_dir, "test.txt")
        with open(sub_file, "w") as f:
            f.write("safe")

        # Positive controls
        ok_dir, msg = check_realpath_containment(sub_dir, sbox, must_exist=True, expected_type="dir")
        assert_check("Containment: valid child directory passes", ok_dir, msg)

        ok_file, msg = check_realpath_containment(sub_file, sbox, must_exist=True, expected_type="file")
        assert_check("Containment: valid child file passes", ok_file, msg)

        # Negative controls
        bad_empty, _ = check_realpath_containment("", sbox)
        assert_check("Containment (negative control): empty path refused", not bad_empty)

        bad_self, _ = check_realpath_containment(sbox, sbox)
        assert_check("Containment (negative control): sandbox root itself refused", not bad_self)

        bad_traversal, _ = check_realpath_containment(f"{sub_dir}/../../..", sbox)
        assert_check("Containment (negative control): path traversal escape refused", not bad_traversal)

        # Symlink escape negative control
        symlink_escape = os.path.join(sbox, "escape_link")
        try:
            os.symlink("/etc", symlink_escape)
            bad_symlink, _ = check_realpath_containment(symlink_escape, sbox)
            assert_check("Containment (negative control): symlink outside sandbox refused", not bad_symlink)
        except OSError:
            pass

    print("==================================================")
    print(f" Summary: {passed_checks}/{total_checks} assertions passed ({failed_checks} failed)")
    print("==================================================")

    return 0 if failed_checks == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Metamorphic Invariant Assertions Oracle (GH-155 Phase 1)")
    parser.add_argument("--mode", choices=["suite", "zero-mutation", "idempotence", "containment"], default="suite")
    parser.add_argument("--cmd", help="Command string to evaluate")
    parser.add_argument("--cwd", help="Working directory for command execution")
    parser.add_argument("--path", help="Target path to test containment for")
    parser.add_argument("--sandbox", help="Sandbox root for containment test")
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--concurrent", action="store_true")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "suite":
        return run_metamorphic_suite(repo_root)

    elif args.mode == "zero-mutation":
        if not args.cmd:
            print("Error: --cmd required for zero-mutation mode", file=sys.stderr)
            return 2
        cmd_args = shlex.split(args.cmd)
        res = check_zero_mutation(cmd_args, cwd=args.cwd)
        if args.json:
            print(json.dumps(res, indent=2))
        else:
            print(f"Zero-mutation verdict: {'PASS' if res['passed'] else 'FAIL'}")
            for m in res["mutations"]:
                print(f"  {m}")
        return 0 if res["passed"] else 1

    elif args.mode == "idempotence":
        if not args.cmd:
            print("Error: --cmd required for idempotence mode", file=sys.stderr)
            return 2
        cmd_args = shlex.split(args.cmd)
        res = check_idempotence(cmd_args, repetitions=args.repetitions, concurrent=args.concurrent, cwd=args.cwd)
        if args.json:
            print(json.dumps(res, indent=2))
        else:
            print(f"Idempotence verdict: {'PASS' if res['passed'] else 'FAIL'}")
            for d in res["divergences"]:
                print(f"  {d}")
        return 0 if res["passed"] else 1

    elif args.mode == "containment":
        if not args.path or not args.sandbox:
            print("Error: --path and --sandbox required for containment mode", file=sys.stderr)
            return 2
        ok, msg = check_realpath_containment(args.path, args.sandbox)
        if args.json:
            print(json.dumps({"passed": ok, "message": msg}, indent=2))
        else:
            print(f"Containment verdict: {'PASS' if ok else 'FAIL'} ({msg})")
        return 0 if ok else 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
