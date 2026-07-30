#!/usr/bin/env bash
#
# test/gh369-find-doc-root-resolution.sh — skills/10days/find-doc.sh root resolution + arg parsing.
#
# Two issues converge here:
#
#   GH-344 (PR #364) moved find-doc.sh from resolving PROJECT/** relative to ITS OWN LOCATION to
#   resolving it from the repo being SWEPT. That fix was verified by hand and never by CI, so
#   nothing stopped it regressing back to the harness-relative form.
#
#   GH-369 found two defects in the argument parser that fix introduced: `--root` with no value
#   spun forever (`shift 2` with one arg left shifts nothing and returns non-zero, and this script
#   is deliberately `-e`-exempt, so $# never decreased and $1 stayed `--root`), and a bad
#   $TENDAYS_ROOT reported `--root` — a flag the caller never passed — with an empty path.
#
# Every hang-capable case runs under a hard timeout, because the bug under test is an INFINITE
# LOOP: without the cap a regression hangs the suite instead of failing it, which is the same
# absent-signal shape the fix is about.

set -uo pipefail
# strict-mode: -e exempt — assertion harness; each case checks its own rc explicitly.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUT="$ROOT/skills/10days/find-doc.sh"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }

# Run the script under a wall-clock cap. Prints output; returns the script's rc, or 142 if the
# alarm fired. perl is used rather than `timeout` (GNU coreutils, not present by default on macOS).
run_capped() {
  perl -e 'alarm shift; exec @ARGV' 5 bash "$SUT" "$@" 2>&1
}

echo "== GH-369: find-doc.sh root resolution and argument parsing =="

[ -x "$SUT" ] || [ -f "$SUT" ] || { echo "  FAIL missing SUT: $SUT"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "  SKIP jq not on PATH"; exit 0; }

# --- Case 1: the infinite loop. THE regression this file exists for. -------------------------
out="$(run_capped --root)"
rc=$?
if [ "$rc" -eq 142 ]; then
  fail "case 1: \`--root\` with no value HUNG (rc=142/SIGALRM) — the GH-369 loop is back"
