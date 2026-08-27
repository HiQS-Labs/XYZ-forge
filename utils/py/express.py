#!/usr/bin/env python3
"""express.py — /express hotfix fast lane driver (GH-267).

One motion, per the design on #267 (v2): fix -> releases DB -> PDDA docs ->
land on development -> reconcile. This driver is the mechanized form of SOP.md
§4's express-to-development carve-out: the ONLY sanctioned agent path to a
direct development landing without a human review loop, because every oracle
that a PR would have satisfied is asserted up front instead.

Landing shape (deliberate deviation, documented on #267): the commit rides a
task branch and lands via a PR that /express itself opens and immediately
merges. That keeps wave_reconcile --pr working, auto-closes the linked issue
(a direct push would not), and preserves base-branch/diff-size predicates.
"Direct" here means "no human gate between fix and development", not "no PR
object". A true push-to-development mode is Phase 2, pending wave_reconcile
--commit. The operator's /express invocation IS the merge authorization.

Exit codes: 0 ok; 3 express-refused (guardrail); 4 environment/dependency.
Every refusal and every fired run appends a .tick event under .tick/events/
(runtime state, untracked) so standup can report the weekly express count.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import datetime
import sqlite3

EXIT_OK = 0
EXIT_REFUSED = 3
EXIT_ENV = 4

# SOP §4 carve-out names exactly these. Anything else belongs on the normal
# fresh-clone PR lane. Keep in sync with AGENTS.md GH-308 (12 frozen twins).
FROZEN_TWINS = [
    "relay-automation/agy-turn.sh",
    "relay-automation/aider-turn.sh",
    "relay-automation/claude-turn.sh",
    "relay-automation/codex-turn.sh",
    "relay-automation/pi-turn.sh",
    "relay-automation/poll.sh",
    "relay-automation/relay-loop.sh",
    "relay-automation/relay-drive.sh",
    "relay-automation/consult.sh",
    "relay-automation/marathon-drive.sh",
    "relay-automation/swarm-preflight.sh",
    "utils/marathon-plan.sh",
]
# AGENTS.md: "Changes to .tick/events/, src/project.js, relay containment, or
# event/verb shape are usually broader than they look. Treat them as at least
# Costly until proven otherwise." Express never lands Costly work.
KERNEL_SURFACES = [".tick/", "src/project.js", "relay-automation/hooks/"]
# Shared (non-twin) Bash runtime the whole relay surface depends on — refused
# under its own rule name so a reader never sees "frozen twin" for a file the
# repo explicitly says is not one (AGENTS.md, QA finding 4).
SHARED_RUNTIME = "relay-automation/relay-turn-lib.sh"
# Docs/paper paths never count against the size bounds — they are required by
# the flow itself, not part of the fix's blast radius.
DOC_PREFIXES = ("CHANGELOG.md", "PROJECT/", "ROADMAP.md", "ROADMAP-DASHBOARD.md",
                "RELEASES.generated.md", "LEADERBOARD", "RELEASES-PREVIEW", "docs/",
                "README", "AGENTS.md", "GUIDING-PRINCIPLES.md", "ROUTER.md", "SOP.md",
                "ARCHITECTURE", "WORKTREE-SAFETY.md", "HARNESS-MODELS-REGISTRY",
                "RELEASES-DB-FAQS.md", "UPGRADE.md")
DEFAULT_MAX_FILES = 4
DEFAULT_MAX_INSERTIONS = 150


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def die(msg, code=EXIT_ENV):
    sys.stderr.write(msg.rstrip() + "\n")
    sys.exit(code)


def refuse(root, rule, reason, issue=None):
    write_tick(root, "express-refused", issue=issue, rule=rule, reason=reason)
    sys.stderr.write("express-refused: rule=%s — %s\n" % (rule, reason))
    sys.exit(EXIT_REFUSED)


def write_tick(root, verb, **fields):
    events = os.path.join(root, ".tick", "events")
    try:
        os.makedirs(events, exist_ok=True)
        ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H-%M-%S.%f")[:-3] + "Z"
        target = "gh-%s" % fields.get("issue") if fields.get("issue") else "lane"
        path = os.path.join(events, "%s-%s-%s.jsonl" % (ts, verb, target))
        rec = dict(at=now_iso(), actor="express", verb=verb)
        rec.update({k: v for k, v in fields.items() if v is not None})
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
    except OSError as exc:  # telemetry must never block the lane, only complain
        sys.stderr.write("express: tick write failed (%s)\n" % exc)


def git(root, *args, check=True):
    r = subprocess.run(["git", "-C", root] + list(args), capture_output=True, text=True)
    if check and r.returncode != 0:
        die("git %s failed: %s" % (" ".join(args[:2]), r.stderr.strip()))
    return r


def gh(args, check=True):
    r = subprocess.run(["gh"] + list(args), capture_output=True, text=True)
    if check and r.returncode != 0:
        die("gh %s failed: %s" % (args[0], r.stderr.strip()))
    return r


def releases_app(root):
    app = os.path.join(root, "utils", "py", "releases_app.py")
    if not os.path.isfile(app):
        die("releases_app.py not found under %s — express requires a canonical-repo layout" % root)
    return app


def run_releases(root, *args, check=True):
    r = subprocess.run([sys.executable, releases_app(root)] + list(args),
                       cwd=root, capture_output=True, text=True)
    if check and r.returncode != 0:
        die("releases %s failed: %s" % (args[0], (r.stderr or r.stdout).strip()))
    return r


# ── change-set plumbing ──────────────────────────────────────────────────────

def change_paths(root):
    """Every path the fix touches vs a fresh task branch: uncommitted tracked
    changes plus untracked files. HEAD must still equal origin/development
    (checked elsewhere), so this diff IS the fix and nothing else."""
    porcelain = git(root, "status", "--porcelain=v1", check=False).stdout
    paths = set()
    for line in porcelain.splitlines():
        if not line.strip():
            continue
        p = line[3:].strip().strip('"')
        if " -> " in p:  # rename: take the destination
            p = p.split(" -> ")[1]
        paths.add(p)
    return sorted(paths)


def core_paths(paths):
    return [p for p in paths if not is_doc_path(p)]


def is_doc_path(p):
    """Docs never count against the size bounds: they are required by the flow
    itself, not part of the fix's blast radius (QA finding 5)."""
    return p.startswith(DOC_PREFIXES) or p.endswith(".md") or p.endswith(".MD")


