#!/usr/bin/env python3
"""GH-103 spike: project the RELEASES SQLite ledger onto the timeline-ui viewer.

Read-only exporter: queries releases.db (releases, manifest_items, issue_refs,
marathons, roadmap_items, settings, op_receipts) and emits

  <out>/data.json     — the viewer's data contract (RELEASES.html fetches this when served)
  <out>/index.html    — self-contained static page (data baked inline; opens from file://)
  <out>/RELEASES.html — copy of the template, for the served/fetch mode

Or, on demand: --preview [PATH] bakes the current DB state into a single
self-contained RELEASES-PREVIEW.html (default: repo root), and --serve PORT
answers /data.json live from the DB on every request.

Never writes to the database (opens it with SQLite's read-only URI mode).

Usage:
  python3 utils/timeline/export_timeline.py [--db releases.db] [--out temp/timeline]
"""

import argparse
import json
import re
import sqlite3
import shutil
import sys
from collections import Counter
from datetime import date, datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
GH_URL_RE = re.compile(r"https://github\.com/([^/]+/[^/]+)/issues/(\d+)")

# roadmap_items.status_marker emoji -> viewer marker keys (wip|done|paused|queued)
MARKER_BY_EMOJI = {"✅": "done", "🚧": "wip", "⏸": "paused", "‖": "paused"}

# GH-108. The DB columns are physically prefixed (`rating_effort`, because the legacy cx/risk/eff
# vocabulary already owns the bare `effort` name); the prefix is translated away here and never
# appears in data.json or the viewer. `calc` is DERIVED — the equal-weighted sum of the four axes,
# range 4-400 — and `effectiveScore` applies the override-wins-over-calc rule once, here, so no
# consumer (viewer, leaderboard, /radar) ever reimplements the precedence.
RATING_AXES = ("pri", "sev", "appeal", "effort")
RATING_COLUMNS = tuple("rating_" + a for a in RATING_AXES)
HOT_SEV = 80        # one constant, not a threshold system: severity this high renders red


def table_columns(cx, table):
    return {r[1] for r in cx.execute(f"PRAGMA table_info({table})")}


def derive_metrics(row):
    """The four axes + derived calc + effectiveScore, or None for an unrated item."""
    values = [row.get(c) for c in RATING_COLUMNS]
    if any(v is None for v in values):
        return None
    metrics = dict(zip(RATING_AXES, values))
    metrics["calc"] = sum(values)
    override = row.get("rating_ovr")
    metrics["effectiveScore"] = override if override is not None else metrics["calc"]
    return metrics


def apply_rating(card, road):
    """Attach a rated task's scores to a card. An unrated card gets NO metrics key at all —
    the viewer then renders it exactly as today, with no placeholder and no '0/400' noise."""
    metrics = road.get("metrics") if road else None
    if not metrics:
        return card
    card["metrics"] = metrics
    if metrics["sev"] >= HOT_SEV:
        card["metricFlags"] = {"sev": "hot"}
    if road.get("rating_ovr") is not None:
        card["override"] = {"value": road["rating_ovr"],
                            "hot": road["rating_ovr"] > metrics["calc"]}
    return card


def humanize_days(n):
    if n == 0:
        return "today"
    unit = "day" if abs(n) == 1 else "days"
    return f"{abs(n)} {unit} ago" if n > 0 else f"in {abs(n)} {unit}"


def days_since(iso_day, today):
    try:
        return (today - date.fromisoformat(iso_day[:10])).days
    except ValueError:
        return None


def repo_url_from_refs(rows):
    """Most common github.com/<org>/<repo> among issue_refs URLs."""
    slugs = Counter(m.group(1) for (u,) in rows if u and (m := GH_URL_RE.match(u)))
    return f"https://github.com/{slugs.most_common(1)[0][0]}" if slugs else None


