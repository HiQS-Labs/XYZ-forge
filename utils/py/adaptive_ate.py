#!/usr/bin/env python3
"""adaptive_ate.py — GH-299 Gen 4 Phase 2: constraint-aware pairwise ATE with $0 two-tier triage.

Replaces Cartesian grid explosion (O(∏ N_i)) with an all-pairs (2-way) covering array that
honours the grid's own `conflicts` and `requires` constraints, then classifies every execution
with a data-calibrated, <5ms, $0 Tier-1 heuristic. Only genuine Tier-1 *anomalies* are routed
to Tier 2 (an LLM, local Gemma or frontier), so >95% of cases never touch a model.

Grid grammar (YAML or JSON; PyYAML optional — JSON always works):

    flags:                      # name -> list of values (bool, int, str, or null = "omit")
      --parallel: [true, false]
      --jobs: [1, 2, 4]
      --mode: [fast, full, null]
    conflicts:                  # each entry: a mapping that must NOT all hold at once
      - {--burst: true, --check: true}
      - {--parallel: false, --jobs: 4}
    requires:                   # each entry: {if: {...}, then: {...}}
      - if:   {--mode: full}
        then: {--parallel: true}
    command: "bash validate.sh {flags}"      # optional; {flags} is replaced by the rendered flags
    per_case_timeout_seconds: 120

Rendering: `--flag: true` -> `--flag`; `false`/`null` -> omitted; scalar -> `--flag VALUE`.

Tier-1 classifier: a thresholded heuristic over the telemetry feedback vector
(exit_code, signal, stderr_digest, duration_ms) plus stderr keyword classes. Thresholds live in
`utils/ate/tier1-calibration.json`, produced by `calibrate_tier1.py` from a labelled benchmark
(50 known-pass / 20 known-fail) with a 0% false-negative floor.

CLI:
  adaptive_ate.py --mode suite                                 # self-test
  adaptive_ate.py --mode generate --grid GRID [--json]          # print the covering array
  adaptive_ate.py --mode coverage --grid GRID                   # prove 100% valid 2-way coverage
  adaptive_ate.py --mode classify --telemetry EVENTS.jsonl      # Tier-1 verdicts (+ anomalies out)
  adaptive_ate.py --mode run --grid GRID --cwd DIR --telemetry-out OUT.jsonl [--tier2-cmd CMD]
"""
from __future__ import annotations

import argparse
import itertools
import json
import os
import random
import shlex
import subprocess
import sys
import time
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from telemetry_schema import (  # noqa: E402
    TelemetryEvent,
    append_jsonl,
    event_from_completed,
    new_run_id,
    normalize_stderr,
    read_jsonl,
)

DEFAULT_CALIBRATION = os.path.join(HERE, "..", "ate", "tier1-calibration.json")

Case = Dict[str, Any]           # flag -> chosen value
Pair = Tuple[str, Any, str, Any]  # (flagA, valA, flagB, valB) with flagA < flagB


# ---- grid loading ------------------------------------------------------------------------------
def load_grid(path: str) -> Dict[str, Any]:
    if not os.path.isfile(path):
        raise ValueError(f"grid file not found: {path!r}")
    with open(path, "r", encoding="utf-8") as fh:
        text = fh.read()
    if path.endswith(".json"):
        grid = json.loads(text)
    else:
        try:
            import yaml  # type: ignore
            grid = yaml.safe_load(text)
        except ImportError:
            grid = json.loads(text)  # JSON is a YAML subset; a YAML-only grid needs PyYAML
    return validate_grid(grid)


