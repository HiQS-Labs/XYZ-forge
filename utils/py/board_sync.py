#!/usr/bin/env python3
"""board_sync.py (GH-402) — Projects-board mirror for work-start detection.

One command, thin adapters (plan of record: issue #402 body, revision v5):

    board_sync.py scan                     extract candidate gh-<n> + strength (offline)
    board_sync.py reconcile [--dedupe]     scan ∎ diff vs board ∎ add missing strong candidates
    board_sync.py touch gh-<n>             explicit add + Status="In progress" (idempotent)
    board_sync.py config                   print resolved settings (no secrets)

Design invariants (each named by the plan's QA, relay 2026-09-02):

- Entry ≠ start: only STRONG signals write to the board. Weak signals (clone folder,
  stale 🚧 marker) log for corroboration and never write alone (S2).
- Empty input fails: a scan that extracts nothing from a populated fixture is a hard
  error, never a green (AGENTS.md "an empty input passes every check").
- --dry-run is the DEFAULT for every mutation; adapters pass --write explicitly.
- XYZ_BOARD_SYNC=0 is the global kill-switch: every entry point no-ops (N1).
- Option/field IDs are resolved by NAME at runtime and re-resolved on failure (S5) —
  never hardcoded into state that outlives a board edit.
- Board state is a cached PROJECTION (PDDA + RELEASES DB stay authoritative); network
  failure warns and degrades, never blocks a host operation (B1 is the adapters'
  contract; this tool exits nonzero on write failure so suites can pin it — adapters
  background+timeout and ignore rc).
- Diagnostics never print tokens or Authorization headers (N4). v1 auth is `gh api
  graphql` (Phase 0 spike 2026-09-02: the gh token CAN mutate the user project);
  `token_file` is a reserved setting for a PAT fallback.
"""

import argparse
import datetime as dt
import errno
import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys
import tempfile
import time
from pathlib import Path

XYZ_ROOT = Path(__file__).resolve().parent.parent.parent
try:
    from device_config import get_device_config_path, load_local_device_config, resolve_device_block
except ImportError:  # direct execution outside utils/py
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from device_config import get_device_config_path, load_local_device_config, resolve_device_block

# --root default: the CONSUMER repo, not the harness copy this file lives in. In a
# vendored install XYZ_ROOT is <consumer>/.xyz — scanning there reads the harness's own
# state (the two-roots disagreement #403 fixed). Prefer #403's shared resolver when the
# branch carries it; fall back to XYZ_ROOT where it does not (review r2 #3).
try:
    from harness_paths import repo_root as _consumer_repo_root
    DEFAULT_SCAN_ROOT = str(_consumer_repo_root())
except Exception:  # ImportError, or repo_root's own resolution failing pre-merge
    DEFAULT_SCAN_ROOT = str(XYZ_ROOT)

STATE_PATH = Path(
    os.environ.get("XYZ_BOARD_SYNC_STATE_PATH", "~/.xyz/board_sync_state.json")
).expanduser()

# GH-549: project_owner, project_number and repos carry NO default. They used to ship one
# person's board as a zero-config default, so any other user of this harness wrote to that
# board. They are now required configuration: unconfigured, board_sync refuses before it makes
# a single network call. The empty string / 0 / [] are sentinels for "not configured", chosen
# so resolve_device_block still knows each value's type for env coercion.
DEFAULTS = {
    "project_owner": "",
    "project_number": 0,
    "status_field": "Status",
    "in_progress": "In progress",
    "repos": [],
    "clone_dirs": ["~/Documents/GH Repos"],
    "mention_policy": "strong-signals-write",
    "adapters": ["pdda", "git-hooks", "harness-fires", "sweeper"],  # consumed in Phase 2
    "token_file": "~/secrets/gh/board-sync.txt",  # reserved (PAT fallback); v1 uses gh
}

POLICY_DEFAULTS = {
    "project_owner": "", "project_number": 0, "repo": "", "repos": [],
    "ready_top_n": 10, "done_lookback_days": 7, "activity_lookback_days": 3,
    "status_field": "Status", "ready": "Ready", "in_progress": "In progress",
    "in_review": "In review", "done": "Done", "backlog": "Backlog",
    "implementation_status": "pending",
}

STRONG_SOURCES = ("pdda_doc", "branch", "tick_event", "jog_running")
WEAK_SOURCES = ("clone_dir", "stale_marker")

_GH_N = re.compile(r"[Gg][Hh][-_]?(\d{1,6})")


def _die(msg, code=2):
    print(f"board_sync: {msg}", file=sys.stderr)
    sys.exit(code)


def _warn(msg):
    print(f"board_sync: {msg}", file=sys.stderr)


def resolve_settings():
    """3-tier resolution per GH-174: XYZ_BOARD_SYNC_<KEY> env > device_config board_sync
    object > feature defaults.

    GH-549: the nested-object merge this used to carry inline now lives once in
    device_config.resolve_device_block, so board_sync, work_connectors and anything after
    them share one implementation instead of a copy each. Behaviour is unchanged — the
    suite pins `board_sync config` byte-for-byte across the migration."""
    cfg, error = resolve_device_block("board_sync", DEFAULTS, "XYZ_BOARD_SYNC")
    if error:
        _warn(error)
    return cfg


def resolve_selection_policy(required=False):
    """Resolve and strictly validate the saved board policy; pending means consumable."""
    cfg, error = resolve_device_block("github_board_selection_policy", POLICY_DEFAULTS,
                                      "XYZ_GITHUB_BOARD_POLICY")
    if error:
        raise ValueError(error)
    if cfg.get("repo"):
        if cfg.get("repos") and cfg["repos"] != [cfg["repo"]]:
            raise ValueError("policy repo and repos disagree")
        cfg["repos"] = [cfg["repo"]]
    absent = [k for k in ("project_owner", "project_number", "repos") if not cfg.get(k)]
    if absent:
        if required:
            raise ValueError("selection policy missing %s" % ", ".join(absent))
        return None
    if not isinstance(cfg["project_owner"], str) or not cfg["project_owner"].strip():
        raise ValueError("project_owner must be a non-empty string")
    if not isinstance(cfg["project_number"], int) or isinstance(cfg["project_number"], bool) or cfg["project_number"] <= 0:
        raise ValueError("project_number must be a positive integer")
    if not isinstance(cfg["repos"], list) or not cfg["repos"]:
        raise ValueError("repos must be a non-empty list")
    cfg["repos"] = [str(r).strip() for r in cfg["repos"]]
    if any(not re.fullmatch(r"[^/\s]+/[^/\s]+", r) for r in cfg["repos"]):
        raise ValueError("every policy repo must be owner/name")
    for key in ("ready_top_n", "done_lookback_days", "activity_lookback_days"):
        if not isinstance(cfg[key], int) or isinstance(cfg[key], bool) or cfg[key] < 0:
            raise ValueError("%s must be a non-negative integer" % key)
    for key in ("status_field", "ready", "in_progress", "in_review", "done", "backlog"):
        if not isinstance(cfg[key], str) or not cfg[key].strip():
            raise ValueError("%s must be a non-empty string" % key)
    loaded = load_local_device_config()
    raw_connectors = loaded.get("work_connectors", {})
    connector = raw_connectors.get("github_board", {}) if isinstance(raw_connectors, dict) else {}
    if isinstance(connector, dict) and connector:
        c_owner, c_number = connector.get("project_owner"), connector.get("project_number")
        if c_owner and c_owner != cfg["project_owner"] or c_number and int(c_number) != cfg["project_number"]:
            raise ValueError("selection policy target disagrees with github_board connector")
    return cfg


def _parse_utc(value):
    if not isinstance(value, str):
        return None
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.astimezone(dt.timezone.utc)


def _identity(obj):
    kind = str(obj.get("kind") or "issue").lower()
    if kind in ("pullrequest", "pull_request"):
        kind = "pr"
    try:
        number = int(obj.get("number", obj.get("num")))
    except (TypeError, ValueError):
        return None
    repo = obj.get("repo")
    return (repo, kind, number) if isinstance(repo, str) and "/" in repo else None


def _within(value, days, as_of):
    observed = _parse_utc(value)
    return observed is not None and observed <= as_of and as_of - observed <= dt.timedelta(days=days)


