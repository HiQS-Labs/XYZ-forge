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
results = []


def want(ac):
    return not ONLY or ac in ONLY


def build(name, installer=False, stack=True, forks=False):
    d = os.path.join(WORK, name, "fx")  # same last path components everywhere, so the pin file's repo slug is identical
    cmd = [sys.executable, os.path.join(HERE, "fixture", "build_fixture.py"), d] + (["--with-installer"] if installer else []) + ([] if stack else ["--no-stack"]) + (["--with-forks"] if forks else [])
    subprocess.run(cmd, check=True, capture_output=True)
    return d


def norm(text, fx):
    text = text.replace(fx, "<FX>").replace(WORK, "<WORK>").replace(os.path.expanduser("~"), "<HOME>")
    text = re.sub(r"/(?:private/)?var/folders/[A-Za-z0-9_/]*?/T/?", "<TMP>/", text)
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
        if suffix == ".err" and merge:  # stderr was merged into stdout: no .err belongs to this invocation
            if os.path.exists(os.path.join(RUNS, label + suffix)):
                os.remove(os.path.join(RUNS, label + suffix))
            continue
        with open(os.path.join(RUNS, label + suffix), "w") as fh:  # always rewritten, even when empty
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
    fb, fc = build("a1b", stack=False), build("a1c", stack=False)
    rb, ob, eb, _ = run(fb, "A1-base-forge", BASE, ["--prs", MIXED])
    rc_, oc, ec, _ = run(fc, "A1-cand-forge", CAND, ["--prs", MIXED])
    nb, nc = norm(ob, fb), norm(oc, fc)
    extra = [l for l in norm(ec, fc).splitlines() if l not in norm(eb, fb).splitlines()]
    ok = rb == rc_ == 2 and nb == nc and "gate wiring failed" in (ob + eb) and "gate wiring failed" in (oc + ec) and all("PRE-FLIGHT:" in l for l in extra) and len(extra) >= 2
    rec("A1", "Forge regression: no flag, fixture without installer, queue with no stacked PR (--no-stack); base and candidate stdout identical, same refusal",
        cmd_s + " --prs " + MIXED + "   (fixture --no-stack)", rc_, ok,
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
    rm, om, em, _ = run(fm, "A2-mutant-no-stack-preview", md, ["--standalone", "--prs", CLEAN])
    rec("A2-mut", "Red control: without the D10 preview a dry run stops at the stacked child", cmd_s + " --standalone --prs " + CLEAN + "   (mutant)",
        rm, rm == 2 and "targets 'feat/faq', not 'main'" in (om + em), "mutant rc %d: %s" % (rm, (lines(om + em, "not 'main'") or [""])[0][:200]), REV_CAND)

# A2b ---------------------------------------------------------------------------------------------------------
if want("A2b"):
    f = build("a2c")
    r, o, e, _ = run(f, "A2b-cand-standalone-mixed-dry", CAND, ["--standalone", "--prs", MIXED])
    need = ["carries hold label 'do not merge'", "PR #115: HANDOFF", "conflict set: config/settings.json", "PR #111: NOT attempted", "PR #112: NOT attempted",
            "PR #113: NOT attempted", "required checks failing (ci)", "PR #116: would NOT land in this run \u2014 depends on #110", "4 PR(s) did not land", "Cycle or unresolved dependency detected among PRs: [111, 112, 113]"]
    allout = o + e
    miss = [n for n in need if n not in allout] + [n for n in ("Would merge PR #110", "Would merge PR #116") if n in allout]
    rec("A2b", "Standalone dry run of the 16-PR MIXED queue: every draft/hold/failing/cyclic/conflicting PR is reported, none dropped; failing-checks #110 and its hard dependent #116 are forecast as not landing, matching --execute (review F7)",
        cmd_s + " --standalone --prs " + MIXED, r, r == 3 and not miss and seq(o) and len(seq(o)) == 16,
        "rc %d (3 = not everything landed); table rows %d; missing expectations: %s" % (r, len(seq(o)), miss), REV_CAND,
        "draft #108 is not in --prs: a draft cannot be pinned (rc 2 if listed); see the --prs-only run")
    f = build("a2d")
    rd = os.path.join(WORK, "shims-rec")
    shutil.rmtree(rd, ignore_errors=True)
    os.makedirs(rd)
    rlog = os.path.join(rd, "clones.log")
    with open(os.path.join(rd, "git"), "w") as fh:
        fh.write('#!/usr/bin/env python3\nimport subprocess, sys\na = sys.argv[1:]\n'
                 'if "clone" in a:\n    open(%r, "a").write("clone\\n")\nsys.exit(subprocess.call([%r] + a))\n' % (rlog, REAL_GIT))
    os.chmod(os.path.join(rd, "git"), 0o755)
    r, o, e, _ = run(f, "A2b-cand-standalone-prs-only", CAND, ["--standalone", "--prs-only"], env={"PATH": rd + os.pathsep + os.environ["PATH"]})
    clones_made = os.path.exists(rlog)
    rec("A2b-prs-only", "Standalone --prs-only over all 17 open PRs (draft and held included): rc 0, 17 rows, no git clone invoked, cycle named",
        cmd_s + " --standalone --prs-only   (recording git shim)", r, r == 0 and len(seq(o)) == 17 and "Cycle or unresolved dependency" in o and not clones_made,
        "rc %d; rows %d; git clone invoked=%s; order %s" % (r, len(seq(o)), clones_made, seq(o)), REV_CAND)
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
    sd = json.loads(sp.stdout.strip().splitlines()[-1]) if sp.returncode == 0 else {"error": sp.stderr[-300:]}
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
        "UNMET lines %d, the last printed %s s before the run's first git clone; no-origin execute rc %d; dry run reports origin UNMET=%s" % (
            len(lines(o, "[UNMET]")), "%.1f" % ((min(clones) - max(unmet)) / 1e9) if clones and unmet else "n/a", ro, "[UNMET] origin remote" in od), REV_CAND,
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

# A16 ---------------------------------------------------------------------------------------------------------
if want("A16"):
    probe = r'''
import json, sys
sys.path.insert(0, sys.argv[1])
import toposort_prs as ts
import merge_cleanup as mc
def pr(n, head, base, cross=False):
    return dict(number=n, title="t%d" % n, body="", headRefName=head, baseRefName=base, files=[], createdAt="2026-11-27", isCrossRepository=cross)
forks = [pr(1, "main", "main", True), pr(2, "main", "main", True)]
stack = [pr(1, "feat/parent", "main"), pr(2, "feat/child", "feat/parent")]
shared = [pr(1, "feat/shared", "main", True), pr(2, "feat/child", "feat/shared")]  # a fork branch named like another PR's base
out = {}
for name, prs in (("fork_main_pair", forks), ("genuine_stack", stack), ("fork_shared_branch", shared)):
    o, _, _ = ts.toposort_prs([dict(p) for p in prs], "main")
    out[name] = {"order_deps": [(p["number"], p["_hard_deps"]) for p in o], "listed_1": [p["number"] for p in mc.effective_sequence([dict(p) for p in prs], {1}, "main")],
                 "listed_2": [p["number"] for p in mc.effective_sequence([dict(p) for p in prs], {2}, "main")]}
print(json.dumps(out))
'''
    md = patched("mut-fork", "toposort_prs.py", 'if pr.get("headRefName") and not pr.get("isCrossRepository")}', 'if pr.get("headRefName")}')
    pc = json.loads(subprocess.run([PY39, "-c", probe, CAND], capture_output=True, text=True).stdout)
    pm = json.loads(subprocess.run([PY39, "-c", probe, md], capture_output=True, text=True).stdout)
    with open(os.path.join(RUNS, "A16-fork-probe.json"), "w") as fh:
        json.dump({"candidate": pc, "mutant_no_cross_repository_guard": pm}, fh, indent=1)
    prot = r'''
import json, subprocess, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import merge_cleanup as mc
calls = []
mc._gh = lambda args, *a, **kw: (calls.append(args) or subprocess.CompletedProcess(args, 0, "", ""))
def run(parent_live, parent_listed, child_base="feat/parent"):
    calls.clear()
    live = dict(number=10, headRefName="feat/parent", baseRefName="main")
    if parent_live is not None:
        live["isCrossRepository"] = parent_live
    listed = dict(number=10, headRefName="feat/parent", baseRefName="main", isCrossRepository=parent_listed)
    child = dict(number=12, headRefName="feat/child", baseRefName=child_base, isCrossRepository=False)
    mc._protect_stacked_dependents(live, [listed, child], Path("."), "main")
    return list(calls)
print(json.dumps({"fork_info_has_field": run(True, True), "fork_production_shape": run(None, True),
                  "same_repository_parent": run(False, False), "no_identity_anywhere": run(None, None)}))
'''
    pcp = json.loads(subprocess.run([PY39, "-c", prot, CAND], capture_output=True, text=True).stdout.strip().splitlines()[-1])
    mdp = patched("mut-protect", "merge_cleanup.py", "    if cross:\n        return True\n    dependents = [p for p in open_prs", "    dependents = [p for p in open_prs")
    pmp = json.loads(subprocess.run([PY39, "-c", prot, mdp], capture_output=True, text=True).stdout.strip().splitlines()[-1])
    edit_call = [["pr", "edit", "12", "--base", "main"]]
    prot_ok = (pcp["fork_info_has_field"] == [] and pcp["fork_production_shape"] == [] and pcp["same_repository_parent"] == edit_call
               and pcp["no_identity_anywhere"] == edit_call and pmp["fork_production_shape"] == edit_call)
    with open(os.path.join(RUNS, "A16-protect-probe.json"), "w") as fh:
        json.dump({"candidate": pcp, "mutant_no_cross_repository_guard": pmp}, fh, indent=1)
    f = build("a16", forks=True)
    r, o, e, _ = run(f, "A16-cand-fork-dry", CAND, ["--standalone", "--prs", "118"], root=False)
    fm = build("a16m", forks=True)
    md2 = patched("mut-fork2", "toposort_prs.py", 'if pr.get("headRefName") and not pr.get("isCrossRepository")}', 'if pr.get("headRefName")}')
    _p = os.path.join(md2, "toposort_prs.py")
    _s = open(_p).read()
    _old = '        if integration and (pr.get("baseRefName") or "") == integration:\n            continue\n'
    assert _s.count(_old) == 1
    open(_p, "w").write(_s.replace(_old, ""))  # neither guard: a fork main->main PR is a stacked parent of its twin
    rm, om, em, _ = run(fm, "A16-mutant-fork-dry", md2, ["--standalone", "--prs", "118"], root=False)
    ok = (pc["fork_main_pair"]["order_deps"] == [[1, []], [2, []]] and pc["fork_main_pair"]["listed_1"] == [1]
          and pc["genuine_stack"]["order_deps"] == [[1, []], [2, [1]]] and pc["genuine_stack"]["listed_2"] == []
          and pc["fork_shared_branch"]["order_deps"] == [[1, []], [2, []]] and pc["fork_shared_branch"]["listed_2"] == [2]
          and pm["fork_shared_branch"]["order_deps"] == [[1, []], [2, [1]]] and pm["fork_shared_branch"]["listed_2"] == []
          and pm["fork_main_pair"]["listed_1"] == [1] and r == 0 and "Would merge PR #118" in o and "Would merge PR #118" not in om and "PR #118: depends on deferred prerequisite (#119)" in (om + em) and prot_ok)
    rec("A16", "Fork heads are not stacked parents (plan QA final R1 F1): two fork PRs from `main` have no edge and a selected one is kept; a genuine same-repository stack still orders and defers; the mutant without the guard reproduces the defect",
        "toposort_prs / effective_sequence probe (candidate vs mutant); " + cmd_s + " --standalone --prs 118   (fixture --with-forks)", r, ok,
        "retarget probe candidate fork(live field)=%s fork(production shape)=%s same-repository=%s no-identity=%s; mutant fork(production shape)=%s; candidate fork pair %s listed {1}->%s; genuine stack %s listed {2}->%s; mutant listed {1}->%s; end-to-end candidate rc %d (Would merge #118: %s), mutant rc %d (#118 previewed: %s; deferred behind fork #119: %s)" % (
            pcp["fork_info_has_field"], pcp["fork_production_shape"], pcp["same_repository_parent"], pcp["no_identity_anywhere"], pmp["fork_production_shape"],
            pc["fork_main_pair"]["order_deps"], pc["fork_main_pair"]["listed_1"], pc["genuine_stack"]["order_deps"], pc["genuine_stack"]["listed_2"],
            pm["fork_main_pair"]["listed_1"], r, "Would merge PR #118" in o, rm, "Would merge PR #118" in om, "depends on deferred prerequisite (#119)" in (om + em)), REV_CAND,
        "probes: runs/A16-fork-probe.json, runs/A16-protect-probe.json. Since the integration-branch rule (A19) a fork main->main pair is covered by either guard, so the fork guard alone is shown on the shared-branch case and the end-to-end mutant removes both")

# A17 ---------------------------------------------------------------------------------------------------------
if want("A17"):
    f = build("a17")
    prim = os.path.join(f, "primary")
    ge = dict(os.environ, GIT_AUTHOR_NAME="o", GIT_AUTHOR_EMAIL="o@o", GIT_COMMITTER_NAME="o", GIT_COMMITTER_EMAIL="o@o")
    open(os.path.join(prim, ".merge-cleanup.json"), "w").write('{"preserve_commit_history": true}\n')
    for a in (["add", ".merge-cleanup.json"], ["commit", "-q", "-m", "policy: preserve history"], ["push", "-q", "origin", "main"]):
        subprocess.run([REAL_GIT, "-C", prim] + a, check=True, env=ge, capture_output=True)
    st = json.load(open(os.path.join(f, "ghstate.json")))
    for p in st["prs"]:
        if p["number"] == 101:
            p["mergeable_override"] = "CONFLICTING"  # GitHub says CONFLICTING; the local merge is clean
    json.dump(st, open(os.path.join(f, "ghstate.json"), "w"))
    tip = lambda: subprocess.run([REAL_GIT, "--git-dir=" + os.path.join(f, "origin.git"), "rev-parse", "main"], capture_output=True, text=True).stdout.strip()
    before = tip()
    r1, o1, e1, _ = run(f, "A17-dry", CAND, ["--standalone", "--prs", "101"], root=False)
    r2, o2, e2, _ = run(f, "A17-exec", CAND, ["--standalone", "--prs", "101", "--execute"], root=False)
    st2 = json.load(open(os.path.join(f, "ghstate.json")))
    state101 = [p["state"] for p in st2["prs"] if p["number"] == 101][0]
    rec("A17", "GH-1656 local-merge rung in standalone: a GitHub-CONFLICTING PR with a clean local merge, policy merge, no installed hook: the dry run says the push would be refused; --execute stops before any push (origin unchanged, PR still open)",
        cmd_s + " --standalone --prs 101 [--execute]   (policy preserve_commit_history, PR scripted CONFLICTING)", r2,
        r1 == 0 and "that push would be refused" in o1 and r2 == 2 and "push refused before pushing" in (o2 + e2) and "githooks/install.sh is missing" in (o2 + e2)
        and before == tip() and state101 == "OPEN",
        "dry rc %d (refusal foretold=%s); execute rc %d (push refused=%s); origin tip unchanged=%s; PR 101 state %s" % (
            r1, "that push would be refused" in o1, r2, "push refused before pushing" in (o2 + e2), before == tip(), state101), REV_CAND,
        "the rung and its push belong to GH-1656; the gate check before the push is the existing gate_unwired_reason")

# A18 ---------------------------------------------------------------------------------------------------------
if want("A18"):  # code review F2: a ledger that arrives in the LANDING tree must never be skipped silently
    def with_ledger_pr(name):
        f = build(name)
        ge = dict(os.environ, GIT_AUTHOR_NAME="o", GIT_AUTHOR_EMAIL="o@o", GIT_COMMITTER_NAME="o", GIT_COMMITTER_EMAIL="o@o")
        origin = os.path.join(f, "origin.git")
        lt = os.path.join(f, "lt")
        for a in (["clone", "-q", origin, lt], ["-C", lt, "checkout", "-q", "-B", "feat/guide", "origin/feat/guide"]):
            subprocess.run([REAL_GIT] + a, check=True, capture_output=True)
        open(os.path.join(lt, "releases.sql"), "w").write("-- a ledger the PR brings in\n")
        for a in (["add", "releases.sql"], ["commit", "-q", "-m", "docs: a PR that adds a ledger"], ["push", "-q", "origin", "feat/guide"]):
            subprocess.run([REAL_GIT, "-C", lt] + a, check=True, env=ge, capture_output=True)
        head = subprocess.run([REAL_GIT, "-C", lt, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        subprocess.run([REAL_GIT, "--git-dir=" + origin, "update-ref", "refs/pull/101/head", head], check=True)
        return f, origin
    f, origin = with_ledger_pr("a18")
    tip = lambda: subprocess.run([REAL_GIT, "--git-dir=" + origin, "rev-parse", "main"], capture_output=True, text=True).stdout.strip()
    before = tip()
    r1, o1, e1, _ = run(f, "A18-cand-dry", CAND, ["--standalone", "--prs", "101"], root=False)
    r2, o2, e2, _ = run(f, "A18-cand-exec", CAND, ["--standalone", "--prs", "101", "--execute"], root=False)
    state101 = [q["state"] for q in json.load(open(os.path.join(f, "ghstate.json")))["prs"] if q["number"] == 101][0]
    md = patched("mut-a18", "merge_cleanup.py", "                if landed_overlay:\n", "                if False:\n")
    fm, _o = with_ledger_pr("a18m")
    rm, om, em, _ = run(fm, "A18-mutant-dry", md, ["--standalone", "--prs", "101"], root=False)
    refuse = "REFUSING under --standalone" in (o1 + e1) and "releases.sql" in (o1 + e1)
    rec("A18", "A PR that brings a ledger file into the landing tree is refused under --standalone (dry run and --execute), naming the file and merging nothing; the mutant without the check skips the gate and previews the merge",
        cmd_s + " --standalone --prs 101 [--execute]   (PR #101 adds releases.sql)", r2,
        r1 == 2 and refuse and "Would merge PR #101" not in (o1 + e1) and r2 == 2 and "REFUSING under --standalone" in (o2 + e2)
        and before == tip() and state101 == "OPEN" and "pre-merge ledger gate skipped" in (om + em) and "Would merge PR #101" in (om + em),
        "dry rc %d (refused=%s); execute rc %d; origin tip unchanged=%s; PR 101 %s; mutant rc %d skipped gate=%s previewed merge=%s" % (
            r1, refuse, r2, before == tip(), state101, rm, "pre-merge ledger gate skipped" in (om + em), "Would merge PR #101" in (om + em)), REV_CAND,
        "review finding on #1674: the primary-only startup guard did not see a ledger arriving in the landing tree")

# A19 ---------------------------------------------------------------------------------------------------------
if want("A19"):  # code review F1: a PR whose base is the integration branch is never a stacked child
    f = build("a19")
    st = json.load(open(os.path.join(f, "ghstate.json")))
    st["prs"].append({"number": 121, "headRefName": "main", "cross": False, "baseRefName": "stable", "title": "promote main to stable", "body": "",
                      "draft": False, "labels": [], "checks": "pass", "state": "OPEN", "createdAt": "2026-11-30T10:00:00Z"})
    json.dump(st, open(os.path.join(f, "ghstate.json"), "w"))
    r, o, e, _ = run(f, "A19-cand-dry", CAND, ["--standalone", "--prs", "109"], root=False)
    md = patched("mut-a19", "toposort_prs.py", '        if integration and (pr.get("baseRefName") or "") == integration:\n            continue\n', "")
    fm = build("a19m")
    json.dump(st, open(os.path.join(fm, "ghstate.json"), "w"))
    rm, om, em, _ = run(fm, "A19-mutant-dry", md, ["--standalone", "--prs", "109"], root=False)
    probe = r"""
import json, sys
sys.path.insert(0, sys.argv[1])
import toposort_prs as ts
import merge_cleanup as mc
def pr(n, head, base):
    return dict(number=n, title="t%d" % n, body="", headRefName=head, baseRefName=base, files=[], createdAt="2026-11-27", isCrossRepository=False)
promo = [pr(1, "development", "main"), pr(2, "feat/x", "development")]
stack = [pr(1, "feat/parent", "development"), pr(2, "feat/child", "feat/parent")]
out = {}
for name, prs in (("promotion", promo), ("stack", stack)):
    o, _, _ = ts.toposort_prs([dict(p) for p in prs], "development")
    out[name] = {"deps": [(p["number"], p["_hard_deps"]) for p in o], "listed_2": [p["number"] for p in mc.effective_sequence([dict(p) for p in prs], {2}, "development")]}
o, _, _ = ts.toposort_prs([dict(p) for p in promo])
out["no_integration_given"] = [(p["number"], p["_hard_deps"]) for p in o]
print(json.dumps(out))
"""
    pr_ = json.loads(subprocess.run([PY39, "-c", probe, CAND], capture_output=True, text=True).stdout.strip().splitlines()[-1])
    with open(os.path.join(RUNS, "A19-promotion-probe.json"), "w") as fh:
        json.dump(pr_, fh, indent=1)
    ok = (r == 0 and "Would merge PR #109" in o and "Would merge PR #109" not in om and "depends on deferred prerequisite (#121)" in (om + em)
          and pr_["promotion"]["deps"] == [[1, []], [2, []]] and pr_["promotion"]["listed_2"] == [2]
          and pr_["stack"]["deps"] == [[1, []], [2, [1]]] and pr_["stack"]["listed_2"] == []
          and pr_["no_integration_given"] == [[1, []], [2, [1]]])
    rec("A19", "A promotion PR (head named like the integration branch, base elsewhere) is not the stacked parent of an ordinary PR into the integration branch (Forge and standalone share this sorter); a real stack still orders and defers; the mutant defers the ordinary PR",
        "toposort_prs / effective_sequence probe; " + cmd_s + " --standalone --prs 109   (a same-repository PR #121, head main, base stable)", r, ok,
        "dry rc %d would-merge #109=%s; mutant would-merge=%s deferred-by-#121=%s; probe promotion deps %s listed{2}->%s; stack deps %s listed{2}->%s" % (
            r, "Would merge PR #109" in o, "Would merge PR #109" in om, "depends on deferred prerequisite (#121)" in (om + em),
            pr_["promotion"]["deps"], pr_["promotion"]["listed_2"], pr_["stack"]["deps"], pr_["stack"]["listed_2"]), REV_CAND,
        "review finding on #1674: the stacked-parent edge ignored whether the base is the integration branch; the CLI without --integration-branch keeps the old behaviour")

bad = [a for a, ok in results if not ok]
print("\nrows: %d, failed: %s" % (len(results), bad or "none"))
sys.exit(1 if bad else 0)