def insertions(root, paths):
    total = 0
    numstat = git(root, "diff", "origin/development", "--numstat", check=False).stdout
    tracked = {}
    for line in numstat.splitlines():
        parts = line.split("\t")
        if len(parts) == 3 and parts[0] != "-":
            tracked[parts[2]] = int(parts[0])
    for p in paths:
        if is_doc_path(p):
            continue
        if p in tracked:
            total += tracked[p]
        elif os.path.isfile(os.path.join(root, p)):  # untracked new file
            with open(os.path.join(root, p), encoding="utf-8", errors="replace") as f:
                total += sum(1 for _ in f)
    return total


# ── step 0–3: check ──────────────────────────────────────────────────────────

def cmd_check(args):
    root = args.root

    if not os.path.isdir(os.path.join(root, ".git")):
        die("not a git repo: %s" % root)

    branch = git(root, "branch", "--show-current").stdout.strip()
    if branch in ("development", "main", ""):
        refuse(root, "task-branch",
               "express runs from a task branch cut off origin/development (SOP §4), "
               "not from %r" % (branch or "(detached)"), issue=args.issue)

    origin_dev = git(root, "rev-parse", "origin/development", check=False)
    if origin_dev.returncode != 0:
        refuse(root, "task-clone", "origin/development not found — clone from the GitHub remote", issue=args.issue)
    head = git(root, "rev-parse", "HEAD").stdout.strip()
    if head != origin_dev.stdout.strip():
        refuse(root, "task-clone",
               "HEAD is not origin/development — the task branch already carries commits; "
               "express lands exactly one fix from a fresh task clone (GH-527: peer work "
               "hides behind unexplained commits)", issue=args.issue)

    paths = change_paths(root)
    if not paths:
        refuse(root, "empty", "no changes present — nothing to express", issue=args.issue)

    core = core_paths(paths)

    # Step 2 — hard refusals. Frozen twins, kernel surfaces, containment.
    for p in core:
        if p in FROZEN_TWINS:
            refuse(root, "frozen-twin",
                   "%s is a frozen Bash twin (GH-308) — the trailer flow "
                   "needs human judgment, not an express lane" % p, issue=args.issue)
        if p == SHARED_RUNTIME:
            refuse(root, "shared-runtime",
                   "%s is the shared Bash runtime dependency (not a twin, AGENTS.md) — "
                   "too load-bearing for an express lane" % p, issue=args.issue)
        if p.endswith(".sh") and (p.startswith("utils/") or p.startswith("relay-automation/")):
            refuse(root, "no-new-bash",
                   "%s — new/edited .sh under utils/ or relay-automation/ is rejected by the "
                   "GH-551 guard; express will not carry it" % p, issue=args.issue)
        for surface in KERNEL_SURFACES:
            if p == surface or p.startswith(surface):
                refuse(root, "kernel-surface",
                       "%s is a coordination-kernel / containment surface (AGENTS: at least "
                       "Costly) — express lands risk-bounded work only" % p, issue=args.issue)
        if p.startswith("scratch/") or p.startswith("temp/") or p.endswith((".bak", ".orig", ".rej")):
            refuse(root, "scratch", "%s is scratch/editor output — commit-worthy paths only" % p, issue=args.issue)

    # Step 1 — bounds. Docs never count; code+test do.
    if len(core) > args.max_files:
        refuse(root, "too-many-files",
               "%d core files > bound %d — route to the normal PR lane" % (len(core), args.max_files),
               issue=args.issue)
    ins = insertions(root, paths)
    if ins > args.max_insertions:
        refuse(root, "too-large",
               "%d insertions > bound %d — route to the normal PR lane" % (ins, args.max_insertions),
               issue=args.issue)
    non_test = [p for p in core if not p.startswith("test/")]
    tops = {p.split("/")[0] for p in non_test}
    if len(tops) > 1:
        refuse(root, "multi-subsystem",
               "core paths span %s — express is single-subsystem by contract" % ", ".join(sorted(tops)),
               issue=args.issue)

    # Step 3 — the issue must exist and be OPEN (closed => maybe already landed).
    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state,title"], check=False)
    if iv.returncode != 0:
        refuse(root, "issue-missing", "gh cannot resolve issue #%s in %s" % (args.issue, args.repo), issue=args.issue)
    meta = json.loads(iv.stdout)
    if meta.get("state") != "OPEN":
        refuse(root, "issue-closed",
               "issue #%s is %s — the work may already be landed; run the preflight "
               "already-landed probes before re-doing it" % (args.issue, meta.get("state")), issue=args.issue)

    # Step 4 — the fix must carry its regression suite, registered in validate.sh.
    suite = args.suite
    if not suite.startswith("test/"):
        suite = "test/" + suite
    if not os.path.isfile(os.path.join(root, suite)):
        refuse(root, "suite-missing", "%s does not exist — a hotfix without its regression suite is a claim, not a fix" % suite, issue=args.issue)
    validate = os.path.join(root, "validate.sh")
    with open(validate, encoding="utf-8", errors="replace") as f:
        vbody = f.read()
    if ('"%s"' % os.path.basename(suite)) not in vbody:
        refuse(root, "suite-unregistered",
               "%s is not registered in validate.sh TESTS — an unregistered suite never runs in the gate" % suite,
               issue=args.issue)

    print("express-check: PASS")
    print("  issue   : #%s %s" % (args.issue, meta.get("title", "")))
    print("  files   : %d core, %d insertions (bounds %d/%d)" % (len(core), ins, args.max_files, args.max_insertions))
    print("  suite   : %s (registered)" % suite)
    print("  changes : %s" % ", ".join(paths))
    return dict(issue=args.issue, title=meta.get("title", ""), paths=paths, suite=suite,
                insertions=ins, branch=branch)