def sanitize_observations(observations, policy, as_of):
    """Validate optional external evidence and discard all private/raw fields."""
    now = _parse_utc(as_of) if isinstance(as_of, str) else as_of
    if not isinstance(observations, list):
        raise ValueError("observations must be a JSON array")
    out = []
    for index, raw in enumerate(observations):
        if not isinstance(raw, dict):
            out.append({"index": index, "valid": False, "reason": "not an object"})
            continue
        safe = {k: raw.get(k) for k in ("source", "issue_url", "observed_at", "kind", "reference")}
        match = re.fullmatch(r"https://github\.com/([^/]+/[^/]+)/issues/(\d+)", safe.get("issue_url") or "")
        observed = _parse_utc(safe.get("observed_at"))
        valid_kind = safe.get("kind") in ("intent", "started", "phase_completed", "completed")
        valid_source = isinstance(safe.get("source"), str) and bool(safe["source"].strip())
        valid_ref = isinstance(safe.get("reference"), str) and bool(safe["reference"].strip())
        if not match or match.group(1) not in policy["repos"]:
            reason = "unmapped issue identity"
        elif observed is None or observed > now:
            reason = "malformed or future timestamp"
        elif not valid_kind or not valid_source or not valid_ref:
            reason = "invalid source/kind/reference"
        else:
            reason = None
        safe.update(valid=reason is None, reason=reason,
                    freshness=("recent" if reason is None and
                               now - observed <= dt.timedelta(days=policy["activity_lookback_days"])
                               else "stale" if reason is None else "unknown"))
        out.append(safe)
    return out


def plan_selection_policy(policy, ledger, board_items, github_items, observations=None, as_of=None):
    """Pure, conservative GH-605 board planner. Unknown/ambiguous identities never move."""
    as_of_dt = _parse_utc(as_of) if isinstance(as_of, str) else as_of
    as_of_dt = as_of_dt or dt.datetime.now(dt.timezone.utc)
    allowed = set(policy["repos"])
    gh = {_identity(x): x for x in github_items if _identity(x) and _identity(x)[0] in allowed}
    ledger_by, invalid_ledger = {}, set()
    for row in ledger:
        ident = _identity(row)
        if ident and ident[1] == "issue" and ident[0] in allowed:
            if row.get("identity_valid", True):
                ledger_by.setdefault(ident, []).append(row)
            else:
                invalid_ledger.add(ident)
    board_by, opaque, duplicates = {}, [], set()
    for item in board_items:
        ident = _identity(item)
        if not ident or ident[0] not in allowed:
            opaque.append(item)
            continue
        if ident in board_by:
            duplicates.add(ident)
        else:
            board_by[ident] = item
    warnings = []
    if opaque:
        warnings.append("%d foreign or opaque board item(s) preserved" % len(opaque))
    if duplicates:
        warnings.append("%d duplicate identity group(s) preserved" % len(duplicates))

    targets, reasons, unresolved = {}, {}, []
    # PR cards and explicit closing links have precedence over issue starts/readiness.
    for ident, item in gh.items():
        if ident[1] != "pr":
            continue
        state = str(item.get("state") or "").upper()
        if state == "OPEN":
            targets[ident], reasons[ident] = policy["in_review"], "open PR"
            for ref in item.get("closing_issues") or []:
                ref_ident = _identity(dict(ref, kind="issue"))
                linked = gh.get(ref_ident)
                if not linked or str(linked.get("state") or "").upper() != "OPEN":
                    continue
                linked_rows = ledger_by.get(ref_ident, [])
                linked_section = (str(linked_rows[0].get("section") or "").strip().lower()
                                  if len(linked_rows) == 1 else "")
                # GitHub is authoritative for an explicit OPEN closing link when the ledger has
                # no row yet. Preserve only evidence that is actually contradictory or ambiguous:
                # an invalid row, duplicate ledger/card identity, or one known terminal row.
                if (ref_ident in duplicates or ref_ident in invalid_ledger
                        or len(linked_rows) > 1
                        or linked_section.startswith("completed")
                        or linked_section.startswith("deferred")):
                    unresolved.append({"identity": ref_ident,
                                       "reason": "linked PR cannot override ambiguous or terminal ledger identity"})
                    continue
                if not item.get("draft"):
                    targets[ref_ident], reasons[ref_ident] = policy["in_review"], "open non-draft closing PR"
                elif (targets.get(ref_ident) != policy["in_review"] and
                      _within(item.get("updated_at"), policy["activity_lookback_days"], as_of_dt)):
                    targets[ref_ident], reasons[ref_ident] = policy["in_progress"], "recent draft closing PR"
        elif state in ("CLOSED", "MERGED"):
            merged_at = _parse_utc(item.get("merged_at"))
            closed_at = _parse_utc(item.get("closed_at"))
            if item.get("merged_at"):
                if merged_at is None or merged_at > as_of_dt:
                    unresolved.append({"identity": ident, "reason": "unknown PR merge date"})
                elif as_of_dt - merged_at <= dt.timedelta(days=policy["done_lookback_days"]):
                    targets[ident], reasons[ident] = policy["done"], "recently merged PR"
                elif ident in board_by:
                    targets[ident], reasons[ident] = policy["done"], "merged PR retained in Done"
            elif state == "MERGED":
                unresolved.append({"identity": ident, "reason": "merged PR lacks a known merge date"})
            elif closed_at is None or closed_at > as_of_dt:
                unresolved.append({"identity": ident, "reason": "unknown PR closure date"})
            elif ident in board_by:
                targets[ident], reasons[ident] = policy["backlog"], "closed unmerged PR"
        else:
            unresolved.append({"identity": ident, "reason": "unknown GitHub PR state"})

    ready = []
    for ident, item in gh.items():
        if ident[1] != "issue" or ident in targets:
            continue
        rows = ledger_by.get(ident, [])
        # Known ambiguity preserves every issue state, including CLOSED. Absence is different:
        # GitHub may authoritatively close an issue before the roadmap has a row for it.
        if ident in duplicates or ident in invalid_ledger or len(rows) > 1:
            unresolved.append({"identity": ident,
                               "reason": "duplicate or invalid ledger or board identity"})
            continue
        state, reason = str(item.get("state") or "").upper(), item.get("state_reason")
        if state == "CLOSED":
            stamp = _parse_utc(item.get("closed_at"))
            if reason not in ("COMPLETED", "NOT_PLANNED"):
                unresolved.append({"identity": ident, "reason": "unknown closure reason"})
            elif stamp is None or stamp > as_of_dt:
                unresolved.append({"identity": ident, "reason": "unknown closure date"})
            elif reason == "COMPLETED" and as_of_dt - stamp <= dt.timedelta(days=policy["done_lookback_days"]):
                targets[ident], reasons[ident] = policy["done"], "recently completed issue"
            elif reason == "COMPLETED" and ident in board_by:
                targets[ident], reasons[ident] = policy["done"], "completed issue retained in Done"
            elif ident in board_by:
                targets[ident], reasons[ident] = policy["backlog"], "closed not-planned issue"
            continue
        if state != "OPEN":
            unresolved.append({"identity": ident, "reason": "unknown GitHub state"})
            continue
        if len(rows) != 1:
            unresolved.append({"identity": ident, "reason": "duplicate/missing ledger or board identity"})
            continue
        row = rows[0]
        section = str(row.get("section") or "").strip().lower()
        if section.startswith("completed") or section.startswith("deferred"):
            unresolved.append({"identity": ident, "reason": "reopened issue contradicts terminal ledger"})
            continue
        start = row.get("recent_start")
        if isinstance(start, dict) and start.get("freshness") == "recent":
            targets[ident], reasons[ident] = policy["in_progress"], "recent unsuperseded recorded start"
            continue
        if row.get("activity") in ("stale", "unknown") and (row.get("marker") == "\U0001F6A7" or section.startswith("in progress")):
            unresolved.append({"identity": ident, "reason": "unverified inflight evidence"})
            continue
        ratings = row.get("ratings") or {}
        axes = [ratings.get(k) for k in ("pri", "sev", "appeal", "effort")]
        if all(isinstance(v, int) and not isinstance(v, bool) and 1 <= v <= 100 for v in axes):
            score = ratings.get("ovr")
            if not isinstance(score, int) or isinstance(score, bool) or not 4 <= score <= 400:
                score = sum(axes)
            ready.append((ident, row, score))
        elif board_by.get(ident, {}).get("status") == policy["ready"]:
            unresolved.append({"identity": ident,
                               "reason": "unrated Ready card preserved as unknown"})
    ready.sort(key=lambda x: (-x[2], x[0][0].casefold(), x[0][2], str(x[1].get("global_id") or "")))
    selected = {ident for ident, _, _ in ready[:policy["ready_top_n"]]}
    for ident, _, _ in ready:
        targets[ident] = policy["ready"] if ident in selected else policy["backlog"]
        reasons[ident] = "top-N eligible" if ident in selected else "eligible outside top-N"

    changes, decisions = [], []
    for ident in sorted(targets, key=lambda x: (x[0].casefold(), x[1], x[2])):
        before = board_by.get(ident, {}).get("status")
        target = targets[ident]
        decisions.append({"identity": list(ident), "status": target, "reason": reasons[ident]})
        if ident in duplicates:
            continue
        # Old/NOT_PLANNED terminal rows are never added merely to place them in Backlog.
        if ident not in board_by and target == policy["backlog"]:
            continue
        if before != target:
            changes.append({"identity": list(ident), "item_id": board_by.get(ident, {}).get("item_id"),
                            "before": before, "after": target, "reason": reasons[ident]})
    return {"as_of": as_of_dt.isoformat().replace("+00:00", "Z"),
            "decisions": decisions, "changes": changes, "warnings": warnings,
            "unresolved": [dict(item, identity=list(item["identity"])) for item in unresolved],
            "ready_selected": [list(i) for i in sorted(selected)]}


