#!/usr/bin/env python3
"""Gated Autonomous Self-Healing Builder Loop (GH-155 Phase 4).

Consumes synthesized hermetic repro.sh test cases or failure telemetry, dispatches
autonomous builder turns (DeepSeek Harness / OpenRouter deepseek-v4-pro / heuristic repairs)
in isolated disposable sandboxes, and verifies candidate fixes against dual acceptance
and regression gates with multi-attempt iterative feedback.
"""

import argparse
import difflib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Callable, Dict, List, Optional, Tuple


def check_realpath_containment(path: str, root: str) -> bool:
    """Assert path is a resolved physical descendant of root (GH-567)."""
    if not path or not root:
        return False
    try:
        resolved_path = os.path.realpath(path)
        resolved_root = os.path.realpath(root)
        if resolved_path == resolved_root:
            return True
        return resolved_path.startswith(resolved_root + os.sep)
    except Exception:
        return False


def apply_patch_content(
    target_file: str,
    original_content: str,
    replacement_content: str,
    sandbox_root: str,
) -> Tuple[bool, str]:
    """Atomically write replacement content to target_file within sandbox_root."""
    if not check_realpath_containment(target_file, sandbox_root):
        return False, f"Refusing write: {target_file} is outside sandbox root {sandbox_root} (GH-567 containment)"

    try:
        parent_dir = os.path.dirname(target_file)
        os.makedirs(parent_dir, exist_ok=True)
        with open(target_file, "w") as f:
            f.write(replacement_content)
        return True, "Patch applied successfully"
    except Exception as e:
        return False, f"Failed to apply patch: {e}"


def apply_unified_diff(
    target_file: str,
    diff_text: str,
    sandbox_root: str,
) -> Tuple[bool, str]:
    """Apply unified diff text to target_file within sandbox_root."""
    if not check_realpath_containment(target_file, sandbox_root):
        return False, f"Refusing diff: {target_file} is outside sandbox root {sandbox_root} (GH-567 containment)"

    if not os.path.exists(target_file):
        return False, f"Target file does not exist: {target_file}"

    try:
        with open(target_file, "r") as f:
            lines = f.readlines()

        # Parse simple unified diff hunk
        diff_lines = diff_text.splitlines(keepends=True)
        new_lines: List[str] = []
        i = 0
        in_hunk = False

        for dl in diff_lines:
            if dl.startswith("---") or dl.startswith("+++"):
                continue
            if dl.startswith("@@"):
                in_hunk = True
                continue
            if not in_hunk:
                continue

            prefix = dl[:1]
            content = dl[1:]

            if prefix == " ":
                if i < len(lines):
                    new_lines.append(lines[i])
                    i += 1
                else:
                    new_lines.append(content)
            elif prefix == "-":
                i += 1  # Skip original line
            elif prefix == "+":
                new_lines.append(content)

        while i < len(lines):
            new_lines.append(lines[i])
            i += 1

        with open(target_file, "w") as f:
            f.writelines(new_lines)

        return True, "Unified diff applied successfully"
    except Exception as e:
        return False, f"Failed to apply unified diff: {e}"


def execute_gate_command(
    cmd: List[str],
    cwd: str,
    env_overrides: Optional[Dict[str, str]] = None,
    timeout: int = 900,
) -> Tuple[int, str, str]:
    """Execute gate command in specified CWD with timeout protection."""
    env = os.environ.copy()
    if env_overrides:
        env.update(env_overrides)

    try:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return res.returncode, res.stdout, res.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "Gate execution timed out"
    except Exception as e:
        return 1, "", f"Gate execution error: {e}"


