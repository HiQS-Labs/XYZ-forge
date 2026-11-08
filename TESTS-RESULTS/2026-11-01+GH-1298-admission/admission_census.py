#!/usr/bin/env python3
"""GH-1298 step 1: admission census over every open issue. Read-only measurement, not a test suite (GH-831).

Reuses the marathon planner's own admission states (the #1251 fail-closed slice) over the live ledger and GitHub
state, adds open-PR and delivered-by-merged-PR exclusions, then runs the live preflight dry run on each
planner-ready issue. Run from the root of a disposable full clone at the ref under test:

    PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-11-01+GH-1298-admission/admission_census.py

Writes census.json, preflight-<n>.json and census-summary.json beside this file. Needs `gh` (read-only).
"""
import collections
import json
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "utils" / "py"))
import harness  # noqa: E402
import wave_reconcile  # noqa: E402


def run(argv, **kw):
    return subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=kw.pop("timeout", 300), **kw)


def gh_json(argv):
    p = run(argv)
    if p.returncode != 0:
        raise SystemExit(f"{' '.join(argv)} failed: {p.stderr[-200:]}")
    return json.loads(p.stdout)


def main() -> int:
    backlog = Path(tempfile.mkdtemp(prefix="adm-backlog-"))
    src = sqlite3.connect(f"file:{ROOT / 'releases.db'}?mode=ro", uri=True)
    dst = sqlite3.connect(backlog / "releases.db")
    src.backup(dst)
    dst.close()
    (backlog / "branches.txt").write_text(run(["git", "branch", "-a", "--format=%(refname:short)"]).stdout)
    (backlog / "base-files.txt").write_text(run(["git", "ls-tree", "-r", "--name-only", "HEAD"]).stdout)
    states = {str(d["number"]): d["state"] for d in gh_json(["gh", "issue", "list", "--state", "all", "--limit", "3000", "--json", "number,state"])}
    (backlog / "gh-state.json").write_text(json.dumps(states))
    opens = sorted(int(n) for n, s in states.items() if s == "OPEN")
    computed = harness._planner(backlog, "stub").compute()
    rec = {r["gh"]: r for r in computed["deduped"] if r["gh"] is not None}
    slug = wave_reconcile.github_slug_from_origin(str(ROOT))
    in_pr, delivered = collections.defaultdict(list), collections.defaultdict(list)
    for pr in gh_json(["gh", "pr", "list", "--state", "open", "--limit", "300", "--json", "number,title,body"]):
        for n in wave_reconcile.extract_linked_issues(pr, slug)[0]:
            in_pr[str(n)].append(pr["number"])
    # limit 300 is the same window the harness freezes at init; older merged PRs are not seen (a stated limit)
    for pr in gh_json(["gh", "pr", "list", "--state", "merged", "--limit", "300", "--json", "number,title,body"]):
        for n in wave_reconcile.extract_linked_issues(pr, slug)[0]:
            if states.get(str(n)) == "OPEN":
                delivered[str(n)].append(pr["number"])
    census = []
    for n in opens:
        r = rec.get(n)
        census.append({"issue": n, "stage": r["state"] if r else "no-ledger-row", "doc": (r or {}).get("docRel"),
                       "open_pr": in_pr.get(str(n), []), "delivered_by": delivered.get(str(n), [])})
    for o in census:
        if o["stage"] != "ready":
            continue
        p = run(["utils/swarm-preflight.sh", "--project-doc", o["doc"], "--dry-run", "--format", "json"], timeout=600)
        (HERE / f"preflight-{o['issue']}.json").write_text(p.stdout)
        # exit contract (swarm-preflight.sh): 0 ready, 3 contract missing/invalid, 4 stale/already-landed, 7 bundle disagreement
        o["preflight_rc"] = p.returncode
    for o in census:
        o["admissible"] = o["stage"] == "ready" and o.get("preflight_rc") == 0 and not o["open_pr"] and not o["delivered_by"]
    (HERE / "census.json").write_text(json.dumps(census, indent=1) + "\n")
    summary = {"head": run(["git", "rev-parse", "HEAD"]).stdout.strip(), "open_issues": len(census),
               "by_stage": dict(collections.Counter(o["stage"] for o in census)),
               "preflight_rc": dict(collections.Counter(str(o["preflight_rc"]) for o in census if "preflight_rc" in o)),
               "admissible": [o["issue"] for o in census if o["admissible"]],
               "ready_but_excluded": [{"issue": o["issue"], "open_pr": o["open_pr"], "delivered_by": o["delivered_by"], "preflight_rc": o.get("preflight_rc")}
                                      for o in census if o["stage"] == "ready" and not o["admissible"]]}
    (HERE / "census-summary.json").write_text(json.dumps(summary, indent=1) + "\n")
    print(json.dumps(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