# ── candidate extraction (offline) ─────────────────────────────────────────────


def _scan_pdda_docs(root):
    out = []
    for p in sorted((root / "PROJECT" / "2-WORKING").glob("GH-*.md")):
        m = re.match(r"GH-?(\d{1,6})[-_]", p.name) or re.match(r"GH-?(\d{1,6})\.md", p.name)
        if m:
            out.append((int(m.group(1)), "pdda_doc", str(p.relative_to(root))))
    return out


def _scan_branches(root):
    out = []
    try:
        refs = subprocess.run(
            ["git", "-C", str(root), "for-each-ref", "--format=%(refname:short)", "refs/heads"],
            capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        _warn(f"branch scan skipped: {exc}")
        return out
    for ref in refs.stdout.splitlines():
        # Any `prefix/gh-?N` shape counts (review r2: the fix|feat|marathon allow-list
        # missed this repo's own chore/ and docs/ lanes — half the live branches); the
        # gh is case-insensitive to match `feat/GH-402-…` conventions.
        m = re.match(r"[^/\s]+/[Gg][Hh]-?(\d{1,6})(?:[-_/.]|$)", ref.strip())
        if m:
            out.append((int(m.group(1)), "branch", ref.strip()))
    return out


def _scan_tick_events(root):
    out, seen = [], set()
    ev_dir = root / ".tick" / "events"
    if not ev_dir.is_dir():
        return out
    for p in sorted(ev_dir.glob("*.jsonl")):
        try:
            payload = json.loads(p.read_text(errors="replace").strip().splitlines()[0])
        except (OSError, ValueError, IndexError):
            continue
        task = str(payload.get("task", ""))
        m = re.search(r"[Gg][Hh][-_]?(\d{1,6})", task)
        if m and payload.get("type") in ("task.created", "task.claimed"):
            key = (int(m.group(1)), task)
            if key not in seen:
                seen.add(key)
                out.append((int(m.group(1)), "tick_event", task))
    return out


def _scan_releases_db(root):
    """🚧 markers are WEAK (stale by the QA probe, S3); jog running rows are STRONG."""
    out = []
    db = root / "releases.db"
    if not db.is_file():
        return out
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=10)
        try:
            for (n,) in conn.execute(
                "SELECT gh_number FROM roadmap_items WHERE status_marker = '🚧' AND gh_number IS NOT NULL"
            ):
                out.append((int(n), "stale_marker", f"roadmap_items gh-{n} 🚧"))
            for (n,) in conn.execute(
                "SELECT gh_number FROM jog_queue WHERE status = 'running' AND gh_number IS NOT NULL"
            ):
                out.append((int(n), "jog_running", f"jog_queue gh-{n}"))
        finally:
            conn.close()
    except sqlite3.Error as exc:
        _warn(f"releases.db scan skipped: {exc}")
    return out


def _scan_clone_dirs(cfg):
    out = []
    for raw in cfg.get("clone_dirs", []):
        base = Path(raw).expanduser()
        if not base.is_dir():
            continue
        try:
            entries = list(base.iterdir())
        except OSError:
            continue
        for entry in entries:
            m = _GH_N.search(entry.name)
            if m:
                out.append((int(m.group(1)), "clone_dir", str(entry)))
    return out


def scan(root, cfg, allow_empty=False):
    """Return {issue_number: [(source, detail), ...]} — every candidate, strong and weak.
    allow_empty is for internal callers (reconcile over an idle clone is "nothing to
    reconcile", not an error); the explicit `scan` verb keeps the refusal (review r1 F3)."""
    root = Path(root).resolve()
    if not root.is_dir():
        _die(f"scan root is not a directory: {root}")
    found = {}
    for num, source, detail in (
        *_scan_pdda_docs(root),
        *_scan_branches(root),
        *_scan_tick_events(root),
        *_scan_releases_db(root),
        *_scan_clone_dirs(cfg),
    ):
        found.setdefault(num, []).append((source, detail))

    # Empty-input refusal (QA r1 S-2): an explicit scan that extracts nothing is a
    # broken extractor or a wrong root — never a green.
    if not found and not allow_empty:
        _die("scan extracted zero candidates — refusing (empty input is not a pass)", 1)
    return found


# ── board side (network; gh api graphql is the auth layer) ─────────────────────


def _raise_if_insufficient_scopes(blob):
    """GH-549: name a missing token scope, and print the exact remediation.

    This is the most likely first failure on a fresh machine — verified on this host, whose gh
    token carries `gist, read:org, repo, workflow` and NOT `read:project` — and it used to
    arrive as an opaque `gh api graphql rc=1` or `GraphQL errors: [...]` blob. It is checked on
    BOTH failure paths because real `gh` exits nonzero for this, so the payload branch alone
    would never have seen it.

    We never run an auth command on anyone's behalf: the operator is told the command and runs
    it themselves.
    """
    if not blob:
        return
    if "INSUFFICIENT_SCOPES" in blob or "read:project" in blob:
        raise RuntimeError(
            "the gh token lacks the Projects scope, so no board call can succeed. "
            "Grant it with:  gh auth refresh -s read:project,project   "
            "(this tool will not run an auth command for you). Underlying error: %s"
            % blob.strip()[:200])


