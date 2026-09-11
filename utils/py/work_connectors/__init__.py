#!/usr/bin/env python3
"""GH-549: work-state connectors — registry, config, and bounded concurrent dispatch.

The contract, in one paragraph, because every word of it is load-bearing:

A ledger verb's added latency is BOUNDED and does not grow with the number of connectors.
Every enabled connector is launched before any is joined, and the whole set is collected
under ONE total deadline rather than a per-connector timeout, so two hung connectors cost
one window rather than two. A child that is still running at the deadline is terminated and
reaped. The host's exit code never changes. With no connectors configured the added latency
is exactly zero, because dispatch returns before spawning anything.

Two boundaries this module must never cross:

1. It runs AFTER perform_write has released its WriterLock. A governance writer must not hold
   the lock across network time. perform_write calls dispatch_for_txn() from one common
   post-lock section — one seam, not 29 call sites.
2. A child owns NO database handle. It receives its event batch as JSON on stdin and reports
   on stdout; this parent is the sole writer of connector_cursors, in one short transaction
   taken after the join.
"""

import errno
import fcntl
import json
import os
import sqlite3
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from device_config import resolve_device_block
except ImportError:  # pragma: no cover - path fallback for odd invocations
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))), "py"))
    from device_config import resolve_device_block

# One total window for ALL connectors, not per connector (Codex plan-QA r2).
CONNECTOR_WINDOW_S = float(os.environ.get("XYZ_CONNECTOR_WINDOW_S", "5"))

# How long a dispatch waits for the connector lock before giving up (impl QA r3). Bounded on
# purpose: a ledger verb must never wait on another process's network time. Giving up is safe —
# the batch simply stays unacknowledged and the next write or `work reconcile` replays it.
CONNECTOR_LOCK_WAIT_S = float(os.environ.get("XYZ_CONNECTOR_LOCK_WAIT_S", "2"))

CONNECTOR_DEFAULTS = {
    "enabled": False,
    "project_owner": "",
    "project_number": 0,
    "owner_type": "user",
    "repos": [],
    "status_field": "Status",
    # Event -> board column. Empty here so a user's partial override merges onto the
    # connector's own defaults rather than replacing them wholesale; see github_board.py.
    "status_map": {},
}

# The registry is a literal table of name -> module path. No entry points, no import-by-string
# from config: adding a connector is a pull request, not a runtime install (issue non-goal).
REGISTRY = {
    "github_board": "work_connectors.github_board",
}


def _warn(msg):
    print("work_connectors: %s" % msg, file=sys.stderr)


def load_connectors(warn=True):
    """Resolve the `work_connectors` block into {name: config} for ENABLED connectors only.

    An absent config returns {} silently — the unconfigured no-op that acceptance criterion 1
    pins. A malformed config warns and returns {}: it must never be mistaken for absent, and it
    must never raise into a ledger verb.
    """
    # The global kill switch, checked HERE rather than only at the hot-path call site, because
    # `work reconcile` calls dispatch() directly and would otherwise sail past it (impl QA r2).
    # This is the one function both paths go through.
    if os.environ.get("XYZ_WORK_CONNECTORS") == "0":
        if warn:
            _warn("XYZ_WORK_CONNECTORS=0 — connectors disabled, dispatching nothing")
        return {}
    try:
        cfg, error = resolve_device_block("work_connectors", {"enabled": False}, "XYZ_WORK_CONNECTORS")
    except Exception as exc:            # a config read must never break a ledger write
        if warn:
            _warn("config unreadable (%r) — no connectors" % (exc,))
        return {}
    if error and warn:
        _warn(error)
    from device_config import load_device_config_diagnostic
    loaded, _ = load_device_config_diagnostic()
    block = loaded.get("work_connectors", {})
    if not isinstance(block, dict):
        if warn:
            _warn("work_connectors is not an object — no connectors")
        return {}
    out = {}
    for name, raw in block.items():
        if name not in _registry():
            if warn:
                _warn("unknown connector %r — not in the vendored registry, ignoring" % name)
            continue
        if not isinstance(raw, dict):
            if warn:
                _warn("connector %r config is not an object — ignoring" % name)
            continue
        merged, err = resolve_device_block("work_connectors", CONNECTOR_DEFAULTS,
                                           "XYZ_WORK_CONNECTORS_%s" % name.upper())
        merged.update({k: v for k, v in raw.items() if k in CONNECTOR_DEFAULTS})
        if err and warn:
            _warn(err)
        if merged.get("enabled"):
            out[name] = merged
    return out


