from __future__ import annotations

import json
import os
import re
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MAX_SOURCE_BYTES = 4 * 1024 * 1024
MAX_RECORDS = 5_000
REPO_RE = re.compile(r"(?:(?:https?://)?github\.com[/:])?([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?$")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_time(value: Any) -> str | None:
    if not value:
        return None
    text = str(value).strip()
    try:
        if text.isdigit():
            return datetime.fromtimestamp(int(text), timezone.utc).isoformat().replace("+00:00", "Z")
        datetime.fromisoformat(text.replace("Z", "+00:00"))
        return text
    except (ValueError, OSError, OverflowError):
        return None


def repo_key(value: Any) -> str | None:
    if not value:
        return None
    text = str(value).strip().rstrip("/")
    match = REPO_RE.search(text)
    if match:
        return f"github.com/{match.group(1).lower()}/{match.group(2).lower()}"
    slug = re.sub(r"[^a-z0-9._-]+", "-", text.lower()).strip("-")
    return f"local/{slug}" if slug else None


def repo_name(key: str) -> str:
    return key.rsplit("/", 1)[-1].replace("-", " ").replace("_", " ").title()


def bounded_text(path: Path, limit: int = MAX_SOURCE_BYTES) -> str:
    size = path.stat().st_size
    with path.open("rb") as handle:
        if size > limit:
            handle.seek(size - limit)
            handle.readline()
        return handle.read(limit).decode("utf-8", "replace")


def safe_path(path: Path, root: Path | None = None) -> Path:
    resolved = path.expanduser().resolve(strict=True)
    if root is not None:
        base = root.expanduser().resolve(strict=True)
        if resolved != base and base not in resolved.parents:
            raise ValueError("path escapes configured connector root")
    return resolved


@dataclass(frozen=True)
class ConnectorConfig:
    rebalance_db: Path | None
    clio_jsonl: Path | None
    git_pulse_dir: Path | None
    topology_json: Path | None
    continuity_json: Path | None
    enabled: frozenset[str]

    @classmethod
    def from_environment(cls) -> "ConnectorConfig":
        home = Path.home()
        if sys.platform == "darwin":
            default_db = home / "Library" / "Application Support" / "rebalance-os" / "rebalance.db"
        else:
            default_db = Path(os.environ.get("XDG_DATA_HOME", home / ".local" / "share")) / "rebalance-os" / "rebalance.db"

        config_file = os.environ.get("FLIGHTDECK_CONFIG")
        configured: dict[str, Any] = {}
        if config_file:
            config_path = Path(config_file).expanduser()
            if config_path.is_file() and config_path.stat().st_size <= 64 * 1024:
                configured = json.loads(config_path.read_text(encoding="utf-8"))

        def source(name: str, env_name: str, default: Path | None) -> Path | None:
            raw = os.environ.get(env_name) or configured.get(name)
            return Path(raw).expanduser() if raw else default

        enabled_raw = os.environ["FLIGHTDECK_CONNECTORS"] if "FLIGHTDECK_CONNECTORS" in os.environ else configured.get("connectors")
        enabled = frozenset(
            (item for item in str(enabled_raw).split(",") if item) if isinstance(enabled_raw, str) else
            enabled_raw if isinstance(enabled_raw, list) else
            ("rebalance", "clio", "git_pulse", "topology", "continuity")
        )
        return cls(
            rebalance_db=source("rebalance_db", "FLIGHTDECK_REBALANCE_DB", default_db),
            clio_jsonl=source("clio_jsonl", "FLIGHTDECK_CLIO_JSONL", home / ".claude" / "prompt-log.jsonl"),
            git_pulse_dir=source("git_pulse_dir", "FLIGHTDECK_GIT_PULSE_DIR", home / "git-pulse-sync"),
            topology_json=source("topology_json", "FLIGHTDECK_TOPOLOGY_JSON", None),
            continuity_json=source("continuity_json", "FLIGHTDECK_CONTINUITY_JSON", None),
            enabled=enabled,
        )


def empty_batch(connector_id: str, capabilities: tuple[str, ...], status: str, error: str | None = None) -> dict[str, Any]:
    return {
        "connector": connector_id,
        "schema_version": 1,
        "capabilities": list(capabilities),
        "source": {"id": connector_id, "availability": status, "coverage": "unknown", "observed_through": None, "error": error},
        "repos": [], "checkouts": [], "issues": [], "prs": [], "lanes": [], "events": [],
    }


def deadline_guard(deadline: float) -> None:
    if time.monotonic() >= deadline:
        raise TimeoutError("connector deadline exceeded")