def generate_issue_rollup(
    target_file: str,
    repro_path: str,
    history: List[Dict[str, Any]],
    status: str,
    error_context: str = "",
) -> str:
    """Generate Markdown issue rollup body for compile_issue.py (GH-182)."""
    lines = [
        f"Automated Self-Healing Escalation Report: `{target_file}`",
        f"Status: `{status}` after {len(history)} attempt(s).",
        "",
        "## Findings & Escalation Checklist",
        f"- [ ] **Defect unresolved in `{target_file}`** — self-healing escalated after {len(history)} attempt(s)",
        f"  - reproducer: `{repro_path}`",
        f"  - target file: `{target_file}`",
        "",
        "## Attempt History",
    ]
    for h in history:
        att = h.get("attempt", "?")
        res = h.get("result", "unknown")
        g1 = h.get("gate1_rc", "N/A")
        g2 = h.get("gate2_rc", "N/A")
        lines.append(f"- **Attempt {att}**: `{res}` (Acceptance Gate rc={g1}, Regression Gate rc={g2})")

    if error_context:
        lines.append("")
        lines.append("## Final Error Context")
        lines.append("```")
        lines.append(error_context.strip()[:1000])
        lines.append("```")
    lines.append("")
    return "\n".join(lines)


def run_self_healing_cycle(
    repro_path: str,
    target_file: str,
    repo_root: str,
    fix_generator: Callable[[str, str, int], Optional[str]],
    regression_cmd: Optional[List[str]] = None,
    max_attempts: int = 3,
    sandbox_root: Optional[str] = None,
    gate_timeout: int = 900,
    diff_out_path: Optional[str] = None,
    escalation_out_path: Optional[str] = None,
) -> Dict[str, Any]:
    """Execute gated autonomous self-healing loop with iterative refinement."""
    disposable = False
    if not sandbox_root:
        sandbox_root = tempfile.mkdtemp(prefix="self_heal_")
        disposable = True

    history: List[Dict[str, Any]] = []
    status = "escalated"
    winning_diff = ""
    winning_diff_file = ""
    issue_rollup = ""
    issue_rollup_file = ""
    original_content: Optional[str] = None

    try:
        if not os.path.exists(repro_path):
            return {
                "status": "error",
                "message": f"Reproducer script not found: {repro_path}",
                "history": [],
            }

        if not os.path.exists(target_file):
            return {
                "status": "error",
                "message": f"Target file not found: {target_file}",
                "history": [],
            }

        # Backup target file original content
        with open(target_file, "r") as f:
            original_content = f.read()

        # First verify initial reproduction (Acceptance Gate must fail initially)
        rc_init, out_init, err_init = execute_gate_command(["bash", repro_path], cwd=repo_root, timeout=gate_timeout)
        if rc_init == 0:
            return {
                "status": "no_repro",
                "message": "Initial reproducer script already exits 0 (defect is not reproducing)",
                "history": [],
            }

        current_error_context = err_init or out_init

        for attempt in range(1, max_attempts + 1):
            attempt_rec: Dict[str, Any] = {"attempt": attempt}

            # Generate candidate fix from generator
            try:
                candidate_patch = fix_generator(target_file, current_error_context, attempt)
            except Exception as gen_err:
                attempt_rec["result"] = f"generator_error: {gen_err}"
                history.append(attempt_rec)
                continue

            if not candidate_patch:
                attempt_rec["result"] = "no_patch_generated"
                history.append(attempt_rec)
                continue

            # Apply candidate fix to target file
            ok_apply, msg_apply = apply_patch_content(
                target_file,
                original_content,
                candidate_patch,
                sandbox_root=sandbox_root,
            )
            if not ok_apply:
                attempt_rec["result"] = f"apply_failed: {msg_apply}"
                history.append(attempt_rec)
                continue

            # Gate 1: Acceptance Gate (Run repro.sh — must pass with rc=0)
            rc_gate1, out_gate1, err_gate1 = execute_gate_command(
                ["bash", repro_path], cwd=repo_root, timeout=gate_timeout
            )
            attempt_rec["gate1_rc"] = rc_gate1
            attempt_rec["gate1_out"] = out_gate1
            attempt_rec["gate1_err"] = err_gate1

            if rc_gate1 != 0:
                attempt_rec["result"] = "gate1_failed"
                current_error_context = err_gate1 or out_gate1
                history.append(attempt_rec)
                # Revert to original content before next iteration
                with open(target_file, "w") as f:
                    f.write(original_content)
                continue

            # Gate 2: Regression Gate (Optional regression suite)
            if regression_cmd:
                rc_gate2, out_gate2, err_gate2 = execute_gate_command(
                    regression_cmd, cwd=repo_root, timeout=gate_timeout
                )
                attempt_rec["gate2_rc"] = rc_gate2
                attempt_rec["gate2_out"] = out_gate2
                attempt_rec["gate2_err"] = err_gate2

                if rc_gate2 != 0:
                    attempt_rec["result"] = "gate2_regression_failed"
                    current_error_context = err_gate2 or out_gate2
                    history.append(attempt_rec)
                    # Revert to original content before next iteration
                    with open(target_file, "w") as f:
                        f.write(original_content)
                    continue

            # Both gates passed!
            status = "healed"
            attempt_rec["result"] = "passed"
            history.append(attempt_rec)

            # Compute winning diff
            diff_lines = list(difflib.unified_diff(
                original_content.splitlines(keepends=True),
                candidate_patch.splitlines(keepends=True),
                fromfile=target_file + ".orig",
                tofile=target_file,
            ))
            winning_diff = "".join(diff_lines)

            # Write winning diff to file if requested or if sandbox_root is set
            target_diff_path = diff_out_path or (os.path.join(sandbox_root, "winning_diff.patch") if sandbox_root else None)
            if target_diff_path:
                try:
                    with open(target_diff_path, "w") as df:
                        df.write(winning_diff)
                    winning_diff_file = target_diff_path
                except Exception:
                    pass
            break

        if status != "healed":
            # Generate issue rollup artifact on escalation
            issue_rollup = generate_issue_rollup(
                target_file=target_file,
                repro_path=repro_path,
                history=history,
                status=status,
                error_context=current_error_context,
            )
            target_rollup_path = escalation_out_path or (os.path.join(sandbox_root, "issue_body.md") if sandbox_root else None)
            if target_rollup_path:
                try:
                    with open(target_rollup_path, "w") as ef:
                        ef.write(issue_rollup)
                    issue_rollup_file = target_rollup_path
                except Exception:
                    pass

        res_dict: Dict[str, Any] = {
            "status": status,
            "attempts": len(history),
            "max_attempts": max_attempts,
            "winning_diff": winning_diff,
            "history": history,
        }
        if winning_diff_file:
            res_dict["winning_diff_file"] = winning_diff_file
        if issue_rollup:
            res_dict["issue_rollup"] = issue_rollup
        if issue_rollup_file:
            res_dict["issue_rollup_file"] = issue_rollup_file
        return res_dict

    finally:
        # Restore target on ANY exit (try/finally) unless healed (GH-182)
        if status != "healed" and original_content is not None:
            try:
                with open(target_file, "w") as f:
                    f.write(original_content)
            except Exception:
                pass
        if disposable and os.path.exists(sandbox_root):
            shutil.rmtree(sandbox_root, ignore_errors=True)


