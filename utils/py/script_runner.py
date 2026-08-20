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


def build_sandboxed_cmd(cmd: list[str], containment_root: Optional[str | Path]) -> list[str]:
    """
    Wraps execution command with OS-level sandbox isolation when containment_root is specified.
    On macOS (darwin), applies seatbelt sandbox-exec profile restricting write operations strictly
    to containment_root and /dev.
    On Linux, wraps with bubblewrap (bwrap) if available.
    """
    import shutil

    if not containment_root:
        return cmd

    resolved_root = str(Path(containment_root).resolve())
    if sys.platform == "darwin" and shutil.which("sandbox-exec"):
        seatbelt_profile = (
            f'(version 1) '
            f'(allow default) '
            f'(deny file-write* (regex #"^/")) '
            f'(allow file-write* (subpath "{resolved_root}")) '
            f'(allow file-write* (subpath "/private{resolved_root}")) '
            f'(allow file-write* (subpath "/dev"))'
        )
        return ["sandbox-exec", "-p", seatbelt_profile] + cmd
    elif sys.platform.startswith("linux") and shutil.which("bwrap"):
        return ["bwrap", "--ro-bind", "/", "/", "--bind", resolved_root, resolved_root, "--dev", "/dev", "--proc", "/proc"] + cmd
    return cmd


def run_script_safely(
    code_or_file: str,
    is_file: bool = False,
    language: str = "python",
    work_dir: Optional[str | Path] = None,
    containment_root: Optional[str | Path] = None,
    timeout_s: float = 5.0,
    grace_s: float = 1.0,
    env: Optional[Dict[str, str]] = None,
    max_output_bytes: int = 500000,
) -> Dict[str, Any]:
    """
    Executes a script safely inside a process group with deterministic timeout handling
    and optional containment validation against a sandbox root.
    """
    if timeout_s <= 0:
        raise ValueError("timeout_s must be strictly positive")
    if grace_s < 0:
        raise ValueError("grace_s must be non-negative")

    start_time = time.monotonic()
    resolved_work_dir = Path(work_dir).resolve() if work_dir else Path.cwd()

    # Enforce containment root if specified
    if containment_root:
        valid_root, resolved_root, root_err = validate_path_containment(resolved_work_dir, containment_root)
        if not valid_root:
            return {
                "status": "error",
                "exit_code": 2,
                "duration_ms": 0,
                "stdout": "",
                "stderr": f"Containment violation: work_dir {root_err}",
                "timed_out": False,
            }

    if is_file:
        script_path = Path(code_or_file)
        if not script_path.is_absolute():
            script_path = resolved_work_dir / script_path
        if containment_root:
            valid_file, _, file_err = validate_path_containment(script_path, containment_root)
            if not valid_file:
                return {
                    "status": "error",
                    "exit_code": 2,
                    "duration_ms": 0,
                    "stdout": "",
                    "stderr": f"Containment violation: script_path {file_err}",
                    "timed_out": False,
                }
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
    else:
        if language == "python":
            normalized_code = normalize_script_serialization(code_or_file)
            cmd = [sys.executable, "-c", normalized_code]
        else:
            cmd = ["bash", "-c", code_or_file]

    # Wrap with OS-level seatbelt/bwrap sandbox if containment_root is specified
    if containment_root:
        cmd = build_sandboxed_cmd(cmd, containment_root)

    run_env = os.environ.copy()
    if env:
        run_env.update(env)

    try:
        # start_new_session=True creates a new process group (setsid)
        proc = subprocess.Popen(
            cmd,
            cwd=str(resolved_work_dir),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace",
            env=run_env,
            start_new_session=True,
        )
        pgid = proc.pid
    except Exception as e:
        duration_ms = int((time.monotonic() - start_time) * 1000)
        return {
            "status": "error",
            "exit_code": 1,
            "duration_ms": duration_ms,
            "stdout": "",
            "stderr": f"Process launch failure: {e}",
            "timed_out": False,
        }

    stdout_str = ""
    stderr_str = ""
    timed_out = False

    try:
        stdout_str, stderr_str = proc.communicate(timeout=timeout_s)
    except subprocess.TimeoutExpired:
        timed_out = True
        # Phase 1: Graceful SIGTERM to process group
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
            stdout_str, stderr_str = proc.communicate(timeout=1.0)
        except Exception:
            pass

    duration_ms = int((time.monotonic() - start_time) * 1000)
    exit_code = 124 if timed_out else proc.returncode

    if stdout_str and len(stdout_str) > max_output_bytes:
        stdout_str = stdout_str[:max_output_bytes] + f"\n... [TRUNCATED at {max_output_bytes} chars]"
    if stderr_str and len(stderr_str) > max_output_bytes:
        stderr_str = stderr_str[:max_output_bytes] + f"\n... [TRUNCATED at {max_output_bytes} chars]"

    return {
        "status": "timeout" if timed_out else ("pass" if exit_code == 0 else "fail"),
        "exit_code": exit_code,
        "duration_ms": duration_ms,
        "stdout": stdout_str or "",
        "stderr": stderr_str or "",
        "timed_out": timed_out,
        "pgid": pgid,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Programmatic Script Execution Runner")
    parser.add_argument("--code", type=str, help="Inline script code to execute")
    parser.add_argument("--file", type=str, help="Script file path to execute")
    parser.add_argument("--lang", type=str, default="python", choices=["python", "bash"], help="Script language")
    parser.add_argument("--workdir", type=str, default=".", help="Working directory")
    parser.add_argument("--containment-root", type=str, default=None, help="Sandbox root directory that workdir and file must resolve within")
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
        containment_root=args.containment_root,
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
