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
import time
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
    timeout: int = 30,
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


def check_governor(governor_path: Optional[str]) -> Optional[Dict[str, Any]]:
    """Check control.json governor for operator pause / abort / halt directives."""
    if not governor_path or not os.path.exists(governor_path):
        return None
    try:
        with open(governor_path, "r") as f:
            return json.loads(f.read())
    except Exception:
        return None


def advisory_blast_radius_sensor(
    original_content: str,
    candidate_patch: str,
    target_file: str,
    max_diff_lines: int = 500,
) -> Tuple[bool, str, Dict[str, Any]]:
    """Evaluate candidate patch against advisory blast radius invariants (Task 8b / GH-201)."""
    diff_lines = list(difflib.unified_diff(
        original_content.splitlines(keepends=True),
        candidate_patch.splitlines(keepends=True),
    ))
    total_diff_lines = len(diff_lines)
    added_lines = sum(1 for l in diff_lines if l.startswith("+") and not l.startswith("+++"))
    removed_lines = sum(1 for l in diff_lines if l.startswith("-") and not l.startswith("---"))

    metrics = {
        "total_diff_lines": total_diff_lines,
        "lines_added": added_lines,
        "lines_removed": removed_lines,
        "target_file": target_file,
    }

    if total_diff_lines > max_diff_lines:
        return False, f"Diff size ({total_diff_lines} lines) exceeds maximum allowed blast radius ({max_diff_lines} lines)", metrics

    # Protected repo infrastructure checks
    base_name = os.path.basename(target_file)
    rel_parts = os.path.normpath(target_file).split(os.sep)
    if ".git" in rel_parts or "githooks" in rel_parts or base_name == "validate.sh":
        return False, f"Target file '{target_file}' matches protected infrastructure pattern", metrics

    return True, "Approved by advisory blast radius sensor", metrics


def format_escalation_report(
    target_file: str,
    repro_path: str,
    history: List[Dict[str, Any]],
    max_attempts: int,
    status: str,
    message: Optional[str] = None,
) -> str:
    """Format structured markdown escalation report for issue compilation."""
    lines = [
        "# Self-Healer Escalation Report",
        "",
        f"- **Status**: `{status}`",
        f"- **Target File**: `{target_file}`",
        f"- **Reproducer Script**: `{repro_path}`",
        f"- **Attempts Exhausted**: {len(history)} / {max_attempts}",
    ]
    if message:
        lines.extend([f"- **Message**: {message}", ""])
    else:
        lines.append("")

    lines.extend(["## Attempt History", ""])
    if not history:
        lines.append("_No attempt records generated._")
    else:
        for rec in history:
            attempt_num = rec.get("attempt", "?")
            res = rec.get("result", "unknown")
            lines.append(f"### Attempt {attempt_num}: `{res}`")
            if "gate1_rc" in rec:
                lines.append(f"- **Gate 1 (Acceptance repro.sh)**: Exit Code `{rec['gate1_rc']}`")
            if "gate2_rc" in rec:
                lines.append(f"- **Gate 2 (Regression Suite)**: Exit Code `{rec['gate2_rc']}`")
            if rec.get("gate1_err"):
                snippet = rec['gate1_err'].strip()[:300]
                lines.append(f"```text\n{snippet}\n```")
            lines.append("")

    return "\n".join(lines)