# ── step 5: docs born complete ───────────────────────────────────────────────

def slugify(title):
    s = re.sub(r"[^A-Za-z0-9]+", "-", title).strip("-").upper()
    return s[:60]


def cmd_docs(args):
    root = args.root
    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state,title,url"])
    meta = json.loads(iv.stdout)

    slug = args.slug or slugify(meta["title"])
    doc = os.path.join(root, "PROJECT", "2-WORKING", "GH-%d-%s.md" % (args.issue, slug))
    if os.path.isfile(doc):
        refuse(root, "doc-exists", "%s already exists — express does not overwrite capture docs" % doc, issue=args.issue)
    os.makedirs(os.path.dirname(doc), exist_ok=True)

    today = datetime.date.today().isoformat()
    body = """---
title: "GH-{n}: {t}"
status: Active
created: {d}
updated: {d}
owner: operator (via /express)
gh_issue: {n}
source: {src}
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): {t}
---

# GH-{n} — {t}

## Status

| What was just completed | What's next |
|---|---|
| Fix landed via /express; regression suite {suite} registered and green | Reconcile promotes this doc when issue #{n} closes |

## Acceptance Criteria

- [x] Regression suite {suite} green in the gate.
- [x] Single-subsystem, risk-bounded diff (express qualification passed).

## Merge evidence

- (recorded at landing by the /express driver)

## Lessons Learned (For Future Agents)

- Landed via the /express fast lane (GH-267): the fix, its suite, this doc, and the
  CHANGELOG entry moved as one motion; consult the .tick express-fired event for the
  run's receipts. Operator-supplied summary: {sm}
""".format(n=args.issue, t=meta["title"], d=today, src=meta["url"], suite=args.suite, sm=args.summary or "(none)")
    with open(doc, "w", encoding="utf-8") as f:
        f.write(body)

    # CHANGELOG — newest-first under a fresh dated Unreleased section.
    cl = os.path.join(root, "CHANGELOG.md")
    bullet = ("- **GH-%d: %s.** (express hotfix, GH-267 lane; "
              "suite %s green.)\n" % (args.issue, meta["title"], args.suite))
    entry = "## [Unreleased] - %s\n\n### Fixed\n%s\n" % (today, bullet)
    with open(cl, encoding="utf-8", errors="replace") as f:
        cbody = f.read()
    m = re.search(r"^## \[", cbody, re.M)
    if m and today in cbody[m.start():m.start() + 40]:
        # Today's section exists: append under its Fixed list, or create the
        # Fixed list if the section lacks one — the entry is never silently
        # dropped (QA finding 3).
        hdr_nl = cbody.index("\n", m.start()) + 1
        nxt = re.search(r"^## \[", cbody[hdr_nl:], re.M)
        section_end = hdr_nl + nxt.start() if nxt else len(cbody)
        fx = re.search(r"^### Fixed[^\n]*\n", cbody[hdr_nl:section_end], re.M)
        if fx:
            insert_at = hdr_nl + fx.end()
        else:
            insert_at = hdr_nl
            bullet = "\n### Fixed\n" + bullet
        cbody = cbody[:insert_at] + bullet + cbody[insert_at:]
    elif m:
        cbody = cbody[:m.start()] + entry + cbody[m.start():]
    else:
        cbody += "\n" + entry
    with open(cl, "w", encoding="utf-8") as f:
        f.write(cbody)

    print("express-docs: born complete -> %s (+ CHANGELOG entry)" % os.path.relpath(doc, root))
    return dict(doc=os.path.relpath(doc, root))


