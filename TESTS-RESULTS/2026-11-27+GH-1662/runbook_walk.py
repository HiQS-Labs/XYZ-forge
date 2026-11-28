#!/usr/bin/env python3
"""GH-1662 row A15: walk the STANDALONE.md prose runbook on the fixture and compare it with the script.

It uses ONLY what the runbook tells an agent to do: the `gh pr list --json ...` inventory command, the hard and
soft edge rules, the lowest-number-first order with a cycle appended, and the `git merge-tree --write-tree`
alone / pair / fold commands in a no-checkout clone. It then compares the order with the script's Phase 4 table
(runs/A2b-cand-standalone-prs-only.out) and the conflicting pairs and fold stop with the script's forecast
(runs/A2b-cand-standalone-mixed-dry.out). The author of the script and of the runbook is the same, so this finds
prose/script drift; it is not independent review. Python 3.9 compatible.

  WORK  scratch dir (a fresh fixture is built under it)    REV_CAND  revision recorded in provenance
"""
import itertools
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
WORK, REV = os.environ["WORK"], os.environ["REV_CAND"]
RUNS = os.path.join(HERE, "runs")
GIT = shutil.which("git")
fx = os.path.join(WORK, "a15", "fx")
subprocess.run([sys.executable, os.path.join(HERE, "fixture", "build_fixture.py"), fx], check=True, capture_output=True)
env = dict(os.environ, FIXTURE_DIR=fx)

# 1. Inventory (the runbook's command)
inv = subprocess.run([os.path.join(fx, "bin", "gh"), "pr", "list", "--state", "open", "--limit", "1000", "--json",
                      "number,title,headRefName,headRefOid,baseRefName,isDraft,labels,mergeable,statusCheckRollup,body,files,createdAt,url"],
                     capture_output=True, text=True, env=env, check=True).stdout
prs = {p["number"]: p for p in json.loads(inv)}
files = {n: set(f["path"] for f in p["files"]) for n, p in prs.items()}

# 3. hard edges (runbook step 3)
hard = {n: set() for n in prs}
pat = re.compile(r"(?:depends\s+on|blocked\s+by|after|requires|prerequisite:?)\s+(?:https://github\.com/[^/]+/[^/]+/pull/|#)(\d+)|part\s+of\s+wave\s+after\s+#(\d+)", re.I)
for n, p in prs.items():
    for m in pat.finditer((p["title"] or "") + "\n" + (p["body"] or "")):
        d = int(m.group(1) or m.group(2))
        if d in prs:
            hard[n].add(d)
heads = {p["headRefName"]: n for n, p in prs.items()}
for n, p in prs.items():
    parent = heads.get(p["baseRefName"])
    if parent is not None and parent != n:
        hard[n].add(parent)

# 4. soft edges: shared file, no hard edge between the pair, older first, skip if it would close a cycle
edges = {n: set(h) for n, h in hard.items()}
def reaches(src, dst):
    todo, seen = [src], set()
    while todo:
        x = todo.pop()
        if x == dst:
            return True
        if x in seen:
            continue
        seen.add(x)
        todo.extend(edges[x])
    return False
for a, b in itertools.combinations(sorted(prs), 2):
    if files[a] & files[b] and b not in edges[a] and a not in edges[b]:
        first, second = (a, b) if prs[a]["createdAt"] <= prs[b]["createdAt"] else (b, a)
        if not reaches(first, second):  # an edge second -> first would close a cycle iff first already waits for second
            edges[second].add(first)

# 5. order: repeatedly the lowest-numbered PR with no unmet incoming edge; a remaining cycle is appended ascending
left, order = set(prs), []
while left:
    ready = sorted(n for n in left if not (edges[n] & left))
    if not ready:
        order += sorted(left)
        break
    order.append(ready[0])
    left.discard(ready[0])

script_table = open(os.path.join(RUNS, "A2b-cand-standalone-prs-only.out")).read()
script_order = [int(m.group(1)) for m in re.finditer(r"^\| \d+ \| \[#(\d+)\]", script_table, re.M)]

# 6. forecast with the runbook's git commands (no checkout), over the MIXED listing
listed = [int(x) for x in "101,102,103,104,105,106,107,109,110,111,112,113,114,115,116,117".split(",")]
lorder = [n for n in order if n in listed]
td = tempfile.mkdtemp(prefix="runbook-walk-", dir=WORK)
f = os.path.join(td, "f")
def g(*a, cwd=None, check=True):
    return subprocess.run([GIT] + list(a), cwd=cwd or f, capture_output=True, text=True, check=check)
