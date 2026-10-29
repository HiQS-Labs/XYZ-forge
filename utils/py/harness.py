#!/usr/bin/env python3
"""Harness registry alias plus the isolated GH-1248 factory-primitive subcommand."""
from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import shutil
import sys
import threading
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from proc_group import run_bounded
from releases_app import connect as gateway_connect

PACKAGE = Path(__file__).resolve().parent / "factory_primitive"
ENTRYPOINT = Path(__file__).resolve()
REPO_ROOT = PACKAGE.parents[2]
DEFAULT_RUN_ROOT = REPO_ROOT / "temp" / "factory-primitive"
TOOLS = {"note", "summarize", "probe", "idle"}
FAULTS = {"", "malformed-decision", "disallowed-decision", "escape-create", "escape-modify",
          "escape-external", "crash-intent", "crash-act", "crash-before-snapshot", "unbilled-error",
          "timeout-unknown", "tool-failure", "missing-receipt"}
TERMINAL = {"completed", "paused", "uncertain", "unpersisted-intent-abort", "failed", "rejected"}
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


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def canonical(value) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def connect(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = gateway_connect(path, must_exist=False)
    conn.execute("PRAGMA busy_timeout=10000")
    conn.executescript(SCHEMA)
    return conn


def emit(conn, instance: Path, tick_id: str | None, stage: str, status: str, **fields) -> None:
    record = {"ts": utcnow(), "tick_id": tick_id, "stage": stage, "status": status, **fields}
    payload = canonical(record)
    with conn:
        conn.execute("INSERT INTO events(ts,tick_id,stage,status,json) VALUES(?,?,?,?,?)",
                     (record["ts"], tick_id, stage, status, payload))
    telemetry = instance / "telemetry"
    telemetry.mkdir(parents=True, exist_ok=True)
    with (telemetry / "events.jsonl").open("a", encoding="utf-8") as fh:
        fh.write(payload + "\n")


def new_tick(conn, tick_id: str, slot: int) -> None:
    ts = utcnow()
    with conn:
        conn.execute("INSERT INTO ticks(tick_id,slot,status,stage,created_at,updated_at) VALUES(?,?,?,?,?,?)",
                     (tick_id, slot, "started", "start", ts, ts))


def set_stage(conn, tick_id: str, stage: str) -> None:
    with conn:
        conn.execute("UPDATE ticks SET stage=?,updated_at=? WHERE tick_id=?", (stage, utcnow(), tick_id))


def finish(conn, instance: Path, tick_id: str, status: str,
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


def quarantine(conn, ids: list[str]) -> None:
    if ids:
        with conn:
            conn.executemany("UPDATE inbox_items SET status='quarantined' WHERE id=? AND status='pending'",
                             [(item_id,) for item_id in ids])


@dataclass
class AdapterResult:
    raw: str
    normalized: str
    decision: dict | None
    actual_cost: float | None
    billing_status: str


def _decision(tool: str, args: dict, reason: str) -> dict:
    return {"tool": tool, "args": args, "reason": reason, "confidence": 1.0}


def rules_decide(snapshot: dict) -> AdapterResult:
    budget = snapshot["budget"]
    flags = snapshot["flags"]
    if flags.get("paused") or flags.get("degraded") or budget["remaining"] < 0.1 * budget["daily_cap"]:
        result = _decision("idle", {}, "paused, degraded, or below the remaining-budget threshold")
    else:
        failed = {}
        for row in snapshot["recent"]:
            if row.get("status") == "failed":
                failed[row.get("input_fingerprint")] = failed.get(row.get("input_fingerprint"), 0) + 1
        pending = snapshot["inbox"]
        result = None
        for item in pending:
            if item["kind"] == "note-request":
                candidate = _decision("note", {"inbox_id": item["id"], "text": item["body"][:180]}, "oldest note request")
            elif item["kind"] == "summarize":
                ids = [row["id"] for row in pending if row["kind"] == "summarize"][:5]
                candidate = _decision("summarize", {"inbox_ids": ids}, "oldest summarize request")
            elif item["kind"] == "probe":
                candidate = _decision("probe", {"target": item["target"]}, "oldest probe request")
            else:
                continue
            fingerprint = sha_text(canonical({"tool": candidate["tool"], "args": candidate["args"]}))
            if failed.get(fingerprint, 0) < 2:
                result = candidate
                break
        if result is None and not pending and snapshot["probe_targets"]:
            last = snapshot.get("last_probe_at")
            old = last is None or (datetime.fromisoformat(snapshot["now"]) - datetime.fromisoformat(last)).total_seconds() > 3600
            if old:
                result = _decision("probe", {"target": snapshot["probe_targets"][0]}, "periodic local probe")
        if result is None:
            result = _decision("idle", {}, "no actionable input")
    return AdapterResult(canonical(result), "ok", result, 0.0, "reported")


def _write(path: Path, content: str) -> str:
    if path.exists():
        return "already-done"
    path.write_text(content, encoding="utf-8")
    return "ok"


def execute_tool(tool: str, tick_id: str, out_dir: Path, args: dict, items: list[dict]) -> int:
    fault = os.environ.get("FACTORY_FAULT", "")
    try:
        if fault:
            if fault == "escape-create":
                (out_dir.parent / "unauthorized.txt").write_text("escape", encoding="utf-8")
            elif fault == "escape-modify":
                (out_dir.parents[1] / "canary.txt").write_text("modified", encoding="utf-8")
            elif fault == "escape-external":
                (out_dir.parents[3] / "external.txt").write_text("external", encoding="utf-8")
            elif fault == "tool-failure":
                raise RuntimeError("injected tool failure")
        suffix = ".md" if tool == "note" else ".json"
        path = out_dir / f"{tick_id}{suffix}"
        if tool == "note":
            content = f"# Observation {tick_id}\n\n{args['text']}\n"
        elif tool == "summarize":
            selected = [item for item in items if item["id"] in args["inbox_ids"]]
            content = canonical({"tick_id": tick_id, "status": "ok", "summaries": [
                {"id": item["id"], "text": item["body"][:200]} for item in selected]})
        elif tool == "probe":
            content = canonical({"tick_id": tick_id, "status": "ok", "target": args["target"],
                                 "checked_at": utcnow(), "probe": "local-no-network"})
        elif tool == "idle":
            content = canonical({"tick_id": tick_id, "status": "ok", "reason": args.get("reason", "idle")})
        else:
            raise ValueError("unknown tool")
        status = _write(path, content)
        print(canonical({"status": status, "output": str(path)}))
        return 0
    except Exception as exc:
        print(f"tool error: {exc}", file=sys.stderr)
        return 1


def load_scenario(path: Path) -> tuple[str, list[dict]]:
    raw = path.read_bytes()
    items = []
    for line in raw.decode("utf-8").splitlines():
        if line.strip():
            item = json.loads(line)
            if item.get("type") != "inbox" or not item.get("id"):
                raise ValueError("scenario contains a non-inbox or id-less record")
            if not 1 <= int(item["available_at_slot"]) <= 288:
                raise ValueError("scenario slot outside 1..288")
            items.append(item)
    ids = [item["id"] for item in items]
    if len(ids) != len(set(ids)) or not ids:
        raise ValueError("scenario must contain unique, non-empty inbox ids")
    return hashlib.sha256(raw).hexdigest(), items


def available_digest(ids: list[str]) -> str:
    return sha_text(canonical(sorted(ids)))


def generate_manifest(scenario: Path, output: Path) -> None:
    scenario_sha, items = load_scenario(scenario)
    slots = {}
    for slot in range(1, 289):
        ids = [item["id"] for item in items if item["available_at_slot"] <= slot]
        slots[str(slot)] = available_digest(ids)
    targets = sorted({item["target"] for item in items if item["kind"] == "probe" and item.get("target")})
    manifest = {"schema": "factory-primitive/scenario-manifest@1", "scenario_sha256": scenario_sha,
                "probe_targets": targets, "slots": slots}
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _config(instance: Path) -> dict:
    return json.loads((instance / "config.json").read_text(encoding="utf-8"))


def init_instance(instance: Path, scenario: Path, manifest_path: Path,
                  daily_cap: float, max_call_cost: float) -> None:
    if (instance / "state.db").exists():
        raise ValueError("instance already initialized; use a new run root")
    instance.mkdir(parents=True, exist_ok=True)
    scenario_sha, items = load_scenario(scenario)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest["scenario_sha256"] != scenario_sha:
        raise ValueError("scenario manifest hash mismatch")
    conn = connect(instance / "state.db")
    try:
        with conn:
            conn.executemany(
                "INSERT INTO inbox_items(id,available_at_slot,created_at,kind,body,target) VALUES(?,?,?,?,?,?)",
                [(i["id"], i["available_at_slot"], i["created_at"], i["kind"], i.get("body"), i.get("target")) for i in items])
        (instance / "canary.txt").write_text("do-not-modify\n", encoding="utf-8")
        prompt_sha = sha_text((PACKAGE / "prompts" / "evaluator.v1.md").read_text(encoding="utf-8"))
        config = {"daily_cap": daily_cap, "max_call_cost": max_call_cost,
                  "probe_targets": manifest["probe_targets"], "scenario_sha256": scenario_sha,
                  "scenario_path": str(scenario), "manifest_path": str(manifest_path), "prompt_sha256": prompt_sha}
        (instance / "config.json").write_text(json.dumps(config, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        emit(conn, instance, None, "init", "ok", items=len(items), scenario_sha256=scenario_sha)
    finally:
        conn.close()


class Heartbeat:
    def __init__(self, instance: Path, tick_id: str):
        self.path = instance / "heartbeat.json"
        self.record = {"tick_id": tick_id, "stage": "start", "pid": os.getpid(), "updated_at": utcnow()}
        self.stop = threading.Event()
        self.thread = threading.Thread(target=self._run, daemon=True)

    def start(self) -> None:
        self._write()
        self.thread.start()

    def _write(self) -> None:
        self.record["updated_at"] = utcnow()
        temp = self.path.with_suffix(".tmp")
        temp.write_text(canonical(self.record), encoding="utf-8")
        os.replace(temp, self.path)

    def stage(self, stage: str) -> None:
        self.record["stage"] = stage
        self._write()

    def _run(self) -> None:
        while not self.stop.wait(10):
            self._write()

    def close(self) -> None:
        self.stop.set()
        self.thread.join(timeout=1)
        self.record["stage"] = "closed"
        self._write()


def _decision_fingerprint(decision: dict) -> str:
    return sha_text(canonical({"tool": decision["tool"], "args": decision["args"]}))


def _safe_idle(reason: str) -> dict:
    return {"tool": "idle", "args": {}, "reason": reason[:200], "confidence": 0.0}


def _validate(decision: dict, snapshot: dict) -> str | None:
    if not isinstance(decision, dict) or set(decision) != {"tool", "args", "reason", "confidence"}:
        return "decision-shape"
    tool, args = decision.get("tool"), decision.get("args")
    if tool not in TOOLS or not isinstance(args, dict):
        return "tool-or-args-not-allowlisted"
    if not isinstance(decision["reason"], str) or len(decision["reason"]) > 200:
        return "reason-shape"
    if not isinstance(decision["confidence"], (int, float)) or isinstance(decision["confidence"], bool) \
            or not 0 <= decision["confidence"] <= 1:
        return "confidence-shape"
    pending = {item["id"]: item for item in snapshot["inbox"]}
    if tool == "note":
        if set(args) != {"inbox_id", "text"} or not isinstance(args.get("text"), str) \
                or not 1 <= len(args["text"]) <= 200:
            return "note-args"
        if pending.get(args.get("inbox_id"), {}).get("kind") != "note-request":
            return "note-id-not-eligible"
    elif tool == "summarize":
        if set(args) != {"inbox_ids"} or not isinstance(args.get("inbox_ids"), list) \
                or not 1 <= len(args["inbox_ids"]) <= 5 or len(set(args["inbox_ids"])) != len(args["inbox_ids"]):
            return "summarize-args"
        if any(pending.get(item_id, {}).get("kind") != "summarize" for item_id in args["inbox_ids"]):
            return "summarize-id-not-eligible"
    elif tool == "probe":
        targets = set(snapshot["probe_targets"]) | {item["target"] for item in snapshot["inbox"] if item["kind"] == "probe"}
        if set(args) != {"target"} or args.get("target") not in targets:
            return "probe-target-not-eligible"
    elif args:
        return "idle-args"
    fingerprint = _decision_fingerprint(decision)
    failures = [row for row in snapshot["recent"] if row.get("input_fingerprint") == fingerprint and row.get("status") == "failed"]
    if len(failures) >= 2:
        return "failure-suppression"
    return None


def _snapshot(conn, config: dict, slot: int) -> tuple[dict, str]:
    all_available = [row["id"] for row in conn.execute(
        "SELECT id FROM inbox_items WHERE available_at_slot<=?", (slot,))]
    digest = available_digest(all_available)
    manifest = json.loads(Path(config["manifest_path"]).read_text(encoding="utf-8"))
    if digest != manifest["slots"][str(slot)]:
        raise ValueError("scenario-synchronization-mismatch")
    rows = conn.execute(
        "SELECT * FROM inbox_items WHERE available_at_slot<=? AND status='pending' ORDER BY created_at,id", (slot,)).fetchall()
    inbox = [{"id": r["id"], "created_at": r["created_at"], "kind": r["kind"],
              "body": r["body"], "target": r["target"]} for r in rows]
    recent = [dict(row) for row in conn.execute(
        "SELECT i.tick_id,i.tool,i.args_json AS args,i.input_fingerprint,t.status,t.error "
        "FROM intents i JOIN tool_runs t USING(tick_id) ORDER BY i.persisted_at DESC LIMIT 10")]
    costs = conn.execute("SELECT billing_status,amount,actual_cost FROM reservations").fetchall()
    spent = sum(row["amount"] if row["billing_status"] == "unknown" else (row["actual_cost"] or 0) for row in costs)
    last_probe = conn.execute(
        "SELECT i.persisted_at FROM intents i JOIN tool_runs t USING(tick_id) "
        "WHERE i.tool='probe' AND t.status IN ('ok','already-done') ORDER BY i.persisted_at DESC LIMIT 1").fetchone()
    snapshot = {"tick_id": f"slot_{slot:03d}", "now": utcnow(), "inbox": inbox, "recent": recent,
                "last_probe_at": last_probe["persisted_at"] if last_probe else None,
                "budget": {"spent": spent, "remaining": config["daily_cap"] - spent,
                           "daily_cap": config["daily_cap"], "ticks_left": 289 - slot},
                "probe_targets": config["probe_targets"],
                "flags": {"paused": False, "degraded": False, "injected_faults_enabled": False}}
    payload = canonical(snapshot)
    return snapshot, payload


def _adapter(snapshot: dict, fault: str) -> AdapterResult:
    if fault == "malformed-decision":
        return AdapterResult("{not-json", "invalid-output", None, 0.0, "reported")
    if fault == "disallowed-decision":
        raw = canonical({"tool": "erase", "args": {}, "reason": "injected unknown tool", "confidence": 1})
        return AdapterResult(raw, "ok", json.loads(raw), 0.0, "reported")
    if fault == "unbilled-error":
        return AdapterResult("", "adapter-error", None, 0.0, "unbilled")
    if fault == "timeout-unknown":
        return AdapterResult("", "timeout", None, None, "unknown")
    return rules_decide(snapshot)


def _reserve(conn, tick_id: str, amount: float) -> None:
    with conn:
        conn.execute("INSERT INTO reservations(tick_id,amount,status,billing_status) VALUES(?,?,?,?)",
                     (tick_id, amount, "reserved", "pending"))


def _settle(conn, tick_id: str, result: AdapterResult) -> None:
    if result.billing_status == "unknown":
        reservation_status, actual = "held", None
    elif result.billing_status == "unbilled":
        reservation_status, actual = "released", 0.0
    else:
        reservation_status, actual = "reported", result.actual_cost
    with conn:
        conn.execute("UPDATE reservations SET status=?,billing_status=?,actual_cost=? WHERE tick_id=?",
                     (reservation_status, result.billing_status, actual, tick_id))


def _reconcile(conn, instance: Path, exclude_tick_id: str = "") -> None:
    rows = conn.execute("SELECT tick_id FROM ticks WHERE status NOT IN (%s) AND tick_id!=?" %
                        ",".join("?" for _ in TERMINAL), tuple(TERMINAL) + (exclude_tick_id,)).fetchall()
    for row in rows:
        tick_id = row["tick_id"]
        intent = conn.execute("SELECT * FROM intents WHERE tick_id=?", (tick_id,)).fetchone()
        snapshot = conn.execute("SELECT json FROM snapshots WHERE tick_id=?", (tick_id,)).fetchone()
        if intent:
            args = json.loads(intent["args_json"])
            ids = args.get("inbox_ids", []) + ([args["inbox_id"]] if "inbox_id" in args else [])
            if intent["tool"] == "probe":
                ids += [r["id"] for r in conn.execute("SELECT id FROM inbox_items WHERE kind='probe' AND target=? AND status='pending'",
                                                       (args.get("target"),))]
            quarantine(conn, ids)
            finish(conn, instance, tick_id, "uncertain", {"error": "nonterminal tick recovered; no automatic retry"})
            continue
        if snapshot:
            ids = [item["id"] for item in json.loads(snapshot["json"])["inbox"]]
            quarantine(conn, ids)
        else:
            ids = [r["id"] for r in conn.execute("SELECT id FROM inbox_items WHERE status='pending'")]
            quarantine(conn, ids)
            (instance / "PAUSE").touch()
        finish(conn, instance, tick_id, "unpersisted-intent-abort",
               {"error": "missing durable intent", "snapshot_available": bool(snapshot)})
        emit(conn, instance, tick_id, "reconcile", "unpersisted-intent-abort")


def _run_tool(instance: Path, tick_id: str, decision: dict, items: list[dict], fault: str):
    tool = decision["tool"]
    out_dir = instance / "out" / tool
    tmp_dir = instance / "tmp" / tool
    out_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir.mkdir(parents=True, exist_ok=True)
    sandbox = shutil.which("sandbox-exec")
    if not sandbox:
        raise RuntimeError("sandbox-exec unavailable; refusing uncontained tool execution")
    profile = ("(version 1)(deny default)(allow process*)(allow file-read*)(allow sysctl-read)(allow mach-lookup)"
               f"(allow file-write* (subpath \"{out_dir.resolve()}\")(subpath \"{tmp_dir.resolve()}\"))")
    argv = [sandbox, "-p", profile, sys.executable, str(ENTRYPOINT), "factory-primitive", "tool",
            "--tool", tool, "--tick-id", tick_id, "--out-dir", str(out_dir),
            "--args-json", canonical(decision["args"]), "--items-json", canonical(items)]
    env = {"PATH": "/usr/bin:/bin", "OUT_DIR": str(out_dir), "FACTORY_FAULT": fault,
           "PYTHONDONTWRITEBYTECODE": "1", "TMPDIR": str(tmp_dir)}
    return run_bounded(argv, cwd=str(instance), env=env, timeout=60, grace=1)


def _verify_output(instance: Path, tick_id: str, tool: str) -> tuple[Path, str]:
    path = instance / "out" / tool / f"{tick_id}{'.md' if tool == 'note' else '.json'}"
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError("tool output missing or empty")
    raw = path.read_bytes()
    if tool == "note":
        if tick_id not in raw.decode("utf-8"):
            raise ValueError("note output tick mismatch")
    else:
        data = json.loads(raw)
        if data.get("tick_id") != tick_id or data.get("status") not in {"ok", "already-done"}:
            raise ValueError("tool output schema mismatch")
    return path, hashlib.sha256(raw).hexdigest()


def run_tick(instance: Path, slot: int, fault: str = "") -> str:
    tick_id = f"slot_{slot:03d}"
    instance.mkdir(parents=True, exist_ok=True)
    with (instance / "lock").open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(canonical({"tick_id": tick_id, "status": "skipped-busy"}))
            return "skipped-busy"
        conn = connect(instance / "state.db")
        heartbeat = None
        try:
            existing = conn.execute("SELECT status FROM ticks WHERE tick_id=?", (tick_id,)).fetchone()
            if existing:
                if existing["status"] not in TERMINAL:
                    _reconcile(conn, instance)
                return existing["status"]
            if (instance / "PAUSE").exists():
                new_tick(conn, tick_id, slot)
                finish(conn, instance, tick_id, "paused", {"reason": "PAUSE present"})
                return "paused"
            new_tick(conn, tick_id, slot)
            heartbeat = Heartbeat(instance, tick_id)
            heartbeat.start()
            emit(conn, instance, tick_id, "tick.started", "ok", slot=slot, fault=fault or None)
            set_stage(conn, tick_id, "reconcile")
            heartbeat.stage("reconcile")
            _reconcile(conn, instance, exclude_tick_id=tick_id)
            if (instance / "PAUSE").exists():
                finish(conn, instance, tick_id, "paused", {"reason": "reconciliation required pause"})
                return "paused"
            if fault == "crash-before-snapshot":
                os._exit(70)
            config = _config(instance)
            set_stage(conn, tick_id, "observe")
            heartbeat.stage("observe")
            snapshot, payload = _snapshot(conn, config, slot)
            with conn:
                conn.execute("INSERT INTO snapshots(tick_id,json,sha256) VALUES(?,?,?)",
                             (tick_id, payload, sha_text(payload)))
            set_stage(conn, tick_id, "evaluate")
            heartbeat.stage("evaluate")
            if snapshot["budget"]["remaining"] <= 0 or snapshot["budget"]["remaining"] < config["max_call_cost"]:
                (instance / "PAUSE").touch()
                result = AdapterResult("", "budget-exhausted", None, 0.0, "unbilled")
                emit(conn, instance, tick_id, "evaluate", "budget-exhausted", agent_called=False)
            else:
                _reserve(conn, tick_id, config["max_call_cost"])
                result = _adapter(snapshot, fault)
                _settle(conn, tick_id, result)
                emit(conn, instance, tick_id, "evaluate", result.normalized, agent_called=True)
                spent = conn.execute(
                    "SELECT COALESCE(SUM(CASE WHEN billing_status='unknown' THEN amount ELSE actual_cost END),0) "
                    "FROM reservations").fetchone()[0]
                if spent >= config["daily_cap"]:
                    (instance / "PAUSE").touch()
            transcripts = instance / "telemetry" / "transcripts"
            transcripts.mkdir(parents=True, exist_ok=True)
            (transcripts / f"{tick_id}.json").write_text(canonical({
                "normalized": result.normalized, "raw": result.raw,
                "billing_status": result.billing_status, "actual_cost": result.actual_cost}), encoding="utf-8")
            if result.decision is None:
                decision = _safe_idle(f"adapter {result.normalized}")
                decision_status = result.normalized
            else:
                decision = result.decision
                decision_status = "raw-valid"
            set_stage(conn, tick_id, "validate")
            rejection = _validate(decision, snapshot) if result.decision is not None else None
            if rejection:
                decision_status = "rejected"
                with conn:
                    conn.execute("INSERT INTO decisions(tick_id,raw,status,rejected_reason) VALUES(?,?,?,?)",
                                 (tick_id, result.raw, decision_status, rejection))
                decision = _safe_idle(f"rejected: {rejection}")
            with conn:
                if rejection:
                    conn.execute("UPDATE decisions SET validated_json=? WHERE tick_id=?", (canonical(decision), tick_id))
                else:
                    conn.execute("INSERT INTO decisions(tick_id,raw,validated_json,status) VALUES(?,?,?,?)",
                                 (tick_id, result.raw, canonical(decision), decision_status))
            emit(conn, instance, tick_id, "validate", decision_status, rejection=rejection)
            if fault == "crash-intent":
                os._exit(70)
            set_stage(conn, tick_id, "intent")
            with conn:
                conn.execute("INSERT INTO intents(tick_id,tool,args_json,input_fingerprint,persisted_at) VALUES(?,?,?,?,?)",
                             (tick_id, decision["tool"], canonical(decision["args"]), _decision_fingerprint(decision), utcnow()))
            set_stage(conn, tick_id, "act")
            heartbeat.stage("act")
            with conn:
                conn.execute("UPDATE intents SET tool_started_at=? WHERE tick_id=?", (utcnow(), tick_id))
            if fault == "crash-act":
                os._exit(70)
            completed = _run_tool(instance, tick_id, decision, snapshot["inbox"], fault)
            if completed.timed_out or completed.rc != 0:
                error = "tool-timeout" if completed.timed_out else (completed.stderr.strip() or "tool-failure")
                with conn:
                    conn.execute("INSERT INTO tool_runs(tick_id,rc,status,error) VALUES(?,?,?,?)",
                                 (tick_id, completed.rc, "failed", error))
                finish(conn, instance, tick_id, "failed", {"error": error, "decision_status": decision_status})
                return "failed"
            output, output_sha = _verify_output(instance, tick_id, decision["tool"])
            with conn:
                conn.execute("INSERT INTO tool_runs(tick_id,rc,status,output_path,sha256) VALUES(?,?,?,?,?)",
                             (tick_id, completed.rc, "ok", str(output), output_sha))
            if fault == "missing-receipt":
                os._exit(70)
            consumed = []
            if decision["tool"] == "note":
                consumed = [decision["args"]["inbox_id"]]
            elif decision["tool"] == "summarize":
                consumed = decision["args"]["inbox_ids"]
            elif decision["tool"] == "probe":
                consumed = [item["id"] for item in snapshot["inbox"]
                            if item["kind"] == "probe" and item["target"] == decision["args"]["target"]]
            finish(conn, instance, tick_id, "completed", {
                "tool": decision["tool"], "decision_status": decision_status, "output_sha256": output_sha}, consumed)
            return "completed"
        except Exception as exc:
            emit(conn, instance, tick_id, "error", "failed", error=str(exc))
            existing = conn.execute("SELECT status FROM ticks WHERE tick_id=?", (tick_id,)).fetchone()
            if existing and existing["status"] not in TERMINAL:
                finish(conn, instance, tick_id, "failed", {"error": str(exc)})
            return "failed"
        finally:
            if heartbeat:
                heartbeat.close()
            conn.close()
            fcntl.flock(lock, fcntl.LOCK_UN)


def status(instance: Path) -> dict:
    conn = connect(instance / "state.db")
    try:
        counts = {row["status"]: row["n"] for row in conn.execute("SELECT status,COUNT(*) n FROM ticks GROUP BY status")}
        pending = conn.execute("SELECT COUNT(*) n FROM inbox_items WHERE status='pending'").fetchone()["n"]
        quarantined = conn.execute("SELECT COUNT(*) n FROM inbox_items WHERE status='quarantined'").fetchone()["n"]
        reservations = [dict(row) for row in conn.execute("SELECT * FROM reservations ORDER BY rowid")]
        spent = sum(row["amount"] if row["billing_status"] == "unknown" else (row["actual_cost"] or 0) for row in reservations)
        return {"ticks": counts, "pending": pending, "quarantined": quarantined,
                "paused": (instance / "PAUSE").exists(), "spent_or_reserved": spent,
                "unknown_cost": any(row["billing_status"] == "unknown" for row in reservations)}
    finally:
        conn.close()


def _run_root(value: str | None) -> Path:
    root = Path(value).resolve() if value else DEFAULT_RUN_ROOT.resolve()
    try:
        root.relative_to(DEFAULT_RUN_ROOT.resolve())
    except ValueError as exc:
        raise ValueError(f"run root must stay under {DEFAULT_RUN_ROOT}") from exc
    return root


def factory_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="harness.py factory-primitive",
                                description="GH-1248 deterministic outer-loop primitive")
    p.add_argument("--run-root", help="mutable run root under temp/factory-primitive")
    sub = p.add_subparsers(dest="command", required=True)
    init = sub.add_parser("init")
    init.add_argument("--instance", default="C")
    init.add_argument("--scenario", type=Path, default=PACKAGE / "scenarios" / "soak-v1.jsonl")
    init.add_argument("--manifest", type=Path, default=PACKAGE / "scenarios" / "soak-v1.manifest.json")
    init.add_argument("--daily-cap", type=float, default=1.0)
    init.add_argument("--max-call-cost", type=float, default=0.0)
    manifest = sub.add_parser("generate-manifest")
    manifest.add_argument("--scenario", type=Path, default=PACKAGE / "scenarios" / "soak-v1.jsonl")
    manifest.add_argument("--output", type=Path, default=PACKAGE / "scenarios" / "soak-v1.manifest.json")
    tick = sub.add_parser("tick")
    tick.add_argument("--instance", default="C")
    tick.add_argument("--slot", type=int, required=True)
    tick.add_argument("--fault", choices=sorted(FAULTS), default="")
    stat = sub.add_parser("status")
    stat.add_argument("--instance", default="C")
    tool = sub.add_parser("tool")
    tool.add_argument("--tool", required=True, choices=sorted(TOOLS))
    tool.add_argument("--tick-id", required=True)
    tool.add_argument("--out-dir", type=Path, required=True)
    tool.add_argument("--args-json", required=True)
    tool.add_argument("--items-json", required=True)
    return p


def factory_main(argv: list[str]) -> int:
    args = factory_parser().parse_args(argv)
    try:
        if args.command == "tool":
            return execute_tool(args.tool, args.tick_id, args.out_dir,
                                json.loads(args.args_json), json.loads(args.items_json))
        if args.command == "generate-manifest":
            generate_manifest(args.scenario, args.output)
            return 0
        root = _run_root(args.run_root)
        if args.instance in {"", ".", ".."} or not all(c.isalnum() or c in "-_." for c in args.instance):
            raise ValueError("instance must be a simple name without path separators")
        instance = (root / "instances" / args.instance).resolve()
        instance.relative_to((root / "instances").resolve())
        if args.command == "init":
            if args.daily_cap <= 0 or args.max_call_cost < 0 or args.max_call_cost > args.daily_cap:
                raise ValueError("invalid daily cap or maximum call cost")
            init_instance(instance, args.scenario.resolve(), args.manifest.resolve(),
                          args.daily_cap, args.max_call_cost)
            print(canonical({"status": "initialized", "instance": str(instance)}))
            return 0
        if args.command == "tick":
            if not 1 <= args.slot <= 288:
                raise ValueError("slot must be in 1..288")
            outcome = run_tick(instance, args.slot, args.fault)
            print(canonical({"tick_id": f"slot_{args.slot:03d}", "status": outcome}))
            return 0 if outcome in {"completed", "paused", "uncertain", "unpersisted-intent-abort"} else 1
        if args.command == "status":
            print(json.dumps(status(instance), indent=2, sort_keys=True))
            return 0
        raise ValueError("unknown command")
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(f"factory-primitive: {exc}", file=sys.stderr)
        return 2


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "factory-primitive":
        return factory_main(sys.argv[2:])
    from harness_app import main as registry_main
    return registry_main()


if __name__ == "__main__":
    sys.exit(main())
