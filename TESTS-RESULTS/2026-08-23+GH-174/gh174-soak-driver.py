#!/usr/bin/env python3
"""GH-174 Gen 3.5 soak driver: time-budgeted campaign over the five Gen-3 ATE engines.

Mirrors run_variations.py SOP conventions: control.json abort before every
iteration, wall-clock budget, JSONL telemetry per run, process-group containment
(start_new_session + PGID SIGKILL on timeout). Runs everything from the
standalone full clone (GH-564). Receipts land in temp/gh174-soak/ (uncommitted).
"""
import json
import os
import signal
import subprocess
import sys
import time

CLONE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECEIPTS = os.path.join(CLONE, "temp", "gh174-soak")
LOGS = os.path.join(RECEIPTS, "logs")
CONTROL = os.path.join(RECEIPTS, "control.json")
TELEMETRY = os.path.join(RECEIPTS, "soak_telemetry.jsonl")
SAMPLE = os.path.join(RECEIPTS, "sample-record.json")
REPRO_OUT = os.path.join(RECEIPTS, "loop-repro.sh")

BUDGET_S = 3600
SUB_TIMEOUT_S = 300

# Deterministic environment for every sub-run: strip ambient runner/relay vars so
# shim behaviour does not depend on the operator's shell (A11/D5 discipline).
STRIP_PREFIXES = ("RELAY_", "AGY_", "CODEX_", "CLAUDE_", "AIDER_", "DEEPSEEK_", "PI_", "COMMANDCODE_", "XYZ_")

ENGINES = [
    ("phase1-suite", ["python3", "utils/py/metamorphic_oracle.py", "--mode", "suite"], 0),
    ("phase2-suite", ["python3", "utils/py/differential_oracle.py", "--mode", "suite"], 0),
    ("phase3-suite", ["python3", "utils/py/repro_builder.py", "--mode", "suite"], 0),
    ("phase4-suite", ["python3", "utils/py/self_healer.py", "--mode", "suite"], 0),
    ("phase5-suite", ["python3", "utils/py/active_explorer.py", "--mode", "suite"], 0),
]

OPS = [
    ("op-diff-vector-unknown", ["python3", "utils/py/differential_oracle.py", "--mode", "vector", "--vector", "unknown-argv"], 0),
    ("op-explore-argv-aider-shim", ["python3", "utils/py/active_explorer.py", "--mode", "explore", "--family", "argv", "--target-cmd", "bash relay-automation/aider-turn.sh", "--rounds", "10", "--json"], 0),
    ("op-explore-env-agy-shim", ["python3", "utils/py/active_explorer.py", "--mode", "explore", "--family", "env", "--target-cmd", "bash relay-automation/agy-turn.sh", "--rounds", "10", "--json"], 0),
    ("op-repro-build-real-record", ["python3", "utils/py/repro_builder.py", "--mode", "build", "--telemetry", SAMPLE, "--output", REPRO_OUT], 0),
    # Facade probe: CLI heal mode against a real repo file. Containment should
    # refuse (mkdtemp sandbox) -> escalated, rc=1, zero writes to the clone.
    ("op-heal-cli-facade", ["python3", "utils/py/self_healer.py", "--mode", "heal", "--repro", REPRO_OUT, "--target-file", "relay-automation/agy-turn.sh", "--json"], 1),
]


def clean_env():
    env = dict(os.environ)
    for k in list(env.keys()):
        if any(k.startswith(p) for p in STRIP_PREFIXES):
            del env[k]
    return env


def check_abort():
    try:
        with open(CONTROL) as f:
            if json.load(f).get("action") == "abort":
                return True
    except Exception:
        pass
    return False


def run_one(name, cmd, expected_rc, iteration):
    t0 = time.time()
    proc = subprocess.Popen(
        cmd, cwd=CLONE, env=clean_env(),
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace", start_new_session=True,
    )
    timed_out = False
    try:
        out, _ = proc.communicate(timeout=SUB_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        out, _ = proc.communicate()
        timed_out = True
    duration_ms = int((time.time() - t0) * 1000)
    summary = ""
    for line in (out or "").splitlines()[::-1]:
        if "Summary:" in line or "SUITE_RESULT" in line or "Exploration Complete" in line:
            summary = line.strip()
            break
    rec = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "iteration": iteration,
        "kind": name,
        "cmd": " ".join(cmd),
        "rc": proc.returncode,
        "expected_rc": expected_rc,
        "verdict": "PASS" if (proc.returncode == expected_rc and not timed_out) else ("TIMEOUT" if timed_out else "UNEXPECTED"),
        "duration_ms": duration_ms,
        "summary": summary[:200],
    }
    with open(TELEMETRY, "a") as f:
        f.write(json.dumps(rec) + "\n")
    with open(os.path.join(LOGS, f"iter{iteration:03d}-{name}.log"), "w") as f:
        f.write(out or "")
    return rec


def main():
    os.makedirs(LOGS, exist_ok=True)
    with open(CONTROL, "w") as f:
        json.dump({"action": "continue"}, f)
    t_start = time.time()
    iteration = 0
    op_idx = 0
    counts = {}
    print(f"[soak] budget={BUDGET_S}s start={time.strftime('%H:%M:%S')}", flush=True)
    while time.time() - t_start < BUDGET_S:
        if check_abort():
            print("[soak] abort received, stopping.", flush=True)
            break
        iteration += 1
        for name, cmd, exp in ENGINES:
            rec = run_one(name, cmd, exp, iteration)
            counts.setdefault(name, {"PASS": 0, "UNEXPECTED": 0, "TIMEOUT": 0})
            counts[name][rec["verdict"]] += 1
            if rec["verdict"] != "PASS":
                print(f"[soak] iter{iteration} {name} -> {rec['verdict']} rc={rec['rc']}", flush=True)
        name, cmd, exp = OPS[op_idx % len(OPS)]
        op_idx += 1
        rec = run_one(name, cmd, exp, iteration)
        counts.setdefault(name, {"PASS": 0, "UNEXPECTED": 0, "TIMEOUT": 0})
        counts[name][rec["verdict"]] += 1
        if rec["verdict"] != "PASS":
            print(f"[soak] iter{iteration} {name} -> {rec['verdict']} rc={rec['rc']}", flush=True)
        elapsed = int(time.time() - t_start)
        print(f"[soak] iter{iteration} done at {elapsed}s", flush=True)
    summary = {
        "budget_s": BUDGET_S,
        "elapsed_s": int(time.time() - t_start),
        "iterations": iteration,
        "verdict_counts": counts,
        "finished_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    with open(os.path.join(RECEIPTS, "soak_summary.json"), "w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    sys.exit(main())
