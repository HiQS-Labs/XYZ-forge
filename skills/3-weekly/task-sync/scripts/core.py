"""task-sync core — shared semantics and the adapter safety contract.

Owns the stamp logic, the report schema, and the adapter error contract.
Adapters own only their app's store I/O; they must raise AdapterError
(with a clear, named message) instead of proceeding on a failed or empty
authoritative read — a failed read never triggers a destructive write.

Stamp semantics (operator-locked, GH-896): the MM-DD prefix is the task's
own last-activity date, never wall-clock at sweep time. Adapters convert
their store's native timestamp to a local datetime and call stamp_of().
"""

from __future__ import annotations

import re
from datetime import datetime, timezone

# A leading U.S. mm-dd (or legacy mm/dd) stamp followed by a description.
STAMP_RE = re.compile(r"^(\d{2}-\d{2})\s+(\S.*)$", re.DOTALL)
# Legacy slash form seen in Antigravity titles, stripped before re-stamping.
SLASH_STAMP_RE = re.compile(r"^\d{2}/\d{2}(?=\s|$)\s*")
# A bare date is not a description ("09-29" alone must not restack to "09-29 09-29").
BARE_DATE_RE = re.compile(r"^\d{2}[-/]\d{2}$")
MAX_BASE = 72  # keep the descriptive part readable in a task list


class AdapterError(Exception):
    """An adapter refused to proceed — the store failed a safety check."""


def local_stamp(dt: datetime) -> str:
    """The mm-dd stamp for an aware-or-naive local datetime."""
    return dt.strftime("%m-%d")


def utc_text_to_local_dt(text: str) -> datetime | None:
    """Parse an app's UTC timestamp text into local time.

    Handles the formats actually seen in Antigravity's
    ``conversation_summaries.last_modified_time`` — ISO-8601 with
    fractional seconds and an explicit offset
    (``2026-06-19 01:31:58.720731+00:00``). The fallback chain also
    accepts offset-naive ``%Y-%m-%d %H:%M:%S`` text and — deliberately,
    matching the superseded original — treats NAIVE text as already
    local. Returns None for absent, non-string, or unparseable input —
    callers decide whether that skips the row or aborts."""
    if not text or not isinstance(text, str):
        return None
    cleaned = text.strip()
    try:
        return datetime.fromisoformat(cleaned).astimezone()
    except ValueError:
        pass
    for fmt in (
        "%Y-%m-%d %H:%M:%S.%f%z",
        "%Y-%m-%d %H:%M:%S%z",
        "%Y-%m-%d %H:%M:%S.%f",
        "%Y-%m-%d %H:%M:%S",
    ):
        try:
            parsed = datetime.strptime(cleaned, fmt)
        except ValueError:
            continue
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone()
    return None


def ms_to_local_dt(ms: int) -> datetime:
    return datetime.fromtimestamp(ms / 1000)


def clean_base(raw: str, *, slash_stamps: bool = False) -> str:
    """Strip any existing stamp and collapse whitespace so re-stamping
    never stacks prefixes; cap length so long prompt-derived titles stay
    scannable. A bare date is not a description.

    slash_stamps=True also strips the legacy mm/dd form (Antigravity)."""
    base = raw.strip()
    if slash_stamps:
        base = SLASH_STAMP_RE.sub("", base)
    match = STAMP_RE.match(base)
    base = match.group(2) if match else base
    base = re.sub(r"\s+", " ", base).strip()
    if BARE_DATE_RE.fullmatch(base):
        return ""
    if len(base) > MAX_BASE:
        base = base[: MAX_BASE - 1].rstrip() + "…"
    return base


def new_ide_report() -> dict:
    """The per-IDE report shape every adapter returns."""
    return {
        "swept": 0,
        "renamed": [],
        "pinned": [],
        "unpinned": [],
        "needs_summary": [],
        "skipped": 0,
        "error": None,
    }


def merge_report(mode: str, ide_reports: dict) -> dict:
    """The merged stdout contract: mode + one section per IDE. The
    heartbeat and installer consume this JSON; per-IDE lists stay
    machine-addressable."""
    return {"mode": mode, "ides": ide_reports}


def receipt_path() -> str:
    import os

    return os.path.expanduser("~/.cache/task-sync/last-run.json")


def atomic_write_text(path, content: str) -> None:
    """Replace one file from a unique sibling temp; retain old bytes on failure."""
    import os
    import tempfile
    from pathlib import Path

    target = Path(path)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8",
                                         dir=target.parent, prefix=target.name + ".",
                                         delete=False) as f:
            temporary = f.name
            f.write(content)
        if target.exists():
            os.chmod(temporary, target.stat().st_mode & 0o777)
        os.replace(temporary, target)
    finally:
        if temporary is not None and os.path.exists(temporary):
            os.unlink(temporary)


def write_receipt(mode: str, ide_reports: dict) -> str:
    """Heartbeat receipt — written on apply runs only. Doctor reads it;
    a missing receipt is a distinct non-red 'pending' state."""
    import json
    import os

    path = receipt_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    atomic_write_text(path, json.dumps(
        {
            "at": datetime.now().isoformat(timespec="seconds"),
            "mode": mode,
            "ides": {
                name: {
                    "swept": rep.get("swept", 0),
                    "renamed": len(rep.get("renamed", [])),
                    "error": rep.get("error"),
                }
                for name, rep in ide_reports.items()
            },
        },
        indent=2,
    ) + "\n")
    return path
