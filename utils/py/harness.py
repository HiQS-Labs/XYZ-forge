#!/usr/bin/env python3
"""Harness registry alias plus the isolated GH-1248 factory-primitive subcommand."""
from __future__ import annotations

import argparse
import copy
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
from contextlib import closing
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

from proc_group import run_bounded
from releases_app import connect as gateway_connect

PACKAGE = Path(__file__).resolve().parent / "factory_primitive"
ENTRYPOINT = Path(__file__).resolve()
REPO_ROOT = PACKAGE.parents[2]
DEFAULT_RUN_ROOT = REPO_ROOT / "temp" / "factory-primitive"
TOOLS = {"note", "summarize", "probe", "idle", "plan-draft"}
FAULTS = {"", "malformed-decision", "disallowed-decision", "escape-create", "escape-modify",
          "escape-external", "crash-intent", "crash-act", "crash-before-snapshot", "unbilled-error",
          "timeout-unknown", "tool-failure", "missing-receipt",
          # GH-1257 plan-draft output controls (each must end the tick uncertain + quarantined)
          "fail-after-output", "corrupt-issue-hash", "drop-key", "md-mismatch", "drop-file"}
DRAFT_LABEL = "draft; preflight and independent plan QA outstanding"
BRIEF_KEYS = ("schema", "tick_id", "status", "label", "request_id", "issue", "title", "issue_sha256",
              "issue_updated_at", "doc_path", "doc_sha256", "planner_state", "planner_flags", "rating",
              "existing_contract", "deps", "scope", "acceptance", "open_questions", "write_set",
              "draft_status", "held_reason", "unresolved_names", "probe_results")
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
            elif item["kind"] == "plan-request":
                candidate = _decision("plan-draft", {"inbox_id": item["id"]}, "oldest plan request")
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


def execute_tool(tool: str, tick_id: str, out_dir: Path, args: dict, items: list[dict],
                 context: dict | None = None) -> int:
    fault = os.environ.get("FACTORY_FAULT", "")
    try:
        if tool == "plan-draft":
            plan_draft(tick_id, out_dir, args, (context or {}).get("accepted", []), fault)
            print(canonical({"status": "ok", "output": str(out_dir / f"{tick_id}.json")}))
            return 0
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


# ── GH-1257: read-only backlog-to-wave pilot (plan-draft) ───────────────────────────────────
SECTION_KINDS = (("scope", ("scope", "goal", "outcome")),
                 ("acceptance", ("acceptance", "definition of done", "done when")),
                 ("open_questions", ("open question", "unknown")))
PATH_RE = re.compile(r"(?<![\w/.:-])((?:\.{1,2}/)*(?:[\w.-]+/)+[\w.-]+)")
# GH-1261: a file named without a directory, e.g. `wave_reconcile.py`.
BARE_RE = re.compile(r"(?<![\w/.:-])([\w-][\w.-]*\.(?:py|sh|md|js|ts|json|ya?ml|sql|toml|txt))(?![\w/-]|\.\w)")


def _planner(backlog: Path, gh: str):
    """The existing marathon planner over the instance's frozen ledger copy, never live state."""
    import _marathon_plan
    now = utcnow()
    cfg = {"root": str(REPO_ROOT), "roadmap": str(REPO_ROOT / "ROADMAP.md"),
           "queue_dir": str(REPO_ROOT / "PROJECT" / "2-WORKING"), "today": now[:10], "now": now,
           "policy": "quick-wins", "format": "text", "deep": False, "require_gh": False,
           "utils_dir": str(REPO_ROOT / "utils"), "releases_db": str(backlog / "releases.db"),
           "branches_file": str(backlog / "branches.txt"), "base_files_file": str(backlog / "base-files.txt")}
    if gh == "off":
        cfg["gh_force"] = "off"
    else:
        cfg["gh_state_file"] = str(backlog / "gh-state.json")
    return _marathon_plan.Engine(cfg)


def _sections(text: str, source: str) -> dict:
    """Headed scope / acceptance / open-question sections, each with its source line."""
    found = {kind: [] for kind, _ in SECTION_KINDS}
    lines = (text or "").splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if not m:
            continue
        heading = m.group(2).strip().lower()
        if "non-goal" in heading or "non goal" in heading:
            continue
        kind = next((k for k, words in SECTION_KINDS if any(w in heading for w in words)), None)
        if not kind:
            continue
        body = []
        for nxt in lines[i + 1:]:
            n = re.match(r"^(#{1,6})\s", nxt)
            if n and len(n.group(1)) <= len(m.group(1)):
                break
            body.append(nxt)
        content = "\n".join(body).strip()
        if content:
            found[kind].append({"heading": m.group(2).strip(), "text": content[:1500],
                                "source": f"{source}:L{i + 1}"})
    return found


def _frontmatter_goal(doc_text: str) -> tuple[int, str] | None:
    """(line, text) of the YAML frontmatter `goal:`, decoding folded/literal block scalars."""
    lines = doc_text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            return None
        m = re.match(r"^goal:\s*(.*)$", line)
        if not m:
            continue
        value = m.group(1).strip()
        if re.fullmatch(r"[>|][-+]?", value):
            block = []
            for nxt in lines[i + 1:]:
                if nxt.strip() and not nxt.startswith((" ", "\t")):
                    break
                block.append(nxt.strip())
            value = ("\n" if value.startswith("|") else " ").join(b for b in block if b).strip()
        value = value.strip().strip('"\'').strip()
        return (i + 1, value) if value else None
    return None


