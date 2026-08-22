#!/usr/bin/env python3
"""GH-153: the RELEASES-cycle rollup — the full-ledger companion to the marathon rollup.

One read-only pass over releases.db that answers "where does the whole cycle stand":
releases by status (with open targets and overdue counts), roadmap-shadow movement,
marathon states, manifest outcomes (dialed-in / shipped / cut) and the latest
append-only manifest state events. Two consumers share this module so the numbers can
never drift between surfaces:

  * utils/hq/rollup.sh — embeds the markdown render per known repo (the GH-192 daily
    rollup, extended from marathon-runs-only to the entire cycle)
  * utils/timeline/export_timeline.py — ships the summary inside the dashboard payload
    (the sidebar's "releases cycle" panel)

Never writes to the database (read-only URI mode), so it is safe to run mid-merge.

Usage:
  releases_cycle.py [--db releases.db] [--repo-label LABEL] [--json] [--events N]

Exit codes: 0 ok · 2 DB missing/unreadable/not-a-ledger (callers degrade per repo).
"""

import argparse
import json
import re
import sqlite3
import sys
from datetime import date, datetime, timezone
from pathlib import Path

GH_URL_RE = re.compile(r"https://github\.com/([^/]+/[^/]+)/issues/(\d+)")

# Mirror of export_timeline.MARKER_BY_EMOJI, kept local to avoid a circular import (the
# exporter imports THIS module). If one changes, change both.
_MARKER_BY_EMOJI = {"✅": "done", "🚧": "wip", "⏸": "paused", "‖": "paused"}
_MARKER_ORDER = ("wip", "queued", "done", "paused")


def connect_ro(db_path):
    path = Path(db_path).resolve()
    if not path.is_file():
        raise FileNotFoundError(str(path))
    return sqlite3.connect(f"{path.as_uri()}?mode=ro", uri=True)


def _days_until(iso_day, today):
    try:
        return (date.fromisoformat(iso_day[:10]) - today).days
    except (ValueError, TypeError):
        return None


def summary_from_cx(cx, repo_label=None, events_limit=5, today=None):
    """The full-cycle summary as a plain dict (JSON-shaped; also the dashboard payload key)."""
    today = today or date.today()
    settings = dict(cx.execute("SELECT key, value FROM settings"))

    rel_by_status = dict(cx.execute("SELECT status, COUNT(*) FROM releases GROUP BY status"))
    open_releases, overdue = [], 0
    for version, codename, status, target in cx.execute(
        "SELECT version, codename, status, target_date FROM releases "
        "WHERE status IN ('active','draft') ORDER BY (target_date IS NULL), target_date"
    ):
        delta = _days_until(target, today) if target else None
        if status == "active" and delta is not None and delta < 0:
            overdue += 1
        open_releases.append({"version": version, "codename": codename, "status": status,
                              "target": target, "daysToTarget": delta})
    recent_shipped = [
        {"version": v, "shipped": s}
        for v, s in cx.execute(
            "SELECT version, shipped_date FROM releases "
            "WHERE status IN ('shipped','cut') AND shipped_date IS NOT NULL "
            "ORDER BY shipped_date DESC LIMIT 3")
    ]

    markers = dict.fromkeys(_MARKER_ORDER, 0)
    unmarked = road_total = 0
    for marker, n in cx.execute(
        "SELECT status_marker, COUNT(*) FROM roadmap_items GROUP BY status_marker"
    ):
        road_total += n
        key = _MARKER_BY_EMOJI.get((marker or "").strip())
        if key:
            markers[key] += n
        else:
            unmarked += n

    mar_by_status = dict(cx.execute("SELECT status, COUNT(*) FROM marathons GROUP BY status"))
    running_refs = []
    for (url,) in cx.execute(
        "SELECT ir.url FROM marathons m JOIN issue_refs ir ON ir.id = m.tracking_ref_id "
        "WHERE m.status IN ('running','planned')"
    ):
        m = GH_URL_RE.match(url or "")
        if m:
            running_refs.append(f"GH-{m.group(2)}")

    items = dict(cx.execute("SELECT state, COUNT(*) FROM manifest_items GROUP BY state"))

    events = []
    for at, from_state, to_state, reason, url, temp_id in cx.execute(
        "SELECT e.at, e.from_state, e.to_state, e.reason, ir.url, ir.temp_id "
        "FROM manifest_state_events e "
        "JOIN manifest_items mi ON mi.id = e.item_id "
        "JOIN issue_refs ir ON ir.id = mi.issue_ref_id "
        "ORDER BY e.at DESC LIMIT ?", (max(0, events_limit),)
    ):
        m = GH_URL_RE.match(url or "")
        events.append({"at": at, "from": from_state, "to": to_state, "reason": reason,
                       "item": f"GH-{m.group(2)}" if m else (temp_id or "item")})

    (receipts,) = cx.execute("SELECT COUNT(*) FROM op_receipts").fetchone()
    (last_op,) = cx.execute(
        "SELECT MAX(at) FROM op_receipts "
        "WHERE at GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'"
    ).fetchone()
    (schema_v,) = cx.execute("SELECT MAX(version) FROM schema_migrations").fetchone()

    return {
        "repo": repo_label or settings.get("repo_slug"),
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "db": {"generation": int(settings.get("generation", 0) or 0), "receipts": receipts,
               "lastOp": last_op, "schemaVersion": schema_v},
        "releases": {
            "total": sum(rel_by_status.values()), "open": len(open_releases),
            "overdue": overdue, "byStatus": rel_by_status,
            "openList": open_releases[:5], "recentShipped": recent_shipped,
        },
        "roadmap": {"total": road_total, "unmarked": unmarked, **markers},
        "marathons": {"total": sum(mar_by_status.values()), "byStatus": mar_by_status,
                      "runningRefs": running_refs},
        "items": {"open": items.get("open", 0), "dialedIn": items.get("dialed_in", 0),
                  "shipped": items.get("shipped", 0), "cut": items.get("cut", 0)},
        "recentEvents": events,
    }


