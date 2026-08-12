#!/usr/bin/env python3
"""Create and advance serialized XYZ agent2agent discussions."""

from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path
import re
import secrets
import sys
import tempfile
from typing import Iterable, List, Optional, Tuple


ID_RE = re.compile(r"^[0-9]{6}$")
FIELD_RE_TEMPLATE = r"^{key}:[ \t]*(.*?)[ \t]*$"
DISCUSSION_MARKER = "\n## Discussion\n"
MAX_ID_ATTEMPTS = 1_000


class Agent2AgentError(RuntimeError):
    """A user-facing agent2agent failure."""


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


def invitation(discussion_id: str, number: int, subject: str) -> str:
    return (
        f"Join XYZ agent2agent #{discussion_id} as agent number {number_word(number)} "
        f"to discuss: {quoted_subject(subject)}"
    )


def relay_root(root: Path) -> Path:
    return root / "relay-system"


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


def find_discussions(root: Path, discussion_id: str) -> List[Path]:
    if not ID_RE.fullmatch(discussion_id):
        raise Agent2AgentError("discussion ID must be exactly six digits")
    base = relay_root(root)
    if not base.is_dir():
        return []
    matches: List[Path] = []
    for candidate in base.glob(f"**/{discussion_id}-*.md"):
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


def resolve_discussion(root: Path, discussion_id: str) -> Path:
    matches = find_discussions(root, discussion_id)
    if not matches:
        raise Agent2AgentError(f"agent2agent #{discussion_id} was not found under {relay_root(root)}")
    if len(matches) > 1:
        rendered = "\n  ".join(str(path) for path in matches)
        raise Agent2AgentError(f"agent2agent #{discussion_id} is ambiguous:\n  {rendered}")
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


def reserve_id(root: Path, explicit_id: Optional[str]) -> Tuple[str, Path]:
    base = relay_root(root)
    base.mkdir(parents=True, exist_ok=True)
    for candidate in id_candidates(explicit_id):
        reservation = base / f".agent2agent-id-{candidate}.lock"
        try:
            descriptor = os.open(reservation, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            if explicit_id:
                raise Agent2AgentError(f"agent2agent #{candidate} is currently being created")
            continue
        try:
            os.write(descriptor, f"pid={os.getpid()} created={utc_now()}\n".encode())
        finally:
            os.close(descriptor)
        if find_discussions(root, candidate):
            reservation.unlink(missing_ok=True)
            if explicit_id:
                raise Agent2AgentError(f"agent2agent #{candidate} already exists")
            continue
        return candidate, reservation
    raise Agent2AgentError("could not allocate an unused six-digit discussion ID")


def render_initial(discussion_id: str, subject: str, agents: int, timestamp: str) -> str:
    roster = " ".join(agent_id(number) for number in range(1, agents + 1))
    return f"""# XYZ agent2agent #{discussion_id}

AGENT2AGENT-ID: {discussion_id}
SUBJECT: {subject}
AGENTS: {roster}
NEXT: agent2
STATUS: Open
TURN: 1
CREATED: {timestamp}
UPDATED: {timestamp}

## Protocol

- Only the participant named by `NEXT:` may append the next turn.
- After writing, route `NEXT:` to exactly one other participant in `AGENTS:`.
- Keep turns serialized. Do not broadcast or write in parallel.
- `STATUS: Closed` is terminal.

## Discussion

### Turn 1 — agent1 — {timestamp}

{subject}
"""


def atomic_write(path: Path, content: str) -> None:
    mode = path.stat().st_mode & 0o777
    descriptor, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        os.fchmod(descriptor, mode)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)


def create_discussion(root: Path, subject: str, agents: int, explicit_id: Optional[str]) -> Tuple[str, Path]:
    if agents < 2:
        raise Agent2AgentError("--agents must be at least 2")
    normalized = normalize_subject(subject)
    discussion_id, reservation = reserve_id(root, explicit_id)
    timestamp = utc_now()
    dated = relay_root(root) / timestamp[:10]
    dated.mkdir(parents=True, exist_ok=True)
    path = dated / f"{discussion_id}-agent2agent-{slugify(normalized)}.md"
    try:
        descriptor = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(render_initial(discussion_id, normalized, agents, timestamp))
            handle.flush()
            os.fsync(handle.fileno())
    except FileExistsError as exc:
        raise Agent2AgentError(f"discussion path already exists: {path}") from exc
    finally:
        reservation.unlink(missing_ok=True)
    return discussion_id, path


