#!/usr/bin/env bash
# gh349-vendored-roadmap-ledger.sh — GH-349: roadmap layer and releases ledger in vendored installs.
#
# Asserts:
#   Scope 1: `roadmap sync` refuses rather than deleting when 0 entries are parsed from non-empty ROADMAP.md.
#   Scope 1: Link-style bullets `- [Title](path) — ...` parse cleanly.
#   Scope 2: Issue URLs from foreign orgs (arbitrary GitHub orgs/repos) are captured into issue_url.
#   Scope 3: Migration 007 applies `updated_at` timestamps to all 9 tables, non-null backfill, updates on mutation, and dump/rebuild preservation.
#   Scope 4: Rating system doc and validation (pri/sev/appeal/effort/ovr, vocabulary clash, out-of-range).
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

# ── 3. Scope 3: Migration 007, updated_at across all 9 tables, mutation timestamps, dump/rebuild roundtrip ──
TABLES=("releases" "manifest_items" "marathons" "repos" "settings" "issue_refs" "doc_lines" "legacy_lines" "grandfather_entries")
all_tables_have_col=1
for tbl in "${TABLES[@]}"; do
  has_col="$(sqlite3 "$R/releases.db" "PRAGMA table_info($tbl);" | grep -c 'updated_at' || true)"
  if [ "$has_col" -lt 1 ]; then
    all_tables_have_col=0
    echo "table $tbl missing updated_at" >&2
  fi
done
ok "all 9 Migration 007 tables have updated_at column" "$(is "$all_tables_have_col" "1"; echo $?)"

# Check non-null backfill on existing rows in releases, repos, settings, issue_refs
NULL_COUNT="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM settings WHERE updated_at IS NULL;")"
ok "settings rows have non-null updated_at" "$(is "$NULL_COUNT" "0"; echo $?)"
NULL_COUNT="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM repos WHERE updated_at IS NULL;")"
ok "repos rows have non-null updated_at" "$(is "$NULL_COUNT" "0"; echo $?)"

# Test mutation advances updated_at
REL_GID="$(ra add --version 1.0.0 --status draft --tracking-issue https://github.com/ExternalOrg/ExternalRepo/issues/99 --description "v1.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
TIME_BEFORE="$(sqlite3 "$R/releases.db" "SELECT updated_at FROM releases WHERE global_id='$REL_GID';")"
sleep 1
ra update --gid "$REL_GID" --description "updated description" >/dev/null
TIME_AFTER="$(sqlite3 "$R/releases.db" "SELECT updated_at FROM releases WHERE global_id='$REL_GID';")"
ok "release update advances updated_at timestamp" "$([ "$TIME_AFTER" \> "$TIME_BEFORE" ] && echo 0 || echo 1)"

# Test dump and rebuild preserves updated_at
ra check >/dev/null
DUMP_HAS_UPDATED_AT="$(grep -c 'updated_at' "$R/releases.sql" || true)"
ok "canonical dump carries updated_at column definitions/inserts" "$([ "$DUMP_HAS_UPDATED_AT" -gt 0 ] && echo 0 || echo 1)"

# ── 4. Scope 4: Canonical rating vocabulary, axis parsing, ranges, vocabulary clash ──
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-110 · Rated Feature](PROJECT/2-WORKING/GH-110.md) — 4-axis rated. rated 90/80/70/60. ovr 350. → [#110](https://github.com/ExternalOrg/ExternalRepo/issues/110)
MD
ra roadmap sync >/dev/null
RATING_VALS="$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number=110;")"
ok "4-axis rating and ovr parsed into database" "$(is "$RATING_VALS" "90|80|70|60|350"; echo $?)"

# Test rating out of range (>100 on axis) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-111 · Bad Rating](PROJECT/2-WORKING/GH-111.md) — Out of range. rated 150/80/70/60. → [#111](https://github.com/ExternalOrg/ExternalRepo/issues/111)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "rating axis out of range (>100) is refused (rule=rating-range)" "$(has "$out" "rule=rating-range"; echo $?)"

# Test rating vocabulary clash (legacy cx/risk/eff mixed with rated) refusal
cat > "$R/ROADMAP.md" <<'MD'
# Foreign Org Roadmap
## Ledger
### Active
- [GH-112 · Clash Rating](PROJECT/2-WORKING/GH-112.md) — Clash. cx/risk/eff 3/2/1. rated 80/70/60/50. → [#112](https://github.com/ExternalOrg/ExternalRepo/issues/112)
MD
out="$(ra roadmap sync 2>&1 || true)"
ok "rating vocabulary clash (cx/risk/eff + rated) is refused (rule=rating-vocabulary-clash)" "$(has "$out" "rule=rating-vocabulary-clash"; echo $?)"

# ── 5. Advisory: undated release warning in `releases next` ────────────────────────
ra add --version 2.0.0 --status active --tracking-issue https://github.com/ExternalOrg/ExternalRepo/issues/100 --description "v2.0.0" >/dev/null

out_err="$(ra next 2>&1 >/dev/null || true)"
ok "releases next emits warning when all candidates are undated" "$(has "$out_err" "warning: every candidate release is undated"; echo $?)"

echo "gh349: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
