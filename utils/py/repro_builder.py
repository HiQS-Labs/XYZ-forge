#!/usr/bin/env python3
"""Hermetic Reproducer & Hierarchical Delta Minimization (GH-155 Phase 3).

Ingests failure telemetry from fuzzers, oracles, and test suites, executes deterministic
delta minimization (ddmin) on environment variables and argument lists, and synthesizes
hermetic, self-contained standalone `repro.sh` reproduction scripts.
"""

import argparse
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from typing import Any, Dict, List, Optional, Tuple


def parse_failure_telemetry(raw_data: Any) -> Dict[str, Any]:
    """Parse raw telemetry input (JSON string, dict, or filepath) into normalized failure record."""
    if isinstance(raw_data, str):
        if os.path.exists(raw_data):
            with open(raw_data, "r") as f:
                data = json.load(f)
        else:
            data = json.loads(raw_data)
    elif isinstance(raw_data, dict):
        data = raw_data
    else:
        raise ValueError(f"Unsupported telemetry input type: {type(raw_data)}")

    # Extract or infer standard fields
    cmd = data.get("cmd") or data.get("command") or []
    if isinstance(cmd, str):
        cmd = shlex.split(cmd)

    argv = data.get("argv") or []
    if isinstance(argv, str):
        argv = shlex.split(argv)

    full_cmd = list(cmd) + list(argv)

    env = data.get("env") or data.get("env_overrides") or {}
    exit_code = data.get("exit_code") or data.get("actual_exit_code") or data.get("rc") or 1
    expected_exit_code = data.get("expected_exit_code") or exit_code
    stderr = data.get("stderr") or data.get("actual_stderr") or ""
    stdout = data.get("stdout") or data.get("actual_stdout") or ""
    err_substring = data.get("err_substring") or data.get("expected_err_substring") or ""

    return {
        "command": full_cmd,
        "env": dict(env),
        "exit_code": int(exit_code),
        "expected_exit_code": int(expected_exit_code),
        "stderr": str(stderr),
        "stdout": str(stdout),
        "err_substring": str(err_substring),
        "runner": data.get("runner", "unknown"),
        "source": data.get("source", "telemetry"),
    }


