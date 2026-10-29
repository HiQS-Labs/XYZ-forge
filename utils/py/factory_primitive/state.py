from __future__ import annotations

import hashlib
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = """
PRAGMA journal_mode=WAL;
PRAGMA synchronous=FULL;
CREATE TABLE IF NOT EXISTS ticks(
  tick_id TEXT PRIMARY KEY, slot INTEGER NOT NULL, status TEXT NOT NULL,
  stage TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, error TEXT
);
CREATE TABLE IF NOT EXISTS snapshots(
  tick_id TEXT PRIMARY KEY, json TEXT NOT NULL, sha256 TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS decisions(
  tick_id TEXT PRIMARY KEY, raw TEXT, validated_json TEXT, status TEXT NOT NULL,
  rejected_reason TEXT
);
CREATE TABLE IF NOT EXISTS intents(
  tick_id TEXT PRIMARY KEY, tool TEXT NOT NULL, args_json TEXT NOT NULL,
  input_fingerprint TEXT NOT NULL, persisted_at TEXT NOT NULL, tool_started_at TEXT
);
CREATE TABLE IF NOT EXISTS tool_runs(
  tick_id TEXT PRIMARY KEY, rc INTEGER, status TEXT NOT NULL, output_path TEXT,
  sha256 TEXT, error TEXT
);
CREATE TABLE IF NOT EXISTS receipts(
  tick_id TEXT PRIMARY KEY, status TEXT NOT NULL, json TEXT NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS inbox_items(
  id TEXT PRIMARY KEY, available_at_slot INTEGER NOT NULL, created_at TEXT NOT NULL,
  kind TEXT NOT NULL, body TEXT, target TEXT, status TEXT NOT NULL DEFAULT 'pending'
);
CREATE TABLE IF NOT EXISTS reservations(
  tick_id TEXT PRIMARY KEY, amount REAL NOT NULL, status TEXT NOT NULL,
  billing_status TEXT NOT NULL, actual_cost REAL
);
CREATE TABLE IF NOT EXISTS events(
  id INTEGER PRIMARY KEY AUTOINCREMENT, ts TEXT NOT NULL, tick_id TEXT,
  stage TEXT NOT NULL, status TEXT NOT NULL, json TEXT NOT NULL
);
"""

TERMINAL = {"completed", "paused", "uncertain", "unpersisted-intent-abort", "failed", "rejected"}


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def canonical(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def connect(path: Path) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path, timeout=10, isolation_level=None)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA)
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def emit(conn: sqlite3.Connection, instance: Path, tick_id: str | None,
         stage: str, status: str, **fields) -> None:
    record = {"ts": utcnow(), "tick_id": tick_id, "stage": stage, "status": status, **fields}
    payload = canonical(record)
    with conn:
        conn.execute("INSERT INTO events(ts,tick_id,stage,status,json) VALUES(?,?,?,?,?)",
                     (record["ts"], tick_id, stage, status, payload))
    telemetry = instance / "telemetry"
    telemetry.mkdir(parents=True, exist_ok=True)
    with (telemetry / "events.jsonl").open("a", encoding="utf-8") as fh:
        fh.write(payload + "\n")


def new_tick(conn: sqlite3.Connection, tick_id: str, slot: int) -> None:
    ts = utcnow()
    with conn:
        conn.execute("INSERT INTO ticks(tick_id,slot,status,stage,created_at,updated_at) VALUES(?,?,?,?,?,?)",
                     (tick_id, slot, "started", "start", ts, ts))


def set_stage(conn: sqlite3.Connection, tick_id: str, stage: str) -> None:
    with conn:
        conn.execute("UPDATE ticks SET stage=?,updated_at=? WHERE tick_id=?", (stage, utcnow(), tick_id))


def finish(conn: sqlite3.Connection, instance: Path, tick_id: str, status: str,
           details: dict, consumed: list[str] | None = None) -> None:
    ts = utcnow()
    payload = canonical(details)
    with conn:
        if consumed:
            conn.executemany("UPDATE inbox_items SET status='consumed' WHERE id=? AND status='pending'",
                             [(item_id,) for item_id in consumed])
        conn.execute("UPDATE ticks SET status=?,stage='record',updated_at=?,error=? WHERE tick_id=?",
                     (status, ts, details.get("error"), tick_id))
        conn.execute("INSERT INTO receipts(tick_id,status,json,created_at) VALUES(?,?,?,?)",
                     (tick_id, status, payload, ts))
    emit(conn, instance, tick_id, "tick.completed", status, **details)


def quarantine(conn: sqlite3.Connection, ids: list[str]) -> None:
    if ids:
        with conn:
            conn.executemany("UPDATE inbox_items SET status='quarantined' WHERE id=? AND status='pending'",
                             [(item_id,) for item_id in ids])
