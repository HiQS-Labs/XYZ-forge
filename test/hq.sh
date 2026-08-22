#!/usr/bin/env bash
# GH-128 Phase 1: HQ read-only resolver + project card.
# Hermetic — builds fixture registries in a temp dir and points the HQ_* env seams at them, so the
# result never depends on this machine's live registries. Covers: 3-registry Tier-A resolution,
# filesystem-fallback resolution, PDDA-only Tier B, bare Tier C, and the unresolved path.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq (GH-128 resolver + project card) =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fixture: git-pulse PDDA registry (two device files) ---
PDDA_DIR="$TMP/gitpulse/pdda"; mkdir -p "$PDDA_DIR"
{ printf '# comment header ignored\n'
  printf 'acme-app\t2026-07-04T00:00:00Z\tobserve\tabc1234\tyes\n'
  printf 'acme-api\t2026-07-04T00:00:00Z\tobserve\tabc9999\tno\n'   # shares the "acme" prefix -> ambiguity
  printf 'orphan-pdda\t2026-07-04T00:00:00Z\tfull\tdef5678\tno\n'
} > "$PDDA_DIR/registry-testdev.tsv"

# --- fixture: a real-enough repo tree for acme-app (resolved via XYZ path) ---
ACME="$TMP/repos/acme-app"; mkdir -p "$ACME/.git" "$ACME/PROJECT/2-WORKING" "$ACME/utils/pdda"
printf 'observe\n' > "$ACME/.pdda-mode"
: > "$ACME/ROUTER.md"; : > "$ACME/AGENTS.md"; : > "$ACME/ROADMAP.md"
: > "$ACME/utils/pdda/pdda.sh"
: > "$ACME/PROJECT/2-WORKING/SOMETHING.md"
: > "$ACME/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-04.md"  # counts as a working doc
: > "$ACME/PROJECT/2-WORKING/blank.md"                     # scaffolding — must NOT be counted

# --- fixture: a filesystem-only repo (in no registry) ---
FSONLY="$TMP/repos/fsonly-app"; mkdir -p "$FSONLY/.git"

# --- fixture: XYZ install registry (absolute paths) ---
XYZ_REG="$TMP/xyz-registry.tsv"
{ printf '# install_dir\tlast\ttick\tcommit\tcoordinated_repo\n'
  printf '%s/.xyz\t2026-07-04T00:00:00Z\t0.2.0\tcafe999\t%s\n' "$ACME" "$ACME"
  # GH-159 regression: same path twice (e.g. from a legacy install + a current vendored install)
  printf '%s/xyz-tick\t2026-07-04T00:00:00Z\t0.1.0\tabcdef\t%s\n' "$ACME" "$ACME"
} > "$XYZ_REG"

# --- fixture: rebalance project_registry (sqlite; optional) ---
REBAL_DB="$TMP/rebalance.db"; HAVE_SQLITE=0
if command -v sqlite3 >/dev/null 2>&1; then
  HAVE_SQLITE=1
  sqlite3 "$REBAL_DB" "CREATE TABLE project_registry (name TEXT PRIMARY KEY, status TEXT, summary TEXT, value_level TEXT, priority_tier INTEGER, risk_level TEXT, repos_json TEXT, tags_json TEXT, custom_fields_json TEXT);" 2>/dev/null
  sqlite3 "$REBAL_DB" "INSERT INTO project_registry (name,status,value_level,priority_tier,repos_json) VALUES ('TestOrg/acme-app','active','high',2,'[\"TestOrg/acme-app\"]');" 2>/dev/null
fi

export HQ_PDDA_REGISTRY_DIR="$PDDA_DIR"
export HQ_XYZ_REGISTRY="$XYZ_REG"
export HQ_REBALANCE_DB="$REBAL_DB"
export HQ_SEARCH_ROOTS="$TMP/repos"

field(){ sed -n "s/^$1=//p" | head -1; }

# ---- 1. Tier-A resolution: name -> repo via all three registries ----
R="$(bash "$HQ" resolve acme-app)"; rc=$?
[ "$rc" = 0 ] && pass "resolve acme-app rc=0" || fail "resolve acme-app rc=$rc"
[ "$(printf '%s\n' "$R" | field REPO)" = "acme-app" ] \
  && pass "REPO=acme-app" || fail "REPO wrong: $(printf '%s\n' "$R" | field REPO)"
[ "$(printf '%s\n' "$R" | field REPO_PATH)" = "$ACME" ] \
  && pass "REPO_PATH via xyz" || fail "REPO_PATH: $(printf '%s\n' "$R" | field REPO_PATH)"
[ "$(printf '%s\n' "$R" | field REPO_PATH_SOURCE)" = "xyz-registry" ] \
  && pass "path source = xyz-registry" || fail "path source: $(printf '%s\n' "$R" | field REPO_PATH_SOURCE)"
[ "$(printf '%s\n' "$R" | field PDDA_MODE)" = "observe" ] \
  && pass "PDDA_MODE=observe (git-pulse)" || fail "PDDA_MODE: $(printf '%s\n' "$R" | field PDDA_MODE)"
