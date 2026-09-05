#!/usr/bin/env python3
"""calibrate_tier1.py — GH-299 Gen 4 Phase 2: data-calibrate the $0 Tier-1 classifier.

Reads a labelled benchmark of executions (default: the built-in 50 known-pass / 20 known-fail
corpus modelled on this harness's real failure shapes — usage errors, missing files, tracebacks,
signals, timeouts) and searches the threshold space for the setting with the fewest anomalies
subject to a HARD 0% false-negative floor: a known-fail may become "fail" or "anomaly", never
"pass". The winning thresholds are written to `utils/ate/tier1-calibration.json`, which
`adaptive_ate.tier1_classify` loads at import time.

Benchmark JSONL rows:  {"label": "pass"|"fail", "exit_code": N, "signal": N, "stderr": "...", "duration_ms": F}
Or a telemetry JSONL from adaptive_ate / fuzz_engine plus `--labels-from-oracles` (all-oracles-pass => pass).

CLI:
  calibrate_tier1.py                              # built-in benchmark -> utils/ate/tier1-calibration.json
  calibrate_tier1.py --benchmark runs.jsonl --out FILE [--json]
  calibrate_tier1.py --emit-benchmark FILE        # dump the built-in 50/20 corpus
  calibrate_tier1.py --verify                     # re-score the shipped file, exit 1 on any false negative
"""
from __future__ import annotations

import argparse
import itertools
import json
import os
import random
import sys
from typing import Any, Dict, List, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from adaptive_ate import DEFAULT_CALIBRATION, DEFAULT_THRESHOLDS, tier1_classify  # noqa: E402

Row = Dict[str, Any]


def builtin_benchmark(seed: int = 299) -> List[Row]:
    """50 known-pass / 20 known-fail rows shaped like this harness's real outputs."""
    rng = random.Random(seed)
    rows: List[Row] = []
    pass_stderr = [
        "", "", "", "warning: 3 suites skipped (pytest absent)", "notice: parallel mode auto-selected (cores/2)",
        "validate.sh: mode=parallel workers=4 reason=host-detected", "deprecated: --burst alias, use --width",
        "", "hint: run githooks/install.sh once per clone", "",
    ]
    for i in range(50):
        rows.append({
            "label": "pass", "exit_code": 0, "signal": 0,
            "stderr": pass_stderr[i % len(pass_stderr)],
            "duration_ms": rng.choice([3, 12, 48, 220, 900, 2400, 6100, 14000]) + rng.random() * 10,
        })
    fails = [
        (2, 0, "usage: releases_app.py [-h] ...\nreleases_app.py: error: unrecognized arguments: --bad-flag"),
        (2, 0, "validate.sh: error: unknown flag --nope"),
        (1, 0, "Traceback (most recent call last):\n  File \"jog_run.py\", line 88\nValueError: contract missing"),
        (1, 0, "fatal: not a git repository (or any of the parent directories): .git"),
        (127, 0, "bash: agy: command not found"),
        (126, 0, "bash: ./validate.sh: Permission denied"),
        (1, 0, "AssertionError: expected 6 valid combinations, got 8"),
        (1, 0, "error: cannot open ROADMAP.md: No such file or directory"),
        (137, 9, ""),
        (139, 11, "Segmentation fault (core dumped)"),
        (134, 6, "python3: Assertion failed: (x), function f, file g.c, line 10.\nAbort trap: 6"),
        (124, 0, "[timeout after 120s]"),
        (3, 0, "marathon-drive: blocked-before-dispatch: XYZ_ARCHIVE_ROOT unset"),
        (1, 0, "ERROR [pdda-check-frontmatter] PROJECT/2-WORKING/GH-1.md: missing key 'updated'"),
        (2, 0, "sqlite3.OperationalError: database is locked"),
        (1, 0, "panic: runtime error: index out of range"),
        (1, 0, ""),                                   # silent rc=1 — must not be a pass
        (0, 0, "AssertionError: silent pass with assertion in stderr"),  # rc=0 lie
        (0, 0, "Segmentation fault"),                 # rc=0 lie
        (143, 15, "Terminated"),
    ]
    for rc, sig, err in fails:
        rows.append({"label": "fail", "exit_code": rc, "signal": sig, "stderr": err, "duration_ms": rng.choice([5, 40, 300, 2000])})
    return rows


def load_benchmark(path: str, labels_from_oracles: bool = False) -> List[Row]:
    rows: List[Row] = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            if labels_from_oracles:
                oracles = d.get("oracle_results") or {}
                d["label"] = "pass" if oracles and all(oracles.values()) and d.get("exit_code", 0) == 0 else "fail"
                d["stderr"] = (d.get("extra") or {}).get("stderr_sample", (d.get("extra") or {}).get("stderr", d.get("stderr", "")))
            if d.get("label") not in ("pass", "fail"):
                raise ValueError(f"row without a pass/fail label: {line[:80]}")
            rows.append(d)
    return rows