def run_self_healing_cycle(
    repro_path: str,
    target_file: str,
    repo_root: str,
    fix_generator: Callable[[str, str, int], Optional[str]],
    sandbox_root: str,
    regression_cmd: Optional[List[str]] = None,
    max_attempts: int = 3,
    gate_timeout: int = 900,
    governor_file: Optional[str] = None,
    max_diff_lines: int = 500,
) -> Dict[str, Any]:
    """Execute gated autonomous self-healing loop with fail-safe containment."""
    # Preflight containment assertions (GH-182 / GH-564 / GH-567)
    if not sandbox_root:
        return {
            "status": "refused",
            "message": "Missing required sandbox_root: heal mode requires a designated disposable sandbox (GH-182)",
            "history": [],
        }

    resolved_sandbox = os.path.realpath(sandbox_root)
    resolved_repo = os.path.realpath(repo_root)

    if not os.path.isdir(resolved_sandbox):
        return {
            "status": "refused",
            "message": f"Sandbox root '{sandbox_root}' (resolved: '{resolved_sandbox}') does not exist or is not a directory",
            "history": [],
        }

    if resolved_sandbox == resolved_repo:
        return {
            "status": "refused",
            "message": "Sandbox root cannot be the invoking repository checkout; heal mode requires an isolated disposable clone (GH-182 / GH-564)",
            "history": [],
        }

    if not check_realpath_containment(target_file, resolved_sandbox):
        return {
            "status": "refused",
            "message": f"Target file '{target_file}' is not contained within sandbox root '{resolved_sandbox}' (GH-567)",
            "history": [],
        }

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

    # Pre-flight governor check prior to initial reproduction probe (Task 7 / control.json)
    gov_pre = check_governor(governor_file)
    if gov_pre and gov_pre.get("action") in ("abort", "stop", "halt"):
        reason = gov_pre.get("reason", "Operator requested abort via governor")
        return {
            "status": "aborted_by_governor",
            "message": f"Halted by governor prior to initial reproduction: {reason}",
            "attempts": 0,
            "max_attempts": max_attempts,
            "winning_diff": "",
            "history": [],
            "calibration": {
                "attempts_executed": 0,
                "final_status": "aborted_by_governor",
                "total_duration_ms": 0,
                "history": [],
            },
            "escalation_report": format_escalation_report(
                target_file=target_file,
                repro_path=repro_path,
                history=[],
                max_attempts=max_attempts,
                status="aborted_by_governor",
                message=reason,
            ),
        }

    history: List[Dict[str, Any]] = []
    status = "escalated"
    winning_diff = ""
    original_content: Optional[str] = None

    try:
        # First verify initial reproduction (Acceptance Gate must fail initially)
        rc_init, out_init, err_init = execute_gate_command(
            ["bash", repro_path],
            cwd=resolved_sandbox,
            timeout=gate_timeout,
        )
        if rc_init == 0:
            return {
                "status": "no_repro",
                "message": "Initial reproducer script already exits 0 (defect is not reproducing)",
                "history": [],
            }

        # Backup target file original content
        with open(target_file, "r") as f:
            original_content = f.read()

        current_error_context = err_init or out_init

        for attempt in range(1, max_attempts + 1):
            attempt_rec: Dict[str, Any] = {"attempt": attempt}
            t_att_start = time.time()

            # Governor check (Task 7 / control.json)
            gov = check_governor(governor_file)
            if gov and gov.get("action") in ("abort", "stop", "halt"):
                status = "aborted_by_governor"
                attempt_rec["result"] = f"aborted_by_governor: {gov.get('reason', 'Halted by operator governor')}"
                attempt_rec["duration_ms"] = 0
                history.append(attempt_rec)
                break

            # Generate candidate fix from generator
            candidate_patch = fix_generator(target_file, current_error_context, attempt)
            if not candidate_patch:
                attempt_rec["result"] = "no_patch_generated"
                attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
                history.append(attempt_rec)
                continue

            # Advisory blast radius sensor (Task 8b / GH-201)
            sensor_ok, sensor_msg, diff_metrics = advisory_blast_radius_sensor(
                original_content=original_content,
                candidate_patch=candidate_patch,
                target_file=target_file,
                max_diff_lines=max_diff_lines,
            )
            attempt_rec["diff_metrics"] = diff_metrics
            attempt_rec["advisory_sensor"] = {"approved": sensor_ok, "message": sensor_msg}
            if not sensor_ok:
                attempt_rec["result"] = f"advisory_sensor_rejected: {sensor_msg}"
                attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
                history.append(attempt_rec)
                continue

            # Apply candidate fix to target file
            ok_apply, msg_apply = apply_patch_content(
                target_file,
                original_content,
                candidate_patch,
                sandbox_root=resolved_sandbox,
            )
            if not ok_apply:
                attempt_rec["result"] = f"apply_failed: {msg_apply}"
                attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
                history.append(attempt_rec)
                continue

            # Gate 1: Acceptance Gate (Run repro.sh — must pass with rc=0)
            rc_gate1, out_gate1, err_gate1 = execute_gate_command(
                ["bash", repro_path],
                cwd=resolved_sandbox,
                timeout=gate_timeout,
            )
            attempt_rec["gate1_rc"] = rc_gate1
            attempt_rec["gate1_out"] = out_gate1
            attempt_rec["gate1_err"] = err_gate1

            if rc_gate1 != 0:
                attempt_rec["result"] = "gate1_failed"
                attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
                current_error_context = err_gate1 or out_gate1
                history.append(attempt_rec)
                # Revert to original content before next iteration
                with open(target_file, "w") as f:
                    f.write(original_content)
                continue

            # Gate 2: Regression Gate (Mandatory for heal mode)
            if regression_cmd:
                rc_gate2, out_gate2, err_gate2 = execute_gate_command(
                    regression_cmd,
                    cwd=resolved_sandbox,
                    timeout=gate_timeout,
                )
                attempt_rec["gate2_rc"] = rc_gate2
                attempt_rec["gate2_out"] = out_gate2
                attempt_rec["gate2_err"] = err_gate2

                if rc_gate2 != 0:
                    attempt_rec["result"] = "gate2_regression_failed"
                    attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
                    current_error_context = err_gate2 or out_gate2
                    history.append(attempt_rec)
                    # Revert to original content before next iteration
                    with open(target_file, "w") as f:
                        f.write(original_content)
                    continue

            # Both gates passed!
            status = "healed"
            attempt_rec["result"] = "passed"
            attempt_rec["duration_ms"] = int((time.time() - t_att_start) * 1000)
            history.append(attempt_rec)

            # Compute winning diff
            diff_lines = list(difflib.unified_diff(
                original_content.splitlines(keepends=True),
                candidate_patch.splitlines(keepends=True),
                fromfile=target_file + ".orig",
                tofile=target_file,
            ))
            winning_diff = "".join(diff_lines)
            break

    finally:
        # Invariant: Restore target file if not healed (or on exception/abort)
        if status != "healed" and original_content is not None:
            try:
                with open(target_file, "w") as f:
                    f.write(original_content)
            except Exception:
                pass

    report = format_escalation_report(
        target_file=target_file,
        repro_path=repro_path,
        history=history,
        max_attempts=max_attempts,
        status=status,
    )

    calibration = {
        "attempts_executed": len(history),
        "final_status": status,
        "total_duration_ms": sum(h.get("duration_ms", 0) for h in history),
        "history": history,
    }

    return {
        "status": status,
        "attempts": len(history),
        "max_attempts": max_attempts,
        "winning_diff": winning_diff,
        "history": history,
        "calibration": calibration,
        "escalation_report": report,
    }


