#!/usr/bin/env python3
"""releases_app.py — GH-32 Phase 0+1: SQLite-backed RELEASES ledger CLI.

PRD: PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md (rev 5, post r1-r4 relay review,
relay-system/2026-08-18/gh32-releases-app-prd-review.md). Where this file and the PRD disagree,
the PRD wins.

Authority split (PRD "Decisions" 1): the DB is authoritative for reads/writes at runtime; the
committed logical dump (releases.sql, global-ID-keyed) is authoritative at git merge boundaries
only. On DB<->dump divergence `releases check` fails and `releases check --rebuild`
(dump -> DB, atomic, with a .bak of the displaced DB) is the one documented recovery. Rebuild is
for MERGE RESOLUTION ONLY, never crash recovery — crash recovery is the per-boundary journal
protocol in perform_write()/recover_from_journal().

HARD BOUNDARY (Phase 0): this tool NEVER writes RELEASES.md. `gen` is side-by-side only — it
writes RELEASES.generated.md plus a drift report. If a code path here can reach RELEASES.md for
writing, that is a bug; the only permitted touch on that file is READING it (import, drift).

RELEASES-PREVIEW.md is the one always-fresh rendered view: it is regenerated inside EVERY write
transaction (same staged-rename protocol as the dump) and opens with a non-source-of-truth
disclaimer. It is a preview of the DB, never the ledger — the hard boundary above is unchanged.

Artifacts (repo root unless noted):
  releases.db                    the SQLite DB (committed per-repo, PRD Decision 2)
  releases.sql                   canonical logical dump (committed, git-mergeable)
  releases.db.bak                backup of a DB displaced by `check --rebuild`
  RELEASES-PREVIEW.md            disclaimer-headed preview, auto-regenerated on every write
  RELEASES.generated.md          side-by-side generated view (Phase 0; gen only)
  RELEASES.generated.md.drift    drift report: generated view vs the real RELEASES.md (gen only)
In the git common-dir (GH-448 idiom — never a literal .git/... path; in a linked worktree .git
is a file):
  releases-app.lock              the repo-scoped writer lock
  releases-app-lock-audit.log    append-only contention sidecar (r4: lock evidence lives OUTSIDE
                                 the DB/dump/digest/generation contract, so a refused writer
                                 never mutates a committed artifact)
  releases-app-journal.json      intent journal; exists only mid-write (crash-recovery input)

Environment:
  RELEASES_APP_SESSION   stable per-dogfood-session id stamped into op_receipts (r3)
  RELEASES_APP_NOW       mocked clock (ISO 8601) for the temp-ref staleness tests
  RELEASES_APP_LOCK_WAIT seconds a busy lock is retried before refusing (default 3)
  RELEASES_APP_CRASH_AT  crash-injection boundary for the recovery negative controls:
                         pre-commit | post-commit | post-stage | mid-rename | post-rename
  RELEASES_APP_EXTRA_DBS colon-separated extra DB paths for `list --all-repos` (the Phase-3
                         cross-repo aggregator reads the hq registry; this is its v1 test surface)

Readers (no lock, no write, safe to run anywhere): `list` (one line per release), `show` (one
full record, by --gid OR --version), `next` (the next unshipped release by target date). Start
with `next` / `show`; drop to raw SQL only for something these three do not answer.

Exit codes: 0 ok; 1 check failure; 2 usage; 3 rule refusal (rule named on stderr);
4 writer-lock refusal; 70 injected crash.
"""

import argparse
import datetime as _dt
import fcntl
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time
import uuid

# ── constants ───────────────────────────────────────────────────────────────────────────────────

APP = "releases-app"

EXIT_OK = 0
EXIT_CHECK_FAILED = 1
EXIT_USAGE = 2
EXIT_REFUSED = 3      # a rule refused the write; stderr names the rule
EXIT_LOCK_REFUSED = 4
EXIT_CRASH_INJECTED = 70

DB_NAME = "releases.db"
DUMP_NAME = "releases.sql"
DB_BAK_NAME = "releases.db.bak"
GEN_NAME = "RELEASES.generated.md"
DRIFT_NAME = "RELEASES.generated.md.drift"
PREVIEW_NAME = "RELEASES-PREVIEW.md"
LEDGER_NAME = "RELEASES.md"          # READ-ONLY for this tool, forever in Phase 0
LOCK_NAME = "releases-app.lock"
AUDIT_NAME = "releases-app-lock-audit.log"
JOURNAL_NAME = "releases-app-journal.json"

# GitHub Projects are a one-way visual projection of this DB.  The immutable Release ID field
# is deliberately the remote idempotency key: we do not add GitHub-owned IDs to the release
# schema, and deleting a card merely lets the next sync recreate its projection.
PROJECT_FIELDS = (
    "Release ID", "Release status", "Target date", "Shipped date", "Codename",
    "Tracking issue", "GitHub release", "Front-door reviewed", "Shakedown reviewed",
    "License file",
)

STATUSES = ("draft", "active", "shipped", "cut")
STATUS_RENDER = {"draft": "Draft", "active": "Active", "shipped": "Shipped", "cut": "Cut"}
MARATHON_STATUSES = ("planned", "running", "done", "escalated", "abandoned")
ITEM_STATES = ("open", "shipped", "cut")
# manifest-state transition legality is CLI-enforced (PRD schema note): open/shipped may move
# between each other and into cut; cut is terminal.
LEGAL_ITEM_TRANSITIONS = {("open", "shipped"), ("open", "cut"),
                          ("shipped", "open"), ("shipped", "cut")}
GH_ISSUE_URL_RE = re.compile(r"^https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+$")
TMP_RE = re.compile(r"^TMP-[A-Z0-9]{6}$")
MIG_RE = re.compile(r"^MIG-[A-Z0-9]{6}$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
URL_EXTRACT_RE = re.compile(r"https://github\.com/[^/\s]+/[^/\s]+/issues/[0-9]+")

# Crockford base32 (PRD GID shape note): every global_id CHECK is the type prefix plus exactly
# 26 characters of [0-9A-HJKMNP-TV-Z], written out in full in the migration so length AND
# alphabet are schema-refused, not convention.
CROCKFORD_GLOB_CLASS = "[0-9A-HJKMNP-TV-Z]"

GENERATION_KEY = "generation"

CRASH_BOUNDARIES = ("pre-commit", "post-commit", "post-stage", "mid-rename", "post-rename")


def _env_float(name, default):
    raw = os.environ.get(name, "")
    try:
        return float(raw) if raw else default
    except ValueError:
        return default


# ── small utilities ─────────────────────────────────────────────────────────────────────────────

def now_iso():
    """Current UTC ISO-8601, mockable via RELEASES_APP_NOW (temp-ref staleness tests)."""
    raw = os.environ.get("RELEASES_APP_NOW", "")
    if raw:
        return raw
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def session_id():
    return os.environ.get("RELEASES_APP_SESSION", "default")


def new_txn_id():
    return uuid.uuid4().hex


def _ulid_body():
    """26 Crockford-base32 chars: 48-bit ms timestamp + 80 random bits (128-bit ULID)."""
    ms = int(time.time() * 1000) & ((1 << 48) - 1)
    rand = int.from_bytes(os.urandom(10), "big")
    value = (ms << 80) | rand
    alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    return "".join(alphabet[(value >> shift) & 0x1F] for shift in range(125, -1, -5))


def new_gid(prefix):
    return "%s%s" % (prefix, _ulid_body())


def warn(rule, detail):
    print("warn: rule=%s: %s" % (rule, detail))


def refuse(rule, detail, code=EXIT_REFUSED):
    print("refused: rule=%s: %s" % (rule, detail), file=sys.stderr)
    sys.exit(code)


def valid_date(s):
    if not DATE_RE.match(s or ""):
        return False
    try:
        _dt.date.fromisoformat(s)
        return True
    except ValueError:
        return False


def sentence_count(text):
    parts = [p for p in re.split(r"(?<=[.!?])\s+", (text or "").strip()) if p.strip()]
    return len(parts)


def _project_value(item, field_name):
    """Read a GH CLI item field across CLI versions that vary its display-key casing."""
    wanted = field_name.casefold()
    for key, value in item.items():
        if str(key).casefold() == wanted:
            return value
    return None


def _gh_json(argv):
    """Run the configured GH CLI and return its JSON output with an actionable failure."""
    gh_bin = os.environ.get("RELEASES_GH_BIN", "gh")
    try:
        completed = subprocess.run([gh_bin] + argv, check=True, text=True,
                                   capture_output=True)
    except FileNotFoundError:
        refuse("github-project-cli",
               "cannot find %r; install GitHub CLI or set RELEASES_GH_BIN" % gh_bin)
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or "GitHub CLI failed").strip()
        refuse("github-project-cli", detail)
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError:
        refuse("github-project-cli-json",
               "GitHub CLI did not return JSON: %s" % completed.stdout.strip())


