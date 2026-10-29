from __future__ import annotations

import json
import os
from pathlib import Path

from .state import canonical, utcnow


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
        print(f"tool error: {exc}", file=os.sys.stderr)
        return 1
