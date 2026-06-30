#!/usr/bin/env bash
# oracle-guard.sh test — Part C loop oracle-immutability guard (#50).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
G="$HERE/../relay-automation/oracle-guard.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: oracle-guard =="

run(){ OUT="$(bash "$G" "$@" 2>&1)"; RC=$?; }

# disjoint artifact vs oracle -> safe
run --allow "src/foo.js" --oracle "spec/foo.spec,validate.sh"
[ "$RC" = 0 ] && pass "disjoint builder/oracle -> OK (exit 0)" || fail "rc=$RC out=$OUT"

# exact same path -> overlap
run --allow "validate.sh" --oracle "validate.sh"
{ [ "$RC" = 9 ] && case "$OUT" in *OVERLAP*) true;; *) false;; esac; } && pass "exact same path -> OVERLAP (exit 9)" || fail "rc=$RC out=$OUT"

# builder dir CONTAINS the oracle file (src/** vs src/paths.js) -> overlap (fail-safe ancestor catch)
run --allow "src/**" --oracle "src/paths.js"
[ "$RC" = 9 ] && pass "ancestor dir (src/**) vs oracle child -> OVERLAP" || fail "rc=$RC out=$OUT"

# builder writes the test dir that holds the oracle -> overlap (the real failure: editing tests)
run --allow "test/**" --oracle "test/path-overlap.sh"
[ "$RC" = 9 ] && pass "builder allowed into test/ that holds the oracle -> OVERLAP" || fail "rc=$RC out=$OUT"

# realistic legitimate config: artifact src file, oracle = tests + validate
run --allow "src/cost.js" --oracle "test/cost.sh,validate.sh,relay-automation/measure.sh"
[ "$RC" = 0 ] && pass "realistic disjoint config -> OK" || fail "rc=$RC out=$OUT"

# env-var form (flags absent)
OUT="$(ALLOW_PATHS='src/foo.js' ORACLE_PATHS='spec/foo.spec' bash "$G" 2>&1)"; RC=$?
[ "$RC" = 0 ] && pass "reads ALLOW_PATHS/ORACLE_PATHS from env" || fail "env rc=$RC out=$OUT"
OUT="$(ALLOW_PATHS='lib/x' ORACLE_PATHS='lib/x' bash "$G" 2>&1)"; RC=$?
[ "$RC" = 9 ] && pass "env-form overlap still caught" || fail "env overlap rc=$RC out=$OUT"

# missing oracle / allow -> usage
bash "$G" --allow "src/foo.js" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "missing --oracle -> usage (exit 2)" || fail "expected 2 got $rc"
bash "$G" --oracle "test/x" >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && pass "missing --allow -> usage (exit 2)" || fail "expected 2 got $rc"

# Codex review: aliasing must NOT bypass the guard (canonicalize before overlap)
ROOT="$(cd "$HERE/.." && pwd)"
run --allow "relay-automation/../src/paths.js" --oracle "src/paths.js"
[ "$RC" = 9 ] && pass "'..' alias resolving to the oracle is caught (exit 9)" || fail "alias bypass: rc=$RC out=$OUT"
# a symlink whose target IS an oracle file must be caught
SL="${TMPDIR:-/tmp}/og-alias.$$.sh"; ln -sf "$ROOT/validate.sh" "$SL"
run --allow "$SL" --oracle "validate.sh"
[ "$RC" = 9 ] && pass "symlink to an oracle file is caught (exit 9)" || fail "symlink bypass: rc=$RC out=$OUT"
rm -f "$SL"

echo "  oracle-guard: $PASS pass, $FAIL fail"
[ "$FAIL" = 0 ]