def load_roadmap_index(cx):
    """roadmap_items keyed by gh_number: enrichment for manifest AND detour cards."""
    have = table_columns(cx, "roadmap_items")
    rated = "rating_pri" in have          # a ledger that predates migration 003 simply has none
    extra = ", " + ", ".join(RATING_COLUMNS + ("rating_ovr",)) if rated else ""
    idx = {}
    for row in cx.execute(
        "SELECT gh_number, title, status_marker, section, doc_path, issue_url" + extra +
        " FROM roadmap_items WHERE gh_number IS NOT NULL"
    ):
        gh, title, marker, section, doc_path, issue_url = row[:6]
        entry = {
            "title": re.sub(r"^GH-\d+\s*·\s*", "", title),
            "marker": MARKER_BY_EMOJI.get((marker or "").strip()),
            "section": section,
            "doc_path": doc_path,
            "issue_url": issue_url,
            "rating_ovr": row[10] if rated else None,
        }
        if rated:
            entry.update(dict(zip(RATING_COLUMNS, row[6:10])))
        entry["metrics"] = derive_metrics(entry) if rated else None
        idx[gh] = entry
    return idx


def manifest_cards(cx, release_id, roadmap_idx, today):
    """Manifest members as viewer cards, each tagged with the marathon it actually belongs to.

    GH-109: membership is now a fact the row carries (`manifest_items.marathon_id`), not an
    inference. `dialed_in` takes the branch `open` had — queued or wip depending on roadmap
    enrichment — and `shipped` renders the done marker the card renderer has always handled and
    simply never received, because no code path wrote that state until GH-110.
    """
    has_marathon = "marathon_id" in table_columns(cx, "manifest_items")
    select = ("SELECT mi.state, ir.url, ir.temp_id, "
              + ("mi.marathon_id" if has_marathon else "NULL") +
              " FROM manifest_items mi JOIN issue_refs ir ON ir.id = mi.issue_ref_id "
              "WHERE mi.release_id = ? ORDER BY mi.id")
    cards = []
    for state, url, temp_id, marathon_id in cx.execute(select, (release_id,)):
        gh = int(m.group(2)) if url and (m := GH_URL_RE.match(url)) else None
        road = roadmap_idx.get(gh, {})
        if state == "shipped":
            marker, section, label = "done", "done", "completed"
        elif state == "cut":
            marker, section, label = "paused", "deferred", "cut"
        elif road.get("section") == "In progress":
            marker, section, label = "wip", "wip", "in progress"
        else:
            marker, section, label = road.get("marker") or "queued", "queue", "queue"
        links = {}
        if url:
            links["issue"] = url
        if road.get("doc_path"):
            links["doc"] = road["doc_path"]
        cards.append(apply_rating(
            {
                "id": f"GH-{gh}" if gh else (temp_id or "?"),
                "title": road.get("title") or f"issue GH-{gh}" if gh else (temp_id or "untracked item"),
                "marker": marker,
                "section": section,
                "sectionLabel": label,
                "links": links or None,
                "_marathon_id": marathon_id,
                "_state": state,
            }, road))
    return cards


