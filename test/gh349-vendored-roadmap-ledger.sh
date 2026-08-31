#!/usr/bin/env bash
# gh349-vendored-roadmap-ledger.sh — GH-349: roadmap layer and releases ledger in vendored installs.
#
# Asserts:
#   Scope 1: `roadmap sync` refuses rather than deleting when 0 entries are parsed from non-empty ROADMAP.md.
#   Scope 1: Link-style bullets `- [Title](path) — ...` parse cleanly.
#   Scope 2: Issue URLs from foreign orgs (arbitrary GitHub orgs/repos) are captured into issue_url.
#   Scope 3: Migration 007 applies `updated_at` timestamps to all 9 tables from pre-migration state,
#            non-null backfill, direct rebuild from untouched v6 dump backfills all 9 tables,
#            updates advance timestamps (including settings.generation), exact timestamp preservation
#            across all non-generation tables with stable keys, and pinned rebuild timestamp on settings.generation.
#   Scope 4: Rating system doc and validation (shape refusal, axis ranges, ovr range/orphan, vocabulary clash).
#   Advisory: `releases next` warns when all candidates are undated.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
is(){ [ "$1" = "$2" ]; }
has(){ printf '%s' "$1" | grep -Fq "$2"; }

echo "== test: gh349-vendored-roadmap-ledger =="

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh349-vendored.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

mkrepo(){
  local r="$WORK/$1"
  mkdir -p "$r"
  git -C "$r" init -q -b main
  git -C "$r" config user.email test@invalid
  git -C "$r" config user.name test
  printf '%s\n' "$r"
}

R="$(mkrepo repo)"
require_fixture "$R" "fixture repo"

ra(){
  require_fixture "$R" "fixture repo"
  python3 "$APP" --root "$R" "$@"
}

ra init --slug vendored-repo >/dev/null

