#!/usr/bin/env python3
"""Create and advance serialized XYZ AgentChorus discussions (formerly agent2agent)."""

from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shlex
import signal
import subprocess
import sys
import tempfile
import time
from typing import Callable, Dict, Iterable, List, Optional, Tuple


ID_RE = re.compile(r"^[0-9]{6}$")
FIELD_RE_TEMPLATE = r"^{key}:[ \t]*(.*?)[ \t]*$"
DISCUSSION_MARKER = "\n## Discussion\n"
MAX_ID_ATTEMPTS = 1_000
DEFAULT_POLL_INTERVAL = 150.0
DEFAULT_STALE_AFTER = 1_800.0
DEFAULT_DRIVE_TIMEOUT = 3_600.0
DEFAULT_MAX_DRIVE_TURNS = 6
STORE_DIRNAME = "Agent2Agent-Transcripts"
ACTIVE_STORE = None  # type: Optional[Path]
PACKET_SECTIONS = (
    "Goal",
    "Scope",
    "Context and current state",
    "Evidence and artifacts",
    "Constraints and safety boundaries",
    "Questions for participants",
    "Requested outcome / done condition",
)
CLOSE_SECTIONS = (
    "Final Consensus & Recommendation",
    "Decision",
    "Key Invariants & Rationale",
    "Recorded Dissent / Falsifiers",
    "Recommended Next Actions",
)
CLOSE_TEMPLATE = """## Final Consensus & Recommendation

### Decision

State the agreed call plainly.

### Key Invariants & Rationale

Record the evidence and reasoning the participants agreed survives the discussion.

### Recorded Dissent / Falsifiers

Name any dissent and the evidence that would change the decision. Write `None` when unanimous.

### Recommended Next Actions

1. Name the next concrete action, or state that no action is required.
"""


class Agent2AgentError(RuntimeError):
    """A user-facing AgentChorus failure."""


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def default_root() -> Path:
    override = os.environ.get("AGENT2AGENT_ROOT")
    if override:
        return Path(override).expanduser().resolve()
    return Path(__file__).resolve().parents[3]


def normalize_root(value: Optional[str]) -> Path:
    root = Path(value).expanduser().resolve() if value else default_root()
    if not root.is_dir():
        raise Agent2AgentError(f"root is not a directory: {root}")
    return root