def validate_grid(grid: Dict[str, Any]) -> Dict[str, Any]:
    if not isinstance(grid, dict) or not isinstance(grid.get("flags"), dict) or not grid["flags"]:
        raise ValueError("grid needs a non-empty 'flags' mapping")
    for name, values in grid["flags"].items():
        if not isinstance(values, list) or not values:
            raise ValueError(f"flag {name!r} needs a non-empty list of values")
        if len(set(map(_key, values))) != len(values):
            raise ValueError(f"flag {name!r} has duplicate values")
    for c in grid.get("conflicts") or []:
        if not isinstance(c, dict) or len(c) < 2:
            raise ValueError(f"conflict {c!r} must name at least two flag=value assignments")
        for f in c:
            if f not in grid["flags"]:
                raise ValueError(f"conflict references unknown flag {f!r}")
    for r in grid.get("requires") or []:
        if not isinstance(r, dict) or not isinstance(r.get("if"), dict) or not isinstance(r.get("then"), dict):
            raise ValueError(f"requires {r!r} must be {{if: {{...}}, then: {{...}}}}")
        for f in list(r["if"]) + list(r["then"]):
            if f not in grid["flags"]:
                raise ValueError(f"requires references unknown flag {f!r}")
    return grid


def _key(v: Any) -> str:
    return json.dumps(v, sort_keys=True)


# ---- constraints ---------------------------------------------------------------------------------
def _assignment_holds(assign: Dict[str, Any], case: Case) -> Optional[bool]:
    """True/False when every flag in `assign` is decided in `case`; None while undecided."""
    verdict = True
    for f, v in assign.items():
        if f not in case:
            return None
        if _key(case[f]) != _key(v):
            verdict = False
    return verdict


def violates(case: Case, grid: Dict[str, Any], partial: bool = True) -> bool:
    """Does `case` (possibly partial) already break a constraint?"""
    for c in grid.get("conflicts") or []:
        if _assignment_holds(c, case) is True:
            return True
    for r in grid.get("requires") or []:
        cond = _assignment_holds(r["if"], case)
        if cond is True:
            then = _assignment_holds(r["then"], case)
            if then is False:
                return True
            if then is None and not partial:
                return True
    return False


def is_valid(case: Case, grid: Dict[str, Any]) -> bool:
    return len(case) == len(grid["flags"]) and not violates(case, grid, partial=False)


def valid_pairs(grid: Dict[str, Any]) -> List[Pair]:
    """Every 2-way (flag, value) pair that can appear in at least one fully valid case.

    A pair that no valid case can contain is not a coverage obligation; deciding that needs the
    full Cartesian check only for pairs that a constraint touches, so it stays cheap in practice.
    """
    flags = list(grid["flags"])
    constrained = set()
    for c in grid.get("conflicts") or []:
        constrained.update(c)
    for r in grid.get("requires") or []:
        constrained.update(r["if"])
        constrained.update(r["then"])
    out: List[Pair] = []
    for a, b in itertools.combinations(flags, 2):
        for va in grid["flags"][a]:
            for vb in grid["flags"][b]:
                seed = {a: va, b: vb}
                if violates(seed, grid):
                    continue
                if (a in constrained or b in constrained) and _complete(seed, grid) is None:
                    continue
                out.append((a, va, b, vb))
    return out


def _complete(seed: Case, grid: Dict[str, Any], rng: Optional[random.Random] = None) -> Optional[Case]:
    """Extend a partial assignment to a full valid case by backtracking; None if impossible."""
    flags = [f for f in grid["flags"] if f not in seed]
    rng = rng or random.Random(0)

    def rec(case: Case, idx: int) -> Optional[Case]:
        if idx == len(flags):
            return case if is_valid(case, grid) else None
        f = flags[idx]
        values = list(grid["flags"][f])
        rng.shuffle(values)
        for v in values:
            case[f] = v
            if not violates(case, grid):
                got = rec(case, idx + 1)
                if got is not None:
                    return got
            del case[f]
        return None

    return rec(dict(seed), 0)


