#!/usr/bin/env bash
# test/gh708-vendored-suite-skips.sh — GH-708: a suite that needs a forge-root-only path
# (validate.sh, githooks/, .github/, …) is red from every vendored .xyz/ because xyz-vendor.sh
# mirrors only VENDOR_DIRS. `require_forge_root` (test/lib/fixture-guard.sh) turns that into a
# WITNESSED skip in a vendored install and stays a loud refusal anywhere else.
#
#   A. vendored tree (VERSION with source_commit=) + missing path → `skip: not vendored — …`, rc 0,
#      and the suite body never runs
#   B. the same tree WITHOUT the VERSION stamp → rc 2, `forge-root: REFUSING` on stderr (red control:
#      a forge checkout that lost the file is broken, not skippable)
#   C. the path present → the helper is silent and the suite body runs
#   D. the real witness: xyz-vendor.sh this checkout into a throwaway target, then run the shipped
#      test/gh267-express-skill.sh from `.xyz/` — the pre-fix failure (`cp: … githooks/install.sh:
#      No such file`, rc 1) must be gone and the skip line present; sentinel-overlay.sh likewise.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
. "$HERE/lib/fixture-guard.sh"
require_forge_root sentinel-overlay githooks/install.sh relay-automation/xyz-vendor.sh   # this suite vendors the FORGE and asserts its forge-side behaviour

PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL: $*"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh708.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || exit 1
fixture_guard_init "$WORK"
trap 'rm -rf "$WORK"' EXIT

# ── A–C: a minimal vendored-shaped tree: <root>/VERSION, <root>/test/lib/fixture-guard.sh, a probe ──
V="$WORK/vendored"
mkdir -p "$V/test/lib"
require_fixture "$V" "vendored fixture"
cp "$ROOT/test/lib/fixture-guard.sh" "$V/test/lib/fixture-guard.sh"
cat > "$V/test/probe.sh" <<'EOF'
#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib/fixture-guard.sh"
require_forge_root validate.sh
echo "probe: body ran"
EOF
printf 'source_commit=deadbeefcafe\ntick_version=0.2.0\nvendored_utc=2026-09-18T00:00:00Z\ntier=2\n' > "$V/VERSION"

out="$(bash "$V/test/probe.sh" 2>"$WORK/errA")"; rc=$?
[ "$rc" -eq 0 ] && pass "A: vendored + missing path exits 0" || fail "A: rc=$rc (expected 0)"
grep -q '^skip: not vendored — probe.sh needs validate.sh (forge-root only; vendored source_commit=deadbeefcafe)$' <<<"$out" \
  && pass "A: skip line names the suite, the path and the vendored SHA" || fail "A: skip line wrong: '$out'"
grep -q 'probe: body ran' <<<"$out" && fail "A: suite body ran after the skip" || pass "A: suite body did not run"
[ -s "$WORK/errA" ] && fail "A: stderr not empty: $(cat "$WORK/errA")" || pass "A: nothing on stderr for a witnessed skip"

# B — red control: no VERSION stamp → this is not a vendored install; a missing forge file REFUSES.
rm -f "$V/VERSION"
out="$(bash "$V/test/probe.sh" 2>"$WORK/errB")"; rc=$?
[ "$rc" -eq 2 ] && pass "B: not vendored + missing path exits 2 (refusal, never a skip)" || fail "B: rc=$rc (expected 2)"
grep -q '^forge-root: REFUSING — probe.sh needs .*validate.sh and it is missing' "$WORK/errB" \
  && pass "B: refusal names the suite and the missing path on stderr" || fail "B: refusal text wrong: $(cat "$WORK/errB")"
grep -q 'skip: not vendored' <<<"$out" && fail "B: printed a skip in a non-vendored tree" || pass "B: no skip line printed"

# C — the path exists → silent, body runs (this is what every forge run sees).
: > "$V/validate.sh"
out="$(bash "$V/test/probe.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && grep -q 'probe: body ran' <<<"$out" && ! grep -q 'skip:' <<<"$out" \
  && pass "C: path present → helper silent, suite body runs" || fail "C: rc=$rc out='$out'"

# An empty path argument is a caller bug, not a skip.
cat > "$V/test/probe-empty.sh" <<'EOF'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib/fixture-guard.sh"
require_forge_root ""
echo "probe: body ran"
EOF
bash "$V/test/probe-empty.sh" >/dev/null 2>"$WORK/errE"; rc=$?
[ "$rc" -eq 2 ] && grep -q 'EMPTY path' "$WORK/errE" && pass "empty path argument refuses (exit 2)" || fail "empty path: rc=$rc"

# ── D: the real witness — vendor THIS checkout and run the shipped suites from .xyz/ ──────────
T="$WORK/consumer"
mkdir -p "$T"
require_fixture "$T" "consumer target"
( cd "$T" && git init -q && git config user.email gh708@example.invalid && git config user.name gh708 \
  && printf 'consumer\n' > README.md && git add -A && git commit -qm seed ) || fail "D: could not seed the consumer repo"
if XYZ_REGISTRY="$WORK/registry.tsv" bash "$ROOT/relay-automation/xyz-vendor.sh" --no-register "$T" >"$WORK/vendor.log" 2>&1; then
  pass "D: xyz-vendor.sh vendored this checkout into the consumer"
else
  fail "D: xyz-vendor.sh failed: $(tail -3 "$WORK/vendor.log")"
fi
[ -f "$T/.xyz/VERSION" ] && grep -q '^source_commit=' "$T/.xyz/VERSION" && pass "D: .xyz/VERSION carries source_commit=" \
  || fail "D: .xyz/VERSION missing or unstamped"
[ -e "$T/.xyz/githooks" ] && fail "D: githooks/ was vendored (VENDOR_DIRS changed?) — the skip would be vacuous" \
  || pass "D: githooks/ is not vendored (decision: skip, never vendor forge-only infrastructure)"

for suite in gh267-express-skill.sh sentinel-overlay.sh; do
  out="$(cd "$T" && bash ".xyz/test/$suite" 2>"$WORK/err-$suite")"; rc=$?
  if [ "$rc" -eq 0 ] && grep -q "^skip: not vendored — $suite needs " <<<"$out"; then
    pass "D: .xyz/test/$suite exits 0 with a witnessed skip"
  else
    fail "D: .xyz/test/$suite rc=$rc; out: $(head -3 <<<"$out")"
  fi
  grep -q 'No such file or directory' "$WORK/err-$suite" \
    && fail "D: $suite still reaches a missing forge path ($(head -1 "$WORK/err-$suite"))" \
    || pass "D: $suite no longer touches a missing forge path"
done

# The skip must be a VENDORED-only behaviour: the same suites run for real in this checkout.
out="$(bash "$ROOT/test/sentinel-overlay.sh" 2>&1 | head -1)"
grep -q 'skip: not vendored' <<<"$out" && fail "forge run of sentinel-overlay.sh skipped" \
  || pass "forge run of sentinel-overlay.sh does not skip (paths present)"

echo "gh708-vendored-suite-skips: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