def cursor_for(conn, name):
    row = conn.execute("SELECT last_event_id FROM connector_cursors WHERE connector = ?",
                       (name,)).fetchone()
    return int(row[0]) if row else 0


def events_after(conn, last_id, limit=500):
    rows = conn.execute("""SELECT id, gh_number, event, payload, at FROM work_events
                           WHERE id > ? ORDER BY id LIMIT ?""", (last_id, limit)).fetchall()
    return [{"id": r[0], "gh_number": r[1], "event": r[2],
             "payload": json.loads(r[3]) if r[3] else None, "at": r[4]} for r in rows]


def _registry():
    """The vendored registry, plus an explicit test overlay.

    XYZ_WORK_CONNECTORS_REGISTRY is a JSON object of {name: "path/to/script.py"} and exists so a
    suite can inject stub connectors without shipping them. Same shape of seam as
    XYZ_BOARD_SYNC_GH_BIN, which board_sync already uses to point at the offline mock.

    Be precise about what contains it, because an earlier version of this docstring was not.
    The overlay is read from the ENVIRONMENT and from nowhere else. Device config cannot
    introduce one: load_connectors only consults names already in this registry, so a
    work_connectors block naming an overlay connector does nothing unless the environment
    already defined it. The environment is therefore the whole trust boundary — and anyone who
    can set XYZ_WORK_CONNECTORS_REGISTRY on the machine that runs the ledger can equally run
    python3 directly, so the overlay grants no capability they did not already hold. What it
    would otherwise cost is legibility, which is why an active overlay announces itself below:
    a production run must never use one silently.
    """
    reg = dict(REGISTRY)
    raw = os.environ.get("XYZ_WORK_CONNECTORS_REGISTRY")
    if raw:
        try:
            overlay = json.loads(raw)
            if isinstance(overlay, dict):
                names = sorted(k for k, v in overlay.items() if isinstance(v, str))
                reg.update({k: v for k, v in overlay.items() if isinstance(v, str)})
                if names:
                    _warn("XYZ_WORK_CONNECTORS_REGISTRY is active — running non-vendored "
                          "connector(s) %s from the environment" % ", ".join(names))
        except Exception as exc:
            _warn("registry overlay unreadable (%r) — ignoring" % (exc,))
    return reg


def _child_argv(name):
    target = _registry()[name]
    if target.endswith(".py") or os.path.sep in target:
        return [sys.executable, target]
    return [sys.executable, "-m", target]


def _launch(name, cfg, events):
    """Start one child. Never raises: a connector that cannot even be spawned is a connector
    that failed, not a ledger verb that failed."""
    payload = json.dumps({"connector": name, "config": cfg, "events": events})
    # A vendored connector is invoked as `python -m work_connectors.<name>`, which resolves the
    # package off the child's own sys.path, not ours. cwd is the repo root, so without this the
    # import fails and every ordinary configured run reports "No module named work_connectors" —
    # the exact failure impl QA r2 found. Prepend utils/py rather than replace, so an operator's
    # PYTHONPATH still works.
    pkg_parent = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    env = dict(os.environ)
    env["PYTHONPATH"] = os.pathsep.join([pkg_parent] + (
        [env["PYTHONPATH"]] if env.get("PYTHONPATH") else []))
    try:
        proc = subprocess.Popen(_child_argv(name), stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, env=env,
                                cwd=os.path.dirname(os.path.dirname(
                                    os.path.dirname(os.path.abspath(__file__)))))
    except Exception as exc:
        return (name, None, "spawn failed: %r" % (exc,))
    try:
        proc.stdin.write(payload)
        proc.stdin.close()
    except Exception as exc:
        return (name, proc, "stdin write failed: %r" % (exc,))
    return (name, proc, None)