# ── step 6: ledger ───────────────────────────────────────────────────────────

def cmd_ledger(args):
    root = args.root
    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state,title,url,createdAt"])
    meta = json.loads(iv.stdout)

    db = os.path.join(root, "releases.db")
    if not os.path.isfile(db):
        die("no releases.db under %s — express requires the releases ledger" % root)
    conn = sqlite3.connect(db)
    try:
        row = conn.execute("SELECT global_id FROM roadmap_items WHERE gh_number = ?",
                           (args.issue,)).fetchone()
    finally:
        conn.close()

    if row is None:
        doc = args.doc_path
        if not doc:
            cands = sorted(
                p for p in os.listdir(os.path.join(root, "PROJECT", "2-WORKING"))
                if p.startswith("GH-%d-" % args.issue)) if os.path.isdir(os.path.join(root, "PROJECT", "2-WORKING")) else []
            if not cands:
                refuse(root, "no-doc", "run `express docs` first (or pass --doc-path)", issue=args.issue)
            doc = "PROJECT/2-WORKING/" + cands[0]
        raw = ("- **GH-%d · %s** 🆕 rated 2/2/2 — [doc](%s) · [#%d](%s)" %
               (args.issue, meta["title"], doc, args.issue, meta["url"]))
        run_releases(root, "roadmap", "add",
                     "--issue-num", str(args.issue), "--issue-url", meta["url"],
                     "--title", meta["title"], "--created", (meta.get("createdAt") or "")[:10],
                     "--doc-path", doc, "--raw-text", raw)
        print("express-ledger: parked roadmap row for GH-%d -> %s" % (args.issue, doc))
    else:
        print("express-ledger: roadmap row already parked (%s)" % row[0])

    # dial-in into the named release (default: the active one from `releases next`)
    rel = args.release
    if not rel:
        nxt = run_releases(root, "next").stdout
        m = re.search(r"gid=(rel-[0-9A-Z]+)", nxt)
        if not m:
            refuse(root, "no-active-release", "`releases next` names no release gid: %s" % nxt.strip(), issue=args.issue)
        rel = m.group(1)
    run_releases(root, "manifest", "dial-in", meta["url"], "--gid", rel,
                 "--reason", "express hotfix %s (GH-267 lane)" % datetime.date.today().isoformat())
    print("express-ledger: dialed into %s" % rel)
    return dict(release=rel)