def release_columns(cx, repo_url, roadmap_idx, today):
    marathons = {
        mid: {"gh": ref_url, "status": status}
        for mid, ref_url, status in cx.execute(
            "SELECT m.id, ir.url, m.status FROM marathons m "
            "JOIN issue_refs ir ON ir.id = m.tracking_ref_id"
        )
    }
    columns, n_open_releases, n_overdue = [], 0, 0
    has_baseline = "baseline_count" in table_columns(cx, "releases")
    baseline_cols = ("r.baseline_count, r.baseline_at, r.baseline_source"
                     if has_baseline else "NULL, NULL, NULL")
    rows = cx.execute(
        "SELECT r.id, r.version, r.codename, r.status, r.target_date, r.shipped_date, "
        "       r.description, r.exit_criterion, r.milestone, r.marathon_id, ir.url, "
        + baseline_cols +
        " FROM releases r JOIN issue_refs ir ON ir.id = r.tracking_ref_id"
    ).fetchall()
    # Rail order: shipped/cut history on the far left (by ship date), then the
    # open releases by target date. The viewer auto-scrolls to the active node,
    # so history sits off-screen left until the reader pages back with ‹.
    rows.sort(
        key=lambda r: (
            (0, r[5] or r[4] or "") if r[3] in ("shipped", "cut") else (1, r[4] or "9999-12-31"),
            r[1],
        )
    )
    for (rid, version, codename, status, target, shipped, descr, exit_c, milestone, mar_id,
         ref_url, base_count, base_at, base_source) in rows:
        db_status = status
        cards = manifest_cards(cx, rid, roadmap_idx, today)
        # GH-111 denominator: COMMITTED work only — dialed_in + shipped, cut excluded. The old
        # count included cut rows, which contradicted the ledger's own prose that a cut "reduced
        # the manifest from 5 to 4 entries". Cut items still render (as deferred); they just stop
        # inflating the total, or "N of M" is not a commitment figure.
        n_total = sum(1 for c in cards if c["_state"] != "cut")
        n_open = sum(1 for c in cards if c["section"] in ("queue", "wip"))

        flags, extra = {}, None
        if status == "shipped":
            badge = {"type": "shipped", "label": "shipped"}
            date_label, day = "shipped", (shipped or target)
        elif status == "cut":
            badge = {"type": "draft", "label": "cut"}
            date_label, day, status = "cut", (shipped or target), "shipped"
        else:  # active | draft
            date_label, day = "target", target
            delta = days_since(target, today) if target else None
            if delta is not None:
                extra = f"{delta} days overdue" if delta > 0 else humanize_days(delta)
            if status == "active":
                n_open_releases += 1
                flags["now"] = True
                if delta is not None and delta > 0:
                    n_overdue += 1
                    flags["overdue"] = True
                    badge = {"type": "od", "label": f"{delta} days overdue"}
                else:
                    badge = {"type": "active", "label": "active"}
            else:
                n_open_releases += 1
                badge = {"type": "draft", "label": "draft"}

        # The card leads with the release's own sentence (human answer to "what IS
        # this release"); the exit criterion is the machine contract, shown after.
        plain = descr.replace("**", "").strip() if descr else ""
        blurb = re.split(r"(?<=[.!?])\s+", plain, maxsplit=1)[0] if plain else None
        exit_text = (f"Exit: {exit_c}" if exit_c else plain[:280] + ("…" if len(plain) > 280 else "")).replace("**", "")
        milestone_ref = milestone if milestone and len(milestone) <= 24 else "milestones"

        # GH-109: group ONLY the items whose row names this marathon. The old code wrapped EVERY
        # manifest card whenever the release had a marathon at all — the viewer then asserted a
        # membership the data never claimed, latent until a non-marathon item joined a marathon
        # release. Non-members render as siblings beside the box, in manifest order.
        roadmap = cards
        if mar_id in marathons:
            members = [c for c in cards if c["_marathon_id"] == mar_id]
            if members:
                m = marathons[mar_id]
                gh = GH_URL_RE.match(m["gh"] or "")
                group = {
                    "type": "marathon",
                    "id": f"GH-{gh.group(2)}" if gh else "marathon",
                    "url": m["gh"],
                    "title": f"{codename} marathon",
                    "meta": m["status"],
                    "state": "done" if m["status"] == "done" else "run",
                    "cards": members,
                }
                roadmap = [group] + [c for c in cards if c["_marathon_id"] != mar_id]
        for card in cards:
            del card["_marathon_id"]
            del card["_state"]

        # Two numbers, not one: progress against what was committed at kickoff, and how much the
        # commitment itself grew. A release with no baseline shows progress alone — no growth
        # figure and no placeholder zero, because a zero would read as "no scope creep".
        baseline = None
        if base_count is not None:
            baseline = {"count": base_count, "at": base_at, "source": base_source,
                        "growth": n_total - base_count}

        columns.append(
            {
                "id": "c-" + version.replace(".", "-"),
                "slug": (codename or version).lower(),
                "name": codename or version,
                "version": version,
                "status": {"active": "active", "draft": "draft"}.get(status, "shipped"),
                "flags": flags,
                "badge": badge,
                "dateLabel": date_label,
                "date": day or "—",
                "extra": extra,
                "itemsTotal": n_total,
                "itemsOpen": n_open,
                "baseline": baseline,
                "milestoneUrl": f"{repo_url}/milestones" if repo_url else "#",
                "milestoneRef": milestone_ref,
                "blurb": blurb,
                "exit": exit_text,
                "detours": [],   # no detour concept in releases.db yet
                "roadmap": roadmap,
                "_raw": {"status": badge["type"], "db_status": db_status, "codename": codename,
                         "shipped": shipped, "target": target, "ref": ref_url},
            }
        )
    return columns, n_open_releases, n_overdue