def score(rows: List[Row], thresholds: Dict[str, Any]) -> Dict[str, Any]:
    fn = fp = anomalies = 0
    confusion = {"pass": {"pass": 0, "fail": 0, "anomaly": 0}, "fail": {"pass": 0, "fail": 0, "anomaly": 0}}
    for r in rows:
        v, _ = tier1_classify(int(r.get("exit_code", 0)), int(r.get("signal", 0)), str(r.get("stderr", "")), float(r.get("duration_ms", 0.0)), thresholds)
        confusion[r["label"]][v] += 1
        if r["label"] == "fail" and v == "pass":
            fn += 1
        if r["label"] == "pass" and v == "fail":
            fp += 1
        if v == "anomaly":
            anomalies += 1
    n = len(rows) or 1
    return {
        "rows": len(rows), "false_negatives": fn, "false_positives": fp, "anomalies": anomalies,
        "anomaly_rate_pct": round(100.0 * anomalies / n, 2), "confusion": confusion,
        "false_negative_pct": round(100.0 * fn / max(1, sum(1 for r in rows if r["label"] == "fail")), 2),
    }


def calibrate(rows: List[Row]) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Grid-search slow_ms and the fail-exit-code set; keep the lowest anomaly count with FN=0."""
    pass_durations = [float(r.get("duration_ms", 0)) for r in rows if r["label"] == "pass"]
    slow_candidates = sorted({max(pass_durations) * m for m in (1.5, 2.0, 3.0)} | {30000.0, 60000.0}) if pass_durations else [30000.0]
    observed_fail_rcs = sorted({int(r["exit_code"]) for r in rows if r["label"] == "fail" and not r.get("signal")})
    base_fail = [1, 2, 126, 127]
    rc_candidates = [base_fail, sorted(set(base_fail) | set(observed_fail_rcs) - {0, 124})]
    best_t: Dict[str, Any] = dict(DEFAULT_THRESHOLDS)
    best_s: Dict[str, Any] = score(rows, best_t)
    for slow, rcs in itertools.product(slow_candidates, rc_candidates):
        t = dict(DEFAULT_THRESHOLDS)
        t["slow_ms"] = float(slow)
        t["fail_exit_codes"] = list(rcs)
        s = score(rows, t)
        if s["false_negatives"] > 0:
            continue
        better = (best_s["false_negatives"] > 0) or (s["false_positives"], s["anomalies"]) < (best_s["false_positives"], best_s["anomalies"])
        if better:
            best_t, best_s = t, s
    best_t["calibrated"] = best_s["false_negatives"] == 0
    best_t["benchmark"] = {"rows": len(rows), "pass": sum(1 for r in rows if r["label"] == "pass"), "fail": sum(1 for r in rows if r["label"] == "fail")}
    best_t["score"] = {k: v for k, v in best_s.items() if k != "confusion"}
    return best_t, best_s


def main() -> int:
    p = argparse.ArgumentParser(description="calibrate the Gen 4 Tier-1 classifier (0% false-negative floor)")
    p.add_argument("--benchmark", help="labelled JSONL (default: built-in 50/20 corpus)")
    p.add_argument("--labels-from-oracles", action="store_true")
    p.add_argument("--out", default=DEFAULT_CALIBRATION)
    p.add_argument("--emit-benchmark", help="write the built-in corpus to this JSONL and exit")
    p.add_argument("--verify", action="store_true", help="score the shipped calibration; exit 1 on any false negative")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()

    if a.emit_benchmark:
        with open(a.emit_benchmark, "w") as fh:
            for r in builtin_benchmark():
                fh.write(json.dumps(r) + "\n")
        print(f"wrote {a.emit_benchmark}")
        return 0

    rows = load_benchmark(a.benchmark, a.labels_from_oracles) if a.benchmark else builtin_benchmark()
    if a.verify:
        if not os.path.isfile(a.out):
            print(f"no calibration at {a.out}", file=sys.stderr)
            return 1
        with open(a.out) as fh:
            t = dict(DEFAULT_THRESHOLDS); t.update(json.load(fh))
        s = score(rows, t)
        print(json.dumps(s, indent=2) if a.json else f"verify: FN={s['false_negatives']} FP={s['false_positives']} anomalies={s['anomalies']} ({s['anomaly_rate_pct']}%) rows={s['rows']}")
        return 0 if s["false_negatives"] == 0 else 1

    t, s = calibrate(rows)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, "w") as fh:
        json.dump(t, fh, indent=2, sort_keys=True)
        fh.write("\n")
    print(json.dumps({"out": a.out, "score": s, "thresholds": t}, indent=2) if a.json else
          f"calibrated -> {a.out}: FN={s['false_negatives']} FP={s['false_positives']} anomalies={s['anomalies']} ({s['anomaly_rate_pct']}%) slow_ms={t['slow_ms']} fail_rcs={t['fail_exit_codes']}")
    return 0 if s["false_negatives"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