def _file_index(listing: str) -> dict:
    """Tracked paths from the frozen `git ls-tree` listing, plus a basename lookup."""
    files = [p for p in listing.splitlines() if p]
    names = {}
    for p in files:
        names.setdefault(p.rsplit("/", 1)[-1], []).append(p)
    return {"files": set(files), "names": names}


def _cited_paths(text: str, source: str, root: Path = REPO_ROOT, index: dict | None = None,
                 unresolved: list | None = None) -> list[dict]:
    """Existing repository files cited in text; anything resolving outside root is dropped.
    With a frozen file index, a vendored `.xyz/` path maps to the same path here and a bare
    file name resolves when exactly one tracked file has it; a name with several matches is
    appended to `unresolved`, never guessed (GH-1261)."""
    out, seen = [], set()
    real_root = os.path.realpath(root)

    def exists(rel):
        real = os.path.realpath(os.path.join(root, rel))
        return os.path.commonpath([real, real_root]) == real_root and os.path.isfile(real)

    def add(rel, n):
        if rel not in seen:
            seen.add(rel)
            out.append({"path": rel, "source": f"{source}:L{n}"})
    for n, line in enumerate((text or "").splitlines(), 1):
        line = re.sub(r"https?://\S+", " ", line)
        for m in PATH_RE.finditer(line):
            raw = m.group(1).rstrip(".,:;)")
            rel = os.path.normpath(raw)
            if os.path.isabs(raw) or rel.startswith("..") or rel in {".", ""}:
                continue
            if index and rel.startswith(".xyz/") and not exists(rel) and rel[5:] in index["files"]:
                rel = rel[5:]
            if exists(rel):
                add(rel, n)
        if not index:
            continue
        for m in BARE_RE.finditer(line):
            name = m.group(1)
            hits = index["names"].get(name, [])
            if len(hits) == 1 and exists(hits[0]):
                add(hits[0], n)
            elif len(hits) > 1 and unresolved is not None and all(u["name"] != name for u in unresolved):
                unresolved.append({"name": name, "source": f"{source}:L{n}", "matches": len(hits)})
    return out


def _unregistered_record(issue: int, title: str, body: str) -> dict:
    """A planner-shaped record for an open issue with no ledger row (GH-1261). Its state is
    not a resolved one, so a dependency on it stays unmet until it is placed in a wave."""
    import _marathon_plan
    return {"gh": issue, "title": title, "raw": "", "slug": f"gh-{issue}", "docRel": None,
            "deps": _marathon_plan.Engine._deps_of({"raw": f"{title}\n{body}"}), "state": "unregistered",
            "contract": None, "flags": [], "signals": [], "dbAxes": None, "writeset": [],
            "zone": None, "zoneRule": None, "zoneInferred": False}


def render_brief(b: dict) -> str:
    def block(title, entries):
        out = [f"## {title}", ""]
        if not entries:
            return out + ["_missing_", ""]
        for e in entries:
            out += [f"_Source: {e['source']} ({e['heading']})_", "", e["text"], ""]
        return out
    lines = [f"# Plan draft: #{b['issue']} {b['title']}", "", f"> {b['label']}", "",
             f"- Request: `{b['request_id']}` (tick `{b['tick_id']}`)",
             f"- Draft status: **{b['draft_status']}**" + (f" (held: {b['held_reason']})" if b["held_reason"] else ""),
             f"- Planner state: {b['planner_state']}; flags: {', '.join(b['planner_flags']) or 'none'}",
             f"- Rating: {b['rating'] or 'none'}",
             f"- Capture doc: {b['doc_path'] or 'none'} (sha256 {b['doc_sha256'] or 'none'})",
             f"- Issue sha256: {b['issue_sha256']} (updated {b['issue_updated_at']})",
             f"- Dependencies: {', '.join('#' + str(d) for d in b['deps']) or 'none'}", ""]
    lines += block("Scope", b["scope"]) + block("Acceptance criteria", b["acceptance"])
    lines += block("Open questions", b["open_questions"]) + ["## Write set", ""]
    lines += [f"- `{w['path']}` ({w['source']})" for w in b["write_set"]] or ["_none sourced_"]
    lines += ["", "## Unresolved file names", ""]
    lines += [f"- `{u['name']}` ({u['source']}; {u['matches']} tracked files share this name)"
              for u in b["unresolved_names"]] or ["- none"]
    lines += ["", "## Contract probes", ""]
    lines += [f"- {p['type']} `{p['path']}`: {p['result']}" for p in b["probe_results"]] or ["- none"]
    if b["existing_contract"]:
        lines += ["", "## Existing preflight contract", "", "```json",
                  json.dumps(b["existing_contract"], indent=2, sort_keys=True), "```"]
    return "\n".join(lines) + "\n"


