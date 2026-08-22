#!/usr/bin/env bash
# GH-128 Phase 3: HQ dispatch — `queue` (append lane to a Marathon Plan) + `fire` (gated hand-off).
# Hermetic: fixture registries + fixture repos under a temp dir. No network, no harness driven — `fire`
# only PREPARES a command (operator decides, §8), so there is nothing live to stub.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-dispatch (GH-128 queue + fire) =="

command -v git >/dev/null 2>&1 || { echo "  SKIP: git absent"; echo "== hq-dispatch: 0 passed, 0 failed =="; exit 0; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

PDDA_DIR="$TMP/gitpulse/pdda"; mkdir -p "$PDDA_DIR"
{ printf 'beta-app\t2026-07-04T00:00:00Z\tobserve\taa11\tyes\n'
  printf 'delta-app\t2026-07-04T00:00:00Z\tobserve\tbb22\tno\n'
  printf 'gamma-b\t2026-07-04T00:00:00Z\tobserve\tcc33\tno\n'
} > "$PDDA_DIR/registry-testdev.tsv"

mk_repo(){ local d="$1"; git init -q "$d"; mkdir -p "$d/PROJECT/2-WORKING"; printf 'observe\n' > "$d/.pdda-mode"; }

BETA="$TMP/repos/beta-app";   mk_repo "$BETA"     # Tier A, HAS a marathon plan
: > "$BETA/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-04.md"
printf '# plan\n' > "$BETA/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-04.md"
DELTA="$TMP/repos/delta-app"; mk_repo "$DELTA"    # Tier A, NO marathon plan
GAMMA="$TMP/repos/gamma-b";   mk_repo "$GAMMA"    # Tier B (PDDA only, no XYZ)
EPS="$TMP/repos/epsilon-bare"; git init -q "$EPS" # Tier C (bare)

# XYZ registry: only beta + delta have installs (-> Tier A); gamma/epsilon do not
XYZ_REG="$TMP/xyz.tsv"
{ printf '%s/.xyz\t2026-07-04T00:00:00Z\t0.2.0\tzz00\t%s\n' "$BETA" "$BETA"
  printf '%s/.xyz\t2026-07-04T00:00:00Z\t0.2.0\tzz00\t%s\n' "$DELTA" "$DELTA"
} > "$XYZ_REG"

export HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" HQ_XYZ_REGISTRY="$XYZ_REG"
export HQ_REBALANCE_DB="$TMP/none.db" HQ_SEARCH_ROOTS="$TMP/repos"

PLAN="$BETA/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-04.md"

# ---- queue: preview writes nothing ----
OUT="$(bash "$HQ" queue beta-app "wire up the export button")"; rc=$?
[ "$rc" = 0 ] && pass "queue preview rc=0" || fail "queue preview rc=$rc"
grep -q "PREVIEW (writes nothing)" <<<"$(printf '%s\n' "$OUT")" && pass "queue preview labeled" || fail "no preview label"
grep -q 'HQ-queued' "$PLAN" && fail "queue preview mutated the plan" || pass "plan untouched by preview"

# ---- queue --create appends a non-destructive lane ----
OUT="$(bash "$HQ" queue --create --gh-issue 77 beta-app "wire up the export button")"; rc=$?
[ "$rc" = 0 ] && pass "queue --create rc=0" || fail "queue create rc=$rc"
grep -q 'HQ-queued: wire up the export button' "$PLAN" && pass "lane appended to plan" || fail "no lane in plan"
grep -q '#77' "$PLAN" && pass "issue link recorded in lane" || fail "issue link missing"
grep -q '^# plan' "$PLAN" && pass "existing plan content preserved (append-only)" || fail "plan content clobbered"

# ---- queue refuses when there is no marathon plan / no PDDA ----
bash "$HQ" queue delta-app "x" >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "queue refuses Tier-A repo with no plan (rc=1)" || fail "delta queue rc=$rc"
bash "$HQ" queue epsilon-bare "x" >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "queue refuses Tier C (no PDDA) rc=1" || fail "epsilon queue rc=$rc"

# ---- fire: gates ----
bash "$HQ" fire beta-app >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "fire without --gh-issue rc=2" || fail "fire no-issue rc=$rc"
bash "$HQ" fire --gh-issue 5 beta-app >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "fire with unknown risk refuses rc=1" || fail "fire no-risk rc=$rc"
bash "$HQ" fire --gh-issue 5 --risk 4 beta-app >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "fire risk>=3 refuses rc=1 (routes to human)" || fail "fire risk4 rc=$rc"
bash "$HQ" fire --gh-issue 5 --risk 2 gamma-b >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "fire refuses non-Tier-A (Tier B) rc=1" || fail "fire tierB rc=$rc"
bash "$HQ" fire --gh-issue 5 --risk 2 nope-nope >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "fire unresolved rc=1" || fail "fire unresolved rc=$rc"

# ---- fire: gates PASS -> prepares (never executes) ----
OUT="$(bash "$HQ" fire --gh-issue 5 --risk 2 beta-app)"; rc=$?
[ "$rc" = 0 ] && pass "fire Tier A + risk 2 rc=0" || fail "fire pass rc=$rc"
grep -q 'swarm-preflight.sh --gh-issue 5' <<<"$(printf '%s\n' "$OUT")" && pass "emits swarm-preflight command" || fail "no preflight cmd"
grep -qi 'operator decides' <<<"$(printf '%s\n' "$OUT")" && pass "states operator-decides (no auto-drive)" || fail "no operator-decides note"
grep -qi 'nothing was executed' <<<"$(printf '%s\n' "$OUT")" && pass "confirms nothing executed" || fail "no not-executed note"

echo "== hq-dispatch: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