def _gh_run(argv):
    """Run a mutating GH CLI command and surface its error without masking it."""
    gh_bin = os.environ.get("RELEASES_GH_BIN", "gh")
    try:
        subprocess.run([gh_bin] + argv, check=True, text=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    except FileNotFoundError:
        refuse("github-project-cli",
               "cannot find %r; install GitHub CLI or set RELEASES_GH_BIN" % gh_bin)
    except subprocess.CalledProcessError as exc:
        refuse("github-project-cli", (exc.stderr or "GitHub CLI failed").strip())


def _project_body(release):
    """Render the draft-card body; all GitHub state remains a read-only DB projection."""
    tracking = release["tracking_url"] or release["tracking_temp"] or "—"
    return """## Release

- **Release ID:** `%s`
- **Milestone:** %s
- **Tracking issue:** %s
- **GitHub release:** %s

## Description

%s

## Exit criterion

%s

---

> Read-only projection from `releases.db`. Edit the release through the Releases CLI; GitHub Project edits do not synchronize back.
""" % (release["global_id"], release["milestone"] or "—", tracking,
       release["gh_release_url"] or "—", release["description"],
       release["exit_criterion"] or "Not recorded")


def _project_release_rows(conn):
    return conn.execute("""SELECT r.*, t.url AS tracking_url, t.temp_id AS tracking_temp
                           FROM releases r JOIN issue_refs t ON t.id = r.tracking_ref_id
                           ORDER BY r.target_date IS NULL, r.target_date, r.version""").fetchall()


# ── repo root + GH-448 lock-path resolution ─────────────────────────────────────────────────────

def resolve_root(explicit):
    if explicit:
        return os.path.abspath(explicit)
    try:
        out = subprocess.check_output(["git", "rev-parse", "--show-toplevel"],
                                      stderr=subprocess.DEVNULL).decode().strip()
        if out:
            return os.path.abspath(out)
    except Exception:
        pass
    refuse("not-a-git-repo",
           "releases-app resolves the repo root and its lock through git; run inside the repo "
           "or pass --root (vendored/no-.git layouts are not supported in v1)")


def git_common_dir(root):
    """The GH-448 idiom (see utils/py/rtl.py driver_lock_path): the lock must live at the git
    common-dir, never a literal .git/... path — in a linked worktree .git is a file."""
    git_path = os.path.join(root, ".git")
    if os.path.isdir(git_path):
        return git_path
    if os.path.isfile(git_path):
        try:
            common = subprocess.check_output(
                ["git", "-C", root, "rev-parse", "--path-format=absolute", "--git-common-dir"],
                stderr=subprocess.DEVNULL).decode().strip()
            if common and os.path.isdir(common):
                return common
        except Exception:
            pass
    return None


def state_dir(root):
    common = git_common_dir(root)
    if common is None:
        refuse("not-a-git-repo", "cannot resolve the git common-dir for the lock/journal "
               "(GH-448); a git checkout is required")
    return common


def lock_paths(root):
    common = state_dir(root)
    return (os.path.join(common, LOCK_NAME), os.path.join(common, AUDIT_NAME),
            os.path.join(common, JOURNAL_NAME))


def artifact_paths(root):
    return {
        "db": os.path.join(root, DB_NAME),
        "dump": os.path.join(root, DUMP_NAME),
        "bak": os.path.join(root, DB_BAK_NAME),
        "gen": os.path.join(root, GEN_NAME),
        "drift": os.path.join(root, DRIFT_NAME),
        "preview": os.path.join(root, PREVIEW_NAME),
        "ledger": os.path.join(root, LEDGER_NAME),
    }


# ── lock + audit sidecar ────────────────────────────────────────────────────────────────────────

def audit_log(root, outcome, detail=""):
    """Append-only contention evidence, OUTSIDE the DB (r4 review finding: a refused writer
    inserting into the committed DB would itself be an unlocked write, able to tear the very trio
    it exists to audit). Line shape: <session_id> <timestamp> <outcome> <detail>, outcome in
    acquired|refused|retried|recovered."""
    _, audit_path, _ = lock_paths(root)
    line = "%s %s %s %s\n" % (session_id(), now_iso(), outcome, detail)
    try:
        with open(audit_path, "a", encoding="utf-8") as fh:
            fh.write(line)
    except OSError as exc:
        print("warn: rule=lock-audit: could not append to %s (%s)" % (audit_path, exc))


class WriterLock:
    """Repo-scoped writer lock (PRD Git story 1). Every acquisition attempt is logged to the
    sidecar; a busy lock retries for RELEASES_APP_LOCK_WAIT seconds, then refuses with exit 4 —
    and a refusal changes no committed artifact (that is the r4 negative control)."""

    def __init__(self, root):
        self.root = root
        self.lock_path, _, self.journal_path = lock_paths(root)
        self.fh = None

    def acquire(self):
        wait = _env_float("RELEASES_APP_LOCK_WAIT", 3.0)
        deadline = time.time() + max(wait, 0.0)
        announced_retry = False
        while True:
            self.fh = open(self.lock_path, "a+", encoding="utf-8")
            try:
                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError:
                self.fh.close()
                self.fh = None
                if not announced_retry:
                    audit_log(self.root, "retried", "lock busy; retrying for up to %.0fs" % wait)
                    announced_retry = True
                if time.time() >= deadline:
                    audit_log(self.root, "refused", "lock still busy after %.0fs" % wait)
                    refuse("writer-lock",
                           "another releases-app writer holds %s; refusal recorded in the "
                           "lock-audit sidecar; no committed artifact was changed"
                           % self.lock_path, code=EXIT_LOCK_REFUSED)
                time.sleep(0.1)
                continue
            self.fh.seek(0)
            self.fh.truncate()
            self.fh.write("%s %s %s\n" % (now_iso(), session_id(), os.getpid()))
            self.fh.flush()
            audit_log(self.root, "acquired", "pid %d" % os.getpid())
            return self

    def release(self):
        if self.fh is not None:
            try:
                fcntl.flock(self.fh.fileno(), fcntl.LOCK_UN)
            finally:
                self.fh.close()
                self.fh = None

    def __enter__(self):
        return self.acquire()

    def __exit__(self, *exc):
        self.release()
        return False


# ── DB connection (PRAGMA foreign_keys asserted per connection) ─────────────────────────────────

def connect(db_path, must_exist=True):
    if must_exist and not os.path.exists(db_path):
        refuse("not-initialized", "no %s here; run `releases init` first" % DB_NAME)
    # isolation_level=None: transactions are BEGIN/COMMIT'd explicitly by perform_write, so the
    # intent journal -> COMMIT -> stage -> rename ordering is the ONLY ordering that exists.
    conn = sqlite3.connect(db_path, isolation_level=None)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
        conn.close()
        refuse("foreign-keys-pragma",
               "PRAGMA foreign_keys=ON did not take effect on this connection; refusing to run")
    return conn


def get_setting(conn, key, default=None):
    row = conn.execute("SELECT value FROM settings WHERE key = ?", (key,)).fetchone()
    return row["value"] if row else default


def get_generation(conn):
    try:
        return int(get_setting(conn, GENERATION_KEY, "0"))
    except ValueError:
        return 0


def enforcement_mode(conn):
    return get_setting(conn, "enforcement", "lenient")


# ── migration 001 (v1 schema, PRD "Schema (v1)") ────────────────────────────────────────────────

def _gid_check(column, prefix):
    """Exact-shape global-id CHECK: the type prefix plus exactly 26 characters of the Crockford
    base32 alphabet, written out in full (PRD GID shape note — prefix-only GLOBs were theater)."""
    return "CHECK (%s GLOB '%s%s')" % (column, prefix, CROCKFORD_GLOB_CLASS * 26)


MIGRATION_001 = """
CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE repos (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE {repo_gid},
  slug TEXT NOT NULL UNIQUE CHECK (length(trim(slug)) > 0)
);  -- device-local paths deliberately NOT committed (review finding): the UI resolves local
    -- checkout paths from the utils/hq/ registry, which is already per-device.

CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE {ref_gid},
  url TEXT UNIQUE CHECK (url IS NULL OR url GLOB 'https://github.com/*/issues/*'),
  temp_id TEXT UNIQUE CHECK (temp_id IS NULL OR
    temp_id GLOB 'TMP-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' OR
    temp_id GLOB 'MIG-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'),  -- MIG-: import-only (CLI-enforced)
  created_at TEXT NOT NULL,
  CHECK ((url IS NULL) != (temp_id IS NULL))   -- exactly one
);

CREATE TABLE marathons (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE {mar_gid},
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
  created_at TEXT NOT NULL
);

CREATE TABLE releases (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE {rel_gid},
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  version TEXT CHECK (version IS NULL OR length(trim(version)) > 0),
  codename TEXT,
  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
  target_date TEXT CHECK (target_date IS NULL OR target_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  shipped_date TEXT CHECK (shipped_date IS NULL OR shipped_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
  exit_criterion TEXT,
  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  marathon_id INTEGER REFERENCES marathons(id),
  gh_release_url TEXT,
  milestone TEXT,
  front_door_reviewed TEXT CHECK (front_door_reviewed IN ('Yes','No') OR front_door_reviewed IS NULL),
  shakedown_reviewed  TEXT CHECK (shakedown_reviewed  IN ('Yes','No') OR shakedown_reviewed  IS NULL),
  license_file        TEXT CHECK (license_file        IN ('Yes','No') OR license_file        IS NULL),
  UNIQUE (repo_id, version)
);

CREATE TABLE manifest_items (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE {mfi_gid},
  release_id INTEGER NOT NULL REFERENCES releases(id),
  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
  UNIQUE (release_id, issue_ref_id)
);

CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
  from_state TEXT NOT NULL CHECK (from_state IN ('open','shipped','cut')),
  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','shipped','cut')),
  at TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)   -- a cut without a reason is refused
);
-- Append-only is enforced by triggers, not convention (r2 review finding):
CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
-- (same trigger pair on op_receipts). Transition LEGALITY and the item-state/event coupling are
-- CLI-enforced, stated as such: the CLI updates manifest_items.state and appends the event in ONE
-- transaction; a direct writer that skips the event is caught by the digest chain below, not
-- prevented.

CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
  id INTEGER PRIMARY KEY,              -- preamble is release-less; legacy_lines can't hold it)
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  position INTEGER NOT NULL,           -- ordering among document-level segments
  content TEXT NOT NULL,
  UNIQUE (repo_id, position)
);

CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
  id INTEGER PRIMARY KEY,
  release_id INTEGER NOT NULL REFERENCES releases(id),
  position INTEGER NOT NULL,
  content TEXT NOT NULL,
  disposition TEXT,                    -- NULL = pending; else 'kept'|'migrated'|'dropped:<why>'
  UNIQUE (release_id, position)
);

CREATE TABLE grandfather_entries (     -- r3: referenced throughout but previously never defined
  id INTEGER PRIMARY KEY,
  import_run TEXT NOT NULL,            -- one id per `releases import` invocation
  release_gid TEXT,                    -- NULL for document-level entries
  rule TEXT NOT NULL,                  -- which rule was tolerated/defaulted
  source_value TEXT,                   -- what the legacy file had (NULL = field absent)
  supplied_value TEXT,                 -- what import wrote (default, MIG- ref, normalization)
  disposition TEXT                     -- NULL = pending; strict flip requires none pending
);

CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
  id INTEGER PRIMARY KEY,              -- trigger pair as manifest_state_events)
  op TEXT NOT NULL,
  target_gid TEXT,
  at TEXT NOT NULL,
  txn_id TEXT NOT NULL,                -- one per CLI transaction
  session_id TEXT NOT NULL,            -- r3: stable per-dogfood-session id (env-provided), so the
                                       --   exit gate's ">=2 sessions" is mechanically checkable
  state_digest_before TEXT NOT NULL,   -- sha256 of the BUSINESS-STATE dump (r3: excludes
  state_digest_after TEXT NOT NULL     --   op_receipts, lock_audit, generation, and all digest
);                                     --   fields — the old dump digest was self-referential and
                                       --   uncomputable). Chain rule: each receipt's `before` must
                                       --   equal the previous receipt's `after`; `check` recomputes
                                       --   the current business-state digest and a mismatch with the
                                       --   latest `after` = receipt-less mutation.
CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;
CREATE TRIGGER op_no_delete BEFORE DELETE ON op_receipts
  BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;

CREATE INDEX idx_releases_repo ON releases(repo_id);
CREATE INDEX idx_items_release ON manifest_items(release_id);
CREATE INDEX idx_mse_item ON manifest_state_events(item_id);
CREATE INDEX idx_legacy_release ON legacy_lines(release_id);
CREATE INDEX idx_gf_import ON grandfather_entries(import_run);
""".format(
    repo_gid=_gid_check("global_id", "repo-"),
    ref_gid=_gid_check("global_id", "ref-"),
    mar_gid=_gid_check("global_id", "mar-"),
    rel_gid=_gid_check("global_id", "rel-"),
    mfi_gid=_gid_check("global_id", "mfi-"),
)


def apply_migrations(conn):
    try:
        applied = {r["version"] for r in conn.execute("SELECT version FROM schema_migrations")}
    except sqlite3.OperationalError:
        applied = set()   # fresh DB: the tracker table itself is created by migration 001
    if 1 not in applied:
        conn.executescript(MIGRATION_001)
        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (1, ?)",
                     (now_iso(),))


# ── canonical dump (PRD Git story 6) ────────────────────────────────────────────────────────────
# GID-bearing rows keyed by global_id; non-GID rows by natural key (parent GID / repo slug +
# position / txn_id / the grandfather import_run composite). Integer PKs and FK ids never appear
# as VALUES; row order follows insertion order (stable through merges), and rebuild renumbers
# the integer PKs deterministically in that order. grandfather_entries rows carry an explicit
# `-- gf-key:` comment spelling out the PRD's natural key (import_run + release-gid-or-document
# + rule + source ordinal) — the ordinal is the row's position within its key group, which the
# dump's order preserves. The lock-audit sidecar is not in the dump at all (it is not in the DB).

def _sql_str(value):
    if value is None:
        return "NULL"
    return "'%s'" % str(value).replace("'", "''")


def _rows(conn, sql):
    return [dict(r) for r in conn.execute(sql).fetchall()]


def _emit(w, table, columns, rows):
    if not rows:
        return
    w("-- table: %s" % table)
    for row in rows:
        values = ", ".join(_sql_str(row[c]) for c in columns)
        w("INSERT INTO %s(%s) VALUES(%s);" % (table, ", ".join(columns), values))


def dump_text(conn, generation, include_receipts=True, include_generation=True):
    """Canonical logical dump. include_receipts=False, include_generation=False yields exactly
    the BUSINESS-STATE text the receipt digests hash (r3: excluding op_receipts, generation and
    digest fields keeps the digest computable and non-self-referential)."""
    out = []

    def w(s=""):
        out.append(s)

    w("-- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,")
    w("-- no integer PKs/FKs as values; rebuild renumbers deterministically)")
    if include_generation:
        w("-- generation: %d" % generation)

    _emit(w, "schema_migrations", ["version", "applied_at"],
          _rows(conn, "SELECT version, applied_at FROM schema_migrations ORDER BY version"))

    settings_sql = "SELECT key, value FROM settings"
    if not include_generation:
        settings_sql += " WHERE key != '%s'" % GENERATION_KEY
    _emit(w, "settings", ["key", "value"], _rows(conn, settings_sql + " ORDER BY key"))

    _emit(w, "repos", ["global_id", "slug"],
          _rows(conn, "SELECT global_id, slug FROM repos ORDER BY id"))

    _emit(w, "issue_refs", ["global_id", "url", "temp_id", "created_at"],
          _rows(conn, "SELECT global_id, url, temp_id, created_at FROM issue_refs ORDER BY id"))

    _emit(w, "marathons", ["global_id", "repo_gid", "tracking_ref_gid", "status", "created_at"],
          _rows(conn, """SELECT m.global_id, r.global_id AS repo_gid, t.global_id AS tracking_ref_gid,
                         m.status, m.created_at
                         FROM marathons m JOIN repos r ON r.id = m.repo_id
                         JOIN issue_refs t ON t.id = m.tracking_ref_id ORDER BY m.id"""))

    _emit(w, "releases",
          ["global_id", "repo_gid", "version", "codename", "status", "target_date",
           "shipped_date", "description", "exit_criterion", "tracking_ref_gid", "marathon_gid",
           "gh_release_url", "milestone", "front_door_reviewed", "shakedown_reviewed",
           "license_file"],
          _rows(conn, """SELECT rel.global_id, r.global_id AS repo_gid, rel.version, rel.codename,
                         rel.status, rel.target_date, rel.shipped_date, rel.description,
                         rel.exit_criterion, t.global_id AS tracking_ref_gid,
                         mar.global_id AS marathon_gid, rel.gh_release_url, rel.milestone,
                         rel.front_door_reviewed, rel.shakedown_reviewed, rel.license_file
                         FROM releases rel JOIN repos r ON r.id = rel.repo_id
                         JOIN issue_refs t ON t.id = rel.tracking_ref_id
                         LEFT JOIN marathons mar ON mar.id = rel.marathon_id ORDER BY rel.id"""))

    _emit(w, "manifest_items", ["global_id", "release_gid", "issue_ref_gid", "state"],
          _rows(conn, """SELECT mi.global_id, rel.global_id AS release_gid,
                         t.global_id AS issue_ref_gid, mi.state
                         FROM manifest_items mi JOIN releases rel ON rel.id = mi.release_id
                         JOIN issue_refs t ON t.id = mi.issue_ref_id ORDER BY mi.id"""))

    _emit(w, "manifest_state_events", ["item_gid", "from_state", "to_state", "at", "reason"],
          _rows(conn, """SELECT mi.global_id AS item_gid, e.from_state, e.to_state, e.at, e.reason
                         FROM manifest_state_events e JOIN manifest_items mi ON mi.id = e.item_id
                         ORDER BY e.id"""))

    _emit(w, "doc_lines", ["repo_gid", "position", "content"],
          _rows(conn, """SELECT r.global_id AS repo_gid, d.position, d.content
                         FROM doc_lines d JOIN repos r ON r.id = d.repo_id
                         ORDER BY d.repo_id, d.position"""))

    _emit(w, "legacy_lines", ["release_gid", "position", "content"],
          _rows(conn, """SELECT rel.global_id AS release_gid, l.position, l.content
                         FROM legacy_lines l JOIN releases rel ON rel.id = l.release_id
                         ORDER BY l.release_id, l.position"""))

    gf_rows = _rows(conn, """SELECT g.import_run, COALESCE(g.release_gid, '(document)') AS rgid,
                             g.rule, g.source_value, g.supplied_value, g.disposition, g.id AS _id
                             FROM grandfather_entries g
                             ORDER BY g.import_run, COALESCE(g.release_gid, ''), g.rule, g.id""")
    if gf_rows:
        w("-- table: grandfather_entries (natural key per PRD grammar: import_run + "
          "release_gid-or-(document) + rule + source ordinal)")
        ordinal = {}
        for row in gf_rows:
            key = (row["import_run"], row["rgid"], row["rule"])
            ordinal[key] = ordinal.get(key, 0) + 1
            values = ", ".join(_sql_str(row[c]) for c in
                               ("import_run", "rgid", "rule", "source_value",
                                "supplied_value", "disposition"))
            w("-- gf-key: %s/%s/%s/%d" % (row["import_run"], row["rgid"], row["rule"],
                                           ordinal[key]))
            w("INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value, "
              "supplied_value, disposition) VALUES(%s);" % values)

    if include_receipts:
        _emit(w, "op_receipts",
              ["op", "target_gid", "at", "txn_id", "session_id",
               "state_digest_before", "state_digest_after"],
              _rows(conn, "SELECT op, target_gid, at, txn_id, session_id, state_digest_before, "
                          "state_digest_after FROM op_receipts ORDER BY id"))
    return "\n".join(out) + "\n"