subprocess.run([GIT, "clone", "--quiet", "--no-checkout", os.path.join(fx, "origin.git"), f], check=True, capture_output=True)
g("fetch", "--quiet", "origin", "main")
base = g("rev-parse", "origin/main").stdout.strip()
for n in listed:
    g("fetch", "--quiet", "origin", "+pull/%d/head:refs/forecast/%d" % (n, n))
def mt(a, b):
    r = g("merge-tree", "--write-tree", "--name-only", "--no-messages", a, b, check=False)
    ls = r.stdout.split("\n")
    paths = []
    for l in ls[1:]:
        if not l.strip():
            break
        paths.append(l.strip())
    return r.returncode, ls[0].strip(), paths
alone = {n: mt(base, "refs/forecast/%d" % n)[0] for n in listed}
pairs = {}
for a, b in itertools.combinations(listed, 2):
    rc, _, paths = mt("refs/forecast/%d" % a, "refs/forecast/%d" % b)
    if rc == 1:
        pairs[(a, b)] = sorted(paths)
cur, stop = base, None
for n in lorder:
    rc, tree, paths = mt(cur, "refs/forecast/%d" % n)
    if rc == 0:
        cur = g("-c", "user.name=fold", "-c", "user.email=fold@local", "commit-tree", tree, "-p", cur, "-p", "refs/forecast/%d" % n, "-m", "fold").stdout.strip()
    else:
        stop = n
        break

script_fc = open(os.path.join(RUNS, "A2b-cand-standalone-mixed-dry.out")).read()
script_pairs = {}
for m in re.finditer(r"^Members #(\d+) and #(\d+) conflict with each other on: (.*)$", script_fc, re.M):
    script_pairs[(int(m.group(1)), int(m.group(2)))] = sorted(x.strip() for x in m.group(3).split(","))
norm_pairs = {tuple(sorted(k)): v for k, v in pairs.items()}
norm_script = {tuple(sorted(k)): v for k, v in script_pairs.items()}
script_fold = re.search(r"^\| #(\d+) \| clean \| conflict \|", script_fc, re.M)
script_fold_stop = int(script_fold.group(1)) if script_fold else None
alone_conf = sorted(n for n, rc in alone.items() if rc == 1)
script_alone = sorted(int(m.group(1)) for m in re.finditer(r"^\| #(\d+) \| conflict \|", script_fc, re.M))

out = {"runbook_order": order, "script_order": script_order, "order_equal": order == script_order,
       "runbook_pairs": {"%d-%d" % k: v for k, v in sorted(norm_pairs.items())}, "pairs_equal": norm_pairs == norm_script,
       "runbook_fold_stop": stop, "script_fold_stop": script_fold_stop, "runbook_alone_conflicts": alone_conf, "script_alone_conflicts": script_alone}
with open(os.path.join(RUNS, "A15-runbook-walk.json"), "w") as fh:
    json.dump(out, fh, indent=1)
ok = out["order_equal"] and out["pairs_equal"] and stop == script_fold_stop and alone_conf == script_alone
row = {"ac": "A15", "title": "Runbook honesty: the prose runbook's inventory, edge rules, order and merge-tree commands reproduce the script's order, conflict pairs, alone-conflicts and fold stop on the fixture",
       "command": "python3 runbook_walk.py (gh pr list ...; git merge-tree --write-tree alone/pair/fold in a no-checkout clone)", "exit_code": 0 if ok else 1, "passed": ok,
       "output_snippet": ("order equal=%s (%s); pairs equal=%s (%d pairs); fold stop %s vs %s; alone conflicts %s vs %s" % (
           out["order_equal"], order, out["pairs_equal"], len(norm_pairs), stop, script_fold_stop, alone_conf, script_alone))[:600],
       "notes": "same author as the script and the runbook: finds prose/script drift, is not independent review", "revision": REV,
       "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
with open(os.path.join(HERE, "provenance.jsonl"), "a") as fh:
    fh.write(json.dumps(row) + "\n")
print("A15", "PASS" if ok else "FAIL", row["output_snippet"])
shutil.rmtree(td, ignore_errors=True)
sys.exit(0 if ok else 1)
