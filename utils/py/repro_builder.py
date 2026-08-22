#!/usr/bin/env python3
"""Hermetic Reproducer & Hierarchical Delta Minimization (GH-155 Phase 3).

Ingests failure telemetry from fuzzers, oracles, and test suites, executes true hierarchical
delta minimization (ddmin) on environment variables and argument lists, and synthesizes
hermetic, self-contained standalone `repro.sh` reproduction scripts.
"""

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Callable, Dict, List, Optional, Tuple


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

    # Extract command and arguments
    cmd_raw = data.get("cmd") if "cmd" in data else data.get("command", [])
    if isinstance(cmd_raw, str):
        cmd_raw = shlex.split(cmd_raw)

    argv_raw = data.get("argv", [])
    if isinstance(argv_raw, str):
        argv_raw = shlex.split(argv_raw)

    full_cmd = list(cmd_raw) + list(argv_raw)

    env_raw = data.get("env") if "env" in data else data.get("env_overrides", {})

    # Preserve explicit 0 exit codes
    if "exit_code" in data:
        exit_code = data["exit_code"]
    elif "actual_exit_code" in data:
        exit_code = data["actual_exit_code"]
    elif "rc" in data:
        exit_code = data["rc"]
    else:
        exit_code = 1

    if "expected_exit_code" in data:
        expected_exit_code = data["expected_exit_code"]
    else:
        expected_exit_code = exit_code

    stderr = data.get("stderr", "") or data.get("actual_stderr", "")
    stdout = data.get("stdout", "") or data.get("actual_stdout", "")
    err_substring = data.get("err_substring", "") or data.get("expected_err_substring", "")

    return {
        "command": full_cmd,
        "env": dict(env_raw),
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

        if target_err_substring and (target_err_substring not in res.stderr and target_err_substring not in res.stdout):
            return False

        return True
    except subprocess.TimeoutExpired:
        return False
    except OSError:
        return False
    except Exception:
        return False


def ddmin_list(
    items: List[str],
    test_fn: Callable[[List[str]], bool],
    preserve_first_n: int = 0,
) -> List[str]:
    """Hierarchical delta minimization (Zeller ddmin algorithm) on a list of items."""
    prefix = items[:preserve_first_n]
    candidates = items[preserve_first_n:]

    if not candidates:
        return prefix

    # Verify initial reproduction
    if not test_fn(prefix + candidates):
        return items

    n = 2
    while len(candidates) >= 2:
        subsets: List[List[str]] = []
        k = len(candidates) // n
        for i in range(n):
            start = i * k
            end = len(candidates) if i == n - 1 else (i + 1) * k
            subsets.append(candidates[start:end])

        reduced = False
        # 1. Test each subset
        for subset in subsets:
            if test_fn(prefix + subset):
                candidates = subset
                n = max(n - 1, 2)
                reduced = True
                break

        if not reduced:
            # 2. Test each complement
            for subset in subsets:
                complement = [item for item in candidates if item not in subset]
                if complement and test_fn(prefix + complement):
                    candidates = complement
                    n = max(n - 1, 2)
                    reduced = True
                    break

        if not reduced:
            if n == len(candidates):
                break
            n = min(n * 2, len(candidates))

    # Final 1-by-1 fine sweep
    i = len(candidates) - 1
    while i >= 0:
        test_candidate = candidates[:i] + candidates[i + 1:]
        if test_fn(prefix + test_candidate):
            candidates = test_candidate
            i = min(i, len(candidates) - 1)
        else:
            i -= 1

    return prefix + candidates


def minimize_environment(
    base_env: Dict[str, str],
    cmd: List[str],
    repo_root: str,
    target_rc: int,
    target_err_substring: Optional[str] = None,
    essential_keys: Optional[List[str]] = None,
) -> Dict[str, str]:
    """Hierarchical delta minimization (ddmin) on environment variables."""
    essential = set(essential_keys or [])
    non_essential_keys = [k for k in sorted(base_env.keys()) if k not in essential]

    def env_test(active_keys: List[str]) -> bool:
        test_env = {k: base_env[k] for k in active_keys if k in base_env}
        for ek in essential:
            if ek in base_env:
                test_env[ek] = base_env[ek]
        return test_reproduction(cmd, test_env, repo_root, target_rc, target_err_substring)

    minimized_keys = ddmin_list(non_essential_keys, env_test, preserve_first_n=0)
    result = {k: base_env[k] for k in minimized_keys if k in base_env}
    for ek in essential:
        if ek in base_env:
            result[ek] = base_env[ek]
    return result


def minimize_argv(
    base_cmd: List[str],
    env: Dict[str, str],
    repo_root: str,
    target_rc: int,
    target_err_substring: Optional[str] = None,
    keep_first_n: int = 1,
) -> List[str]:
    """Hierarchical delta minimization (ddmin) on command-line arguments."""
    def argv_test(candidate_cmd: List[str]) -> bool:
        return test_reproduction(candidate_cmd, env, repo_root, target_rc, target_err_substring)

    return ddmin_list(base_cmd, argv_test, preserve_first_n=keep_first_n)


def generate_repro_script(
    cmd: List[str],
    env: Dict[str, str],
    target_rc: int,
    target_err_substring: Optional[str] = None,
    title: str = "Automated Failure Reproducer",
    repo_root: Optional[str] = None,
) -> str:
    """Synthesize a standalone, hermetic repro.sh test case script with separate stdout/stderr assertions."""
    cmd_str = " ".join(shlex.quote(arg) for arg in cmd)
    err_check = ""
    if target_err_substring:
        quoted_err = shlex.quote(target_err_substring)
        err_check = f"""
if ! grep -q {quoted_err} <<<"$STDERR" && ! grep -q {quoted_err} <<<"$STDOUT"; then
  echo "FAIL: Expected substring {quoted_err} not found in stdout or stderr"
  echo "STDOUT was: $STDOUT"
  echo "STDERR was: $STDERR"
  exit 1
fi
"""

    env_exports = "\n".join(f"export {k}={shlex.quote(v)}" for k, v in sorted(env.items()))
    if env_exports:
        env_exports += "\n"

    baked_root = (repo_root or "").strip()

    script = f"""#!/usr/bin/env bash
# {title} (Synthesized by utils/py/repro_builder.py - GH-155 Phase 3)
set -euo pipefail

HERE="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
# Resolve root from explicit environment, baked root, or traversal fallback
ROOT="${{XYZ_ROOT:-{baked_root}}}"
if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  ROOT="$(cd "$HERE/.." && pwd)"
fi

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

echo "== Executing minimal reproducer in $ROOT =="
STDOUT_FILE="$WORK/stdout.log"
STDERR_FILE="$WORK/stderr.log"

cd "$ROOT"

RC=0
{cmd_str} > "$STDOUT_FILE" 2> "$STDERR_FILE" || RC=$?

STDOUT="$(cat "$STDOUT_FILE")"
STDERR="$(cat "$STDERR_FILE")"

echo "Command exited with code: $RC"

if [ "$RC" -ne {target_rc} ]; then
  echo "FAIL: Expected exit code {target_rc}, got $RC"
  echo "STDOUT: $STDOUT"
  echo "STDERR: $STDERR"
  exit 1
fi
{err_check}
echo "PASS: Failure reproduced successfully with expected signature (rc={target_rc})"
exit 0
"""
    return script


def run_repro_builder_suite(repo_root: str, as_json: bool = False) -> int:
    """Hermetic self-test suite validating telemetry parsing, ddmin minimization, and script synthesis."""
    if not as_json:
        print("==================================================")
        print(" Hermetic Reproducer & Delta Minimization Suite (GH-155 Phase 3)")
        print("==================================================")

    assertions: List[Tuple[str, bool, str]] = []
    tmp_dir = tempfile.mkdtemp(prefix="repro_suite_")

    try:
        # Create a hermetic test fixture script in tmp_dir
        fixture_script = os.path.join(tmp_dir, "mock_runner.sh")
        with open(fixture_script, "w") as f:
            f.write("""#!/usr/bin/env bash
if [ -z "${REQUIRED_TRIGGER_ENV:-}" ]; then
  echo "mock: REQUIRED_TRIGGER_ENV required" >&2
  exit 2
fi
for arg in "$@"; do
  if [ "$arg" = "--trigger-error" ]; then
    echo "mock: triggered error flag detected" >&2
    exit 42
  fi
done
echo "mock: success"
exit 0
""")
        os.chmod(fixture_script, 0o755)

        # 1. Telemetry parsing test (preserving explicit 0 exit codes)
        sample_telemetry = {
            "command": ["bash", fixture_script],
            "argv": ["--extra-flag-1", "--extra-flag-2"],
            "env": {"REQUIRED_TRIGGER_ENV": "1", "DUMMY_VAR_1": "abc", "DUMMY_VAR_2": "123"},
            "exit_code": 0,
            "expected_exit_code": 0,
            "stderr": "",
            "err_substring": "success",
        }
        rec = parse_failure_telemetry(sample_telemetry)
        t1 = len(rec["command"]) == 4 and rec["exit_code"] == 0 and rec["expected_exit_code"] == 0
        assertions.append(("Telemetry parsing correctly normalizes failure record and preserves explicit 0 exit code", t1, ""))

        # 2. Hierarchical Environment Delta Minimization test (ddmin)
        dirty_env = {
            "DUMMY_ALPHA": "foo",
            "DUMMY_BETA": "bar",
            "DUMMY_GAMMA": "baz",
            "DUMMY_DELTA": "qux",
            "DUMMY_EPSILON": "123",
            "DUMMY_ZETA": "456",
        }
        # Failure occurs when REQUIRED_TRIGGER_ENV is missing -> exits 2 with 'REQUIRED_TRIGGER_ENV required'
        min_env = minimize_environment(
            dirty_env,
            ["bash", fixture_script],
            repo_root,
            target_rc=2,
            target_err_substring="REQUIRED_TRIGGER_ENV required",
        )
        # All dummy variables must be pruned (minimal env is empty)
        t2 = len(min_env) == 0
        assertions.append((f"Hierarchical ddmin pruned all extraneous environment variables ({len(dirty_env)} -> {len(min_env)})", t2, f"Result: {min_env}"))

        # 3. Hierarchical Argv Delta Minimization test (ddmin)
        cmd_with_extraneous_args = [
            "bash",
            fixture_script,
            "--dummy-flag-1",
            "--dummy-flag-2",
            "--dummy-flag-3",
            "--trigger-error",  # The load-bearing flag that triggers exit 42
            "--dummy-flag-4",
            "--dummy-flag-5",
        ]
        min_cmd = minimize_argv(
            cmd_with_extraneous_args,
            {"REQUIRED_TRIGGER_ENV": "1"},
            repo_root,
            target_rc=42,
            target_err_substring="triggered error flag detected",
            keep_first_n=2,
        )
        # Minimized command must keep bash, script, and --trigger-error, but prune all dummy flags
        t3 = len(min_cmd) == 3 and min_cmd[2] == "--trigger-error"
        assertions.append((f"Hierarchical ddmin pruned extraneous argv flags ({len(cmd_with_extraneous_args)} -> {len(min_cmd)})", t3, f"Result: {min_cmd}"))

        # 4. Reproducer Script Generation and Execution test
        repro_code = generate_repro_script(
            min_cmd,
            {"REQUIRED_TRIGGER_ENV": "1"},
            target_rc=42,
            target_err_substring="triggered error flag detected",
            title="Hermetic Fixture Reproducer",
        )
        t4 = "set -euo pipefail" in repro_code and "fixture_guard_init" in repro_code and "triggered error flag detected" in repro_code
        assertions.append(("Reproducer script code generation creates compliant syntax with separate streams", t4, ""))

        # 5. Standalone Execution of generated repro script
        repro_path = os.path.join(tmp_dir, "repro.sh")
        with open(repro_path, "w") as f:
            f.write(repro_code)
        os.chmod(repro_path, 0o755)

        res = subprocess.run(["bash", repro_path], cwd=tmp_dir, capture_output=True, text=True)
        t5 = res.returncode == 0 and "PASS: Failure reproduced successfully" in res.stdout
        assertions.append(("Synthesized repro.sh executes and reproduces failure in isolated sandbox", t5, f"rc={res.returncode}, out={res.stdout}"))

        # 6. Falsifiability Negative Control: Verify that a non-reproducing candidate is rejected
        non_repro_result = test_reproduction(
            ["bash", fixture_script],
            {"REQUIRED_TRIGGER_ENV": "1"},
            repo_root,
            target_rc=42,  # Intentionally wrong expected rc (script without flag exits 0)
        )
        t6 = (non_repro_result is False)
        assertions.append(("Negative control: Non-reproducing candidate correctly rejected", t6, ""))

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

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
            repo_root=repo_root,
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
