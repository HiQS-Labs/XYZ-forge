"""Antigravity adapter — grooms Google Antigravity's task surfaces.

Behavior port of ``utils/skills/agy-task-sync/scripts/agy_task_sync.py``
(GH-892) onto the task-sync adapter contract, with the three safety fixes
from the GH-896 plan:

1. **A failed or empty-authoritative read never triggers a destructive
   write.** If ``app_storage.json`` cannot be read, the whole sweep
   aborts (AdapterError) — the original stripped ``pinned:true`` from
   every annotation file on that path. A *successful* read of an empty
   pinned list is authoritative (nothing pinned) and mirrors cleanly.
2. **App-running write gate.** While Antigravity is running, all adapter
   writes are refused (reads stay fine). Injectable for probes.
3. **Atomic backed-up Electron writes.** ``app_storage.json`` is backed
   up (``.bak-<ts>``) and replaced via temp-file + rename, never
   rewritten in place, and only under ``--auto-pin``.

Pin model: **mirror-app-owned** — ``pinned_conversations_order`` is
ground truth; the sweep mirrors it to annotations. ``--auto-pin`` opts
into derived pin writes including the Electron store.

Stamp semantics: last-activity date — ``last_modified_time`` (UTC text)
converted to the local mm-dd, replacing the original's rolling-today.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import sqlite3
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

import core

DEFAULT_AGY_ROOT = os.path.expanduser("~/.gemini/antigravity")
DEFAULT_ELECTRON_STORE = os.path.expanduser(
    "~/Library/Application Support/Antigravity/app_storage.json"
)

EXPECTED_SUMMARY_COLUMNS = {
    "conversation_id", "title", "preview", "status", "last_modified_time",
}


def _default_app_running() -> bool:
    try:
        result = subprocess.run(
            ["pgrep", "-x", "Antigravity"],
            capture_output=True,
            timeout=10,
        )
        return result.returncode == 0
    except (OSError, subprocess.SubprocessError):
        # Cannot tell — treat as running so writes stay gated (fail closed).
        return True


class AntigravityAdapter:
    NAME = "agy"

    def __init__(
        self,
        agy_root: str | None = None,
        electron_store: str | None = None,
        apply: bool = False,
        app_running_fn=None,
    ):
        self.agy_root = Path(agy_root or DEFAULT_AGY_ROOT)
        # A synthetic probe root keeps its own electron store beside the DB.
        if electron_store:
            self.electron_store = Path(electron_store)
        elif agy_root:
            self.electron_store = self.agy_root / "app_storage.json"
        else:
            self.electron_store = Path(DEFAULT_ELECTRON_STORE)
        self.db_path = self.agy_root / "conversation_summaries.db"
        self.annotations_dir = self.agy_root / "annotations"
        self.brain_dir = self.agy_root / "brain"
        self.apply = apply
        self._app_running_fn = app_running_fn or _default_app_running

    # -- safety surface -------------------------------------------------

    def app_running(self) -> bool:
        return self._app_running_fn()

    def _require_writes_allowed(self) -> None:
        if self.app_running():
            raise core.AdapterError(
                "agy: Antigravity is running — adapter writes are gated; "
                "close the app or run with the app stopped"
            )

    def _connect(self) -> sqlite3.Connection:
        if not self.db_path.exists():
            raise core.AdapterError(f"agy: summaries DB not found at {self.db_path}")
        conn = sqlite3.connect(str(self.db_path), timeout=10.0)
        conn.execute("PRAGMA busy_timeout=5000")
        return conn

    def _check_schema(self, conn: sqlite3.Connection) -> None:
        rows = conn.execute("PRAGMA table_info(conversation_summaries)").fetchall()
        present = {row[1] for row in rows}
        missing = EXPECTED_SUMMARY_COLUMNS - present
        if missing:
            raise core.AdapterError(
                f"agy: conversation_summaries missing expected columns: {sorted(missing)}"
            )

    def _read_pinned_ids(self) -> list[str]:
        """Read the authoritative pinned list. Raises AdapterError on any
        read/parse failure — the caller must not write on a failed read."""
        if not self.electron_store.exists():
            raise core.AdapterError(
                f"agy: electron store not found at {self.electron_store} — "
                "refusing to infer pin state"
            )
        try:
            with open(self.electron_store, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError) as exc:
            raise core.AdapterError(
                f"agy: failed to read app_storage.json ({exc}) — refusing to "
                "infer pin state; no writes performed"
            ) from exc
        if not isinstance(data, dict):
            raise core.AdapterError(
                f"agy: app_storage.json is {type(data).__name__}, not an object — "
                "refusing to infer pin state; no writes performed"
            )
        pinned = data.get("pinned_conversations_order", [])
        if isinstance(pinned, str):
            try:
                pinned = json.loads(pinned)
            except ValueError as exc:
                raise core.AdapterError(
                    f"agy: unparsable pinned_conversations_order ({exc}) — "
                    "refusing to infer pin state; no writes performed"
                ) from exc
        if not isinstance(pinned, list):
            raise core.AdapterError(
                "agy: pinned_conversations_order is not a list — refusing to "
                "infer pin state; no writes performed"
            )
        return [str(cid) for cid in pinned]

    def _write_pinned_ids(self, pinned_ids: list[str]) -> None:
        """Atomic, backed-up whole-file write of the electron store.
        Only reachable under --auto-pin and with the app closed."""
        data = json.loads(self.electron_store.read_text(encoding="utf-8"))
        data["pinned_conversations_order"] = json.dumps(pinned_ids)
        backup = self.electron_store.with_name(
            self.electron_store.name + ".bak-" + datetime.now().strftime("%Y%m%d-%H%M%S")
        )
        shutil.copy2(self.electron_store, backup)
        tmp = self.electron_store.with_suffix(".json.tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp, self.electron_store)

    # -- public contract ------------------------------------------------

    def doctor(self) -> dict:
        out = {
            "store": str(self.agy_root),
            "electron_store": str(self.electron_store),
            "ok": True,
            "reds": [],
        }
        if not self.agy_root.exists():
            out.update(ok=False, reds=[f"agy: root not found at {self.agy_root}"])
            return out
        if self.db_path.exists():
            try:
                conn = self._connect()
                try:
                    self._check_schema(conn)
                    rows = conn.execute(
                        "SELECT COUNT(*) FROM conversation_summaries"
                    ).fetchone()[0]
                    out["conversations"] = rows
                finally:
                    conn.close()
            except (core.AdapterError, sqlite3.Error) as exc:
                out.update(ok=False, reds=[str(exc)])
        else:
            out.update(ok=False, reds=[f"agy: summaries DB not found at {self.db_path}"])
        running = self.app_running()
        out["app_running"] = running
        if running:
            out["reds"].append(
                "agy: Antigravity is running — adapter writes are gated"
            )
            out["ok"] = False
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
        auto_pin_ids: list[str] | None = None,
    ) -> dict:
        if include_all:
            candidates = self._recent_rows(hours)
        else:
            candidates = self._pinned_rows()
        rep = core.new_ide_report()
        rep["candidates"] = len(candidates)
        rep["app_running"] = self.app_running()

        writes: list[tuple[str, tuple]] = []
        annotation_writes: list[tuple[str, dict]] = []

        for cid, title, preview, last_mod in candidates:
            rep["swept"] += 1
            stamp = self._stamp_for(last_mod)
            base = core.clean_base(title or "", slash_stamps=True)
            new_title = f"{stamp} {base}" if (stamp and base) else title
            new_preview = self._last_action_from_transcript(cid)
            if new_title != title:
                rep["renamed"].append({"conversation_id": cid, "old": title, "new": new_title})
                writes.append((
                    "UPDATE conversation_summaries SET title=?, preview=? WHERE conversation_id=?",
                    (new_title, new_preview, cid),
                ))
            elif new_preview != preview:
                writes.append((
                    "UPDATE conversation_summaries SET preview=? WHERE conversation_id=?",
                    (new_preview, cid),
                ))
            rep.setdefault("previews", []).append(
                {"conversation_id": cid, "last_action": new_preview}
            )

        if self.apply:
            self._require_writes_allowed()
            # Authoritative read happens here, after the gate, before any write.
            pinned_ids = self._read_pinned_ids()
            rep["pinned_source"] = "app_storage.json"
            if writes:
                conn = self._connect()
                try:
                    self._check_schema(conn)
                    with conn:
                        for sql, params in writes:
                            conn.execute(sql, params)
                finally:
                    conn.close()
            # Mirror-app-owned: annotations follow the authoritative list.
            self._mirror_annotations(pinned_ids, rep)
            if auto_pin_ids:
                self._auto_pin(auto_pin_ids, pinned_ids, rep)
        else:
            rep["pinned_source"] = "not read (dry-run)"

        return rep

    def set_title(
        self, conversation_id: str, description: str, auto_pin: bool = False
    ) -> dict:
        if not description.strip():
            raise core.AdapterError("agy: --set-title requires a non-empty title")
        out = {"task_id": conversation_id, "found": False, "renamed": []}
        conn = self._connect()
        try:
            self._check_schema(conn)
            row = conn.execute(
                "SELECT title, last_modified_time FROM conversation_summaries"
                " WHERE conversation_id=?",
                (conversation_id,),
            ).fetchone()
            if not row:
                return out
            out["found"] = True
            title, last_mod = row
            base = core.clean_base(description, slash_stamps=True)
            if not base:
                raise core.AdapterError("agy: --set-title requires a non-empty description")
            stamp = self._stamp_for(last_mod)
            desired = f"{stamp} {base}" if stamp else base
            out["renamed"].append({"old": title, "new": desired})
            if self.apply:
                self._require_writes_allowed()
                conn.execute(
                    "UPDATE conversation_summaries SET title=? WHERE conversation_id=?",
                    (desired, conversation_id),
                )
                conn.commit()
                self._update_annotation_file(conversation_id, new_title=desired, apply=True)
                if auto_pin:
                    pinned_ids = self._read_pinned_ids()
                    self._auto_pin([conversation_id], pinned_ids, out)
        except sqlite3.Error as exc:
            raise core.AdapterError(f"agy: sqlite error: {exc}") from exc
        finally:
            conn.close()
        return out

    # -- internals --------------------------------------------------------

    def _stamp_for(self, last_modified_text: str) -> str:
        """Local mm-dd from the row's own UTC last_modified_time text.
        Unparseable/absent → empty stamp (row keeps its title)."""
        dt = core.utc_text_to_local_dt(last_modified_text)
        return core.local_stamp(dt) if dt else ""

    def _recent_rows(self, hours: float) -> list[tuple]:
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=hours)).strftime(
            "%Y-%m-%d %H:%M:%S"
        )
        conn = self._connect()
        try:
            self._check_schema(conn)
            return conn.execute(
                "SELECT conversation_id, title, preview, last_modified_time"
                " FROM conversation_summaries WHERE last_modified_time >= ?"
                " ORDER BY last_modified_time DESC LIMIT 50",
                (cutoff,),
            ).fetchall()
        finally:
            conn.close()

    def _pinned_rows(self) -> list[tuple]:
        # Authoritative read even in dry-run: candidates come from the
        # app's own pin list; a failed read aborts before any probing.
        pinned_ids = self._read_pinned_ids()
        if not pinned_ids:
            return []
        conn = self._connect()
        try:
            self._check_schema(conn)
            placeholders = ",".join("?" for _ in pinned_ids)
            return conn.execute(
                "SELECT conversation_id, title, preview, last_modified_time"
                f" FROM conversation_summaries WHERE conversation_id IN ({placeholders})",
                pinned_ids,
            ).fetchall()
        finally:
            conn.close()

    def _last_action_from_transcript(self, conversation_id: str) -> str:
        """Ported verbatim-in-behavior from the QA'd original."""
        tpath = self.brain_dir / conversation_id / ".system_generated" / "logs" / "transcript.jsonl"
        if not tpath.exists():
            return "No transcript recorded"
        try:
            with open(tpath, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except OSError as exc:
            return f"Error reading transcript: {exc}"
        if not lines:
            return "Empty transcript"

        for line in reversed(lines):
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue

            tool_calls = entry.get("tool_calls")
            if tool_calls and isinstance(tool_calls, list):
                tc = tool_calls[0]
                if isinstance(tc, dict):
                    args = tc.get("args", {})
                    summary = tc.get("toolSummary")
                    if not summary and isinstance(args, dict):
                        summary = args.get("toolSummary")
                    if not summary:
                        summary = tc.get("toolAction")
                    if not summary and isinstance(args, dict):
                        summary = args.get("toolAction")
                    if not summary:
                        summary = tc.get("name", "Tool call")
                    return f"[Tool] {str(summary).strip('\'\"')}"

            step_type = entry.get("type")
            raw_content = entry.get("content", "")
            content = raw_content if isinstance(raw_content, str) else (
                str(raw_content) if raw_content is not None else ""
            )
            if step_type == "PLANNER_RESPONSE" and content:
                for cl in content.splitlines():
                    cl_clean = cl.strip().lstrip(">").lstrip("#").strip()
                    if cl_clean:
                        return f"[Response] {cl_clean[:80]}"
            elif step_type == "USER_INPUT" and content:
                for cl in content.splitlines():
                    if cl.strip():
                        return f"[User] {cl.strip()[:80]}"
        return "Awaiting instructions"

    def _update_annotation_file(
        self,
        conversation_id: str,
        new_title: str | None = None,
        pin: bool | None = None,
        apply: bool = False,
    ) -> bool:
        """Ported from the original, minus its delete-empty-file branch
        (an annotation that becomes empty is written empty, never
        unlinked — deletions are the app's business, not ours)."""
        pbtxt_path = self.annotations_dir / f"{conversation_id}.pbtxt"
        content = ""
        if pbtxt_path.exists():
            try:
                content = pbtxt_path.read_text(encoding="utf-8").strip()
            except OSError as exc:
                raise core.AdapterError(
                    f"agy: failed to read {pbtxt_path}: {exc}"
                ) from exc

        original = content
        if new_title is not None:
            escaped = new_title.replace("\\", "\\\\").replace('"', '\\"')
            title_pattern = r'title:\s*"(?:\\.|[^"\\])*"'
            if re.search(title_pattern, content):
                content = re.sub(title_pattern, f'title:"{escaped}"', content)
            else:
                content = f'title:"{escaped}" {content}'.strip()

        if pin is True:
            unquoted = re.sub(r'"(?:\\.|[^"\\])*"', "", content)
            if not re.search(r"\bpinned:\s*true\b", unquoted):
                content = f"{content} pinned:true".strip()
        elif pin is False:
            def _remove(m):
                return m.group(1) if m.group(1) else ""
            content = re.sub(r'("(?:\\.|[^"\\])*")|\bpinned:\s*true\b', _remove, content)
            content = re.sub(r"[ \t]+", " ", content).strip()

        if apply and content != original:
            self.annotations_dir.mkdir(parents=True, exist_ok=True)
            pbtxt_path.write_text(content + "\n", encoding="utf-8")
        return True

    def _mirror_annotations(self, pinned_ids: list[str], rep: dict) -> None:
        """Mirror the authoritative pin list onto annotation files. The
        read succeeded (caller guarantees it), so an empty list is a real
        'nothing pinned' state and stripping is correct — never a guess."""
        if not self.annotations_dir.exists():
            return
        pinned_set = set(pinned_ids)
        stripped = 0
        for pbtxt in self.annotations_dir.glob("*.pbtxt"):
            cid = pbtxt.stem
            should_pin = cid in pinned_set
            before = pbtxt.read_text(encoding="utf-8") if pbtxt.exists() else ""
            self._update_annotation_file(cid, pin=should_pin, apply=True)
            after = pbtxt.read_text(encoding="utf-8") if pbtxt.exists() else ""
            if before != after:
                if should_pin:
                    rep.setdefault("pinned", []).append({"conversation_id": cid})
                else:
                    stripped += 1
        if stripped:
            rep["annotations_stripped"] = stripped

    def _auto_pin(self, target_ids: list[str], pinned_ids: list[str], rep: dict) -> None:
        """--auto-pin: derived pin writes, including the electron store
        (original semantics, made safe by the gate/backup/atomic path)."""
        changed = False
        for cid in target_ids:
            if cid not in pinned_ids:
                pinned_ids.append(cid)
                changed = True
                self._update_annotation_file(cid, pin=True, apply=True)
                rep.setdefault("auto_pinned", []).append({"conversation_id": cid})
        if changed:
            self._write_pinned_ids(pinned_ids)
