#!/usr/bin/env python3
"""GH-1662 manual check driver (not a test suite; GH-831). Python 3.9 compatible.

Runs the acceptance rows A1-A12 and A14 of PROJECT/2-WORKING/GH-1662-MERGE-CLEANUP-STANDALONE.md against
the foreign-repo fixture (fixture/build_fixture.py + the stand-in fixture/fakegh.py), with a fresh HOME per
fixture, and writes one provenance row per check plus the path-normalised outputs under runs/.

  BASE_SCRIPTS   merge-cleanup/scripts of the base revision (git archive of origin/development)
  CAND_SCRIPTS   merge-cleanup/scripts of the candidate
  WORK           scratch directory for fixtures and mutants (created, wiped per fixture)
  PY313          a Python 3.13 interpreter (the test venv)
  REV_BASE REV_CAND   revisions recorded in provenance
  ONLY           optional comma list of row ids to run (default all)

The stand-in `gh` cannot exercise real GitHub (checks, protection, a real merge queue, rate limits).
"""
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BASE, CAND = os.environ["BASE_SCRIPTS"], os.environ["CAND_SCRIPTS"]
WORK = os.environ["WORK"]
PY39 = os.environ.get("PY39", sys.executable)
PY313 = os.environ["PY313"]
REV_BASE, REV_CAND = os.environ["REV_BASE"], os.environ["REV_CAND"]
ONLY = [x for x in os.environ.get("ONLY", "").split(",") if x]
RUNS = os.path.join(HERE, "runs")
PROV = os.path.join(HERE, "provenance.jsonl")
os.makedirs(RUNS, exist_ok=True)
os.makedirs(WORK, exist_ok=True)
REAL_GIT = shutil.which("git")

CLEAN = "101,109,106,107"
MIXED = "101,102,103,104,105,106,107,109,110,111,112,113,114,115,116,117"
NOSTACK = "101,102,103,104,105,109,110,111,112,113,114,115,116,117"
results = []


def want(ac):
    return not ONLY or ac in ONLY


def build(name, installer=False):
    d = os.path.join(WORK, name)
    cmd = [sys.executable, os.path.join(HERE, "fixture", "build_fixture.py"), d] + (["--with-installer"] if installer else [])
    subprocess.run(cmd, check=True, capture_output=True)
    return d


def norm(text, fx):
    text = text.replace(fx, "<FX>").replace(WORK, "<WORK>").replace(os.path.expanduser("~"), "<HOME>")
    text = re.sub(r"/(?:private/)?var/folders/[A-Za-z0-9_/]*?/T/", "<TMP>/", text)
    text = re.sub(r"merge-cleanup-[a-z0-9_]{8}", "merge-cleanup-XXXX", text)
    text = re.sub(r"(pr-\d+-[0-9a-f]+-)[a-z0-9_]{8}", r"\1XXXX", text)
    return text


def run(fx, label, scripts, args, py=None, root=True, env=None, merge=False, integ="main", stamp=False):
    """Run merge_cleanup.py; returns (rc, stdout, stderr, stamps). Stdout/stderr saved normalised under runs/."""
    cmd = [py or PY39, os.path.join(scripts, "merge_cleanup.py"), "--primary", os.path.join(fx, "primary"),
           "--integration-branch", integ] + (["--root", os.path.join(fx, "home")] if root else []) + list(args)
    e = dict(os.environ, HOME=os.path.join(fx, "home"), FIXTURE_DIR=fx,
             MERGE_CLEANUP_GH_BIN=os.path.join(fx, "bin", "gh"), FAKEGH_LOG=os.path.join(fx, "gh.log"),
             PATH=os.path.join(fx, "bin") + os.pathsep + os.environ["PATH"])
    e.update(env or {})
    for k in ("XYZ_ATTEMPT_CONTEXT",):
        e.pop(k, None)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT if merge else subprocess.PIPE,
                            env=e, text=True)
    stamps = []
    out_lines = []

    def pump():
        for line in proc.stdout:
            stamps.append((time.time_ns(), line))
            out_lines.append(line)
    t = threading.Thread(target=pump)
    t.start()
    err = proc.stderr.read() if not merge else ""
    t.join()
    rc = proc.wait()
    out = "".join(out_lines)
    for suffix, text in ((".out", out), (".err", err)):
        if text or suffix == ".out":
            with open(os.path.join(RUNS, label + suffix), "w") as fh:
                fh.write(norm(text, fx))
    with open(os.path.join(RUNS, label + ".rc"), "w") as fh:
        fh.write("%d\n" % rc)
    return rc, out, err, stamps


