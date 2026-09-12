#!/usr/bin/env python3
"""express.py — /express hotfix fast lane driver (GH-267).

One motion, per the design on #267 (v2): fix -> releases DB -> PDDA docs ->
land on development -> reconcile. This driver is the mechanized form of SOP.md
§4's express-to-development carve-out: the ONLY sanctioned agent path to a
direct development landing without a human review loop, because every oracle
that a PR would have satisfied is asserted up front instead.

Landing shape: the qualified commit is pushed directly to development. The
operator's /express invocation IS the landing authorization; the pre-push gate,
fast-forward update, commit reachability check, and commit-based reconciliation
replace the former immediately-merged ghost PR.

Exit codes: 0 ok; 3 express-refused (guardrail); 4 environment/dependency.
Every refusal and every fired run appends a .tick event under .tick/events/
(runtime state, untracked) so standup can report the weekly express count.
"""

import argparse
import hashlib
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
KERNEL_SURFACES = [".tick/", "src/project.js", "relay-automation/hooks/", "githooks/"]
# Shared (non-twin) Bash runtime the whole relay surface depends on — refused
# under its own rule name so a reader never sees "frozen twin" for a file the
# repo explicitly says is not one (AGENTS.md, QA finding 4).
SHARED_RUNTIME = "relay-automation/relay-turn-lib.sh"
# The lane's OWN paperwork — the only doc exemptions. A blanket .md exemption
# (the first draft, per deepseek QA F5) would let a gateless merge rewrite
# governance and skills unbounded (PR #270 review finding 5), so this list is
# exactly what the flow itself generates.
# Ledger artifacts: driver-written during the ledger/ship phases and expected
# at landing requalification. An operator hand-edit is refused — verbs only.
DRIVER_LEDGER = ("releases.db", "releases.sql")
# Every adopted projection refreshed by a releases write. Presence is the
# releases app's opt-in signal, so only files already adopted by this checkout
# are accepted as driver output. The dashboard is rendered explicitly below.
RELEASES_PROJECTIONS = (
    "RELEASES-PREVIEW.html",
    "LEADERBOARD.html",
    "LEADERBOARD.md",
)
DRIVER_GENERATED = RELEASES_PROJECTIONS
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
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H-%M-%S.%f")[:-3] + "Z"
    target = "gh-%s" % fields.get("issue") if fields.get("issue") else "lane"
    filename = "%s-%s-%s.jsonl" % (ts, verb, target)
    rec = dict(at=now_iso(), actor="express", verb=verb)
    rec.update({k: v for k, v in fields.items() if v is not None})
    payload = json.dumps(rec) + "\n"
    try:
        os.makedirs(events, exist_ok=True)
        path = os.path.join(events, filename)
        with open(path, "w", encoding="utf-8") as f:
            f.write(payload)
    except OSError as exc:  # telemetry must never block the lane, only complain
        sys.stderr.write("express: tick write failed (%s)\n" % exc)

    # Mirror to central telemetry store (GH-516)
    try:
        central = os.path.expanduser("~/.config/xyz/events")
        os.makedirs(central, exist_ok=True)
        cpath = os.path.join(central, filename)
        with open(cpath, "w", encoding="utf-8") as f:
            f.write(payload)
    except OSError:
        pass



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


def gate_check(root):
    installer = os.path.join(root, "githooks", "install.sh")
    if not os.path.isfile(installer):
        return False, "githooks/install.sh is missing"
    r = subprocess.run(["bash", installer, "--check"], cwd=root,
                       capture_output=True, text=True)
    return r.returncode == 0, (r.stderr or r.stdout).strip()


# ── change-set plumbing ──────────────────────────────────────────────────────

def change_paths(root):
    """Every path the fix touches vs origin/development: pre-committed branch diff
    plus uncommitted tracked changes and untracked files."""
    paths = set()
    dev_rev = git(root, "rev-parse", "origin/development", check=False)
    if dev_rev.returncode == 0:
        d = git(root, "diff", "--name-only", "origin/development..HEAD", check=False).stdout
        for line in d.splitlines():
            line = line.strip().strip('"')
            if line:
                paths.add(line)
    porcelain = git(root, "status", "--porcelain=v1", "-uall", check=False).stdout
    for line in porcelain.splitlines():
        if not line.strip():
            continue
        p = line[3:].strip().strip('"')
        if " -> " in p:  # rename: take the destination
            p = p.split(" -> ")[1]
        paths.add(p)
    return sorted(paths)