def _collect(launched, deadline, bounds):
    """Join every child under ONE shared deadline. Returns {name: (advanced_to, error)}.

    `bounds` is {name: (prior_cursor, batch_max_id)} — the closed range a connector is allowed to
    report. A child's stdout is UNTRUSTED input, so its advanced_to is validated here, at the
    parse boundary, rather than in _persist: a value above batch_max would skip events the
    connector was never handed, and a value at or below prior_cursor would replay events it
    already acknowledged. Either one is a failed run, not an advance — the cursor stays put and
    `work reconcile` replays the batch.
    """
    results = {}
    for name, proc, err in launched:
        if proc is None:
            results[name] = (None, err)
            continue
        remaining = max(0.0, deadline - time.monotonic())
        try:
            out, errout = proc.communicate(timeout=remaining)
        except subprocess.TimeoutExpired:
            proc.kill()
            try:
                proc.communicate(timeout=5)     # reap, so no zombie is left behind
            except Exception:
                pass
            results[name] = (None, "timed out after the %.1fs window" % CONNECTOR_WINDOW_S)
            continue
        except Exception as exc:
            results[name] = (None, "communicate failed: %r" % (exc,))
            continue
        if err:
            results[name] = (None, err)
            continue
        if proc.returncode != 0:
            results[name] = (None, "exit %s: %s" % (proc.returncode, (errout or "").strip()[:200]))
            continue
        advanced = None
        for line in (out or "").splitlines():
            if line.startswith("advanced_to:"):
                try:
                    advanced = int(line.split(":", 1)[1].strip())
                except ValueError:
                    advanced = None
        if advanced is None:
            results[name] = (None, "exited 0 without an advanced_to line")
            continue
        prior, batch_max = bounds.get(name, (0, None))
        if batch_max is None:
            results[name] = (None, "reported advanced_to=%d but no batch was dispatched" % advanced)
        elif advanced > batch_max:
            results[name] = (None, "advanced_to=%d overshoots the dispatched batch (max event id "
                                   "%d) — refusing to skip events the connector never saw"
                                   % (advanced, batch_max))
        elif advanced <= prior:
            results[name] = (None, "advanced_to=%d does not move the cursor forward from %d"
                                   % (advanced, prior))
        else:
            results[name] = (advanced, None)
    return results


def _persist(db_path, results, at):
    """One short transaction on a SEPARATE connection, taken AFTER the join. The parent is the
    only writer of connector_cursors; no child ever holds a database handle."""
    conn = sqlite3.connect(db_path, timeout=30)
    try:
        conn.execute("BEGIN IMMEDIATE")
        for name, (advanced, error) in sorted(results.items()):
            if advanced is not None:
                conn.execute("""INSERT INTO connector_cursors(connector, last_event_id,
                                last_attempt_at, last_error, updated_at)
                                VALUES (?, ?, ?, NULL, ?)
                                ON CONFLICT(connector) DO UPDATE SET
                                  -- Monotonic on purpose (impl QA r3). The connector lock makes
                                  -- an out-of-order write unreachable in normal operation; this
                                  -- is the second line of defence, so a cursor can never go
                                  -- backwards and re-deliver events already acknowledged.
                                  last_event_id = MAX(connector_cursors.last_event_id,
                                                      excluded.last_event_id),
                                  last_attempt_at = excluded.last_attempt_at,
                                  last_error = NULL,
                                  updated_at = excluded.updated_at""",
                             (name, advanced, at, at))
            else:
                # A failed connector does NOT advance. Its cursor stays put so `work reconcile`
                # replays exactly what it missed.
                conn.execute("""INSERT INTO connector_cursors(connector, last_event_id,
                                last_attempt_at, last_error, updated_at)
                                VALUES (?, 0, ?, ?, ?)
                                ON CONFLICT(connector) DO UPDATE SET
                                  last_attempt_at = excluded.last_attempt_at,
                                  last_error = excluded.last_error,
                                  updated_at = excluded.updated_at""",
                             (name, at, str(error)[:500], at))
        conn.commit()
    finally:
        conn.close()