def strip_entries(columns, today):
    """justFinished = latest shipped release; whatsNext = earliest unshipped target."""
    jf = wn = None
    shipped = [c for c in columns if c["_raw"]["shipped"]]
    if shipped:
        c = max(shipped, key=lambda c: c["_raw"]["shipped"])
        ago = days_since(c["_raw"]["shipped"], today)
        jf = {
            "issue": f"v{c['version']}",
            "title": f"{c['name']} shipped",
            "closedDateDisplay": c["_raw"]["shipped"],
            "closedAgoDisplay": humanize_days(ago) if ago is not None else "",
            "issueUrl": c["_raw"]["ref"],
        }
    upcoming = [c for c in columns if c["status"] in ("active", "draft") and c["_raw"]["target"]]
    if upcoming:
        c = min(upcoming, key=lambda c: c["_raw"]["target"])
        wn = {
            "issue": f"v{c['version']}",
            "title": c["name"],
            "note": f"target {c['_raw']['target']} · {c['extra']}" if c["extra"] else f"target {c['_raw']['target']}",
            "issueUrl": c["_raw"]["ref"],
        }
    return jf, wn


def roadmap_detours(path, manifest_ghs, roadmap_idx=None):
    """ROADMAP.md '### In progress' entries not in any release manifest -> ad-hoc
    detour cards for the ACTIVE release column (work in flight during its window
    that isn't part of its goalpost — the timeline's ad-hoc lane, merges down).

    This function reparses the markdown rather than reading the ledger, so it must be handed the
    GH-keyed roadmap index too: an in-progress RATED task on no manifest is exactly the kind of
    thing an operator scores highly, and it would otherwise render scoreless — the leaderboard
    would then silently omit the very work in flight.
    """
    roadmap_idx = roadmap_idx or {}
    if not path.is_file():
        return []
    cards, section = [], None
    for line in path.read_text().splitlines():
        if line.startswith("### "):
            section = line[4:].strip()
            continue
        m = re.match(r"^- \*\*GH-(\d+) · (.+?)\*\*", line)
        if not m or section != "In progress":
            continue
        gh = int(m.group(1))
        if gh in manifest_ghs:
            continue
        url = re.search(r"https://github\.com/[^\s)]+/issues/\d+", line)
        cards.append(apply_rating(
            {
                "id": f"GH-{gh}",
                "title": m.group(2),
                "marker": "wip",
                "section": "adhoc",
                "sectionLabel": "ad-hoc detour",
                "links": {"issue": url.group(0)} if url else None,
            }, roadmap_idx.get(gh, {})))
    return cards


def parse_releases_md(path):
    """RELEASES.md 'Release:' blocks -> {version: {status, codename}}. None if unreadable."""
    if not path.is_file():
        return None
    blocks, cur = {}, None
    for line in path.read_text().splitlines():
        if m := re.match(r"^Release:\s*(\S+)", line):
            cur = blocks.setdefault(m.group(1), {})
        elif cur is not None and (m := re.match(r"^(Status|Codename|Iterations):\s*(.+?)\s*$", line)):
            cur.setdefault(m.group(1).lower(), m.group(2))
    return blocks


