#!/usr/bin/env python3
"""gen4_campaign.py — GH-299 Gen 4 Phase 5: sandboxed CI testing campaign + self-healing handoff.

Runs the whole Gen 4 stack unattended against a DISPOSABLE FULL CLONE of this repo
(`cwd=sandbox_root`, GH-564): round-robins a target list through the mutational fuzz engine
(Phase 3), classifies every execution with the $0 Tier-1 classifier (Phase 2), checks the
sandbox tree and the HOST repo's identity with the domain oracles after every batch (Phase 1),
and at the end clusters the counterexamples and synthesizes one hermetic regression suite per
root cause (Phase 4). Optionally hands the first cluster to `self_healer.py --mode heal`.

Guarantees the soak measures (all written to <out>/campaign-report.json):
  contamination_events   sandbox tree drifted (outside .fuzz_corpus/, caches) — the sandbox is
                         reset (git reset --hard + clean) and the offending batch is recorded
  host_violations        the HOST clone's .git/config, core.bare, remotes, HEAD or tip moved
  false_positives        counterexample clusters whose representative did NOT reproduce on
                         replay — reported, never synthesized
  mutations              total executions; the plan's Phase-5 bar is >10,000 in a 2-hour soak

Everything is local-first and $0: no LLM is invoked unless --tier2-cmd / --heal-generator-cmd
is given, and hosted CI never runs this (it runs only the synthesized minimal suites).

CLI:
  gen4_campaign.py --mode suite
  gen4_campaign.py --mode run --duration 7200 --out TESTS-RESULTS/<date>+GH-299/campaign \\
      [--repo ROOT] [--sandbox-root DIR] [--targets targets.json] [--batch 25] [--seed 299] \\
      [--max-mutations N] [--parity] [--synth] [--tier2-cmd CMD] [--heal-generator-cmd CMD]
  gen4_campaign.py --mode targets            # print the default target list as JSON
"""
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any, Dict, List, Optional, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

from domain_oracles import host_identity  # noqa: E402
from fuzz_engine import execute, fuzz  # noqa: E402
from repro_synth import cluster, synthesize  # noqa: E402
from telemetry_schema import validate_jsonl  # noqa: E402

REPO_ROOT = os.path.dirname(os.path.dirname(HERE))


def sandbox_state(clone: str) -> Dict[str, Any]:
    """What 'zero-state' means for the sandbox: no git-visible drift and an unmoved .git identity.

    Ignored files (XYZ.json, relay-system/logs/, .gate-evidence/, caches) are per-machine local
    state that harness commands legitimately write; they are cleaned between batches, not counted.
    """
    status = [ln for ln in _git(clone, "status", "--porcelain").stdout.splitlines() if ".fuzz_corpus" not in ln]
    return {"status": status, "identity": host_identity(clone)}

# Real harness surfaces. Each target is fuzzed from its --base argv; usage errors are handled
# rejections, so only unhandled failures (tracebacks, signals, timeouts, unclassified rcs) count.
# validate.sh is deliberately NOT a target: a mutant that slips past --print-mode runs the whole
# gate (clones, 10+ minutes) inside the sandbox — observed on the first campaign run.
DEFAULT_TARGETS: List[Dict[str, Any]] = [
    {"name": "ci-route", "target": "bash utils/ci-route.sh {mutant}", "base": ["subsystems"], "timeout": 30},
    {"name": "releases-roadmap", "target": "python3 utils/py/releases_app.py {mutant}", "base": ["roadmap", "list"], "timeout": 60},
    {"name": "releases-check", "target": "python3 utils/py/releases_app.py {mutant}", "base": ["check"], "timeout": 90},
    {"name": "pdda-frontmatter", "target": "bash utils/pdda/pdda.sh {mutant}", "base": ["frontmatter"], "timeout": 120},
    {"name": "domain-oracles-cli", "target": "python3 utils/py/domain_oracles.py {mutant}", "base": ["--mode", "zero-state", "--cmd", "true", "--cwd", "."], "timeout": 60},
    {"name": "adaptive-ate-cli", "target": "python3 utils/py/adaptive_ate.py {mutant}", "base": ["--mode", "coverage", "--grid", "utils/ate/grids/gen4-pairwise-example.yaml"], "timeout": 60},
    {"name": "codex-turn-twins", "target": "bash relay-automation/codex-turn.sh {mutant}", "base": ["--help"], "timeout": 30, "parity_env": {"XYZ_PYTHON": "0"}},
    {"name": "agy-turn-twins", "target": "bash relay-automation/agy-turn.sh {mutant}", "base": ["--help"], "timeout": 30, "parity_env": {"XYZ_PYTHON": "0"}},
    {"name": "marathon-plan", "target": "python3 utils/py/marathon_plan.py {mutant}", "base": ["--help"], "timeout": 60},
]