def test_reproduction(
    cmd: List[str],
    env: Dict[str, str],
    repo_root: str,
    target_rc: int,
    target_err_substring: Optional[str] = None,
    timeout: int = 15,
) -> bool:
    """Execute command in clean isolated env and check if target failure reproduces."""
    if not cmd:
        return False

    clean_env = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": os.environ.get("HOME", "/tmp"),
        "TMPDIR": os.environ.get("TMPDIR", "/tmp"),
        "XYZ_ROOT": repo_root,
    }
    clean_env.update(env)

    try:
        res = subprocess.run(
            cmd,
            cwd=repo_root,
            env=clean_env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        if res.returncode != target_rc:
            return False

        if target_err_substring and target_err_substring not in res.stderr and target_err_substring not in res.stdout:
            return False

        return True
    except Exception:
        return False


def minimize_environment(
    base_env: Dict[str, str],
    cmd: List[str],
    repo_root: str,
    target_rc: int,
    target_err_substring: Optional[str] = None,
    essential_keys: Optional[List[str]] = None,
) -> Dict[str, str]:
    """Delta minimize (ddmin) environment variables to find minimal failure trigger."""
    essential = set(essential_keys or [])
    current_env = dict(base_env)

    # First verify initial reproduction
    if not test_reproduction(cmd, current_env, repo_root, target_rc, target_err_substring):
        return current_env

    # 1-by-1 pruning
    keys = list(current_env.keys())
    for k in keys:
        if k in essential:
            continue
        test_env = dict(current_env)
        del test_env[k]
        if test_reproduction(cmd, test_env, repo_root, target_rc, target_err_substring):
            # Still reproduces without key k -> key k is not required
            current_env = test_env

    return current_env


def minimize_argv(
    base_cmd: List[str],
    env: Dict[str, str],
    repo_root: str,
    target_rc: int,
    target_err_substring: Optional[str] = None,
    keep_first_n: int = 1,
) -> List[str]:
    """Delta minimize (ddmin) CLI arguments to find minimal failing argument list."""
    current_cmd = list(base_cmd)
    if len(current_cmd) <= keep_first_n:
        return current_cmd

    # First verify initial reproduction
    if not test_reproduction(current_cmd, env, repo_root, target_rc, target_err_substring):
        return current_cmd

    # Try removing arguments from the end towards the front
    i = len(current_cmd) - 1
    while i >= keep_first_n:
        candidate = current_cmd[:i] + current_cmd[i + 1:]
        if test_reproduction(candidate, env, repo_root, target_rc, target_err_substring):
            current_cmd = candidate
            i = min(i, len(current_cmd) - 1)
        else:
            i -= 1

    return current_cmd


def generate_repro_script(
    cmd: List[str],
    env: Dict[str, str],
    target_rc: int,
    target_err_substring: Optional[str] = None,
    title: str = "Automated Failure Reproducer",
) -> str:
    """Synthesize a standalone, hermetic repro.sh test case script."""
    cmd_str = " ".join(shlex.quote(arg) for arg in cmd)
    err_check = ""
    if target_err_substring:
        quoted_err = shlex.quote(target_err_substring)
        err_check = f"""
if ! grep -q {quoted_err} <<<"$OUT"; then
  echo "FAIL: Expected substring {quoted_err} not found in output"
  echo "Output was: $OUT"
  exit 1
fi
"""

    env_exports = "\n".join(f"export {k}={shlex.quote(v)}" for k, v in sorted(env.items()))
    if env_exports:
        env_exports += "\n"

    script = f"""#!/usr/bin/env bash
# {title} (Synthesized by utils/py/repro_builder.py - GH-155 Phase 3)
set -euo pipefail

HERE="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Initialize sandbox and containment (GH-567)
WORK="$(mktemp -d "${{TMPDIR:-/tmp}}/repro.XXXXXX")"
cleanup() {{ [ -n "${{WORK:-}}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }}
trap cleanup EXIT

if [ -f "$ROOT/test/lib/fixture-guard.sh" ]; then
  . "$ROOT/test/lib/fixture-guard.sh"
  fixture_guard_init "$WORK"
fi

# Minimal reproduction environment
{env_exports}export XYZ_ROOT="$ROOT"

echo "== Executing minimal reproducer =="
RC=0
OUT="$({cmd_str} 2>&1)" || RC=$?

echo "Command exited with code: $RC"

if [ "$RC" -ne {target_rc} ]; then
  echo "FAIL: Expected exit code {target_rc}, got $RC"
  echo "Output was: $OUT"
  exit 1
fi
{err_check}
echo "PASS: Failure reproduced successfully with expected signature (rc={target_rc})"
exit 0
"""
    return script


def run_repro_builder_suite(repo_root: str, as_json: bool = False) -> int:
    """Self-test suite validating telemetry parsing, ddmin minimization, and script synthesis."""
    if not as_json:
        print("==================================================")
        print(" Hermetic Reproducer & Delta Minimization Suite (GH-155 Phase 3)")
        print("==================================================")

    assertions: List[Tuple[str, bool, str]] = []

    # 1. Telemetry parsing test
    sample_telemetry = {
        "command": ["bash", "relay-automation/agy-turn.sh"],
        "argv": ["--extra-flag-1", "--extra-flag-2"],
        "env": {"RELAY_AGENT": "tester", "DUMMY_VAR_1": "abc", "DUMMY_VAR_2": "123"},
        "exit_code": 2,
        "stderr": "agy-turn: RELAY_FILE required",
        "err_substring": "RELAY_FILE required",
    }
    rec = parse_failure_telemetry(sample_telemetry)
    t1 = len(rec["command"]) == 4 and rec["exit_code"] == 2 and rec["err_substring"] == "RELAY_FILE required"
    assertions.append(("Telemetry parsing correctly normalizes failure record", t1, ""))

    # 2. Environment Delta Minimization test
    # Target: agy-turn.sh with missing RELAY_FILE exits 2 with 'RELAY_FILE required'
    # Start with 5 dummy environment variables + 1 essential (RELAY_AGENT=tester)
    dirty_env = {
        "RELAY_AGENT": "tester",
        "AGY_AGENT": "tester",
        "DUMMY_ALPHA": "foo",
        "DUMMY_BETA": "bar",
        "DUMMY_GAMMA": "baz",
        "DUMMY_DELTA": "qux",
    }
    min_env = minimize_environment(
        dirty_env,
        ["bash", os.path.join(repo_root, "relay-automation/agy-turn.sh")],
        repo_root,
        target_rc=2,
        target_err_substring="RELAY_FILE required",
    )
    # The minimal env only requires RELAY_AGENT and AGY_AGENT; dummy variables must be pruned
    t2 = "DUMMY_ALPHA" not in min_env and "DUMMY_BETA" not in min_env and "RELAY_AGENT" in min_env
    assertions.append((f"Delta minimization pruned extraneous environment variables ({len(dirty_env)} -> {len(min_env)})", t2, f"Result: {min_env}"))

    # 3. Argv Delta Minimization test
    # Target: agy-turn.sh with missing RELAY_AGENT exits 2
    cmd_with_extraneous_args = [
        "bash",
        os.path.join(repo_root, "relay-automation/agy-turn.sh"),
        "--arbitrary-opt-1",
        "--arbitrary-opt-2",
        "--arbitrary-opt-3",
    ]
    min_cmd = minimize_argv(
        cmd_with_extraneous_args,
        {},
        repo_root,
        target_rc=2,
        target_err_substring="RELAY_AGENT required",
        keep_first_n=2,  # Keep 'bash' and shim script
    )
    t3 = len(min_cmd) == 2 and min_cmd[0] == "bash"
    assertions.append((f"Delta minimization pruned extraneous argv flags ({len(cmd_with_extraneous_args)} -> {len(min_cmd)})", t3, f"Result: {min_cmd}"))

    # 4. Reproducer Script Generation and Execution test
    repro_code = generate_repro_script(
        ["bash", os.path.join(repo_root, "relay-automation/codex-turn.sh")],
        {"RELAY_AGENT": "tester", "CODEX_AGENT": "tester"},
        target_rc=2,
        target_err_substring="RELAY_FILE required",
        title="Test Codegen Reproducer",
    )
    t4 = "set -euo pipefail" in repro_code and "fixture_guard_init" in repro_code and "RELAY_FILE required" in repro_code
    assertions.append(("Reproducer script code generation creates compliant syntax", t4, ""))

    # 5. Standalone Execution of generated repro script in temporary directory
    tmp_dir = tempfile.mkdtemp(prefix="repro_test_")
    repro_path = os.path.join(tmp_dir, "repro.sh")
    with open(repro_path, "w") as f:
        f.write(repro_code)
    os.chmod(repro_path, 0o755)

    res = subprocess.run(["bash", repro_path], cwd=tmp_dir, capture_output=True, text=True)
    t5 = res.returncode == 0 and "PASS: Failure reproduced successfully" in res.stdout
    subprocess.run(["rm", "-rf", tmp_dir])
    assertions.append(("Synthesized repro.sh executes and reproduces failure in isolated sandbox", t5, f"rc={res.returncode}, out={res.stdout}"))

    # 6. Falsifiability Negative Control: Verify that a non-reproducing candidate is rejected
    non_repro_result = test_reproduction(
        ["bash", os.path.join(repo_root, "relay-automation/agy-turn.sh"), "--help"],
        {},
        repo_root,
        target_rc=42,  # Intentionally wrong expected rc
    )
    t6 = (non_repro_result is False)
    assertions.append(("Negative control: Non-reproducing candidate correctly rejected", t6, ""))

    passed_count = sum(1 for _, ok, _ in assertions if ok)
    total_count = len(assertions)
    failed_count = total_count - passed_count

    if as_json:
        payload = {
            "suite": "repro_builder",
            "passed": failed_count == 0,
            "passed_count": passed_count,
            "total_count": total_count,
            "assertions": [{"name": name, "passed": ok, "details": det} for name, ok, det in assertions],
        }
        print(json.dumps(payload, indent=2))
    else:
        for name, ok, det in assertions:
            status = "PASS" if ok else "FAIL"
            print(f"  {status}: {name}")
            if not ok and det:
                print(f"        -> {det}")
        print("==================================================")
        print(f" Summary: {passed_count}/{total_count} assertions passed ({failed_count} failed)")
        print(" SUITE_RESULT=PASS" if failed_count == 0 else " SUITE_RESULT=FAIL")
        print("==================================================")

    return 0 if failed_count == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Hermetic Reproducer & Delta Minimization (GH-155 Phase 3)")
    parser.add_argument("--mode", choices=["suite", "build", "minimize"], default="suite", help="Execution mode")
    parser.add_argument("--telemetry", help="Path to telemetry JSON file or raw JSON string")
    parser.add_argument("--output", help="Output path for synthesized repro.sh")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "suite":
        return run_repro_builder_suite(repo_root, as_json=args.json)

    if args.mode in ("build", "minimize"):
        if not args.telemetry:
            print("Error: --telemetry is required for build/minimize mode", file=sys.stderr)
            return 2
        record = parse_failure_telemetry(args.telemetry)
        min_env = minimize_environment(
            record["env"],
            record["command"],
            repo_root,
            record["expected_exit_code"],
            record["err_substring"],
        )
        min_cmd = minimize_argv(
            record["command"],
            min_env,
            repo_root,
            record["expected_exit_code"],
            record["err_substring"],
        )
        repro_script = generate_repro_script(
            min_cmd,
            min_env,
            record["expected_exit_code"],
            record["err_substring"],
            title=f"Reproducer for {record.get('runner', 'command')}",
        )

        if args.output:
            with open(args.output, "w") as f:
                f.write(repro_script)
            os.chmod(args.output, 0o755)
            print(f"Wrote hermetic reproducer to {args.output}")
        else:
            print(repro_script)
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