def _git_value(root: Path, *args: str) -> Optional[str]:
    try:
        value = subprocess.check_output(
            ["git", "-C", str(root), *args], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    return value or None


def canonical_repository_root(root: Path) -> Path:
    top = _git_value(root, "rev-parse", "--show-toplevel")
    common = _git_value(root, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if common:
        common_path = Path(common).resolve()
        if common_path.name == ".git":
            return common_path.parent
    return Path(top).resolve() if top else root.resolve()


def store_config_path() -> Path:
    config = os.environ.get("AGENT2AGENT_CONFIG")
    path = Path(config).expanduser() if config else Path.home() / ".config/xyz/agent2agent-home"
    return path.resolve()


def configured_store() -> Optional[str]:
    path = store_config_path()
    try:
        value = path.read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return value or None


def persist_store_default(store: Path) -> Path:
    config_path = store_config_path()
    if not config_path.parent.exists():
        private_mkdir(config_path.parent, parents=True)
    atomic_write(config_path, f"{store}\n")
    os.chmod(config_path, 0o600)
    return config_path


def normalize_store(root: Path, value: Optional[str], create: bool = False) -> Path:
    if value is not None and not value.strip():
        raise Agent2AgentError("--store must not be empty")
    if value is None and "AGENT2AGENT_HOME" in os.environ and not os.environ["AGENT2AGENT_HOME"].strip():
        raise Agent2AgentError("AGENT2AGENT_HOME must not be empty")
    requested = value or os.environ.get("AGENT2AGENT_HOME") or configured_store()
    canonical = canonical_repository_root(root)
    store = (
        Path(requested).expanduser().resolve()
        if requested else (canonical.parent / STORE_DIRNAME).resolve()
    )
    if store == canonical or _is_within(store, canonical):
        raise Agent2AgentError(
            f"session store must be outside the coordinated repository: {store}"
        )
    if not store.exists() and not create:
        return store
    try:
        store.mkdir(mode=0o700, parents=True, exist_ok=True)
    except OSError as exc:
        raise Agent2AgentError(f"could not create session store {store}: {exc}") from exc
    if not store.is_dir():
        raise Agent2AgentError(f"session store is not a directory: {store}")
    try:
        os.chmod(store, 0o700)
    except OSError as exc:
        raise Agent2AgentError(f"could not enforce private store permissions on {store}: {exc}") from exc
    if (store.stat().st_mode & 0o077) != 0:
        raise Agent2AgentError(f"session store is not private (expected mode 0700): {store}")
    return store


def repository_identity(root: Path) -> Tuple[str, str]:
    canonical = canonical_repository_root(root)
    remote = _git_value(canonical, "remote", "get-url", "origin")
    identity = remote.rstrip("/") if remote else str(canonical)
    if identity.endswith(".git"):
        identity = identity[:-4]
    name = identity.rsplit("/", 1)[-1].rsplit(":", 1)[-1] or canonical.name
    short_id = hashlib.sha256(identity.encode("utf-8")).hexdigest()[:12]
    return f"{slugify(name)}--{short_id}", identity


def private_mkdir(path: Path, parents: bool = False) -> None:
    path.mkdir(mode=0o700, parents=parents, exist_ok=True)
    os.chmod(path, 0o700)


def legacy_relay_root(root: Path) -> Path:
    return root / "relay-system"


def external_repositories_root(store: Path) -> Path:
    path = store / "repositories"
    private_mkdir(path, parents=True)
    return path


# ── Telemetry (Gen 2 Phase 1, #193) ─────────────────────────────────────────────
# Metadata-only sidecar + store-level index. STRUCTURAL no-content guarantee: emit_telemetry
# writes only fields present in TELEMETRY_EVENT_FIELDS[event] — anything else is dropped before
# serialization, so no API path can ever write message bodies into telemetry.
TELEMETRY_SCHEMA_VERSION = 1
TELEMETRY_PILOT_WINDOW = ("2026-08-24", "2026-09-08")  # default-ON pilot (EXPERIMENTS.md)
TELEMETRY_EVENT_FIELDS = {
    "discussion_started": {"schema", "agents", "timed_watch", "store", "created_at", "subject_sha256"},
    "turn_written": {"turn", "agent", "next_agent", "message_bytes", "line_count",
                     "citation_count", "unique_citation_count",
                     "contains_falsifier_section", "contains_dissent_section"},
    "close_written": {"close_type", "decision_bytes", "dissent_present",
                      "falsifier_count", "recommended_actions_count", "turn_count"},
    "extension_added": {"extension_number", "question_bytes", "done_condition_bytes"},
    "watch_transition": {"agent", "transition", "rearm_count"},
    "outcome_recorded": {"result", "note_bytes", "agents_json"},
}
_CITATION_RE = None  # compiled lazily; keep the module import-light


def telemetry_enabled() -> bool:
    """Hard env override beats the declared pilot window (data policy, TELEMETRY.md)."""
    flag = os.environ.get("AGENT2AGENT_TELEMETRY", "").strip().lower()
    if flag in ("1", "true", "yes", "on"):
        return True
    if flag in ("0", "false", "no", "off"):
        return False
    today = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d")
    start, end = TELEMETRY_PILOT_WINDOW
    return start <= today <= end


def telemetry_sidecar(path: Path) -> Path:
    """telemetry.jsonl lives beside the doorbell markers, never inside conversation.md."""
    runtime = path.parent / "runtime"
    return runtime / "telemetry.jsonl"


def _citation_counts(text: str) -> Tuple[int, int]:
    global _CITATION_RE
    if _CITATION_RE is None:
        import re
        _CITATION_RE = re.compile(r"[\w./-]+:\d+")
    hits = _CITATION_RE.findall(text)
    return len(hits), len(set(hits))


def emit_telemetry(path: Path, event: str, **fields) -> None:
    if not telemetry_enabled():
        return
    allowed = TELEMETRY_EVENT_FIELDS.get(event)
    if allowed is None:
        return
    record = {"event": event, "ts": utc_now(), "schema": TELEMETRY_SCHEMA_VERSION}
    for key, value in fields.items():
        if key in allowed and value is not None:
            record[key] = value
    sidecar = telemetry_sidecar(path)
    try:
        private_mkdir(sidecar.parent)
        with open(sidecar, "a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, sort_keys=True) + "\n")
    except OSError:
        pass  # telemetry is a nicety: it must never break the discussion operation


def telemetry_index_path(store: Optional[Path]) -> Optional[Path]:
    resolved = store or ACTIVE_STORE
    return Path(resolved) / "telemetry_index.db" if resolved else None


def index_connect(store: Optional[Path]):
    import sqlite3
    db_path = telemetry_index_path(store)
    if db_path is None:
        return None, None
    conn = sqlite3.connect(str(db_path))
    conn.execute(
        "CREATE TABLE IF NOT EXISTS discussions ("
        " id TEXT PRIMARY KEY, subject_sha256 TEXT, agents INTEGER, opened_at TEXT,"
        " closed_at TEXT, close_type TEXT, turn_count INTEGER,"
        " outcome TEXT, outcome_note TEXT, outcome_agents TEXT)"
    )
    conn.execute("CREATE TABLE IF NOT EXISTS outcomes_log ("
                 " id TEXT, result TEXT, note TEXT, agents TEXT, recorded_at TEXT)")
    return conn, db_path


def index_upsert(store: Optional[Path], discussion_id: str, **columns) -> None:
    if not telemetry_enabled():
        return
    conn, _ = index_connect(store)
    if conn is None:
        return
    try:
        existing = conn.execute(
            "SELECT id FROM discussions WHERE id = ?", (discussion_id,)
        ).fetchone()
        if existing:
            sets = ", ".join(f"{k} = ?" for k in columns)
            conn.execute(
                f"UPDATE discussions SET {sets} WHERE id = ?",
                list(columns.values()) + [discussion_id],
            )
        else:
            cols = ["id"] + list(columns)
            conn.execute(
                f"INSERT INTO discussions ({', '.join(cols)}) VALUES ({', '.join('?' * len(cols))})",
                [discussion_id] + list(columns.values()),
            )
        conn.commit()
    except Exception:
        pass  # index is derived state; the JSONL sidecar is the raw log
    finally:
        conn.close()


def parse_close_metrics(message: str) -> Dict[str, object]:
    """Extract only counts/flags from a structured close — never the prose itself."""
    def section(heading: str) -> str:
        marker = f"### {heading}"
        if marker not in message:
            return ""
        tail = message.split(marker, 1)[1]
        parts = tail.split("\n### ")
        return parts[0]
    decision = section("Decision")
    dissent = section("Recorded Dissent / Falsifiers")
    actions = section("Recommended Next Actions")
    falsifiers = [ln for ln in dissent.splitlines()
                  if ln.strip().startswith(("-", "*")) and "none" not in ln.strip().lower()[:6]]
    numbered = [ln for ln in actions.splitlines() if len(ln) > 1 and ln.strip()[0].isdigit()]
    return {
        "decision_bytes": len(decision.strip()),
        "dissent_present": bool(dissent.strip()) and "none" not in dissent.strip().lower()[:8],
        "falsifier_count": len(falsifiers),
        "recommended_actions_count": len(numbered),
    }


def normalize_subject(value: str) -> str:
    subject = " ".join(value.split())
    if not subject:
        raise Agent2AgentError("subject must not be empty")
    return subject


def normalize_message(value: str) -> str:
    message = value.strip()
    if not message:
        raise Agent2AgentError("message must not be empty")
    return message


def validate_context_packet(value: str) -> str:
    packet = value.strip()
    if not packet:
        raise Agent2AgentError("context packet must not be empty")
    positions = []
    for section in PACKET_SECTIONS:
        heading = f"## {section}"
        matches = list(re.finditer(rf"(?m)^{re.escape(heading)}[ \t]*$", packet))
        if len(matches) != 1:
            raise Agent2AgentError(f"context packet must contain exactly one '{heading}' heading")
        start = matches[0].end()
        body = packet[start:]
        next_heading = re.search(r"(?m)^##[ \t]+", body)
        body = body[:next_heading.start()] if next_heading else body
        if not body.strip():
            raise Agent2AgentError(f"context packet section '{heading}' must not be empty")
        positions.append(matches[0].start())
    if positions != sorted(positions):
        raise Agent2AgentError("context packet headings are out of order")
    return packet


def load_context_packet(path_value: str) -> str:
    try:
        if path_value == "-":
            return validate_context_packet(sys.stdin.read())
        return validate_context_packet(Path(path_value).read_text(encoding="utf-8"))
    except (OSError, UnicodeError) as exc:
        raise Agent2AgentError(f"could not read context packet: {exc}") from exc


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return (slug[:56].rstrip("-") or "discussion")


def agent_id(number: int) -> str:
    if number < 1:
        raise Agent2AgentError("agent number must be at least one")
    return f"agent{number}"


_SMALL_NUMBERS = (
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
    "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen",
)
_TENS = ("", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety")


def number_word(number: int) -> str:
    if number < 20:
        return _SMALL_NUMBERS[number]
    if number < 100:
        tens, remainder = divmod(number, 10)
        return _TENS[tens] if remainder == 0 else f"{_TENS[tens]}-{_SMALL_NUMBERS[remainder]}"
    if number < 1_000:
        hundreds, remainder = divmod(number, 100)
        prefix = f"{_SMALL_NUMBERS[hundreds]} hundred"
        return prefix if remainder == 0 else f"{prefix} {number_word(remainder)}"
    return str(number)


def quoted_subject(subject: str) -> str:
    return '"' + subject.replace("\\", "\\\\").replace('"', '\\"') + '"'


def invitation(discussion_id: str, number: int, subject: str, timed_watch: bool = False) -> str:
    text = (
        f"Join XYZ AgentChorus #{discussion_id} as agent number {number_word(number)} "
        f"to discuss: {quoted_subject(subject)}"
    )
    if timed_watch:
        text += (
            "\n\nTimed two-minute doorbell requested: when waiting, start a background "
            "watch that checks every 120 seconds for 1,800 seconds."
        )
    return text


def relay_root(root: Path) -> Path:
    """Legacy repository-local root retained for compatibility."""
    return legacy_relay_root(root)


def _header(content: str) -> str:
    return content.split(DISCUSSION_MARKER, 1)[0]


def field(content: str, key: str) -> str:
    match = re.search(FIELD_RE_TEMPLATE.format(key=re.escape(key)), _header(content), re.MULTILINE)
    if not match:
        raise Agent2AgentError(f"discussion is missing required field {key}:")
    return match.group(1)


def replace_field(content: str, key: str, value: str) -> str:
    pattern = FIELD_RE_TEMPLATE.format(key=re.escape(key))
    replaced, count = re.subn(pattern, f"{key}: {value}", content, count=1, flags=re.MULTILINE)
    if count != 1:
        raise Agent2AgentError(f"discussion is missing required field {key}:")
    return replaced


def optional_field(content: str, key: str, default: str = "") -> str:
    match = re.search(FIELD_RE_TEMPLATE.format(key=re.escape(key)), _header(content), re.MULTILINE)
    return match.group(1) if match else default


def upsert_field(content: str, key: str, value: str, after: str) -> str:
    pattern = FIELD_RE_TEMPLATE.format(key=re.escape(key))
    if re.search(pattern, _header(content), re.MULTILINE):
        return replace_field(content, key, value)
    anchor = FIELD_RE_TEMPLATE.format(key=re.escape(after))
    updated, count = re.subn(
        anchor,
        lambda match: f"{match.group(0)}\n{key}: {value}",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise Agent2AgentError(f"discussion is missing required field {after}:")
    return updated


def parse_roster(content: str) -> List[str]:
    roster = field(content, "AGENTS").split()
    if len(roster) < 2 or roster != [f"agent{i}" for i in range(1, len(roster) + 1)]:
        raise Agent2AgentError("discussion has an invalid AGENTS roster")
    return roster


def _is_within(path: Path, parent: Path) -> bool:
    try:
        return os.path.commonpath((str(path), str(parent))) == str(parent)
    except ValueError:
        return False


def find_discussions(root: Path, discussion_id: str, store: Optional[Path] = None) -> List[Path]:
    if not ID_RE.fullmatch(discussion_id):
        raise Agent2AgentError("discussion ID must be exactly six digits")
    if store is None:
        store = ACTIVE_STORE
    matches: List[Path] = []
    roots_and_patterns = [(legacy_relay_root(root), f"**/{discussion_id}-*.md")]
    if store is not None:
        external = store / "repositories"
        if external.is_dir():
            for session_dir in external.glob(f"**/{discussion_id}--*"):
                if session_dir.is_dir() and not (session_dir / "conversation.md").exists():
                    # A crashed creator's directory is a durable reservation. Return its expected
                    # canonical path so allocation will not reuse the ID and lookup fails loudly
                    # in read_discussion instead of pretending the ID is free.
                    matches.append(session_dir / "conversation.md")
        roots_and_patterns.insert(0, (external, f"**/{discussion_id}--*/conversation.md"))
    for base, pattern in roots_and_patterns:
        if not base.is_dir():
            continue
        for candidate in base.glob(pattern):
            if candidate.is_symlink() or not candidate.is_file():
                continue
            resolved = candidate.resolve()
            if not _is_within(resolved, base.resolve()):
                continue
            try:
                content = candidate.read_text(encoding="utf-8")
                if field(content, "AGENT2AGENT-ID") == discussion_id:
                    matches.append(candidate)
            except (Agent2AgentError, OSError, UnicodeError):
                continue
    return sorted(matches)


def resolve_discussion(root: Path, discussion_id: str, store: Optional[Path] = None) -> Path:
    if store is None:
        store = ACTIVE_STORE
    matches = find_discussions(root, discussion_id, store)
    if not matches:
        locations = f"{store} or {legacy_relay_root(root)}" if store else str(legacy_relay_root(root))
        raise Agent2AgentError(f"AgentChorus discussion #{discussion_id} was not found under {locations}")
    if len(matches) > 1:
        rendered = "\n  ".join(str(path) for path in matches)
        raise Agent2AgentError(f"AgentChorus discussion #{discussion_id} is ambiguous:\n  {rendered}")
    return matches[0]


def id_candidates(explicit_id: Optional[str]) -> Iterable[str]:
    if explicit_id is not None:
        if not ID_RE.fullmatch(explicit_id):
            raise Agent2AgentError("--id must be exactly six digits")
        yield explicit_id
        return
    deterministic = os.environ.get("AGENT2AGENT_ID_SEQUENCE", "")
    for item in deterministic.split(","):
        item = item.strip()
        if not item:
            continue
        if not ID_RE.fullmatch(item):
            raise Agent2AgentError("AGENT2AGENT_ID_SEQUENCE entries must be exactly six digits")
        yield item
    for _ in range(MAX_ID_ATTEMPTS):
        yield str(100_000 + secrets.randbelow(900_000))


def allocation_lock(store: Path) -> object:
    runtime = store / "runtime"
    private_mkdir(runtime, parents=True)
    path = runtime / "allocation.lock"
    handle = path.open("a+", encoding="utf-8")
    os.chmod(path, 0o600)
    fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
    return handle


def render_initial(
    discussion_id: str, subject: str, agents: int, timestamp: str, timed_watch: bool,
    context_packet: str,
) -> str:
    roster = " ".join(agent_id(number) for number in range(1, agents + 1))
    return f"""# XYZ AgentChorus #{discussion_id}

AGENT2AGENT-ID: {discussion_id}
SUBJECT: {subject}
AGENTS: {roster}
NEXT: agent2
STATUS: Open
TURN: 1
TIMED-WATCH: {"enabled" if timed_watch else "disabled"}
EXTENSIONS: 0
CREATED: {timestamp}
UPDATED: {timestamp}

## Attention — Rules for LLMs

- When waiting, if the host supports background-task wake, launch a watch every 120 seconds for up
  to 1,800 seconds. Re-arm it immediately after sending a turn.
- If the host cannot wake a dormant session, say so plainly and use manual `watch` instead. Never
  claim a timer is armed when no observable watch process exists.

## Protocol

- Read the complete producer packet and every existing turn before responding.
- Only the participant named by `NEXT:` may append the next turn.
- After writing, route `NEXT:` to exactly one other participant in `AGENTS:`.
- Keep turns serialized. Do not broadcast or write in parallel.
- Stay within the seeded goal, scope, questions, evidence, and safety boundaries.
- Treat helper-recorded scope extensions as part of the active done condition.
- Never claim an asynchronous or remote action completed until it exited successfully and its
  observable final state was verified; include the receipt in the turn.
- Close with the helper's structured final-consensus template unless the closure is explicitly
  trivial or administrative.
- Never ask the human to paste the prepared packet again.
- Never modify, reset, delete, or clean another participant's workspace.
- `STATUS: Closed` is terminal.

## Discussion

### Turn 1 — agent1 — {timestamp}

{context_packet}
"""


def _fsync_dir(directory: Path) -> None:
    """Persist a rename itself, not just the bytes it points at (GH-38 item 5). Without this a
    power loss can lose the newest turn even though its content was fsynced: the file was durable,
    the directory entry naming it was not. Best-effort — a filesystem that refuses to open a
    directory for fsync must not fail an otherwise-complete write."""
    try:
        fd = os.open(directory, os.O_RDONLY)
    except OSError:
        return
    try:
        os.fsync(fd)
    except OSError:
        pass
    finally:
        os.close(fd)


def atomic_write(path: Path, content: str) -> None:
    mode = (path.stat().st_mode & 0o777) if path.exists() else 0o600
    descriptor, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        os.fchmod(descriptor, mode)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
        if path.name in ("conversation.md", "metadata.json"):
            os.chmod(path, 0o600)
        _fsync_dir(path.parent)
    finally:
        temp_path.unlink(missing_ok=True)


def sync_metadata(path: Path, content: str) -> None:
    if path.name != "conversation.md":
        return
    metadata_path = path.parent / "metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata.update({
            "status": field(content, "STATUS"),
            "next": field(content, "NEXT"),
            "turn": int(field(content, "TURN")),
            "extensions": int(optional_field(content, "EXTENSIONS", "0")),
            "updated": field(content, "UPDATED"),
        })
        atomic_write(metadata_path, json.dumps(metadata, indent=2, sort_keys=True) + "\n")
    except (Agent2AgentError, OSError, UnicodeError, ValueError, TypeError, json.JSONDecodeError) as exc:
        print(f"agent-chorus: warning: conversation advanced but metadata sync failed: {exc}", file=sys.stderr)


def create_discussion(
    root: Path, subject: str, agents: int, explicit_id: Optional[str], timed_watch: bool,
    context_packet: str, store: Path,
) -> Tuple[str, Path]:
    if agents < 2:
        raise Agent2AgentError("--agents must be at least 2")
    normalized = normalize_subject(subject)
    timestamp = utc_now()
    namespace, identity = repository_identity(root)
    canonical_root = canonical_repository_root(root)
    repository_remote = _git_value(canonical_root, "remote", "get-url", "origin")
    repository_dir = external_repositories_root(store) / namespace
    private_mkdir(repository_dir, parents=True)
    dated = repository_dir / timestamp[:10]
    private_mkdir(dated, parents=True)
    allocation = allocation_lock(store)
    try:
        discussion_id = ""
        session_dir = None  # type: Optional[Path]
        for candidate in id_candidates(explicit_id):
            if find_discussions(root, candidate, store):
                if explicit_id:
                    raise Agent2AgentError(f"AgentChorus discussion #{candidate} already exists")
                continue
            candidate_dir = dated / f"{candidate}--{slugify(normalized)}"
            try:
                candidate_dir.mkdir(mode=0o700)
            except FileExistsError:
                if explicit_id:
                    raise Agent2AgentError(f"AgentChorus discussion #{candidate} already exists")
                continue
            os.chmod(candidate_dir, 0o700)
            discussion_id, session_dir = candidate, candidate_dir
            break
        if not discussion_id or session_dir is None:
            raise Agent2AgentError("could not allocate an unused six-digit discussion ID")
        runtime = session_dir / "runtime"
        private_mkdir(runtime)
        path = session_dir / "conversation.md"
        descriptor = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(render_initial(
                discussion_id, normalized, agents, timestamp, timed_watch, context_packet
            ))
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(path, 0o600)
        metadata = {
            "agent2agent_id": discussion_id,
            "subject": normalized,
            "repository_identity": identity,
            "repository_root": str(canonical_root),
            "repository_remote": repository_remote,
            "created": timestamp,
            "status": "Open",
            "next": "agent2",
            "turn": 1,
            "extensions": 0,
            "updated": timestamp,
        }
        metadata_path = session_dir / "metadata.json"
        descriptor = os.open(metadata_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(metadata, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(metadata_path, 0o600)
        _fsync_dir(session_dir)
    finally:
        fcntl.flock(allocation.fileno(), fcntl.LOCK_UN)
        allocation.close()
    emit_telemetry(
        path, "discussion_started", agents=agents, timed_watch=timed_watch,
        store=str(store), created_at=timestamp,
        subject_sha256=hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16],
    )
    index_upsert(store, discussion_id, subject_sha256=hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16],
                 agents=agents, opened_at=timestamp)
    return discussion_id, path


def _read_lock_holder(path: Path) -> Tuple[Optional[int], str]:
    """Parse `pid=<n> held-since=<ts>` from a lock file, for DIAGNOSTICS ONLY — the lock itself is
    held by flock, never inferred from this content. Returns (pid or None, raw text)."""
    try:
        raw = path.read_text(encoding="utf-8").strip()
    except OSError:
        return None, ""
    match = re.search(r"\bpid=(\d+)\b", raw)
    return (int(match.group(1)) if match else None), raw


class DiscussionLock:
    """Exclusive writer lock for one discussion, held by `flock` — the same idiom `DriveLock`
    already uses in this file.

    GH-38 item 1 asked for a stale lock left by a killed sender to stop bricking a discussion
    forever. The first implementation read the holder's pid, tested liveness with `os.kill(pid, 0)`,
    and stole the lock from a dead holder. The agy QA review (relay-system/2026-08-18) rejected that
    as unsafe and it was right on two counts:

      1. `os.kill` inspects only the LOCAL process table, so a holder on another host sharing the
         path reads as dead — and pid reuse makes the verdict unreliable even locally.
      2. Steal-then-claim is not atomic. Two contenders could both see the dead pid, both unlink,
         and both create: the second unlink removes the FIRST contender's freshly created lock, so
         both return believing they hold it exclusively. `O_EXCL` cannot detect that, because the
         damage is done by the unlink, not the create.

    `flock` removes the whole class of problem: the kernel releases the lock when the holding
    process dies, so a crashed sender's lock is simply not held and the next writer proceeds. No
    liveness guess, no steal, no unlink race. The lock FILE is deliberately never unlinked —
    unlinking is what reintroduces the race (a releaser can delete an inode another process is
    mid-acquire on). The leftover file is inert: it is a mutex, not a claim."""

    def __init__(self, path: Path):
        if path.name == "conversation.md":
            runtime = path.parent / "runtime"
            private_mkdir(runtime)
            self.path = runtime / "discussion.lock"
        else:
            self.path = path.with_name(f".{path.name}.lock")
        self.handle = None  # type: Optional[object]

    def __enter__(self) -> None:
        self.handle = self.path.open("a+", encoding="utf-8")
        try:
            fcntl.flock(self.handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            self.handle.close()
            self.handle = None
            pid, raw = _read_lock_holder(self.path)
            detail = f"held by pid {pid}" if pid is not None else f"holder unrecorded: {raw!r}"
            raise Agent2AgentError(
                f"discussion is locked by another writer: {self.path} ({detail}). "
                f"That process is running — wait for it to finish rather than deleting the lock; "
                f"a crashed holder's lock is released by the OS and needs no cleanup."
            ) from exc
        self.handle.seek(0)
        self.handle.truncate()
        self.handle.write(f"pid={os.getpid()} held-since={utc_now()}\n")
        self.handle.flush()

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
        if self.handle is not None:
            fcntl.flock(self.handle.fileno(), fcntl.LOCK_UN)
            self.handle.close()
            self.handle = None


class DriveLock:
    """Hold one process-owned drive lane; flock releases automatically after a crash."""

    def __init__(self, path: Path, member: str):
        if path.name == "conversation.md":
            runtime = path.parent / "runtime"
            private_mkdir(runtime)
            self.path = runtime / f"drive-{member}.lock"
        else:
            self.path = path.with_name(f".{path.name}.{member}.drive.lock")
        self.handle = None  # type: Optional[object]

    def __enter__(self) -> None:
        try:
            self.handle = self.path.open("a+", encoding="utf-8")
            fcntl.flock(self.handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            if self.handle is not None:
                self.handle.close()
                self.handle = None
            raise Agent2AgentError(f"drive is already active for this participant: {self.path}") from exc
        self.handle.seek(0)
        self.handle.truncate()
        self.handle.write(f"pid={os.getpid()} started={utc_now()}\n")
        self.handle.flush()

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
        if self.handle is not None:
            fcntl.flock(self.handle.fileno(), fcntl.LOCK_UN)
            self.handle.close()
            self.handle = None


def read_discussion(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        raise Agent2AgentError(f"discussion is not a regular file: {path}")
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise Agent2AgentError(f"could not read discussion: {path}: {exc}") from exc


def validate_member(content: str, number: int) -> str:
    member = agent_id(number)
    if member not in parse_roster(content):
        raise Agent2AgentError(f"{member} is not in this discussion's roster")
    return member


def join_discussion(
    root: Path, discussion_id: str, number: int, expected_subject: Optional[str]
) -> Tuple[Path, str, str, str]:
    path = resolve_discussion(root, discussion_id)
    content = read_discussion(path)
    member = validate_member(content, number)
    subject = field(content, "SUBJECT")
    if expected_subject is not None and normalize_subject(expected_subject) != subject:
        raise Agent2AgentError(
            f"invitation subject does not match #{discussion_id}: expected {subject!r}, got {normalize_subject(expected_subject)!r}"
        )
    status = field(content, "STATUS")
    next_member = field(content, "NEXT")
    if status.lower() == "closed":
        decision = "closed"
    elif next_member == member:
        decision = "take-turn"
    else:
        decision = "wait"
    return path, subject, next_member, decision


def timed_watch_enabled(content: str) -> bool:
    """Old discussions predate this optional setting and remain manual by default."""
    match = re.search(FIELD_RE_TEMPLATE.format(key="TIMED-WATCH"), _header(content), re.MULTILINE)
    return bool(match and match.group(1) == "enabled")


def positive_interval(value: str) -> float:
    try:
        interval = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be a number of seconds") from exc
    if interval <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return interval


def nonnegative_timeout(value: str) -> float:
    try:
        timeout = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be a number of seconds") from exc
    if timeout < 0:
        raise argparse.ArgumentTypeError("must be zero or greater")
    return timeout


def stale_after_default() -> float:
    raw = os.environ.get("AGENT2AGENT_STALE_AFTER")
    if raw is None:
        return DEFAULT_STALE_AFTER
    try:
        return positive_interval(raw)
    except argparse.ArgumentTypeError as exc:
        raise Agent2AgentError(f"AGENT2AGENT_STALE_AFTER {exc}") from exc


def wait_for_turn(
    root: Path,
    discussion_id: str,
    number: int,
    interval: float,
    timeout: float,
    announce: bool,
    heartbeat: Optional[Callable[[Path], None]] = None,
) -> Tuple[Path, str, str, str]:
    """Poll without writing until this member owns NEXT, closure, or timeout.

    `heartbeat` runs once per poll against the resolved relay path. It exists so a doorbell can
    refresh its liveness marker on EVERY iteration: the agy QA review caught that stamping it once
    before the loop made any seat waiting longer than 2x its interval read as STALE while it was
    polling perfectly normally — the false positive would have been worst for exactly the long,
    patient waits the doorbell exists to support. The heartbeat writes only to a sidecar, so this
    stays a non-writing poll as far as the discussion is concerned."""
    started = time.monotonic()
    previous = None  # type: Optional[Tuple[str, str, str]]
    while True:
        path, subject, next_member, decision = join_discussion(root, discussion_id, number, None)
        if heartbeat is not None:
            heartbeat(path)
        content = read_discussion(path)
        state = (field(content, "TURN"), next_member, field(content, "STATUS"))
        if announce and state != previous:
            print(f"STATE: turn={state[0]} next={state[1]} status={state[2]}", flush=True)
        previous = state
        if decision in ("take-turn", "closed"):
            return path, subject, next_member, decision
        elapsed = time.monotonic() - started
        if timeout and elapsed >= timeout:
            return path, subject, next_member, "timeout"
        delay = interval
        if timeout:
            delay = min(delay, max(0.0, timeout - elapsed))
        time.sleep(delay)


def rearm_command(
    root: Path, discussion_id: str, number: int, interval: float, timeout: float
) -> str:
    """The exact argv that relaunches this watch — self-contained (absolute script + --root)
    so the waking session can run it verbatim from any CWD.

    GH-38 item 2: the interpreter is named EXPLICITLY rather than relying on the shebang plus the
    executable bit, and the script path comes from __file__ rather than sys.argv[0]. argv[0] is
    whatever the invoking session happened to use — loading this module via `python3 -c` rendered a
    bogus `<cwd>/-c` path — and a mode-stripping copy (zip vendoring, some transfer paths) turns a
    bare script path into a 127/permission error instead of the intended argparse behavior."""
    argv = [
        sys.executable or "python3",
        os.path.abspath(__file__),
        "--root", str(root),
    ]
    if ACTIVE_STORE is not None:
        argv.extend(["--store", str(ACTIVE_STORE)])
    argv.extend([
        "watch",
        "--id", discussion_id,
        "--agent", str(number),
        "--interval", f"{interval:g}",
        "--timeout", f"{timeout:g}",
    ])
    return " ".join(shlex.quote(part) for part in argv)


def watch_sidecar(path: Path, number: int) -> Path:
    """Per-agent doorbell-liveness marker (GH-38 item 6). Deliberately a SIDECAR, not a field in
    the relay file: `watch` must leave the discussion byte-identical (the suite pins this), and
    lock/liveness evidence does not belong inside the artifact it describes — the same reasoning
    as GH-32's r4 lock-audit finding."""
    if path.name == "conversation.md":
        runtime = path.parent / "runtime"
        private_mkdir(runtime)
        return runtime / f"{agent_id(number)}.watch"
    return path.with_name(f"{path.name}.watch.{agent_id(number)}")


def touch_watch_sidecar(path: Path, number: int) -> None:
    marker = watch_sidecar(path, number)
    try:
        atomic_write(marker, f"pid={os.getpid()} armed={utc_now()}\n")
    except OSError:
        pass   # liveness reporting is a nicety; it must never break a watch


def _age_since(timestamp: str) -> Optional[float]:
    try:
        parsed = dt.datetime.fromisoformat(timestamp)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt.timezone.utc)
        return max(0.0, (dt.datetime.now(dt.timezone.utc) - parsed).total_seconds())
    except (TypeError, ValueError):
        return None


def doorbell_state(
    path: Path,
    number: int,
    stale_after: float,
    active: bool = False,
    turn_age: Optional[float] = None,
) -> Optional[str]:
    """Describe a seat's observed doorbell state, or None when it may be participating manually."""
    marker = watch_sidecar(path, number)
    try:
        age = time.time() - marker.stat().st_mtime
    except OSError:
        if active:
            duration = f" for {turn_age:.0f}s" if turn_age is not None else ""
            return f"ACTIVE — owns NEXT{duration}; heartbeat not observed/manual"
        return None
    if active:
        duration = f" for {turn_age:.0f}s" if turn_age is not None else ""
        return f"ACTIVE — owns NEXT{duration}; heartbeat {age:.0f}s ago"
    stale = age > stale_after
    suffix = " — STALE, that seat may no longer be listening" if stale else ""
    return f"armed {age:.0f}s ago{suffix}"


def peer_doorbell_report(
    path: Path, content: str, number: int, stale_after: float
) -> Optional[str]:
    """One advisory peer line, or None when no doorbell has been observed for that seat."""
    member = agent_id(number)
    active = field(content, "STATUS").lower() != "closed" and field(content, "NEXT") == member
    state = doorbell_state(
        path,
        number,
        stale_after,
        active=active,
        turn_age=_age_since(field(content, "UPDATED")) if active else None,
    )
    return None if state is None else f"peer doorbell ({agent_id(number)}): {state}"


def report_peer_doorbells(
    path: Path, content: str, self_number: int, stale_after: float
) -> None:
    """Print one advisory line per OTHER roster seat that has ever armed a doorbell. Silence about
    a seat means it never armed one — which is normal for a manual participant, so this reports and
    never refuses."""
    for index, _ in enumerate(parse_roster(content), start=1):
        if index == self_number:
            continue
        line = peer_doorbell_report(path, content, index, stale_after)
        if line:
            print(line)


def report_discussion_status(root: Path, discussion_id: str, stale_after: float) -> None:
    """Print a seat-agnostic overview without changing the discussion or its sidecars."""
    path = resolve_discussion(root, discussion_id)
    content = read_discussion(path)
    roster = parse_roster(content)
    print(f"XYZ AgentChorus #{discussion_id}")
    print(f"Relay file: {path}")
    print(f"Subject: {field(content, 'SUBJECT')}")
    print(f"STATUS: {field(content, 'STATUS')}")
    print(f"TURN: {field(content, 'TURN')}")
    print(f"NEXT: {field(content, 'NEXT')}")
    print(f"EXTENSIONS: {optional_field(content, 'EXTENSIONS', '0')}")
    print(f"AGENTS: {' '.join(roster)}")
    print(f"TIMED-WATCH: {'enabled' if timed_watch_enabled(content) else 'disabled'}")
    next_member = field(content, "NEXT")
    turn_age = _age_since(field(content, "UPDATED"))
    for number, member in enumerate(roster, start=1):
        active = field(content, "STATUS").lower() != "closed" and member == next_member
        state = doorbell_state(
            path, number, stale_after, active=active,
            turn_age=turn_age if active else None,
        )
        print(f"DOORBELL {member}: {state or 'not observed/manual'}")


def ping_discussion(root: Path, discussion_id: str, number: int) -> Path:
    """Refresh one participant heartbeat without touching the canonical conversation."""
    path = resolve_discussion(root, discussion_id)
    content = read_discussion(path)
    member = validate_member(content, number)
    if field(content, "STATUS").lower() == "closed":
        raise Agent2AgentError(f"AgentChorus discussion #{discussion_id} is closed")
    touch_watch_sidecar(path, number)
    print(f"HEARTBEAT: refreshed {member}")
    return path


def watch_discussion(
    root: Path, discussion_id: str, number: int, interval: float, timeout: float
) -> int:
    path = resolve_discussion(root, discussion_id)
    print(f"Watching XYZ AgentChorus #{discussion_id} as {agent_id(number)}")
    print(f"Relay file: {path}")
    touch_watch_sidecar(path, number)
    _, _, _, decision = wait_for_turn(
        root, discussion_id, number, interval, timeout, announce=True,
        heartbeat=lambda p: touch_watch_sidecar(p, number),
    )
    print(f"DECISION: {decision}")
    # GH-510 doorbell: re-arming after a turn is protocol, not discipline — hand the waking
    # session the exact relaunch command at the moment it needs it. Printed ONLY on take-turn:
    # a closed or timed-out watch must not be re-armed by reflex, so those exits stay bare.
    if decision == "take-turn":
        print(f"REARM: {rearm_command(root, discussion_id, number, interval, timeout)}")
    elif decision == "timeout":
        # GH-38 item 3: a window that expires while the peer is still thinking used to kill the
        # doorbell with exit 3 and NO printed command — a background task exits, the session may
        # not notice, and the orchestrator's next turn lands in front of a deaf seat. The command
        # is offered under a distinct verb so it stays a deliberate choice, never a reflex: this
        # is not REARM, and `closed` still prints nothing at all.
        print(
            "STILL-WAITING: the watch window elapsed with the turn still held elsewhere. "
            "Re-arm deliberately (or report the wait) with:"
        )
        print(f"  {rearm_command(root, discussion_id, number, interval, timeout)}")
    return 3 if decision == "timeout" else 0


def turn_prompt(discussion_id: str, number: int, path: Path, subject: str) -> str:
    return f"""Join XYZ AgentChorus #{discussion_id} as agent number {number_word(number)} to discuss: {quoted_subject(subject)}

It is now your turn. Read the complete discussion at:
{path}

Respond to the discussion, then use the AgentChorus helper's send or close command. Do not edit the
relay file directly. Route NEXT to exactly one other roster member unless you close the discussion.
"""


def stop_turn_command(process: subprocess.Popen) -> None:
    """Stop the isolated command group; do not leave agent descendants running."""
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=2)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()


def run_turn_command(
    command: List[str], root: Path, environment: dict, prompt: str, timeout: float
) -> int:
    try:
        process = subprocess.Popen(
            command,
            cwd=str(root),
            env=environment,
            stdin=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
    except OSError as exc:
        raise Agent2AgentError(f"could not start turn command: {exc}") from exc
    try:
        process.communicate(prompt, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        stop_turn_command(process)
        raise Agent2AgentError(f"turn command timed out after {timeout:.1f} seconds") from exc
    except KeyboardInterrupt:
        stop_turn_command(process)
        raise
    return process.returncode


def drive_discussion(
    root: Path,
    discussion_id: str,
    number: int,
    interval: float,
    timeout: float,
    max_turns: int,
    turn_command: List[str],
) -> int:
    if turn_command and turn_command[0] == "--":
        turn_command = turn_command[1:]
    if not turn_command:
        raise Agent2AgentError("drive requires a turn command after --")
    path = resolve_discussion(root, discussion_id)
    content = read_discussion(path)
    member = validate_member(content, number)
    completed = 0
    deadline = time.monotonic() + timeout
    with DriveLock(path, member):
        print(f"Driving XYZ AgentChorus #{discussion_id} as {member}")
        print(f"Relay file: {path}")
        while completed < max_turns:
            remaining = max(0.0, deadline - time.monotonic())
            if remaining == 0:
                print("DECISION: timeout")
                return 3
            current_path, subject, _, decision = wait_for_turn(
                root, discussion_id, number, interval, remaining, announce=True
            )
            if decision == "closed":
                print("DECISION: closed")
                return 0
            if decision == "timeout":
                print("DECISION: timeout")
                return 3
            before = read_discussion(current_path)
            before_turn = int(field(before, "TURN"))
            environment = os.environ.copy()
            environment.update(
                {
                    "AGENT2AGENT_ID": discussion_id,
                    "AGENT2AGENT_AGENT": str(number),
                    "AGENT2AGENT_MEMBER": member,
                    "AGENT2AGENT_RELAY_FILE": str(current_path),
                    "AGENT2AGENT_ROOT": str(root),
                    "AGENT2AGENT_HOME": str(ACTIVE_STORE) if ACTIVE_STORE else "",
                    "AGENT2AGENT_SUBJECT": subject,
                }
            )
            command_timeout = max(0.0, deadline - time.monotonic())
            if command_timeout == 0:
                print("DECISION: timeout")
                return 3
            returncode = run_turn_command(
                turn_command,
                root,
                environment,
                turn_prompt(discussion_id, number, current_path, subject),
                command_timeout,
            )
            if returncode != 0:
                raise Agent2AgentError(f"turn command failed with exit {returncode}")
            after = read_discussion(current_path)
            after_turn = int(field(after, "TURN"))
            if after_turn <= before_turn or (
                field(after, "STATUS").lower() != "closed" and field(after, "NEXT") == member
            ):
                raise Agent2AgentError(
                    "turn command exited 0 without advancing and handing off the discussion"
                )
            completed += 1
            print(f"DRIVE: completed turn {after_turn} ({completed}/{max_turns})", flush=True)
        print("DECISION: max-turns")
    return 0


def load_message(args: argparse.Namespace) -> str:
    if args.message is not None:
        return normalize_message(args.message)
    source = args.message_file
    if source == "-":
        return normalize_message(sys.stdin.read())
    try:
        return normalize_message(Path(source).read_text(encoding="utf-8"))
    except (OSError, UnicodeError) as exc:
        raise Agent2AgentError(f"could not read message file {source}: {exc}") from exc


def load_named_text(args: argparse.Namespace, name: str) -> str:
    value = getattr(args, name)
    if value is not None:
        return normalize_message(value)
    source = getattr(args, f"{name}_file")
    if source == "-":
        return normalize_message(sys.stdin.read())
    try:
        return normalize_message(Path(source).read_text(encoding="utf-8"))
    except (OSError, UnicodeError) as exc:
        raise Agent2AgentError(f"could not read {name.replace('_', ' ')} file {source}: {exc}") from exc


def validate_structured_close(message: str) -> str:
    positions = []
    for index, section in enumerate(CLOSE_SECTIONS):
        level = "##" if index == 0 else "###"
        heading = f"{level} {section}"
        matches = list(re.finditer(rf"(?m)^{re.escape(heading)}[ \t]*$", message))
        if len(matches) != 1:
            raise Agent2AgentError(
                f"structured close must contain exactly one '{heading}' heading; "
                "use `close --print-template` for the scaffold or `--trivial` for an administrative close"
            )
        if index:
            body = message[matches[0].end():]
            next_heading = re.search(r"(?m)^#{2,3}[ \t]+", body)
            body = body[:next_heading.start()] if next_heading else body
            if not body.strip():
                raise Agent2AgentError(f"structured close section '{heading}' must not be empty")
        positions.append(matches[0].start())
    if positions != sorted(positions):
        raise Agent2AgentError("structured close headings are out of order")
    return message


def render_scope_extension(question: str, done_condition: str) -> str:
    return (
        "## Scope Extension — Operator Follow-Up\n\n"
        f"### New Question\n\n{question}\n\n"
        f"### Updated Done Condition\n\n{done_condition}"
    )


def verify_git_handoff(root: Path) -> str:
    repository = canonical_repository_root(root)
    if _git_value(repository, "rev-parse", "--is-inside-work-tree") != "true":
        raise Agent2AgentError("--check-clean requires a Git working tree")
    try:
        dirty = subprocess.check_output(
            ["git", "-C", str(repository), "status", "--porcelain=v1"],
            text=True,
            stderr=subprocess.STDOUT,
        ).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise Agent2AgentError(f"could not inspect Git working tree: {exc}") from exc
    if dirty:
        first = dirty.splitlines()[0]
        raise Agent2AgentError(f"--check-clean refused: working tree is not clean ({first})")
    branch = _git_value(repository, "symbolic-ref", "--quiet", "--short", "HEAD")
    if not branch:
        raise Agent2AgentError("--check-clean refused: detached HEAD has no upstream handoff target")
    upstream = _git_value(
        repository, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"
    )
    if not upstream:
        raise Agent2AgentError(f"--check-clean refused: branch {branch} has no upstream")
    head = _git_value(repository, "rev-parse", "HEAD")
    upstream_head = _git_value(repository, "rev-parse", "@{upstream}")
    if not head or not upstream_head:
        raise Agent2AgentError("--check-clean could not resolve HEAD and its upstream")
    if head != upstream_head:
        raise Agent2AgentError(
            f"--check-clean refused: HEAD {head[:12]} does not match {upstream} {upstream_head[:12]}"
        )
    return f"clean; HEAD {head} matches {upstream}"


def append_turn(
    root: Path,
    discussion_id: str,
    number: int,
    message: str,
    next_number: Optional[int],
    close: bool,
    extension: bool = False,
) -> Tuple[Path, int, str, str]:
    path = resolve_discussion(root, discussion_id)
    with DiscussionLock(path):
        content = read_discussion(path)
        member = validate_member(content, number)
        roster = parse_roster(content)
        status = field(content, "STATUS")
        if status.lower() == "closed":
            raise Agent2AgentError(f"AgentChorus discussion #{discussion_id} is closed")
        current = field(content, "NEXT")
        if current != member:
            raise Agent2AgentError(f"out of turn: NEXT is {current}, not {member}")
        last_turn_text = field(content, "TURN")
        try:
            turn = int(last_turn_text) + 1
        except ValueError as exc:
            raise Agent2AgentError(f"discussion has invalid TURN: {last_turn_text}") from exc
        if close:
            next_member = "none"
            new_status = "Closed"
        else:
            if next_number is None:
                raise Agent2AgentError("--next-agent is required when sending a turn")
            next_member = agent_id(next_number)
            if next_member not in roster:
                raise Agent2AgentError(f"{next_member} is not in this discussion's roster")
            if next_member == member:
                raise Agent2AgentError("the next turn must be routed to a different participant")
            new_status = status
        timestamp = utc_now()
        updated = replace_field(content, "NEXT", next_member)
        updated = replace_field(updated, "STATUS", new_status)
        updated = replace_field(updated, "TURN", str(turn))
        updated = replace_field(updated, "UPDATED", timestamp)
        if extension:
            raw_extensions = optional_field(content, "EXTENSIONS", "0")
            try:
                extension_count = int(raw_extensions) + 1
            except ValueError as exc:
                raise Agent2AgentError(f"discussion has invalid EXTENSIONS: {raw_extensions}") from exc
            updated = upsert_field(updated, "EXTENSIONS", str(extension_count), "TIMED-WATCH")
        updated = updated.rstrip() + f"\n\n### Turn {turn} — {member} — {timestamp}\n\n{message}\n"
        atomic_write(path, updated)
        sync_metadata(path, updated)
    citations, unique_citations = _citation_counts(message)
    if telemetry_enabled():
        emit_telemetry(
            path, "turn_written", turn=turn, agent=member, next_agent=next_member,
            message_bytes=len(message.encode("utf-8")), line_count=message.count("\n") + 1,
            citation_count=citations, unique_citation_count=unique_citations,
            contains_falsifier_section="Falsifier" in message,
            contains_dissent_section="Dissent" in message,
        )
        store_for_index = ACTIVE_STORE
        if close:
            metrics = parse_close_metrics(message)
            emit_telemetry(path, "close_written", close_type="substantive", turn_count=turn, **metrics)
            try:
                report = {"discussion_id": discussion_id, "turn_count": turn, **metrics}
                runtime = path.parent / "runtime"
                private_mkdir(runtime)
                atomic_write(runtime / "close_report.json", json.dumps(report, indent=2, sort_keys=True) + "\n")
            except OSError:
                pass
            index_upsert(store_for_index, discussion_id, closed_at=timestamp,
                         close_type="substantive", turn_count=turn)
        if extension:
            raw_ext = optional_field(updated, "EXTENSIONS", "0")
            emit_telemetry(path, "extension_added", extension_number=raw_ext,
                           question_bytes=len(message.encode("utf-8")), done_condition_bytes=0)
    return path, turn, next_member, field(updated, "SUBJECT")


# ── Telemetry commands (Gen 2 Phase 1) ──────────────────────────────────────────

def telemetry_audit(discussion_id: str) -> int:
    """Comparator negative control: prove the sidecar carries ZERO transcript content.

    Deterministic check: no string field value of any event (length >= 12) may appear
    verbatim inside conversation.md. Exits 1 naming the leak on any hit.
    """
    path = resolve_discussion(normalize_root(os.environ.get("AGENT2AGENT_ROOT")), discussion_id)
    sidecar = telemetry_sidecar(path)
    if not sidecar.is_file():
        print(f"audit: no telemetry sidecar for #{discussion_id} (telemetry off or no events)")
        return 1
    transcript = path.read_text(encoding="utf-8")
    iso8601 = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}")
    pathlike = re.compile(r"^[/~.]?[-\w/.*%]+$")
    leaks = []
    for line in sidecar.read_text(encoding="utf-8").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        for key, value in event.items():
            if not isinstance(value, str) or len(value) < 12:
                continue
            # timestamps and filesystem paths are allowed metadata that may legitimately
            # coincide with transcript headers; the audit hunts prose/content leakage.
            if key in ("ts", "created_at", "closed_at", "recorded_at", "store"):
                continue
            if iso8601.match(value) or pathlike.match(value):
                continue
            if value in transcript:
                leaks.append(f"{event.get('event')}.{key}")
    if leaks:
        print(f"audit FAIL: transcript content found in telemetry fields: {sorted(set(leaks))}")
        return 1
    print(f"audit PASS: zero transcript content in {sidecar} "
          f"(structural allowlist held; checked every string field >= 12 chars)")
    return 0


def command_telemetry(args: argparse.Namespace) -> int:
    action = args.telemetry_action
    if action == "status":
        flag = os.environ.get("AGENT2AGENT_TELEMETRY", "")
        enabled = telemetry_enabled()
        window = TELEMETRY_PILOT_WINDOW
        print(f"telemetry enabled: {enabled}")
        print(f"AGENT2AGENT_TELEMETRY env: {flag!r} ({'hard override active' if flag else 'unset — pilot window decides'})")
        print(f"pilot window (default-ON): {window[0]} .. {window[1]}")
        print(f"schema version: {TELEMETRY_SCHEMA_VERSION}")
        db = telemetry_index_path(ACTIVE_STORE)
        print(f"index: {db} ({'present' if db and db.is_file() else 'not created yet'})")
        print("policy: metadata-only; field allowlist per event; hard override AGENT2AGENT_TELEMETRY=0")
        return 0
    if action == "purge":
        removed = []
        store = ACTIVE_STORE
        if store and store.is_dir():
            for sidecar in store.rglob("telemetry.jsonl"):
                sidecar.unlink()
                removed.append(str(sidecar))
            for report in store.rglob("close_report.json"):
                report.unlink()
                removed.append(str(report))
            db = telemetry_index_path(store)
            if db and db.is_file():
                db.unlink()
                removed.append(str(db))
        print(f"purged {len(removed)} telemetry artifacts under {store}")
        for item in removed:
            print(f"  - {item}")
        return 0
    if action == "aggregate":
        conn, db = index_connect(ACTIVE_STORE)
        if conn is None:
            print("telemetry aggregate: no store configured", file=sys.stderr)
            return 2
        rows = conn.execute(
            "SELECT id, agents, opened_at, closed_at, close_type, turn_count, outcome"
            " FROM discussions ORDER BY opened_at"
        ).fetchall()
        conn.close()
        closed = [r for r in rows if r[3]]
        with_outcome = [r for r in rows if r[6]]
        print(f"discussions: {len(rows)} (closed: {len(closed)}, outcome recorded: {len(with_outcome)})")
        for r in rows:
            print(f"  #{r[0]} agents={r[1]} opened={r[2]} closed={r[3] or '-'} "
                  f"type={r[4] or '-'} turns={r[5] or 0} outcome={r[6] or '-'}")
        return 0
    if action == "audit":
        return telemetry_audit(args.id)
    raise Agent2AgentError(f"unknown telemetry action: {action}")


def command_outcome(args: argparse.Namespace) -> int:
    allowed = {"implemented", "partial", "not_implemented", "superseded"}
    if args.result not in allowed:
        raise Agent2AgentError(f"--result must be one of {sorted(allowed)}")
    root = normalize_root(args.root)
    path = resolve_discussion(root, args.id)
    content = read_discussion(path)
    if field(content, "STATUS").lower() != "closed":
        raise Agent2AgentError(f"outcome requires a closed discussion (#{args.id} is still open)")
    agents_meta = {}
    for pair in args.agent or []:
        seat, _, model = pair.partition("=")
        if not model:
            raise Agent2AgentError("--agent expects SEAT=MODEL, e.g. --agent 2=glm-5.3")
        agents_meta[seat] = model
    roster_size = len(parse_roster(content))
    emit_telemetry(path, "outcome_recorded", result=args.result,
                   note_bytes=len((args.note or "").encode("utf-8")),
                   agents_json=json.dumps(agents_meta, sort_keys=True))
    index_upsert(ACTIVE_STORE, args.id, outcome=args.result,
                 outcome_note=(args.note or "")[:200], outcome_agents=json.dumps(agents_meta, sort_keys=True))
    conn, _ = index_connect(ACTIVE_STORE)
    if conn is not None:
        try:
            conn.execute(
                "INSERT INTO outcomes_log (id, result, note, agents, recorded_at) VALUES (?,?,?,?,?)",
                (args.id, args.result, (args.note or "")[:200],
                 json.dumps(agents_meta, sort_keys=True), utc_now()),
            )
            conn.commit()
        finally:
            conn.close()
    print(f"Outcome recorded for #{args.id}: {args.result}"
          + (f" ({len(agents_meta)}/{roster_size} seats attributed)" if agents_meta else ""))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="agent-chorus",
        description="Create or advance a serialized XYZ discussion shared by two or more agent sessions.",
    )
    parser.add_argument("--root", help="XYZ harness root; defaults to AGENT2AGENT_ROOT or this skill's repository")
    parser.add_argument(
        "--store",
        help="external AgentChorus transcript store (directory name Agent2Agent-Transcripts retained for compatibility); defaults to AGENT2AGENT_HOME, user config, or a sibling Agent2Agent-Transcripts directory",
    )
    parser.add_argument(
        "--stale-after", type=positive_interval,
        help="seconds before an inactive waiting heartbeat is STALE (default: 1800 or AGENT2AGENT_STALE_AFTER)",
    )
    commands = parser.add_subparsers(dest="command", required=True)

    start = commands.add_parser("start", help="create a discussion and seed turn 1 from agent1")
    start.add_argument("--subject", required=True)
    start.add_argument(
        "--packet-file", required=True,
        help="prepared UTF-8 context packet, or - for stdin",
    )
    start.add_argument("--agents", type=int, default=2, help="participant count (default: 2)")
    start.add_argument(
        "--timed-watch", action="store_true",
        help="include a 2-minute / 30-minute background-watch request in every invitation",
    )
    start.add_argument("--id", dest="explicit_id", help=argparse.SUPPRESS)

    configure = commands.add_parser(
        "configure-store", help="persist a private user-level default transcript store"
    )
    configure.add_argument("--path", required=True, help="external directory to persist as the default")

    status = commands.add_parser("status", help="inspect a discussion without taking a participant seat")
    status.add_argument("--id", required=True)

    join = commands.add_parser("join", help="resolve an invitation without modifying the discussion")
    join.add_argument("--id", required=True)
    join.add_argument("--agent", type=int, required=True, help="plain agent number, such as 2")
    join.add_argument("--expect-subject", help="reject a stale or altered invitation subject")

    ping = commands.add_parser("ping", help="refresh this participant's heartbeat without changing the transcript")
    ping.add_argument("--id", required=True)
    ping.add_argument("--agent", type=int, required=True)

    watch = commands.add_parser("watch", help="wait read-only until this participant owns NEXT")
    watch.add_argument("--id", required=True)
    watch.add_argument("--agent", type=int, required=True)
    watch.add_argument(
        "--interval", type=positive_interval, default=DEFAULT_POLL_INTERVAL,
        help="poll interval in seconds (default: 150)",
    )
    watch.add_argument(
        "--timeout", type=nonnegative_timeout, default=0.0,
        help="stop after this many seconds; 0 waits indefinitely (default: 0)",
    )

    send = commands.add_parser("send", help="append the caller's turn and route to another participant")
    send.add_argument("--id", required=True)
    send.add_argument("--agent", type=int, required=True)
    send.add_argument("--next-agent", type=int, required=True)
    send.add_argument(
        "--check-clean", action="store_true",
        help="require a clean Git tree whose HEAD matches its configured upstream before handoff",
    )
    send_message = send.add_mutually_exclusive_group(required=True)
    send_message.add_argument("--message")
    send_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")

    close = commands.add_parser("close", help="append the caller's final turn and close the discussion")
    close.add_argument("--id", required=True)
    close.add_argument("--agent", type=int, required=True)
    close.add_argument("--trivial", action="store_true", help="allow an unstructured administrative close")
    close.add_argument("--print-template", action="store_true", help="print the structured close scaffold and write nothing")
    close.add_argument(
        "--check-clean", action="store_true",
        help="require a clean Git tree whose HEAD matches its configured upstream before closing",
    )
    close_message = close.add_mutually_exclusive_group(required=False)
    close_message.add_argument("--message")
    close_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")

    extend = commands.add_parser("extend", help="record an operator scope extension and route the next turn")
    extend.add_argument("--id", required=True)
    extend.add_argument("--agent", type=int, required=True)
    extend.add_argument("--next-agent", type=int, required=True)
    extend.add_argument(
        "--check-clean", action="store_true",
        help="require a clean Git tree whose HEAD matches its configured upstream before handoff",
    )
    extend_question = extend.add_mutually_exclusive_group(required=True)
    extend_question.add_argument("--question")
    extend_question.add_argument("--question-file")
    extend_done = extend.add_mutually_exclusive_group(required=True)
    extend_done.add_argument("--done-condition")
    extend_done.add_argument("--done-condition-file")

    drive = commands.add_parser("drive", help="opt in to bounded polling plus a turn command")
    drive.add_argument("--id", required=True)
    drive.add_argument("--agent", type=int, required=True)
    drive.add_argument(
        "--interval", type=positive_interval, default=DEFAULT_POLL_INTERVAL,
        help="poll interval in seconds (default: 150)",
    )
    drive.add_argument(
        "--timeout", type=positive_interval, default=DEFAULT_DRIVE_TIMEOUT,
        help="total drive timeout in seconds (default: 3600)",
    )
    drive.add_argument(
        "--max-turns", type=int, default=DEFAULT_MAX_DRIVE_TURNS,
        help="maximum turns this process may dispatch (default: 6)",
    )
    drive.add_argument("turn_command", nargs=argparse.REMAINDER, help="command to run on each owned turn")
    outcome = commands.add_parser(
        "outcome", help="record a closed discussion's real-world result (read-only after closure)",
    )
    outcome.add_argument("--id", required=True)
    outcome.add_argument("--result", required=True,
                         help="implemented | partial | not_implemented | superseded")
    outcome.add_argument("--note", help="short operator note (truncated to 200 chars in the index)")
    outcome.add_argument("--agent", action="append",
                         help="SEAT=MODEL attribution, repeatable (e.g. --agent 2=glm-5.3)")

    telemetry = commands.add_parser(
        "telemetry", help="telemetry sidecar + index operations (status | purge | aggregate | audit)",
    )
    telemetry.add_argument("telemetry_action", choices=["status", "purge", "aggregate", "audit"])
    telemetry.add_argument("--id", help="discussion id (audit)")

    return parser



def main(argv: Optional[List[str]] = None) -> int:
    global ACTIVE_STORE
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        root = normalize_root(args.root)
        stale_after = args.stale_after if args.stale_after is not None else stale_after_default()
        context_packet = load_context_packet(args.packet_file) if args.command == "start" else None
        requested_store = args.path if args.command == "configure-store" else args.store
        ACTIVE_STORE = normalize_store(
            root, requested_store, create=args.command in ("start", "configure-store")
        )
        os.environ["AGENT2AGENT_HOME"] = str(ACTIVE_STORE)
        if args.command == "configure-store":
            config_path = persist_store_default(ACTIVE_STORE)
            print(f"Configured Agent2Agent store: {ACTIVE_STORE}")
            print(f"Config file: {config_path}")
        elif args.command == "start":
            discussion_id, path = create_discussion(
                root, args.subject, args.agents, args.explicit_id, args.timed_watch, context_packet,
                ACTIVE_STORE,
            )
            subject = normalize_subject(args.subject)
            print(f"Created XYZ AgentChorus #{discussion_id}")
            print(f"Relay file: {path}")
            for number in range(2, args.agents + 1):
                print(invitation(discussion_id, number, subject, args.timed_watch))
        elif args.command == "status":
            report_discussion_status(root, args.id, stale_after)
        elif args.command == "join":
            path, subject, next_member, decision = join_discussion(
                root, args.id, args.agent, args.expect_subject
            )
            print(f"XYZ AgentChorus #{args.id}")
            print(f"Relay file: {path}")
            print(f"Subject: {subject}")
            print(f"You are: {agent_id(args.agent)}")
            print(f"NEXT: {next_member}")
            print("CONTEXT: read the prepared packet in Turn 1 before responding")
            if timed_watch_enabled(read_discussion(path)):
                print("TIMED-WATCH: check every 120 seconds for 1,800 seconds while waiting")
            report_peer_doorbells(path, read_discussion(path), args.agent, stale_after)
            print(f"DECISION: {decision}")
        elif args.command == "ping":
            path = ping_discussion(root, args.id, args.agent)
            print(f"Relay file: {path}")
        elif args.command == "watch":
            return watch_discussion(root, args.id, args.agent, args.interval, args.timeout)
        elif args.command == "send":
            receipt = verify_git_handoff(root) if args.check_clean else None
            path, turn, next_member, subject = append_turn(
                root, args.id, args.agent, load_message(args), args.next_agent, False
            )
            print(f"Recorded turn {turn}: {path}")
            if receipt:
                print(f"VERIFIED-GIT: {receipt}")
            report_peer_doorbells(path, read_discussion(path), args.agent, stale_after)
            print(invitation(args.id, args.next_agent, subject, timed_watch_enabled(read_discussion(path))))
        elif args.command == "close":
            if args.print_template:
                if args.message is not None or args.message_file is not None or args.trivial:
                    raise Agent2AgentError("--print-template cannot be combined with a message or --trivial")
                print(CLOSE_TEMPLATE.rstrip())
                return 0
            if args.message is None and args.message_file is None:
                raise Agent2AgentError("close requires --message/--message-file or --print-template")
            message = load_message(args)
            if not args.trivial:
                validate_structured_close(message)
            receipt = verify_git_handoff(root) if args.check_clean else None
            path, turn, _, _ = append_turn(root, args.id, args.agent, message, None, True)
            print(f"Closed XYZ AgentChorus #{args.id} at turn {turn}")
            print(f"Relay file: {path}")
            if receipt:
                print(f"VERIFIED-GIT: {receipt}")
        elif args.command == "extend":
            receipt = verify_git_handoff(root) if args.check_clean else None
            message = render_scope_extension(
                load_named_text(args, "question"),
                load_named_text(args, "done_condition"),
            )
            path, turn, _, subject = append_turn(
                root, args.id, args.agent, message, args.next_agent, False, extension=True
            )
            print(f"Recorded scope extension {optional_field(read_discussion(path), 'EXTENSIONS', '0')} at turn {turn}: {path}")
            if receipt:
                print(f"VERIFIED-GIT: {receipt}")
            report_peer_doorbells(path, read_discussion(path), args.agent, stale_after)
            print(invitation(args.id, args.next_agent, subject, timed_watch_enabled(read_discussion(path))))
        elif args.command == "outcome":
            return command_outcome(args)
        elif args.command == "telemetry":
            return command_telemetry(args)
        elif args.command == "drive":
            if args.max_turns < 1:
                raise Agent2AgentError("--max-turns must be at least one")
            return drive_discussion(
                root, args.id, args.agent, args.interval, args.timeout,
                args.max_turns, args.turn_command,
            )
        else:
            raise Agent2AgentError(f"unsupported command: {args.command}")
    except KeyboardInterrupt:
        print("agent-chorus: interrupted", file=sys.stderr)
        return 130
    except Agent2AgentError as exc:
        print(f"agent-chorus: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