class DiscussionLock:
    def __init__(self, path: Path):
        self.path = path.with_name(path.name + ".lock")

    def __enter__(self) -> None:
        try:
            descriptor = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError as exc:
            raise Agent2AgentError(f"discussion is locked by another writer: {self.path}") from exc
        try:
            os.write(descriptor, f"pid={os.getpid()} created={utc_now()}\n".encode())
        finally:
            os.close(descriptor)

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
        self.path.unlink(missing_ok=True)


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


def append_turn(
    root: Path,
    discussion_id: str,
    number: int,
    message: str,
    next_number: Optional[int],
    close: bool,
) -> Tuple[Path, int, str, str]:
    path = resolve_discussion(root, discussion_id)
    with DiscussionLock(path):
        content = read_discussion(path)
        member = validate_member(content, number)
        roster = parse_roster(content)
        status = field(content, "STATUS")
        if status.lower() == "closed":
            raise Agent2AgentError(f"agent2agent #{discussion_id} is closed")
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
        updated = updated.rstrip() + f"\n\n### Turn {turn} — {member} — {timestamp}\n\n{message}\n"
        atomic_write(path, updated)
    return path, turn, next_member, field(updated, "SUBJECT")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="agent2agent",
        description="Create or advance a serialized XYZ discussion shared by two or more agent sessions.",
    )
    parser.add_argument("--root", help="XYZ harness root; defaults to AGENT2AGENT_ROOT or this skill's repository")
    commands = parser.add_subparsers(dest="command", required=True)

    start = commands.add_parser("start", help="create a discussion and seed turn 1 from agent1")
    start.add_argument("--subject", required=True)
    start.add_argument("--agents", type=int, default=2, help="participant count (default: 2)")
    start.add_argument("--id", dest="explicit_id", help=argparse.SUPPRESS)

    join = commands.add_parser("join", help="resolve an invitation without modifying the discussion")
    join.add_argument("--id", required=True)
    join.add_argument("--agent", type=int, required=True, help="plain agent number, such as 2")
    join.add_argument("--expect-subject", help="reject a stale or altered invitation subject")

    send = commands.add_parser("send", help="append the caller's turn and route to another participant")
    send.add_argument("--id", required=True)
    send.add_argument("--agent", type=int, required=True)
    send.add_argument("--next-agent", type=int, required=True)
    send_message = send.add_mutually_exclusive_group(required=True)
    send_message.add_argument("--message")
    send_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")

    close = commands.add_parser("close", help="append the caller's final turn and close the discussion")
    close.add_argument("--id", required=True)
    close.add_argument("--agent", type=int, required=True)
    close_message = close.add_mutually_exclusive_group(required=True)
    close_message.add_argument("--message")
    close_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        root = normalize_root(args.root)
        if args.command == "start":
            discussion_id, path = create_discussion(root, args.subject, args.agents, args.explicit_id)
            subject = normalize_subject(args.subject)
            print(f"Created XYZ agent2agent #{discussion_id}")
            print(f"Relay file: {path}")
            print(invitation(discussion_id, 2, subject))
        elif args.command == "join":
            path, subject, next_member, decision = join_discussion(
                root, args.id, args.agent, args.expect_subject
            )
            print(f"XYZ agent2agent #{args.id}")
            print(f"Relay file: {path}")
            print(f"Subject: {subject}")
            print(f"You are: {agent_id(args.agent)}")
            print(f"NEXT: {next_member}")
            print(f"DECISION: {decision}")
        elif args.command == "send":
            path, turn, next_member, subject = append_turn(
                root, args.id, args.agent, load_message(args), args.next_agent, False
            )
            print(f"Recorded turn {turn}: {path}")
            print(invitation(args.id, args.next_agent, subject))
        else:
            path, turn, _, _ = append_turn(root, args.id, args.agent, load_message(args), None, True)
            print(f"Closed XYZ agent2agent #{args.id} at turn {turn}")
            print(f"Relay file: {path}")
    except Agent2AgentError as exc:
        print(f"agent2agent: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
