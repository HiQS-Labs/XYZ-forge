#!/usr/bin/env python3
"""prs_backfill.py — deterministic half of the PRS rating backfiller (GH-1175).

Keeps the four-axis PRS ratings (`pri/sev/appeal/effort`, 1–100) complete on registered
roadmap rows WITHOUT becoming a second scorer or a second writer:

  scan       read-only inventory of open issues vs `releases.db`; writes bounded rating
             packets for the selected rows (the only GitHub reads that fetch comments)
  validate   checks the agent's proposals against the rating rules and freezes an
             approvable plan with a content hash
  apply      writes ONLY through `releases roadmap rate` (never --force, never --ovr), with
             a fresh-issue check before every write and a read-back after it
  comment    posts the dated rationale on issues whose rating was applied without
             `--post-rationale`; same plan approval, one receipt per attempt, re-runnable
  calibrate  E0: compares blind proposals for already-rated rows against the ledger; no writes
  status     summary of the last scan, open plans and receipts

The judgment (the four scores and their rationale) is made by the agent running the
`prs-backfill` skill and confirmed by an independent reviewer. This script never invents a
score: it builds the evidence packet, enforces the rules, binds the operator's approval to
the exact plan, and records provenance.

Registration is NOT done here. A row needs a capture doc (`roadmap add --doc-path`) and the
capture template belongs to HQ / weekly-prepare (#1022). Unregistered issues are reported, not
parked.

State lives under `<root>/.tick/prs-backfill/` (gitignored):
  runs/<run_id>/scan.json | packets/GH-N.json | proposals.json | plan.json | calibration.json
  receipts.jsonl   append-only provenance: applied / held / skipped / write-failed / commented /
                   calibration
  lock             single-instance flock

Exit codes: 0 ok · 2 usage · 3 refused (incl. `apply` stopped on a failed write, `comment` on a
            failed post) ·
            4 disabled (PRS_BACKFILL_DISABLE=1) · 5 busy
"""
import argparse
import datetime
import fcntl
import glob
import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys

POLICY_VERSION = "prs-backfill/1"
SELF_DIR = os.path.dirname(os.path.realpath(__file__))
RELEASES_APP = os.path.join(SELF_DIR, "releases_app.py")

EXIT_OK, EXIT_USAGE, EXIT_REFUSED, EXIT_DISABLED, EXIT_BUSY = 0, 2, 3, 4, 5

BODY_MAX = 6000          # chars of issue body in a packet
COMMENT_MAX = 1000       # chars per comment
COMMENTS_KEPT = 10       # most recent comments in a packet
DOC_MAX = 4000           # chars of capture doc excerpt
RATIONALE_MAX = 1200     # chars across the three rationale fields
DEFAULT_LIMIT = 20       # packets per scan: the per-wake model budget
APPEAL_NEUTRAL = 50
SEV_BANDS = ((1, 39, "low"), (40, 79, "mid"), (80, 100, "high"))
AXES = ("pri", "sev", "appeal", "effort")


# ── small helpers ───────────────────────────────────────────────────────────────────────────────

def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def die(code, reason, msg):
    print("prs-backfill: REFUSED %s: %s" % (reason, msg), file=sys.stderr)
    sys.exit(code)


def canon(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha256(obj):
    return hashlib.sha256(canon(obj).encode("utf-8")).hexdigest()


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2, ensure_ascii=False, sort_keys=True)
        fh.write("\n")
    os.replace(tmp, path)


def read_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def sev_band(v):
    for lo, hi, name in SEV_BANDS:
        if lo <= v <= hi:
            return name
    return "invalid"


# ── roots, repo, state ──────────────────────────────────────────────────────────────────────────

def resolve_root(arg):
    """--root > $PRS_BACKFILL_ROOT > git toplevel of CWD > CWD (GH-344: never the harness's own
    location — a vendored install rates the repo it is run in, not the harness clone)."""
    if arg:
        return os.path.realpath(arg)
    env = os.environ.get("PRS_BACKFILL_ROOT")
    if env:
        return os.path.realpath(env)
    try:
        top = subprocess.check_output(["git", "rev-parse", "--show-toplevel"],
                                      stderr=subprocess.DEVNULL, text=True).strip()
        if top:
            return os.path.realpath(top)
    except Exception:
        pass
    return os.path.realpath(os.getcwd())


def resolve_slug(root, arg):
    if arg:
        return arg
    try:
        sys.path.insert(0, SELF_DIR)
        from harness_paths import github_slug_from_origin  # noqa: E402
        slug = github_slug_from_origin(root)
    except Exception:
        slug = None
    if not slug:
        die(EXIT_USAGE, "no-repo", "cannot resolve <org>/<repo> from origin; pass --repo")
    return slug


def state_dir(root):
    return os.path.join(root, ".tick", "prs-backfill")


def db_path(root):
    return os.path.join(root, "releases.db")


