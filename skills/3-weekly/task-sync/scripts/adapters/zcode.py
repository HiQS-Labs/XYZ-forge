"""ZCode adapter — grooms the ZCode app's task index.

Behavior-verbatim port of the relay-QA'd ``utils/zcode/task-stamp/
scripts/sweep_tasks.py`` (PR #893, attested PASS) onto the task-sync
adapter contract. Owns only this app's store I/O:
``~/.zcode/v2/tasks-index.sqlite``.

Pin model: **derive-by-window** — tasks active within ``--pin-hours``
get ``pinned=1``; the app's PINNED section renders them.
"""

from __future__ import annotations

import json
import os
import sqlite3
import uuid
from datetime import datetime

import core

DEFAULT_DB = os.path.expanduser("~/.zcode/v2/tasks-index.sqlite")

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


def _sync_meta(meta_json: str, title: str) -> str | None:
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


class ZcodeAdapter:
    NAME = "zcode"

    def __init__(self, db_path: str | None = None, apply: bool = False):
        self.db_path = db_path or DEFAULT_DB
        self.apply = apply

    # -- safety surface -------------------------------------------------

    def _connect(self) -> sqlite3.Connection:
        if not os.path.exists(self.db_path):
            raise core.AdapterError(f"zcode: task index DB not found at {self.db_path}")
        conn = sqlite3.connect(self.db_path, timeout=5.0)  # SQLITE-BYPASS-OK: external app store (~/.zcode task index), not a repo ledger — GH-777 gateway is releases-ledger-specific
        conn.execute("PRAGMA busy_timeout=5000")
        return conn

    def _check_schema(self, conn: sqlite3.Connection, require_groups: bool) -> None:
        def columns(table: str) -> set[str]:
            rows = conn.execute(f"PRAGMA table_info({table})").fetchall()
            return {row[1] for row in rows}

        missing = EXPECTED_TASK_COLUMNS - columns("tasks")
        if missing:
            raise core.AdapterError(
                f"zcode: tasks table missing expected columns: {sorted(missing)}"
            )
        for table, expected in (("task_groups", EXPECTED_GROUP_COLUMNS),
                                ("task_group_members", EXPECTED_MEMBER_COLUMNS)):
            present = columns(table)
            if not present:
                if require_groups:
                    raise core.AdapterError(
                        f"zcode: --group needs the {table} table; not found in this index"
                    )
                continue
            if expected - present:
                raise core.AdapterError(
                    f"zcode: {table} table missing expected columns: {sorted(expected - present)}"
                )

    # -- public contract ------------------------------------------------

    def doctor(self) -> dict:
        """Read-only health: store reachability, schema, WAL, receipt."""
        out = {"store": self.db_path, "ok": True, "reds": []}
        try:
            conn = self._connect()
        except core.AdapterError as exc:
            out.update(ok=False, reds=[str(exc)])
            return out
        try:
            self._check_schema(conn, require_groups=False)
            mode = conn.execute("PRAGMA journal_mode").fetchone()[0]
            out["journal_mode"] = mode
            tasks = conn.execute(
                "SELECT COUNT(*) FROM tasks WHERE deleted=0 AND archived=0"
            ).fetchone()[0]
            out["active_tasks"] = tasks
        except core.AdapterError as exc:
            out.update(ok=False, reds=[str(exc)])
        except sqlite3.Error as exc:
            out.update(ok=False, reds=[f"zcode: sqlite error: {exc}"])
        finally:
            conn.close()
        return out

    def sweep(
        self,
        hours: float = 24.0,
        include_all: bool = False,
        pin: bool = True,
        pin_hours: float = 24.0,
        unpin_days: float | None = None,
        include_cron: bool = False,
        group: str | None = None,
    ) -> dict:
        rep = core.new_ide_report()
        conn = self._connect()
        try:
            self._check_schema(conn, require_groups=bool(group))
            self._sweep_locked(conn, rep, hours, include_all, pin, pin_hours,
                               unpin_days, include_cron, group)
        except core.AdapterError:
            raise
        except sqlite3.Error as exc:
            raise core.AdapterError(f"zcode: sqlite error: {exc}") from exc
        finally:
            conn.close()
        return rep

    def set_title(self, task_id: str, description: str) -> dict:
        """Write a reviewed title, stamped from each row's own
        last-activity date (a caller-supplied stamp is normalized)."""
        if not description.strip():
            raise core.AdapterError("zcode: --set-title requires a non-empty title")
        conn = self._connect()
        out = {"task_id": task_id, "found": False, "renamed": []}
        try:
            rows = conn.execute(
                "SELECT workspace_key, task_id, title, meta_json, updated_at"
                " FROM tasks WHERE task_id=?",
                (task_id,),
            ).fetchall()
            if not rows:
                return out
            out["found"] = True
            base = core.clean_base(description)
            if not base:
                raise core.AdapterError(
                    "zcode: --set-title requires a non-empty description"
                )
            if not self.apply:
                for ws_key, _, old, _meta, updated_at in rows:
                    out["renamed"].append(
                        {"old": old, "new": f"{core.local_stamp(core.ms_to_local_dt(updated_at))} {base}"}
                    )
                return out
            for ws_key, _, old, meta_json, updated_at in rows:
                desired = f"{core.local_stamp(core.ms_to_local_dt(updated_at))} {base}"
                meta = _sync_meta(meta_json, desired)
                with conn:
                    conn.execute(
                        "UPDATE tasks SET title=?, title_overridden=1, meta_json=?"
                        " WHERE workspace_key=? AND task_id=?",
                        (desired, meta if meta is not None else meta_json, ws_key, task_id),
                    )
                out["renamed"].append({"old": old, "new": desired})
        except core.AdapterError:
            raise
        except sqlite3.Error as exc:
            raise core.AdapterError(f"zcode: sqlite error: {exc}") from exc
        finally:
            conn.close()
        return out

    # -- sweep internals (ported) ----------------------------------------

    def _sweep_locked(self, conn, rep, hours, include_all, pin, pin_hours,
                      unpin_days, include_cron, group) -> None:
        now_ms = int(datetime.now().timestamp() * 1000)
        pin_cutoff = int((datetime.now().timestamp() - pin_hours * 3600) * 1000)
        unpin_cutoff = (
            int((datetime.now().timestamp() - unpin_days * 86400) * 1000)
            if unpin_days is not None
            else None
        )

        if include_all:
            rows = conn.execute(
                "SELECT workspace_key, workspace_path, workspace_identity, task_id, title,"
                " title_overridden, pinned, updated_at, meta_json, cron_automation_id"
                " FROM tasks WHERE deleted=0 AND archived=0 ORDER BY updated_at DESC"
            ).fetchall()
        else:
            cutoff = int((datetime.now().timestamp() - hours * 3600) * 1000)
            rows = conn.execute(
                "SELECT workspace_key, workspace_path, workspace_identity, task_id, title,"
                " title_overridden, pinned, updated_at, meta_json, cron_automation_id"
                " FROM tasks WHERE deleted=0 AND archived=0 AND updated_at >= ?"
                " ORDER BY updated_at DESC",
                (cutoff,),
            ).fetchall()

        group_id = None
        if group:
            row = conn.execute(
                "SELECT group_id FROM task_groups WHERE title=?", (group,)
            ).fetchone()
            if row:
                group_id = row[0]
            elif self.apply:
                with conn:
                    gid = f"grp-{uuid.uuid4()}"
                    conn.execute(
                        "INSERT INTO task_groups (group_id, title, color, created_at, updated_at)"
                        " VALUES (?,?,?,?,?)",
                        (gid, group, "gray", now_ms, now_ms),
                    )
                    group_id = gid
            else:
                rep["group_note"] = f"dry-run: would create group {group!r}"

        writes: list[tuple[str, tuple]] = []

        for row in rows:
            (ws_key, ws_path, ws_identity, task_id, title, title_overridden,
             pinned, updated_at, meta_json, cron_id) = row
            if cron_id and not include_cron:
                rep["skipped"] += 1
                continue
            rep["swept"] += 1

            stamp = core.local_stamp(core.ms_to_local_dt(updated_at))
            base = core.clean_base(title)
            new_title = f"{stamp} {base}" if base else title
            if new_title != title:
                meta = _sync_meta(meta_json, new_title)
                rep["renamed"].append(
                    {"task_id": task_id, "workspace_path": ws_path,
                     "old": title, "new": new_title}
                )
                writes.append((
                    "UPDATE tasks SET title=?, title_overridden=1, meta_json=?"
                    " WHERE workspace_key=? AND task_id=?",
                    (new_title, meta if meta is not None else meta_json, ws_key, task_id),
                ))

            if updated_at >= pin_cutoff:
                if pin and not pinned:
                    rep["pinned"].append({"task_id": task_id, "title": new_title})
                    writes.append((
                        "UPDATE tasks SET pinned=1 WHERE workspace_key=? AND task_id=?",
                        (ws_key, task_id),
                    ))
                if group_id:
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
                        rep.setdefault("group_added", []).append(
                            {"task_id": task_id, "group": group}
                        )

            if title_overridden == 0:
                rep["needs_summary"].append(
                    {"task_id": task_id, "workspace_path": ws_path, "title": new_title}
                )

        if unpin_cutoff is not None:
            stale = conn.execute(
                "SELECT workspace_key, task_id, title FROM tasks WHERE pinned=1 AND deleted=0"
                " AND archived=0 AND updated_at < ?",
                (unpin_cutoff,),
            ).fetchall()
            for ws_key, task_id, title in stale:
                rep["unpinned"].append({"task_id": task_id, "title": title})
                writes.append((
                    "UPDATE tasks SET pinned=0 WHERE workspace_key=? AND task_id=?",
                    (ws_key, task_id),
                ))

        if self.apply and writes:
            with conn:
                for sql, params in writes:
                    conn.execute(sql, params)
