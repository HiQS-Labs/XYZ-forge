#!/usr/bin/env python3
"""repro_synth.py — GH-299 Gen 4 Phase 4: clustered hermetic reproducer & test synthesizer bridge.

Turns Gen 4 telemetry (fuzz / pairwise / oracle rows from `telemetry_schema`) into committed
regression suites, one per ROOT CAUSE rather than one per mutant:

  1. select     counterexamples = Tier-1 `anomaly`, or `fail` that is not a handled rejection
  2. cluster    group by `stderr_digest` (sha256 of the normalized stderr) — 50 mutations of the
                same bug collapse to one cluster
  3. minimize   per cluster, take the smallest mutant and ddmin its argv + env with the Gen 3
                minimizers (`repro_builder.minimize_argv` / `minimize_environment`), asserting the
                failure signature still reproduces after every cut
  4. emit       `test/gh<N>-gen4-<digest>.sh` via `repro_builder.generate_repro_script` — a
                standalone, hermetic script that sources `test/lib/fixture-guard.sh` and PASSES
                when the failure reproduces (a regression test that turns red when the bug is
                fixed is then flipped by the human who closes the issue)

Nothing here re-implements Gen 3: the minimizer, the reproduction check and the script template
are imported from `repro_builder.py`. `repro_builder.py --mode synth` delegates here.

CLI:
  repro_synth.py --mode suite
  repro_synth.py --mode cluster --telemetry T.jsonl [--json]
  repro_synth.py --mode synth --telemetry T.jsonl --out-dir test/ --issue 299 [--repo-root R] [--no-minimize] [--json]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import stat
import sys
from typing import Any, Dict, Iterable, List, Optional, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from repro_builder import generate_repro_script, minimize_argv, minimize_environment, test_reproduction  # noqa: E402
from telemetry_schema import TelemetryEvent, read_jsonl, stderr_digest  # noqa: E402


# ---- selection & clustering ----------------------------------------------------------------------
def is_counterexample(ev: TelemetryEvent) -> bool:
    if ev.tier_1_verdict == "anomaly":
        return True
    if ev.tier_1_verdict == "fail" and not ev.extra.get("handled_rejection"):
        return True
    if ev.phase == "oracle" and not ev.all_oracles_passed:
        return True
    return False


def _argv_of(ev: TelemetryEvent) -> List[str]:
    argv = ev.extra.get("argv") or []
    return [str(a) for a in argv]


def cluster(events: Iterable[TelemetryEvent]) -> List[Dict[str, Any]]:
    """Group counterexamples by stderr_digest; keep the smallest representative per cluster."""
    groups: Dict[str, Dict[str, Any]] = {}
    for ev in events:
        if not is_counterexample(ev):
            continue
        key = ev.stderr_digest or stderr_digest(str(ev.extra.get("stderr_sample", "")))
        argv = _argv_of(ev)
        size = sum(len(a) for a in argv) + len(argv)
        g = groups.setdefault(key, {"digest": key, "members": 0, "phases": set(), "verdicts": set(), "reasons": set(),
                                    "representative": None, "rep_size": None, "exit_code": ev.exit_code, "signal": ev.signal,
                                    "stderr_sample": "", "env": {}, "cwd": ev.extra.get("cwd")})
        g["members"] += 1
        g["phases"].add(ev.phase)
        if ev.tier_1_verdict:
            g["verdicts"].add(ev.tier_1_verdict)
        if ev.extra.get("tier_1_reason"):
            g["reasons"].add(str(ev.extra["tier_1_reason"]))
        if argv and (g["rep_size"] is None or size < g["rep_size"]):
            g["representative"], g["rep_size"] = argv, size
            g["exit_code"], g["signal"] = ev.exit_code, ev.signal
            g["stderr_sample"] = str(ev.extra.get("stderr_sample", ""))
            g["env"] = dict(ev.extra.get("env") or {})
    out = []
    for g in groups.values():
        g["phases"] = sorted(g["phases"]); g["verdicts"] = sorted(g["verdicts"]); g["reasons"] = sorted(g["reasons"])
        out.append(g)
    out.sort(key=lambda g: (-g["members"], g["digest"]))
    return out


# ---- signature line: the most stable stderr line to assert on ---------------------------------------
_VOLATILE = re.compile(r"(/[\w./-]+|\b\d+\b|0x[0-9a-f]+)", re.IGNORECASE)


_ERRORISH = re.compile(r"(Error|Exception|Fault|panic|fatal|assert|error:|unsupported|invalid|refus|denied)", re.IGNORECASE)


def signature_substring(stderr: str) -> str:
    """The most specific stable line: prefer error-class lines, never one with volatile tokens."""
    best, best_score = "", (-1, -1)
    for line in stderr.splitlines():
        line = line.strip()
        if not line or line.startswith("File ") or line.startswith("[timeout") or line.startswith("Traceback ("):
            continue
        if _VOLATILE.search(line):
            continue
        score = (1 if _ERRORISH.search(line) else 0, len(line))
        if score > best_score:
            best, best_score = line, score
    if best:
        return best
    for line in stderr.splitlines():
        m = re.search(r"([A-Za-z]+(?:Error|Exception|Fault)\b[^:\n]*)", line)
        if m:
            return m.group(1).strip()
    return ""


def _slug(text: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:40] or "cluster"


# ---- synthesis -------------------------------------------------------------------------------------
def synthesize(
    clusters: List[Dict[str, Any]],
    out_dir: str,
    issue: int,
    repo_root: str,
    minimize: bool = True,
    verify: bool = True,
    max_clusters: Optional[int] = None,
) -> Dict[str, Any]:
    os.makedirs(out_dir, exist_ok=True)
    emitted: List[Dict[str, Any]] = []
    skipped: List[Dict[str, Any]] = []
    for g in clusters[: max_clusters or None]:
        argv = g.get("representative") or []
        if not argv:
            skipped.append({"digest": g["digest"], "why": "no argv recorded"}); continue
        env = {k: str(v) for k, v in (g.get("env") or {}).items()}
        rc = int(g["exit_code"])
        sub = signature_substring(g.get("stderr_sample", ""))
        reproduces = test_reproduction(argv, env, repo_root, rc, sub or None) if verify else True
        if verify and not reproduces and sub:
            sub = ""  # the substring may be volatile; retry on exit code alone
            reproduces = test_reproduction(argv, env, repo_root, rc, None)
        if verify and not reproduces:
            skipped.append({"digest": g["digest"], "why": f"did not reproduce rc={rc} in {repo_root}", "argv": argv}); continue
        min_argv, min_env = argv, env
        if minimize:
            min_env = minimize_environment(env, argv, repo_root, rc, sub or None)
            min_argv = minimize_argv(argv, min_env, repo_root, rc, sub or None, keep_first_n=1)
        name = f"gh{issue}-gen4-{g['digest'][:8]}-{_slug(sub or 'rc' + str(rc))}.sh"
        path = os.path.join(out_dir, name)
        title = (f"GH-{issue} Gen 4 synthesized reproducer — cluster {g['digest']} "
                 f"({g['members']} counterexample(s), phases {','.join(g['phases'])}, verdicts {','.join(g['verdicts'])})")
        script = generate_repro_script(min_argv, min_env, rc, sub or None, title=title, repo_root=None)
        header_note = (f"# Synthesized by utils/py/repro_synth.py (GH-299 Phase 4).\n"
                       f"# cluster={g['digest']} members={g['members']} original_argv={' '.join(shlex.quote(a) for a in argv)}\n"
                       f"# This suite PASSES while the defect reproduces; flip the assertion when the fix lands.\n")
        script = script.replace("set -euo pipefail\n", header_note + "set -euo pipefail\n", 1)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(script)
        os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        emitted.append({"digest": g["digest"], "path": path, "members": g["members"], "argv": min_argv, "env": min_env,
                        "exit_code": rc, "signature": sub, "minimized_from": len(argv), "minimized_to": len(min_argv)})
    return {"emitted": emitted, "skipped": skipped, "clusters": len(clusters)}


# ---- self-test ---------------------------------------------------------------------------------------
def run_suite(as_json: bool = False) -> int:
    import subprocess
    import tempfile
    checks: List[Tuple[str, bool, str]] = []

    def ok(name: str, cond: bool, detail: str = "") -> None:
        checks.append((name, bool(cond), detail))

    ok("signature line skips volatile tokens", signature_substring("Traceback (most recent call last):\n  File \"/tmp/x.py\", line 3\nValueError: negative jobs") == "ValueError: negative jobs")
    ok("signature line empty on pure noise", signature_substring("/tmp/a 123\n0xdeadbeef") == "")

    with tempfile.TemporaryDirectory(prefix="gen4-synth.") as td:
        # fixture repo: a tool with TWO root causes and a fixture-guard, plus fuzz telemetry
        os.makedirs(os.path.join(td, "test", "lib"))
        with open(os.path.join(td, "test", "lib", "fixture-guard.sh"), "w") as fh:
            fh.write("fixture_guard_init() { :; }\nrequire_fixture() { :; }\n")
        tool = os.path.join(td, "tool.py")
        with open(tool, "w") as fh:
            fh.write("import sys\na=sys.argv[1:]\n"
                     "if '-1' in a: sys.stderr.write('Traceback (most recent call last):\\nValueError: negative jobs\\n'); sys.exit(1)\n"
                     "if any('\\u202e' in x for x in a): sys.stderr.write('UnicodeError: rtl override in argv\\n'); sys.exit(1)\n"
                     "if any(x.startswith('--') and x not in ('--jobs','--mode') for x in a): sys.stderr.write('usage: tool.py\\n'); sys.exit(2)\n"
                     "sys.exit(0)\n")
        sys.path.insert(0, HERE)
        from fuzz_engine import fuzz  # noqa: E402
        tel = os.path.join(td, "fuzz.jsonl")
        rep = fuzz(f"{sys.executable} tool.py {{mutant}}", td, 7, 300, os.path.join(td, "corpus"), tel, timeout_budget=10, base=["--jobs", "4", "--mode", "fast"])
        ok("fixture fuzz produced counterexamples", len(rep["counterexamples"]) >= 2, str(len(rep["counterexamples"])))
        events = list(read_jsonl(tel))
        cl = cluster(events)
        ok("counterexamples collapse to root-cause clusters (≤3 for 2 planted bugs)", 1 <= len(cl) <= 3, f"{len(cl)} clusters from {len(rep['counterexamples'])} counterexamples")
        ok("handled usage rejections are not clustered", all("usage" not in g["stderr_sample"] for g in cl))
        ok("largest cluster has >1 member (dedup happened)", cl[0]["members"] > 1, str(cl[0]["members"]))
        out = synthesize(cl, os.path.join(td, "test"), 299, td, minimize=True, verify=True)
        ok("one suite emitted per reproducible cluster", len(out["emitted"]) == len(cl) - len(out["skipped"]) and len(out["emitted"]) >= 1, f"emitted={len(out['emitted'])} skipped={len(out['skipped'])}")
        for e in out["emitted"]:
            ok(f"emitted suite is executable and embeds fixture-guard: {os.path.basename(e['path'])}",
               os.access(e["path"], os.X_OK) and "fixture-guard.sh" in open(e["path"]).read())
            ok("argv was minimized (ddmin)", e["minimized_to"] <= e["minimized_from"], f"{e['minimized_from']} -> {e['minimized_to']}")
            r = subprocess.run(["bash", e["path"]], cwd=td, capture_output=True, text=True, env={**os.environ, "XYZ_ROOT": td}, timeout=60)
            ok("emitted suite PASSES while the defect reproduces", r.returncode == 0, r.stdout[-200:] + r.stderr[-200:])
        # falsification: fix the tool -> every emitted suite must go red
        with open(tool, "w") as fh:
            fh.write("import sys\nsys.exit(0)\n")
        for e in out["emitted"]:
            r = subprocess.run(["bash", e["path"]], cwd=td, capture_output=True, text=True, env={**os.environ, "XYZ_ROOT": td}, timeout=60)
            ok("emitted suite FAILS once the defect is fixed (falsification)", r.returncode != 0)

    failed = [c for c in checks if not c[1]]
    if as_json:
        print(json.dumps({"checks": [{"name": n, "ok": o, "detail": d} for n, o, d in checks], "passed": not failed}, indent=2))
    else:
        for n, o, d in checks:
            print(f"  {'PASS' if o else 'FAIL'}: {n}" + (f" ({d})" if d else ""))
        print(f"SUITE_RESULT={'PASS' if not failed else 'FAIL'} ({len(checks) - len(failed)}/{len(checks)})")
    return 0 if not failed else 1


# ---- CLI -----------------------------------------------------------------------------------------------
def main(argv: Optional[List[str]] = None) -> int:
    p = argparse.ArgumentParser(description="GH-299 Gen 4 clustered reproducer & test synthesizer")
    p.add_argument("--mode", choices=["suite", "cluster", "synth"], default="suite")
    p.add_argument("--telemetry", action="append", default=[], help="Gen 4 telemetry JSONL (repeatable)")
    p.add_argument("--out-dir", default="test")
    p.add_argument("--issue", type=int, default=299)
    p.add_argument("--repo-root", default=os.path.dirname(os.path.dirname(HERE)))
    p.add_argument("--no-minimize", action="store_true")
    p.add_argument("--no-verify", action="store_true", help="emit without re-running the counterexample first")
    p.add_argument("--max-clusters", type=int)
    p.add_argument("--json", action="store_true")
    a = p.parse_args(argv)
    if a.mode == "suite":
        return run_suite(a.json)
    if not a.telemetry:
        print("--telemetry required", file=sys.stderr)
        return 2
    events: List[TelemetryEvent] = []
    for t in a.telemetry:
        events.extend(read_jsonl(t))
    cl = cluster(events)
    if a.mode == "cluster":
        slim = [{k: v for k, v in g.items() if k not in ("stderr_sample",)} | {"stderr_head": g["stderr_sample"][:160]} for g in cl]
        print(json.dumps(slim, indent=2, ensure_ascii=False) if a.json else
              "\n".join(f"{g['digest']}  members={g['members']:4d}  rc={g['exit_code']}  {','.join(g['verdicts'])}  {signature_substring(g['stderr_sample'])[:80]}" for g in cl))
        return 0
    res = synthesize(cl, a.out_dir, a.issue, os.path.abspath(a.repo_root), minimize=not a.no_minimize, verify=not a.no_verify, max_clusters=a.max_clusters)
    print(json.dumps(res, indent=2, ensure_ascii=False) if a.json else
          f"clusters={res['clusters']} emitted={len(res['emitted'])} skipped={len(res['skipped'])}\n" + "\n".join("  " + e["path"] for e in res["emitted"]))
    return 0 if res["emitted"] or not cl else 1


if __name__ == "__main__":
    sys.exit(main())