def _gql(query, variables=None):
    # GH-405: the gh executable is a seam so the mock board (utils/py/mock_gh_board.py) can
    # stand in for the real API offline. Default is the real `gh` — nothing changes unless
    # XYZ_BOARD_SYNC_GH_BIN is set, and the binary is named in every error below so a run
    # against the mock can never be mistaken for a run against the live board.
    gh_bin = os.environ.get("XYZ_BOARD_SYNC_GH_BIN", "gh")
    cmd = [gh_bin, "api", "graphql", "-f", f"query={query}"]
    for k, v in (variables or {}).items():
        # -F applies type inference and @file expansion — a project_owner of "@someuser"
        # would read a FILE named someuser (review r2 #7). Raw -f for strings; -F only
        # where the schema wants a typed scalar (Int).
        flag = "-F" if isinstance(v, int) and not isinstance(v, bool) else "-f"
        cmd += [flag, f"{k}={v}"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError(f"gh api graphql failed ({gh_bin}): {exc}") from exc
    if proc.returncode != 0:
        blob = (proc.stderr or "") + (proc.stdout or "")
        _raise_if_insufficient_scopes(blob)
        raise RuntimeError(f"gh api graphql rc={proc.returncode} ({gh_bin}): {proc.stderr.strip()[:300]}")
    try:
        payload = json.loads(proc.stdout)
    except ValueError as exc:
        raise RuntimeError(f"gh api graphql returned non-JSON: {exc}") from exc
    if "errors" in payload:
        blob = json.dumps(payload["errors"])
        _raise_if_insufficient_scopes(blob)
        raise RuntimeError(f"GraphQL errors: {blob[:300]}")
    return payload["data"]


def _atomic_state_write(payload):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(STATE_PATH.parent), prefix=".board_sync_state.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, sort_keys=True)
    os.replace(tmp, STATE_PATH)  # atomic: write-temp + rename (S5)


def _load_state():
    try:
        return json.loads(STATE_PATH.read_text())
    except (OSError, ValueError):
        return {}


def require_board_identity(cfg):
    """Refuse before any network call when the board identity is not configured (GH-549).

    This is what replaces the old personal defaults. It must run BEFORE the first _gql, so an
    unconfigured harness cannot write to anyone's board — not even by accident, and not even
    once.
    """
    missing = [k for k in ("project_owner", "project_number", "repos") if not cfg.get(k)]
    if missing:
        _die("board identity is not configured (missing: %s). Set them in "
             "~/.xyz/device_config.json under \"board_sync\", or via "
             "XYZ_BOARD_SYNC_PROJECT_OWNER / XYZ_BOARD_SYNC_PROJECT_NUMBER / "
             "XYZ_BOARD_SYNC_REPOS. There is no "
             "default — a default would write to somebody else's board."
             % ", ".join(missing), 2)


def resolve_ids(cfg, force=False, cache=True):
    """Resolve project / field / option IDs BY NAME, cached in state, re-resolved on
    demand (S5) — a board edit (renamed option) must self-heal, not persist stale IDs.
    The cache records the SETTINGS it was resolved from: change project_number (or any
    input) and the cache self-invalidates instead of silently writing to the old board
    (review r2 #1)."""
    require_board_identity(cfg)
    wanted_inputs = {
        "project_owner": cfg["project_owner"],
        "project_number": int(cfg["project_number"]),
        "status_field": cfg["status_field"],
        "in_progress": cfg["in_progress"],
    }
    state = _load_state() if cache else {}
    if not cache:
        force = True
    ids = state.get("ids", {}) if not force else {}
    if ids and ids.get("_inputs") != wanted_inputs:
        _warn("cached board IDs were resolved from different settings — re-resolving")
        ids = {}
    if ids and "options" not in ids:
        # A cache written before GH-549 has no option table. Re-resolve rather than fail
        # later with a KeyError in the middle of a status write.
        ids = {}
    if not ids:
        # GitHub's RepositoryOwner union resolves both users and organizations without asking
        # for a nonexistent concrete owner shape (which GraphQL reports as an error).
        data = _gql(
            "query($o:String!,$n:Int!,$f:String!){repositoryOwner(login:$o){"
            "... on User{projectV2(number:$n){id field(name:$f){"
            "... on ProjectV2SingleSelectField{id options{id name}}}}}"
            "... on Organization{projectV2(number:$n){id field(name:$f){"
            "... on ProjectV2SingleSelectField{id options{id name}}}}}}}",
            {"o": cfg["project_owner"], "n": int(cfg["project_number"]), "f": cfg["status_field"]},
        )
        owner = data.get("repositoryOwner") or {}
        proj = owner.get("projectV2")
        if proj is None:
            raise RuntimeError(
                f"project {cfg['project_owner']}/{cfg['project_number']} not found "
                f"as a repository owner"
            )
        field = proj.get("field")
        if field is None:
            raise RuntimeError(f"field {cfg['status_field']!r} not found on the project")
        options = field.get("options") or []
        option = next((o for o in options if o["name"] == cfg["in_progress"]), None)
        if option is None:
            raise RuntimeError(
                f"option {cfg['in_progress']!r} not found on field {cfg['status_field']!r} "
                f"(options: {[o['name'] for o in options]})"
            )
        ids = {
            "_inputs": wanted_inputs,
            "project": proj["id"],
            "status_field": field["id"],
            "in_progress_option": option["id"],
            # GH-549: the whole option table, by name. board_add only ever needed
            # in_progress, but a kanban connector moves a card to a column named by
            # config, so the id for every column has to survive the one round trip we
            # already make rather than costing a query each.
            "options": {o["name"]: o["id"] for o in options},
        }
        if cache:
            state["ids"] = ids
            _atomic_state_write(state)
    return ids


def fetch_board_items(cfg, cache=True):
    """Paginate project items once; cache the snapshot in state. Keyed by
    (nameWithOwner, number) — the board is user-level and multi-repo, and a
    number-only key makes another repo's card with the same number silently
    disable writes for this repo forever (QA r1 B-1). Also captures each item's
    id and Status value so a card that predates its work-start signal can be
    status-flipped without a re-add (review r2 #2)."""
    ids = resolve_ids(cfg, force=not cache, cache=cache)
    q = (
        "query($id:ID!,$cur:String,$f:String!){node(id:$id){... on ProjectV2{"
        "items(first:100,after:$cur){pageInfo{endCursor hasNextPage}nodes{id "
        "content{__typename ... on Issue{number repository{nameWithOwner}} "
        "... on PullRequest{number repository{nameWithOwner}}} "
        "fieldValueByName(name:$f){... on ProjectV2ItemFieldSingleSelectValue{name}}}}}}}"
    )
    base_vars = {"id": ids["project"], "f": cfg["status_field"]}
    cur, issues, seen_cursors = None, [], set()
    for _page in range(100):
        data = _gql(q, dict(base_vars, cur=cur) if cur else base_vars)
        node = ((data.get("node") or {}).get("items") if isinstance(data, dict) else None)
        if not isinstance(node, dict) or not isinstance(node.get("nodes"), list):
            raise RuntimeError("GitHub returned a malformed project-items page")
        for item in node["nodes"]:
            content = item.get("content") or {}
            fv = item.get("fieldValueByName") or {}
            if "number" in content:
                key = (content.get("repository", {}).get("nameWithOwner", "?"), content["number"])
                issues.append({
                    "repo": key[0], "num": key[1],
                    "number": key[1],
                    "kind": "pr" if content.get("__typename") == "PullRequest" else "issue",
                    "item_id": item.get("id"),
                    "status": fv.get("name"),
                })
            else:
                # Draft/redacted/unknown content is still part of the board snapshot. Keep it
                # so policy planning can report and preserve it instead of silently dropping it.
                issues.append({"repo": None, "num": None, "number": None, "kind": "opaque",
                               "item_id": item.get("id"), "status": fv.get("name")})
        info = node.get("pageInfo")
        if not isinstance(info, dict) or not isinstance(info.get("hasNextPage"), bool):
            raise RuntimeError("GitHub returned malformed project pagination metadata")
        if not info["hasNextPage"]:
            break
        next_cursor = info.get("endCursor")
        if not isinstance(next_cursor, str) or not next_cursor or next_cursor in seen_cursors:
            raise RuntimeError("GitHub pagination advertised another page without a fresh cursor")
        seen_cursors.add(next_cursor)
        cur = next_cursor
    else:
        raise RuntimeError("GitHub project pagination exceeded the 100-page safety bound")
    if cache:
        state = _load_state()
        state["snapshot"] = {"issues": issues, "fetched_at": int(time.time())}
        _atomic_state_write(state)
    return issues


def fetch_board_issues(cfg):
    """Compatibility snapshot for legacy issue-only callers."""
    return {(i["repo"], i["num"]): i for i in fetch_board_items(cfg)
            if i.get("kind") == "issue"}


def content_node(cfg, repo_name, num, kind="issue"):
    if not cfg.get("repos"):
        raise RuntimeError("no repos configured (board_sync.repos / XYZ_BOARD_SYNC_REPOS)")
    owner_name = repo_name.split("/", 1)
    if len(owner_name) != 2:
        raise RuntimeError(f"repos entry {cfg['repos'][0]!r} is not owner/name")
    field = "pullRequest" if kind == "pr" else "issue"
    data = _gql(
        "query($o:String!,$n:String!,$i:Int!){repository(owner:$o,name:$n){%s(number:$i){id state}}}" % field,
        {"o": owner_name[0], "n": owner_name[1], "i": int(num)},
    )
    repo = data.get("repository") or {}
    content = repo.get(field)
    if content is None:
        raise RuntimeError(f"{kind} #{num} not found in {repo_name}")
    return content


def issue_node_id(cfg, num):
    return content_node(cfg, cfg["repos"][0], num, "issue")


class IndeterminateMutation(RuntimeError):
    pass


def _remote_request(operation, variables, invoke, audit=None, validate=None):
    entry = {"request_id": "req-%s-%s" % (os.getpid(), time.time_ns()),
             "operation": operation, "variables": dict(variables)}
    if audit is None:
        result = invoke()               # legacy self-heal/retry behavior stays byte-compatible
        if validate is not None:
            validate(result)
        return result
    if audit:
        audit(dict(entry, phase="intent"))
    try:
        result = invoke()
        if validate is not None:
            validate(result)
    except Exception as exc:
        if audit:
            try:
                audit(dict(entry, phase="result", outcome="indeterminate", error=str(exc)))
            except Exception:
                pass
        raise IndeterminateMutation("%s response indeterminate: %s" % (operation, exc)) from exc
    if audit:
        try:
            audit(dict(entry, phase="result", outcome="success", result=result))
        except Exception as exc:
            raise IndeterminateMutation("%s succeeded but result audit failed: %s" % (operation, exc)) from exc
    return result


def _validate_mutation_item(result, operation, expected_item_id=None):
    """Require GraphQL mutation acknowledgement before an audited success is durable."""
    try:
        item_id = result[operation]["item" if operation == "addProjectV2ItemById"
                                    else "projectV2Item"]["id"]
    except (KeyError, TypeError):
        raise RuntimeError("%s returned no project item id" % operation)
    if not isinstance(item_id, str) or not item_id:
        raise RuntimeError("%s returned no project item id" % operation)
    if expected_item_id is not None and item_id != expected_item_id:
        raise RuntimeError("%s returned item %r, expected %r"
                           % (operation, item_id, expected_item_id))


def _add_item(cfg, ids, content_id, audit=None):
    variables = {"p": ids["project"], "c": content_id}
    data = _remote_request("addProjectV2ItemById", variables, lambda: _gql(
        "mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}",
        variables), audit,
        validate=lambda result: _validate_mutation_item(result, "addProjectV2ItemById"))
    return data["addProjectV2ItemById"]["item"]["id"]


def board_add(cfg, num, write, snapshot=None):
    """Add issue + set In progress. Idempotent: check-first (repo-qualified, B-1)
    against the snapshot (fetched when not supplied — reconcile passes one in so N
    candidates cost one pagination, not 2N, review r2 #5). A card that already exists
    with a DIFFERENT status gets a status-only write — the work-start event must not be
    missed just because the card predates it (review r2 #2)."""
    require_board_identity(cfg)   # GH-549: before repos[0], which would otherwise IndexError
    repo = cfg["repos"][0]
    board_name = f"{cfg['project_owner']}/projects/{cfg['project_number']}"
    on_board = snapshot if snapshot is not None else fetch_board_issues(cfg)
    existing = on_board.get((repo, num))
    if existing and existing.get("status") == cfg["in_progress"]:
        return f"gh-{num}: already {cfg['in_progress']!r} on {board_name} ({repo}) — no-op"
    issue = issue_node_id(cfg, num)
    if issue.get("state") == "CLOSED":
        return f"gh-{num}: issue is CLOSED — a closed issue is not a work-start, skipping"
    if existing and existing.get("item_id"):
        if not write:
            return (f"gh-{num} ({issue['state']}): dry-run — card exists with status "
                    f"{existing.get('status')!r}, would set {cfg['in_progress']!r}")
        ids = resolve_ids(cfg)
        try:
            _set_status(cfg, ids, existing["item_id"])
        except RuntimeError as exc:
            ids = resolve_ids(cfg, force=True)  # S5: stale-ID self-heal
            _set_status(cfg, ids, existing["item_id"])
            _warn(f"status write failed ({exc}); re-resolved IDs and succeeded")
        if snapshot is None:
            fetch_board_issues(cfg)  # refresh snapshot post-write
        else:
            existing["status"] = cfg["in_progress"]
        return f"gh-{num}: card existed as {existing.get('status')!r} — set Status={cfg['in_progress']!r} on {board_name}"
    if not write:
        return f"gh-{num} ({issue['state']}): dry-run — would add + set {cfg['in_progress']!r} on {board_name}"
    ids = resolve_ids(cfg)
    item_id = None
    try:
        item_id = _add_item(cfg, ids, issue["id"])
        _set_status(cfg, ids, item_id)
    except RuntimeError as exc:
        ids = resolve_ids(cfg, force=True)  # S5: stale-ID self-heal
        # S-1: if the ADD already succeeded, retrying it would duplicate the card —
        # retry only the status write in that case.
        if item_id is None:
            item_id = _add_item(cfg, ids, issue["id"])
        _set_status(cfg, ids, item_id)
        _warn(f"first attempt failed ({exc}); re-resolved IDs and succeeded")
    if snapshot is None:
        fetch_board_issues(cfg)  # refresh snapshot post-write
    else:
        snapshot[(repo, num)] = {"repo": repo, "num": num, "number": num,
                                 "kind": "issue", "item_id": item_id,
                                 "status": cfg["in_progress"]}
    return f"gh-{num}: added + Status={cfg['in_progress']!r} on {board_name}"


def _set_status_option(cfg, ids, item_id, option_id, audit=None):
    variables = {"p": ids["project"], "i": item_id,
                 "f": ids["status_field"], "o": option_id}
    _remote_request("updateProjectV2ItemFieldValue", variables, lambda: _gql(
        "mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{"
        "projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}",
        variables), audit,
        validate=lambda result: _validate_mutation_item(
            result, "updateProjectV2ItemFieldValue", item_id))


def _clear_status(cfg, ids, item_id, audit=None):
    variables = {"p": ids["project"], "i": item_id, "f": ids["status_field"]}
    _remote_request("clearProjectV2ItemFieldValue", variables, lambda: _gql(
        "mutation($p:ID!,$i:ID!,$f:ID!){clearProjectV2ItemFieldValue(input:{"
        "projectId:$p,itemId:$i,fieldId:$f}){projectV2Item{id}}}", variables), audit,
        validate=lambda result: _validate_mutation_item(
            result, "clearProjectV2ItemFieldValue", item_id))


def _set_status(cfg, ids, item_id):
    _set_status_option(cfg, ids, item_id, ids["in_progress_option"])


def option_id_for(cfg, column, force=False):
    """The option id for a column NAME, with one self-heal retry (GH-549).

    A board owner renames or adds a column and the cached table goes stale; that must
    re-resolve, exactly as S5 already does for a renamed in_progress option, rather than
    write to the wrong column or fail permanently.
    """
    ids = resolve_ids(cfg, force=force)
    option = (ids.get("options") or {}).get(column)
    if option is None and not force:
        return option_id_for(cfg, column, force=True)
    if option is None:
        raise RuntimeError(
            f"column {column!r} not found on field {cfg['status_field']!r} "
            f"(columns: {sorted((ids.get('options') or {}).keys())})"
        )
    return ids, option


def set_issue_status(cfg, num, column, write=True, snapshot=None, audit=None,
                     policy_mode=False, repo=None, kind="issue", on_added=None):
    """Move gh-<num>'s card to <column>, adding the card if the board has none (GH-549).

    Set-to-value, never an increment — which is what makes connector replay idempotent and
    lets `work reconcile` re-run a batch without double-applying anything.
    """
    require_board_identity(cfg)
    repo = repo or cfg["repos"][0]
    board_name = f"{cfg['project_owner']}/projects/{cfg['project_number']}"
    on_board = snapshot if snapshot is not None else fetch_board_issues(cfg)
    existing = on_board.get((repo, kind, num)) or on_board.get((repo, num))
    if existing and existing.get("status") == column:
        return f"gh-{num}: already {column!r} on {board_name} — no-op"
    if not write:
        return (f"gh-{num}: dry-run — would set {column!r} on {board_name} "
                f"(currently {existing.get('status') if existing else 'not on the board'!r})")
    item_id = existing.get("item_id") if existing else None
    # Resolve and validate the destination before an add. The outer policy preflight is not
    # sufficient for legacy callers or a column disappearing between planning and this seam.
    ids, option = option_id_for(cfg, column, force=policy_mode)
    if item_id is None:
        issue = content_node(cfg, repo, num, kind)
        item_id = _add_item(cfg, ids, issue["id"], audit=audit)
        if on_added is not None:
            on_added(item_id)
        if snapshot is not None:
            snapshot[(repo, kind, num)] = {"repo": repo, "num": num, "number": num,
                                           "kind": kind, "item_id": item_id, "status": None}
    try:
        _set_status_option(cfg, ids, item_id, option, audit=audit)
    except RuntimeError as exc:
        if policy_mode or isinstance(exc, IndeterminateMutation):
            raise
        ids, option = option_id_for(cfg, column, force=True)   # S5: stale-ID self-heal
        _set_status_option(cfg, ids, item_id, option, audit=audit)
        _warn(f"status write failed ({exc}); re-resolved IDs and succeeded")
    if snapshot is not None:
        key = (repo, kind, num) if (repo, kind, num) in snapshot else (repo, num)
        snapshot[key]["status"] = column
    else:
        fetch_board_issues(cfg)
    return f"gh-{num}: Status={column!r} on {board_name}"


def dedupe(cfg, write):
    ids = resolve_ids(cfg)
    q = (
        "query($id:ID!,$cur:String){node(id:$id){... on ProjectV2{items(first:100,after:$cur){"
        "pageInfo{endCursor hasNextPage}nodes{id content{... on Issue{number repository{nameWithOwner}}}}}}}}"
    )
    cur, by_issue, duplicates = None, {}, []
    while True:
        data = _gql(q, {"id": ids["project"], "cur": cur} if cur else {"id": ids["project"]})
        node = data["node"]["items"]
        for item in node["nodes"]:
            content = item.get("content") or {}
            if "number" in content:
                key = (content.get("repository", {}).get("nameWithOwner"), content["number"])
                if key in by_issue:
                    duplicates.append((key, by_issue[key], item["id"]))
                else:
                    by_issue[key] = item["id"]
        if not node["pageInfo"]["hasNextPage"]:
            break
        cur = node["pageInfo"]["endCursor"]
    if not duplicates:
        return "no duplicate cards"
    lines = []
    for key, keep, drop in duplicates:
        if not write:
            lines.append(f"dry-run — would delete duplicate card {drop} for {key} (keeping {keep})")
            continue
        _gql("mutation($p:ID!,$i:ID!){deleteProjectV2Item(input:{projectId:$p,itemId:$i}){deletedItemId}}",
             {"p": ids["project"], "i": drop})
        lines.append(f"deleted duplicate card {drop} for {key} (kept {keep})")
    fetch_board_issues(cfg)  # keep the cached snapshot honest after deletions (review r1 F8)
    return "\n".join(lines)


def _policy_board_cfg(policy):
    cfg = resolve_settings()
    cfg.update({"project_owner": policy["project_owner"],
                "project_number": policy["project_number"],
                "repos": policy["repos"], "status_field": policy["status_field"],
                "in_progress": policy["in_progress"]})
    return cfg


def collect_github_state(policy):
    """Read complete bounded issue/PR state for every policy repository."""
    found = []
    for repo_name in policy["repos"]:
        owner, name = repo_name.split("/", 1)
        for kind, field in (("issue", "issues"), ("pr", "pullRequests")):
            cursor = None
            for _page in range(100):
                if kind == "issue":
                    body = ("number state stateReason closedAt updatedAt id")
                else:
                    body = ("number state isDraft mergedAt closedAt updatedAt id "
                            "closingIssuesReferences(first:100){pageInfo{endCursor hasNextPage}nodes{"
                            "number repository{nameWithOwner}}}")
                query = ("query($o:String!,$n:String!,$cur:String){repository(owner:$o,name:$n){"
                         "%s(first:100,after:$cur,orderBy:{field:UPDATED_AT,direction:DESC}){"
                         "pageInfo{endCursor hasNextPage}nodes{%s}}}}" % (field, body))
                variables = {"o": owner, "n": name}
                if cursor:
                    variables["cur"] = cursor
                data = _gql(query, variables)
                repo = data.get("repository")
                if not repo or field not in repo:
                    raise RuntimeError("GitHub returned no %s collection for %s" % (field, repo_name))
                page = repo[field]
                if not isinstance(page, dict) or not isinstance(page.get("nodes"), list):
                    raise RuntimeError("GitHub returned a malformed %s page for %s" % (field, repo_name))
                for node in page["nodes"]:
                    item = {"repo": repo_name, "kind": kind, "number": node.get("number"),
                            "id": node.get("id"), "state": node.get("state"),
                            "updated_at": node.get("updatedAt"), "closed_at": node.get("closedAt")}
                    if kind == "issue":
                        item["state_reason"] = node.get("stateReason")
                    else:
                        refs = node.get("closingIssuesReferences") or {}
                        ref_info = refs.get("pageInfo")
                        ref_nodes = refs.get("nodes")
                        if (not isinstance(ref_info, dict)
                                or not isinstance(ref_info.get("hasNextPage"), bool)
                                or not isinstance(ref_nodes, list)):
                            raise RuntimeError("malformed closingIssuesReferences for %s#%s" %
                                               (repo_name, node.get("number")))
                        all_refs = list(ref_nodes)
                        ref_cursor = ref_info.get("endCursor")
                        for _ref_page in range(99):
                            if not ref_info["hasNextPage"]:
                                break
                            if not isinstance(ref_cursor, str) or not ref_cursor:
                                raise RuntimeError("closingIssuesReferences missing cursor for %s#%s" %
                                                   (repo_name, node.get("number")))
                            ref_data = _gql(
                                "query($o:String!,$n:String!,$i:Int!,$cur:String!){repository(owner:$o,name:$n){"
                                "pullRequest(number:$i){closingIssuesReferences(first:100,after:$cur){"
                                "pageInfo{endCursor hasNextPage}nodes{number repository{nameWithOwner}}}}}}",
                                {"o": owner, "n": name, "i": int(node.get("number")), "cur": ref_cursor})
                            more = ((((ref_data.get("repository") or {}).get("pullRequest") or {})
                                     .get("closingIssuesReferences"))
                                    if isinstance(ref_data, dict) else None)
                            if (not isinstance(more, dict) or not isinstance(more.get("nodes"), list)
                                    or not isinstance(more.get("pageInfo"), dict)
                                    or not isinstance(more["pageInfo"].get("hasNextPage"), bool)):
                                raise RuntimeError("malformed closingIssuesReferences page for %s#%s" %
                                                   (repo_name, node.get("number")))
                            all_refs.extend(more["nodes"])
                            ref_info = more["pageInfo"]
                            ref_cursor = ref_info.get("endCursor")
                        else:
                            raise RuntimeError("closingIssuesReferences exceeded the 100-page safety bound")
                        item.update({"draft": bool(node.get("isDraft")),
                                     "merged_at": node.get("mergedAt"),
                                     "closing_issues": [{"repo": (r.get("repository") or {}).get("nameWithOwner"),
                                                         "number": r.get("number")} for r in all_refs]})
                    found.append(item)
                info = page.get("pageInfo")
                if not isinstance(info, dict) or not isinstance(info.get("hasNextPage"), bool):
                    raise RuntimeError("GitHub returned malformed %s pagination for %s" % (field, repo_name))
                if not info.get("hasNextPage"):
                    break
                cursor = info.get("endCursor")
                if not cursor:
                    raise RuntimeError("GitHub pagination advertised another page without a cursor")
            else:
                raise RuntimeError("GitHub pagination exceeded the 100-page safety bound")
    return found


def _json_digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     default=str).encode()).hexdigest()


