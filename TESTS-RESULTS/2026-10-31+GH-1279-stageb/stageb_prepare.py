#!/usr/bin/env python3
"""GH-1279 Stage B: initialise both arms on identical frozen inputs and record the frozen identity.

Run-specific tooling (not a test, not a scheduler). Two back-to-back `harness.py factory-primitive init` calls
(rules arm, then codex arm) with the same layout flags; the live GitHub state can move between them, so both
arms are re-initialised in fresh run roots up to three times and the run aborts unless the complete frozen
planning input matches: every non-manifest file under backlog/ by SHA-256, plus the normalised manifest
(created_at excluded). `freeze.json` records the identities the driver re-verifies before every tick.

usage: stageb_prepare.py --repo REPO --name NAME [--canaries FILE]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

MODEL, EFFORT = "gpt-6.1-terra", "medium"
PROMPTS = ("evaluator.v1.md", "evaluator.v2.md", "evaluator.v3.md")


def sha_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def instance_of(repo: Path, root_name: str) -> Path:
    return repo / "temp" / "factory-primitive" / root_name / "instances" / "C"


def frozen_identity(repo: Path, root_name: str) -> dict:
    """Everything the loop must not see change during the window (QA r2 R5, including the source ledger)."""
    inst = instance_of(repo, root_name)
    backlog = inst / "backlog"
    manifest = json.loads((backlog / "manifest.json").read_text(encoding="utf-8"))
    manifest.pop("created_at", None)
    cfg = json.loads((inst / "config.json").read_text(encoding="utf-8"))
    head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True, check=True).stdout.strip()
    return {
        "source_head": head,
        "source_ledger": sha_file(repo / "releases.db"),
        "backlog_files": {f.name: sha_file(f) for f in sorted(backlog.iterdir()) if f.is_file() and f.name != "manifest.json"},
        "manifest_normalised": hashlib.sha256(canonical(manifest).encode()).hexdigest(),
        "config": sha_file(inst / "config.json"),
        "config_route": {k: cfg.get(k) for k in ("adapter", "codex_model", "codex_effort", "adapter_timeout_s", "codex_flags",
                                               "codex_authoring", "prompt_sha256", "daily_cap", "max_call_cost")},
        "prompts": {n: sha_file(repo / "utils" / "py" / "factory_primitive" / "prompts" / n) for n in PROMPTS},
        "harness": sha_file(repo / "utils" / "py" / "harness.py"),
    }


def init_arm(repo: Path, root_name: str, arm: str, canaries: Path) -> subprocess.CompletedProcess:
    argv = [sys.executable, str(repo / "utils" / "py" / "harness.py"), "factory-primitive", "--run-root",
            f"temp/factory-primitive/{root_name}", "init", "--from-prs", "--limit", "33", "--unregistered", "33",
            "--canaries", str(canaries), "--slots", "96", "--miss", "85-90", "--daily-cap", "1.8", "--max-call-cost", "0.01"]
    if arm == "codex":
        argv += ["--adapter", "codex", "--codex-model", MODEL, "--codex-effort", EFFORT, "--codex-authoring", "--adapter-timeout", "90"]
    return subprocess.run(argv, cwd=repo, capture_output=True, text=True, timeout=900)


def parity(a: dict, b: dict) -> list[str]:
    """Differences that must abort the run. Only the intended rules/codex config route may differ."""
    diffs = []
    for key in ("source_head", "source_ledger", "backlog_files", "manifest_normalised", "prompts", "harness"):
        if a[key] != b[key]:
            diffs.append(key)
    return diffs


def layout_ok(repo: Path, root_name: str) -> dict:
    man = json.loads((instance_of(repo, root_name) / "backlog" / "manifest.json").read_text(encoding="utf-8"))
    lay = man["layout"]
    assert len(lay["canaries"]) == 24, "expected exactly 24 canaries"
    assert lay["miss"] == [85, 90] and lay["slots"] == 96
    assert 24 + 6 + lay["real"] + lay["idle"] == 96, "slot budget does not sum to 96"
    assert lay["real"] + lay["idle"] == 66
    slots = {q["slot"]: q for q in man["requests"].values()}
    assert 37 in slots and "canary" not in slots[37], "slot 37 must carry a real request"
    assert not any(85 <= s <= 90 for s in slots), "no request may be available in the missed range"
    return lay


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--canaries", default="utils/py/factory_primitive/scenarios/gh1279-canaries.jsonl")
    a = ap.parse_args()
    repo = Path(a.repo).resolve()
    assert (repo / "utils" / "py" / "harness.py").is_file(), "not a harness checkout"
    canaries = (repo / a.canaries).resolve() if not Path(a.canaries).is_absolute() else Path(a.canaries)
    last = None
    for attempt in range(1, 4):
        names = {"rules": f"{a.name}-rules", "codex": f"{a.name}-codex"}
        for n in names.values():
            shutil.rmtree(repo / "temp" / "factory-primitive" / n, ignore_errors=True)
        procs = {arm: init_arm(repo, n, arm, canaries) for arm, n in names.items()}
        if any(p.returncode != 0 for p in procs.values()):
            last = {arm: p.stderr[-200:] for arm, p in procs.items()}
            print(f"attempt {attempt}: init failed {last}", flush=True)
            time.sleep(20)
            continue
        ids = {arm: frozen_identity(repo, n) for arm, n in names.items()}
        diffs = parity(ids["rules"], ids["codex"])
        if diffs:
            last = f"parity differs in {diffs}"
            print(f"attempt {attempt}: {last}", flush=True)
            continue
        lay = layout_ok(repo, names["rules"])
        freeze = {"name": a.name, "roots": names, "layout": {k: lay[k] for k in ("slots", "miss", "real", "idle")},
                  "canary_file": str(canaries), "canary_sha256": sha_file(canaries), "identities": ids,
                  "route": {"model": MODEL, "effort": EFFORT, "authoring": True, "call_cap": 180}}
        out = repo / "temp" / "factory-primitive" / f"{a.name}-freeze.json"
        out.write_text(json.dumps(freeze, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(json.dumps({"status": "prepared", "freeze": str(out), "real": lay["real"], "idle": lay["idle"], "attempt": attempt}))
        return 0
    print(f"abort: could not obtain two arms with identical frozen inputs ({last})", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