def _fmt_delta(days):
    if days is None:
        return "no target"
    if days == 0:
        return "target today"
    unit = "day" if abs(days) == 1 else "days"
    return f"target {days} {unit} out" if days > 0 else f"{-days} {unit} overdue"


def render_markdown(s):
    r, rm, m, it, db = s["releases"], s["roadmap"], s["marathons"], s["items"], s["db"]
    lines = [
        f"# RELEASES cycle — {s['repo']}",
        "",
        f"_generated {s['generatedAt']} · db generation {db['generation']} · "
        f"{db['receipts']:,} receipts · schema v{db['schemaVersion']}_",
        "",
        f"## Releases — {r['total']} total · {r['open']} open ({r['overdue']} overdue) · "
        f"{r['byStatus'].get('shipped', 0)} shipped · {r['byStatus'].get('cut', 0)} cut",
    ]
    for rel in r["openList"]:
        name = f"v{rel['version']}" + (f" “{rel['codename']}”" if rel["codename"] else "")
        when = (f" — {rel['target'] or '—'} ({_fmt_delta(rel['daysToTarget'])})"
                if rel["status"] == "active" else "")
        lines.append(f"- {rel['status']}: {name}{when}")
    if r["recentShipped"]:
        lines.append("- recently shipped: " + ", ".join(
            f"v{x['version']} ({x['shipped']})" for x in r["recentShipped"]))
    lines += [
        "",
        f"## Roadmap shadow — {rm['total']} items",
        "",
        f"◑ {rm['wip']} wip · ○ {rm['queued']} queued · ✓ {rm['done']} done · ‖ {rm['paused']} paused"
        + (f" · {rm['unmarked']} unmarked" if rm["unmarked"] else ""),
        "",
        f"## Marathons — {m['total']} total",
        "",
        (" · ".join(f"{v} {k}" for k, v in sorted(m["byStatus"].items())) or "none recorded")
        + (f" — running now: {', '.join(m['runningRefs'])}" if m["runningRefs"] else ""),
        "",
        "## Manifest outcomes",
        "",
        f"{it['dialedIn']} dialed-in · {it['shipped']} shipped · {it['cut']} cut · {it['open']} open",
        "",
        "## Latest state events",
        "",
    ]
    if s["recentEvents"]:
        lines.extend(f"- {e['at'][:10]} {e['item']} {e['from']} → {e['to']} — {e['reason']}"
                     for e in s["recentEvents"])
    else:
        lines.append("- none recorded")
    return "\n".join(lines) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--db", default="releases.db", type=Path)
    ap.add_argument("--repo-label", default=None,
                    help="override the repo label (default: the DB's own settings.repo_slug)")
    ap.add_argument("--json", action="store_true", help="print the summary as JSON")
    ap.add_argument("--events", type=int, default=5, metavar="N",
                    help="recent manifest state events to include (default 5)")
    args = ap.parse_args(argv)

    try:
        cx = connect_ro(args.db)
    except FileNotFoundError:
        print(f"releases_cycle: no releases DB at {args.db}", file=sys.stderr)
        return 2
    except sqlite3.Error as exc:
        print(f"releases_cycle: cannot open {args.db}: {exc}", file=sys.stderr)
        return 2
    try:
        summary = summary_from_cx(cx, repo_label=args.repo_label, events_limit=args.events)
    except sqlite3.Error as exc:
        print(f"releases_cycle: {args.db} is not a readable releases ledger: {exc}",
              file=sys.stderr)
        return 2
    finally:
        cx.close()

    if args.json:
        print(json.dumps(summary, ensure_ascii=False))
    else:
        sys.stdout.write(render_markdown(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