# ---- pairwise (AETG-style greedy) generator ----------------------------------------------------
def generate_pairwise(grid: Dict[str, Any], seed: int = 0, candidates: int = 30) -> List[Case]:
    """Greedy covering array: each new case is the best of `candidates` random valid completions."""
    rng = random.Random(seed)
    flags = list(grid["flags"])
    uncovered = set(valid_pairs(grid))
    cases: List[Case] = []

    def pairs_of(case: Case) -> Iterable[Pair]:
        for a, b in itertools.combinations(flags, 2):
            yield (a, case[a], b, case[b])

    def covers(case: Case) -> int:
        return sum(1 for p in pairs_of(case) if p in uncovered)

    stall = 0
    while uncovered and stall < 50:
        best: Optional[Case] = None
        best_gain = -1
        # bias candidates toward an uncovered pair so progress is guaranteed under constraints
        for _ in range(candidates):
            a, va, b, vb = rng.choice(tuple(uncovered))
            cand = _complete({a: va, b: vb}, grid, rng)
            if cand is None:
                uncovered.discard((a, va, b, vb))  # provably uncoverable, drop the obligation
                continue
            gain = covers(cand)
            if gain > best_gain:
                best, best_gain = cand, gain
        if best is None or best_gain <= 0:
            stall += 1
            continue
        stall = 0
        cases.append({f: best[f] for f in flags})
        for p in pairs_of(best):
            uncovered.discard(p)
    return cases


def coverage_report(cases: Sequence[Case], grid: Dict[str, Any]) -> Dict[str, Any]:
    flags = list(grid["flags"])
    obligations = set(valid_pairs(grid))
    seen = set()
    invalid = [c for c in cases if not is_valid(c, grid)]
    for c in cases:
        for a, b in itertools.combinations(flags, 2):
            seen.add((a, c[a], b, c[b]))
    missing = obligations - seen
    cartesian = 1
    for v in grid["flags"].values():
        cartesian *= len(v)
    return {
        "cases": len(cases),
        "cartesian": cartesian,
        "reduction_pct": round(100.0 * (1 - len(cases) / cartesian), 1) if cartesian else 0.0,
        "pairs_required": len(obligations),
        "pairs_covered": len(obligations & seen),
        "pairs_missing": sorted(json.dumps(m) for m in missing),
        "invalid_cases": len(invalid),
        "coverage_pct": round(100.0 * (len(obligations & seen) / len(obligations)), 2) if obligations else 100.0,
        "complete": not missing and not invalid,
    }


def render_flags(case: Case) -> List[str]:
    argv: List[str] = []
    for f, v in case.items():
        if v is None or v is False:
            continue
        if v is True:
            argv.append(f)
        else:
            argv.extend([f, str(v)])
    return argv


# ---- Tier-1 $0 classifier -----------------------------------------------------------------------
DEFAULT_THRESHOLDS: Dict[str, Any] = {
    "version": 1,
    "calibrated": False,
    "pass_exit_codes": [0],
    "fail_exit_codes": [1, 2, 126, 127],
    "slow_ms": 30000.0,                 # slower than this with rc=0 is an anomaly, not a pass
    "fail_keywords": ["traceback", "error:", "fatal:", "assert", "panic", "segmentation fault", "command not found", "no such file"],
    "benign_keywords": ["warning:", "deprecat", "notice:"],
    "anomaly_signals": [6, 9, 11, 15],  # SIGABRT/SIGKILL/SIGSEGV/SIGTERM: never silently classified
}

FAIL_CLASSES = ("usage", "missing_file", "crash", "assertion", "generic_error")


