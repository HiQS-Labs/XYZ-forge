#!/usr/bin/env bash
# GH-128 Phase 4: HQ `next` — Rebalance-priority-ranked project board.
# Hermetic: a fixture rebalance.db (sqlite) + fixture registries/repos under a temp dir.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-next (GH-128 priority board) =="

command -v sqlite3 >/dev/null 2>&1 || { echo "  SKIP: sqlite3 absent"; echo "== hq-next: 0 passed, 0 failed =="; exit 0; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- fixture: rebalance project_registry with three tiers (1 highest .. 5 lowest) ---
DB="$TMP/rebalance.db"
sqlite3 "$DB" "CREATE TABLE project_registry (name TEXT PRIMARY KEY, status TEXT, summary TEXT, value_level TEXT, priority_tier INTEGER, risk_level TEXT, repos_json TEXT, tags_json TEXT, custom_fields_json TEXT);"
sqlite3 "$DB" "INSERT INTO project_registry (name,priority_tier,repos_json) VALUES
  ('Org/top-proj',1,'[\"Org/top-proj\"]'),
  ('Org/mid-proj',3,'[\"Org/mid-proj\"]'),
  ('Org/low-proj',5,'[\"Org/low-proj\"]');"

# --- fixture: top-proj is Tier A (PDDA + XYZ); the others don't resolve ---
PDDA_DIR="$TMP/gitpulse/pdda"; mkdir -p "$PDDA_DIR"
printf 'top-proj\t2026-07-04T00:00:00Z\tobserve\tabc1\tyes\n' > "$PDDA_DIR/registry-testdev.tsv"
TOP="$TMP/repos/top-proj"; mkdir -p "$TOP/.git"; printf 'observe\n' > "$TOP/.pdda-mode"
XYZ_REG="$TMP/xyz.tsv"
printf '%s/.xyz\t2026-07-04T00:00:00Z\t0.2.0\tzz\t%s\n' "$TOP" "$TOP" > "$XYZ_REG"

export HQ_REBALANCE_DB="$DB" HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" HQ_XYZ_REGISTRY="$XYZ_REG"
export HQ_SEARCH_ROOTS="$TMP/repos"

OUT="$(bash "$HQ" next)"; rc=$?
[ "$rc" = 0 ] && pass "hq next rc=0" || fail "next rc=$rc"

# ordering: tier 1 before tier 3 before tier 5
line_top="$(printf '%s\n' "$OUT" | grep -n 'top-proj' | cut -d: -f1)"
line_mid="$(printf '%s\n' "$OUT" | grep -n 'mid-proj' | cut -d: -f1)"
line_low="$(printf '%s\n' "$OUT" | grep -n 'low-proj' | cut -d: -f1)"
{ [ -n "$line_top" ] && [ -n "$line_mid" ] && [ -n "$line_low" ] \
  && [ "$line_top" -lt "$line_mid" ] && [ "$line_mid" -lt "$line_low" ]; } \
  && pass "ranked by priority tier (1 -> 3 -> 5)" \
  || fail "ordering: top=$line_top mid=$line_mid low=$line_low"

# top-proj resolves Tier A (dispatch-eligible)
printf '%s\n' "$OUT" | grep -E 'top-proj .*A .*dispatch-eligible' >/dev/null \
  && pass "top-proj shown Tier A dispatch-eligible" \
  || fail "top-proj cap: $(printf '%s\n' "$OUT" | grep top-proj)"

# unresolved projects are labeled, not crashed
printf '%s\n' "$OUT" | grep -E 'mid-proj .*unresolved' >/dev/null \
  && pass "unresolved project labeled (not crashed)" \
  || fail "mid-proj row: $(printf '%s\n' "$OUT" | grep mid-proj)"

# --limit caps the board
n="$(bash "$HQ" next --limit 1 | grep -cE '^  [0-9]+ ')"
[ "$n" = 1 ] && pass "--limit 1 caps to one row" || fail "--limit produced $n rows"

# degrades cleanly with no rebalance DB
HQ_REBALANCE_DB="$TMP/none.db" bash "$HQ" next >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "no rebalance DB -> rc=1 (clean)" || fail "no-db rc=$rc"

echo "== hq-next: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
