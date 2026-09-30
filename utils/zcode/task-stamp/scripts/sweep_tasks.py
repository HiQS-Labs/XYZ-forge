#!/usr/bin/env python3
"""task-stamp — groom the ZCode app task list.

Sweep mode (--sweep):
  * Date-stamps task titles with a U.S. mm-dd stamp of the task's last
    activity (``09-29 LTvera 676`` style), replacing a stale stamp on
    tasks that were touched again on a later day.
  * Pins recently-active tasks (``--pin-hours`` window) so they surface
    in the app's PINNED section, and optionally unpins stale ones.
  * Reports tasks whose titles are still raw prompt text
    (``needs_summary``) so an agent can replace them with a short
    description of the task's last action via ``--set-title``.

Set-title mode (--set-title TASK_ID TITLE):
  * Writes a reviewed title, stamped with the task's own last-activity
    mm-dd date (a caller-supplied stamp is normalized, never kept).

The ZCode app keeps its task index in ``~/.zcode/v2/tasks-index.sqlite``.
Writes here are short WAL transactions against the live DB — safe to run
while the app is open, but the app may not re-render its task list until
it next refreshes (switch workspace or restart to see changes). The app
can also rewrite the title of a session that is still active; the next
sweep re-applies the stamp.

Operational envelope: a local developer CLI grooming a local app DB.
No retries, no daemons, no recovery machinery — rerun the sweep.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
import uuid
from datetime import datetime

DEFAULT_DB = os.path.expanduser("~/.zcode/v2/tasks-index.sqlite")

# A leading U.S. mm-dd stamp followed by a description ("09-29 LTvera 676").
STAMP_RE = re.compile(r"^(\d{2}-\d{2})\s+(\S.*)$", re.DOTALL)
MAX_BASE = 72  # keep the descriptive part readable in the task list

EXPECTED_TASK_COLUMNS = {
    "workspace_key", "workspace_path", "workspace_identity", "task_id",
    "title", "title_overridden", "pinned", "updated_at", "deleted",
    "archived", "meta_json", "cron_automation_id",
}
EXPECTED_GROUP_COLUMNS = {"group_id", "title", "color", "created_at", "updated_at"}
EXPECTED_MEMBER_COLUMNS = {
    "group_id", "workspace_key", "workspace_path", "workspace_identity",
    "task_id", "sort_order", "added_at", "created_at", "updated_at",
}


def local_stamp(ms: int) -> str:
    """The mm-dd stamp for a millisecond-epoch timestamp, in local time."""
    return datetime.fromtimestamp(ms / 1000).strftime("%m-%d")


def clean_base(raw: str) -> str:
    """Strip any existing stamp and collapse whitespace so re-stamping
    never stacks prefixes; cap length so long prompt-derived titles stay
    scannable. A bare date is not a description."""
    match = STAMP_RE.match(raw.strip())
    base = match.group(2) if match else raw.strip()
    base = re.sub(r"\s+", " ", base).strip()
    if re.fullmatch(r"\d{2}-\d{2}", base):
        return ""
    if len(base) > MAX_BASE:
        base = base[: MAX_BASE - 1].rstrip() + "…"
    return base


def check_schema(conn: sqlite3.Connection, require_groups: bool = False) -> None:
    def columns(table: str) -> set[str]:
        rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
        return {row[1] for row in rows}

    missing = EXPECTED_TASK_COLUMNS - columns("tasks")
    if missing:
        raise SystemExit(f"task-stamp: tasks table missing expected columns: {sorted(missing)}")
    for table, expected in (("task_groups", EXPECTED_GROUP_COLUMNS),
                            ("task_group_members", EXPECTED_MEMBER_COLUMNS)):
        present = columns(table)
        if not present:
            if require_groups:
                raise SystemExit(f"task-stamp: --group needs the {table} table; not found in this index")
            continue
        if expected - present:
            raise SystemExit(f"task-stamp: {table} table missing expected columns: {sorted(expected - present)}")


def open_db(path: str, require_groups: bool = False) -> sqlite3.Connection:
    if not os.path.exists(path):
        raise SystemExit(f"task-stamp: task index DB not found at {path}")
    conn = sqlite3.connect(path, timeout=5.0)
    conn.execute("PRAGMA busy_timeout=5000")
    check_schema(conn, require_groups=require_groups)
    return conn


def sync_meta(meta_json: str, title: str) -> str | None:
    """Mirror the new title into meta_json (the app stores title and
    titleOverridden there too). Returns None if meta_json isn't valid JSON."""
    try:
        meta = json.loads(meta_json)
    except (TypeError, ValueError):
        return None
    if not isinstance(meta, dict):
        return None
    meta["title"] = title
    meta["titleOverridden"] = True
    return json.dumps(meta, ensure_ascii=False)


