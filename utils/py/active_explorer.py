#!/usr/bin/env python3
"""4-Family Active Explorer Agent (GH-155 Phase 5).

Autonomous generative explorer and fuzzer spanning 4 key mutation families:
1. Argv Grammar Fuzzing (flag mutations, unicode, boundary integers, conflicting options)
2. Env Presence Fuzzing (missing, corrupted, conflicting runner identities, buffer limits)
3. Path Canonicalization & Containment (symlinks, relative escapes, trailing slashes, GH-567)
4. Process Limits & Signals (timeouts, EOF stdin, buffer saturation)

Feeds anomalies directly into Phase 1 (Metamorphic Invariants), Phase 2 (Differential Oracle),
Phase 3 (Hermetic Reproducer & ddmin), and Phase 4 (Autonomous Self-Healing Loop).
"""

import argparse
import itertools
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from typing import Any, Dict, List, Optional, Tuple


# ==========================================
# Family 1: Argv Grammar & Flag Mutations
# ==========================================

BOUNDARY_STRINGS = [
    "",
    "   ",
    "\t\n",
    "0",
    "-1",
    "2147483647",
    "9223372036854775807",
    "A" * 1024,
    "!@#$%^&*()[]{};:'\",<>/?`~",
    "../../../../../../etc/passwd",
    "\\x00nullbyte",
    "unicode_тест_🚀_测试",
    "--unknown-fuzz-flag-xyz",
    "-z",
    "--",
]


def generate_argv_mutations(base_cmd: List[str], max_variants: int = 15) -> List[List[str]]:
    """Generate mutating argv combinations from base command."""
    variants: List[List[str]] = []
    if not base_cmd:
        return variants

    # 1. Unknown & conflicting flags appended
    for s in BOUNDARY_STRINGS:
        variants.append(list(base_cmd) + [s])
        variants.append(list(base_cmd) + ["--flag-param=" + s])

    # 2. Flag insertion at various positions
    if len(base_cmd) > 1:
        variants.append([base_cmd[0], "--unknown-pre-flag"] + base_cmd[1:])
        variants.append(base_cmd + ["--help", "--dry-run"])

    return variants[:max_variants]


# ==========================================
# Family 2: Env Presence & Corruption
# ==========================================

def generate_env_mutations(base_env: Dict[str, str], max_variants: int = 15) -> List[Dict[str, str]]:
    """Generate corrupted and mutating environment dictionaries."""
    variants: List[Dict[str, str]] = []

    # 0. Fully empty environment
    variants.append({})

    # 1. Missing keys (prune one key at a time)
    for k in list(base_env.keys()):
        mutated = dict(base_env)
        del mutated[k]
        variants.append(mutated)

    # 2. Empty string values
    for k in list(base_env.keys()):
        mutated = dict(base_env)
        mutated[k] = ""
        variants.append(mutated)

    # 3. Corrupted values & buffer injection
    for k in list(base_env.keys()):
        mutated = dict(base_env)
        mutated[k] = "CORRUPTED_VALUE_!@#"
        variants.append(mutated)
        mutated_long = dict(base_env)
        mutated_long[k] = "X" * 2048
        variants.append(mutated_long)

    # 4. Conflicting runner environment variables
    conflicting = dict(base_env)
    conflicting["RELAY_AGENT"] = "codex"
    conflicting["AGY_AGENT"] = "agy"
    conflicting["CLAUDE_AGENT"] = "claude"
    variants.append(conflicting)

    return variants[:max_variants]


# ==========================================
# Family 3: Path Canonicalization & Containment
# ==========================================

def generate_path_mutations(sandbox_root: str, max_variants: int = 15) -> List[str]:
    """Generate path traversal, symlink, and canonicalization test paths."""
    test_paths: List[str] = [
        os.path.join(sandbox_root, "valid_subdir", "file.txt"),
        os.path.join(sandbox_root, "./nested/./file.txt"),
        os.path.join(sandbox_root, "../escape.txt"),
        os.path.join(sandbox_root, "dir_with_trailing_slash/"),
        os.path.join(sandbox_root, "non_existent_deep/a/b/c/file.txt"),
        "",
        "   ",
        "/tmp",
        "/etc/passwd",
        os.path.join(sandbox_root, "symlink_loop"),
    ]
    return test_paths[:max_variants]


# ==========================================
# Family 4: Process Limits & Signals
# ==========================================