def business_digest(conn):
    text = dump_text(conn, generation=0, include_receipts=False, include_generation=False)
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def dump_generation_from_text(text):
    for line in text.splitlines():
        m = re.match(r"^-- generation: (\d+)$", line.strip())
        if m:
            return int(m.group(1))
    return None


# ── generation marker in the generated file ─────────────────────────────────────────────────────
# The side-by-side generated file carries the marker as an HTML comment on line 1 (the trio
# contract needs it there). The real RELEASES.md never carries one — this tool never writes that
# file, and no header is added during Phase 0 (the header arrives with the Phase 2 flip).

GEN_MARKER_RE = re.compile(r"^<!-- releases-app generation: (\d+) -->$")


def gen_marker(generation):
    return "<!-- releases-app generation: %d -->" % generation


PREVIEW_DISCLAIMER = """\
> **PREVIEW ONLY — NOT the source of truth.** Work-in-progress view auto-generated from
> `releases.db` on every `releases` CLI write. Do not edit this file, cite it as shipped
> history, or resolve conflicts in it — regenerate it. The authoritative artifacts are
> `releases.db` / `releases.sql` (GH-32); `RELEASES.md` remains the human ledger until the
> Phase 2 flip.
"""


def preview_text(conn, generation):
    return "%s\n%s\n%s" % (gen_marker(generation), PREVIEW_DISCLAIMER, render_ledger(conn))


# ── staged writes + crash injection ─────────────────────────────────────────────────────────────

def _crash(boundary):
    if os.environ.get("RELEASES_APP_CRASH_AT", "") == boundary:
        sys.stdout.flush()
        sys.stderr.flush()
        os._exit(EXIT_CRASH_INJECTED)


def _stage_write(final_path, content):
    """Staged temp-name write; the caller renames (atomic) only once the DB commit is durable."""
    tmp = "%s.tmp-%s" % (final_path, new_txn_id()[:12])
    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(content)
        fh.flush()
        os.fsync(fh.fileno())
    return tmp


def _atomic_write(final_path, content):
    tmp = _stage_write(final_path, content)
    os.replace(tmp, final_path)


# ── the writer protocol (PRD Git story 2-3): journal -> txn -> stage -> rename -> clear ─────────