class Lock:
    def __init__(self, root):
        os.makedirs(state_dir(root), exist_ok=True)
        self.path = os.path.join(state_dir(root), "lock")
        self.fh = None

    def __enter__(self):
        # "a+", and truncate only AFTER the flock is ours: opening with "w" would wipe the
        # holder's pid before the contender finds out it lost (same shape as WriterLock).
        self.fh = open(self.path, "a+")
        try:
            fcntl.flock(self.fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self.fh.close()
            die(EXIT_BUSY, "busy", "another prs-backfill holds %s" % self.path)
        self.fh.seek(0)
        self.fh.truncate()
        self.fh.write(str(os.getpid()))
        self.fh.flush()
        return self

    def __exit__(self, *exc):
        fcntl.flock(self.fh, fcntl.LOCK_UN)
        self.fh.close()


def check_disabled():
    if os.environ.get("PRS_BACKFILL_DISABLE") == "1":
        die(EXIT_DISABLED, "disabled", "PRS_BACKFILL_DISABLE=1 (kill switch)")


# ── GitHub (gh CLI) ─────────────────────────────────────────────────────────────────────────────

def gh_json(args, timeout=180):
    try:
        out = subprocess.run(["gh"] + args, capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        die(EXIT_USAGE, "no-gh", "gh CLI not found on PATH")
    except subprocess.TimeoutExpired:
        die(EXIT_REFUSED, "gh-timeout", "gh %s timed out" % " ".join(args[:3]))
    if out.returncode != 0:
        die(EXIT_REFUSED, "gh-failed", "gh %s: %s" % (" ".join(args[:3]), out.stderr.strip()[:400]))
    return json.loads(out.stdout or "null")


def list_open_issues(slug, max_issues):
    # One paginated list call for the whole inventory; comments are fetched only per packet.
    return gh_json(["issue", "list", "-R", slug, "--state", "open", "--limit", str(max_issues),
                    "--json", "number,title,labels,createdAt,updatedAt,url"])


def view_issue(slug, number):
    return gh_json(["issue", "view", str(number), "-R", slug, "--json",
                    "number,title,body,labels,state,createdAt,updatedAt,url,comments"])


def content_hash(issue):
    """What the rating was judged against: title, body, labels, comments. updatedAt alone moves
    on label churn by bots, so freshness is decided on content."""
    return sha256({
        "title": issue.get("title") or "",
        "body": issue.get("body") or "",
        "labels": sorted(l.get("name", "") for l in issue.get("labels") or []),
        "comments": [((c.get("author") or {}).get("login", ""), c.get("createdAt", ""),
                      c.get("body") or "") for c in issue.get("comments") or []],
    })


# ── ledger (read-only) ──────────────────────────────────────────────────────────────────────────

def open_ledger_ro(root):
    p = db_path(root)
    if not os.path.exists(p):
        die(EXIT_REFUSED, "no-ledger", "%s not found (a releases-mode repo is required)" % p)
    conn = sqlite3.connect("file:%s?mode=ro" % p, uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def ledger_rows(conn):
    """{gh_number: [row dict, ...]} in one query. Refuses a ledger without rating columns."""
    cols = {r[1] for r in conn.execute("PRAGMA table_info(roadmap_items)")}
    if not cols:
        die(EXIT_REFUSED, "no-ledger", "roadmap_items table missing; run `releases migrate`")
    if "rating_pri" not in cols:
        die(EXIT_REFUSED, "schema-behind", "no rating columns; run `releases migrate` first")
    want = ["global_id", "gh_number", "title", "doc_path", "rating_pri", "rating_sev",
            "rating_appeal", "rating_effort", "rating_ovr"]
    legacy = [c for c in ("complexity", "risk", "effort") if c in cols]
    q = "SELECT %s FROM roadmap_items WHERE gh_number IS NOT NULL" % ", ".join(want + legacy)
    out = {}
    for r in conn.execute(q):
        d = dict(r)
        d["legacy"] = any(d.get(c) is not None for c in legacy)
        out.setdefault(int(d["gh_number"]), []).append(d)
    return out


def doc_index(root):
    """{issue_number: [relpath, ...]} for PROJECT/**/GH-N-*.md, built in one pass."""
    idx = {}
    for p in glob.glob(os.path.join(root, "PROJECT", "**", "GH-*.md"), recursive=True):
        m = re.match(r"GH-(\d+)\b", os.path.basename(p))
        if m:
            idx.setdefault(int(m.group(1)), []).append(os.path.relpath(p, root))
    return idx


# ── receipts ────────────────────────────────────────────────────────────────────────────────────

def receipts_path(root):
    return os.path.join(state_dir(root), "receipts.jsonl")


def append_receipt(root, rec):
    rec = dict(rec, ts=now_iso(), policy=POLICY_VERSION)
    os.makedirs(state_dir(root), exist_ok=True)
    with open(receipts_path(root), "a", encoding="utf-8") as fh:
        fh.write(canon(rec) + "\n")
        fh.flush()
        os.fsync(fh.fileno())


def load_receipts(root):
    p = receipts_path(root)
    if not os.path.exists(p):
        return []
    out = []
    with open(p, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                try:
                    out.append(json.loads(line))
                except ValueError:
                    continue   # a torn last line never blocks a run
    return out


def latest_by_issue(receipts, types):
    last = {}
    for r in receipts:
        if r.get("type") in types and r.get("issue") is not None:
            last[int(r["issue"])] = r
    return last


# ── scan ────────────────────────────────────────────────────────────────────────────────────────

def classify(issue, rows, docs):
    n = issue["number"]
    if not rows:
        return "unregistered-with-doc" if docs.get(n) else "unregistered"
    if len(rows) > 1:
        return "ambiguous-row"
    r = rows[0]
    if r["legacy"] and r["rating_pri"] is None:
        return "legacy-vocabulary"
    if r["rating_pri"] is None:
        return "unrated"
    return "rated-ovr" if r["rating_ovr"] is not None else "rated"


def build_packet(slug, root, row, live, mode):
    doc_excerpt, doc_path = None, row.get("doc_path")
    if doc_path:
        full = os.path.join(root, doc_path)
        if os.path.isfile(full):
            with open(full, encoding="utf-8", errors="replace") as fh:
                doc_excerpt = strip_rating_lines(fh.read(DOC_MAX))
    comments = (live.get("comments") or [])[-COMMENTS_KEPT:]
    # E0 only: the issue body and comments are the OTHER channel the answer travels in — this
    # tool's own `--post-rationale` comment carries the exact `rated N/N/N/N` token (Codex QA
    # round 2). Backfill/changed packets keep them verbatim: the row is unrated, and a filer's
    # suggested score is operator input the rater should see and weigh, not an answer key.
    blind = (lambda t: strip_rating_lines(t)) if mode == "calibrate" else (lambda t: t)
    packet = {
        "schema": "prs-backfill/packet@1",
        "mode": mode,
        "issue": live["number"],
        "repo": slug,
        "url": live.get("url"),
        "title": live.get("title"),
        "labels": sorted(l.get("name", "") for l in live.get("labels") or []),
        "created_at": live.get("createdAt"),
        "updated_at": live.get("updatedAt"),
        "body": blind((live.get("body") or "")[:BODY_MAX]),
        "body_truncated": len(live.get("body") or "") > BODY_MAX,
        "comments": [{"author": (c.get("author") or {}).get("login"),
                      "created_at": c.get("createdAt"),
                      "body": blind((c.get("body") or "")[:COMMENT_MAX])} for c in comments],
        "comments_total": len(live.get("comments") or []),
        "doc_path": doc_path,
        "doc_excerpt": doc_excerpt,
        "row_gid": row.get("global_id"),
        "content_hash": content_hash(live),
    }
    # E0 is blind by construction: no packet ever carries the row's existing scores.
    return packet


_RATING_LINE = re.compile(r"^\s*rating:.*$", re.MULTILINE)
# The same answer in prose: the ledger token `rated 55/25/50/40 [ovr N]` and the long form
# `pri/sev/appeal/effort 55/25/50/40` (both verbatim in real capture docs — GH-589:44, GH-579:66).
_RATING_TOKEN = re.compile(
    r"(\brated\s+\d{1,3}/\d{1,3}/\d{1,3}/\d{1,3}(?:\s*\[?\s*ovr\s+\d{1,3}\s*\]?)?"
    r"|\bpri/sev/appeal/effort\s+\d{1,3}/\d{1,3}/\d{1,3}/\d{1,3})", re.IGNORECASE)


def strip_rating_lines(text):
    """A capture doc carries its PRS answer in two serializations: the frontmatter line
    `rating: "pri/sev/appeal/effort N/N/N/N"` and prose tokens `rated N/N/N/N`. Left in the
    packet either one anchors the rater and makes E0 "blind" a fiction (first E0 pass: 3 of 15
    packets via frontmatter; Codex QA round 1: GH-589 / GH-579 via prose). Both are withheld. The
    PDDA trio (effort/complexity/risk, 1–5) stays: a different vocabulary the policy already
    forbids copying, and the rater should see what the doc claims."""
    if not text:
        return text
    text = _RATING_LINE.sub("rating: [withheld from the rater]", text)
    return _RATING_TOKEN.sub("[rating withheld]", text)


def is_placeholder_rating(row):
    """A row whose four axes are all <=5 carries the PDDA 1–5 trio mis-stored as PRS 1–100; a
    row at exactly 50/50/50/50 is an intake default nobody judged. Neither is ground truth for
    E0 (found 13 + 47 such rows in the 2026-10-21 ledger), so calibration never samples them."""
    v = [row["rating_pri"], row["rating_sev"], row["rating_appeal"], row["rating_effort"]]
    return all(x is not None and x <= 5 for x in v) or v == [50, 50, 50, 50]


def select_calibration(rated, n, seed):
    """Deterministic stratified sample across sev bands, ovr rows excluded (the ovr replaces the
    rank, so it says nothing about the axes) and placeholder rows excluded (they are not
    judgments to agree with)."""
    bands = {}
    for num, row in rated.items():
        if is_placeholder_rating(row):
            continue
        bands.setdefault(sev_band(row["rating_sev"]), []).append(num)
    for b in bands:
        bands[b].sort(key=lambda x: hashlib.sha256(("%s:%d" % (seed, x)).encode()).hexdigest())
    picked, order = [], [b for _, _, b in reversed(SEV_BANDS) if b in bands]
    while len(picked) < n and any(bands[b] for b in order):
        for b in order:
            if bands[b] and len(picked) < n:
                picked.append(bands[b].pop(0))
    return picked


def cmd_scan(a):
    check_disabled()
    root, slug = resolve_root(a.root), resolve_slug(resolve_root(a.root), a.repo)
    with Lock(root):
        issues = list_open_issues(slug, a.max_issues)
        conn = open_ledger_ro(root)
        try:
            rows = ledger_rows(conn)
        finally:
            conn.close()
        docs = doc_index(root)
        receipts = load_receipts(root)
        # Only JUDGMENT holds suppress re-selection (low confidence, reviewer disagreed, bad
        # proposal): the evidence has not changed, so a second model call buys nothing. A
        # `write-failed` receipt is an infrastructure failure (locked ledger, writer crash) and
        # must NOT hide the issue from the next scan.
        held = latest_by_issue(receipts, {"held"})
        applied = latest_by_issue(receipts, {"applied"})

        inventory, by_state = [], {}
        for it in issues:
            st = classify(it, rows.get(it["number"]), docs)
            by_state.setdefault(st, []).append(it["number"])
            inventory.append({"issue": it["number"], "state": st, "updated_at": it["updatedAt"]})

        # STALE is report-only: a row this tool rated whose issue moved since. Re-scoring needs
        # the operator's deliberate --force path, never this script. `updatedAt` is only the
        # cheap pre-filter (it moves on bot label churn, see content_hash); a candidate is
        # confirmed stale only when the CONTENT hash the rating was judged against differs.
        updated = {i["issue"]: i["updated_at"] for i in inventory}
        stale = []
        for n in sorted(by_state.get("rated", []) + by_state.get("rated-ovr", [])):
            if n in applied and updated[n] > applied[n]["issue_updated_at"]:
                if content_hash(view_issue(slug, n)) != applied[n].get("content_hash"):
                    stale.append(n)
        if a.mode == "calibrate":
            rated = {n: rows[n][0] for n in by_state.get("rated", [])}
            selected = select_calibration(rated, a.limit, a.seed)
        else:
            cands = list(by_state.get("unrated", []))
            # Never spend a model call twice on unchanged evidence: skip an issue held on the
            # same updatedAt it still has.
            # --include-held is the operator's deliberate re-rate of a judgment hold (a reviewer
            # disagreed, the rater re-scores); a scheduled pass never passes it.
            if not a.include_held:
                cands = [n for n in cands if not (n in held and held[n].get("issue_updated_at")
                                                  == updated[n])]
            if a.mode == "changed":
                cands.sort(key=lambda n: updated[n], reverse=True)
            else:
                cands.sort()
            selected = cands[:a.limit]

        run_id = "%s-%s" % (datetime.datetime.now(datetime.timezone.utc)
                            .strftime("%Y%m%dT%H%M%SZ"), a.mode)
        run_dir = os.path.join(state_dir(root), "runs", run_id)
        for n in selected:
            live = view_issue(slug, n)
            write_json(os.path.join(run_dir, "packets", "GH-%d.json" % n),
                       build_packet(slug, root, rows[n][0], live, a.mode))

        template = [{"issue": n, "pri": None, "sev": None, "appeal": APPEAL_NEUTRAL,
                     "effort": None, "confidence": None,
                     "rationale": {"consequence": "", "recurrence": "", "uncertainty": ""},
                     "rater": {"agent": "", "model": ""},
                     "review": {"agent": "", "model": "", "verdict": "", "notes": ""},
                     "hold": None} for n in selected]
        counts = {k: len(v) for k, v in sorted(by_state.items())}
        scan = {"schema": "prs-backfill/scan@1", "run_id": run_id, "mode": a.mode,
                "repo": slug, "root": root, "scanned_at": now_iso(), "policy": POLICY_VERSION,
                "open_issues": len(issues), "counts": counts, "selected": selected,
                "stale_report": stale,
                "unregistered": sorted(by_state.get("unregistered", [])),
                "holds_by_state": {k: sorted(v) for k, v in by_state.items()
                                   if k in ("ambiguous-row", "legacy-vocabulary",
                                            "unregistered-with-doc")}}
        write_json(os.path.join(run_dir, "scan.json"), scan)
        write_json(os.path.join(run_dir, "proposals.template.json"), template)

    print("run %s  (%s, %s)" % (run_id, slug, a.mode))
    print("open issues: %d" % len(issues))
    for k, v in counts.items():
        print("  %-22s %d" % (k, v))
    print("selected for packets: %d (limit %d)" % (len(selected), a.limit))
    if stale:
        print("stale (report only): %s" % ", ".join("#%d" % n for n in stale))
    print("next: write %s/proposals.json from proposals.template.json" % run_dir)
    return EXIT_OK


# ── validate ────────────────────────────────────────────────────────────────────────────────────

def load_run(root, run_id):
    run_dir = os.path.join(state_dir(root), "runs", run_id)
    if not os.path.isdir(run_dir):
        die(EXIT_USAGE, "no-run", "no run %s under %s" % (run_id, state_dir(root)))
    scan = read_json(os.path.join(run_dir, "scan.json"))
    packets = {}
    for p in glob.glob(os.path.join(run_dir, "packets", "GH-*.json")):
        pk = read_json(p)
        packets[int(pk["issue"])] = pk
    prop_path = os.path.join(run_dir, "proposals.json")
    if not os.path.exists(prop_path):
        die(EXIT_USAGE, "no-proposals", "%s missing" % prop_path)
    proposals = read_json(prop_path)
    if not isinstance(proposals, list):
        die(EXIT_USAGE, "bad-proposals", "proposals.json must be a JSON list")
    return run_dir, scan, packets, proposals


def check_proposal(p, appeal_map, require_review):
    """Return (rated_string, None) or (None, hold_reason). Every rule is the published policy,
    not a new one: start-task "Task rating policy" + #522 independent review."""
    if p.get("hold"):
        return None, "rater-hold: %s" % str(p["hold"])[:200]
    vals = {}
    for ax in AXES:
        v = p.get(ax)
        if not isinstance(v, int) or isinstance(v, bool) or not 1 <= v <= 100:
            return None, "invalid-%s" % ax
        vals[ax] = v
    n = int(p["issue"])
    want_appeal = appeal_map.get(str(n), appeal_map.get(n, APPEAL_NEUTRAL))
    if vals["appeal"] != want_appeal:
        return None, "appeal-must-be-%d" % want_appeal
    rat = p.get("rationale") or {}
    parts = [str(rat.get(k) or "").strip() for k in ("consequence", "recurrence", "uncertainty")]
    if not all(parts):
        return None, "rationale-incomplete"
    if sum(len(x) for x in parts) > RATIONALE_MAX:
        return None, "rationale-too-long"
    if p.get("confidence") not in ("high", "medium", "low"):
        return None, "confidence-missing"
    if p["confidence"] == "low":
        return None, "low-confidence"
    rater = (p.get("rater") or {})
    if not rater.get("agent") or not rater.get("model"):
        return None, "rater-identity-missing"
    if require_review:
        rv = p.get("review") or {}
        if not rv.get("agent") or not rv.get("model"):
            return None, "review-missing"
        if (rv["agent"], rv["model"]) == (rater["agent"], rater["model"]):
            return None, "reviewer-not-independent"
        if rv.get("verdict") != "agree":
            return None, "review-%s" % (rv.get("verdict") or "missing")
    return "/".join(str(vals[ax]) for ax in AXES), None


def cmd_validate(a):
    check_disabled()
    root = resolve_root(a.root)
    with Lock(root):
        run_dir, scan, packets, proposals = load_run(root, a.run)
        if scan["mode"] == "calibrate":
            die(EXIT_USAGE, "calibrate-run", "calibration runs never write; use `calibrate`")
        appeal_map = read_json(a.appeal_map) if a.appeal_map else {}
        seen, items, holds = set(), [], []
        for p in proposals:
            n = int(p.get("issue", -1))
            if n not in packets:
                holds.append({"issue": n, "reason": "not-in-run"})
                continue
            if n in seen:
                holds.append({"issue": n, "reason": "duplicate-proposal"})
                continue
            seen.add(n)
            rated, reason = check_proposal(p, appeal_map, not a.no_review)
            if reason:
                holds.append({"issue": n, "reason": reason})
                append_receipt(root, {"type": "held", "stage": "validate", "run_id": a.run,
                                      "issue": n, "reason": reason,
                                      "issue_updated_at": packets[n]["updated_at"],
                                      "content_hash": packets[n]["content_hash"]})
                continue
            items.append({"issue": n, "rated": rated, "row_gid": packets[n]["row_gid"],
                          "content_hash": packets[n]["content_hash"],
                          "issue_updated_at": packets[n]["updated_at"],
                          "confidence": p["confidence"], "rationale": p["rationale"],
                          "rater": p["rater"], "review": p.get("review")})
        for n in sorted(set(packets) - seen):
            holds.append({"issue": n, "reason": "no-proposal"})
        items.sort(key=lambda x: x["issue"])
        plan_sha = sha256(items)
        write_json(os.path.join(run_dir, "plan.json"),
                   {"schema": "prs-backfill/plan@1", "run_id": a.run, "repo": scan["repo"],
                    "policy": POLICY_VERSION, "created_at": now_iso(), "plan_sha": plan_sha,
                    "review_required": not a.no_review, "items": items, "holds": holds})

    print("plan %s  run %s" % (plan_sha[:12], a.run))
    for it in items:
        print("  GH-%-5d rated %-13s %s" % (it["issue"], it["rated"], it["confidence"]))
    for h in holds:
        print("  GH-%-5s HOLD  %s" % (h["issue"], h["reason"]))
    if items:
        print("approve: prs_backfill.py apply --run %s --approve %s [--dry-run]"
              % (a.run, plan_sha[:12]))
    return EXIT_OK


# ── apply ───────────────────────────────────────────────────────────────────────────────────────

def run_rate(root, issue, rated, dry_run):
    # The ONE writer. No --force (an already-rated refusal is final here) and no --ovr (new rank
    # overrides are the operator's choice, never this tool's).
    cmd = [sys.executable, RELEASES_APP, "--root", root, "roadmap", "rate",
           "--issue-num", str(issue), "--rated", rated]
    if dry_run:
        cmd.append("--dry-run")
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        # A hung writer is a failed write, not a crash: it must reach the `write-failed` receipt
        # and the exit-3 stop like any other rc != 0 (Codex QA round 1, F2).
        return cmd, -1, "roadmap rate timed out after 120s; run `releases check`"
    return cmd, p.returncode, (p.stdout + p.stderr).strip()[-600:]


def rationale_body(item, plan_sha):
    r = item["rationale"]
    return ("**PRS rating** `rated %s` (pri/sev/appeal/effort) — %s\n\n"
            "- Consequence: %s\n- Recurrence: %s\n- Uncertainty: %s\n\n"
            "Rater: %s/%s · reviewer: %s/%s · plan `%s` · `%s`"
            % (item["rated"], now_iso()[:10], r["consequence"], r["recurrence"],
               r["uncertainty"], item["rater"]["agent"], item["rater"]["model"],
               (item.get("review") or {}).get("agent", "-"),
               (item.get("review") or {}).get("model", "-"), plan_sha[:12], POLICY_VERSION))


def post_rationale(slug, item, plan_sha):
    body = rationale_body(item, plan_sha)
    try:
        p = subprocess.run(["gh", "issue", "comment", str(item["issue"]), "-R", slug,
                            "--body", body], capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return False   # the rating is already written and read back; a lost comment is reported, never fatal
    return p.returncode == 0


def load_approved_plan(root, run, approve):
    """(plan, plan_sha) for a run, refusing a tampered plan or an --approve that does not name it."""
    plan_file = os.path.join(state_dir(root), "runs", run, "plan.json")
    if not os.path.exists(plan_file):
        die(EXIT_USAGE, "no-plan", "run `validate --run %s` first" % run)
    plan = read_json(plan_file)
    real_sha = sha256(plan["items"])
    if real_sha != plan["plan_sha"]:
        die(EXIT_REFUSED, "plan-tampered", "plan.json items no longer match plan_sha")
    if len(approve) < 12 or not real_sha.startswith(approve.lower()):
        die(EXIT_REFUSED, "approval-mismatch",
            "--approve %s does not name plan %s" % (approve, real_sha[:12]))
    return plan, real_sha


def cmd_apply(a):
    check_disabled()
    root = resolve_root(a.root)
    with Lock(root):
        plan, real_sha = load_approved_plan(root, a.run, a.approve)
        slug = resolve_slug(root, a.repo or plan.get("repo"))
        done = {int(r["issue"]) for r in load_receipts(root)
                if r.get("type") == "applied" and r.get("plan_sha") == real_sha}
        writes, failed = 0, False
        tally = {"applied": 0, "held": 0, "skipped": 0, "dry-run": 0, "write-failed": 0}
        for it in plan["items"]:
            n = it["issue"]
            base = {"run_id": a.run, "plan_sha": real_sha, "issue": n, "rated": it["rated"],
                    "issue_updated_at": it["issue_updated_at"],
                    "content_hash": it["content_hash"], "rater": it["rater"],
                    "review": it.get("review"), "rationale": it["rationale"],
                    "confidence": it["confidence"]}
            if n in done:
                tally["skipped"] += 1
                continue
            if writes >= a.max_writes:
                print("  GH-%-5d deferred (max-writes %d)" % (n, a.max_writes))
                continue
            live = view_issue(slug, n)
            if (live.get("state") or "").upper() != "OPEN":
                reason = "closed-since-scan"
            elif content_hash(live) != it["content_hash"]:
                reason = "changed-since-scan"
            else:
                conn = open_ledger_ro(root)
                try:
                    rows = ledger_rows(conn).get(n, [])
                finally:
                    conn.close()
                if len(rows) != 1:
                    reason = "ambiguous-row" if rows else "row-missing"
                elif rows[0]["rating_pri"] is not None:
                    reason = "already-rated"
                elif rows[0]["legacy"]:
                    reason = "legacy-vocabulary"
                else:
                    reason = None
            if reason:
                kind = "skipped" if reason == "already-rated" else "held"
                tally[kind] += 1
                print("  GH-%-5d %s %s" % (n, kind.upper(), reason))
                if not a.dry_run:
                    # The receipt keeps the SCAN-time `issue_updated_at` (in `base`): this hold is
                    # a judgment about the version the rater saw, not about the live one. Stamping
                    # the live timestamp here made `scan` treat the edited issue as already judged
                    # and never re-select it (Codex QA round 1, F3).
                    append_receipt(root, dict(base, type=kind, stage="apply", reason=reason,
                                              live_updated_at=live.get("updatedAt")))
                continue

            cmd, rc, out = run_rate(root, n, it["rated"], a.dry_run)
            if a.dry_run:
                tally["dry-run"] += 1
                print("  GH-%-5d dry-run rc=%d %s" % (n, rc, out.splitlines()[-1] if out else ""))
                continue
            writes += 1
            readback_ok = False
            if rc == 0:
                conn = open_ledger_ro(root)
                try:
                    row = ledger_rows(conn)[n][0]
                finally:
                    conn.close()
                got = "/".join(str(row[c]) for c in ("rating_pri", "rating_sev",
                                                     "rating_appeal", "rating_effort"))
                readback_ok = got == it["rated"] and row["rating_ovr"] is None
            ok = rc == 0 and readback_ok
            # The public comment is the LAST step and only follows a verified write: a comment
            # on an issue whose row was never written would be a rating that exists nowhere.
            commented = post_rationale(slug, it, real_sha) if (ok and a.post_rationale) else False
            kind = "applied" if ok else "write-failed"
            tally[kind] += 1
            append_receipt(root, dict(base, type=kind, stage="apply", writer_rc=rc,
                                      writer_out=out, readback_ok=readback_ok,
                                      commented=commented,
                                      reason=None if ok else "writer-or-readback"))
            print("  GH-%-5d %s rated %s rc=%d readback=%s"
                  % (n, kind.upper(), it["rated"], rc, readback_ok))
            if not ok:
                failed = True
                print("prs-backfill: stopping after a failed write; run `releases check`",
                      file=sys.stderr)
                break
    print("summary: %s" % ", ".join("%s %d" % kv for kv in tally.items()))
    # A caller (a scheduled E2 pass most of all) must be able to tell "stopped on a failed
    # ledger write" from "done": exit 0 after a failure is a lie.
    return EXIT_REFUSED if failed else EXIT_OK


# ── comment ─────────────────────────────────────────────────────────────────────────────────────

def cmd_comment(a):
    """Posts the rationale for ratings applied WITHOUT `--post-rationale` (`apply` skips applied
    rows, so it cannot be re-run for them). Eligible: the latest `applied` receipt for the issue
    under this plan, not already commented, and the ledger still holding exactly that rating."""
    check_disabled()
    root = resolve_root(a.root)
    with Lock(root):
        plan, real_sha = load_approved_plan(root, a.run, a.approve)
        slug = resolve_slug(root, a.repo or plan.get("repo"))
        receipts = [r for r in load_receipts(root) if r.get("plan_sha") == real_sha]
        applied = latest_by_issue(receipts, {"applied"})
        commented = {int(r["issue"]) for r in receipts
                     if r.get("type") == "commented" and r.get("ok")}
        posts, failed = 0, False
        tally = {"commented": 0, "dry-run": 0, "skipped": 0, "held": 0, "failed": 0}
        for it in plan["items"]:
            n = it["issue"]
            if n not in applied:
                tally["skipped"] += 1
                print("  GH-%-5d SKIPPED not-applied" % n)
                continue
            if applied[n].get("commented") or n in commented:
                tally["skipped"] += 1
                print("  GH-%-5d SKIPPED already-commented" % n)
                continue
            if posts >= a.max_comments:
                print("  GH-%-5d deferred (max-comments %d)" % (n, a.max_comments))
                continue
            conn = open_ledger_ro(root)
            try:
                rows = ledger_rows(conn).get(n, [])
            finally:
                conn.close()
            got = ("/".join(str(rows[0][c]) for c in ("rating_pri", "rating_sev",
                                                      "rating_appeal", "rating_effort"))
                   if len(rows) == 1 else None)
            # Never comment a score the ledger does not hold (re-rated, overridden, row gone).
            if got != it["rated"] or rows[0]["rating_ovr"] is not None:
                tally["held"] += 1
                print("  GH-%-5d HELD row-changed" % n)
                continue
            if a.dry_run:
                tally["dry-run"] += 1
                print("  GH-%-5d dry-run would comment on %s:\n%s\n" % (n, slug,
                                                                        rationale_body(it, real_sha)))
                continue
            posts += 1
            ok = post_rationale(slug, it, real_sha)
            append_receipt(root, {"type": "commented", "stage": "comment", "run_id": a.run,
                                  "plan_sha": real_sha, "issue": n, "rated": it["rated"],
                                  "ok": ok})
            tally["commented" if ok else "failed"] += 1
            print("  GH-%-5d %s rated %s" % (n, "COMMENTED" if ok else "COMMENT-FAILED", it["rated"]))
            if not ok:
                failed = True
                print("prs-backfill: stopping after a failed post; re-run `comment` to retry",
                      file=sys.stderr)
                break
    print("summary: %s" % ", ".join("%s %d" % kv for kv in tally.items()))
    return EXIT_REFUSED if failed else EXIT_OK


# ── calibrate (E0) ──────────────────────────────────────────────────────────────────────────────

def cmd_calibrate(a):
    check_disabled()   # it writes calibration.json and a receipt: the kill switch covers it
    root = resolve_root(a.root)
    with Lock(root):
        run_dir, scan, packets, proposals = load_run(root, a.run)
        if scan["mode"] != "calibrate":
            die(EXIT_USAGE, "not-calibrate", "run %s is mode %s" % (a.run, scan["mode"]))
        conn = open_ledger_ro(root)
        try:
            rows = ledger_rows(conn)
        finally:
            conn.close()
        pairs = []
        for p in proposals:
            n = int(p.get("issue", -1))
            if n not in packets or p.get("hold") or not rows.get(n):
                continue
            if not all(isinstance(p.get(ax), int) for ax in AXES):
                continue
            truth = rows[n][0]
            pairs.append({"issue": n,
                          "proposed": {ax: p[ax] for ax in AXES},
                          "ledger": {"pri": truth["rating_pri"], "sev": truth["rating_sev"],
                                     "appeal": truth["rating_appeal"],
                                     "effort": truth["rating_effort"]}})
        if not pairs:
            die(EXIT_USAGE, "no-pairs", "no scorable proposals in run %s" % a.run)
        k = len(pairs)
        mae = {ax: round(sum(abs(x["proposed"][ax] - x["ledger"][ax]) for x in pairs) / k, 1)
               for ax in ("pri", "sev", "effort")}
        band_agree = sum(sev_band(x["proposed"]["sev"]) == sev_band(x["ledger"]["sev"])
                         for x in pairs)
        high_truth = [x for x in pairs if sev_band(x["ledger"]["sev"]) == "high"]
        false_low = sum(sev_band(x["proposed"]["sev"]) != "high" for x in high_truth)
        false_high = sum(sev_band(x["proposed"]["sev"]) == "high" and
                         sev_band(x["ledger"]["sev"]) != "high" for x in pairs)
        appeal_neutral = sum(x["proposed"]["appeal"] == APPEAL_NEUTRAL for x in pairs)
        result = {"schema": "prs-backfill/calibration@1", "run_id": a.run, "n": k,
                  "mae": mae, "sev_band_agreement": round(band_agree / k, 3),
                  "sev_high_false_low": false_low, "sev_high_truth_n": len(high_truth),
                  "sev_false_high": false_high, "appeal_neutral": appeal_neutral,
                  "pairs": pairs,
                  "note": "agreement is consistency with existing ratings, not ground truth"}
        write_json(os.path.join(run_dir, "calibration.json"), result)
        append_receipt(root, {"type": "calibration", "run_id": a.run, "n": k, "mae": mae,
                              "sev_band_agreement": result["sev_band_agreement"],
                              "sev_high_false_low": false_low, "sev_false_high": false_high})
    print("calibration %s: n=%d  MAE pri %.1f sev %.1f effort %.1f" %
          (a.run, k, mae["pri"], mae["sev"], mae["effort"]))
    print("  sev band agreement %.0f%%  · high-band false-low %d/%d · false-high %d · appeal=50 %d/%d"
          % (100 * result["sev_band_agreement"], false_low, len(high_truth), false_high,
             appeal_neutral, k))
    return EXIT_OK


# ── status ──────────────────────────────────────────────────────────────────────────────────────

def cmd_status(a):
    root = resolve_root(a.root)
    runs = sorted(glob.glob(os.path.join(state_dir(root), "runs", "*", "scan.json")))
    if not runs:
        print("no runs under %s" % state_dir(root))
        return EXIT_OK
    last = read_json(runs[-1])
    print("last scan %s (%s) — %d open" % (last["run_id"], last["scanned_at"],
                                           last["open_issues"]))
    for k, v in last["counts"].items():
        print("  %-22s %d" % (k, v))
    rec = load_receipts(root)
    tally = {}
    for r in rec:
        tally[r.get("type")] = tally.get(r.get("type"), 0) + 1
    print("receipts: %s" % (", ".join("%s %d" % kv for kv in sorted(tally.items())) or "none"))
    applied_plans = {r.get("plan_sha") for r in rec if r.get("type") == "applied"}
    for p in sorted(glob.glob(os.path.join(state_dir(root), "runs", "*", "plan.json"))):
        pl = read_json(p)
        if pl["items"] and pl["plan_sha"] not in applied_plans:
            print("unapplied plan %s run %s (%d items)" % (pl["plan_sha"][:12], pl["run_id"],
                                                          len(pl["items"])))
    return EXIT_OK


# ── CLI ─────────────────────────────────────────────────────────────────────────────────────────

def main(argv=None):
    ap = argparse.ArgumentParser(prog="prs_backfill.py", description=__doc__.split("\n")[0])
    ap.add_argument("--root", help="repo root (default: $PRS_BACKFILL_ROOT, git toplevel, CWD)")
    ap.add_argument("--repo", help="<org>/<repo> (default: from origin)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("scan", help="inventory + bounded rating packets (read-only on the ledger)")
    s.add_argument("--mode", choices=("backfill", "changed", "calibrate"), default="backfill")
    s.add_argument("--limit", type=int, default=DEFAULT_LIMIT, help="packets per run (budget)")
    s.add_argument("--max-issues", type=int, default=2000)
    s.add_argument("--seed", default="prs-e0", help="calibration sample seed")
    s.add_argument("--include-held", action="store_true",
                   help="operator-attended re-rate: also select issues held on unchanged evidence")
    s.set_defaults(fn=cmd_scan)

    v = sub.add_parser("validate", help="check proposals and freeze an approvable plan")
    v.add_argument("--run", required=True)
    v.add_argument("--appeal-map", help="JSON {issue: appeal} of operator-supplied appeal values")
    v.add_argument("--no-review", action="store_true",
                   help="operator-attended backfill only: skip the independent-review gate")
    v.set_defaults(fn=cmd_validate)

    w = sub.add_parser("apply", help="write approved ratings via `releases roadmap rate`")
    w.add_argument("--run", required=True)
    w.add_argument("--approve", required=True, help="plan sha (>=12 hex) printed by validate")
    w.add_argument("--dry-run", action="store_true")
    w.add_argument("--max-writes", type=int, default=50)
    w.add_argument("--post-rationale", action="store_true",
                   help="also comment the dated rationale on each issue (off by default)")
    w.set_defaults(fn=cmd_apply)

    m = sub.add_parser("comment", help="post the rationale for ratings applied without "
                                       "--post-rationale")
    m.add_argument("--run", required=True)
    m.add_argument("--approve", required=True, help="plan sha (>=12 hex) printed by validate")
    m.add_argument("--dry-run", action="store_true", help="print the comments, post nothing")
    m.add_argument("--max-comments", type=int, default=50)
    m.set_defaults(fn=cmd_comment)

    c = sub.add_parser("calibrate", help="E0: score blind proposals against the ledger")
    c.add_argument("--run", required=True)
    c.set_defaults(fn=cmd_calibrate)

    t = sub.add_parser("status", help="last scan, receipts, unapplied plans")
    t.set_defaults(fn=cmd_status)

    a = ap.parse_args(argv)
    if getattr(a, "limit", 1) < 1 or getattr(a, "max_writes", 1) < 1 \
            or getattr(a, "max_comments", 1) < 1:
        die(EXIT_USAGE, "bad-bound", "--limit/--max-writes/--max-comments must be >= 1")
    return a.fn(a)


if __name__ == "__main__":
    sys.exit(main())