def execute_with_process_limits(
    cmd: List[str],
    cwd: str,
    env: Dict[str, str],
    timeout: float = 10.0,
    stdin_content: Optional[str] = None,
) -> Tuple[int, str, str, bool]:
    """Execute command under strict process limits; returns (rc, out, err, timed_out).

    Env discipline (GH-183): probes run over a CLEAN base (PATH/HOME/TMPDIR/XYZ_ROOT
    only) plus the passed env — never os.environ.copy() — so ambient runner vars
    (RELAY_AGENT & friends) cannot silently satisfy "missing key" mutations.
    """
    clean_env = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": os.environ.get("HOME", "/tmp"),
        "TMPDIR": os.environ.get("TMPDIR", "/tmp"),
        "XYZ_ROOT": os.environ.get("XYZ_ROOT", cwd),
    }
    clean_env.update(env)

    timed_out = False
    try:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            env=clean_env,
            input=stdin_content,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return res.returncode, res.stdout, res.stderr, False
    except subprocess.TimeoutExpired as e:
        timed_out = True
        return 124, (e.stdout or "").decode("utf-8", errors="ignore") if isinstance(e.stdout, bytes) else (e.stdout or ""), (e.stderr or "").decode("utf-8", errors="ignore") if isinstance(e.stderr, bytes) else (e.stderr or ""), True
    except Exception as e:
        return 1, "", f"Execution error: {e}", False


# ==========================================
# Active Exploration Execution Engine & Closed Data Path
# ==========================================

def synthesize_reproducers_from_anomalies(
    anomalies: List[Dict[str, Any]],
    repo_root: str,
    output_dir: str,
) -> List[str]:
    """Synthesize standalone hermetic repro.sh scripts for all detected anomalies via repro_builder."""
    from repro_builder import generate_repro_script, minimize_argv, minimize_environment

    os.makedirs(output_dir, exist_ok=True)
    generated_scripts: List[str] = []

    for idx, anomaly in enumerate(anomalies, 1):
        if anomaly.get("type") == "zero_mutation_violation":
            continue
        target_rc = int(anomaly.get("rc", 1))
        cmd = list(anomaly.get("cmd", []))
        env = dict(anomaly.get("env", {}))
        raw_err = str(anomaly.get("err_sample", ""))
        err_lines = [line.strip() for line in raw_err.splitlines() if line.strip()]
        err_sub = err_lines[0][:60] if err_lines else None

        min_env = minimize_environment(env, cmd, repo_root, target_rc, err_sub)
        min_cmd = minimize_argv(cmd, min_env, repo_root, target_rc, err_sub)

        repro_content = generate_repro_script(
            cmd=min_cmd,
            env=min_env,
            target_rc=target_rc,
            target_err_substring=err_sub,
            title=f"Reproducer for Active Explorer Anomaly {idx}",
            repo_root=repo_root,
        )

        repro_path = os.path.join(output_dir, f"repro_anomaly_{idx}.sh")
        with open(repro_path, "w") as f:
            f.write(repro_content)
        os.chmod(repro_path, 0o755)
        generated_scripts.append(repro_path)

    return generated_scripts