def _read_json(path):
    try:
        value = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise RuntimeError("cannot read JSON %s: %s" % (path, exc)) from exc
    return value


def _write_json(path, value):
    target = Path(path).expanduser().resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(target.parent), prefix=".%s." % target.name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, target)
        # The file contents and rename both need durability: otherwise a power loss can leave
        # a remote mutation with no matching audit result even though the callback returned.
        try:
            directory_fd = os.open(str(target.parent), os.O_RDONLY)
            try:
                os.fsync(directory_fd)
            finally:
                os.close(directory_fd)
        except OSError as exc:
            if exc.errno not in (errno.EINVAL, getattr(errno, "ENOTSUP", errno.EINVAL),
                                 getattr(errno, "EOPNOTSUPP", errno.EINVAL)):
                raise
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def build_policy_preview(root, observations=None, as_of=None):
    policy = resolve_selection_policy(required=True)
    from releases_app import load_work_evidence
    evidence = load_work_evidence(Path(root) / "releases.db",
                                  policy["activity_lookback_days"], as_of=as_of)
    if not evidence.get("schema_ready"):
        raise RuntimeError(evidence.get("error") or "work evidence is not ready")
    board = fetch_board_items(_policy_board_cfg(policy), cache=False)
    github = collect_github_state(policy)
    obs = sanitize_observations(observations or [], policy, evidence["as_of"])
    plan = plan_selection_policy(policy, evidence["issues"], board, github, obs,
                                 as_of=evidence["as_of"])
    source = {"ledger_generation": evidence["generation"], "ledger": evidence["issues"],
              "github": github, "board": board, "observations": obs}
    if any(not item.get("valid") or item.get("freshness") != "recent" for item in obs):
        plan["warnings"].append("external observations include stale/unmapped evidence; no board decision was inferred from it")
    return {"schema": "github-board-policy-preview@1", "created_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
            "as_of": plan["as_of"], "policy": policy,
            "ledger_generation": evidence["generation"], "source_digest": _json_digest(source),
            "observations": obs, "board": board, "github": github, **plan}