elif [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'requires a directory argument'; then
  pass "case 1: \`--root\` with no value exits 2 with a specific message, does not spin"
else
  fail "case 1: expected rc=2 + 'requires a directory argument', got rc=$rc: $out"
fi

# --- Case 2: a bad $TENDAYS_ROOT must name ITS OWN source, not --root ------------------------
out="$(TENDAYS_ROOT=/no/such/dir perl -e 'alarm shift; exec @ARGV' 5 bash "$SUT" 5 2>&1)"
rc=$?
if [ "$rc" -ne 2 ]; then
  fail "case 2: expected rc=2 for a bad \$TENDAYS_ROOT, got rc=$rc"
elif printf '%s' "$out" | grep -q -- '--root'; then
  fail "case 2: message blames --root, which was never passed: $out"
elif printf '%s' "$out" | grep -q 'TENDAYS_ROOT' && printf '%s' "$out" | grep -q '/no/such/dir'; then
  pass "case 2: bad \$TENDAYS_ROOT names its source AND the offending path"
else
  fail "case 2: message must name \$TENDAYS_ROOT and the path, got: $out"
fi

# --- Case 3: a bad --root still names --root, and prints the path ----------------------------
out="$(run_capped --root /no/such/dir 5)"
rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q -- '--root' && printf '%s' "$out" | grep -q '/no/such/dir'; then
  pass "case 3: bad --root reports --root and the path"
else
  fail "case 3: expected rc=2 naming --root and the path, got rc=$rc: $out"
fi

# --- Cases 4-6: GH-344 itself. Resolution must follow the SWEPT repo, not the script. --------
# Build two throwaway repos, each with a PROJECT/ tree, using the SAME issue number for
# DIFFERENT docs in DIFFERENT buckets. That collision is the real-world failure: both repos
# number issues from 1, so a harness-relative lookup answers with a coincidental match.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for r in alpha beta; do
  mkdir -p "$TMP/$r/PROJECT/1-INBOX" "$TMP/$r/PROJECT/2-WORKING" "$TMP/$r/PROJECT/3-COMPLETED"
  git -C "$TMP/$r" init -q 2>/dev/null
done
echo '# alpha' > "$TMP/alpha/PROJECT/3-COMPLETED/GH-777-ALPHA-DOC.md"
echo '# beta'  > "$TMP/beta/PROJECT/2-WORKING/GH-777-BETA-DOC.md"

bucket_of() { printf '%s' "$1" | jq -r '.bucket // "null"'; }
doc_of()    { printf '%s' "$1" | jq -r '.doc // "null"'; }

out="$(cd "$TMP/alpha" && run_capped 777)"
if [ "$(bucket_of "$out")" = "3-COMPLETED" ] && [ "$(doc_of "$out")" = "PROJECT/3-COMPLETED/GH-777-ALPHA-DOC.md" ]; then
  pass "case 4: from alpha's cwd, resolves alpha's own doc (3-COMPLETED)"
else
  fail "case 4: expected alpha/3-COMPLETED, got: $out"
fi

out="$(cd "$TMP/beta" && run_capped 777)"
if [ "$(bucket_of "$out")" = "2-WORKING" ] && [ "$(doc_of "$out")" = "PROJECT/2-WORKING/GH-777-BETA-DOC.md" ]; then
  pass "case 5: same issue number from beta's cwd resolves BETA's doc — not alpha's, not the harness's"
else
  fail "case 5: expected beta/2-WORKING, got: $out"
fi

# The anti-regression assertion proper. It must use an issue number that EXISTS IN THE HARNESS,
# or it proves nothing: with a number absent from both trees (777), the harness-relative bug and
# the correct behaviour both return null, and the case passes against the very code it is meant to
# catch. Verified: this case as originally written passed against pre-#364 find-doc.sh.
#
# So: pick a real GH-<N> doc from the harness's own PROJECT/ tree, then ask from a directory that
# is not a git repo and has no PROJECT/. Correct behaviour resolves $PWD and misses. A script that
# has drifted back to resolving from its own location answers with the harness's doc.
HARNESS_N="$(find "$ROOT/PROJECT" -maxdepth 2 -type f -name 'GH-*-*.md' 2>/dev/null \
  | head -1 | sed -E 's|.*/GH-([0-9]+)-.*|\1|')"
if [ -z "$HARNESS_N" ]; then
  echo "  SKIP case 6: no GH-<N>-*.md found under the harness PROJECT/ tree to probe with"
else
  out="$(cd "$TMP" && run_capped "$HARNESS_N")"
  if [ "$(bucket_of "$out")" = "null" ]; then
    pass "case 6: GH-$HARNESS_N exists in the harness, yet a non-repo cwd returns a clean miss"
  else
    fail "case 6: answered GH-$HARNESS_N from the HARNESS tree — harness-relative regression: $out"
  fi
fi

# --- Case 7: explicit --root and $TENDAYS_ROOT override cwd, and --root wins -----------------
out="$(cd "$TMP/alpha" && run_capped --root "$TMP/beta" 777)"
[ "$(bucket_of "$out")" = "2-WORKING" ] \
  && pass "case 7a: --root overrides cwd" \
  || fail "case 7a: --root did not override cwd: $out"

out="$(cd "$TMP/alpha" && TENDAYS_ROOT="$TMP/beta" perl -e 'alarm shift; exec @ARGV' 5 bash "$SUT" 777 2>&1)"
[ "$(bucket_of "$out")" = "2-WORKING" ] \
  && pass "case 7b: \$TENDAYS_ROOT overrides cwd" \
  || fail "case 7b: \$TENDAYS_ROOT did not override cwd: $out"

out="$(cd "$TMP" && TENDAYS_ROOT="$TMP/alpha" perl -e 'alarm shift; exec @ARGV' 5 bash "$SUT" --root "$TMP/beta" 777 2>&1)"
[ "$(bucket_of "$out")" = "2-WORKING" ] \
  && pass "case 7c: --root beats \$TENDAYS_ROOT (documented precedence)" \
  || fail "case 7c: precedence wrong — \$TENDAYS_ROOT won over --root: $out"

# --- Case 8: surviving argument handling (each capped; a parser bug tends to hang) -----------
out="$(run_capped)";               [ $? -eq 2 ] && pass "case 8a: no args exits 2"        || fail "case 8a: rc=$? out=$out"
out="$(run_capped --bogus 5)";     [ $? -eq 2 ] && pass "case 8b: unknown flag exits 2"   || fail "case 8b: rc=$? out=$out"
out="$(run_capped notanumber)";    [ $? -eq 2 ] && pass "case 8c: non-numeric exits 2"    || fail "case 8c: rc=$? out=$out"
out="$(run_capped --help)";        [ $? -eq 0 ] && pass "case 8d: --help exits 0"         || fail "case 8d: rc=$? out=$out"

# --- Case 9: a miss is exit 0 with valid JSON, not an error ----------------------------------
out="$(cd "$TMP/alpha" && run_capped 999)"
rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | jq -e '.doc == null and .bucket == null and .has_contract == false' >/dev/null 2>&1; then
  pass "case 9: a miss is exit 0 with well-formed JSON nulls"
else
  fail "case 9: expected rc=0 + null JSON, got rc=$rc: $out"
fi

echo
echo "gh369-find-doc-root-resolution: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