def render_proposal(p: dict) -> str:
    def waves(ws):
        return [f"- Wave {i}: " + ", ".join(f"#{lane['issue']}" + (" (provisional)" if lane.get("provisional") else "")
                                         for lane in w) for i, w in enumerate(ws, 1)] or ["- none"]
    c = p["counts"]
    lines = [f"# Wave proposal ({p['tick_id']}, request `{p['request_id']}`)", "", f"> {p['label']}", "",
             f"- Requests seeded: {c['requests']}; excluded at init: {c['excluded_at_init']}",
             f"- Accepted briefs: {c['accepted_briefs']} of {c['requests']} "
             f"({', '.join(f'{k} {v}' for k, v in sorted(c['by_status'].items())) or 'none'})",
             f"- Planner waves: {c['actual_lanes']} lanes in {c['actual_waves']} waves",
             f"- Provisional waves: {c['provisional_lanes']} lanes in {c['provisional_waves']} waves; held {c['held']}",
             "", "## Planner waves (unchanged)", ""] + waves(p["actual"]["waves"])
    lines += ["", "## Provisional waves (planner lanes + sourced drafts)", ""] + waves(p["provisional"]["waves"])
    lines += ["", "## Seams", ""]
    lines += [f"- {s['kind']} wave {s['wave']}: #{s['a']} and #{s['b']} share `{s['spine']}/`"
              for s in p["actual"]["seams"] + p["provisional"]["seams"]] or ["- none"]
    lines += ["", "## Held", ""]
    lines += [f"- #{h['issue']}: {h['reason']}" for h in p["held"]] or ["- none"]
    lines += ["", "## Closed (excluded by frozen GitHub state)", ""]
    lines += [f"- #{n}: issue is CLOSED; planner state already-closed" for n in p["closed"]] or ["- none"]
    lines += ["", "## Not in this proposal", ""]
    lines += [f"- #{e['issue']}: excluded at init ({e['reason']})" for e in p["excluded"]]
    lines += [f"- `{r}`: not accepted yet (pending, uncertain or quarantined)" for r in p["not_accepted"]]
    return "\n".join(lines) + "\n"


def _probe_landing(engine, rec: dict) -> tuple[list[dict], int]:
    """Read-only check of a record's contract fix_probes against the working tree (GH-1270).
    `command` probes are never executed; they are reported as unverified."""
    probes = [p for p in ((rec.get("contract") or {}).get("fix_probes") or []) if isinstance(p, dict)]
    results = [{"type": p.get("type"), "path": p.get("path") or "",
                "result": "unverified" if p.get("type") == "command" else engine._eval_probe(p)} for p in probes]
    return results, sum(r["result"] == "landed" for r in results)


def _build_proposal(engine, computed: dict, briefs: list[dict], manifest: dict, tick_id: str, request_id: str) -> dict:
    """Planner waves as computed, plus provisional packing of copied records with sourced drafts."""
    by_gh = {r["gh"]: r for r in computed["deduped"] if r["gh"] is not None}
    delivered = manifest.get("delivered", {})
    # A reviewed brief that fails admission keeps a planner-ready lane out of the provisional view.
    refused = {b["issue"] for b in briefs if b["draft_status"] not in {"draft", "ready"}}
    # Every seeded issue with no ledger row is visible to dependency lookup, admitted or not (GH-1261).
    lookup = {q["issue"]: _unregistered_record(q["issue"], q["title"], "")
              for q in manifest["requests"].values() if q.get("source") == "unregistered"}
    lanes, held = [], []
    for r in computed["active"]:
        if r["gh"] in refused:
            continue
        # GH-1270: every provisional lane gets the read-only readiness checks, briefed or not.
        if str(r["gh"]) in delivered:
            held.append({"issue": r["gh"], "reason": "possibly delivered: closed by merged PR "
                         + ", ".join(f"#{n}" for n in delivered[str(r["gh"])]) + "; issue still open"})
            continue
        results, landed = _probe_landing(engine, r)
        if landed:
            held.append({"issue": r["gh"], "reason": f"stale-contract: {landed} of {len(results)} fix_probes already landed"})
            continue
        lane = copy.deepcopy(r)
        lane.update(wave=None, provisional=False)
        lanes.append(lane)
    for b in briefs:
        if b["draft_status"] == "draft":
            base = by_gh.get(b["issue"]) or {**_unregistered_record(b["issue"], b["title"], ""), "deps": b["deps"]}
            lane = copy.deepcopy(base)
            paths = [w["path"] for w in b["write_set"]]
            zone = engine._zone_of({"artifacts": paths}, lane)
            lane.update(state="ready", writeset=paths, zone=zone["zone"], zoneInferred=False,
                        zoneRule=zone["zoneRule"], wave=None, provisional=True)
            lanes.append(lane)
        elif b["draft_status"] != "ready":
            held.append({"issue": b["issue"], "reason": f"{b['draft_status']}: {b['held_reason']}"})
    placed = {lane["gh"]: lane for lane in lanes if lane["gh"] is not None}
    view = [placed.get(r["gh"], r) for r in computed["deduped"]] + [placed.get(n, r) for n, r in lookup.items()]
    waves, unplaced = engine._pack_waves(lanes, view, force_tail=False)
    for i, w in enumerate(waves, 1):
        for lane in w:
            lane["wave"] = i
    seams = engine._contract_seams(waves)
    held += [{"issue": lane["gh"], "reason": "unplaceable: unmet dependency, collision or zone cap"} for lane in unplaced]

    def lanes_of(ws):
        return [[{"issue": r["gh"], "provisional": bool(r.get("provisional")), "write_set": r["writeset"]} for r in w]
                for w in ws]

    def seams_of(items, kind):
        return [{"kind": kind, "wave": s["wave"], "a": s["a"]["gh"], "b": s["b"]["gh"], "spine": s["spine"]} for s in items]
    by_status = {}
    for b in briefs:
        by_status[b["draft_status"]] = by_status.get(b["draft_status"], 0) + 1
    return {"schema": "factory-primitive/wave-proposal@1", "tick_id": tick_id, "request_id": request_id,
            "label": DRAFT_LABEL,
            "counts": {"requests": len(manifest["requests"]), "excluded_at_init": len(manifest["excluded"]),
                       "accepted_briefs": len(briefs), "by_status": by_status,
                       "actual_lanes": len(computed["active"]), "actual_waves": len(computed["waves"]),
                       "provisional_lanes": sum(len(w) for w in waves), "provisional_waves": len(waves),
                       "held": len(held)},
            "actual": {"waves": lanes_of(computed["waves"]), "seams": seams_of(computed["contract_seams"], "planner")},
            "provisional": {"waves": lanes_of(waves), "seams": seams_of(seams, "provisional")},
            "held": held, "excluded": manifest["excluded"],
            "closed": sorted(r["gh"] for r in computed["deduped"] if r["state"] == "already-closed" and r["gh"] is not None),
            "not_accepted": sorted(set(manifest["requests"]) - {b["request_id"] for b in briefs})}


