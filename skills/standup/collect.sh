#!/usr/bin/env python3
import json
import os
import sys
import subprocess
import re

def cmd_output(args, cwd=None):
    try:
        p = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return p.returncode, p.stdout, p.stderr
    except FileNotFoundError:
        return 127, "", "command not found"

def read_fixture(fixture_dir, name):
    path = os.path.join(fixture_dir, name)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as fh:
            return fh.read()
    return None

def main():
    args = sys.argv[1:]
    fixture_dir = None
    if "--fixture" in args:
        idx = args.index("--fixture")
        fixture_dir = args[idx+1]

    result = {
        "repo": {"branch": "unknown"},
        "lenses": {
            "2": {"status": "ok", "degraded_id": None, "candidates": []},
            "3": {"status": "ok", "degraded_id": None, "candidates": []},
            "7": {"status": "ok", "degraded_id": None, "candidates": []}
        }
    }

    branch_name = "development"
    if fixture_dir:
        b = read_fixture(fixture_dir, "branch")
        if b is not None:
            branch_name = b.strip()
    else:
        rc, out, err = cmd_output(["git", "symbolic-ref", "--short", "HEAD"])
        if rc == 0:
            branch_name = out.strip()
    result["repo"]["branch"] = branch_name

    # LENS 2
    def run_lens_2():
        candidates = []
        if fixture_dir:
            out = read_fixture(fixture_dir, "git-status")
            if out is None:
                return "degraded", "D5", []
        else:
            rc, out, err = cmd_output(["git", "status", "--porcelain"])
            if rc != 0:
                return "degraded", "D5", []

        for line in out.splitlines():
            if len(line) < 4:
                continue
            st = line[:2]
            path = line[3:]
            if st == "??" and path.startswith("PARKED/"):
                continue
            candidates.append({
                "key": "wt:" + path,
                "what": "commit or stash " + os.path.basename(path),
                "evidence_type": "wt",
                "evidence_payload": path,
                "staleness": 0,
                "live_state": line,
                "close": "git add " + path,
                "close_kind": "command"
            })
        return "ok", None, candidates

    status2, d_id2, cands2 = run_lens_2()
    result["lenses"]["2"] = {"status": status2, "degraded_id": d_id2, "candidates": cands2}

    # LENS 3
    def run_lens_3():
        candidates = []
        if fixture_dir:
            out = read_fixture(fixture_dir, "git-rev-list")
            if out is None:
                return "degraded", "D5", []
            no_upstream = (read_fixture(fixture_dir, "git-rev-list-no-upstream") is not None)
        else:
            rc, out, err = cmd_output(["git", "rev-list", "--left-right", "--count", "@{upstream}...HEAD"])
            no_upstream = False
            if rc == 128:
                rc, out, err = cmd_output(["git", "rev-list", "--left-right", "--count", "main...HEAD"])
                no_upstream = True
            if rc != 0:
                return "degraded", "D5", []

        parts = out.strip().split()
        if len(parts) >= 2:
            try:
                behind = int(parts[0])
                ahead = int(parts[1])
            except ValueError:
                return "ok", None, candidates
            
            if behind > 0 or ahead > 0:
                c = {
                    "key": "branch:" + branch_name,
                    "what": "push or rebase branch",
                    "evidence_type": "branch",
                    "evidence_payload": branch_name + f"+{ahead}-{behind}",
                    "staleness": None if no_upstream else 0,
                    "live_state": f"ahead {ahead}, behind {behind}",
                    "close": "inspect: push state" if no_upstream else "git push",
                    "close_kind": "inspect" if no_upstream else "command",
                    "ahead": ahead,
                    "behind": behind,
                    "upstream_state": "no-upstream" if no_upstream else "tracked",
                    "clean_tree": True
                }
                candidates.append(c)
        return "ok", None, candidates

    status3, d_id3, cands3 = run_lens_3()
    if cands3:
        cands3[0]["clean_tree"] = (len(cands2) == 0)
    result["lenses"]["3"] = {"status": status3, "degraded_id": d_id3, "candidates": cands3}

    # LENS 7
    def run_lens_7():
        candidates = []
        if fixture_dir:
            out = read_fixture(fixture_dir, "roadmap-sync")
            if out is None:
                return "degraded", "D4", []
        else:
            if not os.path.exists("ROADMAP.md"):
                return "degraded", "D4", []
            rc, out, err = cmd_output(["python3", "utils/py/releases_app.py", "roadmap", "sync", "--dry-run"])
            if rc != 0:
                return "degraded", "D4", []

        lines = out.splitlines()
        idx = 1
        for line in lines:
            if line.startswith("  + ") or line.startswith("  ~ ") or line.startswith("  - "):
                what = line.strip()
                candidates.append({
                    "key": f"roadmap:sync:{idx}",
                    "what": "sync roadmap items",
                    "evidence_type": "roadmap",
                    "evidence_payload": what,
                    "staleness": 0,
                    "live_state": what,
                    "close": "python3 utils/py/releases_app.py roadmap sync",
                    "close_kind": "command"
                })
                idx += 1
        
        return "ok", None, candidates

    status7, d_id7, cands7 = run_lens_7()
    result["lenses"]["7"] = {"status": status7, "degraded_id": d_id7, "candidates": cands7}

    print(json.dumps(result))

if __name__ == "__main__":
    main()
