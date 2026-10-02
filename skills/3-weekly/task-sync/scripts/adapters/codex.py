"""Read-only Codex desktop planner; native app tools own all mutations (GH-901)."""
from __future__ import annotations

import json
import math
import time
from datetime import datetime
from pathlib import Path

import core


class CodexAdapter:
    def __init__(self, snapshot_path: str, exclude_thread: str, apply: bool = False):
        self.snapshot_path = snapshot_path
        self.exclude_thread = exclude_thread
        self.apply = apply

    def _snapshot(self):
        if self.apply:
            raise core.AdapterError("Codex plans only; apply with native desktop tools")
        try:
            data = json.loads(Path(self.snapshot_path).read_text(encoding="utf-8"))
        except (OSError, ValueError, TypeError) as exc:
            raise core.AdapterError("Codex snapshot unreadable") from exc
        if not isinstance(data, dict) or not self.exclude_thread:
            raise core.AdapterError("Codex requires a snapshot object and heartbeat thread exclusion")
        captured = data.get("captured_at")
        now = time.time()
        if not self._seconds(captured) or not 0 <= now - captured <= 300:
            raise core.AdapterError("Codex snapshot stale or invalid (freshness limit 300s)")
        state, activity = data.get("state"), data.get("activity_at")
        if not isinstance(state, dict) or not isinstance(activity, dict):
            raise core.AdapterError("Codex snapshot requires state and activity_at objects")
        for key in ("threads", "pinnedThreads", "sections"):
            if not isinstance(state.get(key), list):
                raise core.AdapterError(f"Codex snapshot requires {key} list")
        rows = state["pinnedThreads"] + state["threads"]
        if not rows:
            raise core.AdapterError("Codex empty inventory refused")
        ids = set()
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"]:
                raise core.AdapterError("Codex inventory has invalid thread ID")
            if row["id"] in ids:
                raise core.AdapterError("Codex inventory has duplicate thread ID")
            ids.add(row["id"])
            if row.get("kind") == "codex" and row.get("hostId") == "local":
                if not isinstance(row.get("title"), str) or not self._seconds(row.get("updatedAt")):
                    raise core.AdapterError("Codex local thread title/timestamp invalid")
                if row["updatedAt"] > captured + 60:
                    raise core.AdapterError("Codex thread timestamp is in the future or wrong units")
        sections = {}
        for section in state["sections"]:
            if (not isinstance(section, dict) or not isinstance(section.get("sectionId"), str)
                    or not isinstance(section.get("itemKeys"), list)):
                raise core.AdapterError("Codex sidebar sections malformed")
            for key in section["itemKeys"]:
                if not isinstance(key, str) or key in sections:
                    raise core.AdapterError("Codex sidebar membership ambiguous")
                sections[key] = section["sectionId"]
        pinned = {r["id"] for r in state["pinnedThreads"]}
        for row in rows:
            if row.get("kind") == "codex" and row.get("hostId") == "local":
                section = sections.get(f"codex:thread:local:{row['id']}")
                if (row["id"] in pinned) != (section == "pinned"):
                    raise core.AdapterError("Codex pinned inventory disagrees with sidebar sections")
        return captured, rows, pinned, sections, activity

    @staticmethod
    def _seconds(value):
        return (isinstance(value, (int, float)) and not isinstance(value, bool)
                and math.isfinite(value) and value > 0)

    def doctor(self):
        self._snapshot()
        return {"ok": True, "reds": [], "note": "snapshot ready; native mutations require app tools"}

    def sweep(self, *, hours=24, include_all=False, pin=True, pin_hours=24,
              unpin_days=None, include_cron=False, group=None):
        captured, rows, pinned, sections, activity = self._snapshot()
        if unpin_days is not None or group:
            raise core.AdapterError("Codex preserves pins and groups; unpin/group options unsupported")
        report = core.new_ide_report()
        report["scope"] = "bounded native inventory; all pins plus up to 50 recent chats"
        report["execution"] = "native-tools-required"
        for row in rows:
            task_id = row["id"]
            section = sections.get(f"codex:thread:local:{task_id}")
            if (row.get("kind") != "codex" or row.get("hostId") != "local"
                    or row.get("projectId") is not None
                    or task_id == self.exclude_thread or section not in ("pinned", "chats")
                    or row.get("updatedAt", 0) < captured - hours * 3600):
                report["skipped"] += 1
                continue
            at = activity.get(task_id)
            if not self._seconds(at) or at > captured + 60:
                raise core.AdapterError(f"Codex actual turn activity missing/invalid for {task_id}")
            if at < captured - hours * 3600:
                report["skipped"] += 1
                continue
            report["swept"] += 1
            title = row["title"]
            base = core.clean_base(title, max_length=None)
            desired = f"{core.local_stamp(datetime.fromtimestamp(at))} {base}" if base else title
            observed = {"task_id": task_id, "host_id": "local", "old": title,
                        "section_id": section, "activity_at": at}
            if desired != title:
                report["renamed"].append({**observed, "new": desired})
            if pin and task_id not in pinned and at >= captured - pin_hours * 3600:
                report["pinned"].append({**observed, "title": desired})
        return report