def _atomic_write(path: Path, text: str) -> None:
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(text, encoding="utf-8")
    os.replace(temp, path)


def plan_draft(tick_id: str, out_dir: Path, args: dict, accepted: list[str], fault: str) -> None:
    """Runs inside the sandbox: one evidence-linked brief plus a refreshed wave proposal."""
    instance = out_dir.parents[1]
    backlog = instance / "backlog"
    manifest = json.loads((backlog / "manifest.json").read_text(encoding="utf-8"))
    request_id = args["inbox_id"]
    req = manifest["requests"][request_id]
    issue = json.loads((backlog / "issues.json").read_text(encoding="utf-8"))[str(req["issue"])]
    doc_text, doc_sha = "", None
    if req["doc_path"] and (REPO_ROOT / req["doc_path"]).is_file():
        raw = (REPO_ROOT / req["doc_path"]).read_bytes()
        doc_text, doc_sha = raw.decode("utf-8", "replace"), hashlib.sha256(raw).hexdigest()
    if doc_sha != req["doc_sha256"]:
        raise ValueError("capture doc changed since init; refusing to draft from changed input")
    engine = _planner(backlog, "stub")
    computed = engine.compute()
    rec = next((r for r in computed["deduped"] if r["gh"] == req["issue"]), None)
    if rec is None and req.get("source") == "unregistered":
        rec = _unregistered_record(req["issue"], issue["title"], issue.get("body") or "")
    if rec is None:
        raise ValueError("issue missing from the frozen ledger")
    index = _file_index((backlog / "base-files.txt").read_text(encoding="utf-8"))
    unresolved = []
    issue_src = f"issue#{req['issue']}"
    found = _sections(issue["body"], issue_src)
    if doc_text:
        for kind, entries in _sections(doc_text, req["doc_path"]).items():
            found[kind] += entries
        goal = _frontmatter_goal(doc_text)
        if goal:
            found["scope"].append({"heading": "frontmatter goal", "text": goal[1],
                                   "source": f"{req['doc_path']}:L{goal[0]}"})
    contract = rec["contract"]
    if contract and isinstance(contract.get("artifacts"), list) and contract["artifacts"]:
        write_set = [{"path": a, "source": f"{req['doc_path']}:preflight-contract"} for a in contract["artifacts"]]
    else:
        # Every sourced path is kept: a cap here could evict an earlier citation (GH-1261 plan QA R3).
        write_set, seen = [], set()
        for entry in _cited_paths(issue["body"], issue_src, index=index, unresolved=unresolved) + \
                _cited_paths(doc_text, req["doc_path"] or "", index=index, unresolved=unresolved):
            if entry["path"] not in seen:
                seen.add(entry["path"])
                write_set.append(entry)
    if rec["state"] not in {"ready", "needs-contract", "unregistered"}:
        status, held = "held", f"planner state {rec['state']}"
    elif not write_set:
        status, held = "needs-recon", "no sourced write set"
    elif not found["scope"]:
        status, held = "missing-scope", "no sourced scope"
    else:
        status, held = ("ready" if rec["state"] == "ready" else "draft"), None
    probe_results, landed = _probe_landing(engine, rec)
    if landed and status in {"ready", "draft"}:
        status, held = "stale-contract", f"{landed} of {len(probe_results)} fix_probes already landed"
    axes = rec.get("dbAxes")
    brief = {"schema": "factory-primitive/plan-brief@1", "tick_id": tick_id, "status": "ok", "label": DRAFT_LABEL,
             "request_id": request_id, "issue": req["issue"], "title": issue["title"],
             "issue_sha256": req["issue_sha256"], "issue_updated_at": issue.get("updatedAt"),
             "doc_path": req["doc_path"], "doc_sha256": doc_sha, "planner_state": rec["state"],
             "planner_flags": sorted(set(rec["flags"] + rec["signals"])),
             "rating": "/".join(str(a) for a in axes) if axes else None, "existing_contract": contract,
             "deps": rec["deps"], "scope": found["scope"], "acceptance": found["acceptance"],
             "open_questions": found["open_questions"], "write_set": write_set,
             "draft_status": status, "held_reason": held, "unresolved_names": unresolved,
             "probe_results": probe_results}
    markdown = render_brief(brief)
    if fault == "corrupt-issue-hash":
        brief["issue_sha256"] = "0" * 64
    elif fault == "drop-key":
        del brief["scope"]
    elif fault == "md-mismatch":
        markdown += "tampered\n"
    _atomic_write(out_dir / f"{tick_id}.json", canonical(brief))
    _atomic_write(out_dir / f"{tick_id}.md", markdown)
    briefs = [json.loads(Path(p).read_text(encoding="utf-8")) for p in accepted]
    proposal = _build_proposal(engine, computed, briefs + [brief], manifest, tick_id, request_id)
    _atomic_write(out_dir / "wave-proposal.json", canonical(proposal))
    if fault != "drop-file":
        _atomic_write(out_dir / "wave-proposal.md", render_proposal(proposal))
    elif (out_dir / "wave-proposal.md").exists():
        (out_dir / "wave-proposal.md").unlink()
    if fault == "fail-after-output":
        raise RuntimeError("injected failure after plan-draft output was written")