def path_fingerprint(path):
    """Content identity for a qualified path, including untracked trees.

    The suite is arbitrary code. Comparing status paths alone cannot detect it
    rewriting an already-qualified file, so landing snapshots bytes and shape
    immediately before and after the suite runs.
    """
    if not os.path.lexists(path):
        return "missing"
    if os.path.islink(path):
        return "link:" + os.readlink(path)
    if os.path.isfile(path):
        digest = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                digest.update(chunk)
        return "file:" + digest.hexdigest()
    if os.path.isdir(path):
        digest = hashlib.sha256()
        for name in sorted(os.listdir(path)):
            child = os.path.join(path, name)
            digest.update(name.encode("utf-8", "surrogateescape"))
            digest.update(b"\0")
            digest.update(path_fingerprint(child).encode("utf-8", "surrogateescape"))
            digest.update(b"\0")
        return "dir:" + digest.hexdigest()
    st = os.lstat(path)
    return "other:%d:%d" % (st.st_mode, st.st_size)


def snapshot_paths(root, paths):
    return {p: path_fingerprint(os.path.join(root, p)) for p in paths}


def driver_projection_paths(root):
    paths = set(DRIVER_LEDGER)
    paths.update(p for p in RELEASES_PROJECTIONS if os.path.lexists(os.path.join(root, p)))
    return paths


def core_paths(paths):
    return [p for p in paths if not is_doc_path(p)]


def is_doc_path(p):
    """The lane's own paperwork never counts against the size bounds; every
    other path — including operator-supplied .md — counts (finding 5)."""
    return p == "CHANGELOG.md" or p.startswith("PROJECT/")


def insertions(root, paths, expect_driver=frozenset()):
    total = 0
    numstat = git(root, "diff", "origin/development", "--numstat", check=False).stdout
    tracked = {}
    for line in numstat.splitlines():
        parts = line.split("\t")
        if len(parts) == 3 and parts[0] != "-":
            tracked[parts[2]] = int(parts[0])
    for p in paths:
        if is_doc_path(p) or p in expect_driver:
            continue
        if p in tracked:
            total += tracked[p]
        elif os.path.isfile(os.path.join(root, p)):  # untracked new file
            with open(os.path.join(root, p), encoding="utf-8", errors="replace") as f:
                total += sum(1 for _ in f)
    return total


# ── step 0–3: check ──────────────────────────────────────────────────────────