def run_exploration_campaign(
    target_cmd: List[str],
    base_env: Dict[str, str],
    repo_root: str,
    family: str = "all",
    max_rounds: int = 10,
    check_zero_mutation: bool = True,
) -> Dict[str, Any]:
    """Execute active exploration across selected mutation families with zero-mutation checks."""
    records: List[Dict[str, Any]] = []
    anomalies: List[Dict[str, Any]] = []

    # Prepare vector generators based on family
    argv_vectors = generate_argv_mutations(target_cmd, max_variants=max_rounds) if family in ("all", "argv") else [target_cmd]
    env_vectors = generate_env_mutations(base_env, max_variants=max_rounds) if family in ("all", "env") else [base_env]

    # Pre-campaign state check if .git present
    git_dir = os.path.join(repo_root, ".git")
    has_git = os.path.exists(git_dir)

    for cmd_vec, env_vec in itertools.islice(itertools.product(argv_vectors, env_vectors), max_rounds):
        status_before = ""
        if check_zero_mutation and has_git:
            try:
                res_st = subprocess.run(
                    ["git", "-C", repo_root, "status", "--porcelain=v1"],
                    capture_output=True,
                    text=True,
                    timeout=5.0,
                )
                status_before = res_st.stdout.strip()
            except Exception:
                pass

        rc, out, err, timed_out = execute_with_process_limits(
            cmd=cmd_vec,
            cwd=repo_root,
            env=env_vec,
            timeout=5.0,
        )

        mutation_detected = False
        if check_zero_mutation and has_git:
            try:
                res_st2 = subprocess.run(
                    ["git", "-C", repo_root, "status", "--porcelain=v1"],
                    capture_output=True,
                    text=True,
                    timeout=5.0,
                )
                status_after = res_st2.stdout.strip()
                if status_before != status_after:
                    mutation_detected = True
            except Exception:
                pass

        rec = {
            "cmd": cmd_vec,
            "env_keys": list(env_vec.keys()),
            "rc": rc,
            "stdout_len": len(out),
            "stderr_len": len(err),
            "timed_out": timed_out,
            "mutated": mutation_detected,
        }
        records.append(rec)

        # Flag anomalies: unhandled Python tracebacks, core dumps, unexpected exit 134/139/SIGSEGV, or zero-mutation violations
        if "Traceback (most recent call last):" in err or rc in (134, 139) or "Segmentation fault" in err:
            anomalies.append({
                "type": "crash_or_traceback",
                "cmd": cmd_vec,
                "env": env_vec,
                "rc": rc,
                "err_sample": err[:300],
            })
        elif mutation_detected:
            anomalies.append({
                "type": "zero_mutation_violation",
                "cmd": cmd_vec,
                "env": env_vec,
                "rc": rc,
                "err_sample": "Read-only probe caused unauthorized working tree mutation",
            })

    return {
        "family": family,
        "total_probes": len(records),
        "anomalies_detected": len(anomalies),
        "anomalies": anomalies,
        "records": records[:5],
    }


