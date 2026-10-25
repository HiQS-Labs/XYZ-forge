"""Claude Code adapters (GH-1105).

``ClaudeLocalAdapter`` grooms local session transcripts at
``~/.claude/projects/<cwd-slug>/<sessionId>.jsonl``. It writes the same
record ``/rename`` writes — one appended ``custom-title`` line (title
records are last-wins) — and never rewrites existing bytes.

The session list resolves a label from a 64 KiB head and a 64 KiB tail:
``agentName || customTitle || aiTitle || summary || firstPrompt``, where
``customTitle`` = tail, else the ``<sessionId>/custom-title.json`` sidecar,
else head. The adapter compares against that same resolution, so a stamp
that scrolled out of the tail is re-appended on a later tick.

Running sessions (``~/.claude/sessions/<pid>.json`` with a live pid) keep
their title in memory and would revert a stamp; they are skipped. An
unreadable registry fails closed; a missing registry means nothing runs.

``ClaudeCloudAdapter`` is a read-only planner over a native snapshot,
mirroring the Codex adapter: ``set_session_title`` owns all mutation.
``ClaudeDesktopAdapter`` (GH-1191) is the same kind of planner over Claude
Desktop's ``list_sessions`` rows; Desktop owns its sidebar title, so the
transcript append above does not reach it.
"""
from __future__ import annotations

import json
import math
import os
import time
from datetime import datetime
from pathlib import Path

import core

DEFAULT_ROOT = os.path.expanduser("~/.claude")
WINDOW = 65536  # the app's head/tail read size (fv=65536 in Claude Code 2.1.302)
QUIET_SECONDS = 600  # backstop for sessions the running registry misses


def _iso_to_local(text):
    if not isinstance(text, str):
        return None
    if text.endswith("Z"):  # fromisoformat rejects "Z" before Python 3.11
        text = text[:-1] + "+00:00"
    return core.utc_text_to_local_dt(text)


def _records(chunk: str, partial_first: bool):
    lines = chunk.split("\n")
    if partial_first:
        lines = lines[1:]
    for line in lines:
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except ValueError:
            continue
        if isinstance(record, dict):
            yield record


def _last(records, kind, field):
    # The app matches the key in any record of its 64 KiB window; only the typed
    # title records carry these keys in practice, so this reads them by type.
    value = None
    for record in records:
        if record.get("type") == kind and isinstance(record.get(field), str):
            value = record[field]
    return value


def _pid_alive(pid) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