def perform_write(root, conn, op, target_gid, mutate):
    """Run one CLI transaction under the full multi-artifact protocol:

      write intent journal (txn_id, NEXT generation, planned outputs)   [BEFORE the DB commit]
      -> BEGIN IMMEDIATE -> mutate -> stamp generation into settings -> COMMIT
      -> stage dump (+ generated view when one exists), each carrying that generation
      -> atomic renames -> clear journal.

    `mutate(conn)` does the business writes; the op_receipt (before/after business-state digests)
    is appended HERE so no writer can forget it. Recovery per boundary is `check`'s job
    (recover_from_journal); RELEASES_APP_CRASH_AT lands on the five named boundaries. The caller
    must NOT hold the writer lock (this function takes it)."""
    paths = artifact_paths(root)
    lock = WriterLock(root)
    lock.acquire()
    try:
        if os.path.exists(lock.journal_path):
            refuse("journal-live",
                   "an intent journal from an interrupted write exists (%s); run `releases check` "
                   "to recover before writing again" % lock.journal_path)

        generation = get_generation(conn) + 1
        txn_id = new_txn_id()
        planned = [paths["dump"], paths["preview"]]
        if os.path.exists(paths["gen"]):
            planned.append(paths["gen"])

        journal = {
            "app": APP, "txn_id": txn_id, "session_id": session_id(), "op": op,
            "generation": generation, "planned_outputs": planned,
            "db": paths["db"], "started_at": now_iso(),
        }
        _atomic_write(lock.journal_path, json.dumps(journal, indent=2) + "\n")

        digest_before = business_digest(conn)
        conn.execute("BEGIN IMMEDIATE")
        try:
            mutate(conn)
        except BaseException:
            # a refused/mutating error never leaves a live journal behind: the DB rolled back,
            # so there is nothing to recover — clear the journal and re-raise. (An injected
            # crash uses os._exit and deliberately does NOT pass through here.)
            try:
                conn.rollback()
            except sqlite3.Error:
                pass
            try:
                os.unlink(lock.journal_path)
            except OSError:
                pass
            raise
        cur = conn.execute("UPDATE settings SET value = ? WHERE key = ?",
                           (str(generation), GENERATION_KEY))
        if cur.rowcount == 0:
            conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
                         (GENERATION_KEY, str(generation)))
        digest_after = business_digest(conn)
        conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                         state_digest_before, state_digest_after)
                         VALUES (?, ?, ?, ?, ?, ?, ?)""",
                     (op, target_gid, now_iso(), txn_id, session_id(),
                      digest_before, digest_after))
        _crash("pre-commit")
        conn.commit()
        _crash("post-commit")

        staged = [(_stage_write(paths["dump"], dump_text(conn, generation)), paths["dump"]),
                  (_stage_write(paths["preview"], preview_text(conn, generation)),
                   paths["preview"])]
        if os.path.exists(paths["gen"]):
            staged.append((_stage_write(paths["gen"],
                                        gen_marker(generation) + "\n" + render_ledger(conn)),
                           paths["gen"]))
        _crash("post-stage")

        for i, (tmp, final) in enumerate(staged):
            os.replace(tmp, final)
            if i == 0 and len(staged) > 1:
                _crash("mid-rename")
        _crash("post-rename")

        os.unlink(lock.journal_path)
        return txn_id
    finally:
        lock.release()


def recover_from_journal(root, conn):
    """Per-boundary crash recovery (PRD Git story 3), run by `check` (which holds the writer
    lock — this function must not take it again). pre-COMMIT (DB generation < journal's):
    discard stage remnants, clear the journal — the DB never changed. post-COMMIT, any later
    boundary (DB generation == journal's): the DB is truth; REGENERATE the dump and generated
    view from the DB state (staged files, present or missing, are disposable — they are
    derivable), complete the renames, clear the journal — the committed operation is never
    discarded."""
    paths = artifact_paths(root)
    _, _, journal_path = lock_paths(root)
    if not os.path.exists(journal_path):
        return None
    with open(journal_path, encoding="utf-8") as fh:
        journal = json.load(fh)
    txn_id = journal.get("txn_id", "?")
    jgen = int(journal.get("generation", 0))

    # A crash mid-transaction can leave an inert (header-only, never-recognized-hot) sqlite
    # rollback journal behind. Give SQLite the chance to play back a genuinely hot one, then
    # sweep the leftover — we hold the writer lock and know this crash is ours.
    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.rollback()
    except sqlite3.Error:
        pass
    for suffix in ("-journal", "-wal"):
        p = paths["db"] + suffix
        if os.path.exists(p):
            try:
                os.unlink(p)
            except OSError:
                pass

    db_gen = get_generation(conn)

    # stage remnants are disposable on BOTH branches; sweep them first
    for final in journal.get("planned_outputs", []):
        d, base = os.path.split(final)
        try:
            names = os.listdir(d) if os.path.isdir(d) else []
        except OSError:
            names = []
        for name in names:
            if name.startswith(base + ".tmp-"):
                try:
                    os.unlink(os.path.join(d, name))
                except OSError:
                    pass

    if db_gen < jgen:
        os.unlink(journal_path)
        audit_log(root, "recovered",
                  "pre-COMMIT crash discarded (txn %s, gen %d); DB unchanged" % (txn_id, jgen))
        return ("discarded", txn_id)
    if db_gen == jgen:
        _atomic_write(paths["dump"], dump_text(conn, db_gen))
        _atomic_write(paths["preview"], preview_text(conn, db_gen))
        if os.path.exists(paths["gen"]):
            _atomic_write(paths["gen"], gen_marker(db_gen) + "\n" + render_ledger(conn))
        os.unlink(journal_path)
        audit_log(root, "recovered",
                  "post-COMMIT crash completed (txn %s, gen %d); committed operation preserved"
                  % (txn_id, jgen))
        return ("completed", txn_id)
    refuse("recovery-impossible",
           "DB generation %d is ahead of the journal's %d — state is not interpretable; inspect "
           "%s manually" % (db_gen, jgen, journal_path))


# ── legacy RELEASES.md parsing (import + drift) ─────────────────────────────────────────────────

LABEL_RE = re.compile(r"^([A-Za-z][A-Za-z0-9 '&/_-]{0,48}):(?:[ \t](.*))?$")

# Labels the v1 schema maps to columns. Everything else in a block — `Iterations:` bands (absent
# from the schema BY DESIGN, aegis proved them harmful), `Manifest:` prose, `RC evidence:`,
# `Post RC update:`, ad-hoc labels, and continuation paragraphs — is preserved VERBATIM, in
# order, in legacy_lines until dispositioned. `Manifest-Members:` bare numbers stay legacy too:
# they cannot be auto-converted to URLs offline (the rebalanceOS retired-tracker case is the
# reason), and each becomes a grandfather entry awaiting disposition.
MAPPED_LABELS = {
    "Release", "Status", "Target Date", "Codename", "Description", "Exit criterion",
    "GH_URL", "Milestone", "Front-door reviewed", "Shakedown reviewed", "License file",
    "Shipped", "Tracking Issue",
}
UNMAPPED_LABELS = {"Iterations", "Manifest", "Manifest-Members", "RC evidence", "Post RC update"}


def parse_legacy_ledger(path):
    """Parse a RELEASES.md-format ledger. Returns (doc_lines, blocks): doc_lines is the verbatim
    preamble (everything before the first `Release:` line); each block carries its mapped field
    values (LAST occurrence wins, matching the awk consumers) and its extras — unmapped label
    lines and continuation lines, verbatim, with their original line numbers as ordering."""
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    doc, blocks = [], []
    current = None
    for idx, raw in enumerate(lines):
        line = raw.rstrip("\r")
        if line.startswith("Release:"):
            current = {"line": idx, "fields": {}, "extras": []}
            current["fields"]["Release"] = [(line[len("Release:"):].strip())]
            blocks.append(current)
            continue
        if current is None:
            doc.append(line)
            continue
        m = LABEL_RE.match(line)
        label = m.group(1).strip() if m else None
        if m and label in MAPPED_LABELS:
            current["fields"].setdefault(label, []).append(m.group(2) or "")
            if label != "Shipped":
                continue
            # Shipped keeps its whole prose line verbatim alongside the extracted date
            current["extras"].append((idx, line))
            continue
        if m and label in UNMAPPED_LABELS:
            current["extras"].append((idx, line))
            continue
        if m:
            current["extras"].append((idx, line))   # unknown ad-hoc label
            continue
        if not line.strip():
            continue                                 # block separator; renderer emits its own
        current["extras"].append((idx, line))        # continuation paragraph
    return doc, blocks


def _normalize_status(raw):
    low = (raw or "").strip().lower()
    if low in STATUSES:
        return low, False
    return "active", True


# ── generator: the pinned normalized rendering (PRD Generator contract) ─────────────────────────
# Canonical field order and spellings are defined HERE, once. Consumers parse fields, not bytes;
# lossless preservation lives in doc_lines/legacy_lines, both re-rendered verbatim in order until
# dispositioned. `Manifest-Members:` is generated from manifest_items when they exist (imported
# bare numbers stay in legacy_lines verbatim instead). `Status: Shipped` normalizes to the enum;
# the generator renders the canonical capitalized spelling.

def render_ledger(conn):
    out = []

    def w(s=""):
        out.append(s)

    for row in conn.execute("""SELECT d.content FROM doc_lines d JOIN repos r ON r.id = d.repo_id
                               ORDER BY d.repo_id, d.position"""):
        w(row["content"])

    first = True
    for rel in conn.execute("""SELECT rel.*, t.url AS tracking_url, t.temp_id AS tracking_temp
                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
                               ORDER BY rel.id""").fetchall():
        if not first:
            w()
        first = False
        w("Release: %s" % (rel["version"] if rel["version"] else "(unversioned)"))
        w("Status: %s" % STATUS_RENDER[rel["status"]])
        if rel["shipped_date"]:
            w("Shipped: %s" % rel["shipped_date"])
        if rel["target_date"]:
            w("Target Date: %s" % rel["target_date"])
        if rel["codename"]:
            w("Codename: %s" % rel["codename"])
        if rel["description"]:
            w("Description: %s" % rel["description"])
        if rel["exit_criterion"]:
            w("Exit criterion: %s" % rel["exit_criterion"])
        members = conn.execute("""SELECT t.url, t.temp_id FROM manifest_items mi
                                  JOIN issue_refs t ON t.id = mi.issue_ref_id
                                  WHERE mi.release_id = ? ORDER BY mi.id""",
                               (rel["id"],)).fetchall()
        if members:
            nums = [ (m["url"] or "").rsplit("/", 1)[-1] or (m["temp_id"] or "?") for m in members ]
            w("Manifest-Members: %s" % " ".join(nums))
        if rel["gh_release_url"]:
            w("GH_URL: %s" % rel["gh_release_url"])
        if rel["tracking_url"]:
            w("Tracking Issue: %s" % rel["tracking_url"])
        elif rel["tracking_temp"]:
            w("Tracking Issue: %s" % rel["tracking_temp"])
        if rel["milestone"]:
            w("Milestone: %s" % rel["milestone"])
        if rel["front_door_reviewed"]:
            w("Front-door reviewed: %s" % rel["front_door_reviewed"])
        if rel["shakedown_reviewed"]:
            w("Shakedown reviewed: %s" % rel["shakedown_reviewed"])
        if rel["license_file"]:
            w("License file: %s" % rel["license_file"])
        for ll in conn.execute("""SELECT content FROM legacy_lines l
                                  WHERE l.release_id = ? ORDER BY l.position""",
                               (rel["id"],)).fetchall():
            w(ll["content"])
    return "\n".join(out) + "\n"


def write_drift_report(root, conn):
    """Side-by-side drift report (Phase 0 sole-writer evidence): compares the DB-backed view
    against the real RELEASES.md. A hand-edit during the measured window is visible here, and
    each one resets the sole-writer clock (PRD Phase 0). A stale real file after CLI writes is
    EXPECTED in Phase 0 — the flip is Phase 2 — so direction matters and is labeled."""
    paths = artifact_paths(root)
    lines = ["releases-app drift report (GH-32 Phase 0, side-by-side)",
             "generated: %s" % now_iso(),
             "real ledger: %s (READ-ONLY — never written by this tool)" % paths["ledger"],
             ""]
    if not os.path.exists(paths["ledger"]):
        lines.append("no real RELEASES.md present — nothing to drift against")
        _atomic_write(paths["drift"], "\n".join(lines) + "\n")
        return
    doc, blocks = parse_legacy_ledger(paths["ledger"])
    db_rows = {r["version"]: r for r in conn.execute("SELECT * FROM releases ORDER BY id")}
    db_versions = set(db_rows)
    file_versions = {b["fields"]["Release"][0] for b in blocks if b["fields"].get("Release")}

    hand_edits = 0
    only_db = sorted(v for v in (db_versions - file_versions) if v)
    only_file = sorted(v for v in (file_versions - db_versions) if v)
    if only_db:
        lines.append("[stale-file] in the DB but not in RELEASES.md (expected after CLI writes; "
                     "the real file is refreshed only at the Phase 2 flip): %s"
                     % ", ".join(only_db))
    if only_file:
        hand_edits += len(only_file)
        lines.append("[hand-edit] blocks in RELEASES.md with no DB counterpart: %s"
                     % ", ".join(only_file))
    for b in blocks:
        version = b["fields"].get("Release", [None])[0]
        if version not in db_rows:
            continue
        row = db_rows[version]
        f = b["fields"]

        def fv(label):
            vals = f.get(label, [])
            return vals[-1] if vals else None

        status, _ = _normalize_status(fv("Status") or "")
        for label, file_val, db_val in (
                ("Status", status, row["status"]),
                ("Codename", fv("Codename"), row["codename"]),
                ("Target Date", fv("Target Date"), row["target_date"]),
                ("Description", fv("Description"), row["description"]),
                ("Milestone", fv("Milestone"), row["milestone"])):
            if (file_val or "") != (db_val or ""):
                hand_edits += 1
                lines.append("[drift] Release %s: %s is %r in the file, %r in the DB "
                             "(file edited by hand, or stale after a CLI write)"
                             % (version, label, file_val, db_val))
    lines.append("")
    lines.append("summary: %d file-only block(s), %d field-level difference(s). File-only blocks "
                 "and unexpected field drift are hand-edits — each resets the Phase 0 "
                 "sole-writer clock. Stale-after-CLI directions do not." % (len(only_file),
                                                                            hand_edits))
    _atomic_write(paths["drift"], "\n".join(lines) + "\n")


# ── structural validation (refused in BOTH modes — lenient tolerates imported legacy debt,
#    never new corruption) and GH-28 thresholds (strict: refuse / lenient: warn and write) ───────

def check_tracking_token(token, allow_mig=False):
    """Returns ('url', url) or ('temp', temp_id); refuses otherwise, naming the rule."""
    token = (token or "").strip()
    if not token:
        refuse("tracking-required",
               "every release/marathon requires a tracking GH issue (SOP 1/2): pass an issue "
               "URL or a TMP-XXXXXX offline placeholder")
    if GH_ISSUE_URL_RE.match(token):
        return ("url", token)
    if TMP_RE.match(token):
        return ("temp", token)
    if MIG_RE.match(token):
        if allow_mig:
            return ("temp", token)
        refuse("mig-import-only",
               "MIG-XXXXXX placeholders are import-only (migration debt, distinct from the "
               "GitHub-down TMP- fallback); disposition them via `releases reconcile`")
    refuse("issue-url-shape",
           "tracking reference %r must be https://github.com/<org>/<repo>/issues/<n> or "
           "TMP-XXXXXX" % token)


def issue_ref_for_token(conn, token, allow_mig=False):
    """Find or create the issue_refs row for a URL/TMP-/MIG- token (identity is the row, so
    re-adding an existing URL reuses it)."""
    kind, value = check_tracking_token(token, allow_mig=allow_mig)
    col, other = ("url", "temp_id") if kind == "url" else ("temp_id", "url")
    row = conn.execute("SELECT * FROM issue_refs WHERE %s = ?" % col, (value,)).fetchone()
    if row:
        return row
    gid = new_gid("ref-")
    conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) "
                 "VALUES (?, ?, ?, ?)",
                 (gid, value if kind == "url" else None,
                  value if kind == "temp" else None, now_iso()))
    return conn.execute("SELECT * FROM issue_refs WHERE global_id = ?", (gid,)).fetchone()


def validate_release_fields(conn, mode, *, version=None, status=None, target_date=None,
                            shipped_date=None, description=None, exit_criterion=None,
                            editing_gid=None):
    """Structural rules refuse in both modes; GH-28 thresholds (new/edited rows only) refuse in
    strict and warn-and-write in lenient. Every refusal and warning names its rule. `version` is
    the EFFECTIVE version (new or current-when-editing) so uniqueness covers updates too."""
    if status is not None and status not in STATUSES:
        refuse("enum-status", "status %r must be one of %s" % (status, "|".join(STATUSES)))
    if version is not None and not version.strip():
        refuse("version-nonempty", "version must be non-empty when present")
    for name, value in (("target_date", target_date), ("shipped_date", shipped_date)):
        if value is not None and not valid_date(value):
            refuse("date-shape", "%s %r must be a valid YYYY-MM-DD calendar date" % (name, value))
    if description is not None and not description.strip():
        refuse("description-nonempty", "description must be non-empty")
    if version is not None:
        q = "SELECT global_id FROM releases WHERE version = ?"
        args = [version]
        if editing_gid:
            q += " AND global_id != ?"
            args.append(editing_gid)
        if conn.execute(q, args).fetchone():
            refuse("version-uniqueness",
                   "version %r already exists in this repo (structural: UNIQUE(repo_id, version) "
                   "is refused in both modes)" % version)
    if description is not None and sentence_count(description) > 4:
        msg = "description is %d sentences; GH-28 threshold is <= 4" % sentence_count(description)
        if mode == "strict":
            refuse("description-length", msg + " (strict mode refuses)")
        warn("description-length", msg + " (lenient mode: warned and written)")
    if exit_criterion is not None and len(exit_criterion) > 1000:
        msg = "exit criterion is %d chars; GH-28 threshold is ~1000" % len(exit_criterion)
        if mode == "strict":
            refuse("exit-criterion-length", msg + " (strict mode refuses)")
        warn("exit-criterion-length", msg + " (lenient mode: warned and written)")


def find_release(conn, gid):
    row = conn.execute("SELECT * FROM releases WHERE global_id = ?", (gid,)).fetchone()
    if not row:
        refuse("unknown-gid", "no release with global id %r" % gid)
    return row


def _qa(value):
    return value if value in ("Yes", "No") else None


# ── commands ────────────────────────────────────────────────────────────────────────────────────

def cmd_init(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    if os.path.exists(paths["db"]):
        refuse("already-initialized", "%s already exists here" % DB_NAME)
    slug = args.slug or os.path.basename(os.path.normpath(root))
    lock = WriterLock(root)
    lock.acquire()
    try:
        conn = connect(paths["db"], must_exist=False)
        try:
            apply_migrations(conn)
            conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
                         (new_gid("repo-"), slug))
            conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
            conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', ?)", (slug,))
            conn.execute("INSERT INTO settings(key, value) VALUES (?, '1')", (GENERATION_KEY,))
            generation = get_generation(conn)
            _atomic_write(paths["dump"], dump_text(conn, generation))
            _atomic_write(paths["preview"], preview_text(conn, generation))
        finally:
            conn.close()
    finally:
        lock.release()
    print("initialized %s (slug %r, enforcement=lenient, generation 1); canonical dump at %s"
          % (paths["db"], slug, paths["dump"]))


def _grandfather(conn, import_run, release_gid, rule, source_value, supplied_value):
    conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
                     supplied_value, disposition) VALUES (?, ?, ?, ?, ?, NULL)""",
                 (import_run, release_gid, rule, source_value, supplied_value))


def cmd_import(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        if conn.execute("SELECT COUNT(*) c FROM releases").fetchone()["c"]:
            refuse("import-once",
                   "this DB already holds releases; the legacy import is ONE-SHOT (PRD Phase 0) "
                   "— diverge via the dump merge procedure, not re-import")
        ledger = args.file or paths["ledger"]
        if not os.path.exists(ledger):
            refuse("import-source-missing", "no ledger file at %s" % ledger)
        doc_lines, blocks = parse_legacy_ledger(ledger)
        repo = conn.execute("SELECT * FROM repos ORDER BY id LIMIT 1").fetchone()
        import_run = "imp-%s-%s" % (_dt.datetime.now(_dt.timezone.utc).strftime("%Y%m%dT%H%M%S"),
                                    uuid.uuid4().hex[:6])

        def mutate(conn):
            for pos, content in enumerate(doc_lines):
                conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)",
                             (repo["id"], pos, content))
            for block in blocks:
                f = block["fields"]

                def fv(label):
                    vals = f.get(label, [])
                    return vals[-1] if vals else None

                version = (fv("Release") or "").strip()
                if not version:
                    refuse("release-value", "a block's Release: value is empty (malformed ledger)")
                gid = new_gid("rel-")

                status_raw = fv("Status")
                if not status_raw:
                    status = "draft"
                    _grandfather(conn, import_run, gid, "status-default", None, "draft")
                else:
                    status, normalized = _normalize_status(status_raw)
                    if normalized:
                        _grandfather(conn, import_run, gid, "status-enum", status_raw, status)

                description = fv("Description")
                if not (description or "").strip():
                    description = "(imported without a Description; legacy block omitted it)"
                    _grandfather(conn, import_run, gid, "description-default", None, description)

                raw_target = fv("Target Date")
                target_date = None
                if raw_target is not None and raw_target.strip():
                    if valid_date(raw_target.strip()):
                        target_date = raw_target.strip()
                    else:
                        _grandfather(conn, import_run, gid, "target-date-invalid", raw_target, None)
                        block["extras"].append((block["line"], "Target Date: %s" % raw_target))

                gh_raw = fv("GH_URL")
                gh_release_url = None
                if gh_raw and gh_raw.strip():
                    m = URL_EXTRACT_RE.search(gh_raw)
                    if m:
                        gh_release_url = m.group(0)
                        if gh_release_url != gh_raw.strip():
                            _grandfather(conn, import_run, gid, "gh-url-normalized", gh_raw,
                                         gh_release_url)
                    else:
                        _grandfather(conn, import_run, gid, "gh-url-unparsed", gh_raw, None)

                qa = {}
                for label, column in (("Front-door reviewed", "front_door_reviewed"),
                                      ("Shakedown reviewed", "shakedown_reviewed"),
                                      ("License file", "license_file")):
                    val = fv(label)
                    if val in ("Yes", "No"):
                        qa[column] = val
                    elif val and val.strip():
                        _grandfather(conn, import_run, gid, "qa-invalid",
                                     "%s: %s" % (label, val), None)

                shipped_date = None
                for ln, text in sorted(block["extras"], key=lambda e: e[0]):
                    if text.startswith("Shipped:"):
                        m = re.match(r"(\d{4}-\d{2}-\d{2})", text[len("Shipped:"):].strip())
                        if m and valid_date(m.group(1)):
                            shipped_date = m.group(1)
                            _grandfather(conn, import_run, gid, "shipped-prose-extracted",
                                         text, shipped_date)
                        else:
                            _grandfather(conn, import_run, gid, "shipped-unparsed", text, None)
                        break

                for ln, text in block["extras"]:
                    if text.startswith("Manifest-Members:"):
                        _grandfather(conn, import_run, gid, "manifest-bare-numbers", text, None)

                tracking_raw = fv("Tracking Issue")
                if tracking_raw and GH_ISSUE_URL_RE.match(tracking_raw.strip()):
                    ref = issue_ref_for_token(conn, tracking_raw.strip())
                else:
                    # SOP 1 postdates every legacy block: import — and ONLY import — may create
                    # MIG-XXXXXX placeholders, each recorded here (r2 review finding).
                    mig = "MIG-" + uuid.uuid4().hex[:6].upper()
                    ref = issue_ref_for_token(conn, mig, allow_mig=True)
                    _grandfather(conn, import_run, gid, "tracking-issue-missing", tracking_raw,
                                 mig)

                codename = fv("Codename")
                exit_criterion = fv("Exit criterion")
                milestone = fv("Milestone")

                # GH-28 thresholds on legacy rows are grandfathered (tolerated + tracked), not
                # warned-and-written: the debt IS the record.
                if sentence_count(description) > 4:
                    _grandfather(conn, import_run, gid, "description-length",
                                 description[:80] + ("..." if len(description) > 80 else ""), None)
                if exit_criterion and len(exit_criterion) > 1000:
                    _grandfather(conn, import_run, gid, "exit-criterion-length",
                                 "%d chars" % len(exit_criterion), None)
                if conn.execute("SELECT 1 FROM releases WHERE version = ?", (version,)).fetchone():
                    refuse("version-uniqueness",
                           "duplicate Release: %r in the legacy ledger (structural)" % version)

                conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
                             target_date, shipped_date, description, exit_criterion,
                             tracking_ref_id, marathon_id, gh_release_url, milestone,
                             front_door_reviewed, shakedown_reviewed, license_file)
                             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?, ?, ?, ?)""",
                             (gid, repo["id"], version, codename, status, target_date,
                              shipped_date, description, exit_criterion, ref["id"],
                              gh_release_url, milestone, qa.get("front_door_reviewed"),
                              qa.get("shakedown_reviewed"), qa.get("license_file")))
                rel_id = conn.execute("SELECT id FROM releases WHERE global_id = ?",
                                      (gid,)).fetchone()["id"]
                for ln, text in sorted(block["extras"], key=lambda e: e[0]):
                    conn.execute("""INSERT INTO legacy_lines(release_id, position, content,
                                 disposition) VALUES (?, ?, ?, NULL)""", (rel_id, ln, text))

        txn = perform_write(root, conn, "import", None, mutate)
        gf = conn.execute("SELECT COUNT(*) c FROM grandfather_entries").fetchone()["c"]
        ll = conn.execute("SELECT COUNT(*) c FROM legacy_lines").fetchone()["c"]
        dl = conn.execute("SELECT COUNT(*) c FROM doc_lines").fetchone()["c"]
        print("imported %d block(s) from %s (txn %s): %d doc_lines, %d legacy_lines, "
              "%d grandfather_entries pending disposition"
              % (len(blocks), ledger, txn[:12], dl, ll, gf))
    finally:
        conn.close()


def cmd_add(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        mode = enforcement_mode(conn)
        validate_release_fields(conn, mode, version=args.version, status=args.status,
                                target_date=args.target_date, shipped_date=args.shipped_date,
                                description=args.description, exit_criterion=args.exit_criterion)
        gid = new_gid("rel-")

        def mutate(conn):
            ref = issue_ref_for_token(conn, args.tracking_issue)
            marathon_id = None
            if args.marathon:
                row = conn.execute("SELECT id FROM marathons WHERE global_id = ?",
                                   (args.marathon,)).fetchone()
                if not row:
                    refuse("unknown-gid", "no marathon with global id %r" % args.marathon)
                marathon_id = row["id"]
            conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
                         target_date, shipped_date, description, exit_criterion, tracking_ref_id,
                         marathon_id, gh_release_url, milestone, front_door_reviewed,
                         shakedown_reviewed, license_file)
                         VALUES (?, (SELECT id FROM repos ORDER BY id LIMIT 1), ?, ?, ?, ?, ?, ?, ?,
                                 ?, ?, ?, ?, ?, ?, ?)""",
                         (gid, args.version, args.codename, args.status, args.target_date,
                          args.shipped_date, args.description, args.exit_criterion, ref["id"],
                          marathon_id, args.gh_release_url, args.milestone,
                          _qa(args.front_door), _qa(args.shakedown), _qa(args.license)))
            print("added release %s (version %s, status %s)" % (gid, args.version, args.status))

        perform_write(root, conn, "add", gid, mutate)
    finally:
        conn.close()