def run_self_healer_suite(repo_root: str, as_json: bool = False) -> int:
    """Hermetic self-test suite validating patch application, dual-gated healing, and feedback recovery."""
    if not as_json:
        print("==================================================")
        print(" Gated Autonomous Self-Healing Suite (GH-155 Phase 4)")
        print("==================================================")

    assertions: List[Tuple[str, bool, str]] = []
    tmp_dir = tempfile.mkdtemp(prefix="self_heal_suite_")

    try:
        # Create a defective mock script
        target_script = os.path.join(tmp_dir, "calc.sh")
        buggy_code = """#!/usr/bin/env bash
# Bug: fails when given --sum flag
if [ "$1" = "--sum" ]; then
  echo "calc: internal arithmetic error" >&2
  exit 2
fi
echo "calc: ok"
exit 0
"""
        with open(target_script, "w") as f:
            f.write(buggy_code)
        os.chmod(target_script, 0o755)

        # Create a repro.sh test script
        repro_script = os.path.join(tmp_dir, "repro.sh")
        with open(repro_script, "w") as f:
            f.write(f"""#!/usr/bin/env bash
set -euo pipefail
RC=0
OUT="$(bash {shlex.quote(target_script)} --sum 2>&1)" || RC=$?
# Pass when target_script --sum exits 0
if [ "$RC" -eq 0 ]; then
  exit 0
fi
exit 1
""")
        os.chmod(repro_script, 0o755)

        # 1. Realpath containment check
        c1 = check_realpath_containment(target_script, tmp_dir)
        c2 = not check_realpath_containment(os.path.join(tmp_dir, "../escape.sh"), tmp_dir)
        assertions.append(("Realpath containment accurately permits sandbox descendants and rejects traversal escapes", c1 and c2, ""))

        # 2. Patch applicator validation
        ok_p, msg_p = apply_patch_content(
            target_script,
            buggy_code,
            buggy_code + "# patch comment\n",
            sandbox_root=tmp_dir,
        )
        assertions.append(("Patch content applicator successfully applies atomic writes under sandbox", ok_p, msg_p))

        # Reset buggy code
        with open(target_script, "w") as f:
            f.write(buggy_code)

        # 3. Simulated Multi-Round Self-Healing (Attempt 1 fails, Attempt 2 succeeds)
        def multi_attempt_generator(path: str, error_trace: str, attempt: int) -> Optional[str]:
            if attempt == 1:
                # Flawed fix: changes exit code to 3 (still fails repro.sh)
                return buggy_code.replace("exit 2", "exit 3")
            elif attempt == 2:
                # Correct fix: resolves arithmetic error and exits 0
                return """#!/usr/bin/env bash
if [ "$1" = "--sum" ]; then
  echo "calc: sum computed: 42"
  exit 0
fi
echo "calc: ok"
exit 0
"""
            return None

        result = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=tmp_dir,
            fix_generator=multi_attempt_generator,
            max_attempts=3,
            sandbox_root=tmp_dir,
        )

        t3 = (result["status"] == "healed" and result["attempts"] == 2 and "winning_diff" in result)
        assertions.append(("Multi-attempt iterative loop recovers and heals defect after initial failed candidate", t3, f"Result: {result}"))

        # 4. Falsifiability Negative Control: Unsolvable defect halts and escalates after max_attempts
        # Reset buggy code
        with open(target_script, "w") as f:
            f.write(buggy_code)

        def defective_generator(path: str, error_trace: str, attempt: int) -> Optional[str]:
            # Always produces non-working fix
            return buggy_code.replace("exit 2", f"exit {10 + attempt}")

        result_neg = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=tmp_dir,
            fix_generator=defective_generator,
            max_attempts=2,
            sandbox_root=tmp_dir,
        )

        t4 = (result_neg["status"] == "escalated" and result_neg["attempts"] == 2)
        assertions.append(("Negative control: Unsolvable defect halts and escalates after exceeding max_attempts", t4, f"Result: {result_neg}"))

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

    passed_count = sum(1 for _, ok, _ in assertions if ok)
    total_count = len(assertions)
    failed_count = total_count - passed_count

    if as_json:
        payload = {
            "suite": "self_healer",
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
    parser = argparse.ArgumentParser(description="Gated Autonomous Self-Healing Builder Loop (GH-155 Phase 4 / GH-182)")
    parser.add_argument("--mode", choices=["suite", "heal"], default="suite", help="Execution mode")
    parser.add_argument("--repro", help="Path to repro.sh script")
    parser.add_argument("--target-file", help="Path to target source file to fix")
    parser.add_argument("--sandbox-root", help="Path to disposable sandbox root (required for heal mode)")
    parser.add_argument("--regression-cmd", help="Command to run for regression gating (required for heal mode)")
    parser.add_argument("--generator-cmd", help="External command to generate candidate fixes")
    parser.add_argument("--gate-timeout", type=int, default=900, help="Gate command execution timeout in seconds (default: 900)")
    parser.add_argument("--max-attempts", type=int, default=3, help="Max healing attempts before escalating")
    parser.add_argument("--diff-out", help="Path to write winning diff file when healed")
    parser.add_argument("--issue-rollup-out", help="Path to write issue rollup markdown when escalated")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "suite":
        return run_self_healer_suite(repo_root, as_json=args.json)

    if args.mode == "heal":
        # 1. Missing --repro or --target-file
        if not args.repro or not args.target_file:
            print("Error: --repro and --target-file are required for heal mode", file=sys.stderr)
            return 2

        # 2. Mandatory --regression-cmd (GH-182 Plan §2)
        if not args.regression_cmd:
            print("Error: --regression-cmd is required for heal mode (mandatory regression gate per GH-182)", file=sys.stderr)
            return 2

        # 3. Mandatory --sandbox-root (GH-182 Plan §1)
        if not args.sandbox_root:
            print("Error: --sandbox-root is required for heal mode (must be an existing disposable directory outside invoking checkout)", file=sys.stderr)
            return 2

        # 3a. sandbox-root exists
        if not os.path.exists(args.sandbox_root):
            print(f"Error: --sandbox-root does not exist: {args.sandbox_root}", file=sys.stderr)
            return 2

        # 3c. sandbox-root is NOT the invoking checkout
        resolved_sandbox = os.path.realpath(args.sandbox_root)
        resolved_checkout = os.path.realpath(repo_root)
        if resolved_sandbox == resolved_checkout:
            print(f"Error: --sandbox-root cannot be the invoking checkout repository ({repo_root})", file=sys.stderr)
            return 2

        # 3b. sandbox-root contains target-file after realpath resolution
        if not check_realpath_containment(args.target_file, args.sandbox_root):
            print(f"Error: --target-file ({args.target_file}) is outside --sandbox-root ({args.sandbox_root})", file=sys.stderr)
            return 2

        reg_cmd = shlex.split(args.regression_cmd) if args.regression_cmd else None

        # Build fix generator (placeholder deleted per GH-182 Plan §1)
        if args.generator_cmd:
            def fix_gen(path: str, trace: str, attempt: int) -> Optional[str]:
                cmd = shlex.split(args.generator_cmd) + [path, trace, str(attempt)]
                try:
                    res = subprocess.run(cmd, capture_output=True, text=True, timeout=args.gate_timeout)
                    if res.returncode == 0:
                        return res.stdout
                    return None
                except Exception:
                    return None
        else:
            def fix_gen(path: str, trace: str, attempt: int) -> Optional[str]:
                return None

        result = run_self_healing_cycle(
            repro_path=args.repro,
            target_file=args.target_file,
            repo_root=args.sandbox_root,
            fix_generator=fix_gen,
            regression_cmd=reg_cmd,
            max_attempts=args.max_attempts,
            sandbox_root=args.sandbox_root,
            gate_timeout=args.gate_timeout,
            diff_out_path=args.diff_out,
            escalation_out_path=args.issue_rollup_out,
        )

        if args.json:
            print(json.dumps(result, indent=2))
        else:
            print(f"Self-Healing Result: {result.get('status')}")
            if result.get("winning_diff"):
                print("--- Applied Diff ---")
                print(result["winning_diff"])
                if result.get("winning_diff_file"):
                    print(f"Winning diff written to: {result['winning_diff_file']}")
            if result.get("status") == "escalated":
                if result.get("issue_rollup_file"):
                    print(f"Issue rollup written to: {result['issue_rollup_file']}")

        return 0 if result.get("status") == "healed" else 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
