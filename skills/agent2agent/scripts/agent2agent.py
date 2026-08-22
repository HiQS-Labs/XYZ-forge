#!/usr/bin/env python3
"""Create and advance serialized XYZ agent2agent discussions."""

from __future__ import annotations

import argparse
import datetime as dt
import fcntl
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
from typing import Callable, Iterable, List, Optional, Tuple


ID_RE = re.compile(r"^[0-9]{6}$")
FIELD_RE_TEMPLATE = r"^{key}:[ \t]*(.*?)[ \t]*$"
DISCUSSION_MARKER = "\n## Discussion\n"
MAX_ID_ATTEMPTS = 1_000
DEFAULT_POLL_INTERVAL = 150.0
DEFAULT_DRIVE_TIMEOUT = 3_600.0
DEFAULT_MAX_DRIVE_TURNS = 6


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


def invitation(discussion_id: str, number: int, subject: str, timed_watch: bool = False) -> str:
    text = (
        f"Join XYZ agent2agent #{discussion_id} as agent number {number_word(number)} "
        f"to discuss: {quoted_subject(subject)}"
    )
    if timed_watch:
        text += (
            "\n\nTimed two-minute doorbell requested: when waiting, start a background "
            "watch that checks every 120 seconds for 1,800 seconds."
        )
    return text


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


def render_initial(
    discussion_id: str, subject: str, agents: int, timestamp: str, timed_watch: bool
) -> str:
    roster = " ".join(agent_id(number) for number in range(1, agents + 1))
    return f"""# XYZ agent2agent #{discussion_id}

AGENT2AGENT-ID: {discussion_id}
SUBJECT: {subject}
AGENTS: {roster}
NEXT: agent2
STATUS: Open
TURN: 1
TIMED-WATCH: {"enabled" if timed_watch else "disabled"}
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
        _fsync_dir(path.parent)
    finally:
        temp_path.unlink(missing_ok=True)


def create_discussion(
    root: Path, subject: str, agents: int, explicit_id: Optional[str], timed_watch: bool
) -> Tuple[str, Path]:
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
            handle.write(render_initial(discussion_id, normalized, agents, timestamp, timed_watch))
            handle.flush()
            os.fsync(handle.fileno())
    except FileExistsError as exc:
        raise Agent2AgentError(f"discussion path already exists: {path}") from exc
    finally:
        reservation.unlink(missing_ok=True)
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
        # Dotfile, matching DriveLock's convention — the lock sits beside the discussion but never
        # appears in a listing of it, and `find_discussions` only globs `*.md`.
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
        "watch",
        "--id", discussion_id,
        "--agent", str(number),
        "--interval", f"{interval:g}",
        "--timeout", f"{timeout:g}",
    ]
    return " ".join(shlex.quote(part) for part in argv)


def watch_sidecar(path: Path, number: int) -> Path:
    """Per-agent doorbell-liveness marker (GH-38 item 6). Deliberately a SIDECAR, not a field in
    the relay file: `watch` must leave the discussion byte-identical (the suite pins this), and
    lock/liveness evidence does not belong inside the artifact it describes — the same reasoning
    as GH-32's r4 lock-audit finding."""
    return path.with_name(f"{path.name}.watch.{agent_id(number)}")


def touch_watch_sidecar(path: Path, number: int) -> None:
    marker = watch_sidecar(path, number)
    try:
        marker.write_text(f"pid={os.getpid()} armed={utc_now()}\n", encoding="utf-8")
    except OSError:
        pass   # liveness reporting is a nicety; it must never break a watch


def doorbell_state(path: Path, number: int, interval: float) -> Optional[str]:
    """Describe a seat's observed doorbell state, or None when it may be participating manually."""
    marker = watch_sidecar(path, number)
    try:
        age = time.time() - marker.stat().st_mtime
    except OSError:
        return None
    stale = age > max(interval, 1.0) * 2
    suffix = " — STALE, that seat may no longer be listening" if stale else ""
    return f"armed {age:.0f}s ago{suffix}"


def peer_doorbell_report(path: Path, number: int, interval: float) -> Optional[str]:
    """One advisory peer line, or None when no doorbell has been observed for that seat."""
    state = doorbell_state(path, number, interval)
    return None if state is None else f"peer doorbell ({agent_id(number)}): {state}"


def report_peer_doorbells(path: Path, content: str, self_number: int) -> None:
    """Print one advisory line per OTHER roster seat that has ever armed a doorbell. Silence about
    a seat means it never armed one — which is normal for a manual participant, so this reports and
    never refuses."""
    for index, _ in enumerate(parse_roster(content), start=1):
        if index == self_number:
            continue
        line = peer_doorbell_report(path, index, DEFAULT_POLL_INTERVAL)
        if line:
            print(line)