def cmd_update(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        row = find_release(conn, args.gid)
        mode = enforcement_mode(conn)
        if args.tracking_issue is not None:
            refuse("tracking-ref-immutable",
                   "a release's tracking reference keeps its identity; fill the real URL with "
                   "`releases reconcile --map` (the TMP-/MIG- lifecycle), never by replacing it")
        eff_version = args.version if args.version is not None else row["version"]
        validate_release_fields(conn, mode, version=eff_version,
                                status=args.status, target_date=args.target_date,
                                shipped_date=args.shipped_date, description=args.description,
                                exit_criterion=args.exit_criterion, editing_gid=args.gid)

        def mutate(conn):
            conn.execute("""UPDATE releases SET version=?, codename=?, status=?, target_date=?,
                         shipped_date=?, description=?, exit_criterion=?, gh_release_url=?,
                         milestone=?, front_door_reviewed=?, shakedown_reviewed=?, license_file=?
                         WHERE global_id=?""",
                         (eff_version,
                          args.codename if args.codename is not None else row["codename"],
                          args.status if args.status is not None else row["status"],
                          args.target_date if args.target_date is not None else row["target_date"],
                          args.shipped_date if args.shipped_date is not None else row["shipped_date"],
                          args.description if args.description is not None else row["description"],
                          args.exit_criterion if args.exit_criterion is not None
                          else row["exit_criterion"],
                          args.gh_release_url if args.gh_release_url is not None
                          else row["gh_release_url"],
                          args.milestone if args.milestone is not None else row["milestone"],
                          _qa(args.front_door) if args.front_door is not None
                          else row["front_door_reviewed"],
                          _qa(args.shakedown) if args.shakedown is not None
                          else row["shakedown_reviewed"],
                          _qa(args.license) if args.license is not None
                          else row["license_file"],
                          args.gid))
            print("updated release %s" % args.gid)

        perform_write(root, conn, "update", args.gid, mutate)
    finally:
        conn.close()


def cmd_ship(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        row = find_release(conn, args.gid)
        evidence = (args.evidence or "").strip()
        if not evidence:
            refuse("ship-needs-evidence",
                   "shipping requires --evidence citing the exit-criterion run (structural, "
                   "both modes)")
        if row["status"] not in ("draft", "active"):
            refuse("transition",
                   "cannot ship a release in status %r (legal: draft|active -> shipped); "
                   "transition legality is CLI-enforced" % row["status"])
        when = args.date or now_iso()[:10]
        if not valid_date(when):
            refuse("date-shape", "--date %r must be a valid YYYY-MM-DD calendar date" % when)

        def mutate(conn):
            conn.execute("UPDATE releases SET status='shipped', shipped_date=? WHERE global_id=?",
                         (when, args.gid))
            # The evidence citation rides in the append-only audit trail (the schema has no
            # evidence column by design): a ship-evidence receipt in the SAME transaction as the
            # status flip. check()'s chain rule skips op='ship-evidence' rows.
            conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                         state_digest_before, state_digest_after)
                         VALUES ('ship-evidence', ?, ?, ?, ?, '', '')""",
                         (args.gid, "evidence: %s" % evidence, new_txn_id(), session_id()))
            print("shipped %s on %s (evidence recorded in the op_receipts audit trail)"
                  % (args.gid, when))

        perform_write(root, conn, "ship", args.gid, mutate)
    finally:
        conn.close()


def cmd_manifest_add(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        rel = find_release(conn, args.gid)
        gid = new_gid("mfi-")

        def mutate(conn):
            ref = issue_ref_for_token(conn, args.issue)
            if conn.execute("""SELECT 1 FROM manifest_items
                               WHERE release_id=? AND issue_ref_id=?""",
                            (rel["id"], ref["id"])).fetchone():
                refuse("manifest-duplicate",
                       "issue already in this release's manifest (UNIQUE(release_id, "
                       "issue_ref_id), refused in both modes)")
            shared = conn.execute("""SELECT r.global_id FROM manifest_items mi
                                     JOIN releases r ON r.id = mi.release_id
                                     WHERE mi.issue_ref_id = ? AND mi.release_id != ?
                                       AND mi.state != 'cut'""",
                                  (ref["id"], rel["id"])).fetchall()
            if shared:
                warn("shared-manifest-issue",
                     "issue also sits in non-cut release(s) %s — warn, never refuse (handoffs "
                     "are legitimate; the Meter->Sundown transfer is the recorded precedent)"
                     % ", ".join(s["global_id"] for s in shared))
            conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state)
                         VALUES (?, ?, ?, 'open')""", (gid, rel["id"], ref["id"]))
            print("manifest item %s added to %s (state=open)" % (gid, args.gid))

        perform_write(root, conn, "manifest-add", gid, mutate)
    finally:
        conn.close()


def cmd_manifest_cut(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        rel = find_release(conn, args.gid)
        reason = (args.reason or "").strip()
        if not reason:
            refuse("cut-needs-reason",
                   "a manifest cut without a reason is refused (structural, both modes)")
        kind, value = check_tracking_token(args.issue)

        def mutate(conn):
            if kind == "url":
                ref = conn.execute("SELECT * FROM issue_refs WHERE url = ?", (value,)).fetchone()
            else:
                ref = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
                                   (value,)).fetchone()
            if not ref:
                refuse("unknown-issue", "no issue_refs row for %r" % value)
            item = conn.execute("""SELECT * FROM manifest_items
                                   WHERE release_id=? AND issue_ref_id=?""",
                                (rel["id"], ref["id"])).fetchone()
            if not item:
                refuse("unknown-issue",
                       "issue %r is not in release %s's manifest" % (value, args.gid))
            if (item["state"], "cut") not in LEGAL_ITEM_TRANSITIONS:
                refuse("transition",
                       "cannot cut an item in state %r (cut is terminal; legality is "
                       "CLI-enforced)" % item["state"])
            conn.execute("UPDATE manifest_items SET state='cut' WHERE id=?", (item["id"],))
            # item state and its event land in ONE transaction (PRD: the coupling is
            # CLI-enforced; a direct writer that skips the event is caught by the digest chain)
            conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at,
                         reason) VALUES (?, ?, 'cut', ?, ?)""",
                         (item["id"], item["state"], now_iso(), reason))
            print("manifest item %s cut (%s -> cut); re-scope event appended"
                  % (item["global_id"], item["state"]))

        perform_write(root, conn, "manifest-cut", args.gid, mutate)
    finally:
        conn.close()


def cmd_marathon_add(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    try:
        gid = new_gid("mar-")

        def mutate(conn):
            ref = issue_ref_for_token(conn, args.tracking_issue)
            repo_id = conn.execute("SELECT id FROM repos ORDER BY id LIMIT 1").fetchone()["id"]
            conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
                         created_at) VALUES (?, ?, ?, ?, ?)""",
                         (gid, repo_id, ref["id"], args.status, now_iso()))
            print("marathon %s added (status %s)" % (gid, args.status))

        perform_write(root, conn, "marathon-add", gid, mutate)
    finally:
        conn.close()


def cmd_marathon_list(args):
    root = resolve_root(args.root)
    conn = connect(artifact_paths(root)["db"])
    try:
        for row in conn.execute("""SELECT m.global_id, m.status, m.created_at, t.url, t.temp_id
                                   FROM marathons m JOIN issue_refs t ON t.id = m.tracking_ref_id
                                   ORDER BY m.id"""):
            print("%s  %-9s  %s  %s" % (row["global_id"], row["status"], row["created_at"],
                                        row["url"] or row["temp_id"]))
    finally:
        conn.close()