# ── 1. Scope 1 & 2: Link bullets and foreign org issue URLs ────────────────────────
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-101 · Custom Feature](PROJECT/2-WORKING/GH-101.md) — Link-style bullet format. rated 80/60/70/50. → [#101](https://github.com/ExternalOrg/ExternalRepo/issues/101)
- [External Pull Request](PROJECT/2-WORKING/GH-102.md) — External PR link. → [#102](https://github.com/OtherOrg/OtherRepo/pull/102)
- **GH-103 · Bold Format** — Standard format for comparison. rated 60/40/80/70. → [#103](https://github.com/ExternalOrg/ExternalRepo/issues/103)
MD

out="$(ra roadmap sync 2>&1)"
ok "roadmap sync parsed link-style bullets and bold bullets" "$(has "$out" "+3 added"; echo $?)"

# Check issue_url from foreign orgs
URL_101="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=101;")"
ok "foreign org issue url extracted properly" "$(is "$URL_101" "https://github.com/ExternalOrg/ExternalRepo/issues/101"; echo $?)"

URL_102="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE title='External Pull Request';")"
ok "foreign org pull url extracted properly" "$(is "$URL_102" "https://github.com/OtherOrg/OtherRepo/pull/102"; echo $?)"

COUNT_ITEMS="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
ok "all 3 items mirrored" "$(is "$COUNT_ITEMS" "3"; echo $?)"

# ── 2. Scope 1: Non-empty file with 0 parsed entries refuses and protects data ────
cat > "$R/ROADMAP.md" <<'MD'
# Malformed format where nothing is under ## Ledger
Some notes about the roadmap without a Ledger section.
MD

out="$(ra roadmap sync 2>&1 || true)"
ok "sync on non-empty roadmap with 0 parsed entries is refused (rule=roadmap-empty)" "$(has "$out" "rule=roadmap-empty"; echo $?)"

# Confirm data was NOT deleted
COUNT_AFTER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items;")"
ok "roadmap_items preserved without wipe" "$(is "$COUNT_AFTER" "3"; echo $?)"

# ── 3. Scope 3: Pre-migration fixture, direct rebuild from untouched v6 dump, non-null backfill, v7 exact preservation ──
R_PRE="$(mkrepo pre_mig_repo)"
require_fixture "$R_PRE" "pre-mig fixture repo"

# Build a pre-007 fixture (v6 schema migrations) with untouched v6 dump
python3 - "$R_PRE" "$APP" <<'PYPRE'
import sys, os, importlib.util
root = sys.argv[1]
app_path = sys.argv[2]
spec = importlib.util.spec_from_file_location("releases_app", app_path)
ra = importlib.util.module_from_spec(spec); spec.loader.exec_module(ra)
db_path = os.path.join(root, "releases.db")
conn = ra.connect(db_path, must_exist=False)
# Apply migrations 001 through 006 only
for v, m_spec in sorted(ra.MIGRATIONS.items()):
    if v < 7:
        m_spec["apply"](conn)
        conn.execute("INSERT INTO schema_migrations(version, applied_at) VALUES (?, ?)", (v, ra.now_iso()))
# Populate all 9 target tables without updated_at
conn.execute("INSERT INTO settings(key, value) VALUES ('enforcement', 'lenient')")
conn.execute("INSERT INTO settings(key, value) VALUES ('repo_slug', 'pre-repo')")
conn.execute("INSERT INTO settings(key, value) VALUES ('generation', '1')")
conn.execute("INSERT INTO repos(global_id, slug) VALUES ('repo-01ARZ3NDEKTSV4RRFFQ69G5FA0', 'pre-repo')")
conn.execute("INSERT INTO issue_refs(global_id, url, temp_id, created_at) VALUES ('ref-01ARZ3NDEKTSV4RRFFQ69G5FA1', 'https://github.com/A/B/issues/1', NULL, '2026-08-01T00:00:00Z')")
conn.execute("INSERT INTO marathons(global_id, repo_id, tracking_ref_id, status, created_at) VALUES ('mar-01ARZ3NDEKTSV4RRFFQ69G5FA2', 1, 1, 'running', '2026-08-01T00:00:00Z')")
conn.execute("""INSERT INTO releases(global_id, repo_id, version, codename, status, description, tracking_ref_id, marathon_id)
                VALUES ('rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 1, '1.0.0', 'Kickoff', 'active', 'pre-mig release', 1, 1)""")
conn.execute("""INSERT INTO manifest_items(global_id, release_id, issue_ref_id, state, dialed_in_at, dial_reason, marathon_id)
                VALUES ('mfi-01ARZ3NDEKTSV4RRFFQ69G5FA4', 1, 1, 'dialed_in', '2026-08-01T00:00:00Z', 'first item', 1)""")
conn.execute("INSERT INTO doc_lines(repo_id, position, content) VALUES (1, 0, '# Title')")
conn.execute("INSERT INTO legacy_lines(release_id, position, content) VALUES (1, 0, 'Legacy notes')")
conn.execute("""INSERT INTO grandfather_entries(import_run, release_gid, rule, source_value, supplied_value, disposition)
                VALUES ('imp-20260801', 'rel-01ARZ3NDEKTSV4RRFFQ69G5FA3', 'status-enum', 'Draft', 'draft', NULL)""")
paths = ra.artifact_paths(root)
ra._atomic_write(paths["dump"], ra.dump_text(conn, 1))
conn.commit()
conn.close()
PYPRE

# Test direct rebuild from untouched v6 dump (exercises loading pre-007 dump into v7 schema)
python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null

TABLES=("releases" "manifest_items" "marathons" "repos" "settings" "issue_refs" "doc_lines" "legacy_lines" "grandfather_entries")
all_rebuild_non_null=1
for tbl in "${TABLES[@]}"; do
  null_count="$(sqlite3 "$R_PRE/releases.db" "SELECT COUNT(*) FROM $tbl WHERE updated_at IS NULL;")"
  if [ "$null_count" -ne 0 ]; then
    all_rebuild_non_null=0
    echo "table $tbl has $null_count NULL updated_at rows after rebuild from untouched v6 dump" >&2
  fi
done
ok "direct rebuild from untouched v6 dump populates 100% non-NULL updated_at across all 9 tables" "$(is "$all_rebuild_non_null" "1"; echo $?)"

# Test newly created issue_ref has non-null updated_at
NEW_REF="$(python3 "$APP" --root "$R_PRE" add --version 2.0.0 --status draft --tracking-issue https://github.com/A/B/issues/2 --description "v2.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
REF_UPDATED_AT="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM issue_refs WHERE url='https://github.com/A/B/issues/2';")"
ok "newly inserted issue_ref has non-null updated_at" "$([ -n "$REF_UPDATED_AT" ] && echo 0 || echo 1)"

# Test timestamp advancement on mutation
GEN_TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
TIME_BEFORE="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
sleep 1
python3 "$APP" --root "$R_PRE" update --gid "$NEW_REF" --description "updated description" >/dev/null
GEN_TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
TIME_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM releases WHERE global_id='$NEW_REF';")"
ok "release update advances release updated_at timestamp" "$([ "$TIME_AFTER" \> "$TIME_BEFORE" ] && echo 0 || echo 1)"
ok "mutation advances settings.generation updated_at timestamp" "$([ "$GEN_TIME_AFTER" \> "$GEN_TIME_BEFORE" ] && echo 0 || echo 1)"

# Test dump and rebuild exact timestamp preservation across all non-generation tables using stable keys
python3 "$APP" --root "$R_PRE" check >/dev/null