def cmd_check(args, expect_driver=frozenset()):
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
    is_ancestor = git(root, "merge-base", "--is-ancestor", "origin/development", "HEAD", check=False)
    if is_ancestor.returncode != 0:
        refuse(root, "task-clone",
               "task branch is not based on origin/development — rebase onto origin/development",
               issue=args.issue)
    commit_count_res = git(root, "rev-list", "--count", "origin/development..HEAD", check=False)
    commit_count = int(commit_count_res.stdout.strip() or "0") if commit_count_res.returncode == 0 else 0
    if commit_count > 2:
        refuse(root, "too-many-commits",
               "the task branch carries %d commits ahead of origin/development (> 2 allowed); "
               "express lands small hotfixes with <= 2 local commits — route to normal PR lane" % commit_count,
               issue=args.issue)

    # Gate wiring is proven, not assumed (PR #270 review finding 3): hooks do
    # not travel with a clone, and an unwired push boundary would merge on the
    # focused suite alone.
    wired, detail = gate_check(root)
    if not wired:
        refuse(root, "gate-unwired",
               "`bash githooks/install.sh --check` did not prove the canonical gate stub; "
               "run `bash githooks/install.sh` first (GH-549: wiring is per clone): %s" % detail,
               issue=args.issue)

    paths = change_paths(root)
    if not paths:
        refuse(root, "empty", "no changes present — nothing to express", issue=args.issue)

    for p in paths:
        if p in DRIVER_LEDGER and p not in expect_driver:
            refuse(root, "ledger-hand-edit",
                   "%s is a releases-ledger artifact — never hand-edited (verbs only); only "
                   "the driver's own ledger phase may carry it" % p, issue=args.issue)
        if p in DRIVER_GENERATED and p not in expect_driver:
            refuse(root, "driver-output-hand-edit",
                   "%s is generated by releases/roadmap verbs; only the driver's own "
                   "projection refresh may carry it" % p, issue=args.issue)

    core = [p for p in paths if not is_doc_path(p) and p not in expect_driver]

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
    ins = insertions(root, paths, expect_driver)
    if ins > args.max_insertions:
        refuse(root, "too-large",
               "%d insertions > bound %d — route to the normal PR lane" % (ins, args.max_insertions),
               issue=args.issue)
    non_test = [p for p in core if not p.startswith("test/")]
    tops = {p.split("/")[0] for p in non_test}
    if len(tops) > 1:
        allow_multi = getattr(args, "allow_multi_subsystem", False)
        micro_diff = (len(core) <= 2 and ins <= 30)
        if not allow_multi and not micro_diff:
            refuse(root, "multi-subsystem",
                   "core paths span %s — express is single-subsystem by contract "
                   "(pass --allow-multi-subsystem or keep <= 30 insertions across <= 2 files)" % ", ".join(sorted(tops)),
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

    print("express-check%s: PASS" % (" [dry-run]" if getattr(args, "dry_run", False) else ""))
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
    if getattr(args, "dry_run", False):
        print("express-docs [dry-run]: would write capture doc %s (+ CHANGELOG entry)" % os.path.relpath(doc, root))
        return dict(doc=os.path.relpath(doc, root))
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

    if getattr(args, "dry_run", False):
        print("express-ledger [dry-run]: would park roadmap row and dial in manifest for GH-%d" % args.issue)
        return dict(release=args.release or "(active)")

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
        raw = ("- **GH-%d · %s** 🆕 rated 2/2/2/2 — [doc](%s) · [#%d](%s)" %
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
    # Under GH-496 Phase 2, generated views (LEADERBOARD.md, etc.) are decoupled
    # from task branches and owned exclusively by wave_reconcile on development upon landing.
    # Revert routine view writes caused by dial-in so task branch commits do not trip the guard.
    for view in ("LEADERBOARD.md", "LEADERBOARD.html", "RELEASES-PREVIEW.html"):
        git(root, "checkout", "origin/development", "--", view, check=False)
    print("express-ledger: dialed into %s" % rel)
    return dict(release=rel)


# ── steps 7–11: land + reconcile ─────────────────────────────────────────────

def args_repo():
    return os.environ.get("EXPRESS_REPO", "HiQS-Labs/XYZ-forge")


def cmd_land(args):
    root = args.root
    # `run` sets `_expect_driver` in-process; a bare `land` invocation never has
    # it (fresh argparse Namespace) and must recompute the same allowlist itself
    # so the documented four-step flow isn't refused for what its own earlier
    # `docs`/`ledger` steps wrote (GH-278 review finding — see expect_driver_paths).
    supplied = getattr(args, "_expect_driver", None)
    expect = set(supplied) if supplied is not None else expect_driver_paths(root, args.issue)
    state = cmd_check(args, expect_driver=expect)  # re-qualify at landing time
    suite = state["suite"]
    before_paths = set(state["paths"])
    before_content = snapshot_paths(root, before_paths)

    # Step 7 — the fix's own suite must be green right now.
    if getattr(args, "dry_run", False):
        print("express-land [dry-run]: would run suite %s" % suite)
    else:
        r = subprocess.run(["bash", os.path.join(root, suite)], cwd=root)
        if r.returncode != 0:
            refuse(root, "suite-red", "%s exited %d — no red suite rides the express lane" % (suite, r.returncode),
                   issue=args.issue)

        wired, detail = gate_check(root)
        if not wired:
            refuse(root, "gate-unwired",
                   "the suite changed or disabled the canonical pre-push gate: %s" % detail,
                   issue=args.issue)

    # TOCTOU close (PR #270 review finding 4): the suite just ran arbitrary
    # code — re-snapshot and require the tree to still be exactly the qualified
    # diff plus the driver's own projections, then stage ONLY those paths.
    after = set(change_paths(root))
    drift = sorted(before_paths ^ after)
    content_drift = sorted(p for p in before_paths & after
                           if before_content[p] != path_fingerprint(os.path.join(root, p)))
    drift.extend(p for p in content_drift if p not in drift)
    if drift:
        refuse(root, "tree-drift",
               "qualified paths or content changed after the suite ran (%s) — express stages "
               "exactly the bytes it qualified, nothing the suite generated" % ", ".join(drift),
               issue=args.issue)

    if getattr(args, "dry_run", False):
        print("express-land [dry-run]: PASS — would commit %s, push to origin/development, close issue #%d, and reconcile"
              % (", ".join(sorted(after)), args.issue))
        return dict(sha="dry-run", release=args.release or "(active)")

    # Step 8 — commit the one-motion change set (explicit pathspecs, never -A).
    git(root, "add", "--", *sorted(after))
    msg = ("fix(GH-%d): %s [express]\n\nExpress lane (GH-267): fix + suite + born-complete doc + "
           "CHANGELOG in one motion.\n\nCloses #%d\n" % (args.issue, state["title"], args.issue))
    git(root, "commit", "-m", msg)
    sha = git(root, "rev-parse", "HEAD").stdout.strip()
    git(root, "push", "origin", "HEAD:development")  # normal hook; NFF refuses safely

    # ── post-push closeout — from clean, current development (finding 2) ──
    try:
        # The task branch is done; ship/reconcile state must never ride it, and
        # wave_reconcile requires a clean development tree.
        git(root, "checkout", "-q", "development")
        git(root, "pull", "--ff-only", "origin", "development")
        dirty = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
        if dirty:
            die("development is not clean after pull — refusing closeout over: %s" %
                dirty.replace("\n", "; "))
        reached = git(root, "merge-base", "--is-ancestor", sha, "origin/development", check=False)
        if reached.returncode != 0:
            die("direct-pushed commit %s is not reachable from origin/development" % sha)
        closeout(root, args, sha, suite, state)
    except BaseException as exc:  # every post-push failure leaves a receipt
        if isinstance(exc, SystemExit):
            reason = "SystemExit(%s)" % exc.code
        else:
            reason = "%s: %s" % (type(exc).__name__, exc)
        write_tick(root, "express-reconcile-failed", issue=args.issue, commit=sha,
                   sha=sha, reason=reason[:300])
        sys.stderr.write("express-reconcile-failed: %s\n" % reason)
        if isinstance(exc, (SystemExit, KeyboardInterrupt)):
            raise
        sys.exit(EXIT_ENV)


def active_release(root):
    nxt = run_releases(root, "next").stdout
    mrel = re.search(r"gid=(rel-[0-9A-Z]+)", nxt)
    return mrel.group(1) if mrel else None


def closeout(root, args, sha, suite, state):
    """Steps 9–11 from development: ship, close, reconcile, PERSIST — fail closed.

    A downgraded failure here would leave a closed issue with an active doc and
    a remote manifest still dialed_in — the GH-205 trap with extra steps — so
    every fault exits non-zero with an express-reconcile-failed tick instead."""
    # Step 9 — ship with evidence (post-push, so sha + receipts exist).
    rel = args.release or active_release(root)
    if rel:
        iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "url"])
        url = json.loads(iv.stdout)["url"]
        run_releases(root, "manifest", "ship", url, "--gid", rel,
                     "--evidence", "%s; %s green in gate; direct development push (express)" % (sha, suite))

    # Step 10 — the default-branch commit says "Closes #N"; verify closure and
    # close explicitly if GitHub has not processed it.
    iv = gh(["issue", "view", str(args.issue), "-R", args.repo, "--json", "state"], check=False)
    if iv.returncode == 0 and json.loads(iv.stdout)["state"] != "CLOSED":
        gh(["issue", "close", str(args.issue), "-R", args.repo,
            "--comment", "Express hotfix landed directly on development: %s (suite %s green)" % (sha, suite)])

    # wave_reconcile refuses a dirty tree. Persist the ship transaction first,
    # then reconcile from the clean committed development state.
    persist_closeout(root,
                     "chore(releases): express ship GH-%d (commit %s)" %
                     (args.issue, sha[:12]))

    # Step 11 — reconcile the direct landing by commit identity. Failure is
    # fatal — never a stderr footnote.
    wr = os.path.join(root, "utils", "py", "wave_reconcile.py")
    if not os.path.isfile(wr):
        die("wave_reconcile.py missing under %s — cannot reconcile commit %s" % (root, sha))
    base = [sys.executable, wr, "--commit", sha, "--root", root]
    r = subprocess.run(base, cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        err = r.stderr or r.stdout
        die("reconcile FAILED for commit %s after the ship transaction was persisted. "
            "Fix and run `wave_reconcile.py --commit %s` on development:\n%s" %
            (sha, sha, err[-500:]))

    persist_closeout(root,
                     "chore(pdda): express reconcile GH-%d (commit %s)" %
                     (args.issue, sha[:12]))

    write_tick(root, "express-fired", issue=args.issue, sha=sha,
               suite=suite, release=rel, files=len(state["paths"]), insertions=state["insertions"])
    print("express-land: commit %s pushed to development, issue #%d closed, mfi shipped against %s, reconcile persisted"
          % (sha[:12], args.issue, rel or "(none)"))
    return dict(sha=sha, release=rel)


CLOSEOUT_ALLOWLIST_PREFIXES = (
    "PROJECT/2-WORKING/",
    "PROJECT/3-COMPLETED/",
    "PROJECT/4-MISC/",
    ".tick/",
)
CLOSEOUT_ALLOWLIST_FILES = {
    "releases.db",
    "releases.sql",
    "RELEASES-PREVIEW.html",
    "LEADERBOARD.html",
    "LEADERBOARD.md",
    "CHANGELOG.md",
}


def is_allowed_closeout_path(p):
    if p in CLOSEOUT_ALLOWLIST_FILES:
        return True
    for prefix in CLOSEOUT_ALLOWLIST_PREFIXES:
        if p.startswith(prefix):
            return True
    return False


def persist_closeout(root, message):
    """Persist one cleanly delimited closeout transaction."""
    paths = change_paths(root)
    if not paths:
        return False
    disallowed = [p for p in paths if not is_allowed_closeout_path(p)]
    if disallowed:
        die("refusing closeout persistence over unexpected dirty path(s): %s" % ", ".join(disallowed))
    git(root, "add", "--", *paths)
    git(root, "commit", "-m", message)
    git(root, "push", "origin", "development")
    return True


def capture_doc_path(root, issue):
    wd = os.path.join(root, "PROJECT", "2-WORKING")
    if os.path.isdir(wd):
        cands = sorted(p for p in os.listdir(wd) if p.startswith("GH-%d-" % issue))
        if cands:
            return "PROJECT/2-WORKING/" + cands[0]
    return None


def expect_driver_paths(root, issue):
    """Driver-written outputs express may already have produced for this issue:
    the capture doc (if born), the lane's CHANGELOG entry, and any adopted
    releases/roadmap projections. `run` computes this in-process before calling
    `cmd_land`; a standalone `land` invocation (SKILL.md's documented four-step
    form: check / docs / ledger / land, each its own process) has no other way
    to learn what an earlier standalone `docs`/`ledger` step wrote, so `cmd_land`
    falls back to recomputing the same set itself (GH-278 review finding)."""
    paths = {"CHANGELOG.md"} | driver_projection_paths(root)
    doc = capture_doc_path(root, issue)
    if doc:
        paths.add(doc)
    return paths


def commit_closes_issue(body, issue):
    """Check if commit message contains a closing reference for the exact issue number."""
    # Pattern 1: closing keyword followed by #issue or GH-issue with word boundaries
    p1 = rf"\b(?:closes?|closed|fix(?:es|ed)?|resolves?|resolved)[ \t]*:?[ \t]+(?:#|GH-){issue}\b"
    if re.search(p1, body, re.IGNORECASE):
        return True
    # Pattern 2: title trailer (#issue) or (GH-issue) with word boundaries
    p2 = rf"\([ \t]*(?:#|GH-){issue}\b[ \t]*\)"
    if re.search(p2, body, re.IGNORECASE):
        return True
    return False


def resolve_landing_commit(root, issue, explicit_sha=None):
    """Resolve and validate the exact landing commit for an issue on origin/development."""
    if explicit_sha:
        res = git(root, "rev-parse", "--verify", "%s^{commit}" % explicit_sha, check=False)
        if res.returncode != 0:
            die("Commit %s cannot be resolved locally" % explicit_sha)
        sha = res.stdout.strip()
        reached = git(root, "merge-base", "--is-ancestor", sha, "origin/development", check=False)
        if reached.returncode != 0:
            die("Commit %s is not reachable from origin/development (unpushed or local-only commit)" % sha[:12])
        body = git(root, "log", "-1", "--format=%B", sha, check=False).stdout
        if not commit_closes_issue(body, issue):
            die("Commit %s does not close issue #%d (missing closing reference in commit message)" % (sha[:12], issue))
        return sha

    # Auto-resolution from origin/development
    log_res = git(root, "log", "origin/development", "-n", "50", "--format=%H%x00%B%x00", check=False)
    if log_res.returncode != 0 or not log_res.stdout.strip():
        die("Could not read commit log from origin/development")

    entries = log_res.stdout.split("\x00\n")
    candidates = []
    ship_commit_sha_for_issue = None

    for entry in entries:
        if not entry.strip():
            continue
        parts = entry.split("\x00", 1)
        if len(parts) != 2:
            continue
        c_sha, c_body = parts[0].strip(), parts[1].strip()

        if commit_closes_issue(c_body, issue):
            candidates.append(c_sha)

        # Check for post-landing ship commit for this issue:
        # chore(releases): express ship GH-999 (commit 1234567890ab)
        m_ship = re.search(rf"^chore\(releases\):\s*express\s+ship\s+GH-{issue}\b.*\(commit\s+([0-9a-fA-F]+)\)",
                           c_body, re.MULTILINE)
        if m_ship and not ship_commit_sha_for_issue:
            ship_commit_sha_for_issue = m_ship.group(1)

    if candidates:
        landing_sha = candidates[0]
        print("express-resume: resolved landing commit %s for GH-%d" % (landing_sha[:12], issue))
        return landing_sha

    if ship_commit_sha_for_issue:
        res = git(root, "rev-parse", "--verify", "%s^{commit}" % ship_commit_sha_for_issue, check=False)
        if res.returncode == 0:
            s_sha = res.stdout.strip()
            reached = git(root, "merge-base", "--is-ancestor", s_sha, "origin/development", check=False)
            if reached.returncode == 0:
                s_body = git(root, "log", "-1", "--format=%B", s_sha, check=False).stdout
                if commit_closes_issue(s_body, issue):
                    print("express-resume: resolved landing commit %s cited in ship commit for GH-%d" %
                          (s_sha[:12], issue))
                    return s_sha

    die("Could not automatically resolve landing commit for GH-%d. Pass --sha <SHA> explicitly." % issue)


def check_manifest_state(root, issue, rel):
    """Safely query manifest state for an issue in a release without assuming schema existence."""
    db = os.path.join(root, "releases.db")
    if not os.path.isfile(db):
        return None
    try:
        conn = sqlite3.connect(db)
        try:
            cur = conn.cursor()
            tables = {row[0] for row in cur.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            if not {"manifest_items", "issue_refs", "releases"}.issubset(tables):
                return None
            row = cur.execute("""SELECT mi.state FROM manifest_items mi
                                 JOIN issue_refs ir ON ir.id = mi.issue_ref_id
                                 JOIN releases r ON r.id = mi.release_id
                                 WHERE r.global_id = ? AND (ir.url LIKE ? OR ir.url LIKE ?)
                                 ORDER BY mi.id DESC LIMIT 1""",
                              (rel, "%issues/" + str(issue), "%issues/" + str(issue) + "#%")).fetchone()
            return row[0] if row else None
        finally:
            conn.close()
    except Exception:
        return None


def cmd_resume(args):
    """Recover/resume an interrupted express run: ensure issue is closed, complete reconciliation,
    and persist/push remaining artifacts."""
    root = args.root
    issue = args.issue

    # 1. Check working tree cleanliness before doing ANY operations (regardless of branch)
    cur_branch = git(root, "branch", "--show-current", check=False).stdout.strip()
    dirty = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
    if dirty:
        die("working tree is not clean on %s — stash or discard before resuming: %s" %
            (cur_branch, dirty.replace("\n", "; ")))

    # 2. Resolve and validate the landing commit identity and reachability
    sha = resolve_landing_commit(root, issue, args.sha)

    if getattr(args, "dry_run", False):
        print("express-resume [dry-run]: would ensure issue #%d closed, reconcile commit %s, and persist/push" % (issue, sha[:12]))
        return dict(issue=issue, sha=sha)

    # 3. Switch to clean development checkout if on another branch
    if cur_branch != "development":
        git(root, "checkout", "-q", "development")
        git(root, "pull", "--ff-only", "origin", "development")
        dirty_after = git(root, "status", "--porcelain=v1", check=False).stdout.strip()
        if dirty_after:
            die("development is not clean after pull — refusing resume over: %s" %
                dirty_after.replace("\n", "; "))

    # 4. Check and close issue if still open
    iv = gh(["issue", "view", str(issue), "-R", args.repo, "--json", "state"], check=False)
    if iv.returncode == 0 and json.loads(iv.stdout).get("state") != "CLOSED":
        gh(["issue", "close", str(issue), "-R", args.repo,
            "--comment", "Express hotfix landed directly on development: %s (resumed closeout)" % sha])
        print("express-resume: closed issue #%d" % issue)

    # 5. Ship manifest item if still dialed_in
    rel = args.release or active_release(root)
    if rel:
        mstate = check_manifest_state(root, issue, rel)
        if mstate == "dialed_in":
            iv_url = gh(["issue", "view", str(issue), "-R", args.repo, "--json", "url"])
            url = json.loads(iv_url.stdout)["url"]
            run_releases(root, "manifest", "ship", url, "--gid", rel,
                         "--evidence", "%s; direct development push (express resume)" % sha)
            persist_closeout(root, "chore(releases): express ship GH-%d (commit %s)" % (issue, sha[:12]))
            print("express-resume: shipped manifest item for issue #%d against %s" % (issue, rel))
        elif mstate == "shipped":
            print("express-resume: manifest item already shipped for issue #%d against %s" % (issue, rel))

    # 6. Reconcile
    wr = os.path.join(root, "utils", "py", "wave_reconcile.py")
    if not os.path.isfile(wr):
        die("wave_reconcile.py missing under %s — cannot reconcile commit %s" % (root, sha))
    base = [sys.executable, wr, "--commit", sha, "--root", root]
    r = subprocess.run(base, cwd=root, capture_output=True, text=True)
    if r.returncode != 0:
        err = r.stderr or r.stdout
        die("reconcile FAILED for commit %s: %s" % (sha, err[-500:]))

    persisted = persist_closeout(root, "chore(pdda): express reconcile GH-%d (commit %s)" % (issue, sha[:12]))
    if persisted:
        print("express-resume: reconciliation committed and pushed for commit %s" % sha[:12])
    else:
        print("express-resume: reconciliation already clean for commit %s" % sha[:12])

    write_tick(root, "express-resumed", issue=issue, commit=sha)
    return dict(issue=issue, sha=sha)


def cmd_run(args):
    root = args.root
    cmd_check(args)  # first qualification: the operator's diff, nothing else
    cmd_docs(args)
    cmd_ledger(args)
    if getattr(args, "dry_run", False):
        args._expect_driver = set()
    else:
        doc = capture_doc_path(root, args.issue)
        if not doc:
            refuse(root, "no-doc", "express docs did not produce a capture doc", issue=args.issue)
        # Landing requalification must accept exactly what the driver itself wrote
        # (finding 1) — never a blanket exemption.
        args._expect_driver = expect_driver_paths(root, args.issue)
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
        p.add_argument("--allow-multi-subsystem", action="store_true", default=False,
                       help="permit core changes across multiple top-level directories")
        p.add_argument("--dry-run", action="store_true", default=False,
                       help="preview operations without modifying files or git state")

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

    p = sub.add_parser("land", help="steps 7-11: suite, direct development push, ship, close, reconcile")
    common(p)
    p.add_argument("--release")
    p.set_defaults(fn=cmd_land)

    p = sub.add_parser("resume", help="recover/resume an interrupted express landing and complete reconciliation")
    p.add_argument("--issue", type=int, required=True, help="GH issue number")
    p.add_argument("--sha", help="commit SHA landed on development (resolved from git log if omitted)")
    p.add_argument("--repo", default=args_repo())
    p.add_argument("--release", help="target release GID (defaults to active release)")
    p.add_argument("--dry-run", action="store_true", default=False, help="preview operations without modifying files or git state")
    p.set_defaults(fn=cmd_resume)

    p = sub.add_parser("run", help="the whole motion in order")
    common(p)
    p.add_argument("--release")
    p.add_argument("--doc-path")
    p.add_argument("--slug")
    p.add_argument("--summary")
    p.set_defaults(fn=cmd_run)

    args = ap.parse_args()
    if getattr(args, "suite", None) is None and args.cmd in ("check", "land", "run"):
        ap.error("--suite is required for %s (a hotfix without its regression suite is a claim, not a fix)" % args.cmd)
    args.fn(args)


if __name__ == "__main__":
    main()