def _repo_label(path):
    return os.path.basename(os.path.normpath(path))


def _aggregate_all_repos(root, conn):
    """v1 aggregation surface: this DB plus RELEASES_APP_EXTRA_DBS (colon-separated). The
    Phase-3 cockpit card reads the hq registry instead; until then this is the testable reader.
    Duplicate global IDs across DBs fail the aggregation LOUDLY, never merge silently (PRD)."""
    extra = [p for p in os.environ.get("RELEASES_APP_EXTRA_DBS", "").split(":") if p]
    seen = {}
    for r in conn.execute("SELECT global_id FROM releases"):
        seen.setdefault(r["global_id"], set()).add(_repo_label(root))
    for db_path in extra:
        if not os.path.exists(db_path):
            refuse("extra-db-missing", "RELEASES_APP_EXTRA_DBS entry %s does not exist" % db_path)
        econn = connect(db_path)
        try:
            for r in econn.execute("SELECT global_id FROM releases"):
                seen.setdefault(r["global_id"], set()).add(_repo_label(os.path.dirname(db_path)))
        finally:
            econn.close()
    dups = {g: locs for g, locs in seen.items() if len(locs) > 1}
    # cross-repo codename duplication warns, never refuses — the survey's "Silverlining in two
    # repos" case. Emitted before the duplicate-GID exit so a failing aggregation still carries
    # its warnings.
    names = {}
    for db_path in [None] + extra:
        c = conn if db_path is None else connect(db_path)
        try:
            for r in c.execute("SELECT codename FROM releases WHERE codename IS NOT NULL"):
                names.setdefault((r["codename"] or "").strip().lower(), set()).add(
                    _repo_label(root if db_path is None else os.path.dirname(db_path)))
        finally:
            if db_path is not None:
                c.close()
    for name, locs in sorted(names.items()):
        if len(locs) > 1:
            warn("cross-repo-codename",
                 "codename %r appears in %s (warn, never refuse — the survey's copy-paste case)"
                 % (name, ", ".join(sorted(locs))))
    if dups:
        for gid, locs in sorted(dups.items()):
            print("FAIL: rule=duplicate-gid: %s appears in %s" % (gid, ", ".join(sorted(locs))))
        sys.exit(EXIT_CHECK_FAILED)
    print("aggregated %d release gid(s) across %d repo DB(s); no duplicate global IDs"
          % (len(seen), 1 + len(extra)))


def cmd_list(args):
    root = resolve_root(args.root)
    conn = connect(artifact_paths(root)["db"])
    try:
        rows = conn.execute("""SELECT rel.global_id, rel.version, rel.codename, rel.status,
                                      rel.target_date, rel.shipped_date, t.url, t.temp_id,
                                      (SELECT COUNT(*) FROM manifest_items mi
                                       WHERE mi.release_id = rel.id) AS items
                               FROM releases rel JOIN issue_refs t ON t.id = rel.tracking_ref_id
                               ORDER BY rel.id""").fetchall()
        if args.status:
            rows = [r for r in rows if r["status"] == args.status]
        for r in rows:
            print("%s  %-8s %-12s %-8s target=%s shipped=%s tracking=%s items=%d" % (
                r["global_id"], r["version"] or "-", r["codename"] or "-", r["status"],
                r["target_date"] or "-", r["shipped_date"] or "-", r["url"] or r["temp_id"],
                r["items"]))
        if args.all_repos:
            _aggregate_all_repos(root, conn)
    finally:
        conn.close()


def _resolve_one(conn, gid=None, version=None):
    """Reader-side lookup by GID or version. Readers accept either so an agent that only knows
    '0.6.0' does not need a separate lookup round-trip first."""
    if bool(gid) == bool(version):
        refuse("selector", "pass exactly one of --gid or --version")
    if gid:
        return find_release(conn, gid)
    row = conn.execute("SELECT * FROM releases WHERE version = ?", (version,)).fetchone()
    if row is None:
        refuse("unknown-version", "no release with version %r in this repo" % version)
    return row


SHOW_ELIDE = 240   # imported legacy prose runs to thousands of chars; orientation needs the head


def _elide(text, full):
    """Long values are elided by DEFAULT: this reader exists for fast orientation, and an
    imported description can run past 3,000 characters. --full prints verbatim. The elision
    always states the true length so a reader knows what it is not seeing."""
    text = str(text)
    if full or len(text) <= SHOW_ELIDE:
        return text
    return "%s… (%d chars total; --full to print it all)" % (text[:SHOW_ELIDE], len(text))


def cmd_show(args):
    """Full record for ONE release — the detail reader `list` deliberately does not provide."""
    root = resolve_root(args.root)
    full = getattr(args, "full", False)
    conn = connect(artifact_paths(root)["db"])
    try:
        rel = _resolve_one(conn, args.gid, args.version)
        ref = conn.execute("SELECT url, temp_id FROM issue_refs WHERE id = ?",
                           (rel["tracking_ref_id"],)).fetchone()
        print("GID:           %s" % rel["global_id"])
        print("Release:       %s" % (rel["version"] or "(unversioned)"))
        print("Status:        %s" % rel["status"])
        for label, key in (("Codename", "codename"), ("Target Date", "target_date"),
                           ("Shipped", "shipped_date"), ("Milestone", "milestone"),
                           ("GH_URL", "gh_release_url"), ("Description", "description"),
                           ("Exit criterion", "exit_criterion"),
                           ("Front-door reviewed", "front_door_reviewed"),
                           ("Shakedown reviewed", "shakedown_reviewed"),
                           ("License file", "license_file")):
            if rel[key]:
                print("%-14s %s" % (label + ":", _elide(rel[key], full)))
        print("%-14s %s" % ("Tracking:", (ref["url"] or ref["temp_id"]) if ref else "-"))

        items = conn.execute("""SELECT t.url, t.temp_id, mi.state FROM manifest_items mi
                                JOIN issue_refs t ON t.id = mi.issue_ref_id
                                WHERE mi.release_id = ? ORDER BY mi.id""",
                             (rel["id"],)).fetchall()
        print("Manifest:      %d item(s)" % len(items))
        for it in items:
            print("  - %s [%s]" % (it["url"] or it["temp_id"], it["state"]))

        legacy = conn.execute("""SELECT content FROM legacy_lines WHERE release_id = ?
                                 ORDER BY position""", (rel["id"],)).fetchall()
        if legacy:
            print("Legacy lines:  %d (imported verbatim, pending disposition)" % len(legacy))
            for ll in legacy:
                print("  | %s" % _elide(ll["content"], full))

        pending = conn.execute("""SELECT rule, COUNT(*) AS n FROM grandfather_entries
                                  WHERE release_gid = ? AND disposition IS NULL
                                  GROUP BY rule""", (rel["global_id"],)).fetchall()
        if pending:
            print("Grandfathered: %s"
                  % ", ".join("%s x%d" % (g["rule"], g["n"]) for g in pending))
    finally:
        conn.close()


def cmd_next(args):
    """The next release to work on: unshipped, earliest target date first. A release with no
    target date sorts last — undated is not urgent, it is unplanned."""
    root = resolve_root(args.root)
    conn = connect(artifact_paths(root)["db"])
    try:
        rows = conn.execute("""SELECT global_id, version, codename, status, target_date
                               FROM releases WHERE status IN ('draft', 'active')
                               ORDER BY target_date IS NULL, target_date, version""").fetchall()
        if not rows:
            print("no unshipped releases — the ledger has nothing queued")
            return
        head = rows[0]
        print("NEXT: %s %s (%s) target=%s gid=%s"
              % (head["version"] or "-", head["codename"] or "", head["status"],
                 head["target_date"] or "unplanned", head["global_id"]))
        for r in rows[1:]:
            print("then: %s %s (%s) target=%s"
                  % (r["version"] or "-", r["codename"] or "", r["status"],
                     r["target_date"] or "unplanned"))
        if args.verbose:
            print()
            cmd_show(argparse.Namespace(root=args.root, gid=head["global_id"], version=None,
                                        full=False))
    finally:
        conn.close()


def _project_field_map(payload):
    fields = {field.get("name"): field for field in payload.get("fields", [])}
    missing = [name for name in PROJECT_FIELDS if not fields.get(name, {}).get("id")]
    if missing:
        refuse("github-project-schema",
               "project is missing required field(s): %s" % ", ".join(missing))
    return fields


def _project_select_option(field, value):
    for option in field.get("options", []):
        if option.get("name") == value:
            return option.get("id")
    refuse("github-project-schema",
           "field %r is missing required option %r" % (field.get("name"), value))


def _project_edit_field(project_id, item_id, field, value, kind):
    base = ["project", "item-edit", "--id", item_id, "--project-id", project_id,
            "--field-id", field["id"]]
    if value in (None, ""):
        _gh_run(base + ["--clear"])
    elif kind == "text":
        _gh_run(base + ["--text", str(value)])
    elif kind == "date":
        _gh_run(base + ["--date", str(value)])
    else:
        _gh_run(base + ["--single-select-option-id", _project_select_option(field, value)])


def cmd_project_sync(args):
    """Project the release ledger to GitHub draft cards; DB writes are intentionally impossible."""
    root = resolve_root(args.root)
    conn = connect(artifact_paths(root)["db"])
    try:
        project = _gh_json(["project", "view", str(args.number), "--owner", args.owner,
                            "--format", "json"])
        project_id = project.get("id")
        if not project_id:
            refuse("github-project", "project view returned no project ID")
        fields = _project_field_map(_gh_json(
            ["project", "field-list", str(args.number), "--owner", args.owner,
             "--limit", "100", "--format", "json"]))
        items = _gh_json(["project", "item-list", str(args.number), "--owner", args.owner,
                          "--limit", "1000", "--format", "json"]).get("items", [])
        by_release_id = {}
        for item in items:
            release_id = _project_value(item, "Release ID")
            if release_id:
                if release_id in by_release_id:
                    refuse("github-project-duplicate-card",
                           "Release ID %s occurs in more than one Project card" % release_id)
                by_release_id[release_id] = item

        releases = _project_release_rows(conn)
        if not args.apply:
            print("DRY RUN: GitHub Project is unchanged; repeat with --apply to write cards.")

        for release in releases:
            title = "%s — %s" % (release["version"] or "Unversioned",
                                  release["codename"] or "Untitled")
            body = _project_body(release)
            existing = by_release_id.get(release["global_id"])
            action = "UPDATE" if existing else "CREATE"
            print("%s %s (%s)" % (action, title, release["global_id"]))
            if not args.apply:
                continue

            if existing:
                item_id = existing.get("id")
                if not item_id:
                    refuse("github-project-item", "existing card %s has no item ID"
                           % release["global_id"])
                content = existing.get("content") or {}
                content_id = content.get("id")
                if content.get("type") != "DraftIssue" or not content_id:
                    refuse("github-project-item",
                           "existing card %s is not an editable draft item"
                           % release["global_id"])
                _gh_run(["project", "item-edit", "--id", content_id,
                         "--title", title, "--body", body])
            else:
                created = _gh_json(["project", "item-create", str(args.number), "--owner",
                                    args.owner, "--title", title, "--body", body,
                                    "--format", "json"])
                item_id = created.get("id")
                if not item_id:
                    refuse("github-project-item", "created card %s has no item ID"
                           % release["global_id"])

            tracking = release["tracking_url"] or release["tracking_temp"]
            values = (
                ("Release ID", release["global_id"], "text"),
                ("Release status", STATUS_RENDER[release["status"]], "select"),
                ("Target date", release["target_date"], "date"),
                ("Shipped date", release["shipped_date"], "date"),
                ("Codename", release["codename"], "text"),
                ("Tracking issue", tracking, "text"),
                ("GitHub release", release["gh_release_url"], "text"),
                ("Front-door reviewed", release["front_door_reviewed"], "select"),
                ("Shakedown reviewed", release["shakedown_reviewed"], "select"),
                ("License file", release["license_file"], "select"),
            )
            for name, value, kind in values:
                _project_edit_field(project_id, item_id, fields[name], value, kind)
        print("project sync: %d release card(s) %s"
              % (len(releases), "applied" if args.apply else "planned"))
    finally:
        conn.close()


