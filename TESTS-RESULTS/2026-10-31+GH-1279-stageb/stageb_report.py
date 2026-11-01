#!/usr/bin/env python3
"""GH-1279 Stage B: collect a finished (or stopped) window's evidence and compute the per-arm report with denominators.

Read-only over the window clone; copies logs, transcripts, briefs and table dumps to --dest and writes
window-summary.json + window-summary.md. Reports raw validity, policy correctness, safe fallbacks, adapter failures, calls,
latency and cost separately (unknown cost is never shown as zero), plus every canary's outcome in both arms.

usage: stageb_report.py --repo WINDOW_CLONE --freeze FREEZE.json --dest DIR
"""
from __future__ import annotations

import argparse
import collections
import json
import shutil
import sqlite3
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stageb_prepare as prep  # noqa: E402

TABLES = ("ticks", "decisions", "intents", "tool_runs", "receipts", "reservations", "events")


def dump_tables(db: Path) -> dict:
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    out = {t: [dict(r) for r in conn.execute(f"SELECT * FROM {t}")] for t in TABLES}
    out["inbox_items"] = [dict(r) for r in conn.execute("SELECT id,available_at_slot,kind,status FROM inbox_items")]
    conn.close()
    return out


def arm_report(repo: Path, root: str, dest: Path, manifest: dict) -> dict:
    inst = prep.instance_of(repo, root)
    tables = dump_tables(inst / "state.db")
    (dest / "tables.json").write_text(json.dumps(tables, indent=1, default=str))
    for sub in ("telemetry/transcripts", "out/plan-draft"):
        src = inst / sub
        if src.is_dir():
            shutil.copytree(src, dest / sub.replace("/", "-"), dirs_exist_ok=True)
    for f in ("config.json",):
        shutil.copy2(inst / f, dest / f)
    if (inst / "telemetry" / "events.jsonl").is_file():
        shutil.copy2(inst / "telemetry" / "events.jsonl", dest / "events.jsonl")
    ticks = tables["ticks"]
    decisions = {d["tick_id"]: d for d in tables["decisions"]}
    res = {r["tick_id"]: r for r in tables["reservations"]}
    transcripts = {}
    for f in (inst / "telemetry" / "transcripts").glob("slot_*.json"):
        transcripts[f.stem] = json.loads(f.read_text())
    evaluated = [t for t in transcripts if res.get(t)]
    called = [t for t in evaluated if res[t]["billing_status"] == "unknown"]
    norm = collections.Counter(transcripts[t]["normalized"] for t in called)
    dstat = collections.Counter(decisions[t]["status"] for t in decisions)
    rejected = collections.Counter(decisions[t]["rejected_reason"] for t in decisions if decisions[t]["status"] == "rejected")
    intents = {i["tick_id"]: i for i in tables["intents"]}
    tools = collections.Counter(i["tool"] for i in intents.values())
    briefs = {}
    for f in (inst / "out" / "plan-draft").glob("slot_*.json"):
        b = json.loads(f.read_text())
        briefs[b["request_id"]] = b
    authored = [b for b in briefs.values() if b.get("authored")]
    canary = {}
    for rid, q in manifest["requests"].items():
        if "canary" in q:
            b = briefs.get(rid)
            slot = f"slot_{q['slot']:03d}"
            canary[q["canary"]] = {"category": q["canary_category"], "slot": q["slot"], "issue": q["issue"],
                                   "decision": decisions.get(slot, {}).get("status"), "rejected_reason": decisions.get(slot, {}).get("rejected_reason"),
                                   "brief_status": b and b["draft_status"], "held_reason": b and b["held_reason"], "authored": bool(b and b.get("authored")),
                                   "adapter_outcome": transcripts.get(slot, {}).get("normalized")}
    return {
        "ticks": dict(collections.Counter(t["status"] for t in ticks)), "slots_with_tick": len(ticks),
        "evaluations": len(evaluated), "agent_calls_unknown_cost": len(called), "adapter_outcomes_on_calls": dict(norm),
        "decision_status": dict(dstat), "rejected_reasons": dict(rejected), "tools_selected": dict(tools),
        "briefs": len(briefs), "brief_status": dict(collections.Counter(b["draft_status"] for b in briefs.values())),
        "authored_briefs": len(authored), "authored_entries": sum(1 for b in authored for k in ("scope", "acceptance", "open_questions") for e in b[k] if e["source"] == "codex-authored"),
        "authored_paths_added": sum(1 for b in authored for w in b["write_set"] if w["source"] == "codex-authored"),
        "authored_ignored": sum(1 for b in authored if b.get("authored_ignored")),
        "reservations_unknown": sum(1 for r in res.values() if r["billing_status"] == "unknown"),
        "reservations_released": sum(1 for r in res.values() if r["status"] == "released"),
        "actual_cost_reported": sum((r["actual_cost"] or 0) for r in res.values() if r["billing_status"] == "reported"),
        "canaries": canary, "pause_file": (inst / "PAUSE").exists(),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--freeze", required=True)
    ap.add_argument("--dest", required=True)
    a = ap.parse_args()
    repo, dest = Path(a.repo).resolve(), Path(a.dest).resolve()
    freeze = json.loads(Path(a.freeze).read_text())
    dest.mkdir(parents=True, exist_ok=True)
    log = repo / "temp" / "factory-primitive" / f"{freeze['name']}-driver.jsonl"
    shutil.copy2(log, dest / "driver.jsonl")
    shutil.copy2(a.freeze, dest / "freeze.json")
    dec = repo / "temp" / "factory-primitive" / f"{freeze['name']}-decisions.json"
    if dec.is_file():
        shutil.copy2(dec, dest / "decisions.json")
    events = [json.loads(l) for l in log.read_text().splitlines()]
    ticks = [e for e in events if e.get("event") == "tick"]
    manifest = json.loads((prep.instance_of(repo, freeze["roots"]["rules"]) / "backlog" / "manifest.json").read_text())
    rep = {"freeze": freeze["name"], "layout": freeze["layout"], "route": freeze["route"], "pinned_head": freeze["identities"]["rules"]["source_head"],
           "driver": {"start": next((e for e in events if e.get("event") == "start"), None), "done": next((e for e in events if e.get("event") == "done"), None),
                      "stops": [e for e in events if e.get("event") == "STOP"], "injected_misses": [e["slot"] for e in events if e.get("event") == "injected-miss"],
                      "recovery_checks": [e for e in events if e.get("event") == "recovery-check"]},
           "latency_s": {}, "arms": {}}
    for arm, root in freeze["roots"].items():
        d = dest / arm
        d.mkdir(exist_ok=True)
        rep["arms"][arm] = arm_report(repo, root, d, manifest)
        durs = [t["duration_s"] for t in ticks if t["arm"] == arm]
        rep["latency_s"][arm] = {"ticks": len(durs), "mean": round(statistics.mean(durs), 2) if durs else None, "max": max(durs) if durs else None,
                                 "p95": round(sorted(durs)[int(0.95 * (len(durs) - 1))], 2) if durs else None}
    (dest / "window-summary.json").write_text(json.dumps(rep, indent=1, default=str))
    c = rep["arms"]["codex"]
    md = ["# Stage B window summary (machine-generated)", "", f"- pinned head `{rep['pinned_head']}`; layout {rep['layout']}; route {rep['route']}",
          f"- driver: done={bool(rep['driver']['done'])}, stops={len(rep['driver']['stops'])}, injected misses={rep['driver']['injected_misses']}",
          f"- latency (s): {rep['latency_s']}", ""]
    for arm in ("rules", "codex"):
        r = rep["arms"][arm]
        md += [f"## {arm} arm", f"- ticks {r['ticks']} ({r['slots_with_tick']} slots); agent calls (unknown cost) {r['agent_calls_unknown_cost']}; adapter outcomes on calls {r['adapter_outcomes_on_calls']}",
               f"- decision status {r['decision_status']}; rejected reasons {r['rejected_reasons']}; tools selected {r['tools_selected']}",
               f"- briefs {r['briefs']} {r['brief_status']}; authored briefs {r['authored_briefs']} (entries {r['authored_entries']}, paths added {r['authored_paths_added']}, ignored {r['authored_ignored']})",
               f"- reservations: unknown {r['reservations_unknown']}, released {r['reservations_released']}; reported cost {r['actual_cost_reported']}; PAUSE file {r['pause_file']}", ""]
    md += ["## Canaries (rules / codex)", "", "| canary | slot | category | rules brief | codex decision | codex brief | codex authored |", "|---|---|---|---|---|---|---|"]
    for k, v in rep["arms"]["rules"]["canaries"].items():
        w = c["canaries"].get(k, {})
        md.append(f"| {k} | {v['slot']} | {v['category']} | {v['brief_status']} | {w.get('decision')}{('/' + w['rejected_reason']) if w.get('rejected_reason') else ''} | {w.get('brief_status')} | {w.get('authored')} |")
    (dest / "window-summary.md").write_text("\n".join(md) + "\n")
    print(json.dumps({"dest": str(dest), "codex_calls": c["agent_calls_unknown_cost"], "outcomes": c["adapter_outcomes_on_calls"], "stops": len(rep["driver"]["stops"])}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