def _git(root: str, *args: str, check: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", root, *args], capture_output=True, text=True, timeout=300, check=check)


def make_sandbox(repo: str, sandbox_root: Optional[str]) -> Tuple[str, bool]:
    """Full disposable clone under sandbox_root (or a fresh temp dir). Returns (path, created_tmp)."""
    created = False
    if not sandbox_root:
        sandbox_root = tempfile.mkdtemp(prefix="gen4-campaign.", dir=os.environ.get("TMPDIR") or None)
        created = True
    os.makedirs(sandbox_root, exist_ok=True)
    clone = os.path.join(sandbox_root, "clone")
    if os.path.isdir(os.path.join(clone, ".git")):
        shutil.rmtree(clone)
    subprocess.run(["git", "clone", "-q", "--no-hardlinks", repo, clone], check=True, timeout=600)
    rh, rc_ = os.path.realpath(repo), os.path.realpath(clone)
    if rc_ == rh or rc_.startswith(rh.rstrip(os.sep) + os.sep):
        raise RuntimeError(f"sandbox {rc_} is not disjoint from the repo {rh}")
    return clone, created


def reset_sandbox(clone: str) -> None:
    _git(clone, "reset", "-q", "--hard")
    _git(clone, "clean", "-fdxq", "-e", ".fuzz_corpus")


def run_campaign(
    repo: str,
    out_dir: str,
    duration: float,
    targets: List[Dict[str, Any]],
    sandbox_root: Optional[str] = None,
    batch: int = 25,
    seed: int = 299,
    max_mutations: Optional[int] = None,
    parity: bool = False,
    synth: bool = True,
    tier2_cmd: Optional[str] = None,
    heal_generator_cmd: Optional[str] = None,
    corpus_cap: int = 500,
    keep_sandbox: bool = False,
    progress: bool = True,
) -> Dict[str, Any]:
    os.makedirs(out_dir, exist_ok=True)
    telemetry = os.path.join(out_dir, "telemetry.jsonl")
    log_path = os.path.join(out_dir, "campaign.log")
    log = open(log_path, "a", encoding="utf-8")

    def say(msg: str) -> None:
        line = f"[{time.strftime('%H:%M:%S')}] {msg}"
        log.write(line + "\n"); log.flush()
        if progress:
            print(line, flush=True)

    clone, created_tmp = make_sandbox(repo, sandbox_root)
    say(f"sandbox clone at {clone} (repo {repo})")
    host_before = host_identity(repo)
    baseline = sandbox_state(clone)
    if baseline["status"]:
        raise RuntimeError(f"fresh sandbox clone is not clean: {baseline['status'][:3]}")
    say(f"sandbox baseline: clean tree at {baseline['identity']['head_tip'][:12]}")

    t_start = time.monotonic()
    deadline = t_start + duration
    stats: Dict[str, Any] = {
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "repo": repo, "sandbox": clone, "duration_s": duration,
        "targets": [t["name"] for t in targets], "batches": 0, "mutations": 0, "counts": {"pass": 0, "fail": 0, "anomaly": 0},
        "handled_rejections": 0, "counterexamples": 0, "parity_divergences": 0, "contamination_events": [],
        "host_violations": [], "per_target": {t["name"]: {"batches": 0, "mutations": 0, "counterexamples": 0, "parity_divergences": 0} for t in targets},
        "errors": [],
    }
    round_no = 0
    while time.monotonic() < deadline and (max_mutations is None or stats["mutations"] < max_mutations):
        for t in targets:
            if time.monotonic() >= deadline or (max_mutations is not None and stats["mutations"] >= max_mutations):
                break
            round_no += 1
            per = stats["per_target"][t["name"]]
            n = batch if max_mutations is None else max(1, min(batch, max_mutations - stats["mutations"]))
            try:
                rep = fuzz(
                    t["target"], clone, seed + round_no, n, os.path.join(clone, ".fuzz_corpus", t["name"]), telemetry,
                    timeout_budget=float(t.get("timeout", 30)), parity_env=(t.get("parity_env") if parity else None),
                    base_env=t.get("env"), corpus_cap=corpus_cap, base=t.get("base") or [],
                )
            except Exception as exc:  # a target that cannot even spawn must not kill the soak
                stats["errors"].append({"target": t["name"], "round": round_no, "error": str(exc)})
                say(f"round {round_no} {t['name']}: ERROR {exc}")
                continue
            stats["batches"] += 1; per["batches"] += 1
            stats["mutations"] += rep["executed"]; per["mutations"] += rep["executed"]
            for k in stats["counts"]:
                stats["counts"][k] += rep["counts"].get(k, 0)
            stats["counterexamples"] += len(rep["counterexamples"]); per["counterexamples"] += len(rep["counterexamples"])
            stats["parity_divergences"] += rep["parity_divergences"]; per["parity_divergences"] += rep["parity_divergences"]
            # Phase-1 oracles after every batch: sandbox zero-state + host containment.
            state = sandbox_state(clone)
            if state != baseline:
                changed = state["status"][:10] or [f"identity moved: {[k for k in baseline['identity'] if baseline['identity'][k] != state['identity'][k]]}"]
                stats["contamination_events"].append({"round": round_no, "target": t["name"], "seed": seed + round_no, "changed": changed})
                say(f"round {round_no} {t['name']}: CONTAMINATION — {changed[:3]}; resetting sandbox")
                reset_sandbox(clone)
                if sandbox_state(clone) != baseline:
                    stats["errors"].append({"round": round_no, "error": "sandbox could not be restored to baseline"})
                    say("sandbox could not be restored — aborting soak")
                    break
            else:
                reset_sandbox(clone)  # drop ignored local state a harness command may have written
            host_now = host_identity(repo)
            if host_now != host_before:
                moved = [k for k in host_before if host_before[k] != host_now[k]]
                stats["host_violations"].append({"round": round_no, "target": t["name"], "moved": moved})
                say(f"round {round_no} {t['name']}: HOST VIOLATION — {moved}")
            say(f"round {round_no} {t['name']}: {rep['executed']} mutants {rep['counts']} cex={len(rep['counterexamples'])} parity={rep['parity_divergences']} corpus={rep['corpus_size']} total={stats['mutations']}")
        if stats["errors"] and stats["errors"][-1].get("error", "").startswith("sandbox could not"):
            break

    stats["elapsed_s"] = round(time.monotonic() - t_start, 1)
    stats["mutations_per_min"] = round(stats["mutations"] / max(1e-9, stats["elapsed_s"] / 60), 1)
    stats["handled_rejections"] = _count_handled(telemetry)
    stats["telemetry"] = telemetry
    stats["telemetry_valid"] = validate_jsonl(telemetry)["ok"] if os.path.exists(telemetry) else True

    # Phase 4: cluster, replay-verify (false positives), synthesize.
    clusters: List[Dict[str, Any]] = []
    fps: List[Dict[str, Any]] = []
    synth_out: Dict[str, Any] = {"emitted": [], "skipped": []}
    if os.path.exists(telemetry):
        from telemetry_schema import read_jsonl
        clusters = cluster(read_jsonl(telemetry))
        verified: List[Dict[str, Any]] = []
        for g in clusters:
            argv = g.get("representative") or []
            if not argv:
                continue
            res = execute(argv, clone, float(max(t.get("timeout", 30) for t in targets)), g.get("env") or None)
            if res["vector"][2] == g["digest"] or res["rc"] == g["exit_code"]:
                verified.append(g)
            else:
                fps.append({"digest": g["digest"], "members": g["members"], "argv": argv, "replay_rc": res["rc"], "recorded_rc": g["exit_code"]})
        if synth and verified:
            synth_dir = os.path.join(out_dir, "synth")
            synth_out = synthesize(verified, synth_dir, 299, clone, minimize=True, verify=True)
            say(f"synthesized {len(synth_out['emitted'])} suite(s) into {synth_dir}")
        stats["clusters"] = [{k: v for k, v in g.items() if k not in ("stderr_sample", "env")} | {"stderr_head": g["stderr_sample"][:200]} for g in clusters]
    stats["false_positives"] = fps
    stats["synthesized"] = synth_out

    # Phase 5 optional: sandboxed self-healing handoff for the first synthesized cluster.
    if heal_generator_cmd and synth_out.get("emitted"):
        first = synth_out["emitted"][0]
        heal_cmd = [sys.executable, os.path.join(HERE, "self_healer.py"), "--mode", "heal", "--repro", first["path"],
                    "--target-file", os.path.join(clone, "validate.sh"), "--sandbox-root", os.path.dirname(clone),
                    "--regression-cmd", "bash validate.sh --print-mode", "--generator-cmd", heal_generator_cmd,
                    "--diff-out", os.path.join(out_dir, "heal.diff"), "--issue-rollup-out", os.path.join(out_dir, "heal-rollup.md"), "--json"]
        try:
            r = subprocess.run(heal_cmd, cwd=clone, capture_output=True, text=True, timeout=3600)
            stats["self_heal"] = {"rc": r.returncode, "stdout_tail": r.stdout[-1500:], "stderr_tail": r.stderr[-500:]}
        except (OSError, subprocess.TimeoutExpired) as exc:
            stats["self_heal"] = {"error": str(exc)}

    stats["verdict"] = {
        "zero_host_contamination": not stats["contamination_events"] and not stats["host_violations"],
        "zero_false_positives": not fps,
        "telemetry_line_valid": stats["telemetry_valid"],
    }
    stats["finished_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    report = os.path.join(out_dir, "campaign-report.json")
    with open(report, "w", encoding="utf-8") as fh:
        json.dump(stats, fh, indent=2, ensure_ascii=False, default=str)
    with open(os.path.join(out_dir, "campaign-summary.md"), "w", encoding="utf-8") as fh:
        fh.write(render_summary(stats))
    say(f"report -> {report}")
    log.close()
    if created_tmp and not keep_sandbox:
        shutil.rmtree(os.path.dirname(clone), ignore_errors=True)
    return stats


def _count_handled(path: str) -> int:
    if not os.path.exists(path):
        return 0
    n = 0
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            if '"handled_rejection":true' in line:
                n += 1
    return n


def render_summary(s: Dict[str, Any]) -> str:
    v = s["verdict"]
    lines = [
        f"# GH-299 Gen 4 campaign — {s['started_at']} → {s.get('finished_at', '?')}",
        "",
        f"- sandbox: `{s['sandbox']}` (disposable full clone of `{s['repo']}`)",
        f"- elapsed: {s.get('elapsed_s')}s · batches: {s['batches']} · **mutations: {s['mutations']}** ({s.get('mutations_per_min')}/min)",
        f"- tier-1 counts: {s['counts']} · handled rejections: {s['handled_rejections']} · counterexamples: {s['counterexamples']} · parity divergences: {s['parity_divergences']}",
        f"- clusters: {len(s.get('clusters', []))} · synthesized suites: {len(s['synthesized'].get('emitted', []))} · false positives: {len(s['false_positives'])}",
        f"- **zero host contamination: {v['zero_host_contamination']}** (contamination events {len(s['contamination_events'])}, host violations {len(s['host_violations'])})",
        f"- **zero false positives: {v['zero_false_positives']}** · telemetry line-valid: {v['telemetry_line_valid']}",
        "",
        "## Per target",
        "",
        "| target | batches | mutations | counterexamples | parity divergences |",
        "|---|---:|---:|---:|---:|",
    ]
    for name, p in s["per_target"].items():
        lines.append(f"| {name} | {p['batches']} | {p['mutations']} | {p['counterexamples']} | {p['parity_divergences']} |")
    if s.get("clusters"):
        lines += ["", "## Counterexample clusters", ""]
        for g in s["clusters"]:
            lines.append(f"- `{g['digest']}` × {g['members']} rc={g['exit_code']} {','.join(g['verdicts'])} — {g['stderr_head'][:120]!r}")
    if s["false_positives"]:
        lines += ["", "## False positives (did not reproduce on replay)", ""]
        for f in s["false_positives"]:
            lines.append(f"- `{f['digest']}` × {f['members']} recorded rc={f['recorded_rc']} replay rc={f['replay_rc']}")
    if s["contamination_events"]:
        lines += ["", "## Contamination events", ""]
        for c in s["contamination_events"]:
            lines.append(f"- round {c['round']} target {c['target']} seed {c['seed']}: {c['changed'][:3]}")
    if s.get("errors"):
        lines += ["", "## Errors", ""] + [f"- {e}" for e in s["errors"]]
    return "\n".join(lines) + "\n"


# ---- self-test ---------------------------------------------------------------------------------------
def run_suite(as_json: bool = False) -> int:
    checks: List[Tuple[str, bool, str]] = []

    def ok(name: str, cond: bool, detail: str = "") -> None:
        checks.append((name, bool(cond), detail))

    with tempfile.TemporaryDirectory(prefix="gen4-campaign-suite.") as td:
        # tiny host repo with one clean target and one poisoning target
        host = os.path.join(td, "host"); os.makedirs(host)
        subprocess.run(["git", "-C", host, "init", "-q", "-b", "main"], check=True)
        subprocess.run(["git", "-C", host, "config", "user.email", "t@t"], check=True)
        subprocess.run(["git", "-C", host, "config", "user.name", "t"], check=True)
        os.makedirs(os.path.join(host, "test", "lib"))
        shutil.copy(os.path.join(REPO_ROOT, "test", "lib", "fixture-guard.sh"), os.path.join(host, "test", "lib", "fixture-guard.sh"))
        with open(os.path.join(host, "tool.py"), "w") as fh:
            fh.write("import sys\na=sys.argv[1:]\nif any(x in ('-1', '0', '', '--', 'NaN') for x in a): sys.stderr.write('ValueError: bad scalar\\n'); sys.exit(1)\nsys.exit(0)\n")
        with open(os.path.join(host, "poison.sh"), "w") as fh:
            fh.write("#!/usr/bin/env bash\necho poisoned > POISON.txt\nexit 0\n")
        subprocess.run(["git", "-C", host, "add", "."], check=True)
        subprocess.run(["git", "-C", host, "commit", "-q", "-m", "init"], check=True)
        targets = [{"name": "clean", "target": f"{sys.executable} tool.py {{mutant}}", "base": ["--jobs", "4"], "timeout": 10}]
        out = os.path.join(td, "out")
        s = run_campaign(host, out, duration=20, targets=targets, sandbox_root=os.path.join(td, "sb"), batch=15, seed=1, max_mutations=60, synth=True, progress=False)
        ok("bounded soak stops at --max-mutations", s["mutations"] == 60, str(s["mutations"]))
        ok("zero host contamination on a clean target", s["verdict"]["zero_host_contamination"])
        ok("telemetry line-valid", s["verdict"]["telemetry_line_valid"])
        ok("counterexamples clustered", len(s.get("clusters", [])) >= 1, str(len(s.get("clusters", []))))
        ok("suites synthesized into <out>/synth", len(s["synthesized"]["emitted"]) >= 1)
        ok("report + summary written", os.path.isfile(os.path.join(out, "campaign-report.json")) and os.path.isfile(os.path.join(out, "campaign-summary.md")))
        ok("host identity untouched", host_identity(host) == host_identity(host) and not s["host_violations"])
        # negative control: a target that writes into the tree is caught and the sandbox restored
        poison = [{"name": "poison", "target": "bash poison.sh {mutant}", "base": ["x"], "timeout": 10}]
        s2 = run_campaign(host, os.path.join(td, "out2"), duration=20, targets=poison, sandbox_root=os.path.join(td, "sb2"), batch=5, seed=1, max_mutations=10, synth=False, progress=False, keep_sandbox=True)
        ok("contamination detected for a tree-writing target", len(s2["contamination_events"]) >= 1, str(len(s2["contamination_events"])))
        ok("verdict flags contamination", not s2["verdict"]["zero_host_contamination"])
        ok("sandbox restored after contamination (no POISON.txt)", not os.path.exists(os.path.join(td, "sb2", "clone", "POISON.txt")))
        ok("host repo never received POISON.txt", not os.path.exists(os.path.join(host, "POISON.txt")))
        # vacuous-sandbox refusal
        try:
            make_sandbox(host, os.path.join(host, "inside"))
            ok("sandbox inside the repo is refused", False)
        except RuntimeError:
            ok("sandbox inside the repo is refused", True)

    failed = [c for c in checks if not c[1]]
    if as_json:
        print(json.dumps({"checks": [{"name": n, "ok": o, "detail": d} for n, o, d in checks], "passed": not failed}, indent=2))
    else:
        for n, o, d in checks:
            print(f"  {'PASS' if o else 'FAIL'}: {n}" + (f" ({d})" if d else ""))
        print(f"SUITE_RESULT={'PASS' if not failed else 'FAIL'} ({len(checks) - len(failed)}/{len(checks)})")
    return 0 if not failed else 1


def main() -> int:
    p = argparse.ArgumentParser(description="GH-299 Gen 4 sandboxed campaign runner")
    p.add_argument("--mode", choices=["suite", "run", "targets"], default="suite")
    p.add_argument("--repo", default=REPO_ROOT)
    p.add_argument("--sandbox-root", help="directory to hold the disposable clone (default: fresh temp dir)")
    p.add_argument("--out", help="output dir for telemetry, report, synthesized suites")
    p.add_argument("--duration", type=float, default=7200.0, help="seconds (default 2h)")
    p.add_argument("--max-mutations", type=int)
    p.add_argument("--batch", type=int, default=25)
    p.add_argument("--seed", type=int, default=299)
    p.add_argument("--targets", help="JSON file: list of {name,target,base,timeout,parity_env,env}")
    p.add_argument("--only", action="append", default=[], help="restrict to target name(s)")
    p.add_argument("--parity", action="store_true", help="enable the cross-twin parity oracle where a target declares parity_env")
    p.add_argument("--no-synth", action="store_true")
    p.add_argument("--tier2-cmd")
    p.add_argument("--heal-generator-cmd", help="opt-in: hand the first synthesized cluster to self_healer.py with this fix generator")
    p.add_argument("--corpus-cap", type=int, default=500)
    p.add_argument("--keep-sandbox", action="store_true")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    if a.mode == "suite":
        return run_suite(a.json)
    targets = DEFAULT_TARGETS
    if a.targets:
        with open(a.targets) as fh:
            targets = json.load(fh)
    if a.only:
        targets = [t for t in targets if t["name"] in a.only]
    if a.mode == "targets":
        print(json.dumps(targets, indent=2))
        return 0
    if not a.out:
        print("--out required", file=sys.stderr)
        return 2
    s = run_campaign(os.path.abspath(a.repo), a.out, a.duration, targets, a.sandbox_root, a.batch, a.seed, a.max_mutations,
                     a.parity, not a.no_synth, a.tier2_cmd, a.heal_generator_cmd, a.corpus_cap, a.keep_sandbox, progress=not a.quiet)
    if a.json:
        print(json.dumps({k: s[k] for k in ("mutations", "counts", "counterexamples", "parity_divergences", "verdict", "elapsed_s")}, indent=2))
    else:
        print(render_summary(s))
    v = s["verdict"]
    return 0 if v["zero_host_contamination"] and v["telemetry_line_valid"] else 1


if __name__ == "__main__":
    sys.exit(main())