def load_thresholds(path: Optional[str] = None) -> Dict[str, Any]:
    p = path or DEFAULT_CALIBRATION
    if p and os.path.isfile(p):
        with open(p, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        merged = dict(DEFAULT_THRESHOLDS)
        merged.update(data)
        return merged
    return dict(DEFAULT_THRESHOLDS)


def classify_stderr(stderr: str) -> Optional[str]:
    s = normalize_stderr(stderr).lower()
    if not s:
        return None
    if ("usage:" in s or "unrecognized argument" in s or "invalid option" in s or "unknown option" in s
            or " required" in s or "unknown subsystem" in s or "unknown verb" in s or "unsupported " in s
            or "unknown flag" in s or "unknown command" in s or "unknown argument" in s or "expected one argument" in s
            or "invalid choice" in s or "missing required" in s or "no such option" in s):
        return "usage"
    if "no such file" in s or "not found" in s:
        return "missing_file"
    if "segmentation fault" in s or "core dumped" in s or "panic" in s:
        return "crash"
    if "assert" in s:
        return "assertion"
    if "traceback" in s or "error" in s or "fatal" in s:
        return "generic_error"
    return None


def tier1_classify(exit_code: int, signal: int, stderr: str, duration_ms: float, thresholds: Optional[Dict[str, Any]] = None) -> Tuple[str, str]:
    """(verdict, reason) with verdict in pass|fail|anomaly. Deterministic, no I/O, microseconds."""
    t = thresholds or DEFAULT_THRESHOLDS
    if signal and signal in t["anomaly_signals"]:
        return "anomaly", f"died by signal {signal}"
    if signal:
        return "fail", f"died by signal {signal}"
    cls = classify_stderr(stderr)
    if exit_code in t["pass_exit_codes"]:
        if cls in ("crash", "assertion"):
            return "anomaly", f"rc=0 but stderr looks like {cls}"
        if duration_ms > float(t["slow_ms"]):
            return "anomaly", f"rc=0 but {duration_ms:.0f}ms > slow_ms {t['slow_ms']}"
        return "pass", "rc in pass set"
    if exit_code in t["fail_exit_codes"]:
        if cls or not stderr.strip():
            return "fail", f"rc={exit_code} class={cls or 'silent'}"
        return "anomaly", f"rc={exit_code} with unclassified stderr"
    if exit_code == 124:
        return "anomaly", "timeout"
    return "anomaly", f"rc={exit_code} outside calibrated sets"


def classify_events(events: Iterable[TelemetryEvent], thresholds: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    counts = {"pass": 0, "fail": 0, "anomaly": 0}
    anomalies: List[Dict[str, Any]] = []
    out: List[TelemetryEvent] = []
    t0 = time.perf_counter()
    for ev in events:
        stderr = str(ev.extra.get("stderr_sample", ev.extra.get("stderr", "")))
        verdict, reason = tier1_classify(ev.exit_code, ev.signal, stderr, ev.duration_ms, thresholds)
        ev.tier_1_verdict = verdict
        ev.extra["tier_1_reason"] = reason
        counts[verdict] += 1
        if verdict == "anomaly":
            anomalies.append({"input_hash": ev.input_hash, "argv": ev.extra.get("argv"), "reason": reason, "stderr_digest": ev.stderr_digest})
        out.append(ev)
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    total = sum(counts.values())
    return {
        "counts": counts,
        "total": total,
        "anomaly_rate_pct": round(100.0 * counts["anomaly"] / total, 2) if total else 0.0,
        "classify_ms_per_event": round(elapsed_ms / total, 4) if total else 0.0,
        "anomalies": anomalies,
        "events": out,
    }


# ---- execution ---------------------------------------------------------------------------------
def run_cases(
    grid: Dict[str, Any],
    cases: Sequence[Case],
    cwd: str,
    telemetry_out: str,
    command: Optional[str] = None,
    timeout: Optional[int] = None,
    thresholds: Optional[Dict[str, Any]] = None,
    tier2_cmd: Optional[str] = None,
    run_id: str = "",
) -> Dict[str, Any]:
    run_id = run_id or new_run_id()
    template = command or grid.get("command") or ""
    if "{flags}" not in template:
        raise ValueError("command needs a {flags} placeholder")
    timeout = timeout or int(grid.get("per_case_timeout_seconds", 120))
    events: List[TelemetryEvent] = []
    for case in cases:
        flags = render_flags(case)
        argv = shlex.split(template.replace("{flags}", " ".join(shlex.quote(f) for f in flags)))
        t0 = time.monotonic()
        try:
            res = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=timeout)
            rc, err = res.returncode, res.stderr
        except subprocess.TimeoutExpired as exc:
            rc, err = 124, (exc.stderr.decode() if isinstance(exc.stderr, bytes) else (exc.stderr or "")) + "\n[timeout]"
        except FileNotFoundError as exc:
            rc, err = 127, f"command not found: {exc}"
        ms = (time.monotonic() - t0) * 1000.0
        ev = event_from_completed("pairwise", argv, rc, err, ms, run_id=run_id, case=case, stderr_sample=err[-2000:])
        events.append(ev)
    report = classify_events(events, thresholds)
    for ev in report["events"]:
        append_jsonl(telemetry_out, ev)
    escalated = 0
    if tier2_cmd and report["anomalies"]:
        payload = json.dumps(report["anomalies"])
        try:
            subprocess.run(shlex.split(tier2_cmd), input=payload, text=True, cwd=cwd, timeout=600, check=False)
            escalated = len(report["anomalies"])
        except (OSError, subprocess.TimeoutExpired):
            pass
    report.pop("events", None)
    report.update({"run_id": run_id, "escalated": escalated, "telemetry_out": telemetry_out})
    return report


# ---- self-test ---------------------------------------------------------------------------------
def _twelve_flag_grid() -> Dict[str, Any]:
    flags = {f"--f{i}": [True, False] for i in range(1, 9)}
    flags["--jobs"] = [1, 2, 4]
    flags["--mode"] = ["fast", "full", None]
    flags["--tier"] = [1, 2, 3]
    flags["--fmt"] = ["json", "text"]
    return {
        "flags": flags,
        "conflicts": [{"--f1": True, "--f2": True}, {"--mode": "fast", "--tier": 3}],
        "requires": [{"if": {"--mode": "full"}, "then": {"--f3": True}}, {"if": {"--jobs": 4}, "then": {"--f4": True}}],
    }


def run_suite(as_json: bool = False) -> int:
    checks: List[Tuple[str, bool, str]] = []

    def ok(name: str, cond: bool, detail: str = "") -> None:
        checks.append((name, bool(cond), detail))

    grid = validate_grid(_twelve_flag_grid())
    cases = generate_pairwise(grid, seed=7)
    rep = coverage_report(cases, grid)
    ok("12-flag grid: ≤200 cases", rep["cases"] <= 200, f"{rep['cases']} cases, cartesian {rep['cartesian']}")
    ok("12-flag grid: 100% valid 2-way coverage", rep["complete"], f"{rep['pairs_covered']}/{rep['pairs_required']}, missing {len(rep['pairs_missing'])}")
    ok("12-flag grid: no case violates a constraint", rep["invalid_cases"] == 0)
    ok("12-flag grid: ≥85% reduction vs Cartesian", rep["reduction_pct"] >= 85.0, f"{rep['reduction_pct']}%")
    ok("determinism: same seed, same array", generate_pairwise(grid, seed=7) == cases)
    # falsification: dropping a case must break completeness
    ok("coverage oracle detects a removed case", not coverage_report(cases[:-3], grid)["complete"])
    # falsification: an injected conflicting case is reported invalid
    bad = dict(cases[0]); bad["--f1"] = True; bad["--f2"] = True
    ok("coverage oracle detects an invalid case", coverage_report(cases + [bad], grid)["invalid_cases"] == 1)
    ok("render: true->flag, false/null->omitted, scalar->flag value",
       render_flags({"--a": True, "--b": False, "--c": None, "--d": 4}) == ["--a", "--d", "4"])

    # Tier-1 classifier: deterministic verdicts + speed
    t = DEFAULT_THRESHOLDS
    ok("tier1: rc=0 clean -> pass", tier1_classify(0, 0, "", 10, t)[0] == "pass")
    ok("tier1: rc=2 usage -> fail", tier1_classify(2, 0, "usage: x [-h]\nerror: unrecognized arguments", 5, t)[0] == "fail")
    ok("tier1: SIGSEGV -> anomaly", tier1_classify(139, 11, "", 5, t)[0] == "anomaly")
    ok("tier1: rc=0 with traceback-ish assert -> anomaly", tier1_classify(0, 0, "AssertionError: boom", 5, t)[0] == "anomaly")
    ok("tier1: rc=3 unclassified -> anomaly", tier1_classify(3, 0, "", 5, t)[0] == "anomaly")
    t0 = time.perf_counter()
    for _ in range(2000):
        tier1_classify(1, 0, "Traceback (most recent call last): ValueError: x", 12.0, t)
    per = (time.perf_counter() - t0) * 1000.0 / 2000
    ok("tier1: <5ms per classification", per < 5.0, f"{per:.4f}ms")
    ok("calibration file shipped and calibrated", load_thresholds().get("calibrated") is True, DEFAULT_CALIBRATION)

    failed = [c for c in checks if not c[1]]
    if as_json:
        print(json.dumps({"checks": [{"name": n, "ok": o, "detail": d} for n, o, d in checks], "passed": not failed}, indent=2))
    else:
        for n, o, d in checks:
            print(f"  {'PASS' if o else 'FAIL'}: {n}" + (f" ({d})" if d else ""))
        print(f"SUITE_RESULT={'PASS' if not failed else 'FAIL'} ({len(checks) - len(failed)}/{len(checks)})")
    return 0 if not failed else 1


# ---- CLI -----------------------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description="GH-299 Gen 4 adaptive pairwise ATE")
    p.add_argument("--mode", choices=["suite", "generate", "coverage", "classify", "run"], default="suite")
    p.add_argument("--grid", help="grid YAML/JSON")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--cwd", default=os.getcwd())
    p.add_argument("--command", help="override the grid's command template ({flags})")
    p.add_argument("--timeout", type=int)
    p.add_argument("--telemetry", help="input JSONL for --mode classify")
    p.add_argument("--telemetry-out", help="output JSONL for --mode run")
    p.add_argument("--calibration", help="tier-1 thresholds JSON (default utils/ate/tier1-calibration.json)")
    p.add_argument("--tier2-cmd", help="command that receives the anomaly list on stdin (LLM escalation)")
    p.add_argument("--anomalies-out", help="write Tier-1 anomalies JSON here")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    if a.mode == "suite":
        return run_suite(a.json)
    thresholds = load_thresholds(a.calibration)
    if a.mode in ("generate", "coverage", "run"):
        if not a.grid:
            print("adaptive_ate: --grid required", file=sys.stderr)
            return 2
        try:
            grid = load_grid(a.grid)
        except Exception as e:
            print(f"adaptive_ate: invalid --grid: {e}", file=sys.stderr)
            return 2
        cases = generate_pairwise(grid, seed=a.seed)
        rep = coverage_report(cases, grid)
        if a.mode == "generate":
            if a.json:
                print(json.dumps({"cases": cases, "coverage": rep}, indent=2))
            else:
                for c in cases:
                    print(" ".join(render_flags(c)))
                print(f"# {rep['cases']} cases, {rep['coverage_pct']}% 2-way coverage, {rep['reduction_pct']}% reduction", file=sys.stderr)
            return 0
        if a.mode == "coverage":
            print(json.dumps(rep, indent=2) if a.json else f"cases={rep['cases']} cartesian={rep['cartesian']} coverage={rep['coverage_pct']}% complete={rep['complete']}")
            return 0 if rep["complete"] else 1
        if not a.telemetry_out:
            print("--telemetry-out required", file=sys.stderr)
            return 2
        rep = run_cases(grid, cases, a.cwd, a.telemetry_out, a.command, a.timeout, thresholds, a.tier2_cmd)
        if a.anomalies_out:
            with open(a.anomalies_out, "w") as fh:
                json.dump(rep["anomalies"], fh, indent=2)
        print(json.dumps(rep, indent=2) if a.json else f"ran {rep['total']} cases: {rep['counts']} anomaly_rate={rep['anomaly_rate_pct']}% escalated={rep['escalated']}")
        return 0 if rep["counts"]["fail"] == 0 and rep["counts"]["anomaly"] == 0 else 1
    # classify
    if not a.telemetry:
        print("--telemetry required", file=sys.stderr)
        return 2
    rep = classify_events(list(read_jsonl(a.telemetry)), thresholds)
    if a.telemetry_out:
        for ev in rep["events"]:
            append_jsonl(a.telemetry_out, ev)
    if a.anomalies_out:
        with open(a.anomalies_out, "w") as fh:
            json.dump(rep["anomalies"], fh, indent=2)
    rep.pop("events", None)
    print(json.dumps(rep, indent=2) if a.json else f"{rep['counts']} anomaly_rate={rep['anomaly_rate_pct']}% {rep['classify_ms_per_event']}ms/event")
    return 0


if __name__ == "__main__":
    sys.exit(main())
