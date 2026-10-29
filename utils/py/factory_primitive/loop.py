from __future__ import annotations

import fcntl
import hashlib
import json
import os
import shutil
import sys
import threading
import time
from pathlib import Path

from .adapters import AdapterResult, rules_decide
from proc_group import run_bounded
from .state import (TERMINAL, canonical, connect, emit, finish, new_tick, quarantine,
                    set_stage, sha_text, utcnow)

PACKAGE = Path(__file__).resolve().parent
ENTRYPOINT = PACKAGE.parent / "factory-primitive.py"
TOOLS = {"note", "summarize", "probe", "idle"}


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
        status, actual = "held", None
    elif result.billing_status == "unbilled":
        status, actual = "released", 0.0
    else:
        status, actual = "reported", result.actual_cost
    with conn:
        conn.execute("UPDATE reservations SET status=?,billing_status=?,actual_cost=? WHERE tick_id=?",
                     (status, result.billing_status, actual, tick_id))


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
    argv = [sandbox, "-p", profile, sys.executable, str(ENTRYPOINT), "tool", "--tool", tool,
            "--tick-id", tick_id, "--out-dir", str(out_dir), "--args-json", canonical(decision["args"]),
            "--items-json", canonical(items)]
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
                status = result.normalized
            else:
                decision = result.decision
                status = "raw-valid"
            set_stage(conn, tick_id, "validate")
            rejection = _validate(decision, snapshot) if result.decision is not None else None
            if rejection:
                status = "rejected"
                with conn:
                    conn.execute("INSERT INTO decisions(tick_id,raw,status,rejected_reason) VALUES(?,?,?,?)",
                                 (tick_id, result.raw, status, rejection))
                decision = _safe_idle(f"rejected: {rejection}")
            with conn:
                if rejection:
                    conn.execute("UPDATE decisions SET validated_json=? WHERE tick_id=?", (canonical(decision), tick_id))
                else:
                    conn.execute("INSERT INTO decisions(tick_id,raw,validated_json,status) VALUES(?,?,?,?)",
                                 (tick_id, result.raw, canonical(decision), status))
            emit(conn, instance, tick_id, "validate", status, rejection=rejection)
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
                finish(conn, instance, tick_id, "failed", {"error": error, "decision_status": status})
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
                "tool": decision["tool"], "decision_status": status, "output_sha256": output_sha}, consumed)
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