class ClaudeLocalAdapter:
    NAME = "claude"

    def __init__(self, root: str | None = None, apply: bool = False):
        self.root = Path(root or DEFAULT_ROOT)
        self.apply = apply

    # -- store reads ----------------------------------------------------

    def _projects(self) -> Path:
        projects = self.root / "projects"
        if not projects.is_dir():
            raise core.AdapterError(f"claude: projects dir not found at {projects}")
        return projects

    def _running(self) -> set:
        registry = self.root / "sessions"
        if not registry.exists():
            return set()
        try:
            files = sorted(registry.glob("*.json"))
        except OSError as exc:
            raise core.AdapterError(f"claude: sessions registry unreadable: {exc}") from exc
        running = set()
        for path in files:
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
                pid, session = data["pid"], data["sessionId"]
                if not isinstance(pid, int) or not isinstance(session, str):
                    raise ValueError("pid/sessionId types")
            except (OSError, ValueError, KeyError, TypeError) as exc:
                raise core.AdapterError(f"claude: sessions registry entry unreadable: {path.name}") from exc
            if _pid_alive(pid):
                running.add(session)
        return running

    def _read(self, path: Path) -> dict:
        """One transcript: stat taken first, activity, and the app-resolved label."""
        st = path.stat()
        activity, last_prompt, last_user, ends_newline = None, None, None, False
        with path.open("rb") as f:
            head = f.read(WINDOW).decode("utf-8", "replace")
            f.seek(max(0, st.st_size - WINDOW))
            tail = f.read(WINDOW).decode("utf-8", "replace")
            f.seek(0)
            for raw in f:
                ends_newline = raw.endswith(b"\n")
                try:
                    record = json.loads(raw)
                except ValueError:
                    continue
                if not isinstance(record, dict):
                    continue
                kind = record.get("type")
                if kind in ("user", "assistant"):
                    at = _iso_to_local(record.get("timestamp"))
                    if at is not None and (activity is None or at > activity):
                        activity = at
                    if kind == "user" and record.get("isMeta") is not True:
                        content = (record.get("message") or {}).get("content")
                        if isinstance(content, str) and content.strip():
                            last_user = content
                elif kind == "last-prompt" and isinstance(record.get("lastPrompt"), str):
                    last_prompt = record["lastPrompt"]
        head_records = list(_records(head, partial_first=False))
        tail_records = list(_records(tail, partial_first=st.st_size > WINDOW))
        custom = _last(tail_records, "custom-title", "customTitle")
        if custom is None:
            custom = self._sidecar(path)
        if custom is None:
            custom = _last(head_records, "custom-title", "customTitle")
        ai = _last(tail_records, "ai-title", "aiTitle") or _last(head_records, "ai-title", "aiTitle")
        return {
            "stat": (st.st_size, st.st_mtime_ns, st.st_atime_ns),
            "activity": activity,
            "agent_name": _last(tail_records, "agent-name", "agentName"),
            "label": custom or ai or _last(tail_records, "summary", "summary"),
            "summary_source": last_prompt or last_user,
            "ends_newline": ends_newline,
        }

    @staticmethod
    def _sidecar(path: Path):
        sidecar = path.parent / path.stem / "custom-title.json"
        try:
            value = json.loads(sidecar.read_text(encoding="utf-8")).get("customTitle")
        except (OSError, ValueError, AttributeError):
            return None
        return value if isinstance(value, str) and value.strip() else None

    # -- the one write path ---------------------------------------------

    def _append_title(self, path: Path, session_id: str, title: str, stat) -> bool:
        size, mtime_ns, atime_ns = stat
        now = path.stat()
        if (now.st_size, now.st_mtime_ns) != (size, mtime_ns):
            return False
        line = (json.dumps({"type": "custom-title", "customTitle": title, "sessionId": session_id},
                           ensure_ascii=False) + "\n").encode("utf-8")
        fd = os.open(path, os.O_WRONLY | os.O_APPEND)
        try:
            os.write(fd, line)
            after = os.fstat(fd).st_size
        finally:
            os.close(fd)
        if after == size + len(line):  # nobody else wrote; keep the list's recency order
            os.utime(path, ns=(atime_ns, mtime_ns))
        return True

    # -- adapter contract -----------------------------------------------

    def doctor(self) -> dict:
        out = {"store": str(self.root), "ok": True, "reds": []}
        try:
            self._running()
            files = sorted(self._projects().glob("*/*.jsonl"), key=lambda p: p.stat().st_mtime,
                           reverse=True)
        except (core.AdapterError, OSError) as exc:
            out.update(ok=False, reds=[str(exc)])
            return out
        if not files:
            out.update(ok=False, reds=["claude: no session transcripts found"])
            return out
        sample = [self._read(path) for path in files[:20]]
        if not any(info["activity"] is not None for info in sample):
            out["reds"].append("claude: no recent transcript has a user/assistant timestamp")
        if not any(info["label"] is not None for info in sample):
            out["reds"].append("claude: no recent transcript has a custom-title/ai-title/summary record")
        out["ok"] = not out["reds"]
        out["transcripts"] = len(files)
        return out

    def sweep(self, *, hours=24, include_all=False, pin=True, pin_hours=24,
              unpin_days=None, include_cron=False, group=None):
        if unpin_days is not None or group:
            raise core.AdapterError("claude: no pins or groups; --unpin-days/--group unsupported")
        running = self._running()
        projects = self._projects()
        report = core.new_ide_report()
        now = time.time()
        cutoff = now - hours * 3600
        for path in sorted(projects.glob("*/*.jsonl")):
            session_id = path.stem
            try:
                if path.stat().st_mtime < cutoff:
                    continue
                info = self._read(path)
            except OSError as exc:
                raise core.AdapterError(f"claude: transcript unreadable: {path}: {exc}") from exc
            at = info["activity"]
            if (session_id in running or info["agent_name"]
                    or at is None or at.timestamp() < cutoff or at.timestamp() > now - QUIET_SECONDS):
                report["skipped"] += 1
                continue
            report["swept"] += 1
            if not info["label"]:
                report["needs_summary"].append({"task_id": session_id, "workspace_path": path.parent.name,
                                                "summary_source": info["summary_source"]})
                continue
            base = core.clean_base(info["label"], max_length=None)
            desired = f"{core.local_stamp(at)} {base}" if base else info["label"]
            if desired == info["label"]:
                continue
            change = {"task_id": session_id, "old": info["label"], "new": desired}
            if self.apply:
                if not info["ends_newline"] or not self._append_title(path, session_id, desired, info["stat"]):
                    report["skipped"] += 1
                    continue
            report["renamed"].append(change)
        return report

    def set_title(self, task_id: str, description: str) -> dict:
        base = core.clean_base(description, max_length=None)
        if not base:
            raise core.AdapterError("claude: --set-title requires a non-empty title")
        out = {"task_id": task_id, "found": False, "renamed": []}
        paths = sorted(self._projects().glob(f"*/{task_id}.jsonl"))
        if not paths:
            return out
        out["found"] = True
        if task_id in self._running():
            raise core.AdapterError(f"claude: session {task_id} is running; it would revert the title")
        for path in paths:
            info = self._read(path)
            if info["activity"] is None:
                raise core.AdapterError(f"claude: no user/assistant activity in {path.name}")
            desired = f"{core.local_stamp(info['activity'])} {base}"
            if desired == info["label"]:
                continue
            if self.apply and (not info["ends_newline"]
                               or not self._append_title(path, task_id, desired, info["stat"])):
                raise core.AdapterError(f"claude: transcript changed while writing; retry: {path.name}")
            out["renamed"].append({"old": info["label"], "new": desired})
        return out