def swept_rows(conn: sqlite3.Connection, hours: float, include_all: bool):
    if include_all:
        return conn.execute(
            "SELECT workspace_key, workspace_path, workspace_identity, task_id, title,"
            " title_overridden, pinned, updated_at, meta_json, cron_automation_id"
            " FROM tasks WHERE deleted=0 AND archived=0 ORDER BY updated_at DESC"
        ).fetchall()
    cutoff = int((datetime.now().timestamp() - hours * 3600) * 1000)
    return conn.execute(
        "SELECT workspace_key, workspace_path, workspace_identity, task_id, title,"
        " title_overridden, pinned, updated_at, meta_json, cron_automation_id"
        " FROM tasks WHERE deleted=0 AND archived=0 AND updated_at >= ?"
        " ORDER BY updated_at DESC",
        (cutoff,),
    ).fetchall()


def ensure_group(conn: sqlite3.Connection, title: str, now_ms: int) -> str:
    row = conn.execute("SELECT group_id FROM task_groups WHERE title=?", (title,)).fetchone()
    if row:
        return row[0]
    gid = f"grp-{uuid.uuid4()}"
    conn.execute(
        "INSERT INTO task_groups (group_id, title, color, created_at, updated_at)"
        " VALUES (?,?,?,?,?)",
        (gid, title, "gray", now_ms, now_ms),
    )
    return gid


def run_sweep(conn: sqlite3.Connection, args) -> dict:
    now_ms = int(datetime.now().timestamp() * 1000)
    pin_cutoff = int((datetime.now().timestamp() - args.pin_hours * 3600) * 1000)
    unpin_cutoff = (
        int((datetime.now().timestamp() - args.unpin_days * 86400) * 1000)
        if args.unpin_days is not None
        else None
    )

    report: dict = {
        "db": args.db,
        "dry_run": args.dry_run,
        "swept": 0,
        "skipped_cron": 0,
        "renamed": [],
        "pinned": [],
        "unpinned": [],
        "group_added": [],
        "needs_summary": [],
    }
    rows = swept_rows(conn, args.hours, args.all)
    group_id = None
    if args.group:
        if args.dry_run:
            # Read-only: plan against the group if it exists, else note it.
            row = conn.execute(
                "SELECT group_id FROM task_groups WHERE title=?", (args.group,)
            ).fetchone()
            if row:
                group_id = row[0]
            else:
                report["group_added"] = [{"note": f"dry-run: would create group {args.group!r}"}]
        else:
            with conn:
                group_id = ensure_group(conn, args.group, now_ms)

    writes: list[tuple[str, tuple]] = []

    for row in rows:
        (ws_key, ws_path, ws_identity, task_id, title, title_overridden,
         pinned, updated_at, meta_json, cron_id) = row
        if cron_id and not args.include_cron:
            report["skipped_cron"] += 1
            continue
        report["swept"] += 1

        stamp = local_stamp(updated_at)
        base = clean_base(title)
        new_title = f"{stamp} {base}" if base else title
        if new_title != title:
            meta = sync_meta(meta_json, new_title)
            report["renamed"].append(
                {"task_id": task_id, "workspace_path": ws_path, "old": title, "new": new_title}
            )
            writes.append((
                "UPDATE tasks SET title=?, title_overridden=1, meta_json=?"
                " WHERE workspace_key=? AND task_id=?",
                (new_title, meta if meta is not None else meta_json, ws_key, task_id),
            ))

        if updated_at >= pin_cutoff:
            if not pinned and args.pin:
                report["pinned"].append({"task_id": task_id, "title": new_title})
                writes.append((
                    "UPDATE tasks SET pinned=1 WHERE workspace_key=? AND task_id=?",
                    (ws_key, task_id),
                ))
            if args.group and group_id:
                existing = conn.execute(
                    "SELECT group_id FROM task_group_members WHERE workspace_key=? AND task_id=?",
                    (ws_key, task_id),
                ).fetchone()
                if existing is None or existing[0] != group_id:
                    writes.append((
                        "INSERT OR REPLACE INTO task_group_members"
                        " (group_id, workspace_key, workspace_path, workspace_identity,"
                        " task_id, sort_order, added_at, created_at, updated_at)"
                        " VALUES (?,?,?,?,?,"
                        " (SELECT COALESCE(MAX(sort_order),-1)+1 FROM task_group_members WHERE group_id=?),"
                        " ?,?,?)",
                        (group_id, ws_key, ws_path, ws_identity, task_id,
                         group_id, now_ms, now_ms, now_ms),
                    ))
                    report["group_added"].append({"task_id": task_id, "group": args.group})

        if title_overridden == 0:
            report["needs_summary"].append(
                {"task_id": task_id, "workspace_path": ws_path, "title": new_title}
            )

    if unpin_cutoff is not None:
        stale = conn.execute(
            "SELECT workspace_key, task_id, title FROM tasks WHERE pinned=1 AND deleted=0"
            " AND archived=0 AND updated_at < ?",
            (unpin_cutoff,),
        ).fetchall()
        for ws_key, task_id, title in stale:
            report["unpinned"].append({"task_id": task_id, "title": title})
            writes.append((
                "UPDATE tasks SET pinned=0 WHERE workspace_key=? AND task_id=?",
                (ws_key, task_id),
            ))

    if not args.dry_run and writes:
        with conn:
            for sql, params in writes:
                conn.execute(sql, params)

    return report