def _verify_plan_draft(instance: Path, tick_id: str, args: dict) -> tuple[Path, str, dict]:
    out = instance / "out" / "plan-draft"
    names = (f"{tick_id}.json", f"{tick_id}.md", "wave-proposal.json", "wave-proposal.md")
    hashes = {}
    for name in names:
        if not (out / name).is_file() or (out / name).stat().st_size == 0:
            raise ValueError(f"plan-draft output missing or empty: {name}")
        hashes[name] = hashlib.sha256((out / name).read_bytes()).hexdigest()
    brief = json.loads((out / names[0]).read_text(encoding="utf-8"))
    missing = [key for key in BRIEF_KEYS if key not in brief]
    if missing:
        raise ValueError(f"plan-draft brief missing keys: {', '.join(missing)}")
    manifest = json.loads((instance / "backlog" / "manifest.json").read_text(encoding="utf-8"))
    req = manifest["requests"].get(args.get("inbox_id"), {})
    if (brief["tick_id"], brief["request_id"], brief["status"]) != (tick_id, args.get("inbox_id"), "ok") \
            or (brief["issue"], brief["issue_sha256"], brief["doc_sha256"]) != \
            (req.get("issue"), req.get("issue_sha256"), req.get("doc_sha256")):
        raise ValueError("plan-draft brief does not match its request or frozen sources")
    if render_brief(brief) != (out / names[1]).read_text(encoding="utf-8"):
        raise ValueError("plan-draft Markdown brief disagrees with its JSON")
    proposal = json.loads((out / names[2]).read_text(encoding="utf-8"))
    if (proposal.get("tick_id"), proposal.get("request_id")) != (tick_id, args.get("inbox_id")) \
            or render_proposal(proposal) != (out / names[3]).read_text(encoding="utf-8"):
        raise ValueError("wave proposal does not match this tick")
    return out / names[0], sha_text(canonical(hashes)), hashes