class ClaudeCloudAdapter:
    """Read-only planner for claude.ai/code sessions; native tools own all mutations."""

    NAME = "claude-cloud"

    def __init__(self, snapshot_path: str, exclude_thread: str, apply: bool = False):
        self.snapshot_path = snapshot_path
        self.exclude_thread = exclude_thread
        self.apply = apply

    @staticmethod
    def _seconds(value):
        return (isinstance(value, (int, float)) and not isinstance(value, bool)
                and math.isfinite(value) and value > 0)

    def _snapshot(self):
        if self.apply:
            raise core.AdapterError("claude-cloud plans only; apply with set_session_title")
        try:
            data = json.loads(Path(self.snapshot_path).read_text(encoding="utf-8"))
        except (OSError, ValueError, TypeError) as exc:
            raise core.AdapterError("claude-cloud snapshot unreadable") from exc
        if not isinstance(data, dict) or not self.exclude_thread:
            raise core.AdapterError("claude-cloud requires a snapshot object and own-session exclusion")
        captured = data.get("captured_at")
        if not self._seconds(captured) or not 0 <= time.time() - captured <= 300:
            raise core.AdapterError("claude-cloud snapshot stale or invalid (freshness limit 300s)")
        sessions, activity = data.get("sessions"), data.get("activity_at")
        if not isinstance(sessions, list) or not isinstance(activity, dict):
            raise core.AdapterError("claude-cloud snapshot requires sessions list and activity_at object")
        if not sessions:
            raise core.AdapterError("claude-cloud empty inventory refused")
        ids = set()
        for row in sessions:
            if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"]:
                raise core.AdapterError("claude-cloud inventory has invalid session ID")
            if row["id"] in ids:
                raise core.AdapterError("claude-cloud inventory has duplicate session ID")
            ids.add(row["id"])
            if not isinstance(row.get("title"), str):
                raise core.AdapterError(f"claude-cloud session title invalid for {row['id']}")
        return captured, sessions, activity

    def doctor(self):
        self._snapshot()
        return {"ok": True, "reds": [], "note": "snapshot ready; native mutations require set_session_title"}

    def sweep(self, *, hours=24, include_all=False, pin=True, pin_hours=24,
              unpin_days=None, include_cron=False, group=None):
        if unpin_days is not None or group:
            raise core.AdapterError("claude-cloud: no pins or groups; --unpin-days/--group unsupported")
        captured, sessions, activity = self._snapshot()
        report = core.new_ide_report()
        report["scope"] = "bounded native inventory; up to 100 recent sessions"
        report["execution"] = "native-tools-required"
        cutoff = captured - hours * 3600
        for row in sessions:
            session_id = row["id"]
            updated = _iso_to_local(row.get("updated_at"))
            if (row.get("environment_kind") != "anthropic_cloud"
                    or row.get("session_status") != "SESSION_STATUS_IDLE"
                    or session_id == self.exclude_thread
                    or updated is None or updated.timestamp() < cutoff):
                report["skipped"] += 1
                continue
            at = activity.get(session_id)
            if not self._seconds(at) or at > captured + 60:
                raise core.AdapterError(f"claude-cloud actual turn activity missing/invalid for {session_id}")
            if at < cutoff:
                report["skipped"] += 1
                continue
            report["swept"] += 1
            title = row["title"]
            base = core.clean_base(title, max_length=None)
            desired = f"{core.local_stamp(datetime.fromtimestamp(at))} {base}" if base else title
            if desired != title:
                report["renamed"].append({"task_id": session_id, "old": title, "new": desired,
                                          "activity_at": at})
        return report