def cmd_gen(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    conn = connect(paths["db"])
    lock = WriterLock(root)
    lock.acquire()
    try:
        if os.path.exists(lock.journal_path):
            refuse("journal-live", "run `releases check` to recover the interrupted write first")
        generation = get_generation(conn)
        _atomic_write(paths["gen"], gen_marker(generation) + "\n" + render_ledger(conn))
        _atomic_write(paths["preview"], preview_text(conn, generation))
        write_drift_report(root, conn)
        print("generated %s (side-by-side, generation %d) + drift report %s"
              % (paths["gen"], generation, paths["drift"]))
        print("NOTE: Phase 0 is side-by-side ONLY — %s is never written by this tool"
              % LEDGER_NAME)
    finally:
        lock.release()
        conn.close()


# ── check ───────────────────────────────────────────────────────────────────────────────────────

def cmd_check(args):
    root = resolve_root(args.root)
    paths = artifact_paths(root)
    lock = WriterLock(root)
    lock.acquire()
    failures, warnings = [], []

    def fail(rule, detail):
        failures.append(rule)
        print("FAIL: rule=%s: %s" % (rule, detail))

    try:
        if not os.path.exists(paths["db"]):
            refuse("not-initialized", "no %s here; run `releases init` first" % DB_NAME)

        # Stale sqlite artifacts (PRD Git story 5). Under our protocol an intent journal ALWAYS
        # precedes BEGIN, so a hot -journal/-wal with no live journal means an out-of-protocol
        # writer — fail loudly; no new write proceeds over a dirty state.
        stale = [p for p in (paths["db"] + "-wal", paths["db"] + "-journal") if os.path.exists(p)]
        journal_live = os.path.exists(lock.journal_path)
        if stale and not journal_live:
            fail("stale-artifact",
                 "leftover %s with no live intent journal — a writer bypassed the protocol or "
                 "crashed outside it; inspect before writing"
                 % ", ".join(os.path.basename(p) for p in stale))

        if journal_live:
            conn = connect(paths["db"])
            try:
                outcome = recover_from_journal(root, conn)
            finally:
                conn.close()
            if outcome:
                kind, txn = outcome
                print("RECOVERED: %s crash (txn %s) — %s" % (
                    kind, txn[:12],
                    "the DB never changed; staged remnants discarded" if kind == "discarded"
                    else "the committed operation is preserved; dump/generated regenerated from "
                         "the DB"))
                print("OK: crash recovery completed; continuing the consistency checks")

        conn = connect(paths["db"])
        try:
            if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
                fail("foreign-keys-pragma",
                     "connection could not assert PRAGMA foreign_keys=ON")
            else:
                print("OK: foreign_keys pragma asserted per connection")

            db_gen = get_generation(conn)

            dump_ok = False
            if os.path.exists(paths["dump"]):
                dump_content = open(paths["dump"], encoding="utf-8").read()
                dump_gen = dump_generation_from_text(dump_content)
                if dump_gen != db_gen:
                    fail("generation-mismatch",
                         "settings.generation=%d but %s says %s — write in progress, crashed, or "
                         "a torn trio" % (db_gen, DUMP_NAME, dump_gen))
                elif dump_content != dump_text(conn, db_gen):
                    if not args.rebuild:
                        fail("dump-divergence",
                             "%s does not equal the canonical dump of the DB; recovery is "
                             "`releases check --rebuild` (merge resolution ONLY — never crash "
                             "recovery)" % DUMP_NAME)
                else:
                    dump_ok = True
            else:
                fail("dump-missing", "no %s committed alongside the DB" % DUMP_NAME)
            if dump_ok:
                print("OK: generation trio consistent at %d (DB <-> dump)" % db_gen)

            if os.path.exists(paths["gen"]):
                first = open(paths["gen"], encoding="utf-8").readline().strip()
                m = GEN_MARKER_RE.match(first)
                gen_file_gen = int(m.group(1)) if m else None
                if gen_file_gen != db_gen:
                    fail("generation-mismatch",
                         "%s carries generation %s but the DB is at %d — regenerate with "
                         "`releases gen`" % (GEN_NAME, gen_file_gen, db_gen))
                else:
                    print("OK: %s generation marker matches (%d)" % (GEN_NAME, db_gen))

            if os.path.exists(paths["preview"]):
                first = open(paths["preview"], encoding="utf-8").readline().strip()
                m = GEN_MARKER_RE.match(first)
                preview_gen = int(m.group(1)) if m else None
                if preview_gen != db_gen:
                    fail("preview-stale",
                         "%s carries generation %s but the DB is at %d — it is auto-regenerated "
                         "on every write, so this is a hand-edit or an interrupted write; "
                         "regenerate with `releases gen`" % (PREVIEW_NAME, preview_gen, db_gen))
                else:
                    print("OK: %s generation marker matches (%d)" % (PREVIEW_NAME, db_gen))

            # receipt chain (r3): before == previous after. The ONE legal fork is a history that
            # went through the divergent-dump merge procedure: the union of two branches' dumps
            # necessarily breaks the chain where the branches diverged, and the merge-rebuild
            # receipt the rebuild appends records that fork. So: a break with a merge-rebuild
            # receipt later in the history is the documented merge; a break with none is a
            # spliced or forged audit trail. The latest after must equal the current
            # business-state digest regardless — that is what catches a receipt-less direct
            # write (detected, not prevented). HONEST LIMIT (stated, per r3's "narrow the claim
            # to what can be proven"): a writer who edits the DUMP and launders it through
            # --rebuild can always forge the receipt history too — provenance against a
            # committer with dump-write access is git's job (the dump is a committed file), not
            # the chain's; the chain catches direct DB writes and splices in rebuild-free
            # histories.
            receipts = conn.execute("""SELECT op, txn_id, state_digest_before,
                                              state_digest_after
                                       FROM op_receipts WHERE op != 'ship-evidence'
                                       ORDER BY id""").fetchall()
            chain_ok = True
            breaks = 0
            prev_after = None
            for r in receipts:
                if prev_after is not None and r["state_digest_before"] != prev_after:
                    breaks += 1
                prev_after = r["state_digest_after"]
            has_merge_rebuild = any(r["op"] == "merge-rebuild" for r in receipts)
            if breaks and not has_merge_rebuild:
                fail("receipt-chain",
                     "%d receipt(s) break the chain (before != previous after) with no "
                     "merge-rebuild receipt — spliced or forged audit trail" % breaks)
                chain_ok = False
            digest = business_digest(conn)
            if receipts and receipts[-1]["state_digest_after"] != digest:
                fail("receipt-chain",
                     "latest receipt's after-digest != current business-state digest — a "
                     "receipt-less mutation (a direct write that bypassed the CLI) is caught "
                     "here, not prevented")
                chain_ok = False
            if chain_ok:
                note = (", %d merge fork(s) tolerated under the merge-rebuild receipt" % breaks
                        if breaks else "")
                print("OK: receipt chain intact (%d receipt(s), business-state digest matches%s)"
                      % (len(receipts), note))

            # temp-ref staleness (SOP 3): warn on placeholders older than 7 days (mocked clock).
            try:
                now_dt = _dt.datetime.fromisoformat(now_iso().replace("Z", "+00:00"))
            except ValueError:
                now_dt = _dt.datetime.now(_dt.timezone.utc)
            for r in conn.execute("""SELECT temp_id, created_at FROM issue_refs
                                     WHERE temp_id IS NOT NULL"""):
                try:
                    created = _dt.datetime.fromisoformat(
                        (r["created_at"] or "").replace("Z", "+00:00"))
                except ValueError:
                    continue
                age_days = (now_dt - created).total_seconds() / 86400.0
                if age_days > 7:
                    is_tmp = (r["temp_id"] or "").startswith("TMP-")
                    warn("temp-ref-stale" if is_tmp else "mig-ref-stale",
                         "%s is %.0f days old (> 7) — %s" % (
                             r["temp_id"], age_days,
                             "reconcile the real URL when GitHub returns" if is_tmp else
                             "disposition the migration debt before the strict flip"))
                    warnings.append("stale-ref")

            # duplication warnings (light-touch guard; these warn, never refuse)
            for r in conn.execute("""SELECT codename, COUNT(*) c FROM releases
                                     WHERE version IS NULL AND codename IS NOT NULL
                                     GROUP BY repo_id, codename HAVING c > 1"""):
                warn("unversioned-codename-dup",
                     "%d unversioned releases share codename %r in one repo (the version-unique "
                     "guarantee covers versioned releases only)" % (r["c"], r["codename"]))
                warnings.append("unversioned-codename-dup")
            for r in conn.execute("""SELECT t.global_id, COUNT(DISTINCT mi.release_id) c
                                     FROM manifest_items mi
                                     JOIN issue_refs t ON t.id = mi.issue_ref_id
                                     WHERE mi.state != 'cut'
                                     GROUP BY t.id HAVING c > 1"""):
                warn("shared-manifest-issue",
                     "issue ref %s sits in %d non-cut releases (handoffs are legitimate)"
                     % (r["global_id"], r["c"]))
                warnings.append("shared-manifest-issue")

            pending = conn.execute("""SELECT COUNT(*) c FROM grandfather_entries
                                      WHERE disposition IS NULL""").fetchone()["c"]
            print("info: %d grandfather_entries pending disposition (the strict flip requires "
                  "none pending)" % pending)

            if args.rebuild:
                _rebuild(root, conn)
                # the rebuild resolved the consistency-family failures recorded above (they
                # described the PRE-rebuild state); a failed rebuild refused/exited already
                resolved = {"dump-divergence", "dump-missing", "generation-mismatch",
                            "receipt-chain"}
                failures = [f for f in failures if f not in resolved]
                print("OK: post-rebuild verification — DB rebuilt from %s, displaced DB at %s"
                      % (DUMP_NAME, DB_BAK_NAME))
        finally:
            conn.close()
    finally:
        lock.release()

    if failures:
        print("check: %d failure(s), %d warning(s)" % (len(failures), len(warnings)))
        sys.exit(EXIT_CHECK_FAILED)
    print("check: clean (0 failures, %d warning(s))" % len(warnings))


# ── dump parsing (the merge-boundary direction: dump -> DB) ────────────────────────────────────
# The dump is a LOGICAL grammar (GID/natural-keyed, no integer PKs/FKs), so it cannot be
# executescript'd onto the physical schema. load_dump() maps grammar rows back onto physical
# inserts, resolving parent GIDs to fresh integer ids in dump order — the "deterministic
# renumbering on rebuild" the grammar promises.

INSERT_RE = re.compile(r"^INSERT INTO ([a-z_]+)\(([^)]*)\) VALUES\((.*)\);$")


def _split_values(blob):
    """Split a VALUES(...) blob on top-level commas, honoring '...' quoting with '' escapes."""
    parts, buf, in_str = [], [], False
    i = 0
    while i < len(blob):
        ch = blob[i]
        if in_str:
            buf.append(ch)
            if ch == "'":
                if i + 1 < len(blob) and blob[i + 1] == "'":
                    buf.append("'")
                    i += 1
                else:
                    in_str = False
        else:
            if ch == "'":
                in_str = True
                buf.append(ch)
            elif ch == ",":
                parts.append("".join(buf))
                buf = []
            else:
                buf.append(ch)
        i += 1
    parts.append("".join(buf))
    return [p.strip() for p in parts]


def _value(p):
    if p == "NULL":
        return None
    if p.startswith("'") and p.endswith("'"):
        return p[1:-1].replace("''", "'")
    return p


def parse_dump(text):
    """Parse canonical-dump text into {table: [rowdict,...]} in file order."""
    tables = {}
    buf = ""

    def try_stmt(stmt):
        m = INSERT_RE.match(stmt)
        if not m:
            return False
        table, cols_blob, vals_blob = m.groups()
        cols = [c.strip() for c in cols_blob.split(",")]
        vals = _split_values(vals_blob)
        if len(cols) != len(vals):
            return False
        tables.setdefault(table, []).append(dict(zip(cols, [_value(v) for v in vals])))
        return True

    for line in text.split("\n"):
        if not buf and (not line.strip() or line.lstrip().startswith("--")):
            continue
        buf = (buf + "\n" + line) if buf else line
        if buf.rstrip().endswith(");"):
            if try_stmt(buf.rstrip()):
                buf = ""
    if buf.strip():
        refuse("dump-parse", "unparseable trailing statement in the dump: %r" % buf[:80])
    return tables


def load_dump(conn, tables):
    """Insert parsed dump rows into the (already-migrated, empty) DB, resolving the grammar's
    natural keys to physical ids in dump order."""
    for row in tables.get("schema_migrations", []):
        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)",
                     (int(row["version"]), row["applied_at"]))
    for row in tables.get("settings", []):
        conn.execute("INSERT INTO settings(key, value) VALUES (?, ?)", (row["key"], row["value"]))
    repo_ids = {}
    for row in tables.get("repos", []):
        cur = conn.execute("INSERT INTO repos(global_id, slug) VALUES (?, ?)",
                           (row["global_id"], row["slug"]))
        repo_ids[row["global_id"]] = cur.lastrowid
    ref_ids = {}
    for row in tables.get("issue_refs", []):
        cur = conn.execute("""INSERT INTO issue_refs(global_id, url, temp_id, created_at)
                              VALUES (?, ?, ?, ?)""",
                           (row["global_id"], row.get("url"), row.get("temp_id"),
                            row["created_at"]))
        ref_ids[row["global_id"]] = cur.lastrowid
    mar_ids = {}
    for row in tables.get("marathons", []):
        cur = conn.execute("""INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status,
                              created_at) VALUES (?, ?, ?, ?, ?)""",
                           (row["global_id"], repo_ids[row["repo_gid"]],
                            ref_ids[row["tracking_ref_gid"]], row["status"], row["created_at"]))
        mar_ids[row["global_id"]] = cur.lastrowid
    rel_ids = {}
    for row in tables.get("releases", []):
        cur = conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status,
                              target_date, shipped_date, description, exit_criterion,
                              tracking_ref_id, marathon_id, gh_release_url, milestone,
                              front_door_reviewed, shakedown_reviewed, license_file)
                              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                           (row["global_id"], repo_ids[row["repo_gid"]], row.get("version"),
                            row.get("codename"), row["status"], row.get("target_date"),
                            row.get("shipped_date"), row["description"], row.get("exit_criterion"),
                            ref_ids[row["tracking_ref_gid"]],
                            mar_ids.get(row["marathon_gid"]) if row.get("marathon_gid") else None,
                            row.get("gh_release_url"), row.get("milestone"),
                            row.get("front_door_reviewed"), row.get("shakedown_reviewed"),
                            row.get("license_file")))
        rel_ids[row["global_id"]] = cur.lastrowid
    item_ids = {}
    for row in tables.get("manifest_items", []):
        cur = conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state)
                              VALUES (?, ?, ?, ?)""",
                           (row["global_id"], rel_ids[row["release_gid"]],
                            ref_ids[row["issue_ref_gid"]], row["state"]))
        item_ids[row["global_id"]] = cur.lastrowid
    for row in tables.get("manifest_state_events", []):
        conn.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at, reason)
                        VALUES (?, ?, ?, ?, ?)""",
                     (item_ids[row["item_gid"]], row["from_state"], row["to_state"], row["at"],
                      row["reason"]))
    for row in tables.get("doc_lines", []):
        conn.execute("""INSERT INTO doc_lines(repo_id, position, content) VALUES (?, ?, ?)""",
                     (repo_ids[row["repo_gid"]], int(row["position"]), row["content"]))
    for row in tables.get("legacy_lines", []):
        conn.execute("""INSERT INTO legacy_lines(release_id, position, content, disposition)
                        VALUES (?, ?, ?, ?)""",
                     (rel_ids[row["release_gid"]], int(row["position"]), row["content"],
                      row.get("disposition")))
    for row in tables.get("grandfather_entries", []):
        rgid = row.get("release_gid")
        if rgid in ("(document)", ""):
            rgid = None
        elif rgid is not None and not rgid.startswith("rel-"):
            rgid = None   # tolerate older shapes; the (document) marker is the contract
        conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value,
                        supplied_value, disposition) VALUES (?, ?, ?, ?, ?, ?)""",
                     (row["import_run"], rgid, row["rule"], row.get("source_value"),
                      row.get("supplied_value"), row.get("disposition")))
    for row in tables.get("op_receipts", []):
        conn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                        state_digest_before, state_digest_after) VALUES (?, ?, ?, ?, ?, ?, ?)""",
                     (row["op"], row.get("target_gid"), row["at"], row["txn_id"],
                      row["session_id"], row["state_digest_before"], row["state_digest_after"]))