def rec(ac, title, command, rc, passed, snippet, rev, notes=""):
    row = {"ac": ac, "title": title, "command": command, "exit_code": rc, "passed": bool(passed),
           "output_snippet": snippet[:600], "notes": notes, "revision": rev,
           "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    with open(PROV, "a") as fh:
        fh.write(json.dumps(row) + "\n")
    results.append((ac, bool(passed)))
    print("%-8s %s  %s" % (ac, "PASS" if passed else "FAIL", title))


def patched(name, rel, old, new):
    """A mutant copy of the candidate scripts with one exact replacement."""
    d = os.path.join(WORK, name)
    shutil.rmtree(d, ignore_errors=True)
    shutil.copytree(CAND, d, ignore=shutil.ignore_patterns("__pycache__"))
    p = os.path.join(d, rel)
    s = open(p).read()
    assert s.count(old) == 1, (name, s.count(old))
    open(p, "w").write(s.replace(old, new))
    return d


def lines(text, needle):
    return [l for l in text.splitlines() if needle in l]


def git(fx, *a):
    return subprocess.run([REAL_GIT, "-C", os.path.join(fx, "primary")] + list(a), capture_output=True, text=True).stdout.strip()


def seq(text):
    return [int(m.group(1)) for m in re.finditer(r"^\| \d+ \| \[#(\d+)\]", text, re.M)]


cmd_s = "merge_cleanup.py --primary <FX>/primary --integration-branch main"

# A1 ---------------------------------------------------------------------------------------------------------
if want("A1"):
    fb, fc = build("a1b"), build("a1c")
    rb, ob, eb, _ = run(fb, "A1-base-forge", BASE, ["--prs", NOSTACK])
    rc_, oc, ec, _ = run(fc, "A1-cand-forge", CAND, ["--prs", NOSTACK])
    nb, nc = norm(ob, fb), norm(oc, fc)
    extra = [l for l in norm(ec, fc).splitlines() if l not in norm(eb, fb).splitlines()]
    ok = rb == rc_ == 2 and nb == nc and "gate wiring failed" in ob and all("PRE-FLIGHT:" in l for l in extra) and len(extra) >= 2
    rec("A1", "Forge regression: no flag, fixture without installer, queue without a stack; base and candidate stdout identical, same refusal",
        cmd_s + " --prs " + NOSTACK, rc_, ok,
        "base rc %d, candidate rc %d; stdout identical=%s; stderr-only differences=%d (all PRE-FLIGHT lines): %s" % (rb, rc_, nb == nc, len(extra), extra[:1]),
        REV_CAND, "base output: runs/A1-base-forge.out, candidate: runs/A1-cand-forge.out")

# A2 / A14 ---------------------------------------------------------------------------------------------------
if want("A2"):
    f1, f2 = build("a2"), build("a2b")
    r1, o1, e1, _ = run(f1, "A2-cand-standalone-clean-dry-py39", CAND, ["--standalone", "--prs", CLEAN])
    glog = open(os.path.join(f1, "gh.log")).read()
    r2, o2, e2, _ = run(f2, "A2-cand-standalone-clean-dry-py313", CAND, ["--standalone", "--prs", CLEAN], py=PY313)
    key = lambda o: [l for l in o.splitlines() if re.match(r"^\| \d+ \| \[#", l) or "Would merge" in l or "Recommendation" in l or "retargeted" in l]
    ok = (r1 == 0 and r2 == 0 and seq(o1) == [101, 109, 106, 107] and len(lines(o1, "Would merge PR")) == 4
          and lines(o1, "retargeted to 'main'") and "pr edit" not in glog and "pr merge" not in glog
          and key(o1) == key(o2))
    rec("A2", "Standalone dry run of CLEAN (dependency + stack): rc 0, order 101,109,106,107, stacked child previewed, no mutation, identical under Python 3.9.6 and 3.13",
        cmd_s + " --standalone --prs " + CLEAN, r1, ok,
        "py3.9 rc %d, py3.13 rc %d; order %s; Would-merge x%d; retarget preview present=%s; stand-in log has pr edit/merge=%s" % (r1, r2, seq(o1), len(lines(o1, "Would merge PR")), bool(lines(o1, "retargeted to 'main'")), "pr edit" in glog or "pr merge" in glog),
        REV_CAND)
    rec("A14", "Python versions: the candidate scripts compile and give identical key lines under 3.9.6 and 3.13", "python -m py_compile <scripts>/*.py (3.9.6 and 3.13)",
        0, subprocess.run([PY39, "-m", "py_compile"] + [os.path.join(CAND, f) for f in os.listdir(CAND) if f.endswith(".py")]).returncode == 0
        and subprocess.run([PY313, "-m", "py_compile"] + [os.path.join(CAND, f) for f in os.listdir(CAND) if f.endswith(".py")]).returncode == 0 and key(o1) == key(o2),
        "py_compile ok under both; key lines equal=%s" % (key(o1) == key(o2)), REV_CAND)
    # D10 red control: the dry-run preview removed
    md = patched("mut-d10", "merge_cleanup.py", 'if dry_run and (info.get("baseRefName") or "") in landing_heads:', "if False:")
    fm = build("a2m")
    rm, om, _, _ = run(fm, "A2-mutant-no-stack-preview", md, ["--standalone", "--prs", CLEAN])
    rec("A2-mut", "Red control: without the D10 preview a dry run stops at the stacked child", cmd_s + " --standalone --prs " + CLEAN + "   (mutant)",
        rm, rm == 2 and "targets 'feat/faq', not 'main'" in om, "mutant rc %d: %s" % (rm, (lines(om, "not 'main'") or [""])[0][:200]), REV_CAND)

# A2b ---------------------------------------------------------------------------------------------------------
if want("A2b"):
    f = build("a2c")
    r, o, e, _ = run(f, "A2b-cand-standalone-mixed-dry", CAND, ["--standalone", "--prs", MIXED])
    need = ["carries hold label 'do not merge'", "PR #115: HANDOFF", "conflict set: config/settings.json", "PR #111: NOT attempted", "PR #112: NOT attempted",
            "PR #113: NOT attempted", "required checks failing (ci)", "Would merge PR #116", "4 PR(s) did not land", "Cycle or unresolved dependency detected among PRs: [111, 112, 113]"]
    allout = o + e
    miss = [n for n in need if n not in allout]
    rec("A2b", "Standalone dry run of the 16-PR MIXED queue: every draft/hold/failing/cyclic/conflicting PR is reported, none dropped; #116 previewed (dry run reports checks only)",
        cmd_s + " --standalone --prs " + MIXED, r, r == 3 and not miss and seq(o) and len(seq(o)) == 16,
        "rc %d (3 = not everything landed); table rows %d; missing expectations: %s" % (r, len(seq(o)), miss), REV_CAND,
        "draft #108 is not in --prs: a draft cannot be pinned (rc 2 if listed); see the --prs-only run")
    f = build("a2d")
    r, o, e, _ = run(f, "A2b-cand-standalone-prs-only", CAND, ["--standalone", "--prs-only"])
    rec("A2b-prs-only", "Standalone --prs-only over all 17 open PRs (draft and held included): rc 0, 17 rows, no clone, cycle named",
        cmd_s + " --standalone --prs-only", r, r == 0 and len(seq(o)) == 17 and "Cycle or unresolved dependency" in o and "clone" not in (o + e).lower().replace("clones", ""),
        "rc %d; rows %d; order %s" % (r, len(seq(o)), seq(o)), REV_CAND)
    # execute observation: failing-checks predecessor and its dependent
    f = build("a2e")
    run(f, "A2b-exec-dry", CAND, ["--standalone", "--prs", "101,109,110,116"])
    r, o, e, _ = run(f, "A2b-exec", CAND, ["--standalone", "--prs", "101,109,110,116", "--landing-plan", "direct", "--landing-reason", "manual check of blocked reporting", "--execute"])
    st = json.load(open(os.path.join(f, "ghstate.json")))
    merged = sorted(p["number"] for p in st["prs"] if p["state"] == "MERGED")
    allout = o + e
    rec("A2b-exec", "Standalone --execute: failing-checks #110 is not merged and its dependent #116 is NOT attempted; #101 and #109 land",
        cmd_s + " --standalone --prs 101,109,110,116 --landing-plan direct --landing-reason ... --execute", r,
        r == 3 and merged == [101, 109] and "required checks failing (ci) — not merged" in allout and "PR #116: NOT attempted — depends on #110" in allout,
        "rc %d; merged %s; blocked line present=%s" % (r, merged, "PR #116: NOT attempted — depends on #110" in allout), REV_CAND)

# A3 ----------------------------------------------------------------------------------------------------------
if want("A3"):
    md = patched("mut-wiring", "merge_cleanup.py", 'if standalone and not (Path(clone) / "githooks" / "install.sh").is_file():',
                 'if not (Path(clone) / "githooks" / "install.sh").is_file():')
    fm, fc = build("a3m"), build("a3c")
    rm, om, em, _ = run(fm, "A3-mutant-inferred", md, ["--prs", CLEAN])
    rc_, oc, ec, _ = run(fc, "A3-cand-noflag", CAND, ["--prs", CLEAN])
    diag = "landing clone gate wiring failed: githooks/install.sh is missing"
    rec("A3", "Red control for 'never inferred': a mutant that skips the wiring refusal without the flag loses the GH-1576 diagnostic that base and candidate print",
        cmd_s + " --prs " + CLEAN + "   (no flag; mutant vs candidate)", rm, diag not in (om + em) and diag in (oc + ec) and rc_ == 2,
        "mutant rc %d, diagnostic present=%s; candidate rc %d, diagnostic present=%s" % (rm, diag in (om + em), rc_, diag in (oc + ec)), REV_CAND,
        "the mutant's later ledger-gate failure may keep its rc at 2; the diagnostic is the assertion")

# A4 ----------------------------------------------------------------------------------------------------------
if want("A4"):
    fb, fc = build("a4b", True), build("a4c", True)
    rb, ob, eb, _ = run(fb, "A4-base-forge-installer", BASE, ["--prs", CLEAN])
    rc_, oc, ec, _ = run(fc, "A4-cand-forge-installer", CAND, ["--prs", CLEAN])
    red = "pre-merge ledger gate RED"
    rec("A4", "Forge regression with an installer present, no flag: same pre-merge ledger gate refusal at base and candidate",
        cmd_s + " --prs " + CLEAN + "   (fixture --with-installer)", rc_, rb == rc_ == 2 and red in (ob + eb) and red in (oc + ec),
        "base rc %d, candidate rc %d; RED present at both=%s" % (rb, rc_, red in (ob + eb) and red in (oc + ec)), REV_CAND)

# A5 ----------------------------------------------------------------------------------------------------------
if want("A5"):
    f = build("a5")
    run(f, "A5-dry", CAND, ["--standalone", "--prs", CLEAN], root=False)
    r, o, e, _ = run(f, "A5-exec", CAND, ["--standalone", "--prs", CLEAN, "--landing-plan", "direct", "--landing-reason", "manual check landing a stack and a dependency", "--execute"], root=False)
    st = json.load(open(os.path.join(f, "ghstate.json")))
    merged = sorted(p["number"] for p in st["prs"] if p["state"] == "MERGED")
    log = subprocess.run([REAL_GIT, "--git-dir=" + os.path.join(f, "origin.git"), "log", "--format=%an|%s", "main", "-5"], capture_output=True, text=True).stdout.splitlines()
    landed_order = [int(re.search(r"\(#(\d+)\)", l).group(1)) for l in reversed(log) if re.search(r"\(#\d+\)", l)]
    authors = set(l.split("|")[0] for l in log)
    git(f, "fetch", "origin", "main")
    equal = git(f, "rev-parse", "HEAD") == git(f, "rev-parse", "origin/main")
    clean = git(f, "status", "--porcelain") == ""
    vf = os.path.join(f, "verdict.txt")
    open(vf, "w").write("verdict: clean\nmanual check: the four landings were inspected in the fixture (see TESTS-RESULTS/2026-11-27+GH-1662)\n")
    r2, o2, e2, _ = run(f, "A5-record-sweep", CAND, ["--standalone", "--record-sweep", vf], root=False)
    rec("A5", "Standalone --execute lands the CLEAN queue (dependency then stack) in order; primary equals origin and is clean; no tool push; verdict recorded",
        cmd_s + " --standalone --prs " + CLEAN + " --landing-plan direct --landing-reason ... --execute; then --record-sweep", r,
        r == 4 and merged == [101, 106, 107, 109] and landed_order == [101, 109, 106, 107] and authors <= {"acme", "gh"} and equal and clean and r2 == 0
        and "ledger gate skipped" in (o + e) and "post-merge reconcile" in (o + e) and "retargeted open stacked PR #107" in (o + e),
        "execute rc %d (4 = batch QA pending); landed order %s; origin authors %s; primary==origin %s; primary clean %s; record-sweep rc %d" % (r, landed_order, sorted(authors), equal, clean, r2),
        REV_CAND, "stand-in gh merge: a real GitHub merge is not exercised")
    # A7 mutant lives here: same CLEAN queue, sorter edge removed
if want("A7"):
    md = patched("mut-edge", "toposort_prs.py", 'if parent is not None and parent != pr["number"]:', "if False:")
    f = build("a7")
    run(f, "A7-mutant-dry", md, ["--standalone", "--prs", CLEAN], root=False)
    r, o, e, _ = run(f, "A7-mutant-exec", md, ["--standalone", "--prs", CLEAN, "--landing-plan", "direct", "--landing-reason", "mutant control", "--execute"], root=False)
    probe = r'''
import copy, json, sys
sys.path.insert(0, sys.argv[1])
import toposort_prs as t
def pr(n, head, base, files, body="", created="1"):
    return {"number": n, "headRefName": head, "baseRefName": base, "files": [{"path": f} for f in files], "body": body, "title": "t%d" % n, "createdAt": created}
case1 = [pr(6, "p", "main", ["a"], "Depends on #9"), pr(7, "c", "p", ["b"]), pr(9, "z", "main", ["z"])]
case2 = [pr(1, "p", "main", ["x"], created="1"), pr(2, "c", "p", ["x"], created="2")]
out = {}
for name, prs in (("case1_inverted_stack", case1), ("case2_overlapping_stack", case2)):
    o, raw, w = t.toposort_prs(copy.deepcopy(prs))
    out[name] = {"order": [p["number"] for p in o], "warnings": w, "hard_soft": {p["number"]: [p["_hard_deps"], p["_soft_deps"]] for p in o}}
print(json.dumps(out))
'''
    pb = json.loads(subprocess.run([PY39, "-c", probe, BASE], capture_output=True, text=True).stdout)
    pc = json.loads(subprocess.run([PY39, "-c", probe, CAND], capture_output=True, text=True).stdout)
    with open(os.path.join(RUNS, "A7-sorter-probe.json"), "w") as fh:
        json.dump({"base": pb, "candidate": pc}, fh, indent=1)
    ok = (pb["case1_inverted_stack"]["order"] == [7, 9, 6] and pc["case1_inverted_stack"]["order"] == [9, 6, 7]
          and r == 2 and "targets 'feat/faq', not 'main'" in (o + e))
    rec("A7", "Stacked order: base sequences the child before its base (case 1: [7,9,6]); candidate [9,6,7]; the mutant with only the sorter edge removed stops the landing at the child",
        "toposort_prs probe (base vs candidate); " + cmd_s + " --standalone --prs " + CLEAN + " --execute   (mutant)", r, ok,
        "base %s; candidate %s; mutant execute rc %d: %s. Overlapping pair (F2): base warnings %s hard/soft %s; candidate warnings %s hard/soft %s" % (
            pb["case1_inverted_stack"]["order"], pc["case1_inverted_stack"]["order"], r, (lines(o + e, "not 'main'") or [""])[0][-90:],
            pb["case2_overlapping_stack"]["warnings"], pb["case2_overlapping_stack"]["hard_soft"]["2"],
            pc["case2_overlapping_stack"]["warnings"], pc["case2_overlapping_stack"]["hard_soft"]["2"]),
        REV_CAND, "the overlapping-pair change is the accepted shared semantics of D9 (the collision note is replaced by a hard edge)")

# A6 ----------------------------------------------------------------------------------------------------------
if want("A6"):
    fb = build("a6b")
    run(fb, "A6-base-run1", BASE, ["--prs", CLEAN], root=False)
    rb2, ob2, _, _ = run(fb, "A6-base-run2", BASE, ["--prs", CLEAN], root=False)
    f = build("a6")
    r1, o1, _, _ = run(f, "A6-cand-run1", CAND, ["--standalone", "--prs", CLEAN], root=False)
    r2, o2, _, _ = run(f, "A6-cand-run2", CAND, ["--standalone", "--prs", CLEAN], root=False)
    excl = open(os.path.join(f, "primary", ".git", "info", "exclude")).read().splitlines()
    clean = git(f, "status", "--porcelain") == ""
    md = patched("mut-tick", "merge_cleanup.py", '    probe = ".tick/merge-cleanup/"\n    tracked = run_git', '    return None\n    probe = ".tick/merge-cleanup/"\n    tracked = run_git')
    fm = build("a6m")
    run(fm, "A6-mutant-run1", md, ["--standalone", "--prs", CLEAN], root=False)
    rm2, om2, _, _ = run(fm, "A6-mutant-run2", md, ["--standalone", "--prs", CLEAN], root=False)
    side = r'''
import json, os, subprocess, sys, tempfile
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import merge_cleanup as mc
def sh(*a, cwd):
    subprocess.run(["git"] + list(a), cwd=cwd, check=True, capture_output=True)
res = {}
with tempfile.TemporaryDirectory() as td:
    td = Path(td)
    env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"}
    os.environ.update(env)
    # linked-worktree primary
    main = td / "main"; main.mkdir(); sh("init", "-q", cwd=main); (main / "f").write_text("x"); sh("add", "-A", cwd=main); sh("commit", "-q", "-m", "i", cwd=main)
    wt = td / "wt"; sh("worktree", "add", "-q", "-b", "wtb", str(wt), cwd=main)
    res["linked_worktree"] = {"result": mc.ensure_tick_ignored(wt), "ignored_in_worktree": subprocess.run(["git", "check-ignore", "-q", ".tick/merge-cleanup/"], cwd=wt).returncode == 0,
                              "exclude_lines": [l for l in (main / ".git" / "info" / "exclude").read_text().splitlines() if l == "/.tick/"]}
    # already ignored (bytes unchanged)
    ig = td / "ig"; ig.mkdir(); sh("init", "-q", cwd=ig); (ig / ".gitignore").write_text(".tick/\n"); sh("add", "-A", cwd=ig); sh("commit", "-q", "-m", "i", cwd=ig)
    before = (ig / ".git" / "info" / "exclude").read_bytes()
    res["already_ignored"] = {"result": mc.ensure_tick_ignored(ig), "exclude_unchanged": (ig / ".git" / "info" / "exclude").read_bytes() == before}
    # exclude file without a trailing newline keeps its bytes, gains one line
    nn = td / "nn"; nn.mkdir(); sh("init", "-q", cwd=nn); (nn / ".git" / "info" / "exclude").write_text("keep-me")
    r = mc.ensure_tick_ignored(nn)
    res["no_trailing_newline"] = {"result": r, "exclude": (nn / ".git" / "info" / "exclude").read_text()}
    # tracked record
    tr = td / "tr"; tr.mkdir(); sh("init", "-q", cwd=tr); (tr / ".tick" / "merge-cleanup").mkdir(parents=True); (tr / ".tick" / "merge-cleanup" / "x.json").write_text("{}")
    sh("add", "-f", "-A", cwd=tr); sh("commit", "-q", "-m", "i", cwd=tr)
    res["tracked"] = {"result": mc.ensure_tick_ignored(tr)}
print(json.dumps(res))
'''
    sp = subprocess.run([PY39, "-c", side, CAND], capture_output=True, text=True)
    sd = json.loads(sp.stdout) if sp.returncode == 0 else {"error": sp.stderr[-300:]}
    with open(os.path.join(RUNS, "A6-side-cases.json"), "w") as fh:
        json.dump(sd, fh, indent=1)
    side_ok = (sd.get("linked_worktree", {}).get("result") is None and sd["linked_worktree"]["ignored_in_worktree"] and sd["linked_worktree"]["exclude_lines"] == ["/.tick/"]
               and sd["already_ignored"]["result"] is None and sd["already_ignored"]["exclude_unchanged"]
               and sd["no_trailing_newline"]["exclude"] == "keep-me\n/.tick/\n" and "tracked" in (sd["tracked"]["result"] or ""))
    rec("A6", "T4: two consecutive standalone dry runs leave the primary READY and clean (base: NOT READY on run 2; mutant without ensure_tick_ignored: NOT READY on run 2); side cases per D5",
        cmd_s + " --standalone --prs " + CLEAN + "   (run twice)", r2,
        "landing: NOT READY" in ob2 and "clean: no (1 path(s))" in ob2 and r1 == 0 and r2 == 0 and "landing: READY" in o2 and clean and excl.count("/.tick/") == 1
        and "landing: NOT READY" in om2 and side_ok,
        "base run2 NOT READY=%s; candidate runs rc %d,%d READY=%s, primary clean=%s, exclude entries=%d; mutant run2 NOT READY=%s; side cases ok=%s" % (
            "landing: NOT READY" in ob2, r1, r2, "landing: READY" in o2, clean, excl.count("/.tick/"), "landing: NOT READY" in om2, side_ok), REV_CAND,
        "side cases: runs/A6-side-cases.json")

# A8 ----------------------------------------------------------------------------------------------------------
if want("A8"):
    sh_dir = os.path.join(WORK, "shims")
    shutil.rmtree(sh_dir, ignore_errors=True)
    os.makedirs(sh_dir)
    clone_log = os.path.join(sh_dir, "clones.log")
    with open(os.path.join(sh_dir, "git"), "w") as fh:
        fh.write('#!/usr/bin/env python3\nimport os, subprocess, sys, time\na = sys.argv[1:]\n'
                 'if "--version" in a:\n    print("git version 2.30.0"); sys.exit(0)\n'
                 'if "clone" in a:\n    open(%r, "a").write("%%d\\n" %% time.time_ns())\n'
                 'sys.exit(subprocess.call([%r] + a))\n' % (clone_log, REAL_GIT))
    f = build("a8")
    with open(os.path.join(sh_dir, "gh"), "w") as fh:
        fh.write('#!/bin/sh\n[ "$1" = "--version" ] && { echo "gh version 2.4.0 (shim)"; exit 0; }\nexec %s "$@"\n' % os.path.join(f, "bin", "gh"))
    for n in ("git", "gh"):
        os.chmod(os.path.join(sh_dir, n), 0o755)
    r, o, e, stamps = run(f, "A8-old-tools", CAND, ["--standalone", "--prs", CLEAN], merge=True,
                          env={"PATH": sh_dir + os.pathsep + os.environ["PATH"], "MERGE_CLEANUP_GH_BIN": os.path.join(sh_dir, "gh")})
    unmet = [t for t, l in stamps if "[UNMET]" in l]
    clones = [int(x) for x in open(clone_log).read().split()] if os.path.exists(clone_log) else []
    ok = bool(unmet) and bool(clones) and max(unmet) < min(clones) and len(lines(o, "[UNMET]")) == 2
    fo = build("a8o")
    subprocess.run([REAL_GIT, "-C", os.path.join(fo, "primary"), "remote", "remove", "origin"], check=True)
    ro, oo, eo, _ = run(fo, "A8-no-origin-execute", CAND, ["--standalone", "--prs", "101@abcdef0", "--execute"], merge=True)
    rd, od, ed, _ = run(fo, "A8-no-origin-dry", CAND, ["--standalone", "--prs-only"], merge=True)
    rec("A8", "Prerequisites: an old git and gh are reported UNMET before the run's first clone; a missing origin is UNMET in the dry run and refuses --execute (rc 2)",
        cmd_s + " --standalone --prs " + CLEAN + "   (git 2.30 and gh 2.4 shims, working origin)", r,
        ok and ro == 2 and "unmet standalone prerequisite(s): origin remote" in oo and "[UNMET] origin remote" in od,
        "UNMET lines %d, first at %s ns before first clone at %s ns (diff %s us); no-origin execute rc %d; dry run reports origin UNMET=%s" % (
            len(lines(o, "[UNMET]")), "t", "t", (min(clones) - max(unmet)) // 1000 if clones and unmet else "n/a", ro, "[UNMET] origin remote" in od), REV_CAND,
        "Python below 3.9 cannot be run on this machine: that row of the block is unverified at runtime")

# A9 ----------------------------------------------------------------------------------------------------------
if want("A9"):
    f = build("a9")
    other = os.path.join(f, "other.git")
    subprocess.run([REAL_GIT, "init", "-q", "--bare", "-b", "main", other], check=True)
    oc = os.path.join(f, "home", "marathon-clones", "other-repo")
    os.makedirs(os.path.dirname(oc))
    subprocess.run([REAL_GIT, "clone", "-q", other, oc], check=True, capture_output=True)
    ge = dict(os.environ, GIT_AUTHOR_NAME="o", GIT_AUTHOR_EMAIL="o@o", GIT_COMMITTER_NAME="o", GIT_COMMITTER_EMAIL="o@o")
    subprocess.run([REAL_GIT, "-C", oc, "checkout", "-q", "-b", "main"], check=True, capture_output=True)
    open(os.path.join(oc, "f"), "w").write("x")
    subprocess.run([REAL_GIT, "-C", oc, "add", "-A"], check=True, env=ge)
    subprocess.run([REAL_GIT, "-C", oc, "commit", "-q", "-m", "i"], check=True, env=ge, capture_output=True)
    subprocess.run([REAL_GIT, "-C", oc, "push", "-q", "-u", "origin", "main"], check=True, capture_output=True)
    rf, of, _, _ = run(f, "A9-forge-default-roots", CAND, ["--scan-only"], root=False)
    rs, os_, _, _ = run(f, "A9-standalone-default-roots", CAND, ["--standalone", "--scan-only"], root=False)
    rx, ox, _, _ = run(f, "A9-standalone-explicit-root", CAND, ["--standalone", "--scan-only", "--root", os.path.join(f, "home", "marathon-clones")], root=False)
    rec("A9", "Scan roots: Forge mode lists a clean clone of ANOTHER repository under a default safe root; standalone (no --root) does not; an explicit --root is the operator's choice in both",
        cmd_s + " [--standalone] --scan-only   (fresh HOME holding marathon-clones/other-repo)", rs,
        "other-repo" in of and "other-repo" not in os_ and "other-repo" in ox and rf == rs == rx == 0,
        "forge lists other-repo=%s; standalone lists it=%s; standalone with --root lists it=%s" % ("other-repo" in of, "other-repo" in os_, "other-repo" in ox), REV_CAND,
        "Forge-mode default roots are unchanged by design")

# A10 ---------------------------------------------------------------------------------------------------------
if want("A10"):
    f = build("a10")
    open(os.path.join(f, "primary", "releases.sql"), "w").write("-- a ledger\n")
    r, o, e, _ = run(f, "A10-overlay-guard", CAND, ["--standalone", "--prs", CLEAN], merge=True)
    rec("A10", "Overlay guard: --standalone is refused when the primary has a ledger file", cmd_s + " --standalone --prs " + CLEAN + "   (primary holds releases.sql)", r,
        r == 2 and "REFUSING --standalone" in o and "releases.sql" in o and "PHASE 0" not in o, "rc %d: %s" % (r, (lines(o, "REFUSING")[0] if lines(o, "REFUSING") else "")[:200]), REV_CAND)

# A11 ---------------------------------------------------------------------------------------------------------
if want("A11"):
    ff, fs = build("a11f"), build("a11s")
    rf, of, ef, _ = run(ff, "A11-forge-forecast", CAND, ["--prs", "101,109,117"])
    rs, os_, es, _ = run(fs, "A11-standalone-forecast", CAND, ["--standalone", "--prs", "101,109,117"])
    rowf = [l for l in of.splitlines() if l.startswith("| #117 ")]
    rows = [l for l in os_.splitlines() if l.startswith("| #117 ")]
    rec("A11", "Forecast labelling (M4): a CHANGELOG.md conflict reads 'potentially B1-eligible' + direct in Forge mode, 'needs review' + group + hand-off wording in standalone",
        cmd_s + " [--standalone] --prs 101,109,117", rs,
        rowf and rows and "CHANGELOG.md" in rowf[0].split("|")[4] and "CHANGELOG.md" in rows[0].split("|")[5] and "Recommendation: direct" in of and "Recommendation: group" in os_
        and "handed off, no automatic repair" in os_ and "needs a B1 repair" not in os_ and "standalone mode: there is no B1" in os_,
        "forge row %s ; standalone row %s ; forge %s ; standalone %s" % (rowf[:1], rows[:1], (lines(of, "Recommendation:") or [""])[0][:90], (lines(os_, "Recommendation:") or [""])[0][:90]), REV_CAND)

# A12 ---------------------------------------------------------------------------------------------------------
if want("A12"):
    f = build("a12")
    c = os.path.join(f, "gate-check")
    subprocess.run([REAL_GIT, "clone", "-q", os.path.join(f, "origin.git"), c], check=True, capture_output=True)
    open(os.path.join(c, "dirty.txt"), "w").write("post-merge write\n")
    before = subprocess.run([REAL_GIT, "--git-dir=" + os.path.join(f, "origin.git"), "rev-parse", "main"], capture_output=True, text=True).stdout.strip()
    snippet = r'''
import json, os, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import merge_cleanup as mc
repo = Path(sys.argv[2])
import subprocess
subprocess.run(["git", "-C", str(repo), "config", "user.email", "t@t"]); subprocess.run(["git", "-C", str(repo), "config", "user.name", "t"])
reason = mc.gate_unwired_reason(repo)
ok = mc.commit_and_push_phase5_writes(0, repo, "main", commit_msg="post-merge write")
print(json.dumps({"gate_unwired_reason": reason, "commit_and_push_returned": ok}))
'''
    p = subprocess.run([PY39, "-c", snippet, CAND, c], capture_output=True, text=True, env=dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@t"))
    after = subprocess.run([REAL_GIT, "--git-dir=" + os.path.join(f, "origin.git"), "rev-parse", "main"], capture_output=True, text=True).stdout.strip()
    got = json.loads(p.stdout.strip().splitlines()[-1]) if p.stdout.strip() else {}
    with open(os.path.join(RUNS, "A12.json"), "w") as fh:
        json.dump({"result": got, "stderr": norm(p.stderr, f)}, fh, indent=1)
    rec("A12", "Pushes stay gated: with an identity and a working origin, a dirty foreign checkout's post-merge push is refused with the GH-1576 text and origin does not move",
        "gate_unwired_reason(clone); commit_and_push_phase5_writes(0, clone, 'main')   (candidate scripts, no githooks/install.sh)", p.returncode,
        "githooks/install.sh is missing" in got.get("gate_unwired_reason", "") and got.get("commit_and_push_returned") is False
        and "refusing to push post-merge writes" in p.stderr and before == after,
        "gate: %s; push returned %s; origin tip unchanged=%s" % (got.get("gate_unwired_reason", "")[:110], got.get("commit_and_push_returned"), before == after), REV_CAND)

bad = [a for a, ok in results if not ok]
print("\nrows: %d, failed: %s" % (len(results), bad or "none"))
sys.exit(1 if bad else 0)