def _ver(v):
    try:
        return tuple(int(p) for p in v.split("."))
    except ValueError:
        return None


def in_md_band(version, md):
    """True when an md block's Iterations band (e.g. 0.7.0-0.7.4) covers this version.

    The RELEASES.md contract: versions inside a reserved band ship freely, are
    recorded in CHANGELOG.md only, and never get a block — so a DB release inside
    a band is accounted for, NOT drift.
    """
    v = _ver(version)
    if v is None:
        return False
    for block in md.values():
        if m := re.match(r"^\s*(\S+?)\s*-\s*(\S+?)\s*$", block.get("iterations", "")):
            lo, hi = _ver(m.group(1)), _ver(m.group(2))
            if lo and hi and lo <= v <= hi:
                return True
    return False


def md_drift(md, columns):
    """Compare RELEASES.md (canonical during the GH-32 shadow phase) with the DB rows.

    Only shipped-ness is compared — the md vocabulary (Shipped/Draft) has no
    'active' state, so draft-vs-active is not drift. The real drift classes are
    releases existing on one side only, and shipped/unshipped disagreement.
    """
    if md is None:
        return None
    db = {c["version"]: c["_raw"] for c in columns}
    db_only = [v for v in db if v not in md and not in_md_band(v, md)]
    md_only = [v for v in md if v not in db]
    flipped = [
        v for v in db.keys() & md.keys()
        if (md[v].get("status", "").lower() == "shipped") != (db[v]["db_status"] in ("shipped", "cut"))
    ]
    if not (db_only or md_only or flipped):
        return None
    parts = []
    if db_only:
        names = ", ".join(f"{v} ({db[v]['codename']})" for v in sorted(db_only))
        parts.append(f"{len(db_only)} release(s) exist only in releases.db, outside every RELEASES.md Iterations band: {names}.")
    if md_only:
        parts.append(f"{len(md_only)} release(s) exist only in RELEASES.md: {', '.join(sorted(md_only))}.")
    if flipped:
        parts.append(f"shipped-status disagreement on: {', '.join(sorted(flipped))}.")
    return {
        "stale": True,
        "sourceFile": "RELEASES.md",
        "rowsDiffer": len(db_only) + len(md_only) + len(flipped),
        "heading": "⚠ ledger drift — RELEASES.md (canonical) and releases.db disagree",
        "message": " ".join(parts) + " Everything below reflects the DB. Fix at the source per the RELEASES.md "
        "contract: a band-opening release gets a block, an in-band version is covered by its band (CHANGELOG.md "
        "records it) — never fix it in this page.",
    }