# ── steps 7–11: land + reconcile ─────────────────────────────────────────────

def build_offline_manifest(root, repo, pr_number):
    """Fallback reconcile path: PR bodies citing foreign-tracker numbers
    (GH-368/375/492/551-class) make live wave_reconcile die on unresolvable
    linked issues. Build the sanctioned offline manifest: resolvable in-repo
    numbers carry live state; unresolvable ones are omitted (unknown =>
    promote-as-before per wave_reconcile's GH-202 contract)."""
    pv = gh(["pr", "view", str(pr_number), "-R", repo, "--json",
             "number,title,state,mergedAt,baseRefName,headRefName,body,url"], check=False)
    if pv.returncode != 0:
        return None
    pr = json.loads(pv.stdout)
    manifest = {"prs": [pr], "issues": []}
    seen = set()
    for num in set(int(n) for n in re.findall(r"(?:GH-|#)(\d{1,5})", pr.get("body") or "")):
        if num in seen or num == pr_number:
            continue
        seen.add(num)
        iv = gh(["issue", "view", str(num), "-R", repo, "--json", "state"], check=False)
        if iv.returncode == 0:
            manifest["issues"].append({"number": num, "state": json.loads(iv.stdout)["state"]})
    return manifest


def args_repo():
    return os.environ.get("EXPRESS_REPO", "HiQS-Labs/XYZ-forge")


