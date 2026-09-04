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
    from device_config import get_device_config_path, load_local_device_config
except ImportError:  # direct execution outside utils/py
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from device_config import get_device_config_path, load_local_device_config

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

DEFAULTS = {
    "project_owner": "noelsaw1",
    "project_number": 3,
    "status_field": "Status",
    "in_progress": "In progress",
    "repos": ["HiQS-Labs/XYZ-forge"],
    "clone_dirs": ["~/Documents/GH Repos"],
    "mention_policy": "strong-signals-write",
    "adapters": ["pdda", "git-hooks", "harness-fires", "sweeper"],  # consumed in Phase 2
    "token_file": "~/secrets/gh/board-sync.txt",  # reserved (PAT fallback); v1 uses gh
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
    object > feature defaults. The nested object's env tier lives HERE, not in
    device_config.py — the generic resolver handles top-level keys only (N3)."""
    cfg = dict(DEFAULTS)
    local = load_local_device_config().get("board_sync", {})
    if not isinstance(local, dict):
        _warn("board_sync setting is not an object — ignoring it")
        local = {}
    for key in DEFAULTS:
        env = f"XYZ_BOARD_SYNC_{key.upper()}"
        if env in os.environ:
            raw = os.environ[env]
            if isinstance(DEFAULTS[key], list):
                raw = [p.strip() for p in raw.split(",") if p.strip()]
            elif isinstance(DEFAULTS[key], int) and not isinstance(DEFAULTS[key], bool):
                try:
                    raw = int(raw)
                except ValueError:
                    _warn(f"{env}={raw!r} is not an integer — ignoring it")
                    continue
            cfg[key] = raw
        elif key in local:
            cfg[key] = local[key]
    # JSON-file values skip the env tier's comma-splitting, so a bare string where a
    # list belongs ("repos": "owner/name") would iterate characters downstream —
    # coerce (review r1 F6).
    for key in ("repos", "clone_dirs", "adapters"):
        if isinstance(cfg.get(key), str):
            cfg[key] = [cfg[key]]
    return cfg


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


def _gql(query, variables=None):
    # GH-405: the gh executable is a seam so the mock board (utils/py/mock_gh_board.py) can
    # stand in for the real API offline. Default is the real `gh` — nothing changes unless
    # XYZ_BOARD_SYNC_GH_BIN is set, and the binary is named in every error below so a run
    # against the mock can never be mistaken for a run against the live board.
    gh_bin = os.environ.get("XYZ_BOARD_SYNC_GH_BIN", "gh")
    cmd = [gh_bin, "api", "graphql", "-f", f"query={query}"]
    for k, v in (variables or {}).items():
        # -F applies type inference and @file expansion — a project_owner of "@noelsaw1"
        # would read a FILE named noelsaw1 (review r2 #7). Raw -f for strings; -F only
        # where the schema wants a typed scalar (Int).
        flag = "-F" if isinstance(v, int) and not isinstance(v, bool) else "-f"
        cmd += [flag, f"{k}={v}"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RuntimeError(f"gh api graphql failed ({gh_bin}): {exc}") from exc
    if proc.returncode != 0:
        raise RuntimeError(f"gh api graphql rc={proc.returncode} ({gh_bin}): {proc.stderr.strip()[:300]}")
    try:
        payload = json.loads(proc.stdout)
    except ValueError as exc:
        raise RuntimeError(f"gh api graphql returned non-JSON: {exc}") from exc
    if "errors" in payload:
        raise RuntimeError(f"GraphQL errors: {json.dumps(payload['errors'])[:300]}")
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


def resolve_ids(cfg, force=False):
    """Resolve project / field / option IDs BY NAME, cached in state, re-resolved on
    demand (S5) — a board edit (renamed option) must self-heal, not persist stale IDs.
    The cache records the SETTINGS it was resolved from: change project_number (or any
    input) and the cache self-invalidates instead of silently writing to the old board
    (review r2 #1)."""
    wanted_inputs = {
        "project_owner": cfg["project_owner"],
        "project_number": int(cfg["project_number"]),
        "status_field": cfg["status_field"],
        "in_progress": cfg["in_progress"],
    }
    state = _load_state()
    ids = state.get("ids", {}) if not force else {}
    if ids and ids.get("_inputs") != wanted_inputs:
        _warn("cached board IDs were resolved from different settings — re-resolving")
        ids = {}
    if not ids:
        # GH-405: ask for BOTH owner shapes in one round trip. `user(login:)` returns null
        # for an organization and vice versa, so the v1 user-only query could never reach an
        # org board — and this repo's own owner (HiQS-Labs) is an org, which is why the mock
        # models both (mock_gh_board.py:100-108). One query, no extra call, no guessing.
        data = _gql(
            "query($o:String!,$n:Int!,$f:String!){user(login:$o){projectV2(number:$n){id "
            "field(name:$f){... on ProjectV2SingleSelectField{id options{id name}}}}} "
            "organization(login:$o){projectV2(number:$n){id "
            "field(name:$f){... on ProjectV2SingleSelectField{id options{id name}}}}}}",
            {"o": cfg["project_owner"], "n": int(cfg["project_number"]), "f": cfg["status_field"]},
        )
        owner = data.get("user") or data.get("organization") or {}
        proj = owner.get("projectV2")
        if proj is None:
            raise RuntimeError(
                f"project {cfg['project_owner']}/{cfg['project_number']} not found "
                f"as either a user or an organization"
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
        }
        state["ids"] = ids
        _atomic_state_write(state)
    return ids


def fetch_board_issues(cfg):
    """Paginate project items once; cache the snapshot in state. Keyed by
    (nameWithOwner, number) — the board is user-level and multi-repo, and a
    number-only key makes another repo's card with the same number silently
    disable writes for this repo forever (QA r1 B-1). Also captures each item's
    id and Status value so a card that predates its work-start signal can be
    status-flipped without a re-add (review r2 #2)."""
    ids = resolve_ids(cfg)
    q = (
        "query($id:ID!,$cur:String,$f:String!){node(id:$id){... on ProjectV2{"
        "items(first:100,after:$cur){pageInfo{endCursor hasNextPage}nodes{id "
        "content{... on Issue{number repository{nameWithOwner}}} "
        "fieldValueByName(name:$f){... on ProjectV2ItemFieldSingleSelectValue{name}}}}}}}}"
    )
    base_vars = {"id": ids["project"], "f": cfg["status_field"]}
    cur, issues = None, []
    while True:
        data = _gql(q, dict(base_vars, cur=cur) if cur else base_vars)
        node = data["node"]["items"]
        for item in node["nodes"]:
            content = item.get("content") or {}
            if "number" in content:
                key = (content.get("repository", {}).get("nameWithOwner", "?"), content["number"])
                fv = item.get("fieldValueByName") or {}
                issues.append({
                    "repo": key[0], "num": key[1],
                    "item_id": item.get("id"),
                    "status": fv.get("name"),
                })
        if not node["pageInfo"]["hasNextPage"]:
            break
        cur = node["pageInfo"]["endCursor"]
    state = _load_state()
    state["snapshot"] = {"issues": issues, "fetched_at": int(time.time())}
    _atomic_state_write(state)
    return {(i["repo"], i["num"]): i for i in issues}


def issue_node_id(cfg, num):
    if not cfg.get("repos"):
        raise RuntimeError("no repos configured (board_sync.repos / XYZ_BOARD_SYNC_REPOS)")
    owner_name = cfg["repos"][0].split("/", 1)  # v1: primary repo (multi-repo: Phase 3)
    if len(owner_name) != 2:
        raise RuntimeError(f"repos entry {cfg['repos'][0]!r} is not owner/name")
    data = _gql(
        "query($o:String!,$n:String!,$i:Int!){repository(owner:$o,name:$n){issue(number:$i){id state}}}",
        {"o": owner_name[0], "n": owner_name[1], "i": int(num)},
    )
    repo = data.get("repository") or {}
    issue = repo.get("issue")
    if issue is None:
        raise RuntimeError(f"issue #{num} not found in {cfg['repos'][0]}")
    return issue


def _add_item(cfg, ids, content_id):
    return _gql(
        "mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}",
        {"p": ids["project"], "c": content_id},
    )["addProjectV2ItemById"]["item"]["id"]


def board_add(cfg, num, write, snapshot=None):
    """Add issue + set In progress. Idempotent: check-first (repo-qualified, B-1)
    against the snapshot (fetched when not supplied — reconcile passes one in so N
    candidates cost one pagination, not 2N, review r2 #5). A card that already exists
    with a DIFFERENT status gets a status-only write — the work-start event must not be
    missed just because the card predates it (review r2 #2)."""
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
    return f"gh-{num}: added + Status={cfg['in_progress']!r} on {board_name}"


def _set_status(cfg, ids, item_id):
    _gql(
        "mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(input:{"
        "projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}",
        {"p": ids["project"], "i": item_id, "f": ids["status_field"], "o": ids["in_progress_option"]},
    )


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

    args = ap.parse_args(argv)

    if os.environ.get("XYZ_BOARD_SYNC", "1") == "0":
        print("board_sync: kill-switch XYZ_BOARD_SYNC=0 — no-op")
        return 0

    cfg = resolve_settings()

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