def build_payload(cx, today, md_path=None):
    settings = dict(cx.execute("SELECT key, value FROM settings"))
    repo_url = repo_url_from_refs(cx.execute("SELECT url FROM issue_refs WHERE url IS NOT NULL"))
    roadmap_idx = load_roadmap_index(cx)
    columns, n_open, n_overdue = release_columns(cx, repo_url, roadmap_idx, today)
    jf, wn = strip_entries(columns, today)
    sync = md_drift(parse_releases_md(md_path) if md_path else None, columns)

    # Ad-hoc lane: in-flight non-manifest ROADMAP work attaches to the active release.
    active = next((c for c in columns if c["flags"].get("now")), None)
    if active and md_path:
        manifest_ghs = {
            int(m.group(2))
            for (url,) in cx.execute(
                "SELECT url FROM issue_refs WHERE url IS NOT NULL AND id IN ("
                "  SELECT issue_ref_id FROM manifest_items"
                "  UNION SELECT tracking_ref_id FROM releases"
                "  UNION SELECT tracking_ref_id FROM marathons)"
            )
            if (m := GH_URL_RE.match(url))
        }
        active["detours"] = roadmap_detours(md_path.parent / "ROADMAP.md", manifest_ghs,
                                            roadmap_idx)

    (receipts,) = cx.execute("SELECT COUNT(*) FROM op_receipts").fetchone()
    (last_op,) = cx.execute(  # `at` is free-form in old rows; only trust date-shaped values
        "SELECT MAX(at) FROM op_receipts WHERE at GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'"
    ).fetchone()
    (schema_v,) = cx.execute("SELECT MAX(version) FROM schema_migrations").fetchone()
    last_ago = days_since(last_op, today) if last_op else None

    # ── the complete ranking set ────────────────────────────────────────────────────────────────
    # The timeline only shows work that is ON a release (manifest members) or in flight beside one
    # (detours). A rated task sitting in the QUEUE appears nowhere — and a high-scoring queued task
    # is exactly what "what should go to the front of the line" is asking about, so ranking off the
    # cards alone would answer the question by hiding most of the candidates. ratedTasks is
    # therefore every rated roadmap row, once, annotated with where it currently sits.
    placement = {}
    for c in columns:
        for item in c["detours"] + c["roadmap"]:
            group = item.get("type") == "marathon"
            for card in (item["cards"] if group else [item]):
                placement[card["id"]] = (c["name"],
                                         "marathon" if group else card["sectionLabel"])
    rated_tasks = []
    for gh, road in roadmap_idx.items():
        metrics = road.get("metrics")
        if not metrics:
            continue
        cid = f"GH-{gh}"
        release, lane = placement.get(cid, (None, road.get("section") or "roadmap"))
        entry = {"id": cid, "title": road["title"], "release": release, "lane": lane,
                 "metrics": metrics,
                 "links": {"issue": road["issue_url"]} if road.get("issue_url") else None}
        if road.get("rating_ovr") is not None:
            entry["override"] = {"value": road["rating_ovr"],
                                 "hot": road["rating_ovr"] > metrics["calc"]}
        rated_tasks.append(entry)
    # ties break on id, so the ranking is deterministic rather than dict-iteration order
    rated_tasks.sort(key=lambda r: (-r["metrics"]["effectiveScore"], r["id"]))

    for c in columns:
        del c["_raw"]

    return {
        "meta": {
            "title": "Planning ledgers",
            "subtitle": f"{settings.get('repo_slug', 'repo')} · releases.db · read-only",
            "generatedAtDisplay": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ"),
            "sourceLabel": f"releases.db · schema v{schema_v}",
        },
        "sync": sync,  # RELEASES.md-vs-DB drift banner; None (no banner) when they agree
        # ROADMAP.md row parity: still out of spike scope
        "telemetry": {
            "dbGeneration": int(settings.get("generation", 0)),
            "receipts": receipts,
            "lastSyncDisplay": (last_op or "—")[:16],
            "lastSyncAgoDisplay": humanize_days(last_ago) if last_ago is not None else "",
            "releasesOpen": n_open,
            "releasesTotal": len(columns),
            "releasesOverdue": n_overdue,
        },
        # every rated task in the ledger, ranked — the leaderboard's single input
        "ratedTasks": rated_tasks,
        "justFinished": jf,
        "whatsNext": wn,
        "releases": columns,
    }


def serve(db_path, md_path, template_dir, port):
    """Live mode: /data.json re-queries releases.db on every request — no stale file."""
    import http.server

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(template_dir), **kw)

        def do_GET(self):
            path = self.path.split("?")[0]
            if path == "/":
                self.send_response(302)
                self.send_header("Location", "/RELEASES.html")
                self.end_headers()
                return
            if path != "/data.json":
                return super().do_GET()
            cx = sqlite3.connect(f"{db_path.as_uri()}?mode=ro", uri=True)
            try:
                body = json.dumps(build_payload(cx, date.today(), md_path)).encode()
            finally:
                cx.close()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    with http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler) as srv:
        print(f"live on http://127.0.0.1:{port}/RELEASES.html — every refresh re-queries {db_path}")
        srv.serve_forever()


