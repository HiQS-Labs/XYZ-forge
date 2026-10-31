#!/usr/bin/env python3
"""GH-1279 Stage B: execution-readiness dry runs for one arm's launch packets. Nothing is executed or approved.

For up to --cap lanes of a wave (packet order): validate MARATHON.yaml with the existing validator, copy the packet
into a SEPARATE disposable full clone under PROJECT/2-WORKING/, run `marathon.sh --dry-run` with distinct builder and
reviewer, and run the preflight dry run where the brief names a capture doc. Lanes past the cap are reported
`not dry-run verified`, never ready. All real outcomes (including NOT-READY, STALE, AMBIGUOUS, BLOCKED) are kept verbatim.

usage: stageb_dryrun.py --repo REPO --root RUN_ROOT_NAME --wave N --clone DRYCLONE --out OUTDIR [--cap 10]
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stageb_prepare as prep  # noqa: E402


def sh(argv, cwd, timeout=600):
    p = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    return {"rc": p.returncode, "stdout": p.stdout[-1500:], "stderr": p.stderr[-800:]}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--root", required=True)
    ap.add_argument("--wave", type=int, required=True)
    ap.add_argument("--clone", required=True, help="separate disposable full clone for the dry runs")
    ap.add_argument("--out", required=True)
    ap.add_argument("--cap", type=int, default=10)
    a = ap.parse_args()
    repo, clone, out = Path(a.repo).resolve(), Path(a.clone).resolve(), Path(a.out).resolve()
    assert clone != repo and (clone / ".git").is_dir(), "the dry-run clone must be a separate full clone"
    assert not sh(["git", "status", "--porcelain"], clone)["stdout"].strip(), "dry-run clone must start clean"
    out.mkdir(parents=True, exist_ok=True)
    p = subprocess.run([sys.executable, str(repo / "utils" / "py" / "harness.py"), "factory-primitive", "--run-root",
                        f"temp/factory-primitive/{a.root}", "packet", "--wave", str(a.wave)], cwd=repo, capture_output=True, text=True)
    if p.returncode != 0:
        print(json.dumps({"status": "no packet", "rc": p.returncode, "stderr": p.stderr[-300:]}))
        (out / "dryrun.json").write_text(json.dumps({"ready_lane_set": [], "reason": f"packet failed rc={p.returncode}: {p.stderr[-200:]}"}, indent=1))
        return 1
    packet = json.loads(p.stdout.strip().splitlines()[-1])
    wave_dir = Path(packet["dir"])
    lanes = packet["emitted"]
    if not lanes:
        (out / "dryrun.json").write_text(json.dumps({"ready_lane_set": [], "reason": "the wave emitted no launch packets"}, indent=1))
        print("no ready lanes: the wave emitted no launch packets")
        return 0
    report = {"wave": a.wave, "root": a.root, "cap": a.cap, "emitted": lanes, "lanes": [], "not_dry_run_verified": lanes[a.cap:]}
    # the preflight contract resolves target.ref against a local branch; create it in the disposable clone (no checkout)
    if sh(["git", "rev-parse", "--verify", "--quiet", "development"], clone)["rc"] != 0:
        sh(["git", "branch", "development", "origin/development"], clone)
    worktrees_before = set(sh(["git", "worktree", "list", "--porcelain"], clone)["stdout"].splitlines())
    for issue in lanes[:a.cap]:
        folder = wave_dir / f"GH-{issue}-LAUNCH"
        yaml = folder / "MARATHON.yaml"
        brief = (folder / "brief.md").read_text(encoding="utf-8")
        doc = re.search(r"^- Capture doc: (\S+)", brief, re.M)
        doc_path = doc.group(1) if doc and doc.group(1) != "none" else None
        lane = {"issue": issue, "validator": sh([str(repo / "bin" / "marathon-yaml"), str(yaml)], repo)}
        dest = clone / "PROJECT" / "2-WORKING" / folder.name
        shutil.rmtree(dest, ignore_errors=True)
        shutil.copytree(folder, dest)
        phases = tempfile.mkdtemp(prefix="sb-phases-")
        lane["marathon_dry_run"] = sh(["relay-automation/marathon.sh", "--plan", f"PROJECT/2-WORKING/{folder.name}/MARATHON.yaml",
                                       "--builder", "agy", "--dry-run", "--phases-dir", phases], clone)
        lane["roles"] = {"builder": "agy", "reviewer": re.search(r"reviewer: (\w+)", yaml.read_text()).group(1)}
        if doc_path and (clone / doc_path).is_file():
            full = subprocess.run(["utils/swarm-preflight.sh", "--project-doc", doc_path, "--dry-run", "--format", "json"],
                                  cwd=clone, capture_output=True, text=True, timeout=600)
            (out / f"preflight-{issue}.json").write_text(full.stdout, encoding="utf-8")
            pf = {"rc": full.returncode, "stderr": full.stderr[-400:], "file": f"preflight-{issue}.json"}
            try:
                j = json.loads(full.stdout)
                pf["readiness"] = {k: j["readiness"].get(k) for k in ("ready", "next_action")}
                pf["freshness"] = j.get("freshness")
            except (ValueError, KeyError):
                pf["readiness"] = {"unparsed": full.stdout[:300]}
            lane["preflight_dry_run"] = pf
        else:
            lane["preflight_dry_run"] = {"unsupported": "the brief names no capture doc present in the clone" if not doc_path else f"{doc_path} not found in the clone"}
        lane["dry_run_verified"] = lane["validator"]["rc"] == 0 and lane["marathon_dry_run"]["rc"] == 0 and lane["roles"]["builder"] != lane["roles"]["reviewer"]
        shutil.rmtree(dest, ignore_errors=True)
        shutil.rmtree(phases, ignore_errors=True)
        report["lanes"].append(lane)
    extra = [l for l in sh(["git", "worktree", "list", "--porcelain"], clone)["stdout"].splitlines() if l not in worktrees_before and l.startswith("worktree ")]
    for l in extra:
        sh(["git", "worktree", "remove", "--force", l.split(" ", 1)[1]], clone)
    report["worktrees_removed"] = extra
    report["clone_clean_after"] = not sh(["git", "status", "--porcelain"], clone)["stdout"].strip()
    # ready = validator + marathon dry run + preflight dry run all pass; a lane the preflight cannot assess is only "verified without preflight"
    pf_ready = lambda l: (l["preflight_dry_run"].get("readiness") or {}).get("ready") is True
    report["ready_lane_set"] = [l["issue"] for l in report["lanes"] if l["dry_run_verified"] and pf_ready(l)]
    report["verified_without_preflight"] = [l["issue"] for l in report["lanes"] if l["dry_run_verified"] and "unsupported" in l["preflight_dry_run"]]
    report["marathon_ok_preflight_not_ready"] = [l["issue"] for l in report["lanes"] if l["dry_run_verified"] and "readiness" in l["preflight_dry_run"] and not pf_ready(l)]
    if not report["ready_lane_set"]:
        report["reason"] = "no lane passed the validator, the marathon dry run and the preflight dry run"
    (out / "dryrun.json").write_text(json.dumps(report, indent=1) + "\n")
    print(json.dumps({"ready": report["ready_lane_set"], "marathon_ok_preflight_not_ready": report["marathon_ok_preflight_not_ready"], "verified_without_preflight": report["verified_without_preflight"], "not_verified": report["not_dry_run_verified"], "clone_clean_after": report["clone_clean_after"]}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
