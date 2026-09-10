#!/usr/bin/env python3
"""GH-549: the GitHub Projects connector — the vendored `github_board` entry in REGISTRY.

This is the thin adapter the plan's step 4.1 called for, and nothing more. It owns no write
protocol of its own: every board mutation goes through `board_sync.py`'s existing
resolve / add / set-status functions, which already carry the stale-ID self-heal, the
repo-qualified idempotence check and the board-identity refusal.

The contract with the parent (`work_connectors/__init__.py`) is deliberately narrow, because
the parent treats everything here as untrusted:

  stdin   {"connector": name, "config": {...}, "events": [{"id","gh_number","event",
                                                           "payload","at"}, ...]}
  stdout  advanced_to: <the id of the last event this connector actually applied>
  exit    0 = the batch was applied · non-zero = it was not, and the cursor stays put

**We hold no database handle.** The parent is the sole writer of `connector_cursors`, so the
only thing we can influence is that one integer — and the parent validates it against the batch
it handed us, so we cannot skip events by reporting past the end.

**Why `advanced_to` is the last APPLIED id, not simply the last id in the batch.** If event 7
fails, reporting 9 would bury 7 forever. We report 6, exit non-zero, and `work reconcile`
hands 7 back on the next run. Applying is set-to-value, never an increment, so replaying an
event that already landed is a no-op rather than a double-apply.

## The column mapping is configuration, not code

Issue #549 is explicit that the target board and its columns are user settings. The core's
event vocabulary is the ledger's own (`parked`, `rated`, `in_flight`, `pr_merged`, ...) and it
never inherits GitHub's column model; this module is the one place the two meet, through
`status_map`, which any user can override per column:

    "work_connectors": {
      "github_board": {
        "enabled": true,
        "project_owner": "your-org", "project_number": 3, "repos": ["your-org/your-repo"],
        "status_field": "Status",
        "status_map": {"parked": "Backlog", "in_flight": "In progress",
                       "review_ready": "In review", "pr_merged": "Done"}
      }
    }

An event with no mapping is SKIPPED, not an error: a board that has no column for `rated` is a
legitimate board, and the ledger must not start failing because of one. A mapped column that
does not exist on the board IS an error — that is a misconfiguration the user wants told about,
not a silent no-op.
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import board_sync

# The default vocabulary → column mapping. These are COLUMN NAMES, which are presentation and
# carry a sane default, unlike project_owner / project_number / repos, which name somebody's
# actual board and therefore have none (GH-549: a default there wrote to a stranger's board).
# An empty string means "deliberately unmapped" and is how a user turns one transition off.
DEFAULT_STATUS_MAP = {
    "parked": "Todo",
    "rated": "Todo",
    "in_flight": "In progress",
    "jog_running": "In progress",
    "jog_leased": "In progress",
    "review_ready": "In review",
    "pr_merged": "Done",
}


def column_for(event, status_map):
    """The board column this event maps to, or None when it is deliberately unmapped."""
    column = status_map.get(event)
    return column or None


def apply_event(cfg, ev, status_map, snapshot):
    """Apply one event. Returns (applied: bool, message: str)."""
    num = ev.get("gh_number")
    if not num:
        return (True, "event %s (%s): no issue number — nothing to place on a board"
                % (ev.get("id"), ev.get("event")))
    column = column_for(ev.get("event"), status_map)
    if column is None:
        return (True, "event %s (%s): unmapped in status_map — skipped"
                % (ev.get("id"), ev.get("event")))
    msg = board_sync.set_issue_status(cfg, int(num), column, write=True, snapshot=snapshot)
    return (True, "event %s (%s): %s" % (ev.get("id"), ev.get("event"), msg))


def run(batch):
    cfg = dict(batch.get("config") or {})
    events = batch.get("events") or []

    # board_sync's own settings supply anything the connector block does not name, so a user who
    # already configured board_sync does not have to restate the board twice.
    base = board_sync.resolve_settings()
    for key, value in base.items():
        if not cfg.get(key):
            cfg[key] = value

    raw_map = cfg.get("status_map")
    status_map = dict(DEFAULT_STATUS_MAP)
    if isinstance(raw_map, dict):
        status_map.update({k: v for k, v in raw_map.items() if isinstance(v, str)})
    elif raw_map is not None:
        print("github_board: status_map is not an object — using the defaults", file=sys.stderr)

    # Refuse before the first network call when the board identity is not configured. This is
    # the same guard board_sync's own verbs take, and it is why an unconfigured harness cannot
    # write to anyone's board even with the connector enabled by mistake.
    board_sync.require_board_identity(cfg)

    # One pagination for the whole batch, not one per event. board_add/set_issue_status accept
    # the snapshot for exactly this reason.
    snapshot = board_sync.fetch_board_issues(cfg)

    advanced = None
    for ev in sorted(events, key=lambda e: e["id"]):
        try:
            applied, msg = apply_event(cfg, ev, status_map, snapshot)
        except Exception as exc:                       # noqa: BLE001 — see below
            # Stop at the first failure and report the last id that DID land. Continuing would
            # either bury this event (if we reported past it) or replay everything after it on
            # every subsequent run (if we reported before it).
            print("github_board: event %s failed (%r) — stopping; the cursor keeps %s"
                  % (ev.get("id"), exc, advanced), file=sys.stderr)
            if advanced is not None:
                print("advanced_to: %d" % advanced)
            return 1
        print("github_board: %s" % msg, file=sys.stderr)
        if applied:
            advanced = ev["id"]

    if advanced is None:
        # Nothing was applied and nothing failed — an empty batch. Reporting no advance is
        # correct; the parent treats a missing advanced_to as a failed run and leaves the
        # cursor alone, which is what we want when there was nothing to acknowledge.
        return 0
    print("advanced_to: %d" % advanced)
    return 0


def main():
    try:
        batch = json.load(sys.stdin)
    except Exception as exc:                           # noqa: BLE001
        print("github_board: unreadable batch on stdin (%r)" % (exc,), file=sys.stderr)
        return 2
    try:
        return run(batch)
    except SystemExit as exc:                          # board_sync._die refuses with exit 2
        return exc.code if isinstance(exc.code, int) else 2
    except Exception as exc:                           # noqa: BLE001
        print("github_board: %r" % (exc,), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