def cmd_land(args):
    root = args.root
    state = cmd_check(args)  # re-qualify at landing time, not at capture time
    suite = state["suite"]

    # Step 7 — the fix's own suite must be green right now.
    r = subprocess.run(["bash", os.path.join(root, suite)], cwd=root)
    if r.returncode != 0:
        refuse(root, "suite-red", "%s exited %d — no red suite rides the express lane" % (suite, r.returncode),
               issue=args.issue)

    # Step 8 — commit the one-motion change set.
    git(root, "add", "-A")
    msg = ("fix(GH-%d): %s [express]\n\nExpress lane (GH-267): fix + suite + born-complete doc + "
           "CHANGELOG in one motion.\n\nCloses #%d\n" % (args.issue, state["title"], args.issue))
    git(root, "commit", "-m", msg)
    sha = git(root, "rev-parse", "HEAD").stdout.strip()
    branch = state["branch"]
    git(root, "push", "-u", "origin", branch)  # pre-push hook runs the full gate here

    # Ghost PR: opened and merged by the driver. The operator's /express
    # invocation is the authorization — this is the documented deviation from
    # jog's pause-at-landing default (#267), not an oversight.
    pr_url = gh(["pr", "create", "-R", args.repo, "--base", "development", "--head", branch,
                 "--title", "fix(GH-%d): %s [express]" % (args.issue, state["title"]),
                 "--body", "Closes #%d.\n\nExpress hotfix (GH-267): suite `%s` green; merge "
                           "authorization is the operator's /express invocation." % (args.issue, suite)]
                ).stdout.strip()
    m = re.search(r"/pull/(\d+)", pr_url)
    pr_number = int(m.group(1)) if m else -1
    gh(["pr", "merge", str(pr_number), "-R", args.repo, "--merge"])

    # Step 9 — ship with evidence (post-merge, so sha + receipts exist).
    rel = args.release
    if not rel:
        nxt = run_releases(root, "next").stdout
        mrel = re.search(r"gid=(rel-[0-9A-Z]+)", nxt)
        rel = mrel.group(1) if mrel else None
    if rel:
        iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "url"])
        url = json.loads(iv.stdout)["url"]
        run_releases(root, "manifest", "ship", url, "--gid", rel,
                     "--evidence", "%s; %s green in gate; PR #%d merged (express)" % (sha, suite, pr_number))

    # Step 10 — the merge said "Closes #N" so the issue auto-closed; verify,
    # and close explicitly if GitHub did not.
    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state"], check=False)
    if iv.returncode == 0 and json.loads(iv.stdout)["state"] != "CLOSED":
        gh(["issue", "close", str(args.issue), "-R", args.repo,
            "--comment", "Express hotfix landed: %s (PR #%d, suite %s green)" % (sha, pr_number, suite)])

    # Step 11 — reconcile. Live first; foreign-tracker mentions fall back to
    # the offline manifest (auto-built above) so one PR body can't wedge the lane.
    wr = [sys.executable, os.path.join(root, "utils", "py", "wave_reconcile.py"), "--pr", str(pr_number)]
    r = subprocess.run(wr + ["--root", root], cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        manifest = build_offline_manifest(root, args.repo, pr_number)
        if manifest:
            mpath = os.path.join(root, ".tick", "express-reconcile-manifest.json")
            os.makedirs(os.path.dirname(mpath), exist_ok=True)
            with open(mpath, "w", encoding="utf-8") as f:
                json.dump(manifest, f)
            r2 = subprocess.run(wr + ["--root", root, "--offline", mpath],
                                cwd=root, capture_output=True, text=True)
            if r2.returncode != 0:
                sys.stderr.write("express: reconcile failed even offline — run "
                                 "`wave_reconcile.py --pr %d` manually:\n%s\n" % (pr_number, r2.stderr[-500:]))
        else:
            sys.stderr.write("express: reconcile failed — run `wave_reconcile.py --pr %d` "
                             "manually:\n%s\n" % (pr_number, r.stderr[-500:]))

    write_tick(root, "express-fired", issue=args.issue, sha=sha, pr=pr_number,
               suite=suite, release=rel, files=len(state["paths"]), insertions=state["insertions"])
    print("express-land: PR #%d merged, issue #%d closed, mfi shipped against %s" %
          (pr_number, args.issue, rel or "(none)"))
    return dict(pr=pr_number, sha=sha, release=rel)


def cmd_run(args):
    cmd_check(args)
    cmd_docs(args)
    ledger_args = argparse.Namespace(**vars(args))
    cmd_ledger(ledger_args)
    cmd_land(args)


def main():
    ap = argparse.ArgumentParser(prog="express.py", description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.getcwd())
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p, issue_required=True):
        p.add_argument("--repo", default=args_repo())
        p.add_argument("--issue", type=int, required=issue_required)
        p.add_argument("--suite")
        p.add_argument("--max-files", type=int, default=DEFAULT_MAX_FILES)
        p.add_argument("--max-insertions", type=int, default=DEFAULT_MAX_INSERTIONS)

    p = sub.add_parser("check", help="steps 0-3: tree, bounds, forbidden surfaces, issue, suite")
    common(p)
    p.set_defaults(fn=cmd_check)

    p = sub.add_parser("docs", help="step 5: born-complete capture doc + CHANGELOG entry")
    common(p)
    p.add_argument("--slug")
    p.add_argument("--summary")
    p.set_defaults(fn=cmd_docs)

    p = sub.add_parser("ledger", help="step 6: roadmap add (if absent) + manifest dial-in")
    common(p)
    p.add_argument("--release")
    p.add_argument("--doc-path")
    p.set_defaults(fn=cmd_ledger)

    p = sub.add_parser("land", help="steps 7-11: suite, commit, ghost PR, merge, ship, close, reconcile")
    common(p)
    p.add_argument("--release")
    p.set_defaults(fn=cmd_land)

    p = sub.add_parser("run", help="the whole motion in order")
    common(p)
    p.add_argument("--release")
    p.add_argument("--slug")
    p.add_argument("--summary")
    p.set_defaults(fn=cmd_run)

    args = ap.parse_args()
    if getattr(args, "suite", None) is None and args.cmd in ("check", "land", "run"):
        ap.error("--suite is required for %s (a hotfix without its regression suite is a claim, not a fix)" % args.cmd)
    args.fn(args)


if __name__ == "__main__":
    main()