def _preview_age_ok(preview):
    created = _parse_utc(preview.get("created_at"))
    as_of = _parse_utc(preview.get("as_of"))
    now = dt.datetime.now(dt.timezone.utc)
    window = dt.timedelta(minutes=15)
    return (created is not None and as_of is not None
            and as_of <= created <= now
            and now - created <= window and now - as_of <= window)


def _unmatched_intents(operations):
    intents, results, indeterminate = {}, set(), []
    for entry in operations or []:
        request_id = entry.get("request_id") if isinstance(entry, dict) else None
        if request_id and entry.get("phase") == "intent":
            intents[request_id] = entry
        elif request_id and entry.get("phase") == "result":
            results.add(request_id)
            if entry.get("outcome") == "indeterminate":
                indeterminate.append(entry)
    return ([entry for request_id, entry in intents.items() if request_id not in results]
            + indeterminate)


def apply_policy_preview(root, preview_path, result_path):
    preview = _read_json(preview_path)
    if preview.get("schema") != "github-board-policy-preview@1" or not _preview_age_ok(preview):
        raise RuntimeError("preview is invalid, future-dated, or older than 15 minutes")
    result_target = Path(result_path).expanduser().resolve()
    if result_target.exists():
        raise RuntimeError("result artifact already exists; inspect it before retrying")
    policy = resolve_selection_policy(required=True)
    if policy != preview.get("policy"):
        raise RuntimeError("saved policy changed since preview")
    from work_connectors import _ConnectorLock
    lock = _ConnectorLock(str(Path(root) / "releases.db"))
    if not lock.acquire():
        raise RuntimeError("connector exclusion lock is busy")
    result = {"schema": "github-board-policy-result@1", "preview": str(Path(preview_path).resolve()),
              "root": str(Path(root).resolve()), "policy": policy,
              "as_of": preview["as_of"], "status": "applying",
              "operations": [], "warnings": list(preview.get("warnings") or [])}
    result_created = False

    def audit(entry):
        result["operations"].append(dict(entry, recorded_at=dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")))
        _write_json(result_path, result)

    try:
        # The same-ledger connector lock covers the fresh GH/board/ledger preflight and every
        # mutation. It cannot make the remote compare/write atomic across devices; the immediate
        # per-change read below is the final conditional guard.
        fresh = build_policy_preview(root, observations=preview.get("observations") or [],
                                     as_of=preview.get("as_of"))
        for key in ("ledger_generation", "source_digest", "decisions", "changes", "warnings", "unresolved"):
            if fresh.get(key) != preview.get(key):
                raise RuntimeError("preflight drift in %s; generate and review a new preview" % key)
        cfg = _policy_board_cfg(policy)
        # Resolve every destination from GitHub, without the state cache, before the first write.
        for column in sorted({c["after"] for c in preview["changes"]}):
            option_id_for(cfg, column, force=True)
        _write_json(result_path, result)
        result_created = True
        for change in preview["changes"]:
            repo, kind, number = change["identity"]
            live = [x for x in fetch_board_items(cfg, cache=False) if _identity(x) == (repo, kind, int(number))]
            live_item_id = live[0].get("item_id") if len(live) == 1 else None
            live_status = live[0].get("status") if len(live) == 1 else None
            if (len(live) > 1 or live_status != change["before"]
                    or live_item_id != change.get("item_id")):
                raise RuntimeError("board item changed before %s/%s#%s" % (repo, kind, number))
            snap = {(repo, kind, int(number)): live[0]} if live else {}
            change_record = {"phase": "change", "identity": change["identity"],
                             "before": change["before"], "after": change["after"],
                             "item_id": live_item_id, "added": live_item_id is None,
                             "outcome": "pending"}
            result["operations"].append(change_record)
            _write_json(result_path, result)

            def record_added(item_id):
                change_record["item_id"] = item_id
                _write_json(result_path, result)

            set_issue_status(cfg, int(number), change["after"], write=True, snapshot=snap,
                             audit=audit, policy_mode=True, repo=repo, kind=kind,
                             on_added=record_added)
            after_item = snap[(repo, kind, int(number))]
            change_record["item_id"] = after_item.get("item_id")
            change_record["outcome"] = "success"
            _write_json(result_path, result)
        result["status"] = "complete"
        _write_json(result_path, result)
        return result
    except Exception as exc:
        result["status"] = ("indeterminate" if isinstance(exc, IndeterminateMutation)
                            or _unmatched_intents(result["operations"]) else "partial")
        result["error"] = str(exc)
        if result_created:
            _write_json(result_path, result)
        raise
    finally:
        lock.release()


def restore_policy_result(result_path, write=False, move_added_to_backlog=False,
                          report_path=None):
    result = _read_json(result_path)
    if result.get("schema") != "github-board-policy-result@1":
        raise RuntimeError("not a GH-605 result artifact")
    policy = resolve_selection_policy(required=True)
    if policy != result.get("policy"):
        raise RuntimeError("current policy does not match the result artifact")
    if write and not report_path:
        raise RuntimeError("--write requires --out for durable per-request restore evidence")
    if write and Path(report_path).expanduser().resolve().exists():
        raise RuntimeError("restore artifact already exists; inspect it before retrying")
    cfg = _policy_board_cfg(policy)
    operations = result.get("operations")
    if not isinstance(operations, list):
        raise RuntimeError("result operations must be a list")
    changes = [x for x in operations if isinstance(x, dict) and x.get("phase") == "change"]
    allowed = set(policy["repos"])
    for change in changes:
        ident = change.get("identity")
        if (not isinstance(ident, list) or len(ident) != 3 or ident[0] not in allowed
                or ident[1] not in ("issue", "pr")
                or not isinstance(ident[2], int) or isinstance(ident[2], bool) or ident[2] <= 0):
            raise RuntimeError("result contains an operation outside the policy identity allowlist")
    unmatched = _unmatched_intents(operations)
    proposed, warnings, residual = [], [], []
    if unmatched:
        warnings.append("%d remote request(s) lack a conclusive result; fresh readback required"
                        % len(unmatched))
    for old in reversed(changes):
        repo, kind, number = old["identity"]
        live = [x for x in fetch_board_items(cfg, cache=False) if _identity(x) == (repo, kind, int(number))]
        if old.get("outcome") != "success":
            if old.get("added") and old.get("item_id"):
                match = next((x for x in live if x.get("item_id") == old.get("item_id")), None)
                residual.append({"identity": old["identity"], "item_id": old.get("item_id"),
                                 "status": match.get("status") if match else None,
                                 "reason": "add succeeded before apply stopped"})
            warnings.append("%s/%s#%s apply was partial or indeterminate; preserved after readback"
                            % (repo, kind, number))
            continue
        if len(live) != 1 or live[0].get("status") != old.get("after") or live[0].get("item_id") != old.get("item_id"):
            warnings.append("%s/%s#%s changed since apply; preserved" % (repo, kind, number))
            continue
        if old.get("added"):
            warnings.append("%s/%s#%s was added; retained (no-delete)" % (repo, kind, number))
            residual.append({"identity": old["identity"], "item_id": old.get("item_id"),
                             "status": live[0].get("status"),
                             "reason": "card added by apply is retained under no-delete"})
            if move_added_to_backlog:
                proposed.append(dict(old, restore_to=policy["backlog"]))
            continue
        proposed.append(dict(old, restore_to=old.get("before")))
    report = {"schema": "github-board-policy-restore@1", "write": bool(write),
              "status": ("indeterminate" if unmatched else
                         "partial" if warnings else "preview"),
              "changes": proposed, "residual_added": residual,
              "warnings": warnings, "operations": []}
    if write:
        from work_connectors import _ConnectorLock
        ledger_root = Path(result.get("root") or DEFAULT_SCAN_ROOT).resolve()
        lock = _ConnectorLock(str(ledger_root / "releases.db"))
        if not lock.acquire():
            raise RuntimeError("connector exclusion lock is busy")
        try:
            # Resolve all destinations while holding the same-ledger lock, before any write.
            resolved = {}
            for column in sorted({x["restore_to"] for x in proposed
                                  if x.get("restore_to") is not None}):
                resolved[column] = option_id_for(cfg, column, force=True)
            clear_ids = resolve_ids(cfg, force=True, cache=False)
            _write_json(report_path, report)

            def audit(entry):
                report["operations"].append(dict(
                    entry, recorded_at=dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")))
                _write_json(report_path, report)

            for change in proposed:
                repo, kind, number = change["identity"]
                live = [x for x in fetch_board_items(cfg, cache=False) if _identity(x) == (repo, kind, int(number))]
                if (len(live) != 1 or live[0].get("status") != change.get("after")
                        or live[0].get("item_id") != change.get("item_id")):
                    raise RuntimeError("restore precondition changed for %s/%s#%s" % (repo, kind, number))
                restore_record = {"phase": "restore", "identity": change["identity"],
                                  "item_id": change["item_id"], "before": change.get("after"),
                                  "after": change.get("restore_to"), "outcome": "pending"}
                report["operations"].append(restore_record)
                _write_json(report_path, report)
                if change["restore_to"] is None:
                    _clear_status(cfg, clear_ids, live[0]["item_id"], audit=audit)
                else:
                    ids, option = resolved[change["restore_to"]]
                    _set_status_option(cfg, ids, live[0]["item_id"], option, audit=audit)
                restore_record["outcome"] = "success"
                _write_json(report_path, report)
            report["status"] = ("indeterminate" if unmatched or _unmatched_intents(report["operations"])
                                else "partial" if warnings else "complete")
            _write_json(report_path, report)
        except Exception as exc:
            report["status"] = ("indeterminate" if isinstance(exc, IndeterminateMutation)
                                or unmatched or _unmatched_intents(report["operations"]) else "partial")
            report["error"] = str(exc)
            try:
                _write_json(report_path, report)
            except Exception:
                pass
            raise
        finally:
            lock.release()
    return report


# ── entry points ────────────────────────────────────────────────────────────────


def main(argv=None):
    # NOTE: --write/--root live ONLY on the subparsers. argparse's parents= pattern lets a
    # subparser default silently overwrite a value parsed at top level, so
    # `board_sync.py --write touch gh-1` would no-op instead of writing — a silent
    # safety inversion. Keeping the flags off the top parser makes that spelling a
    # loud usage error instead: `board_sync.py touch gh-1 --write`.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--write", action="store_true",
                        help="perform board mutations (default is dry-run — the safe first cut)")
    common.add_argument("--root", default=DEFAULT_SCAN_ROOT,
                        help="repo root to scan (default: the consumer repo this runs in)")
    ap = argparse.ArgumentParser(prog="board_sync.py",
                                 description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("scan", parents=[common], help="offline: extract gh-<n> candidates with strength")
    sub.add_parser("reconcile", parents=[common], help="scan + diff vs board + add missing strong candidates")
    ded = sub.add_parser("dedupe", parents=[common], help="remove duplicate cards for the same issue")
    sub.add_parser("config", help="print resolved settings (no secrets)")
    t = sub.add_parser("touch", parents=[common], help="explicit add + In progress for one issue")
    t.add_argument("issue", help="issue number or gh-<n>")
    pp = sub.add_parser("policy-preview", help="write a read-only saved-policy preview")
    pp.add_argument("--root", default=DEFAULT_SCAN_ROOT)
    pp.add_argument("--out", required=True, help="explicit output path for the versioned preview")
    pp.add_argument("--observations", help="optional normalized observation JSON array")
    pa = sub.add_parser("policy-apply", help="apply a fresh reviewed policy preview")
    pa.add_argument("--root", default=DEFAULT_SCAN_ROOT)
    pa.add_argument("--preview", required=True)
    pa.add_argument("--result-out", required=True)
    pr = sub.add_parser("policy-restore", help="preview or conditionally restore a result")
    pr.add_argument("--result", required=True)
    pr.add_argument("--write", action="store_true")
    pr.add_argument("--move-added-to-backlog", action="store_true")
    pr.add_argument("--out", help="optional restore-report path")

    args = ap.parse_args(argv)

    if os.environ.get("XYZ_BOARD_SYNC", "1") == "0":
        print("board_sync: kill-switch XYZ_BOARD_SYNC=0 — no-op")
        return 0

    cfg = resolve_settings()

    if args.cmd == "policy-preview":
        try:
            obs = _read_json(args.observations) if args.observations else []
            preview = build_policy_preview(args.root, observations=obs)
            _write_json(args.out, preview)
            print(json.dumps({"preview": str(Path(args.out).resolve()),
                              "changes": len(preview["changes"]),
                              "warnings": preview["warnings"],
                              "unresolved": preview["unresolved"]}, indent=2))
        except (RuntimeError, ValueError) as exc:
            _die(str(exc), 1)
        return 0

    if args.cmd == "policy-apply":
        try:
            result = apply_policy_preview(args.root, args.preview, args.result_out)
            print(json.dumps({"result": str(Path(args.result_out).resolve()),
                              "status": result["status"]}, indent=2))
        except (RuntimeError, ValueError) as exc:
            _die(str(exc), 1)
        return 0

    if args.cmd == "policy-restore":
        try:
            report = restore_policy_result(args.result, write=args.write,
                                           move_added_to_backlog=args.move_added_to_backlog,
                                           report_path=args.out)
            if args.out and not args.write:
                _write_json(args.out, report)
            print(json.dumps(report, indent=2, sort_keys=True))
        except (RuntimeError, ValueError) as exc:
            _die(str(exc), 1)
        return 1 if report.get("status") in ("partial", "indeterminate") else 0

    if args.cmd == "config":
        safe = {k: v for k, v in cfg.items() if k != "token_file"}
        print(json.dumps({"state_path": str(STATE_PATH), "device_config": get_device_config_path(),
                          "token_file": cfg["token_file"] + " (reserved, v1 uses gh)", **safe}, indent=2))
        return 0

    if args.cmd == "scan":
        found = scan(args.root, cfg)
        for num in sorted(found):
            for source, detail in found[num]:
                strength = "strong" if source in STRONG_SOURCES else "weak"
                print(f"gh-{num}\t{strength}\t{source}\t{detail}")
        strongs = sum(1 for num in found for s, _ in found[num] if s in STRONG_SOURCES)
        print(f"# {len(found)} issue(s), {strongs} strong signal(s)")
        return 0

    if args.cmd == "touch":
        # The help promises "issue number or gh-<n>" — a bare number is the documented
        # spelling and must work (review r1 F1).
        m = _GH_N.search(str(args.issue)) or re.fullmatch(r"(\d{1,6})", str(args.issue).strip())
        if not m:
            _die(f"cannot parse an issue number out of {args.issue!r}")
        try:
            print(board_add(cfg, int(m.group(1)), args.write))
        except RuntimeError as exc:
            _die(str(exc), 1)  # clean diagnostic, no traceback (review r2 #6)
        return 0

    if args.cmd == "dedupe":
        try:
            print(dedupe(cfg, args.write))
        except RuntimeError as exc:
            _die(str(exc), 1)
        return 0

    if args.cmd == "reconcile":
        # allow_empty: an idle clone reconciles to "nothing to reconcile" — the refusal
        # belongs to the explicit scan verb, not the sweeper-shaped entry point (r1 F3).
        found = scan(args.root, cfg, allow_empty=True)
        lines = []
        snapshot = None
        for num in sorted(found):
            sources = [s for s, _ in found[num]]
            if any(s in STRONG_SOURCES for s in sources):
                try:
                    # One snapshot for the whole run (r2 #5): fetched on the first
                    # strong candidate, reused for the rest, persisted at the end.
                    if snapshot is None:
                        snapshot = fetch_board_issues(cfg)
                    lines.append(board_add(cfg, num, args.write, snapshot=snapshot))
                except RuntimeError as exc:
                    _warn(f"gh-{num}: add failed — {exc} (degraded; board is a projection)")
            else:
                lines.append(f"gh-{num}: weak-only ({', '.join(sources)}) — log, no write")
        if snapshot is not None and args.write:
            fetch_board_issues(cfg)  # persist the post-run snapshot once
        print("\n".join(lines) if lines else "nothing to reconcile")
        return 0

    _die(f"unhandled command {args.cmd}")


if __name__ == "__main__":
    sys.exit(main())