snapshot_non_generation_tables(){
  local db="$1"
  echo "--- settings (non-generation) ---"
  sqlite3 "$db" "SELECT key, value, updated_at FROM settings WHERE key != 'generation' ORDER BY key;"
  echo "--- repos ---"
  sqlite3 "$db" "SELECT global_id, slug, updated_at FROM repos ORDER BY global_id;"
  echo "--- issue_refs ---"
  sqlite3 "$db" "SELECT global_id, COALESCE(url, temp_id), updated_at FROM issue_refs ORDER BY global_id;"
  echo "--- marathons ---"
  sqlite3 "$db" "SELECT global_id, status, updated_at FROM marathons ORDER BY global_id;"
  echo "--- releases ---"
  sqlite3 "$db" "SELECT global_id, version, updated_at FROM releases ORDER BY global_id;"
  echo "--- manifest_items ---"
  sqlite3 "$db" "SELECT global_id, state, updated_at FROM manifest_items ORDER BY global_id;"
  echo "--- doc_lines ---"
  sqlite3 "$db" "SELECT position, content, updated_at FROM doc_lines ORDER BY position;"
  echo "--- legacy_lines ---"
  sqlite3 "$db" "SELECT position, content, updated_at FROM legacy_lines ORDER BY position;"
  echo "--- grandfather_entries ---"
  sqlite3 "$db" "SELECT import_run, COALESCE(release_gid, '(doc)'), rule, updated_at FROM grandfather_entries ORDER BY import_run, id;"
}

SNAPSHOT_BEFORE="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
RELEASES_APP_NOW="2026-09-01T12:00:00Z" python3 "$APP" --root "$R_PRE" check --rebuild >/dev/null
SNAPSHOT_AFTER="$(snapshot_non_generation_tables "$R_PRE/releases.db")"
ok "check --rebuild preserves exact updated_at values across all non-generation tables" "$(is "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"; echo $?)"

GEN_AFTER="$(sqlite3 "$R_PRE/releases.db" "SELECT updated_at FROM settings WHERE key='generation';")"
ok "check --rebuild stamps pinned rebuild time into settings.generation.updated_at" "$(is "$GEN_AFTER" "2026-09-01T12:00:00Z"; echo $?)"

# ── 4. Scope 4: Canonical rating vocabulary, axis parsing, ranges, ovr, malformed shape, vocabulary clash ──
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-110 · Rated Feature](PROJECT/2-WORKING/GH-110.md) — 4-axis rated. rated 90/80/70/60. ovr 350. → [#110](https://github.com/ExternalOrg/ExternalRepo/issues/110)
MD
ra roadmap sync >/dev/null
RATING_VALS="$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number=110;")"
ok "4-axis rating and ovr parsed into database" "$(is "$RATING_VALS" "90|80|70|60|350"; echo $?)"

# Test malformed rating shape (e.g. 3 axes instead of 4) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-111 · Malformed Rating Shape](PROJECT/2-WORKING/GH-111.md) — Malformed shape. rated 70/40/55. → [#111](https://github.com/ExternalOrg/ExternalRepo/issues/111)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "malformed rating shape (rated 70/40/55) is refused (rule=rating-shape)" "$(has "$out" "rule=rating-shape"; echo $?)"

# Test rating axis out of range (>100 on axis) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-112 · Bad Rating Range](PROJECT/2-WORKING/GH-112.md) — Out of range. rated 150/80/70/60. → [#112](https://github.com/ExternalOrg/ExternalRepo/issues/112)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "rating axis out of range (>100) is refused (rule=rating-range)" "$(has "$out" "rule=rating-range"; echo $?)"

# Test ovr out of range (>400) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-113 · Bad OVR Range](PROJECT/2-WORKING/GH-113.md) — Bad ovr. rated 80/70/60/50. ovr 500. → [#113](https://github.com/ExternalOrg/ExternalRepo/issues/113)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "ovr out of range (>400) is refused (rule=ovr-range)" "$(has "$out" "rule=ovr-range"; echo $?)"

# Test orphan ovr (ovr without rated) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-114 · Orphan OVR](PROJECT/2-WORKING/GH-114.md) — Orphan ovr. ovr 300. → [#114](https://github.com/ExternalOrg/ExternalRepo/issues/114)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "orphan ovr without rated is refused (rule=ovr-orphan)" "$(has "$out" "rule=ovr-orphan"; echo $?)"

# Test rating vocabulary clash (legacy cx/risk/eff mixed with rated) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-115 · Clash Rating](PROJECT/2-WORKING/GH-115.md) — Clash. cx/risk/eff 3/2/1. rated 80/70/60/50. → [#115](https://github.com/ExternalOrg/ExternalRepo/issues/115)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "rating vocabulary clash (cx/risk/eff + rated) is refused (rule=rating-vocabulary-clash)" "$(has "$out" "rule=rating-vocabulary-clash"; echo $?)"

# ── 5. Advisory: undated release warning in `releases next` ────────────────────────
ra add --version 2.0.0 --status active --tracking-issue https://github.com/ExternalOrg/ExternalRepo/issues/100 --description "v2.0.0" >/dev/null

out_err="$(ra next 2>&1 >/dev/null || true)"
ok "releases next emits warning when all candidates are undated" "$(has "$out_err" "warning: every candidate release is undated"; echo $?)"

echo "gh349: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