def report_discussion_status(root: Path, discussion_id: str) -> None:
    """Print a seat-agnostic overview without changing the discussion or its sidecars."""
    path = resolve_discussion(root, discussion_id)
    content = read_discussion(path)
    roster = parse_roster(content)
    print(f"XYZ agent2agent #{discussion_id}")
    print(f"Relay file: {path}")
    print(f"Subject: {field(content, 'SUBJECT')}")
    print(f"STATUS: {field(content, 'STATUS')}")
    print(f"TURN: {field(content, 'TURN')}")
    print(f"NEXT: {field(content, 'NEXT')}")
    print(f"AGENTS: {' '.join(roster)}")
    print(f"TIMED-WATCH: {'enabled' if timed_watch_enabled(content) else 'disabled'}")
    for number, member in enumerate(roster, start=1):
        state = doorbell_state(path, number, DEFAULT_POLL_INTERVAL)
        print(f"DOORBELL {member}: {state or 'not observed/manual'}")


def watch_discussion(
    root: Path, discussion_id: str, number: int, interval: float, timeout: float
) -> int:
    path = resolve_discussion(root, discussion_id)
    print(f"Watching XYZ agent2agent #{discussion_id} as {agent_id(number)}")
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
    return f"""Join XYZ agent2agent #{discussion_id} as agent number {number_word(number)} to discuss: {quoted_subject(subject)}

It is now your turn. Read the complete discussion at:
{path}

Respond to the discussion, then use the agent2agent helper's send or close command. Do not edit the
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
        print(f"Driving XYZ agent2agent #{discussion_id} as {member}")
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
    start.add_argument(
        "--timed-watch", action="store_true",
        help="include a 2-minute / 30-minute background-watch request in every invitation",
    )
    start.add_argument("--id", dest="explicit_id", help=argparse.SUPPRESS)

    status = commands.add_parser("status", help="inspect a discussion without taking a participant seat")
    status.add_argument("--id", required=True)

    join = commands.add_parser("join", help="resolve an invitation without modifying the discussion")
    join.add_argument("--id", required=True)
    join.add_argument("--agent", type=int, required=True, help="plain agent number, such as 2")
    join.add_argument("--expect-subject", help="reject a stale or altered invitation subject")

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
    send_message = send.add_mutually_exclusive_group(required=True)
    send_message.add_argument("--message")
    send_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")

    close = commands.add_parser("close", help="append the caller's final turn and close the discussion")
    close.add_argument("--id", required=True)
    close.add_argument("--agent", type=int, required=True)
    close_message = close.add_mutually_exclusive_group(required=True)
    close_message.add_argument("--message")
    close_message.add_argument("--message-file", help="UTF-8 file, or - for stdin")

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
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        root = normalize_root(args.root)
        if args.command == "start":
            discussion_id, path = create_discussion(
                root, args.subject, args.agents, args.explicit_id, args.timed_watch
            )
            subject = normalize_subject(args.subject)
            print(f"Created XYZ agent2agent #{discussion_id}")
            print(f"Relay file: {path}")
            for number in range(2, args.agents + 1):
                print(invitation(discussion_id, number, subject, args.timed_watch))
        elif args.command == "status":
            report_discussion_status(root, args.id)
        elif args.command == "join":
            path, subject, next_member, decision = join_discussion(
                root, args.id, args.agent, args.expect_subject
            )
            print(f"XYZ agent2agent #{args.id}")
            print(f"Relay file: {path}")
            print(f"Subject: {subject}")
            print(f"You are: {agent_id(args.agent)}")
            print(f"NEXT: {next_member}")
            if timed_watch_enabled(read_discussion(path)):
                print("TIMED-WATCH: check every 120 seconds for 1,800 seconds while waiting")
            report_peer_doorbells(path, read_discussion(path), args.agent)
            print(f"DECISION: {decision}")
        elif args.command == "watch":
            return watch_discussion(root, args.id, args.agent, args.interval, args.timeout)
        elif args.command == "send":
            path, turn, next_member, subject = append_turn(
                root, args.id, args.agent, load_message(args), args.next_agent, False
            )
            print(f"Recorded turn {turn}: {path}")
            report_peer_doorbells(path, read_discussion(path), args.agent)
            print(invitation(args.id, args.next_agent, subject, timed_watch_enabled(read_discussion(path))))
        elif args.command == "close":
            path, turn, _, _ = append_turn(root, args.id, args.agent, load_message(args), None, True)
            print(f"Closed XYZ agent2agent #{args.id} at turn {turn}")
            print(f"Relay file: {path}")
        else:
            if args.max_turns < 1:
                raise Agent2AgentError("--max-turns must be at least one")
            return drive_discussion(
                root, args.id, args.agent, args.interval, args.timeout,
                args.max_turns, args.turn_command,
            )
    except KeyboardInterrupt:
        print("agent2agent: interrupted", file=sys.stderr)
        return 130
    except Agent2AgentError as exc:
        print(f"agent2agent: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
