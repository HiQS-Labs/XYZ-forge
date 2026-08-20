#!/usr/bin/env python3
"""GH-103 spike: project the RELEASES SQLite ledger onto the timeline-ui viewer.

Read-only exporter: queries releases.db (releases, manifest_items, issue_refs,
marathons, roadmap_items, settings, op_receipts) and emits

  <out>/data.json    — the viewer's data contract (ledger.html fetches this when served)
  <out>/index.html   — self-contained static page (data baked inline; opens from file://)
  <out>/ledger.html  — copy of the template, for the served/fetch mode

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
    """roadmap_items keyed by gh_number: enrichment for manifest cards."""
    idx = {}
    for gh, title, marker, section, doc_path, issue_url in cx.execute(
        "SELECT gh_number, title, status_marker, section, doc_path, issue_url "
        "FROM roadmap_items WHERE gh_number IS NOT NULL"
    ):
        idx[gh] = {
            "title": re.sub(r"^GH-\d+\s*·\s*", "", title),
            "marker": MARKER_BY_EMOJI.get((marker or "").strip()),
            "section": section,
            "doc_path": doc_path,
            "issue_url": issue_url,
        }
    return idx


def manifest_cards(cx, release_id, roadmap_idx, today):
    cards = []
    for state, url, temp_id in cx.execute(
        "SELECT mi.state, ir.url, ir.temp_id FROM manifest_items mi "
        "JOIN issue_refs ir ON ir.id = mi.issue_ref_id "
        "WHERE mi.release_id = ? ORDER BY mi.id",
        (release_id,),
    ):
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
        cards.append(
            {
                "id": f"GH-{gh}" if gh else (temp_id or "?"),
                "title": road.get("title") or f"issue GH-{gh}" if gh else (temp_id or "untracked item"),
                "marker": marker,
                "section": section,
                "sectionLabel": label,
                "links": links or None,
            }
        )
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
    rows = cx.execute(
        "SELECT r.id, r.version, r.codename, r.status, r.target_date, r.shipped_date, "
        "       r.description, r.exit_criterion, r.milestone, r.marathon_id, ir.url "
        "FROM releases r JOIN issue_refs ir ON ir.id = r.tracking_ref_id "
        "ORDER BY COALESCE(r.target_date, r.shipped_date, '9999-12-31'), r.version"
    ).fetchall()
    for (rid, version, codename, status, target, shipped, descr, exit_c, milestone, mar_id, ref_url) in rows:
        cards = manifest_cards(cx, rid, roadmap_idx, today)
        n_total = len(cards)
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

        exit_text = f"Exit: {exit_c}" if exit_c else (descr[:280] + ("…" if len(descr) > 280 else ""))
        milestone_ref = milestone if milestone and len(milestone) <= 24 else "milestones"

        roadmap = cards
        if mar_id in marathons and cards:
            m = marathons[mar_id]
            gh = GH_URL_RE.match(m["gh"] or "")
            roadmap = [{
                "type": "marathon",
                "id": f"GH-{gh.group(2)}" if gh else "marathon",
                "url": m["gh"],
                "title": f"{codename} marathon",
                "meta": m["status"],
                "state": "done" if m["status"] == "done" else "run",
                "cards": cards,
            }]

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
                "milestoneUrl": f"{repo_url}/milestones" if repo_url else "#",
                "milestoneRef": milestone_ref,
                "exit": exit_text,
                "detours": [],   # no detour concept in releases.db yet
                "roadmap": roadmap,
                "_raw": {"status": badge["type"], "shipped": shipped, "target": target, "ref": ref_url},
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


def build_payload(cx, today):
    settings = dict(cx.execute("SELECT key, value FROM settings"))
    repo_url = repo_url_from_refs(cx.execute("SELECT url FROM issue_refs WHERE url IS NOT NULL"))
    roadmap_idx = load_roadmap_index(cx)
    columns, n_open, n_overdue = release_columns(cx, repo_url, roadmap_idx, today)
    jf, wn = strip_entries(columns, today)

    (receipts,) = cx.execute("SELECT COUNT(*) FROM op_receipts").fetchone()
    (last_op,) = cx.execute(  # `at` is free-form in old rows; only trust date-shaped values
        "SELECT MAX(at) FROM op_receipts WHERE at GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'"
    ).fetchone()
    (schema_v,) = cx.execute("SELECT MAX(version) FROM schema_migrations").fetchone()
    last_ago = days_since(last_op, today) if last_op else None

    for c in columns:
        del c["_raw"]

    return {
        "meta": {
            "title": "Planning ledgers",
            "subtitle": f"{settings.get('repo_slug', 'repo')} · releases.db · read-only",
            "generatedAtDisplay": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ"),
            "sourceLabel": f"releases.db · schema v{schema_v}",
        },
        # sync-staleness banner + ROADMAP.md row parity: deliberately out of spike scope
        "telemetry": {
            "dbGeneration": int(settings.get("generation", 0)),
            "receipts": receipts,
            "lastSyncDisplay": (last_op or "—")[:16],
            "lastSyncAgoDisplay": humanize_days(last_ago) if last_ago is not None else "",
            "releasesOpen": n_open,
            "releasesTotal": len(columns),
            "releasesOverdue": n_overdue,
        },
        "justFinished": jf,
        "whatsNext": wn,
        "releases": columns,
    }


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
    ap.add_argument("--template", default=HERE / "ledger.html", type=Path)
    ap.add_argument("--out", default=Path("temp/timeline"), type=Path)
    args = ap.parse_args(argv)

    if not args.db.is_file():
        sys.exit(f"releases DB not found: {args.db}")
    cx = sqlite3.connect(f"file:{args.db}?mode=ro", uri=True)
    try:
        payload = build_payload(cx, date.today())
    finally:
        cx.close()

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "data.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    template = args.template.read_text()
    (args.out / "index.html").write_text(bake_static(template, payload))
    shutil.copyfile(args.template, args.out / "ledger.html")
    print(
        f"wrote {args.out}/data.json + index.html "
        f"({payload['telemetry']['releasesTotal']} releases, "
        f"{sum(r['itemsTotal'] for r in payload['releases'])} manifest cards, read-only)"
    )


if __name__ == "__main__":
    main()