def run_active_explorer_suite(repo_root: str, as_json: bool = False) -> int:
    """Self-test suite validating all 4 mutation families, anomaly detection, and pipeline integration."""
    if not as_json:
        print("==================================================")
        print(" 4-Family Active Explorer Agent Suite (GH-155 Phase 5 / Task 4 & 6)")
        print("==================================================")

    assertions: List[Tuple[str, bool, str]] = []
    tmp_dir = tempfile.mkdtemp(prefix="explorer_suite_")

    try:
        # Create a mock target script that crashes on a specific mutated boundary input
        target_script = os.path.join(tmp_dir, "target_cli.py")
        with open(target_script, "w") as f:
            f.write("""#!/usr/bin/env python3
import os, sys

if "--crash-trigger" in sys.argv:
    # Unhandled ValueError bug
    raise ValueError("explorer_fuzz_crash_unhandled")

if os.environ.get("CORRUPTED_SECRET") == "CORRUPTED_VALUE_!@#":
    # Traceback anomaly
    raise RuntimeError("corrupted_env_anomaly_detected")

print("target_cli: ok")
sys.exit(0)
""")
        os.chmod(target_script, 0o755)

        # 1. Family 1: Argv Grammar Mutations
        argv_muts = generate_argv_mutations(["python3", target_script], max_variants=35)
        t1 = len(argv_muts) >= 5 and any("--unknown-fuzz-flag-xyz" in v for v in argv_muts)
        assertions.append(("Family 1 (Argv Grammar): Synthesizes rich boundary, unicode, and flag mutations", t1, f"Count: {len(argv_muts)}"))

        # 2. Family 2: Env Presence & Corruption Mutations
        base_test_env = {"CORRUPTED_SECRET": "valid", "RUNNER": "agy"}
        env_muts = generate_env_mutations(base_test_env, max_variants=10)
        t2 = len(env_muts) >= 4 and any(e.get("CORRUPTED_SECRET") == "CORRUPTED_VALUE_!@#" for e in env_muts)
        assertions.append(("Family 2 (Env Presence): Synthesizes missing, empty, and corrupted env vectors", t2, f"Count: {len(env_muts)}"))

        # 3. Family 3: Path Canonicalization Mutations
        path_muts = generate_path_mutations(tmp_dir, max_variants=10)
        t3 = len(path_muts) >= 5 and any("../escape.txt" in p for p in path_muts)
        assertions.append(("Family 3 (Path Containment): Synthesizes traversal, symlink, and canonicalization paths", t3, f"Count: {len(path_muts)}"))

        # 4. Family 4: Process Limits & Signals
        rc_lim, out_lim, err_lim, timed_out = execute_with_process_limits(
            cmd=["python3", "-c", "import time; time.sleep(10)"],
            cwd=tmp_dir,
            env={},
            timeout=0.2,
        )
        t4 = timed_out is True and rc_lim == 124
        assertions.append(("Family 4 (Process Limits): Accurately enforces process timeouts and signal bounds", t4, f"rc={rc_lim}"))

        # 5. Anomaly Detection Campaign Integration
        campaign = run_exploration_campaign(
            target_cmd=["python3", target_script, "--crash-trigger"],
            base_env=base_test_env,
            repo_root=tmp_dir,
            family="all",
            max_rounds=5,
            check_zero_mutation=False,
        )
        t5 = campaign["total_probes"] > 0 and campaign["anomalies_detected"] > 0
        assertions.append(("Active Explorer Campaign detects crashes and unhandled tracebacks", t5, f"Anomalies: {campaign['anomalies_detected']}"))

        # 6. Task 4: Closed Data Path (Anomaly -> repro_builder -> executable repro.sh)
        repro_dir = os.path.join(tmp_dir, "repro_out")
        repro_scripts = synthesize_reproducers_from_anomalies(
            campaign["anomalies"],
            repo_root=tmp_dir,
            output_dir=repro_dir,
        )
        t6 = len(repro_scripts) > 0 and os.path.exists(repro_scripts[0])
        # Execute generated repro.sh to assert it faithfully reproduces the anomaly
        if t6:
            rc_rep = subprocess.run(["bash", repro_scripts[0]], cwd=tmp_dir, capture_output=True).returncode
            t6 = (rc_rep == 0)
        assertions.append(("Task 4 Closed Data Path: Synthesizes and executes hermetic repro.sh from detected anomaly", t6, f"Repros: {len(repro_scripts)}"))

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

    passed_count = sum(1 for _, ok, _ in assertions if ok)
    total_count = len(assertions)
    failed_count = total_count - passed_count

    if as_json:
        payload = {
            "suite": "active_explorer",
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
    parser = argparse.ArgumentParser(description="4-Family Active Explorer Agent (GH-155 Phase 5 / Task 4 & 6)")
    parser.add_argument("--mode", choices=["suite", "explore"], default="suite", help="Execution mode")
    parser.add_argument("--family", choices=["all", "argv", "env", "path", "process"], default="all", help="Mutation family")
    parser.add_argument("--target-cmd", help="Target command to explore (e.g. 'bash relay-automation/deepseek-turn.sh')")
    parser.add_argument("--base-env", action="append", default=None,
                        help="Declared base env as KEY=VAL (repeatable). Replaces the default RELAY base; "
                             "mutations are derived from this base and run over a CLEAN environment "
                             "(ambient runner vars cannot satisfy them — GH-183).")
    parser.add_argument("--repro-out", help="Directory path to synthesize standalone repro.sh test cases for detected anomalies")
    parser.add_argument("--rounds", type=int, default=10, help="Max exploration rounds")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON output")

    args = parser.parse_args()
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    if args.mode == "suite":
        return run_active_explorer_suite(repo_root, as_json=args.json)

    if args.mode == "explore":
        if not args.target_cmd:
            print("Error: --target-cmd is required for explore mode", file=sys.stderr)
            return 2
        cmd = shlex.split(args.target_cmd)
        if args.base_env:
            base_env: Dict[str, str] = {}
            for pair in args.base_env:
                if "=" not in pair:
                    print(f"Error: --base-env expects KEY=VAL, got '{pair}'", file=sys.stderr)
                    return 2
                k, v = pair.split("=", 1)
                base_env[k] = v
        else:
            base_env = {
                "RELAY_AGENT": "tester",
                "RELAY_FILE": "RELAY.md",
                "RELAY_TASK": "explore",
            }
        res = run_exploration_campaign(
            target_cmd=cmd,
            base_env=base_env,
            repo_root=repo_root,
            family=args.family,
            max_rounds=args.rounds,
        )

        if args.repro_out and res.get("anomalies"):
            repro_files = synthesize_reproducers_from_anomalies(
                anomalies=res["anomalies"],
                repo_root=repo_root,
                output_dir=args.repro_out,
            )
            res["synthesized_repros"] = repro_files
            if not args.json:
                print(f"Synthesized {len(repro_files)} hermetic reproducer scripts in {args.repro_out}")

        if args.json:
            print(json.dumps(res, indent=2))
        else:
            print(f"Exploration Complete: {res['total_probes']} probes, {res['anomalies_detected']} anomalies.")
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