def _rebuild(root, conn):
    """`check --rebuild`: dump -> DB, atomic, with a .bak of the displaced DB. MERGE RESOLUTION
    ONLY (PRD) — crash recovery is the journal protocol, and a live journal is refused here. A
    merge legitimately forks the receipt chain (both sides branch from one ancestor), so the
    rebuild appends a merge-rebuild receipt — the one legal fork point in the chain rule."""
    paths = artifact_paths(root)
    _, _, journal_path = lock_paths(root)
    if os.path.exists(journal_path):
        refuse("journal-live",
               "recover the interrupted write with plain `releases check` first; --rebuild is "
               "for git-merge resolution only, never crash recovery")
    if not os.path.exists(paths["dump"]):
        refuse("dump-missing", "nothing to rebuild from")
    dump_content = open(paths["dump"], encoding="utf-8").read()
    dump_gen = dump_generation_from_text(dump_content)
    if dump_gen is None:
        refuse("dump-generation", "%s carries no generation header — not a canonical dump"
               % DUMP_NAME)

    old_digest = business_digest(conn)
    old_gen = get_generation(conn)
    new_gen = max(dump_gen, old_gen) + 1

    tmp_db = "%s.rebuild-%s" % (paths["db"], new_txn_id()[:12])
    try:
        tconn = sqlite3.connect(tmp_db, isolation_level=None)
        try:
            tconn.row_factory = sqlite3.Row
            tconn.execute("PRAGMA foreign_keys = ON")
            tconn.executescript(MIGRATION_001)
            # the dump itself carries the schema_migrations row (every canonical dump does);
            # load_dump resolves the grammar's GID/natural keys onto fresh physical ids
            load_dump(tconn, parse_dump(dump_content))
            tconn.execute("UPDATE settings SET value = ? WHERE key = ?",
                          (str(new_gen), GENERATION_KEY))
            if tconn.execute("SELECT 1 FROM settings WHERE key = ?",
                             (GENERATION_KEY,)).fetchone() is None:
                tconn.execute("INSERT INTO settings(key, value) VALUES (?, ?)",
                              (GENERATION_KEY, str(new_gen)))
            new_digest = business_digest(tconn)
            tconn.execute("""INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                             state_digest_before, state_digest_after)
                             VALUES ('merge-rebuild', NULL, ?, ?, ?, ?, ?)""",
                          (now_iso(), new_txn_id(), session_id(), old_digest, new_digest))
        finally:
            tconn.close()
        probe = connect(tmp_db)   # FK pragma + openability of the rebuilt DB, before it goes live
        probe.close()
    except BaseException:
        try:
            os.unlink(tmp_db)
        except OSError:
            pass
        raise

    shutil.copy2(paths["db"], paths["bak"])
    os.replace(tmp_db, paths["db"])
    conn.close()
    fresh = connect(paths["db"])
    try:
        _atomic_write(paths["dump"], dump_text(fresh, new_gen))
        _atomic_write(paths["preview"], preview_text(fresh, new_gen))
        if os.path.exists(paths["gen"]):
            _atomic_write(paths["gen"], gen_marker(new_gen) + "\n" + render_ledger(fresh))
    finally:
        fresh.close()
    print("rebuilt %s from %s (generation %d -> %d); displaced DB backed up at %s"
          % (DB_NAME, DUMP_NAME, old_gen, new_gen, paths["bak"]))


def cmd_reconcile(args):
    root = resolve_root(args.root)
    conn = connect(artifact_paths(root)["db"])
    try:
        if not args.map:
            refuse("reconcile-map", "pass --map TMP-XXXXXX=<url> (repeatable)")

        def mutate(conn):
            for pair in args.map:
                if "=" not in pair:
                    refuse("reconcile-map", "--map expects TMP-XXXXXX=<url>, got %r" % pair)
                temp, url = pair.split("=", 1)
                temp, url = temp.strip(), url.strip()
                if not (TMP_RE.match(temp) or MIG_RE.match(temp)):
                    refuse("reconcile-map",
                           "--map key %r must be a TMP-XXXXXX or MIG-XXXXXX placeholder" % temp)
                if not GH_ISSUE_URL_RE.match(url):
                    refuse("issue-url-shape",
                           "mapped URL %r must be https://github.com/<org>/<repo>/issues/<n>"
                           % url)
                row = conn.execute("SELECT * FROM issue_refs WHERE temp_id = ?",
                                   (temp,)).fetchone()
                if not row:
                    refuse("unknown-temp-ref", "no issue_refs row carries temp id %r" % temp)
                conn.execute("UPDATE issue_refs SET url = ?, temp_id = NULL WHERE id = ?",
                             (url, row["id"]))
                if temp.startswith("MIG-"):
                    conn.execute("""UPDATE grandfather_entries SET disposition = ?
                                 WHERE rule = 'tracking-issue-missing' AND supplied_value = ?
                                   AND disposition IS NULL""",
                                 ("reconciled:%s" % now_iso(), temp))
                print("reconciled %s -> %s (row %s kept its identity)"
                      % (temp, url, row["global_id"]))

        perform_write(root, conn, "reconcile", None, mutate)
    finally:
        conn.close()


# ── CLI ─────────────────────────────────────────────────────────────────────────────────────────

def build_parser():
    p = argparse.ArgumentParser(prog="releases",
                                 description="GH-32 SQLite-backed RELEASES ledger CLI "
                                             "(Phase 0+1: side-by-side generation only)")
    p.add_argument("--root", help="repo root (default: git toplevel of the CWD)")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("init", help="create the DB + dump; settings default lenient")
    sp.add_argument("--slug", help="repo slug (default: root directory basename)")

    sp = sub.add_parser("import", help="ONE-SHOT legacy ledger import (Phase 0)")
    sp.add_argument("file", nargs="?",
                    help="path to the legacy RELEASES.md (default: <root>/RELEASES.md)")

    sp = sub.add_parser("add", help="add a release (validated write)")
    for flag in ("--version", "--codename", "--target-date", "--shipped-date", "--description",
                 "--exit-criterion", "--milestone", "--gh-release-url", "--marathon"):
        sp.add_argument(flag)
    sp.add_argument("--status", required=True, choices=STATUSES)
    for flag in ("--front-door", "--shakedown", "--license"):
        sp.add_argument(flag, choices=["Yes", "No"])
    sp.add_argument("--tracking-issue", required=True,
                    help="issue URL or TMP-XXXXXX (GitHub-down fallback)")

    sp = sub.add_parser("update", help="update a release by --gid")
    sp.add_argument("--gid", required=True)
    for flag in ("--version", "--codename", "--status", "--target-date", "--shipped-date",
                 "--description", "--exit-criterion", "--milestone", "--gh-release-url"):
        sp.add_argument(flag)
    for flag in ("--front-door", "--shakedown", "--license"):
        sp.add_argument(flag, choices=["Yes", "No"])
    sp.add_argument("--tracking-issue", help=argparse.SUPPRESS)

    sp = sub.add_parser("ship", help="mark a release shipped, with evidence")
    sp.add_argument("--gid", required=True)
    sp.add_argument("--evidence", default="",
                    help="exit-criterion run cite (REQUIRED — an empty value is refused with rule=ship-needs-evidence)")
    sp.add_argument("--date", help="shipped date (default: today)")

    sp = sub.add_parser("manifest", help="manifest items")
    msub = sp.add_subparsers(dest="manifest_cmd", required=True)
    sp_add = msub.add_parser("add", help="add an issue to a release's manifest")
    sp_add.add_argument("--gid", required=True)
    sp_add.add_argument("issue", help="issue URL or TMP-XXXXXX")
    sp_cut = msub.add_parser("cut",
                             help="cut an item from a release's manifest (REQUIRES --reason)")
    sp_cut.add_argument("--gid", required=True)
    sp_cut.add_argument("issue", help="issue URL or TMP-XXXXXX")
    sp_cut.add_argument("--reason", default="")

    sp = sub.add_parser("marathon", help="marathon CRUD (v1: add/list)")
    msub = sp.add_subparsers(dest="marathon_cmd", required=True)
    sp_add = msub.add_parser("add")
    sp_add.add_argument("--tracking-issue", required=True, help="issue URL or TMP-XXXXXX")
    sp_add.add_argument("--status", default="planned", choices=MARATHON_STATUSES)
    msub.add_parser("list")

    sp = sub.add_parser("list", help="list releases")
    sp.add_argument("--all-repos", action="store_true",
                    help="aggregate RELEASES_APP_EXTRA_DBS too; duplicate GIDs fail loudly")
    sp.add_argument("--status", choices=STATUSES)

    sp = sub.add_parser("show", help="full record for one release (by --gid or --version)")
    sp.add_argument("--gid")
    sp.add_argument("--version")
    sp.add_argument("--full", action="store_true",
                    help="print long values verbatim (default elides them at %d chars)"
                         % SHOW_ELIDE)

    sp = sub.add_parser("next", help="the next unshipped release, by target date")
    sp.add_argument("--verbose", action="store_true", help="also print its full record")

    sp = sub.add_parser("gen", help="side-by-side generation (Phase 0: NEVER writes RELEASES.md)")
    sp.add_argument("--side-by-side", action="store_true", default=True,
                    help="the only mode in Phase 0 (accepted for CLI-shape compatibility)")

    sp = sub.add_parser("check",
                        help="DB<->dump<->generated consistency; FK pragma; stale WAL; "
                             "receipt-vs-change bypass detection; temp-ref staleness; "
                             "duplication warnings; per-boundary crash recovery")
    sp.add_argument("--rebuild", action="store_true",
                    help="rebuild the DB from the dump (git-merge resolution ONLY)")

    sp = sub.add_parser("reconcile", help="fill real URLs into temp refs")
    sp.add_argument("--map", action="append", metavar="TMP-X=URL",
                    help="placeholder -> real issue URL (repeatable)")

    sp = sub.add_parser("project", help="GitHub Project release-card projection")
    psub = sp.add_subparsers(dest="project_cmd", required=True)
    sp_sync = psub.add_parser("sync", help="plan or apply DB -> GitHub Project draft cards")
    sp_sync.add_argument("--owner", required=True, help="GitHub organization or user owning the Project")
    sp_sync.add_argument("--number", required=True, type=int, help="GitHub Project number")
    sp_sync.add_argument("--apply", action="store_true",
                         help="perform GitHub writes (default is an auditable dry run)")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    handlers = {
        "init": cmd_init, "import": cmd_import, "add": cmd_add, "update": cmd_update,
        "ship": cmd_ship,
        "manifest": lambda a: cmd_manifest_add(a) if a.manifest_cmd == "add"
        else cmd_manifest_cut(a),
        "marathon": lambda a: cmd_marathon_add(a) if a.marathon_cmd == "add"
        else cmd_marathon_list(a),
        "list": cmd_list, "show": cmd_show, "next": cmd_next, "gen": cmd_gen,
        "check": cmd_check, "reconcile": cmd_reconcile,
        "project": lambda a: cmd_project_sync(a) if a.project_cmd == "sync" else None,
    }
    handlers[args.cmd](args)


if __name__ == "__main__":
    main()