[ "$(printf '%s\n' "$R" | field PDDA_DEVICE)" = "testdev" ] \
  && pass "PDDA_DEVICE=testdev" || fail "PDDA_DEVICE: $(printf '%s\n' "$R" | field PDDA_DEVICE)"
if [ "$HAVE_SQLITE" = 1 ]; then
  [ "$(printf '%s\n' "$R" | field REBAL_TIER)" = "2" ] \
    && pass "REBAL_TIER=2 (rebalance)" || fail "REBAL_TIER: $(printf '%s\n' "$R" | field REBAL_TIER)"
else
  echo "  SKIP: rebalance assertions (sqlite3 absent)"
fi

# ---- 2. project card is Tier A and counts active docs correctly (blank.md excluded) ----
CARD="$(bash "$HQ" status acme-app)"; rc=$?
[ "$rc" = 0 ] && pass "status acme-app rc=0" || fail "status rc=$rc"
printf '%s\n' "$CARD" | grep -q "Tier A" && pass "card shows Tier A" || fail "card tier: $(printf '%s\n' "$CARD" | grep -i capability)"
grep -q "active docs:  2 " <<<"$(printf '%s\n' "$CARD")" && pass "active docs = 2 (blank.md excluded, marathon counted)" \
  || fail "active-doc count: $(printf '%s\n' "$CARD" | grep -i 'active docs')"
grep -q "MARATHON-PLAN-2026-07-04.md" <<<"$(printf '%s\n' "$CARD")" && pass "marathon plan surfaced" \
  || fail "marathon line: $(printf '%s\n' "$CARD" | grep -i marathon)"

# ---- 3. filesystem-fallback resolution (repo in NO registry, only on disk) ----
R2="$(bash "$HQ" resolve fsonly-app)"; rc=$?
[ "$rc" = 0 ] && pass "resolve fsonly-app rc=0 (fs fallback)" || fail "fsonly rc=$rc"
[ "$(printf '%s\n' "$R2" | field REPO_PATH_SOURCE)" = "filesystem" ] \
  && pass "path source = filesystem" || fail "fsonly source: $(printf '%s\n' "$R2" | field REPO_PATH_SOURCE)"
# fsonly has no PDDA + no XYZ -> Tier C
grep -q "Tier C" <<<"$(bash "$HQ" status fsonly-app)" && pass "fsonly is Tier C" \
  || fail "fsonly tier: $(bash "$HQ" status fsonly-app | grep -i capability)"

# ---- 4. Tier B: PDDA-registered but no XYZ install and no path on disk -> unresolved-but-known ----
# orphan-pdda is in the PDDA registry only; with no path it must NOT crash and must report unresolved.
bash "$HQ" resolve orphan-pdda >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "orphan-pdda unresolved rc=1 (known to PDDA, no path)" || fail "orphan-pdda rc=$rc"

# ---- 5. unresolved: unknown name -> rc=1 + helpful recipe ----
bash "$HQ" status nope-not-here >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "unknown name rc=1" || fail "unknown rc=$rc"
grep -q "UNRESOLVED" <<<"$(bash "$HQ" status nope-not-here 2>&1)" && pass "unresolved card shown" \
  || fail "no UNRESOLVED marker"

# ---- 5b. fuzzy resolution: a loose name normalizes to the canonical repo ----
R="$(bash "$HQ" resolve AcmeApp)"; rc=$?
[ "$rc" = 0 ] && pass "fuzzy 'AcmeApp' resolves rc=0" || fail "fuzzy rc=$rc"
[ "$(printf '%s\n' "$R" | field REPO)" = "acme-app" ] \
  && pass "fuzzy -> REPO=acme-app" || fail "fuzzy REPO: $(printf '%s\n' "$R" | field REPO)"
[ "$(printf '%s\n' "$R" | field RESOLVED_VIA)" = "fuzzy" ] \
  && pass "RESOLVED_VIA=fuzzy" || fail "via: $(printf '%s\n' "$R" | field RESOLVED_VIA)"
[ "$(bash "$HQ" resolve acme-app | field RESOLVED_VIA)" = "exact" ] \
  && pass "exact match stays RESOLVED_VIA=exact" || fail "exact via mislabeled"

# ---- 5c. ambiguous name -> rc=2 + candidates listed (no guess) ----
bash "$HQ" resolve acme >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "ambiguous 'acme' rc=2" || fail "ambiguous rc=$rc"
CANDS="$(bash "$HQ" resolve acme | field CANDIDATES)"
{ printf '%s' "$CANDS" | grep -q "acme-app" && printf '%s' "$CANDS" | grep -q "acme-api"; } \
  && pass "ambiguous lists both candidates" || fail "candidates: $CANDS"
bash "$HQ" park acme "do a thing" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "park refuses ambiguous rc=2" || fail "park ambiguous rc=$rc"

# ---- 6. dispatch verbs (queue/fire) covered by test/hq-dispatch.sh ----

echo "== hq: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