def bake_static(template_html, payload):
    marker = "<!--LEDGER_DATA-->"
    if marker not in template_html:
        sys.exit("template is missing the <!--LEDGER_DATA--> placeholder")
    blob = json.dumps(payload, ensure_ascii=False).replace("</", "<\\/")
    return template_html.replace(
        marker, f'<script id="ledger-data" type="application/json">{blob}</script>'
    )


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--db", default="releases.db", type=Path)
    ap.add_argument("--md", type=Path, help="RELEASES.md for drift check (default: next to --db)")
    ap.add_argument("--template", default=HERE / "RELEASES.html", type=Path)
    ap.add_argument("--out", default=Path("temp/timeline"), type=Path)
    ap.add_argument("--json", action="store_true",
                    help="print the payload (same single-object shape as data.json) to stdout; "
                         "no files written — the input the leaderboard and /radar consume")
    ap.add_argument("--check-drift", action="store_true",
                    help="no files written: exit 1 listing RELEASES.md-vs-DB drift, exit 0 when aligned")
    ap.add_argument("--serve", type=int, metavar="PORT", default=None,
                    help="serve live: /data.json re-queries the DB on every request (no files written)")
    ap.add_argument("--preview", nargs="?", const=Path("RELEASES-PREVIEW.html"), default=None,
                    type=Path, metavar="PATH",
                    help="bake current DB state into one self-contained HTML (default: ./RELEASES-PREVIEW.html)")
    ap.add_argument("--leaderboard", nargs="?", const=Path("LEADERBOARD.html"), default=None,
                    type=Path, metavar="PATH",
                    help="bake the ranked view from the SAME template (default: ./LEADERBOARD.html)")
    args = ap.parse_args(argv)

    if not args.db.is_file():
        sys.exit(f"releases DB not found: {args.db}")
    md_path = args.md if args.md else args.db.resolve().parent / "RELEASES.md"

    if args.serve:
        serve(args.db.resolve(), md_path, args.template.resolve().parent, args.serve)
        return
    cx = sqlite3.connect(f"{args.db.resolve().as_uri()}?mode=ro", uri=True)
    try:
        payload = build_payload(cx, date.today(), md_path)
    finally:
        cx.close()

    if args.json:
        print(json.dumps(payload, ensure_ascii=False))
        return

    if args.check_drift:
        sync = payload.get("sync")
        if sync:
            print(f"DRIFT ({sync['rowsDiffer']}): {sync['message']}")
            sys.exit(1)
        print("releases.db and RELEASES.md agree (releases present on both sides, shipped-status aligned)")
        return

    if args.leaderboard:
        # ONE template, TWO baked artifacts. The only difference is the payload's `view` field —
        # no second copy of the design system, no second baker, one data contract, and both
        # files stay standalone and openable from a plain git checkout with no server.
        args.leaderboard.write_text(
            bake_static(args.template.read_text(), dict(payload, view="leaderboard")))
        print(f"wrote {args.leaderboard} "
              f"({len(payload['ratedTasks'])} rated task(s), self-contained)")
        return

    if args.preview:
        args.preview.write_text(bake_static(args.template.read_text(), payload))
        print(f"wrote {args.preview} ({payload['telemetry']['releasesTotal']} releases, "
              f"self-contained, read-only snapshot of {args.db})")
        return

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "data.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    template = args.template.read_text()
    (args.out / "index.html").write_text(bake_static(template, payload))
    shutil.copyfile(args.template, args.out / "RELEASES.html")
    print(
        f"wrote {args.out}/data.json + index.html "
        f"({payload['telemetry']['releasesTotal']} releases, "
        f"{sum(r['itemsTotal'] for r in payload['releases'])} manifest cards, read-only)"
    )


if __name__ == "__main__":
    main()
