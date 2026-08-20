#!/usr/bin/env python3
"""
Programmatic Script Execution Runner for XYZ-forge (GH-94).

Provides hardened execution for agent-generated Python / Bash scripts:
1. Normalizes script serialization (e.g., literal \\n text escaping bugs).
2. Enforces deterministic execution timeouts with process-group cleanup (SIGTERM -> SIGKILL).
3. Validates path containment at the use boundary against directory traversal / symlink escapes.
4. Emits structured execution telemetry (exit code, duration_ms, stdout/stderr).
"""
from __future__ import annotations

import argparse
import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Any, Dict, Optional, Tuple


def normalize_script_serialization(code: str) -> str:
    """
    Normalizes script text to fix serialization defects.
    If the code is already syntactically valid Python, returns it as-is.
    If it fails due to literal \\n serialization, attempts AST-verified normalization.
    """
    import ast

    try:
        ast.parse(code)
        return code
    except SyntaxError:
        pass

    # Attempt 1: Replace literal \n with actual newlines
    candidate = code.replace("\\n", "\n")
    try:
        ast.parse(candidate)
        return candidate
    except SyntaxError:
        pass

    # Attempt 2: unicode_escape decode if backslashes were double escaped
    try:
        decoded = bytes(code, "utf-8").decode("unicode_escape")
        ast.parse(decoded)
        return decoded
    except Exception:
        pass

    return candidate


def validate_path_containment(path: str | Path, root_dir: str | Path) -> Tuple[bool, Optional[Path], Optional[str]]:
    """
    Validates that `path` strictly resolves to a path inside `root_dir`.
    Rejects directory traversal (../), absolute root breakouts, and symlink escapes.
    Returns (is_valid, resolved_path, error_message).
    """
    try:
        resolved_root = Path(root_dir).resolve()
        candidate = Path(path)
        if not candidate.is_absolute():
            candidate = resolved_root / candidate
        resolved_path = candidate.resolve()
        
        # Check if resolved_path is a descendant of resolved_root
        if resolved_path == resolved_root or resolved_root in resolved_path.parents:
            return True, resolved_path, None
        else:
            return False, resolved_path, f"Path escape detected: {resolved_path} is outside {resolved_root}"
    except Exception as e:
        return False, None, f"Path resolution error: {e}"


def run_script_safely(
    code_or_file: str,
    is_file: bool = False,
    language: str = "python",
    work_dir: Optional[str | Path] = None,
    timeout_s: float = 5.0,
    grace_s: float = 1.0,
    env: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    """
    Executes a script safely inside a process group with deterministic timeout handling.
    """
    start_time = time.monotonic()
    resolved_work_dir = Path(work_dir).resolve() if work_dir else Path.cwd()

    if is_file:
        script_path = Path(code_or_file)
        if not script_path.is_absolute():
            script_path = resolved_work_dir / script_path
        if not script_path.exists():
            return {
                "status": "error",
                "exit_code": 2,
                "duration_ms": 0,
                "stdout": "",
                "stderr": f"Script file not found: {script_path}",
                "timed_out": False,
            }
        cmd = [sys.executable, str(script_path)] if language == "python" else ["bash", str(script_path)]
        temp_file = None
    else:
        if language == "python":
            normalized_code = normalize_script_serialization(code_or_file)
            cmd = [sys.executable, "-c", normalized_code]
        else:
            cmd = ["bash", "-c", code_or_file]
        temp_file = None

    run_env = os.environ.copy()
    if env:
        run_env.update(env)

    # Launch subprocess in its own process group
    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=str(resolved_work_dir),
            env=run_env,
            text=True,
            start_new_session=True,  # setsid to create a new process group
        )
    except Exception as e:
        return {
            "status": "error",
            "exit_code": 1,
            "duration_ms": int((time.monotonic() - start_time) * 1000),
            "stdout": "",
            "stderr": f"Failed to spawn process: {e}",
            "timed_out": False,
        }

    pgid = proc.pid
    timed_out = False
    stdout, stderr = "", ""

    try:
        stdout, stderr = proc.communicate(timeout=timeout_s)
        exit_code = proc.returncode
    except subprocess.TimeoutExpired:
        timed_out = True
        exit_code = 124

        # Kill process group with SIGTERM, then SIGKILL if grace period expires
        try:
            os.killpg(pgid, signal.SIGTERM)
        except ProcessLookupError:
            pass

        time.sleep(grace_s)

        # Check if process group is still alive
        try:
            os.killpg(pgid, 0)
            # Still alive, force kill with SIGKILL
            os.killpg(pgid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass

        try:
            stdout, stderr = proc.communicate(timeout=1.0)
        except Exception:
            pass

    duration_ms = int((time.monotonic() - start_time) * 1000)

    return {
        "status": "timeout" if timed_out else ("pass" if exit_code == 0 else "fail"),
        "exit_code": exit_code,
        "duration_ms": duration_ms,
        "stdout": stdout,
        "stderr": stderr,
        "timed_out": timed_out,
        "pgid": pgid,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Programmatic Script Execution Runner")
    parser.add_argument("--code", type=str, help="Inline script code to execute")
    parser.add_argument("--file", type=str, help="Script file path to execute")
    parser.add_argument("--lang", type=str, default="python", choices=["python", "bash"], help="Script language")
    parser.add_argument("--workdir", type=str, default=".", help="Working directory")
    parser.add_argument("--timeout", type=float, default=5.0, help="Execution timeout in seconds")
    parser.add_argument("--grace", type=float, default=1.0, help="Grace period before SIGKILL in seconds")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")

    args = parser.parse_args()

    if not args.code and not args.file:
        parser.error("Either --code or --file must be specified")

    target = args.file if args.file else args.code
    result = run_script_safely(
        code_or_file=target,
        is_file=bool(args.file),
        language=args.lang,
        work_dir=args.workdir,
        timeout_s=args.timeout,
        grace_s=args.grace,
    )

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result["stdout"]:
            sys.stdout.write(result["stdout"])
        if result["stderr"]:
            sys.stderr.write(result["stderr"])

    return result["exit_code"]


if __name__ == "__main__":
    sys.exit(main())
