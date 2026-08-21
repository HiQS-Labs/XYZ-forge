#!/usr/bin/env bash
# gh32-releases-app.sh — GH-32 Phase 0+1: the SQLite-backed RELEASES ledger CLI
# (utils/py/releases_app.py) — schema, writer protocol, dump discipline, enforcement.
#
# PRD: PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md (rev 5, post r1-r4 relay review).
# This suite is the Phase-1 mechanical acceptance: consistency checks with negative controls,
# temp-ref lifecycle, writer-lock/preimage behavior under a simulated concurrent writer (PRD
# "Phases" 1), plus the Phase-0 import/generation invariants that can be proven in fixtures.
#
# Negative controls asserted here (each observed FAILING when its guard is reverted — recorded in
# test/baselines/GH-32-negative-control.md):
#   - the four check-failure cases: deliberate DB<->dump divergence, a stale -wal, a receipt-less
#     direct write (business-state digest-chain mismatch), a duplicate global ID across two
#     fixture DBs
#   - refused-writer-changes-nothing (the r4 lock-audit control)
#   - crash injection at all five boundaries recovers per the journal protocol
#   - divergent-dump merge with grandfather history surviving both sides
#   - versioned-duplicate refusal + unversioned same-codename warning
#   - temp-ref lifecycle with a mocked clock
#
# The real RELEASES.md is READ ONLY for this suite: it is copied into fixtures, and the hash is
# asserted unchanged after `gen` (the Phase-0 hard boundary — the tool must never write it).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HERE/../utils/py/releases_app.py"
REAL_LEDGER="$HERE/../RELEASES.md"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
# compute-then-assert: values are gathered with normal quoting, then compared.
is(){ [ "$1" = "$2" ]; }
has(){ printf '%s' "$1" | grep -q "$2"; }