class ClaudeDesktopAdapter:
    """Read-only planner for Claude Desktop sidebar sessions (GH-1191).

    Desktop keeps its own sidebar title, so a transcript append (``ClaudeLocalAdapter``)
    does not reach it; ``set_session_title`` owns every write. The snapshot rows are
    ``list_sessions`` rows, whose ``lastActivityAt`` is the session's own turn activity.
    ``list_sessions`` excludes the caller, so an empty inventory is valid, not a refusal.
    Pins (GH-1196) are proposals for ``set_pinned``; the planner only ever adds pins.
    """

    NAME = "claude-desktop"

    def __init__(self, snapshot_path: str, exclude_thread: str, apply: bool = False):
        self.snapshot_path = snapshot_path
        self.exclude_thread = exclude_thread
        self.apply = apply

    def _snapshot(self):
        if self.apply:
            raise core.AdapterError("claude-desktop plans only; apply with set_session_title")
        try:
            data = json.loads(Path(self.snapshot_path).read_text(encoding="utf-8"))
        except (OSError, ValueError, TypeError) as exc:
            raise core.AdapterError("claude-desktop snapshot unreadable") from exc
        if not isinstance(data, dict) or not self.exclude_thread:
            raise core.AdapterError("claude-desktop requires a snapshot object and own-session exclusion")
        captured = data.get("captured_at")
        if not ClaudeCloudAdapter._seconds(captured) or not 0 <= time.time() - captured <= 300:
            raise core.AdapterError("claude-desktop snapshot stale or invalid (freshness limit 300s)")
        sessions = data.get("sessions")
        if not isinstance(sessions, list):
            raise core.AdapterError("claude-desktop snapshot requires a sessions list")
        ids = set()
        for row in sessions:
            if not isinstance(row, dict) or not isinstance(row.get("sessionId"), str) or not row["sessionId"]:
                raise core.AdapterError("claude-desktop inventory has invalid session ID")
            if row["sessionId"] in ids:
                raise core.AdapterError("claude-desktop inventory has duplicate session ID")
            ids.add(row["sessionId"])
            if not isinstance(row.get("title"), str):
                raise core.AdapterError(f"claude-desktop session title invalid for {row['sessionId']}")
        return captured, sessions

    def doctor(self):
        self._snapshot()
        return {"ok": True, "reds": [], "note": "snapshot ready; native mutations require set_session_title"}

    def sweep(self, *, hours=24, include_all=False, pin=True, pin_hours=24,
              unpin_days=None, include_cron=False, group=None):
        if unpin_days is not None or group:
            raise core.AdapterError("claude-desktop: no groups or unpinning; --unpin-days/--group unsupported")
        captured, sessions = self._snapshot()
        report = core.new_ide_report()
        report["scope"] = "list_sessions inventory; the sweeping session is excluded by the tool"
        report["execution"] = "native-tools-required"
        cutoff = captured - hours * 3600
        pin_cutoff = captured - pin_hours * 3600
        for row in sessions:
            session_id = row["sessionId"]
            running = row.get("isRunning")
            if row.get("isArchived") is not False or session_id == self.exclude_thread \
                    or not isinstance(running, bool):
                report["skipped"] += 1
                continue
            at = _iso_to_local(row.get("lastActivityAt"))
            if at is None or at.timestamp() > captured + 60:
                if running:  # skipped before activity was read, as before GH-1196
                    report["skipped"] += 1
                    continue
                raise core.AdapterError(f"claude-desktop lastActivityAt missing/invalid for {session_id}")
            # GH-1196: pins only ever get added; a running session can be pinned.
            if pin and row.get("pinned") is not True and at.timestamp() >= pin_cutoff:
                report["pinned"].append({"task_id": session_id, "title": row["title"],
                                         "activity_at": row["lastActivityAt"]})
            if running or at.timestamp() < cutoff:
                report["skipped"] += 1
                continue
            report["swept"] += 1
            title = row["title"]
            base = core.clean_base(title, max_length=None)
            desired = f"{core.local_stamp(at)} {base}" if base else title
            if desired != title:
                report["renamed"].append({"task_id": session_id, "old": title, "new": desired,
                                          "activity_at": row["lastActivityAt"]})
        return report