def run_set_title(conn: sqlite3.Connection, args) -> dict:
    task_id, desired = args.set_title
    if not desired.strip():
        raise SystemExit("task-stamp: --set-title requires a non-empty title")

    rows = conn.execute(
        "SELECT workspace_key, task_id, title, meta_json, updated_at FROM tasks WHERE task_id=?",
        (task_id,),
    ).fetchall()
    if not rows:
        raise SystemExit(f"task-stamp: no task with id {task_id!r}")

    # Stamp from each row's own last-activity date, matching the sweep's
    # semantics — a wall-clock stamp here would be silently reverted by
    # the next sweep of a task last active on an earlier day.
    base = clean_base(desired)
    if not base:
        raise SystemExit("task-stamp: --set-title requires a non-empty description")

    out = {"task_id": task_id, "renamed": [], "dry_run": args.dry_run}
    for ws_key, _, old, meta_json, updated_at in rows:
        desired = f"{local_stamp(updated_at)} {base}"
        out["renamed"].append({"old": old, "new": desired})
        if args.dry_run:
            continue
        meta = sync_meta(meta_json, desired)
        with conn:
            conn.execute(
                "UPDATE tasks SET title=?, title_overridden=1, meta_json=?"
                " WHERE workspace_key=? AND task_id=?",
                (desired, meta if meta is not None else meta_json, ws_key, task_id),
            )
    return out


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--db", default=DEFAULT_DB, help=f"task index DB (default {DEFAULT_DB})")
    parser.add_argument("--dry-run", action="store_true", help="report planned writes only")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--sweep", action="store_true", help="groom the task list (default)")
    mode.add_argument(
        "--set-title", nargs=2, metavar=("TASK_ID", "TITLE"),
        help="set one task's title; stamps it with the task's own last-activity mm-dd date (a supplied stamp is normalized)",
    )
    parser.add_argument("--hours", type=float, default=24.0,
                        help="sweep window in hours of last activity (default 24)")
    parser.add_argument("--all", action="store_true",
                        help="sweep every non-deleted task, not just the recent window")
    parser.add_argument("--pin", dest="pin", action="store_true", default=True,
                        help="pin tasks active within --pin-hours (default)")
    parser.add_argument("--no-pin", dest="pin", action="store_false",
                        help="skip pinning recently-active tasks (does not disable --unpin-days)")
    parser.add_argument("--pin-hours", type=float, default=24.0,
                        help="pin window in hours of last activity (default 24)")
    parser.add_argument("--unpin-days", type=float, default=None, metavar="N",
                        help="also unpin tasks inactive for N days (default: never)")
    parser.add_argument("--include-cron", action="store_true",
                        help="also touch automation-owned tasks (default: skip)")
    parser.add_argument("--group", metavar="NAME", default=None,
                        help="add pinned-window tasks to this named task group")
    args = parser.parse_args(argv)

    conn = open_db(args.db, require_groups=bool(args.group))
    try:
        if args.set_title:
            report = run_set_title(conn, args)
        else:
            report = run_sweep(conn, args)
    finally:
        conn.close()

    json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