echo "== test: gh32-releases-app =="

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
[ -f "$REAL_LEDGER" ] || { echo "real RELEASES.md not found at $REAL_LEDGER" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh32-app.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

# All fixture repos live under $WORK. Creation guards the path lexically (it does not exist yet);
# every DESTRUCTIVE use of a derived path is guarded at the use boundary with require_fixture
# (GH-564/GH-567 — an empty or traversing fixture path must refuse, never target this clone).
mkrepo(){ # <name> -> echoes the fixture repo path
  local r="$WORK/$1"
  case "$r" in "$WORK"/*) ;; *) echo "REFUSING: $r outside WORK" >&2; exit 2 ;; esac
  mkdir -p "$r"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  printf '%s\n' "$r"
}
R=""
RA(){ RELEASES_APP_LOCK_WAIT=1 python3 "$APP" --root "$R" "$@"; }
sql(){ sqlite3 "$R/releases.db" "$1"; }
rout(){ RA "$@" >/dev/null 2>&1; }
rlog(){ RA "$@" 2>&1; }
# Refresh releases.sql from the DB via module import — the test's stand-in for "a bypass writer
# who keeps the dump consistent", isolating the digest-chain control from dump-divergence.
refresh_dump(){
  python3 - "$R" "$APP" <<'PYEOF'
import importlib.util, sys, os
root, app = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("releases_app", app)
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
conn = ra.connect(os.path.join(root, "releases.db"))
with open(os.path.join(root, "releases.sql"), "w") as fh:
    fh.write(ra.dump_text(conn, ra.get_generation(conn)))
PYEOF
}

# ── A. init + schema-level enforcement ──────────────────────────────────────────────────────────
echo "-- A: init, exact-shape GIDs, append-only triggers, FK pragma"
R="$(mkrepo a)"
rout init --slug alpha
V=""; [ -f "$R/releases.db" ] && [ -f "$R/releases.sql" ]; ok "init creates releases.db + releases.sql" "$?"
V="$(rlog check)"; if has "$V" "check: clean"; then ok "fresh init checks clean (FK pragma asserted per connection)" 0; else ok "fresh init checks clean" 1; fi
SCHEMA_SQL="$(sql "SELECT sql FROM sqlite_master WHERE name='releases'")"
CLASSES="$(printf '%s' "$SCHEMA_SQL" | grep -o '\[0-9A-HJKMNP-TV-Z\]' | wc -l | tr -d ' ')"
ok "migration carries the exact-shape GID check written out in full (26 Crockford classes)" "$(is "$CLASSES" "26"; echo $?)"
sqlite3 "$R/releases.db" "INSERT INTO issue_refs(global_id,url,temp_id,created_at) VALUES('ref-01ARZ3NDEKTSV4RRFFQ69G5FAV','https://github.com/A/B/issues/1',NULL,'2026-01-01T00:00:00Z')"
OUT="$(sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-SHORT', id, '9.9.9', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "CHECK constraint failed"; then ok "schema refuses a too-short global_id (length is schema-enforced)" 0; else ok "schema refuses a too-short global_id" 1; fi
OUT="$(sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-01IIIIIIIIIIIIIIIIIIIIIIII', id, '9.9.8', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "CHECK constraint failed"; then ok "schema refuses a wrong-alphabet global_id (Crockford excludes I/L/O/U)" 0; else ok "schema refuses a wrong-alphabet global_id" 1; fi
sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, status, description, tracking_ref_id) SELECT 'rel-01ARZ3NDEKTSV4RRFFQ69G5FAV', id, '9.9.7', 'draft', 'x', (SELECT id FROM issue_refs LIMIT 1) FROM repos LIMIT 1" 2>/dev/null
sqlite3 "$R/releases.db" "INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state) SELECT 'mfi-01ARZ3NDEKTSV4RRFFQ69G5FAV', id, (SELECT id FROM issue_refs LIMIT 1), 'dialed_in' FROM releases LIMIT 1" 2>/dev/null
sqlite3 "$R/releases.db" "INSERT INTO manifest_state_events(item_id, from_state, to_state, at, reason) VALUES((SELECT id FROM manifest_items LIMIT 1), 'open', 'cut', '2026-01-01T00:00:00Z', 'direct seed')" 2>/dev/null
OUT="$(sqlite3 "$R/releases.db" "UPDATE manifest_state_events SET reason='y'" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "append-only"; then ok "manifest_state_events is append-only (UPDATE refused by trigger)" 0; else ok "manifest_state_events append-only" 1; fi
rout add --version 0.1.0 --status draft --description "seed." --tracking-issue "https://github.com/A/B/issues/7"
OUT="$(sqlite3 "$R/releases.db" "DELETE FROM op_receipts" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "append-only"; then ok "op_receipts is append-only (DELETE refused by trigger)" 0; else ok "op_receipts append-only" 1; fi
V="$(rlog add --version 0.2.0 --status draft --description seed2 --tracking-issue "https://github.com/A/B/issues/8" --marathon mar-01ARZ3NDEKTSV4RRFFQ69G5FAV)"
if has "$V" "rule=unknown-gid"; then ok "the CLI's FK surface: a marathon_id that resolves to nothing is refused before the write" 0; else ok "marathon FK pre-check" 1; fi

# ── B. one-shot import of the REAL ledger + side-by-side generation ─────────────────────────────
echo "-- B: import the real RELEASES.md; grandfather ledger; side-by-side gen"
R="$(mkrepo b)"
rout init --slug xyz-forge
LEDGER_HASH="$(md5 -q "$REAL_LEDGER")"
V="$(rlog import "$REAL_LEDGER")"; if has "$V" "imported 9 block(s)"; then ok "import brings in all 9 blocks of the real ledger (9th = Cargo 0.9.0, cut 2026-08-20)" 0; else ok "import 9 blocks" 1; fi
# The count tracks the REAL ledger's preamble and moves when the preamble is edited (86 -> 100 on
# 2026-08-20, when GH-111 replaced the freeze rule with the dialed-in one). The assertion is that
# EVERY release-less line lands verbatim, not that the number is 86.
N="$(sql "SELECT COUNT(*) FROM doc_lines")"; ok "the 100-line preamble lands verbatim in doc_lines (release-less document content)" "$(is "$N" "100"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM doc_lines WHERE content = '# Major Releases'")"; ok "doc_lines hold the verbatim first line" "$(is "$N" "1"; echo $?)"
N="$(sql 'SELECT COUNT(*) FROM grandfather_entries WHERE disposition IS NULL')"; if [ "$N" -gt 0 ] 2>/dev/null; then ok "every tolerated violation is recorded in grandfather_entries (import is not a silent fill)" 0; else ok "grandfather entries exist" 1; fi
N="$(sql "SELECT COUNT(*) FROM issue_refs WHERE temp_id GLOB 'MIG-*'")"; ok "all 9 imported blocks got import-only MIG- placeholder refs (importer is uniform; GH_URL lines land in legacy_lines)" "$(is "$N" "9"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM grandfather_entries WHERE rule = 'tracking-issue-missing'")"; ok "each MIG- ref is a tracked grandfather entry (rule=tracking-issue-missing)" "$(is "$N" "9"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM legacy_lines")"; N2="$(sql "SELECT COUNT(*) FROM legacy_lines l JOIN releases r ON r.id = l.release_id WHERE l.content LIKE 'Iterations:%'")"
if [ "$N" -gt 0 ] 2>/dev/null && [ "$N2" -ge 8 ] 2>/dev/null; then ok "unmapped lines (Iterations bands, Shipped prose, manifest prose) survive in legacy_lines" 0; else ok "legacy_lines survive" 1; fi
V="$(rlog check)"; if has "$V" "check: clean"; then ok "check is green right after import (DB<->dump consistent, chain intact)" 0; else ok "post-import check" 1; fi
V="$(rlog import "$REAL_LEDGER")"; if has "$V" "rule=import-once"; then ok "second import is refused (the legacy import is ONE-SHOT)" 0; else ok "import once" 1; fi
cp "$REAL_LEDGER" "$R/RELEASES.md"
FILES_BEFORE="$(cd "$R" && ls -A | grep -v -E '^(releases\.db|releases\.sql|RELEASES\.md)$' | sort | tr '\n' ' ')"
rout gen
FILES_AFTER="$(cd "$R" && ls -A | grep -v -E '^(releases\.db|releases\.sql|RELEASES\.md|RELEASES\.generated\.md|RELEASES\.generated\.md\.drift)$' | sort | tr '\n' ' ')"
if [ -f "$R/RELEASES.generated.md" ] && [ -f "$R/RELEASES.generated.md.drift" ] && [ "$FILES_AFTER" = "$FILES_BEFORE" ]; then ok "gen writes ONLY RELEASES.generated.md + drift report" 0; else ok "gen writes only side-by-side artifacts" 1; fi
ok "the real ledger is byte-identical after gen (hash unchanged; read-only contract)" "$(is "$(md5 -q "$REAL_LEDGER")" "$LEDGER_HASH"; echo $?)"
if has "$(cat "$R/RELEASES.generated.md.drift")" "0 file-only block(s), 0 field-level difference(s)"; then ok "drift report shows zero hand-edits against the freshly imported ledger" 0; else ok "drift zero" 1; fi
printf '\nRelease: 9.9.9\nStatus: Draft\nDescription: hand edit.\n' >> "$R/RELEASES.md"
rout gen
if grep -q "^\[hand-edit\] blocks in RELEASES.md with no DB counterpart: 9\.9\.9" "$R/RELEASES.generated.md.drift"; then ok "a hand-edit to the ledger copy is REPORTED by the drift report (sole-writer clock reset)" 0; else ok "drift hand-edit" 1; fi
BD_BEFORE="$(python3 - "$R" "$APP" <<'PYEOF2'
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("releases_app", sys.argv[2])
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
print(ra.business_digest(ra.connect(os.path.join(sys.argv[1], "releases.db"))))
PYEOF2
)"
rout check --rebuild
BD_AFTER="$(python3 - "$R" "$APP" <<'PYEOF3'
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("releases_app", sys.argv[2])
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
print(ra.business_digest(ra.connect(os.path.join(sys.argv[1], "releases.db"))))
PYEOF3
)"
ok "rebuild preserves the BUSINESS state exactly (digest equal; receipts/generation excluded by definition)" "$(is "$BD_BEFORE" "$BD_AFTER"; echo $?)"
if ! grep -qE 'INSERT INTO (releases|manifest_items|marathons|legacy_lines|doc_lines)\([^)]*(^|, )(id|repo_id|release_id|issue_ref_id|tracking_ref_id|marathon_id|item_id)[,)]' "$R/releases.sql"; then ok "the canonical dump contains no integer PKs/FKs as values (rows are GID/natural-keyed)" 0; else ok "dump grammar clean of integer keys" 1; fi
if grep -q '^-- gf-key: imp-' "$R/releases.sql"; then ok "grandfather_entries rows in the dump carry their PRD natural key (gf-key comments)" 0; else ok "gf-key present" 1; fi

# ── C. structural refusals — identical in lenient and strict ────────────────────────────────────
echo "-- C: structural rules refuse in BOTH modes; every refusal names its rule"
R="$(mkrepo c)"
rout init --slug gamma
V="$(rlog add --version 1.0.0 --status draft --description x --tracking-issue "https://example.com/x")"; if has "$V" "rule=issue-url-shape"; then ok "bad tracking URL shape refused, rule named" 0; else ok "url shape" 1; fi
V="$(rlog add --version 1.0.0 --status draft --description x --tracking-issue "MIG-ABC123")"; if has "$V" "rule=mig-import-only"; then ok "MIG- placeholder refused in an ordinary write (import-only shape)" 0; else ok "mig import-only" 1; fi
rout add --version 1.0.0 --status draft --description x --tracking-issue "https://github.com/A/B/issues/1"
V="$(rlog add --version 1.0.0 --status draft --description x2 --tracking-issue "https://github.com/A/B/issues/2")"; if has "$V" "rule=version-uniqueness"; then ok "versioned-duplicate refusal (UNIQUE(repo_id, version) — the narrowed guarantee)" 0; else ok "versioned dup" 1; fi
rout add --status draft --description x --codename Twin --tracking-issue "https://github.com/A/B/issues/3"
rout add --status draft --description y --codename Twin --tracking-issue "https://github.com/A/B/issues/4"
V="$(rlog check)"; if has "$V" "rule=unversioned-codename-dup"; then ok "unversioned same-codename pair does NOT refuse — check WARNS instead" 0; else ok "unversioned codename warn" 1; fi
G1="$(sql "SELECT global_id FROM releases WHERE version = '1.0.0'")"
rout manifest add --gid "$G1" "https://github.com/A/B/issues/9"
V="$(rlog manifest add --gid "$G1" "https://github.com/A/B/issues/9")"; if has "$V" "rule=manifest-duplicate"; then ok "manifest duplicate refused (UNIQUE(release_id, issue_ref_id))" 0; else ok "manifest dup" 1; fi
V="$(rlog manifest cut --gid "$G1" "https://github.com/A/B/issues/9")"; if has "$V" "rule=cut-needs-reason"; then ok "manifest cut without a reason refused (structural, both modes)" 0; else ok "cut needs reason" 1; fi
N="$(sql 'SELECT COUNT(*) FROM releases')"; ok "structural refusal is strict even in lenient mode: refused calls wrote nothing" "$(is "$N" "3"; echo $?)"

# ── D. GH-28 thresholds: strict refuses, lenient warns and writes ───────────────────────────────
echo "-- D: mode table for thresholds"
R="$(mkrepo d)"
rout init --slug delta
LONG="First sentence here. Second sentence. Third one. Fourth. And a fifth."
V="$(rlog add --version 1.0.0 --status draft --description "$LONG" --tracking-issue "https://github.com/A/B/issues/1")"
N="$(sql "SELECT COUNT(*) FROM releases WHERE version = '1.0.0'")"
if has "$V" "warn: rule=description-length" && [ "$N" = "1" ]; then ok "lenient mode WARNS and WRITES an over-threshold description" 0; else ok "lenient warn+write" 1; fi
sqlite3 "$R/releases.db" "UPDATE settings SET value='strict' WHERE key='enforcement'"
V="$(rlog add --version 2.0.0 --status draft --description "$LONG" --tracking-issue "https://github.com/A/B/issues/2")"
N="$(sql "SELECT COUNT(*) FROM releases WHERE version = '2.0.0'")"
if has "$V" "refused: rule=description-length" && [ "$N" = "0" ]; then ok "strict mode REFUSES the same write, naming the rule" 0; else ok "strict refuse" 1; fi

# ── E. manifest lifecycle: the append-only re-scope trail ───────────────────────────────────────
echo "-- E: cut needs a reason; events append-only; coupling detectable"
R="$(mkrepo e)"
rout init --slug eps
rout add --version 1.0.0 --status draft --description "One." --tracking-issue "https://github.com/A/B/issues/1"
rout add --version 2.0.0 --status draft --description "Two." --tracking-issue "https://github.com/A/B/issues/2"
E1="$(sql "SELECT global_id FROM releases WHERE version = '1.0.0'")"
E2="$(sql "SELECT global_id FROM releases WHERE version = '2.0.0'")"
rout manifest add --gid "$E1" "https://github.com/A/B/issues/30"
# GH-111 REVERSES the pre-2026-08-20 "handoff precedent", under which one issue could sit on
# several releases at once and `add` merely WARNED (rule=shared-manifest-issue). A task is now
# dialed into exactly ONE release at a time. Handoffs are still first-class — they are expressed
# as cut-then-dial-in, which RECORDS the move instead of leaving the task on two ledgers silently.
V="$(rlog manifest add --gid "$E2" "https://github.com/A/B/issues/30")"
N="$(sql "SELECT COUNT(*) FROM manifest_items mi JOIN issue_refs t ON t.id = mi.issue_ref_id WHERE t.url LIKE '%/30' AND mi.state='dialed_in'")"
if has "$V" "rule=dialed-in-elsewhere" && [ "$N" = "1" ]; then ok "a task dialed into a second release is REFUSED, naming the holder (GH-111 exclusivity)" 0; else ok "exclusivity refusal" 1; fi
rout manifest cut --gid "$E1" "https://github.com/A/B/issues/30" --reason "handed off to $E2"
V="$(rlog manifest add --gid "$E2" "https://github.com/A/B/issues/30")"
N="$(sql "SELECT COUNT(*) FROM manifest_items mi JOIN issue_refs t ON t.id = mi.issue_ref_id WHERE t.url LIKE '%/30'")"
if has "$V" "dialed into" && [ "$N" = "2" ]; then ok "cut-then-dial-in re-homes a task to another release, leaving BOTH rows as history" 0; else ok "handoff via cut+dial-in" 1; fi
rout manifest cut --gid "$E2" "https://github.com/A/B/issues/30" --reason "descoped at freeze"
ST="$(sql "SELECT mi.state FROM manifest_items mi JOIN releases r ON r.id = mi.release_id WHERE r.global_id = '$E2'")"
EV="$(sql 'SELECT reason FROM manifest_state_events ORDER BY id DESC LIMIT 1')"
if [ "$ST" = "cut" ] && [ "$EV" = "descoped at freeze" ]; then ok "cut with a reason flips state AND appends the event in one transaction" 0; else ok "cut+event" 1; fi
V="$(rlog manifest cut --gid "$E2" "https://github.com/A/B/issues/30" --reason "again")"; if has "$V" "rule=transition"; then ok "cut is terminal for that row: a second cut is refused with the transition rule" 0; else ok "cut terminal" 1; fi
# Exactly ONE row: both cut rows share an issue_ref_id, so flipping both would trip GH-111's
# active-exclusivity index and the direct write would never land — the bypass this asserts.
sqlite3 "$R/releases.db" "UPDATE manifest_items SET state='dialed_in' WHERE id = (SELECT id FROM manifest_items WHERE state='cut' ORDER BY id LIMIT 1)" 2>/dev/null
refresh_dump
V="$(rlog check)"; if has "$V" "FAIL: rule=receipt-chain"; then ok "a direct writer flipping item state WITHOUT an event is caught by the digest chain" 0; else ok "coupling detected" 1; fi

# ── F. temp-ref lifecycle with a mocked clock (SOP 3) ───────────────────────────────────────────
echo "-- F: offline create -> staleness at +7d -> reconcile -> clean"
R="$(mkrepo f)"
rout init --slug zeta
export RELEASES_APP_NOW=2026-08-01T10:00:00Z
rout add --version 1.0.0 --status draft --description "One." --tracking-issue "TMP-ABC123"
export RELEASES_APP_NOW=2026-08-02T10:00:00Z
if ! has "$(rlog check)" "temp-ref-stale"; then ok "fresh temp ref (T0) draws no staleness warning" 0; else ok "no early staleness" 1; fi
export RELEASES_APP_NOW=2026-08-09T10:00:00Z
V="$(rlog check)"; if has "$V" "warn: rule=temp-ref-stale: TMP-ABC123"; then ok "temp ref older than 7 days warns (mocked clock)" 0; else ok "staleness warn" 1; fi
unset RELEASES_APP_NOW
REFGID="$(sql "SELECT global_id FROM issue_refs WHERE temp_id = 'TMP-ABC123'")"
rout reconcile --map "TMP-ABC123=https://github.com/A/B/issues/42"
U="$(sql "SELECT url FROM issue_refs WHERE global_id = '$REFGID'")"
T="$(sql "SELECT IFNULL(temp_id,'') FROM issue_refs WHERE global_id = '$REFGID'")"
if [ "$U" = "https://github.com/A/B/issues/42" ] && [ -z "$T" ]; then ok "reconcile fills the real URL and the row keeps its identity" 0; else ok "reconcile identity" 1; fi
export RELEASES_APP_NOW=2026-09-01T10:00:00Z
if ! has "$(rlog check)" "temp-ref-stale"; then ok "post-reconcile there is no staleness warning at any clock" 0; else ok "post-reconcile clean" 1; fi
unset RELEASES_APP_NOW

# ── G. writer lock: the refused attempt changes NO committed artifact (r4 control) ───────────────
echo "-- G: simulated concurrent writer; lock-audit sidecar"
R="$(mkrepo g)"
rout init --slug eta
LOCK="$R/.git/releases-app.lock"
python3 - "$LOCK" >/dev/null 2>&1 <<'PYEOF' &
import fcntl, sys, time
fh = open(sys.argv[1], "a+")
fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
time.sleep(10)
PYEOF
HOLDER=$!
sleep 1
DB_HASH="$(md5 -q "$R/releases.db")"; DUMP_HASH="$(md5 -q "$R/releases.sql")"
TREE_BEFORE="$(cd "$R" && ls -A | sort | tr '\n' ' ')"
V="$(rlog add --version 5.5.5 --status draft --description x --tracking-issue "https://github.com/A/B/issues/5")"; GRC=$?
TREE_AFTER="$(cd "$R" && ls -A | sort | tr '\n' ' ')"
if [ "$GRC" -eq 4 ] && has "$V" "rule=writer-lock"; then ok "a write under a held lock is refused with exit 4 and the writer-lock rule" 0; else ok "lock refusal rc4" 1; fi
if [ "$(md5 -q "$R/releases.db")" = "$DB_HASH" ] && [ "$(md5 -q "$R/releases.sql")" = "$DUMP_HASH" ] && [ "$TREE_AFTER" = "$TREE_BEFORE" ]; then ok "the refused attempt changed NO committed artifact (r4 control)" 0; else ok "refused changed nothing" 1; fi
AUDIT="$R/.git/releases-app-lock-audit.log"
if has "$(cat "$AUDIT" 2>/dev/null)" " retried " && has "$(cat "$AUDIT")" " refused " && ! has "$(sql '.tables')" "lock"; then ok "lock evidence went to the append-only sidecar in the git common-dir, not the DB" 0; else ok "sidecar" 1; fi
kill $HOLDER 2>/dev/null; wait $HOLDER 2>/dev/null
rout add --version 5.5.5 --status draft --description x --tracking-issue "https://github.com/A/B/issues/5"
V="$(rlog check)"; if has "$V" "check: clean"; then ok "after the holder exits, the same write succeeds (the lock was the only barrier)" 0; else ok "write after release" 1; fi

# ── H. crash injection at all five boundaries ───────────────────────────────────────────────────
echo "-- H: journal protocol recovery, per boundary"
for B in pre-commit post-commit post-stage mid-rename post-rename; do
  R="$(mkrepo "h-$B")"
  rout init --slug h
  rout gen
  export RELEASES_APP_CRASH_AT="$B"
  RA add --version 9.9.9 --status draft --description "crash" --tracking-issue "https://github.com/A/B/issues/99" >/dev/null 2>&1
  CRC=$?
  unset RELEASES_APP_CRASH_AT
  ROWS_PRE="$(sql "SELECT COUNT(*) FROM releases WHERE version = '9.9.9'" 2>/dev/null || echo 0)"
  ok "[$B] the injected crash kills the writer (exit 70)" "$(is "$CRC" "70"; echo $?)"
  C1=0; RA check >/dev/null 2>&1 || C1=1
  V="$(rlog check)"; if [ "$C1" = "0" ] && has "$V" "check: clean"; then ok "[$B] check recovers and leaves a consistent trio (green)" 0; else ok "[$B] recovery green" 1; fi
  ROWS_POST="$(sql "SELECT COUNT(*) FROM releases WHERE version = '9.9.9'")"
  if [ "$B" = "pre-commit" ]; then
    if [ "$ROWS_PRE" = "0" ] && [ "$ROWS_POST" = "0" ]; then ok "[$B] pre-COMMIT: the DB never changed — the operation was discarded" 0; else ok "[$B] discarded" 1; fi
  else
    ok "[$B] post-COMMIT: the committed operation is PRESERVED" "$(is "$ROWS_POST" "1"; echo $?)"
  fi
  LEFT="$(ls "$R" | grep -E 'tmp-|journal' || true)"
  if [ -z "$LEFT" ] && [ ! -f "$R/.git/releases-app-journal.json" ]; then ok "[$B] no staged .tmp remnants or journals survive recovery" 0; else ok "[$B] no remnants" 1; fi
done

# ── I. the four check-failure negative controls ─────────────────────────────────────────────────
echo "-- I: check failure controls — dump divergence, stale -wal, receipt-less write, dup GID"
R="$(mkrepo i)"
rout init --slug iota
rout add --version 1.0.0 --status draft --description "One." --codename Iota --tracking-issue "https://github.com/A/B/issues/1"
printf '\n-- tampered\n' >> "$R/releases.sql"
IRC=0; RA check >/dev/null 2>&1 || IRC=1
V="$(rlog check)"; if [ "$IRC" = "1" ] && has "$V" "FAIL: rule=dump-divergence"; then ok "(1) deliberate DB<->dump divergence fails check" 0; else ok "(1) dump divergence" 1; fi
rout check --rebuild
V="$(rlog check)"; if has "$V" "check: clean" && [ -f "$R/releases.db.bak" ]; then ok "divergence recovery is check --rebuild (atomic, with a .bak of the displaced DB)" 0; else ok "rebuild recovery" 1; fi
: > "$R/releases.db-wal"
IRC=0; RA check >/dev/null 2>&1 || IRC=1
V="$(rlog check)"; if [ "$IRC" = "1" ] && has "$V" "FAIL: rule=stale-artifact"; then ok "(2) a stale -wal with no live journal fails check loudly" 0; else ok "(2) stale -wal" 1; fi
rm -f "$R/releases.db-wal"
sqlite3 "$R/releases.db" "INSERT INTO releases(global_id, repo_id, version, codename, status, description, tracking_ref_id) SELECT 'rel-01ARZ3NDEKTSV4RRFFQ69G5FAV', id, '2.0.0', 'Bypass', 'draft', 'direct write', (SELECT tracking_ref_id FROM releases LIMIT 1) FROM repos LIMIT 1;"
refresh_dump
IRC=0; RA check >/dev/null 2>&1 || IRC=1
V="$(rlog check)"; if [ "$IRC" = "1" ] && has "$V" "FAIL: rule=receipt-chain"; then ok "(3) a receipt-less direct write fails the business-state digest chain (bypass DETECTED)" 0; else ok "(3) receipt-less write" 1; fi
DUPGID="$(sql "SELECT global_id FROM releases LIMIT 1")"
R2="$(mkrepo i2)"
R="$R2"
rout init --slug i2
rout add --version 1.0.0 --status draft --description "One." --codename Iota --tracking-issue "https://github.com/A/B/issues/1"
sqlite3 "$R2/releases.db" "UPDATE releases SET global_id = '$DUPGID'"
R="$WORK/i"   # aggregation compares repo i against the extra DB
export RELEASES_APP_EXTRA_DBS="$R2/releases.db"
ARC=0; RA list --all-repos >/dev/null 2>&1 || ARC=1
V="$(rlog list --all-repos)"; if [ "$ARC" = "1" ] && has "$V" "FAIL: rule=duplicate-gid"; then ok "(4) a duplicate global ID across two fixture DBs fails the aggregation LOUDLY" 0; else ok "(4) dup gid" 1; fi
if has "$V" "warn: rule=cross-repo-codename"; then ok "cross-repo codename collision WARNS in the aggregation (the survey case), never refuses" 0; else ok "cross-repo codename warn" 1; fi
unset RELEASES_APP_EXTRA_DBS

# ── J. divergent-dump merge: grandfather history survives BOTH sides ────────────────────────────
echo "-- J: the tested merge conflict procedure (dump grammar -> check --rebuild)"
ANC="$(mkrepo j-anc)"
R="$ANC"; rout init --slug m
for SIDE in a b; do
  S="$WORK/j-$SIDE"
  case "$S" in "$WORK"/*) ;; *) echo "REFUSING" >&2; exit 2 ;; esac
  cp -R "$ANC" "$S"   # WORK is a fresh mktemp -d: the path cannot pre-exist, so no scrub is needed
  printf 'Release: 1.%s.0\nStatus: Draft\nDescription: Side %s first. Second sentence. Third. Fourth.\nTracking Issue: https://github.com/A/B/issues/1%s\n\nRelease: 2.%s.0\nStatus: Draft\nDescription: Side %s second block.\n' "$SIDE" "$SIDE" "$SIDE" "$SIDE" "$SIDE" > "$WORK/led-$SIDE.md"
  R="$S"; rout import "$WORK/led-$SIDE.md"
done
RUN_A="$(sqlite3 "$WORK/j-a/releases.db" 'SELECT DISTINCT import_run FROM grandfather_entries')"
RUN_B="$(sqlite3 "$WORK/j-b/releases.db" 'SELECT DISTINCT import_run FROM grandfather_entries')"
if [ -n "$RUN_A" ] && [ -n "$RUN_B" ] && [ "$RUN_A" != "$RUN_B" ]; then ok "the two divergent sides carry DISTINCT import runs (same-second imports cannot collide)" 0; else ok "distinct runs" 1; fi
# the human merge: union both dumps per the grammar (shared ancestor lines dedup; one header)
{ grep '^-- generation' "$WORK/j-a/releases.sql"; grep -vh '^-- generation' "$WORK/j-a/releases.sql" "$WORK/j-b/releases.sql" | awk '!seen[$0]++'; } > "$WORK/merged.sql"
MG="$WORK/j-merged"
case "$MG" in "$WORK"/*) ;; *) echo "REFUSING" >&2; exit 2 ;; esac
cp -R "$ANC" "$MG"
cp "$WORK/merged.sql" "$MG/releases.sql"
R="$MG"
rout check --rebuild
V="$(rlog check)"; if has "$V" "check: clean"; then ok "the merged dump rebuilds atomically and checks green" 0; else ok "merge rebuild green" 1; fi
N="$(sql 'SELECT COUNT(*) FROM releases')"; ok "BOTH sides' releases survive the rebuild (4 rows from two 2-block imports)" "$(is "$N" "4"; echo $?)"
N="$(sql 'SELECT COUNT(DISTINCT import_run) FROM grandfather_entries')"
GA="$(sql "SELECT COUNT(*) FROM grandfather_entries WHERE import_run = '$RUN_A'")"
GB="$(sql "SELECT COUNT(*) FROM grandfather_entries WHERE import_run = '$RUN_B'")"
if [ "$N" = "2" ] && [ "$GA" -ge 2 ] 2>/dev/null && [ "$GB" -ge 2 ] 2>/dev/null; then ok "BOTH sides' grandfather history survives the rebuild (2 import runs, entries on each)" 0; else ok "grandfather survives both sides" 1; fi
V="$(rlog check)"; if has "$V" "merge fork(s) tolerated"; then ok "the merge fork is tolerated under the merge-rebuild receipt (the one legal chain fork)" 0; else ok "fork tolerance" 1; fi

# ── K. ship / update / receipts ─────────────────────────────────────────────────────────────────
echo "-- K: ship, update, immutability"
R="$(mkrepo k)"
rout init --slug kappa
rout add --version 1.0.0 --status draft --description "One." --tracking-issue "https://github.com/A/B/issues/1"
K1="$(sql "SELECT global_id FROM releases WHERE version = '1.0.0'")"
V="$(rlog ship --gid "$K1")"; if has "$V" "rule=ship-needs-evidence"; then ok "ship without evidence is refused, rule named" 0; else ok "ship evidence required" 1; fi
rout ship --gid "$K1" --evidence "gate exit 0" --date 2026-08-18
ST="$(sql "SELECT status FROM releases WHERE global_id = '$K1'")"
SD="$(sql "SELECT shipped_date FROM releases WHERE global_id = '$K1'")"
EV="$(sql "SELECT at FROM op_receipts WHERE op = 'ship-evidence'")"
if [ "$ST" = "shipped" ] && [ "$SD" = "2026-08-18" ] && has "$EV" "evidence: gate exit 0"; then ok "ship with evidence flips status, stamps the date, rides the audit trail" 0; else ok "ship works" 1; fi
V="$(rlog ship --gid "$K1" --evidence "again")"; if has "$V" "rule=transition"; then ok "re-shipping a shipped release is refused (transition legality is CLI-enforced)" 0; else ok "re-ship refused" 1; fi
rout update --gid "$K1" --codename Renamed
CN="$(sql "SELECT codename FROM releases WHERE global_id = '$K1'")"
V="$(rlog update --gid "$K1" --tracking-issue "https://github.com/A/B/issues/2")"
if [ "$CN" = "Renamed" ] && has "$V" "rule=tracking-ref-immutable"; then ok "update can change fields but NOT the tracking reference (identity is reconcile-only)" 0; else ok "update + immutable ref" 1; fi
N="$(sql 'SELECT COUNT(DISTINCT op) FROM op_receipts')"
N2="$(sql "SELECT COUNT(*) FROM op_receipts WHERE session_id != ''")"
if [ "$N" -ge 2 ] 2>/dev/null && [ "$N2" -ge 2 ] 2>/dev/null; then ok "the receipt log records >=2 distinct ops with session ids (the exit gate reads these)" 0; else ok "receipts recorded" 1; fi

# ── L. RELEASES-PREVIEW.md is GONE and must stay gone ───────────────────────────────────────────
# It was removed 2026-08-19: a desktop SQLite viewer and `releases project sync` (GH-39) cover both
# jobs it had, and it was a tracked generated file that conflicted on every concurrent write. This
# section is a regression guard, not a feature test — the failure it prevents is someone
# reintroducing a generated Markdown mirror of the database because the write path "looks
# incomplete" without one.
echo "-- L: the preview is not regenerated (removal regression guard)"
R="$(mkrepo l)"
rout init --slug lima
if [ ! -f "$R/RELEASES-PREVIEW.md" ]; then ok "init does NOT create RELEASES-PREVIEW.md" 0; else ok "no preview at init" 1; fi
rout add --version 3.0.0 --status draft --description "Preview seed." --tracking-issue "https://github.com/A/B/issues/3"
if [ ! -f "$R/RELEASES-PREVIEW.md" ]; then ok "a CLI write does NOT create RELEASES-PREVIEW.md" 0; else ok "no preview on write" 1; fi
rout gen
if [ ! -f "$R/RELEASES-PREVIEW.md" ]; then ok "releases gen does NOT create RELEASES-PREVIEW.md" 0; else ok "no preview on gen" 1; fi
V="$(rlog check)"
if has "$V" "check: clean"; then ok "check is clean with no preview present (the preview-stale rule is gone)" 0; else ok "check clean without preview" 1; fi
if ! has "$V" "preview"; then ok "check output no longer mentions a preview at all" 0; else ok "no preview in check output" 1; fi
# and the write path still produces the artifacts that DO matter
if [ -f "$R/releases.sql" ] && [ -f "$R/releases.db" ]; then ok "the dump and DB are still written (removing the preview did not disturb the staged-write protocol)" 0; else ok "dump+db still written" 1; fi

# ── M. readers: show / next (fast orientation without raw SQL) ──────────────────────────────────
echo "-- M: show + next readers"
R="$(mkrepo m)"
rout init --slug mike
rout add --version 2.0.0 --status draft --description "Later target." --target-date 2026-12-01 --codename Later --tracking-issue "https://github.com/A/B/issues/20"
rout add --version 1.0.0 --status draft --description "Earlier target." --target-date 2026-09-01 --codename Sooner --tracking-issue "https://github.com/A/B/issues/10"
rout add --version 0.9.0 --status draft --description "No target." --codename Undated --tracking-issue "https://github.com/A/B/issues/9"
rout add --version 0.5.0 --status draft --description "Ships first." --target-date 2026-08-01 --codename Gone --tracking-issue "https://github.com/A/B/issues/5"
rout ship --gid "$(sql "SELECT global_id FROM releases WHERE version='0.5.0'")" --evidence "gate exit 0"
V="$(rlog next)"
if has "$V" "^NEXT: 1.0.0 Sooner" && has "$V" "then: 2.0.0 Later"; then ok "next picks the earliest-target unshipped release, then lists the rest in order" 0; else ok "next ordering" 1; fi
if ! has "$V" "0.5.0"; then ok "next excludes shipped releases" 0; else ok "next excludes shipped" 1; fi
LAST="$(printf '%s' "$V" | tail -1)"
if has "$LAST" "0.9.0" && has "$LAST" "unplanned"; then ok "an undated release sorts LAST and is labeled unplanned, not urgent" 0; else ok "undated sorts last" 1; fi
V="$(rlog show --version 1.0.0)"
if has "$V" "Codename:      Sooner" && has "$V" "Tracking:      https://github.com/A/B/issues/10"; then ok "show resolves by --version (no GID lookup round-trip needed)" 0; else ok "show by version" 1; fi
G="$(sql "SELECT global_id FROM releases WHERE version='1.0.0'")"
V2="$(rlog show --gid "$G")"
ok "show by --gid returns the identical record" "$(is "$V" "$V2"; echo $?)"
V="$(rlog show)"; if has "$V" "rule=selector"; then ok "show with neither selector is refused (rule=selector)" 0; else ok "show selector refusal" 1; fi
V="$(rlog show --gid "$G" --version 1.0.0)"; if has "$V" "rule=selector"; then ok "show with BOTH selectors is refused (exactly one)" 0; else ok "show both selectors" 1; fi
V="$(rlog show --version 7.7.7)"; if has "$V" "rule=unknown-version"; then ok "show on an unknown version is refused by rule, not a silent empty record" 0; else ok "unknown version" 1; fi
LONG="$(python3 -c "print('word ' * 400, end='')")"
rout update --gid "$G" --exit-criterion "$LONG"
SHORT_N="$(rlog show --gid "$G" | wc -c | tr -d ' ')"
FULL_N="$(rlog show --gid "$G" --full | wc -c | tr -d ' ')"
if [ "$FULL_N" -gt "$SHORT_N" ] 2>/dev/null && has "$(rlog show --gid "$G")" "chars total; --full to print it all"; then ok "long values are elided by default and state their true length" 0; else ok "elision default" 1; fi
if has "$(rlog show --gid "$G" --full)" "word word word" && ! has "$(rlog show --gid "$G" --full)" "chars total; --full"; then ok "--full prints the value verbatim with no elision marker" 0; else ok "--full verbatim" 1; fi
DB_HASH="$(md5 -q "$R/releases.db")"
rout show --gid "$G" >/dev/null; rout next >/dev/null
if [ "$(md5 -q "$R/releases.db")" = "$DB_HASH" ] && [ ! -f "$R/.git/releases-app-journal.json" ]; then ok "the readers take no lock and mutate nothing (DB byte-identical, no journal)" 0; else ok "readers are read-only" 1; fi

# ── N. GH-111 + GH-108: the migrate verb, the registry, baselines, extended dump grammar ────────
# The migration REGISTRY is the truth: apply and rebuild stamp exactly the versions it defines,
# never a hard-coded range. That is what makes a deliberate GAP safe — GH-111 owns 004 and GH-108
# owns 003, and whichever lands first must not claim the other's number.
echo "-- N: releases migrate, migration registry, baseline capture, extended dump grammar"

# the registry's versions, read from the code under test rather than restated here
REGISTRY="$(python3 - "$APP" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("releases_app", sys.argv[1])
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
print(",".join(str(v) for v in ra.registry_versions()))
PYEOF
)"
ledger(){ sql "SELECT group_concat(version, ',') FROM (SELECT version FROM schema_migrations ORDER BY version)"; }

# A genuinely pre-004 ledger: the registry is restricted to {1,2} while it is built, so its
# manifest rows carry the OLD `open` vocabulary and its schema predates every GH-111 column.
# Seeded through perform_write, so the receipt chain is honest and `check` can be asserted on it.
build_v2(){
  python3 - "$1" "$APP" <<'PYEOF' >/dev/null
import importlib.util, sys, os, argparse
root, app = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("releases_app", app)
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
ra.MIGRATIONS = {k: v for k, v in ra.MIGRATIONS.items() if k in (1, 2)}
ra.cmd_init(argparse.Namespace(root=root, slug="nu"))
conn = ra.connect(os.path.join(root, "releases.db"))
def seed(c):
    repo_id = c.execute("SELECT id FROM repos LIMIT 1").fetchone()["id"]
    tref = ra.issue_ref_for_token(c, "https://github.com/A/B/issues/1")
    c.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status, description,
                 tracking_ref_id) VALUES (?,?,?,?,?,?,?)""",
              (ra.new_gid("rel-"), repo_id, "1.0.0", "Nu", "active", "Seed release.", tref["id"]))
    rel_id = c.execute("SELECT id FROM releases WHERE version='1.0.0'").fetchone()["id"]
    for n in (11, 12, 13):
        ref = ra.issue_ref_for_token(c, "https://github.com/A/B/issues/%d" % n)
        c.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state)
                     VALUES (?,?,?,'open')""", (ra.new_gid("mfi-"), rel_id, ref["id"]))
    item = c.execute("SELECT id FROM manifest_items ORDER BY id LIMIT 1").fetchone()["id"]
    c.execute("""INSERT INTO manifest_state_events(item_id, from_state, to_state, at, reason)
                 VALUES (?,'open','open',?,'seed event')""", (item, ra.now_iso()))
ra.perform_write(root, conn, "seed", None, seed)
conn.close()
PYEOF
}

R="$(mkrepo n)"; build_v2 "$R"
ok "the v2 fixture starts at ledger {1,2} — pre-004 by construction, not by assumption" "$(is "$(ledger)" "1,2"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM manifest_items WHERE state = 'open'")"
ok "its manifest rows carry the pre-GH-111 'open' vocabulary" "$(is "$N" "3"; echo $?)"

# THE CONTROL: 004 applied with 003 absent from the registry. A hard-coded "stamp 001->004" would
# claim v3 here while roadmap_items had none of 003's columns — the false-v3 defect this rule exists
# to prevent.
python3 - "$R" "$APP" <<'PYEOF' >/dev/null
import importlib.util, sys, os
root, app = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("releases_app", app)
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
ra.MIGRATIONS = {k: v for k, v in ra.MIGRATIONS.items() if k in (1, 2, 4)}
conn = ra.connect(os.path.join(root, "releases.db"))
ra.perform_migration(root, conn)
conn.close()
PYEOF
ok "GH-111-first: a registry without 003 stamps {1,2,4} and never claims 3" "$(is "$(ledger)" "1,2,4"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM pragma_table_info('roadmap_items') WHERE name LIKE 'rating_%'")"
ok "and the gap is REAL — roadmap_items has none of 003's rating columns" "$(is "$N" "0"; echo $?)"
V="$(rlog check)"; if has "$V" "check: clean"; then ok "the migrated ledger checks clean (dump regenerated, digest chain intact)" 0; else ok "post-migrate check" 1; fi
N="$(sql "SELECT COUNT(*) FROM manifest_items WHERE state = 'dialed_in'")"
ok "every 'open' row became 'dialed_in' — a vocabulary rename, not a state change" "$(is "$N" "3"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM manifest_state_events WHERE from_state = 'open'")"
ok "historical EVENTS still say 'open' — copied verbatim, never rewritten (no silent history edit)" "$(is "$N" "1"; echo $?)"
BC="$(sql "SELECT baseline_count || '/' || baseline_source FROM releases WHERE version = '1.0.0'")"
ok "an already-active release is backfilled to its current count, flagged 'backfilled' not 'observed'" "$(is "$BC" "3/backfilled"; echo $?)"

# 003 lands on a database already at 004 — pending migrations apply in ascending order, gaps filled
# whenever the missing one arrives.
V="$(rlog migrate)"
ok "003 applies cleanly ON TOP of 004; the ledger reaches the full registry" "$(is "$(ledger)" "$REGISTRY"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM pragma_table_info('roadmap_items') WHERE name LIKE 'rating_%'")"
ok "and the rating columns now exist (5 of them)" "$(is "$N" "5"; echo $?)"
GEN_BEFORE="$(sql "SELECT value FROM settings WHERE key='generation'")"
V="$(rlog migrate)"
GEN_AFTER="$(sql "SELECT value FROM settings WHERE key='generation'")"
if has "$V" "nothing to migrate" && [ "$GEN_BEFORE" = "$GEN_AFTER" ]; then ok "migrate is idempotent: nothing pending is a clean no-op that does not bump the generation" 0; else ok "migrate idempotent" 1; fi

# BOTH entry points reach the registry — they get there by different paths and only one of them
# was ever specified.
R="$(mkrepo n2)"; build_v2 "$R"
rout check --rebuild
ok "the OTHER entry point agrees: a rebuilt v2 dump reports the registry's versions, not {1,2}" "$(is "$(ledger)" "$REGISTRY"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM manifest_items WHERE state = 'dialed_in'")"
ok "a pre-migration dump carrying state='open' still loads and maps to dialed_in" "$(is "$N" "3"; echo $?)"
V="$(rlog check)"; if has "$V" "check: clean"; then ok "the rebuilt v2 ledger checks clean" 0; else ok "rebuilt v2 check" 1; fi

# Failure injection. The transaction is all-or-nothing across BOTH pending migrations: if 003 could
# commit mid-flight (the executescript() trap), it would survive a 004 failure while the journal,
# generation and receipt all described an interrupted all-or-nothing migration.
R="$(mkrepo n3)"; build_v2 "$R"
DUMP_HASH="$(md5 -q "$R/releases.sql")"; GEN_BEFORE="$(sql "SELECT value FROM settings WHERE key='generation'")"
FKOUT="$(python3 - "$R" "$APP" <<'PYEOF' 2>&1
import importlib.util, sys, os
root, app = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("releases_app", app)
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
real = ra._migration_004
def boom(conn):
    real(conn)
    raise RuntimeError("injected failure inside migration 004")
ra.MIGRATIONS[4] = {"apply": boom, "txn_safe": True}
conn = ra.connect(os.path.join(root, "releases.db"))
try:
    ra.perform_migration(root, conn)
    print("NO-RAISE")
except RuntimeError:
    print("raised")
print("fk=%d" % conn.execute("PRAGMA foreign_keys").fetchone()[0])
PYEOF
)"
if has "$FKOUT" "raised" && has "$FKOUT" "fk=1"; then ok "a failure mid-migration propagates and RESTORES foreign-key enforcement on the connection" 0; else ok "migration failure restores FK" 1; fi
ok "neither pending migration survives: the ledger is still {1,2} (003 did NOT commit mid-flight)" "$(is "$(ledger)" "1,2"; echo $?)"
N="$(sql "SELECT COUNT(*) FROM pragma_table_info('roadmap_items') WHERE name LIKE 'rating_%'")"
N2="$(sql "SELECT COUNT(*) FROM pragma_table_info('releases') WHERE name = 'baseline_count'")"
if [ "$N" = "0" ] && [ "$N2" = "0" ]; then ok "neither migration's SCHEMA survives either (all-or-nothing across both)" 0; else ok "no schema survives" 1; fi
GEN_AFTER="$(sql "SELECT value FROM settings WHERE key='generation'")"
if [ "$GEN_BEFORE" = "$GEN_AFTER" ] && [ "$(md5 -q "$R/releases.sql")" = "$DUMP_HASH" ]; then ok "no generation bump and no staged dump: the receipt/artifact protocol never reached its stamp" 0; else ok "no generation bump" 1; fi
if [ -f "$R/.git/releases-app-journal.json" ]; then ok "the journal is LEFT IN PLACE — an interrupted migration stops the world, unlike a refused write" 0; else ok "journal left" 1; fi
rout check
V="$(rlog check)"; if has "$V" "check: clean" && [ ! -f "$R/.git/releases-app-journal.json" ]; then ok "plain check recovers the interrupted migration (pre-COMMIT: discarded) and clears the journal" 0; else ok "migration recovery" 1; fi
rout migrate
ok "after recovery the same migration succeeds and reaches the registry" "$(is "$(ledger)" "$REGISTRY"; echo $?)"

# ── baselines: the kickoff denominator ──────────────────────────────────────────────────────────
R="$(mkrepo n4)"
rout init --slug nu4
rout add --version 1.0.0 --status draft --description "Dial first." --tracking-issue "https://github.com/A/B/issues/1"
B1="$(sql "SELECT global_id FROM releases WHERE version='1.0.0'")"
rout manifest dial-in --gid "$B1" "https://github.com/A/B/issues/21" --reason "first"
rout manifest dial-in --gid "$B1" "https://github.com/A/B/issues/22" --reason "second"
rout update --gid "$B1" --status active
BC="$(sql "SELECT baseline_count || '/' || baseline_source FROM releases WHERE global_id='$B1'")"
ok "draft -> active with a NON-EMPTY manifest captures the baseline automatically, flagged observed" "$(is "$BC" "2/observed"; echo $?)"
rout manifest dial-in --gid "$B1" "https://github.com/A/B/issues/23" --reason "scope growth"
rout update --gid "$B1" --status draft
rout update --gid "$B1" --status active
BC="$(sql "SELECT baseline_count FROM releases WHERE global_id='$B1'")"
ok "active -> draft -> active preserves the ORIGINAL snapshot silently (a legitimate round trip must not fail)" "$(is "$BC" "2"; echo $?)"
V="$(rlog baseline --gid "$B1")"
if has "$V" "rule=baseline-already-set"; then ok "the EXPLICIT verb refuses a second capture — write-once, because overwriting erases what it measures" 0; else ok "baseline write-once" 1; fi
OUT="$(sqlite3 "$R/releases.db" "UPDATE releases SET baseline_count = 99 WHERE global_id='$B1'" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "write-once"; then ok "write-once is STRUCTURAL: a direct DB writer is refused by trigger, not merely detected" 0; else ok "write-once trigger" 1; fi
OUT="$(sqlite3 "$R/releases.db" "UPDATE releases SET baseline_at = NULL WHERE global_id='$B1'" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "all-NULL or all-populated"; then ok "a PARTIAL baseline is refused by trigger (count without provenance can never reach rendering)" 0; else ok "baseline shape trigger" 1; fi

# the activate-first path: no draft->active transition to hook, so it lands baseline-less
rout add --version 2.0.0 --status active --description "Activate first." --tracking-issue "https://github.com/A/B/issues/2"
B2="$(sql "SELECT global_id FROM releases WHERE version='2.0.0'")"
N="$(sql "SELECT COUNT(*) FROM releases WHERE global_id='$B2' AND baseline_count IS NULL")"
ok "\`add --status active\` lands BASELINE-LESS (not a misleading zero) — there is no transition to hook" "$(is "$N" "1"; echo $?)"
V="$(rlog baseline --gid "$B2")"
if has "$V" "rule=baseline-empty-manifest"; then ok "capturing a baseline on an EMPTY manifest is refused — zero would report every later commitment as growth" 0; else ok "empty baseline refusal" 1; fi
rout manifest dial-in --gid "$B2" "https://github.com/A/B/issues/24" --reason "late dial"
rout baseline --gid "$B2"
BC="$(sql "SELECT baseline_count || '/' || baseline_source FROM releases WHERE global_id='$B2'")"
ok "the explicit verb fills the activate-first case afterwards (1/observed)" "$(is "$BC" "1/observed"; echo $?)"
# a release activated with an empty manifest takes NO baseline rather than a zero
rout add --version 3.0.0 --status draft --description "Empty at activation." --tracking-issue "https://github.com/A/B/issues/3"
B3="$(sql "SELECT global_id FROM releases WHERE version='3.0.0'")"
rout update --gid "$B3" --status active
N="$(sql "SELECT COUNT(*) FROM releases WHERE global_id='$B3' AND baseline_count IS NULL")"
ok "activating an EMPTY manifest takes no baseline at all — baseline-less is the honest state" "$(is "$N" "1"; echo $?)"

# ── the live-row rule: cut -> redial -> cut on ONE release ──────────────────────────────────────
rout manifest cut --gid "$B1" "https://github.com/A/B/issues/21" --reason "descoped"
rout manifest dial-in --gid "$B1" "https://github.com/A/B/issues/21" --reason "re-admitted"
V="$(rlog manifest cut --gid "$B1" "https://github.com/A/B/issues/21" --reason "descoped again")"
N="$(sql "SELECT COUNT(*) FROM manifest_items mi JOIN issue_refs t ON t.id=mi.issue_ref_id WHERE t.url='https://github.com/A/B/issues/21' AND mi.state='cut'")"
if [ "$N" = "2" ]; then ok "cut -> redial -> cut on ONE release works: transitions select the LIVE row, not the historical one" 0; else ok "cut-redial-cut" 1; fi
rout manifest ship --gid "$B1" "https://github.com/A/B/issues/22" --evidence "landed in abc1234"
N="$(sql "SELECT COUNT(*) FROM manifest_items WHERE state='shipped'")"
ok "manifest ship moves a dialed-in member to shipped (mid-release progress is finally reportable)" "$(is "$N" "1"; echo $?)"

# ── the marathon invariant SQLite cannot express ────────────────────────────────────────────────
R="$(mkrepo n5)"
rout init --slug nu5
rout marathon add --tracking-issue "https://github.com/A/B/issues/70"
M1="$(sql "SELECT global_id FROM marathons LIMIT 1")"
rout add --version 1.0.0 --status draft --description "With a marathon." --marathon "$M1" --tracking-issue "https://github.com/A/B/issues/1"
rout add --version 2.0.0 --status draft --description "Without one." --tracking-issue "https://github.com/A/B/issues/2"
MR1="$(sql "SELECT global_id FROM releases WHERE version='1.0.0'")"
MR2="$(sql "SELECT global_id FROM releases WHERE version='2.0.0'")"
V="$(rlog manifest dial-in --gid "$MR2" "https://github.com/A/B/issues/31" --reason x --marathon "$M1")"
if has "$V" "rule=marathon-not-this-release"; then ok "dialing in with ANOTHER release's marathon is refused by name (the door #109 came through)" 0; else ok "marathon-not-this-release" 1; fi
OUT="$(sqlite3 "$R/releases.db" "UPDATE releases SET marathon_id = (SELECT id FROM marathons LIMIT 1) WHERE global_id='$MR2'" 2>&1)"; RC=$?
if [ $RC -ne 0 ] && has "$OUT" "UNIQUE"; then ok "a marathon cannot be named by two releases (partial unique index; links are permanent)" 0; else ok "marathon exclusivity" 1; fi

# ── the extended dump grammar survives a round trip ─────────────────────────────────────────────
rout manifest dial-in --gid "$MR1" "https://github.com/A/B/issues/32" --reason "carries a marathon" --marathon "$M1"
if grep -qE '^INSERT INTO manifest_items\(global_id, release_gid, issue_ref_gid, state, dialed_in_at, dial_reason, marathon_gid\)' "$R/releases.sql"; then ok "the manifest record's three new fields ride the dump in fixed trailing order, marathon by GID" 0; else ok "manifest dump grammar" 1; fi
if ! grep -qE 'INSERT INTO manifest_items\([^)]*marathon_id' "$R/releases.sql"; then ok "and marathon_id (an integer FK) never appears as a dump value" 0; else ok "no integer FK in dump" 1; fi
BD_BEFORE="$(python3 - "$R" "$APP" <<'PYEOF4'
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("releases_app", sys.argv[2])
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
print(ra.business_digest(ra.connect(os.path.join(sys.argv[1], "releases.db"))))
PYEOF4
)"
DIAL_BEFORE="$(sql "SELECT dial_reason FROM manifest_items ORDER BY id DESC LIMIT 1")"
rout check --rebuild
BD_AFTER="$(python3 - "$R" "$APP" <<'PYEOF5'
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("releases_app", sys.argv[2])
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
print(ra.business_digest(ra.connect(os.path.join(sys.argv[1], "releases.db"))))
PYEOF5
)"
DIAL_AFTER="$(sql "SELECT dial_reason FROM manifest_items ORDER BY id DESC LIMIT 1")"
MG_AFTER="$(sql "SELECT COUNT(*) FROM manifest_items WHERE marathon_id IS NOT NULL")"
if [ "$BD_BEFORE" = "$BD_AFTER" ] && [ "$DIAL_AFTER" = "$DIAL_BEFORE" ] && [ "$MG_AFTER" = "1" ]; then ok "a dump -> rebuild round trip preserves every new column AND the business digest" 0; else ok "round trip preserves new columns" 1; fi
V="$(rlog check)"; if has "$V" "check: clean"; then ok "the rebuilt ledger's manifest event digest chain still verifies" 0; else ok "digest chain after rebuild" 1; fi

# ── a merged dump that stamped the same migration twice ─────────────────────────────────────────
python3 - "$R/releases.sql" <<'PYEOF6'
import sys
path = sys.argv[1]
lines = open(path).read().splitlines()
out = []
doubled = False
for line in lines:
    out.append(line)
    if not doubled and line.startswith("INSERT INTO schema_migrations("):
        out.append(line)     # the union merge's signature damage: the same version twice
        doubled = True
assert doubled, "no schema_migrations row found in the dump"
open(path, "w").write("\n".join(out) + "\n")
PYEOF6
V="$(rlog check --rebuild)"
if has "$V" "rule=dump-duplicate-migration"; then ok "a merged dump carrying a duplicate schema_migrations version is refused BY NAME, before anything is written" 0; else ok "duplicate migration refusal" 1; fi

echo
echo "== gh32-releases-app: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