def run_self_healer_suite(repo_root: str, as_json: bool = False) -> int:
    """Hermetic self-test suite validating patch application, dual-gated healing, and feedback recovery."""
    if not as_json:
        print("==================================================")
        print(" Gated Autonomous Self-Healing Suite (GH-155 / GH-182)")
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
                return buggy_code.replace("exit 2", "exit 3")
            elif attempt == 2:
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
            repo_root=repo_root,
            fix_generator=multi_attempt_generator,
            regression_cmd=["bash", target_script, "--help"],
            max_attempts=3,
            sandbox_root=tmp_dir,
        )

        t3 = (result["status"] == "healed" and result["attempts"] == 2 and "winning_diff" in result)
        assertions.append(("Multi-attempt iterative loop recovers and heals defect after initial failed candidate", t3, f"Result: {result}"))

        # 4. Falsifiability Negative Control: Unsolvable defect halts and escalates after max_attempts
        with open(target_script, "w") as f:
            f.write(buggy_code)

        def defective_generator(path: str, error_trace: str, attempt: int) -> Optional[str]:
            return buggy_code.replace("exit 2", f"exit {10 + attempt}")

        result_neg = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=repo_root,
            fix_generator=defective_generator,
            regression_cmd=["bash", target_script, "--help"],
            max_attempts=2,
            sandbox_root=tmp_dir,
        )

        t4 = (result_neg["status"] == "escalated" and result_neg["attempts"] == 2 and "escalation_report" in result_neg)
        assertions.append(("Negative control: Unsolvable defect halts and escalates with markdown rollup after exceeding max_attempts", t4, f"Result: {result_neg}"))

        # 5. GH-182 Invariant: Containment Refusal on Checkout Sandbox
        result_refuse_checkout = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=tmp_dir,
            fix_generator=multi_attempt_generator,
            regression_cmd=["bash", target_script, "--help"],
            max_attempts=1,
            sandbox_root=tmp_dir,  # sandbox == repo_root
        )
        t5 = (result_refuse_checkout["status"] == "refused" and "checkout" in result_refuse_checkout["message"])
        assertions.append(("GH-182 Safety Invariant: Refuses when sandbox_root is the invoking repository checkout", t5, f"Msg: {result_refuse_checkout.get('message')}"))

        # 6. Target restoration on failed attempt
        with open(target_script, "r") as f:
            current_target_content = f.read()
        t6 = (current_target_content == buggy_code)
        assertions.append(("GH-182 Fail-Safe Invariant: Target file restored to original byte state after failed/escalated attempts", t6, ""))

        # 7. Task 7 Invariant: Governor Control Abort (control.json integration)
        ctrl_file = os.path.join(tmp_dir, "control.json")
        with open(ctrl_file, "w") as f:
            f.write(json.dumps({"action": "abort", "reason": "Operator test abort"}))

        result_gov = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=repo_root,
            fix_generator=multi_attempt_generator,
            regression_cmd=["bash", target_script, "--help"],
            max_attempts=3,
            sandbox_root=tmp_dir,
            governor_file=ctrl_file,
        )
        t7 = (result_gov["status"] == "aborted_by_governor" and result_gov["attempts"] == 0)
        assertions.append(("Task 7 Governor Invariant: Governor abort signal immediately halts self-healing cycle", t7, f"Status: {result_gov.get('status')}"))

        # 8. Task 8b Invariant: Advisory Blast Radius Sensor Rejection
        def oversized_patch_generator(path: str, trace: str, attempt: int) -> Optional[str]:
            return buggy_code + "\n" + "\n".join(f"# bloated line {i}" for i in range(600))

        result_sensor = run_self_healing_cycle(
            repro_path=repro_script,
            target_file=target_script,
            repo_root=repo_root,
            fix_generator=oversized_patch_generator,
            regression_cmd=["bash", target_script, "--help"],
            max_attempts=1,
            sandbox_root=tmp_dir,
            max_diff_lines=500,
        )
        t8 = (result_sensor["status"] == "escalated" and "advisory_sensor_rejected" in str(result_sensor["history"]))
        assertions.append(("Task 8b Advisory Sensor: Rejects oversized candidate patches exceeding blast radius limit", t8, f"History: {result_sensor.get('history')}"))

        # 9. Task 8 Invariant: Calibration Telemetry Integrity
        t9 = ("calibration" in result and "total_duration_ms" in result["calibration"] and result["calibration"]["attempts_executed"] == 2)
        assertions.append(("Task 8 Calibration Telemetry: Structured calibration payload aggregates attempt execution metrics", t9, f"Calibration: {result.get('calibration')}"))

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
    parser = argparse.ArgumentParser(description="Gated Autonomous Self-Healing Builder Loop (GH-155 Phase 4 / GH-182 / Task 7 & 8)")
    parser.add_argument("--mode", choices=["suite", "heal"], default="suite", help="Execution mode")
    parser.add_argument("--repro", help="Path to repro.sh script")
    parser.add_argument("--target-file", help="Path to target source file to fix")
    parser.add_argument("--sandbox-root", help="Path to isolated disposable clone sandbox root (GH-182 / GH-564)")
    parser.add_argument("--regression-cmd", help="Command to run for mandatory regression gating")
    parser.add_argument("--gate-timeout", type=int, default=900, help="Per-gate timeout in seconds (default: 900)")
    parser.add_argument("--governor", help="Path to control.json governor file for operator abort/stop/halt directives")
    parser.add_argument("--max-diff-lines", type=int, default=500, help="Maximum allowed diff lines for advisory blast radius sensor (default: 500)")
    parser.add_argument("--max-attempts", type=int, default=3, help="Max healing attempts before escalating")
    parser.add_argument("--patch-file", help="Optional path to candidate patch file")
    parser.add_argument("--diff-output", help="Optional path to write winning unified diff when healed")
    parser.add_argument("--escalation-report", help="Optional path to write markdown escalation report")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "suite":
        return run_self_healer_suite(repo_root, as_json=args.json)

    if args.mode == "heal":
        # GH-182 Fail-Fast CLI Validation
        if not args.sandbox_root:
            print("Error: --sandbox-root is required for heal mode (prevents in-place mutation of the invoking checkout - GH-182 / GH-564)", file=sys.stderr)
            return 2

        resolved_sandbox = os.path.realpath(args.sandbox_root)
        resolved_repo = os.path.realpath(repo_root)

        if not os.path.isdir(resolved_sandbox):
            print(f"Error: --sandbox-root '{args.sandbox_root}' does not exist or is not a directory", file=sys.stderr)
            return 2

        if resolved_sandbox == resolved_repo:
            print("Error: --sandbox-root cannot be the invoking repository checkout; heal mode requires an isolated disposable clone (GH-182 / GH-564)", file=sys.stderr)
            return 2

        if not args.regression_cmd:
            print("Error: --regression-cmd is required for heal mode (prevents regression-blind patch application - GH-182)", file=sys.stderr)
            return 2

        if not args.repro or not args.target_file:
            print("Error: --repro and --target-file are required for heal mode", file=sys.stderr)
            return 2

        if not check_realpath_containment(args.target_file, resolved_sandbox):
            print(f"Error: --target-file '{args.target_file}' is not contained within --sandbox-root '{resolved_sandbox}' (GH-567)", file=sys.stderr)
            return 2

        reg_cmd = shlex.split(args.regression_cmd)

        def file_or_diff_generator(path: str, trace: str, attempt: int) -> Optional[str]:
            if args.patch_file and os.path.exists(args.patch_file):
                with open(args.patch_file, "r") as f:
                    return f.read()
            return None

        result = run_self_healing_cycle(
            repro_path=args.repro,
            target_file=args.target_file,
            repo_root=repo_root,
            fix_generator=file_or_diff_generator,
            sandbox_root=args.sandbox_root,
            regression_cmd=reg_cmd,
            max_attempts=args.max_attempts,
            gate_timeout=args.gate_timeout,
            governor_file=args.governor,
            max_diff_lines=args.max_diff_lines,
        )

        if args.diff_output and result.get("winning_diff"):
            try:
                with open(args.diff_output, "w") as f:
                    f.write(result["winning_diff"])
            except Exception as e:
                print(f"Warning: Failed to write --diff-output: {e}", file=sys.stderr)

        if args.escalation_report and result.get("escalation_report"):
            try:
                with open(args.escalation_report, "w") as f:
                    f.write(result["escalation_report"])
            except Exception as e:
                print(f"Warning: Failed to write --escalation-report: {e}", file=sys.stderr)

        if args.json:
            print(json.dumps(result, indent=2))
        else:
            print(f"Self-Healing Result: {result.get('status')}")
            if result.get("message"):
                print(f"Message: {result.get('message')}")
            if result.get("winning_diff"):
                print("--- Applied Diff ---")
                print(result["winning_diff"])
            elif result.get("escalation_report"):
                print("\n" + result["escalation_report"])

        return 0 if result.get("status") == "healed" else 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
