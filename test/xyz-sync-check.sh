#!/usr/bin/env bash
# GH-96 — xyz-sync check: report-only drift detection between a vendored install's recorded
# (tick_version, source_commit) pair (stamped once at vendor time by register_vendor(), in
# xyz-vendor.sh) and this harness's CURRENT values. Covers: exact match (silent/ok),
# tick_version-only drift, source_commit-only drift, both drifted, --all over multiple
# registered installs, and the no-installs-registered / target-not-found graceful no-op that
# list/delete already have.
source "$(dirname "$0")/_setup.sh" xyz-sync-check

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
SYNC="$ROOT/relay-automation/xyz-sync.sh"

export XYZ_REGISTRY="$WORK/registry.tsv"

HEAD="$(git -C "$ROOT" rev-parse HEAD)"
CUR_VER="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$ROOT/src/events.js" | head -1)"
[ -n "$CUR_VER" ] || fail "could not read SCHEMA_VERSION from $ROOT/src/events.js for test setup"

mkdir -p "$WORK/repo1"; git init -q "$WORK/repo1"; REPO1="$(cd "$WORK/repo1" && pwd -P)"
mkdir -p "$WORK/repo2"; git init -q "$WORK/repo2"; REPO2="$(cd "$WORK/repo2" && pwd -P)"

"$VENDOR" "$REPO1" >/dev/null 2>&1 || fail "vendor repo1 exited non-zero"
"$VENDOR" "$REPO2" >/dev/null 2>&1 || fail "vendor repo2 exited non-zero"

# set_field <install_dir> <field-index 3=tick_version|4=source_commit> <value>
set_field() {
  local dir="$1" idx="$2" val="$3" tmp
  tmp="$XYZ_REGISTRY.tmp.$$"
  awk -F'\t' -v OFS='\t' -v d="$dir" -v i="$idx" -v v="$val" \
    '/^#/{print;next} NF==0{next} $1==d{$i=v} {print}' "$XYZ_REGISTRY" > "$tmp" && mv "$tmp" "$XYZ_REGISTRY"
}

# --- exact match: silent/ok, no DRIFT ---
out="$("$SYNC" check "$REPO1" 2>&1)"
echo "$out" | grep -q "DRIFT" && fail "exact match wrongly reported drift: $out"
echo "$out" | grep -q "ok    $REPO1/.xyz" && pass "exact match: ok line, no drift warning" \
  || fail "exact match produced no ok line: $out"

# --- tick_version-only drift ---
set_field "$REPO1/.xyz" 3 "bogus-version-9.9.9"
out="$("$SYNC" check "$REPO1" 2>&1)"
echo "$out" | grep -q "DRIFT $REPO1/.xyz (tick_version drifted)" \
  && pass "tick_version-only drift: detected and named, source_commit not blamed" \
  || fail "tick_version-only drift not reported correctly: $out"
echo "$out" | grep -q "recorded: tick_version=bogus-version-9.9.9 source_commit=$HEAD" \
  && pass "tick_version-only drift: recorded line shows the stale tick_version + matching commit" \
  || fail "tick_version-only drift: recorded line wrong: $out"
set_field "$REPO1/.xyz" 3 "$CUR_VER"

# --- source_commit-only drift ---
set_field "$REPO1/.xyz" 4 "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
out="$("$SYNC" check "$REPO1" 2>&1)"
echo "$out" | grep -q "DRIFT $REPO1/.xyz (source_commit drifted)" \
  && pass "source_commit-only drift: detected and named, tick_version not blamed" \
  || fail "source_commit-only drift not reported correctly: $out"
set_field "$REPO1/.xyz" 4 "$HEAD"

# --- both drifted ---
set_field "$REPO1/.xyz" 3 "bogus-version-9.9.9"
set_field "$REPO1/.xyz" 4 "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
out="$("$SYNC" check "$REPO1" 2>&1)"
echo "$out" | grep -q "DRIFT $REPO1/.xyz (tick_version,source_commit drifted)" \
  && pass "both fields drifted: both named together" \
  || fail "both-drifted case not reported correctly: $out"
echo "$out" | grep -q "current:  tick_version=$CUR_VER source_commit=$HEAD" \
  && pass "both-drifted: current line shows this harness's live values" \
  || fail "both-drifted: current line wrong: $out"
set_field "$REPO1/.xyz" 3 "$CUR_VER"
set_field "$REPO1/.xyz" 4 "$HEAD"

# --- --all over multiple registered installs: repo1 clean, repo2 drifted ---
set_field "$REPO2/.xyz" 3 "bogus-version-9.9.9"
out="$("$SYNC" check --all 2>&1)"
echo "$out" | grep -q "ok    $REPO1/.xyz" && pass "--all: clean install (repo1) reported ok" \
  || fail "--all missed repo1's ok line: $out"
echo "$out" | grep -q "DRIFT $REPO2/.xyz (tick_version drifted)" \
  && pass "--all: drifted install (repo2) reported DRIFT" \
  || fail "--all missed repo2's drift: $out"
set_field "$REPO2/.xyz" 3 "$CUR_VER"

# --- target not registered: graceful no-op, same as update/delete ---
mkdir -p "$WORK/unregistered"; git init -q "$WORK/unregistered"
UNREG="$(cd "$WORK/unregistered" && pwd -P)"
out="$("$SYNC" check "$UNREG" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "check on an unregistered target exits 0 (no new failure mode)" \
  || fail "check on an unregistered target exited $rc"
echo "$out" | grep -qi "no vendored registry rows matched" \
  && pass "check on an unregistered target: graceful message, same style as update/delete" \
  || fail "check on an unregistered target: unexpected output: $out"

# --- no installs registered at all: graceful no-op ---
EMPTY_REGISTRY="$WORK/empty-registry.tsv"
out="$(XYZ_REGISTRY="$EMPTY_REGISTRY" "$SYNC" check --all 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "check --all with no registry file exits 0 (no new failure mode)" \
  || fail "check --all with no registry file exited $rc"
echo "$out" | grep -qi "no vendored registry rows matched" \
  && pass "check --all with no registry file: graceful message" \
  || fail "check --all with no registry file: unexpected output: $out"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
