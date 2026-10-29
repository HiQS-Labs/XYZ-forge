from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from .state import canonical


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
            fingerprint = __import__("hashlib").sha256(canonical({"tool": candidate["tool"], "args": candidate["args"]}).encode()).hexdigest()
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
