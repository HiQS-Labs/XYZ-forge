#!/usr/bin/env python3
"""Differential Multi-Harness Cross-Testing Oracle (GH-155 Phase 2).

Evaluates identical argument and environment vectors across all 7 turn shims:
1. agy-turn.sh
2. codex-turn.sh
3. claude-turn.sh
4. aider-turn.sh
5. pi-turn.sh
6. commandcode-turn.sh
7. deepseek-turn.sh

Asserts semantic contract parity, exit code alignment, and zero-mutation guarantees.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from typing import Any, Callable, Dict, List, Optional, Tuple

try:
    from metamorphic_oracle import _capture_repo_state
except ImportError:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from metamorphic_oracle import _capture_repo_state

RUNNERS: Dict[str, Dict[str, str]] = {
    "agy": {
        "shim": "relay-automation/agy-turn.sh",
        "agent_env": "AGY_AGENT",
        "name": "agy",
    },
    "codex": {
        "shim": "relay-automation/codex-turn.sh",
        "agent_env": "CODEX_AGENT",
        "name": "codex",
    },
    "claude": {
        "shim": "relay-automation/claude-turn.sh",
        "agent_env": "CLAUDE_AGENT",
        "name": "claude",
    },
    "aider": {
        "shim": "relay-automation/aider-turn.sh",
        "agent_env": "AIDER_AGENT",
        "name": "aider",
    },
    "pi": {
        "shim": "relay-automation/pi-turn.sh",
        "agent_env": "PI_AGENT",
        "name": "pi",
    },
    "commandcode": {
        "shim": "relay-automation/commandcode-turn.sh",
        "agent_env": "COMMANDCODE_AGENT",
        "name": "commandcode",
    },
    "deepseek": {
        "shim": "relay-automation/deepseek-turn.sh",
        "agent_env": "DEEPSEEK_AGENT",
        "name": "deepseek",
    },
}


def _diff_repo_states(before: Dict[str, Any], after: Dict[str, Any]) -> Tuple[bool, List[str]]:
    """Compare before and after repo snapshots for zero-mutation invariant."""
    deltas = []
    if before.get("status") != after.get("status"):
        deltas.append(f"git status changed: before={before.get('status')!r} after={after.get('status')!r}")
    if before.get("head") != after.get("head"):
        deltas.append(f"HEAD ref changed: before={before.get('head')} after={after.get('head')}")
    if before.get("config_hash") != after.get("config_hash"):
        deltas.append(f".git/config modified: before={before.get('config_hash')} after={after.get('config_hash')}")
    if before.get("untracked_hash") != after.get("untracked_hash"):
        deltas.append(f"Untracked files modified: before={before.get('untracked_hash')} after={after.get('untracked_hash')}")
    return len(deltas) == 0, deltas


def normalize_stderr(text: str, runner: str) -> str:
    """Normalize runner-specific prefixes in stderr for differential comparison."""
    # Replace e.g. 'agy-turn:' -> '<runner>-turn:'
    norm = re.sub(rf"\b{re.escape(runner)}-turn\b", "<runner>-turn", text, flags=re.IGNORECASE)
    # Replace e.g. 'AGY_AGENT' -> '<RUNNER>_AGENT'
    agent_env = RUNNERS.get(runner, {}).get("agent_env", "")
    if agent_env:
        norm = norm.replace(agent_env, "<RUNNER>_AGENT")
    # Replace runner names in deferral prose (e.g. 'is not the DeepSeek agent' -> 'is not the <runner> agent')
    norm = re.sub(r"is not the \w+ agent", "is not the <runner> agent", norm, flags=re.IGNORECASE)
    return norm.strip()


def run_single_vector(
    runner: str,
    argv: List[str],
    env_overrides: Dict[str, str],
    repo_root: str,
    timeout: int = 15,
    assert_zero_mutation: bool = True,
) -> Dict[str, Any]:
    """Execute a single vector against a specific runner and capture output & mutation state."""
    meta = RUNNERS[runner]
    shim_path = meta.get("shim", "")
    if not os.path.isabs(shim_path):
        shim_path = os.path.join(repo_root, shim_path)

    if not os.path.exists(shim_path):
        return {
            "runner": runner,
            "available": False,
            "error": f"Shim not found: {shim_path}",
        }

    # Clean isolated environment
    clean_env = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": os.environ.get("HOME", "/tmp"),
        "TMPDIR": os.environ.get("TMPDIR", "/tmp"),
        "XYZ_ROOT": repo_root,
    }
    clean_env.update(env_overrides)

    snap_before = _capture_repo_state(repo_root) if assert_zero_mutation else None

    cmd = ["bash", shim_path] + argv
    t0 = time.perf_counter()
    try:
        res = subprocess.run(
            cmd,
            cwd=repo_root,
            env=clean_env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        duration_ms = round((time.perf_counter() - t0) * 1000, 2)
        rc = res.returncode
        stdout = res.stdout
        stderr = res.stderr
        timed_out = False
    except subprocess.TimeoutExpired as e:
        duration_ms = round((time.perf_counter() - t0) * 1000, 2)
        rc = 124
        stdout = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        stderr = e.stderr.decode() if isinstance(e.stderr, bytes) else (e.stderr or "")
        timed_out = True
    except Exception as exc:
        duration_ms = round((time.perf_counter() - t0) * 1000, 2)
        rc = 255
        stdout = ""
        stderr = str(exc)
        timed_out = False

    mutation_delta = None
    if assert_zero_mutation and snap_before:
        snap_after = _capture_repo_state(repo_root)
        zero_mut_ok, mutation_delta = _diff_repo_states(snap_before, snap_after)
    else:
        zero_mut_ok = True

    norm_err = normalize_stderr(stderr, runner)

    return {
        "runner": runner,
        "available": True,
        "exit_code": rc,
        "stdout": stdout,
        "stderr": stderr,
        "norm_stderr": norm_err,
        "stdout_sha256": hashlib.sha256(stdout.encode()).hexdigest()[:16],
        "duration_ms": duration_ms,
        "timed_out": timed_out,
        "zero_mutation_ok": zero_mut_ok,
        "mutation_delta": mutation_delta,
    }


def evaluate_vector_across_runners(
    name: str,
    argv: List[str],
    env_builder: Any,  # Callable[[str, Dict[str, str]], Dict[str, str]]
    repo_root: str,
    expected_exit_code: Optional[int] = None,
    expected_err_substring: Optional[str] = None,
    assert_zero_mutation: bool = True,
) -> Dict[str, Any]:
    """Run an argument/environment vector across all 7 runners and assert differential consensus."""
    runner_results: Dict[str, Dict[str, Any]] = {}
    exit_codes: Dict[str, int] = {}
    norm_stderrs: Dict[str, str] = {}
    mutation_failures: Dict[str, Any] = {}

    for runner, meta in RUNNERS.items():
        env_for_runner = env_builder(runner, meta) if callable(env_builder) else dict(env_builder)
        res = run_single_vector(runner, argv, env_for_runner, repo_root, assert_zero_mutation=assert_zero_mutation)
        runner_results[runner] = res
        if res.get("available"):
            exit_codes[runner] = res["exit_code"]
            norm_stderrs[runner] = res["norm_stderr"]
            if not res.get("zero_mutation_ok", True):
                mutation_failures[runner] = res.get("mutation_delta")

    unique_exit_codes = set(exit_codes.values())
    exit_code_consensus = (len(unique_exit_codes) == 1)
    consensus_exit_code = list(unique_exit_codes)[0] if exit_code_consensus else None

    matches_expected_rc = True
    if expected_exit_code is not None:
        matches_expected_rc = all(rc == expected_exit_code for rc in exit_codes.values())

    matches_expected_err = True
    if expected_err_substring:
        matches_expected_err = all(expected_err_substring in err for err in norm_stderrs.values())

    zero_mut_passed = (len(mutation_failures) == 0)

    passed = exit_code_consensus and matches_expected_rc and matches_expected_err and zero_mut_passed

    divergences: List[str] = []
    if not exit_code_consensus:
        divergences.append(f"Exit code divergence across runners: {exit_codes}")
    if not matches_expected_rc:
        divergences.append(f"Exit codes {exit_codes} do not match expected {expected_exit_code}")
    if not matches_expected_err:
        divergences.append(f"Normalized stderr missing expected substring '{expected_err_substring}': {norm_stderrs}")
    if not zero_mut_passed:
        divergences.append(f"Zero mutation failed on runners: {mutation_failures}")

    return {
        "vector_name": name,
        "passed": passed,
        "consensus_exit_code": consensus_exit_code,
        "divergences": divergences,
        "exit_codes": exit_codes,
        "runner_results": runner_results,
    }


def get_standard_vectors() -> Dict[str, Tuple[str, List[str], Callable[[str, Dict[str, str]], Dict[str, str]], Optional[int], Optional[str]]]:
    """Return dictionary of canonical differential test vectors."""
    return {
        "help": (
            "Vector 1: Help flag (--help)",
            ["--help"],
            lambda r, m: {},
            0,
            "",
        ),
        "help-short": (
            "Vector 2: Help flag (-h)",
            ["-h"],
            lambda r, m: {},
            0,
            "",
        ),
        "missing-agent": (
            "Vector 3: Missing RELAY_AGENT",
            [],
            lambda r, m: {},
            2,
            "<runner>-turn: RELAY_AGENT required",
        ),
        "missing-file": (
            "Vector 4: Missing RELAY_FILE",
            [],
            lambda r, m: {"RELAY_AGENT": "tester", m["agent_env"]: "tester"},
            2,
            "<runner>-turn: RELAY_FILE required",
        ),
        "missing-runner-agent": (
            "Vector 5: Missing <RUNNER>_AGENT",
            [],
            lambda r, m: {"RELAY_AGENT": "tester", "RELAY_FILE": "RELAY.md"},
            2,
            "<runner>-turn: <RUNNER>_AGENT required",
        ),
        # In XYZ multi-agent coordination, turn shims exit 0 on actor mismatch to allow serial
        # pollers to yield cleanly without process aborts (per GH-308/GH-68 contracts).
        "deferral": (
            "Vector 6: Window-driven deferral (actor != runner agent)",
            [],
            lambda r, m: {"RELAY_AGENT": "alice", m["agent_env"]: "bob", "RELAY_FILE": "RELAY.md"},
            0,
            "deferring (window-driven)",
        ),
        "unknown-argv": (
            "Vector 7: Unknown flag handling (--unknown-flag-xyz)",
            ["--unknown-flag-xyz"],
            lambda r, m: {},
            2,
            "<runner>-turn: RELAY_AGENT required",
        ),
    }


def run_differential_suite(repo_root: str, as_json: bool = False) -> int:
    """Execute the full differential multi-harness parity suite."""
    vectors = get_standard_vectors()
    total = len(vectors)
    passed_count = 0
    failed_count = 0
    results_list: List[Dict[str, Any]] = []

    if not as_json:
        print("==================================================")
        print(" Differential Multi-Harness Parity Suite (GH-155 Phase 2)")
        print("==================================================")

    for key, (name, argv, env_fn, exp_rc, exp_err) in vectors.items():
        res = evaluate_vector_across_runners(name, argv, env_fn, repo_root, exp_rc, exp_err)
        results_list.append(res)
        if res["passed"]:
            passed_count += 1
            if not as_json:
                print(f"  PASS: {name} (7/7 runners agreed at rc={res['consensus_exit_code']})")
        else:
            failed_count += 1
            if not as_json:
                print(f"  FAIL: {name}")
                for d in res["divergences"]:
                    print(f"        -> {d}")

    if as_json:
        payload = {
            "suite": "differential_oracle",
            "passed": failed_count == 0,
            "passed_count": passed_count,
            "total_count": total,
            "results": results_list,
        }
        print(json.dumps(payload, indent=2))
    else:
        print("==================================================")
        print(f" Summary: {passed_count}/{total} differential vectors passed ({failed_count} failed)")
        print(" SUITE_RESULT=PASS" if failed_count == 0 else " SUITE_RESULT=FAIL")
        print("==================================================")

    return 0 if failed_count == 0 else 1


def run_single_vector_mode(vector_key: str, repo_root: str, as_json: bool = False) -> int:
    """Execute a single named differential vector."""
    vectors = get_standard_vectors()
    if vector_key not in vectors:
        print(f"Error: Unknown vector key '{vector_key}'. Available: {list(vectors.keys())}", file=sys.stderr)
        return 2

    name, argv, env_fn, exp_rc, exp_err = vectors[vector_key]
    res = evaluate_vector_across_runners(name, argv, env_fn, repo_root, exp_rc, exp_err)

    if as_json:
        print(json.dumps(res, indent=2))
    else:
        print(f"Vector: {name}")
        print(f"Passed: {res['passed']}")
        print(f"Consensus exit code: {res['consensus_exit_code']}")
        print(f"Runner exit codes: {res['exit_codes']}")
        if not res["passed"]:
            for d in res["divergences"]:
                print(f"  Divergence: {d}")

    return 0 if res["passed"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Differential Multi-Harness Oracle (GH-155 Phase 2)")
    parser.add_argument("--mode", choices=["suite", "vector"], default="suite", help="Run full suite or single vector")
    parser.add_argument("--vector", choices=["help", "help-short", "missing-agent", "missing-file", "missing-runner-agent", "deferral", "unknown-argv"], help="Named vector to run")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "vector":
        if not args.vector:
            print("Error: --vector is required when --mode=vector", file=sys.stderr)
            return 2
        return run_single_vector_mode(args.vector, repo_root, as_json=args.json)

    if args.mode == "suite":
        return run_differential_suite(repo_root, as_json=args.json)

    return 0


if __name__ == "__main__":
    sys.exit(main())