def init_from_prs(instance: Path, limit: int, daily_cap: float, max_call_cost: float,
                  unregistered: int = 0) -> dict:
    """Freeze up to `limit` open Queue candidates: ledger copy, git listings, one issue read each.
    With `unregistered` > 0, one open-issue listing also adds that many open issues that have no
    ledger row, most recently updated first (GH-1261)."""
    if (instance / "state.db").exists():
        raise ValueError("instance already initialized; use a new run root")
    backlog = instance / "backlog"
    backlog.mkdir(parents=True, exist_ok=True)
    with closing(gateway_connect(REPO_ROOT / "releases.db", readonly=True)) as src, \
            closing(gateway_connect(backlog / "releases.db", must_exist=False)) as dst:
        src.backup(dst)

    def git(*argv):
        return subprocess.run(["git", *argv], cwd=REPO_ROOT, capture_output=True, text=True, check=True).stdout
    (backlog / "branches.txt").write_text(git("branch", "-a", "--format=%(refname:short)"), encoding="utf-8")
    (backlog / "base-files.txt").write_text(git("ls-tree", "-r", "--name-only", "HEAD"), encoding="utf-8")

    def gh_json(argv, what):
        try:
            return json.loads(subprocess.run(argv, cwd=REPO_ROOT, capture_output=True, text=True,
                                             check=True, timeout=120).stdout)
        except (subprocess.SubprocessError, OSError, ValueError) as exc:
            raise ValueError(f"{what} failed: {str(exc)[:120]}") from exc
    # GH-1270: freeze real issue state for every issue, so the planner's own already-closed rule
    # removes CLOSED rows; and freeze merged PRs that close a still-open issue.
    states = {str(d["number"]): d["state"] for d in gh_json(
        ["gh", "issue", "list", "--state", "all", "--limit", "2000", "--json", "number,state"], "issue state list")}
    (backlog / "gh-state.json").write_text(canonical(states) + "\n", encoding="utf-8")
    import wave_reconcile
    delivered = {}
    for pr in gh_json(["gh", "pr", "list", "--state", "merged", "--limit", "300", "--json", "number,title,body"],
                      "merged PR list"):
        for n in wave_reconcile.extract_linked_issues(pr)[0]:
            if states.get(str(n)) == "OPEN":
                delivered.setdefault(str(n), []).append(pr["number"])
    delivered = {n: sorted(set(prs)) for n, prs in sorted(delivered.items())}

    def delivered_reason(n):
        return ("possibly delivered: closed by merged PR " + ", ".join(f"#{p}" for p in delivered[str(n)])
                + "; issue still open")
    computed = _planner(backlog, "stub").compute()
    pool = sorted((r for r in computed["deduped"] if r["section"] == "Queue / parked intake"
                   and r["state"] in {"ready", "needs-contract"} and r["gh"] is not None),
                  key=lambda r: (-(r["dbRank"] or 0), r["gh"]))
    requests, excluded, issues = {}, [], {}
    for r in pool[:limit * 3]:
        if len(requests) >= limit:
            break
        if str(r["gh"]) in delivered:
            excluded.append({"issue": r["gh"], "reason": delivered_reason(r["gh"])})
            continue
        try:
            data = json.loads(subprocess.run(
                ["gh", "issue", "view", str(r["gh"]), "--json", "number,state,title,body,updatedAt"],
                cwd=REPO_ROOT, capture_output=True, text=True, check=True, timeout=60).stdout)
        except (subprocess.SubprocessError, OSError, ValueError) as exc:
            excluded.append({"issue": r["gh"], "reason": f"issue read failed: {str(exc)[:120]}"})
            continue
        if data.get("state") != "OPEN":
            excluded.append({"issue": r["gh"], "reason": f"issue is {data.get('state')}"})
            continue
        issue_sha = sha_text(canonical({"title": data["title"], "body": data.get("body") or ""}))
        doc = REPO_ROOT / r["docRel"] if r["docRel"] else None
        request_id = f"gh-{r['gh']}-{issue_sha[:12]}"
        requests[request_id] = {"issue": r["gh"], "title": data["title"], "doc_path": r["docRel"],
                                "doc_sha256": hashlib.sha256(doc.read_bytes()).hexdigest() if doc and doc.is_file() else None,
                                "issue_sha256": issue_sha, "planner_state": r["state"], "slot": len(requests) + 1,
                                "source": "ledger"}
        issues[str(r["gh"])] = data
    if unregistered:
        try:
            listed = json.loads(subprocess.run(
                ["gh", "issue", "list", "--state", "open", "--limit", "500", "--json", "number,title,body,updatedAt"],
                cwd=REPO_ROOT, capture_output=True, text=True, check=True, timeout=120).stdout)
        except (subprocess.SubprocessError, OSError, ValueError) as exc:
            raise ValueError(f"open issue list failed: {str(exc)[:120]}") from exc
        registered = {r["gh"] for r in computed["deduped"] if r["gh"] is not None}
        fresh = sorted((d for d in listed if d["number"] not in registered),
                       key=lambda d: (d.get("updatedAt") or "", d["number"]), reverse=True)
        excluded += [{"issue": d["number"], "reason": delivered_reason(d["number"])}
                     for d in fresh[:unregistered] if str(d["number"]) in delivered]
        for d in [d for d in fresh if str(d["number"]) not in delivered][:unregistered]:
            data = {**d, "state": "OPEN"}
            issue_sha = sha_text(canonical({"title": data["title"], "body": data.get("body") or ""}))
            requests[f"gh-{d['number']}-{issue_sha[:12]}"] = {
                "issue": d["number"], "title": data["title"], "doc_path": None, "doc_sha256": None,
                "issue_sha256": issue_sha, "planner_state": "unregistered", "slot": len(requests) + 1,
                "source": "unregistered"}
            issues[str(d["number"])] = data
    if not requests:
        raise ValueError("no eligible open Queue candidates to seed")
    (backlog / "issues.json").write_text(json.dumps(issues, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    manifest = {"schema": "factory-primitive/backlog-manifest@1", "created_at": utcnow(),
                "source_head": git("rev-parse", "HEAD").strip(),
                "releases_db_sha256": hashlib.sha256((backlog / "releases.db").read_bytes()).hexdigest(),
                "scenario_sha256": sha_text(canonical(requests)), "probe_targets": [],
                "requests": requests, "excluded": excluded, "delivered": delivered,
                "slots": {str(s): available_digest([k for k, q in requests.items() if q["slot"] <= s])
                          for s in range(1, 289)}}
    manifest_path = backlog / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    base = datetime.now(timezone.utc)
    conn = connect(instance / "state.db")
    try:
        with conn:
            conn.executemany(
                "INSERT INTO inbox_items(id,available_at_slot,created_at,kind,body,target) VALUES(?,?,?,?,?,?)",
                [(k, q["slot"], (base + timedelta(microseconds=q["slot"])).isoformat(), "plan-request",
                  canonical({"issue": q["issue"], "title": q["title"]}), str(q["issue"])) for k, q in requests.items()])
        (instance / "canary.txt").write_text("do-not-modify\n", encoding="utf-8")
        config = {"daily_cap": daily_cap, "max_call_cost": max_call_cost, "probe_targets": [], "source": "prs",
                  "scenario_sha256": manifest["scenario_sha256"], "scenario_path": None,
                  "manifest_path": str(manifest_path),
                  "prompt_sha256": sha_text((PACKAGE / "prompts" / "evaluator.v1.md").read_text(encoding="utf-8"))}
        (instance / "config.json").write_text(json.dumps(config, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        emit(conn, instance, None, "init", "ok", items=len(requests), excluded=len(excluded), source="prs")
    finally:
        conn.close()
    return {"requests": len(requests), "excluded": len(excluded)}


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
    elif tool == "plan-draft":
        if set(args) != {"inbox_id"} or pending.get(args.get("inbox_id"), {}).get("kind") != "plan-request":
            return "plan-draft-id-not-eligible"
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


def _accepted_briefs(conn) -> list[str]:
    """Brief paths of plan-draft ticks that completed with a verified tool run."""
    return [row["output_path"] for row in conn.execute(
        "SELECT r.output_path FROM tool_runs r JOIN intents i USING(tick_id) JOIN ticks t USING(tick_id) "
        "WHERE i.tool='plan-draft' AND r.status='ok' AND t.status='completed' ORDER BY t.slot")]


def make_packet(instance: Path, wave: int, reviewer: str) -> dict:
    """GH-1270: one MARATHON.yaml + brief per lane of provisional wave `wave`, under the run root only.
    Copying a lane folder into PROJECT/2-WORKING/ is the operator's approval; nothing is launched."""
    import contextlib
    from marathon_yaml_emit import EmitError, Lane, Packet, render
    out = instance / "out" / "plan-draft"
    conn = connect(instance / "state.db")
    try:
        receipt = next((json.loads(row["json"]) for row in conn.execute(
            "SELECT json FROM receipts WHERE status='completed' ORDER BY created_at DESC")
            if json.loads(row["json"]).get("tool") == "plan-draft"), None)
        brief_paths = _accepted_briefs(conn)
    finally:
        conn.close()
    expected = ((receipt or {}).get("output_files") or {}).get("wave-proposal.json")
    proposal_path = out / "wave-proposal.json"
    if not expected or not proposal_path.is_file() \
            or hashlib.sha256(proposal_path.read_bytes()).hexdigest() != expected:
        raise ValueError("wave-proposal.json is not the verified output of the latest completed plan-draft tick; "
                         "refusing to build a packet from it")
    proposal = json.loads(proposal_path.read_text(encoding="utf-8"))
    waves = proposal["provisional"]["waves"]
    if not 1 <= wave <= len(waves):
        raise ValueError(f"--wave must be in 1..{len(waves)}")
    briefs = {}
    for p in brief_paths:
        b = json.loads(Path(p).read_text(encoding="utf-8"))
        briefs[b["issue"]] = (b, Path(p).with_suffix(".md"))
    records = {r["gh"]: r for r in _planner(instance / "backlog", "stub").compute()["deduped"] if r["gh"] is not None}
    dest = out.parent / "launch-packet" / f"wave-{wave}"
    staging = dest.with_name(dest.name + ".tmp")
    shutil.rmtree(staging, ignore_errors=True)
    staging.mkdir(parents=True)
    emitted, skipped = [], []
    for lane in waves[wave - 1]:
        n, slug = lane["issue"], f"GH-{lane['issue']}-LAUNCH"
        brief, brief_md = briefs.get(n, (None, None))
        rec = records.get(n, {})
        title = (brief or {}).get("title") or rec.get("title") or f"GH-{n}"
        if brief_md:
            text = brief_md.read_text(encoding="utf-8")
        elif rec.get("docRel"):
            text = f"# Launch brief: #{n} {title}\n\n> {DRAFT_LABEL}\n\nPlanner lane with no plan-draft brief. " \
                   f"Build from the capture doc `{rec['docRel']}`.\n"
        else:
            skipped.append({"issue": n, "reason": "no plan-draft brief and no capture doc"})
            continue
        try:
            with contextlib.chdir(REPO_ROOT):
                yaml = render([Lane(n, title, None, 0.0)],
                              {n: Packet(n, REPO_ROOT / "PROJECT" / "2-WORKING" / slug / "brief.md",
                                         ",".join(lane["write_set"]))}, reviewer, Path(slug))
        except EmitError as exc:
            skipped.append({"issue": n, "reason": f"MARATHON.yaml not representable: {exc}"})
            continue
        lane_dir = staging / slug
        lane_dir.mkdir()
        (lane_dir / "brief.md").write_text(text, encoding="utf-8")
        (lane_dir / "MARATHON.yaml").write_text(yaml, encoding="utf-8")
        check = subprocess.run(["node", str(REPO_ROOT / "bin" / "marathon-yaml"), str(lane_dir / "MARATHON.yaml")],
                               capture_output=True, text=True)
        if check.returncode != 0:
            shutil.rmtree(lane_dir)
            skipped.append({"issue": n, "reason": f"bin/marathon-yaml rejected it: {check.stderr.strip()[:160]}"})
            continue
        emitted.append({"issue": n, "folder": slug, "provisional": lane["provisional"]})
    builder = "agy" if reviewer == "codex" else "codex"  # marathon-drive refuses builder == reviewer
    readme = [f"# Launch packet: wave {wave} ({proposal['tick_id']})", "", f"> {DRAFT_LABEL}", "",
              "Nothing here has been launched. Each folder is one marathon for one lane; lanes in a wave are",
              "write-disjoint, so each can run in its own clone at the same time. Copying a folder into",
              "`PROJECT/2-WORKING/` of a clone is the approval step.",
              f"The builder must differ from the reviewer (`{reviewer}`), so the commands pass `--builder {builder}`.",
              "", "## Lanes", ""]
    for e in emitted:
        readme += [f"- #{e['issue']}" + (" (provisional)" if e["provisional"] else "") + f": `{e['folder']}/`",
                   f"  - `cp -R {e['folder']} <clone>/PROJECT/2-WORKING/`",
                   f"  - `relay-automation/marathon.sh --plan PROJECT/2-WORKING/{e['folder']}/MARATHON.yaml "
                   f"--builder {builder} --dry-run`"]
    readme += ["", "## Skipped", ""] + ([f"- #{s['issue']}: {s['reason']}" for s in skipped] or ["- none"])
    (staging / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
    shutil.rmtree(dest, ignore_errors=True)
    os.replace(staging, dest)
    return {"wave": wave, "dir": str(dest), "emitted": [e["issue"] for e in emitted], "skipped": skipped}


def _run_tool(instance: Path, tick_id: str, decision: dict, items: list[dict], fault: str,
              context: dict | None = None):
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
            "--args-json", canonical(decision["args"]), "--items-json", canonical(items),
            "--context-json", canonical(context or {})]
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
            drafting = decision["tool"] == "plan-draft"
            context = {"accepted": _accepted_briefs(conn)} if drafting else None
            completed = _run_tool(instance, tick_id, decision, snapshot["inbox"], fault, context)
            output_files = None
            try:
                if completed.timed_out or completed.rc != 0:
                    error = "tool-timeout" if completed.timed_out else (completed.stderr.strip() or "tool-failure")
                    if not drafting:
                        with conn:
                            conn.execute("INSERT INTO tool_runs(tick_id,rc,status,error) VALUES(?,?,?,?)",
                                         (tick_id, completed.rc, "failed", error))
                        finish(conn, instance, tick_id, "failed", {"error": error, "decision_status": decision_status})
                        return "failed"
                    raise RuntimeError(error)
                if drafting:
                    output, output_sha, output_files = _verify_plan_draft(instance, tick_id, decision["args"])
                else:
                    output, output_sha = _verify_output(instance, tick_id, decision["tool"])
            except Exception as exc:
                if not drafting:
                    raise
                # GH-1257: the tool may have published drafts before failing, so the attempt is
                # ambiguous: keep its rc and error, quarantine the request, never retry it.
                with conn:
                    conn.execute("INSERT INTO tool_runs(tick_id,rc,status,error) VALUES(?,?,?,?)",
                                 (tick_id, completed.rc, "unverified", str(exc)[:500]))
                quarantine(conn, [decision["args"]["inbox_id"]])
                finish(conn, instance, tick_id, "uncertain", {"error": str(exc)[:500], "decision_status": decision_status})
                return "uncertain"
            with conn:
                conn.execute("INSERT INTO tool_runs(tick_id,rc,status,output_path,sha256) VALUES(?,?,?,?,?)",
                             (tick_id, completed.rc, "ok", str(output), output_sha))
            if fault == "missing-receipt":
                os._exit(70)
            consumed = []
            if decision["tool"] in {"note", "plan-draft"}:
                consumed = [decision["args"]["inbox_id"]]
            elif decision["tool"] == "summarize":
                consumed = decision["args"]["inbox_ids"]
            elif decision["tool"] == "probe":
                consumed = [item["id"] for item in snapshot["inbox"]
                            if item["kind"] == "probe" and item["target"] == decision["args"]["target"]]
            details = {"tool": decision["tool"], "decision_status": decision_status, "output_sha256": output_sha}
            if output_files:
                details["output_files"] = output_files
            finish(conn, instance, tick_id, "completed", details, consumed)
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
        quarantined_ids = [row["id"] for row in conn.execute(
            "SELECT id FROM inbox_items WHERE status='quarantined' ORDER BY id")]
        last = conn.execute("SELECT r.tick_id,r.status,t.error FROM receipts r JOIN ticks t USING(tick_id) "
                            "ORDER BY r.created_at DESC LIMIT 1").fetchone()
        heartbeat = None
        if (instance / "heartbeat.json").is_file():
            beat = json.loads((instance / "heartbeat.json").read_text(encoding="utf-8"))
            age = (datetime.now(timezone.utc) - datetime.fromisoformat(beat["updated_at"])).total_seconds()
            heartbeat = {"tick_id": beat.get("tick_id"), "stage": beat.get("stage"), "age_s": round(age, 1)}
        lock = "free"
        if (instance / "lock").exists():
            with (instance / "lock").open("a+") as fh:
                try:
                    fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    fcntl.flock(fh, fcntl.LOCK_UN)
                except BlockingIOError:
                    lock = "held"
        return {"ticks": counts, "pending": pending, "quarantined": quarantined,
                "paused": (instance / "PAUSE").exists(), "spent_or_reserved": spent,
                "unknown_cost": any(row["billing_status"] == "unknown" for row in reservations),
                "quarantined_ids": quarantined_ids, "heartbeat": heartbeat, "lock": lock,
                "last_receipt": dict(last) if last else None}
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
    init.add_argument("--from-prs", action="store_true",
                      help="seed plan requests from open Queue rows in releases.db (GH-1257)")
    init.add_argument("--limit", type=int, default=10)
    init.add_argument("--unregistered", type=int, default=0,
                      help="with --from-prs, also seed N open issues that have no ledger row (GH-1261)")
    manifest = sub.add_parser("generate-manifest")
    manifest.add_argument("--scenario", type=Path, default=PACKAGE / "scenarios" / "soak-v1.jsonl")
    manifest.add_argument("--output", type=Path, default=PACKAGE / "scenarios" / "soak-v1.manifest.json")
    tick = sub.add_parser("tick")
    tick.add_argument("--instance", default="C")
    tick.add_argument("--slot", type=int, required=True)
    tick.add_argument("--fault", choices=sorted(FAULTS), default="")
    stat = sub.add_parser("status")
    stat.add_argument("--instance", default="C")
    packet = sub.add_parser("packet", help="write marathon launch packets for one provisional wave (GH-1270)")
    packet.add_argument("--instance", default="C")
    packet.add_argument("--wave", type=int, required=True)
    packet.add_argument("--reviewer", choices=["codex", "agy"], default="codex")
    tool = sub.add_parser("tool")
    tool.add_argument("--tool", required=True, choices=sorted(TOOLS))
    tool.add_argument("--tick-id", required=True)
    tool.add_argument("--out-dir", type=Path, required=True)
    tool.add_argument("--args-json", required=True)
    tool.add_argument("--items-json", required=True)
    tool.add_argument("--context-json", default="{}")
    return p


def factory_main(argv: list[str]) -> int:
    args = factory_parser().parse_args(argv)
    try:
        if args.command == "tool":
            return execute_tool(args.tool, args.tick_id, args.out_dir, json.loads(args.args_json),
                                json.loads(args.items_json), json.loads(args.context_json))
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
            if args.from_prs:
                if not 1 <= args.limit <= 50:
                    raise ValueError("--limit must be in 1..50")
                if not 0 <= args.unregistered <= 50:
                    raise ValueError("--unregistered must be in 0..50")
                seeded = init_from_prs(instance, args.limit, args.daily_cap, args.max_call_cost, args.unregistered)
                print(canonical({"status": "initialized", "instance": str(instance), **seeded}))
                return 0
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
        if args.command == "packet":
            print(canonical(make_packet(instance, args.wave, args.reviewer)))
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
