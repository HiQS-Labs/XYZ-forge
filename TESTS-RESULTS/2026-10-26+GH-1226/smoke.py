#!/usr/bin/env python3
"""GH-1226 manual smoke (GH-1088): drive merge_cleanup.py's real CLI against the phase-B fixture
(bare origin + gh stub) through the incident's shape and the adjacent operator paths.
Run from a disposable clone: python3 TESTS-RESULTS/2026-10-26+GH-1226/smoke.py"""
import json, os, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(REPO / "test"), str(REPO / "skills/2-daily/merge-cleanup/scripts")]
from gh534_phase_b_tests import LedgerFixture, park  # noqa: E402

f = LedgerFixture("setUp")
f.setUp()
MC = REPO / "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
env = {**os.environ, "MERGE_CLEANUP_GH_BIN": str(f.gh), "GH_STATE": str(f.state), "RELEASES_GH_BIN": str(f.gh),
       "MERGE_CLEANUP_CHECKS_WAIT_S": "2", "MERGE_CLEANUP_CHECKS_POLL_S": "1"}  # a short, real bounded wait

def cli(label, *extra):
    r = subprocess.run([sys.executable, str(MC), "--primary", str(f.primary), "--root", str(f.tmp / "no-roots"), *extra],
                       capture_output=True, text=True, env=env)
    keep = [l for l in (r.stdout + r.stderr).splitlines()
            if any(k in l for k in ("--prs", "REFUSING", "DEFERRED", "not in --prs", "Merged set", "pinned",
                                    "head moved", "required checks", "not an open", "did not land", "Would merge"))]
    print(f"$ merge_cleanup.py {' '.join(extra)}   # {label}\nrc={r.returncode}")
    print("\n".join("  " + l for l in keep) + "\n")
    return r.returncode

def states():
    return {n: p["state"] for n, p in json.loads(f.state.read_text())["prs"].items()}

f.branch("feat/a", 1, lambda r: park(r, 200, "vetted"))
f.branch("feat/b", 2, lambda r: (r / "b.txt").write_text("b\n"))
results = {}
results["execute_without_prs_refused"] = cli("1. merging --execute without --prs", "--execute") == 2
results["dry_run_pins"] = cli("2. dry run pins the vetted list", "--prs", "1") == 0
f.branch("feat/c", 3, lambda r: (r / "c.txt").write_text("late\n"))   # the incident: opened after the dry run
results["unpinned_pr_refused"] = cli("3. --execute naming a PR the dry run did not pin", "--prs", "1,3", "--execute") == 2
rc = cli("4. MAIN PATH: execute the pinned list; #3 opened after the dry run", "--prs", "1", "--execute")
results["main_path_lands_only_listed"] = rc == 0 and states() == {"1": "MERGED", "2": "OPEN", "3": "OPEN"}
cli("5. dry run pins #2", "--prs", "2")
w = f.clone("w-2-move"); subprocess.run(["git", "-C", str(w), "checkout", "-q", "feat/b"], check=True)
(w / "b.txt").write_text("moved\n"); subprocess.run(["git", "-C", str(w), "commit", "-qam", "move"], check=True)
subprocess.run(["git", "-C", str(w), "push", "-q", "origin", "feat/b"], check=True)
results["moved_head_refused"] = cli("6. head moved after the dry run", "--prs", "2", "--execute") == 2
cli("7. re-pin #2", "--prs", "2")
st = json.loads(f.state.read_text()); st["checks"] = {"2": [{"name": "pytest db fast", "bucket": "pending"}]}
f.state.write_text(json.dumps(st))
rc = cli("8. required check pending", "--prs", "2", "--execute")
results["pending_check_defers"] = rc == 3 and states()["2"] == "OPEN"
st = json.loads(f.state.read_text()); st["checks"] = {"2": [{"name": "pytest db fast", "bucket": "pass"}]}
f.state.write_text(json.dumps(st))
rc = cli("9. rerun once the check passed (same pin)", "--prs", "2", "--resume", "--execute")
results["green_check_lands"] = rc in (0, 4) and states()["2"] == "MERGED" and states()["3"] == "OPEN"
sel = json.loads(merge_cleanup_sel.read_text()) if (merge_cleanup_sel := next(f.primary.glob(".tick/merge-cleanup/*/selection-development.json"), None)) else {}
merge_cleanup_sel.unlink()  # #1231's path: the printed N@sha line stands alone, without the record
r = subprocess.run([sys.executable, str(MC), "--primary", str(f.primary), "--root", str(f.tmp / "no-roots"), "--prs", "3"],
                   capture_output=True, text=True, env=env)
line = next((l.split("--prs ", 1)[1].strip() for l in (r.stdout + r.stderr).splitlines() if "Pinned for --execute: --prs" in l), "")
print(f"# 10a. dry run --prs 3 printed: --prs {line}")
merge_cleanup_sel.unlink(missing_ok=True)
rc = cli("10. execute the printed N@sha line with no dry-run record", "--prs", line, "--execute")
results["inline_pin_line_lands_without_record"] = bool(line) and rc in (0, 4) and states()["3"] == "MERGED"
print(json.dumps(results, indent=1))
f.doCleanups()
sys.exit(0 if all(results.values()) else 1)