class _ConnectorLock:
    """Cross-process mutual exclusion for the read-cursor / project / write-cursor section.

    perform_write releases the ledger's WriterLock BEFORE dispatching, deliberately — a
    governance writer must not hold it across network time. The consequence impl QA r3 found is
    that two ledger writes can dispatch overlapping batches concurrently: dispatch A reads
    cursor 0 and takes event 1, dispatch B reads cursor 0 and takes events 1 and 2, and whichever
    finishes last decides the board. If A finishes last, the card is set back to event 1's column
    and the cursor regresses to 1 — a projection stuck at a stale state, with nothing to repair it
    until the next event happens to arrive.

    A connector-only lock fixes the ordering without ever re-entangling the ledger lock. It is
    held across a whole dispatch, so B reads the cursor A already advanced and applies only what
    is genuinely new.

    Waiting is bounded (CONNECTOR_LOCK_WAIT_S) and failing to acquire is not an error: the batch
    stays unacknowledged, and the next write or `work reconcile` replays it. A ledger verb must
    never block on another process's connectors.

    **It fails CLOSED.** An earlier version returned success when the lock file could not be
    opened or flocked, on the reasoning that a lock we cannot create should not disable
    connectors. Impl QA r4 graded that High and was right: it silently re-enables the very race
    this class exists to close, and it does so on exactly the paths nobody exercises — an
    interrupted call, a filesystem where the database is usable but locking is not. The cost of
    failing closed is a deferred board update, which the next write or reconcile repairs; the
    cost of failing open is a board published at an older state with only a stderr warning. Those
    are not comparable, so every failure to hold the lock is treated as contention.
    """

    def __init__(self, db_path):
        self.path = db_path + "-connectors.lock"
        self.fh = None

    def acquire(self, wait_s=None):
        wait = CONNECTOR_LOCK_WAIT_S if wait_s is None else wait_s
        deadline = time.monotonic() + wait
        try:
            self.fh = open(self.path, "a+")
        except Exception as exc:
            _warn("cannot open the connector lock (%r) — deferring this batch" % (exc,))
            return False
        while True:
            try:
                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                return True
            except OSError as exc:
                if exc.errno == errno.EINTR:
                    continue            # a signal is not a lock failure; retry within the window
                if exc.errno not in (errno.EAGAIN, errno.EACCES, errno.EWOULDBLOCK):
                    _warn("connector lock unavailable (%r) — deferring this batch" % (exc,))
                    self.release()
                    return False
                if time.monotonic() >= deadline:
                    self.release()
                    return False
                time.sleep(0.05)
            except Exception as exc:    # a platform whose flock raises something else entirely
                _warn("connector lock unusable (%r) — deferring this batch" % (exc,))
                self.release()
                return False

    def release(self):
        if self.fh is None:
            return
        try:
            fcntl.flock(self.fh.fileno(), fcntl.LOCK_UN)
        except Exception:
            pass
        try:
            self.fh.close()
        except Exception:
            pass
        self.fh = None


def dispatch(db_path, at, connectors=None, window_s=None, reset=False):
    """Launch every enabled connector concurrently, join under one window, persist cursors.

    Returns {name: (advanced_to, error)}. Never raises, and never changes a host exit code:
    perform_write wraps the call, and this function additionally swallows its own failures.
    """
    conns = load_connectors() if connectors is None else connectors
    if not conns:
        return {}                       # zero connectors == zero added latency
    if not os.path.exists(db_path):
        return {}
    lock = _ConnectorLock(db_path)
    if not lock.acquire():
        _warn("another dispatch holds the connector lock — leaving this batch for the next run")
        return {}
    try:
        return _dispatch_locked(db_path, at, conns, window_s, reset)
    finally:
        lock.release()


def _reset_cursors(db_path, names):
    """Drop these connectors' cursors. Called INSIDE the lock (impl QA r4).

    `work reconcile --reset` used to delete the rows before dispatch took the lock, so an
    in-flight dispatch could re-persist its advance afterwards and the reset would find nothing
    to replay. Deleting inside the same critical section makes "replay from zero" mean it.
    """
    conn = sqlite3.connect(db_path, timeout=30)
    try:
        conn.execute("BEGIN IMMEDIATE")
        for name in names:
            conn.execute("DELETE FROM connector_cursors WHERE connector = ?", (name,))
        conn.commit()
    finally:
        conn.close()


def _dispatch_locked(db_path, at, conns, window_s, reset=False):
    """The read-cursor / project / write-cursor section, run under _ConnectorLock."""
    if reset:
        _reset_cursors(db_path, list(conns))
    read = sqlite3.connect(db_path, timeout=30)
    try:
        batches, bounds = {}, {}
        for name, cfg in conns.items():
            last = cursor_for(read, name)
            evs = events_after(read, last)
            if evs:
                batches[name] = (cfg, evs)
                # The closed range this connector is allowed to report back. Captured here,
                # from the rows we actually handed it — never re-derived from the child.
                bounds[name] = (last, evs[-1]["id"])
    finally:
        read.close()
    if not batches:
        return {}
    launched = [_launch(name, cfg, evs) for name, (cfg, evs) in sorted(batches.items())]
    deadline = time.monotonic() + (CONNECTOR_WINDOW_S if window_s is None else window_s)
    results = _collect(launched, deadline, bounds)
    try:
        _persist(db_path, results, at)
    except Exception as exc:
        _warn("cursor persistence failed (%r)" % (exc,))
    return results
