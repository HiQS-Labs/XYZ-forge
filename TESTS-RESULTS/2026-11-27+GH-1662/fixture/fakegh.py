#!/usr/bin/env python3
"""Stand-in `gh` for the GH-1662 manual check (a foreign repo, no Forge files).

It answers only what merge-cleanup asks of `gh`, from a JSON state file next to the fixture and from
the fixture's bare origin. It computes `files` (three-dot diff) and `mergeable` (git merge-tree) the way
GitHub reports them, and `pr merge --squash` really squash-merges into the bare origin.
It CANNOT exercise real GitHub semantics: required checks and branch protection are scripted, there is
no rate limit, no merge queue and no hosted workflow. Python 3.9 compatible.
"""
import json
import os
import subprocess
import sys
import tempfile

FIX = os.environ["FIXTURE_DIR"]
ORIGIN = os.path.join(FIX, "origin.git")
STATE = os.path.join(FIX, "ghstate.json")
LOG = os.environ.get("FAKEGH_LOG")
args = sys.argv[1:]
if LOG:
    with open(LOG, "a") as fh:
        fh.write("gh " + " ".join(args) + "\n")


def git(*a, **kw):
    return subprocess.run(["git", "--git-dir=" + ORIGIN] + list(a), capture_output=True, text=True, **kw)


def load():
    with open(STATE) as fh:
        return json.load(fh)


def save(s):
    with open(STATE, "w") as fh:
        json.dump(s, fh, indent=1)


def tip(branch):
    r = git("rev-parse", "--verify", "-q", "refs/heads/" + branch)
    return r.stdout.strip() if r.returncode == 0 else ""


def view(pr, state):
    head = tip(pr["headRefName"])
    base = tip(pr["baseRefName"])
    mergeable = "UNKNOWN"
    files = []
    if pr["state"] == "OPEN" and head and base:
        mt = git("merge-tree", "--write-tree", "--no-messages", base, head)
        mergeable = "CONFLICTING" if mt.returncode == 1 else "MERGEABLE"
        d = git("diff", "--name-only", base + "..." + head)
        files = [{"path": p} for p in d.stdout.split() if p]
    roll = []
    if pr["checks"] == "fail":
        roll = [{"name": "ci", "conclusion": "FAILURE", "status": "COMPLETED"}]
    elif pr["checks"] == "pass":
        roll = [{"name": "ci", "conclusion": "SUCCESS", "status": "COMPLETED"}]
    return {
        "number": pr["number"], "title": pr["title"], "body": pr.get("body", ""), "headRefName": pr["headRefName"],
        "headRefOid": head, "baseRefName": pr["baseRefName"], "isDraft": pr.get("draft", False),
        "labels": [{"name": n} for n in pr.get("labels", [])], "mergeable": mergeable,
        "statusCheckRollup": roll, "files": files, "createdAt": pr["createdAt"], "state": pr["state"],
        "mergeCommit": ({"oid": pr["mergeOid"]} if pr.get("mergeOid") else None),
        "url": "https://github.com/acme/widgets/pull/%d" % pr["number"],
    }


def out(o):
    print(json.dumps(o))
    sys.exit(0)


def pick(o, fields):
    return {k: o.get(k) for k in fields.split(",") if k}


s = load()
prs = {p["number"]: p for p in s["prs"]}
if args[:1] == ["--version"]:
    print("gh version 2.99.0 (stand-in)")
    sys.exit(0)
if args[:2] == ["pr", "list"]:
    out([view(p, s) for p in s["prs"] if p["state"] == "OPEN"])
if args[:2] == ["pr", "view"]:
    pr = prs.get(int(args[2]))
    if pr is None:
        sys.stderr.write("no pull requests found\n")
        sys.exit(1)
    fields = args[args.index("--json") + 1] if "--json" in args else ""
    v = view(pr, s)
    out(pick(v, fields) if fields else v)
if args[:2] == ["pr", "checks"]:
    pr = prs[int(args[2])]
    if pr["checks"] == "none":
        sys.stderr.write("no required checks reported on the '%s' branch\n" % pr["headRefName"])
        sys.exit(1)
    bucket = "fail" if pr["checks"] == "fail" else "pass"
    print(json.dumps([{"name": "ci", "bucket": bucket}]))
    sys.exit(1 if bucket == "fail" else 0)
if args[:2] == ["pr", "edit"]:
    pr = prs[int(args[2])]
    if "--base" in args:
        pr["baseRefName"] = args[args.index("--base") + 1]
    save(s)
    sys.exit(0)
if args[:2] == ["pr", "merge"]:
    pr = prs[int(args[2])]
    head, base = tip(pr["headRefName"]), tip(pr["baseRefName"])
    if "--match-head-commit" in args and not head.startswith(args[args.index("--match-head-commit") + 1][:7]):
        sys.stderr.write("head commit does not match\n")
        sys.exit(1)
    with tempfile.TemporaryDirectory() as td:
        env = dict(os.environ, GIT_AUTHOR_NAME="gh", GIT_AUTHOR_EMAIL="gh@example.invalid",
                   GIT_COMMITTER_NAME="gh", GIT_COMMITTER_EMAIL="gh@example.invalid")
        w = os.path.join(td, "w")
        subprocess.run(["git", "clone", "-q", ORIGIN, w], check=True, env=env, capture_output=True)
        subprocess.run(["git", "-C", w, "checkout", "-q", pr["baseRefName"]], check=True, env=env, capture_output=True)
        m = subprocess.run(["git", "-C", w, "merge", "--squash", "origin/" + pr["headRefName"]], env=env, capture_output=True, text=True)
        if m.returncode != 0:
            sys.stderr.write("not mergeable: " + m.stdout[-200:] + "\n")
            sys.exit(1)
        subprocess.run(["git", "-C", w, "commit", "-q", "--allow-empty", "-m", "%s (#%d)" % (pr["title"], pr["number"])],
                       check=True, env=env, capture_output=True)
        oid = subprocess.run(["git", "-C", w, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        subprocess.run(["git", "-C", w, "push", "-q", "origin", "HEAD:refs/heads/" + pr["baseRefName"]], check=True, env=env, capture_output=True)
    pr["state"], pr["mergeOid"] = "MERGED", oid
    save(s)
    print("merged (stand-in)")
    sys.exit(0)
if args[:2] == ["repo", "view"]:
    out({"url": "https://github.com/acme/widgets", "mergeCommitAllowed": True, "nameWithOwner": "acme/widgets"})
if args[:2] == ["run", "list"]:
    out([])
if args[:2] == ["issue", "create"]:
    s.setdefault("issues", {})
    n = 900 + len(s["issues"]) + 1
    body = open(args[args.index("--body-file") + 1]).read() if "--body-file" in args else ""
    s["issues"][str(n)] = body
    save(s)
    print("https://github.com/acme/widgets/issues/%d" % n)
    sys.exit(0)
if args[:2] == ["issue", "view"]:
    out({"body": s.get("issues", {}).get(args[2], ""), "state": "OPEN"})
if args[:2] == ["issue", "edit"]:
    s.setdefault("issues", {})[args[2]] = open(args[args.index("--body-file") + 1]).read()
    save(s)
    sys.exit(0)
sys.stderr.write("stand-in gh: unsupported: " + " ".join(args) + "\n")
sys.exit(1)
