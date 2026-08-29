#!/usr/bin/env bash
set -uo pipefail
#
# gh306-registry-bidirectional.sh — GH-306: the exists→registered half of the test registry
# contract (the B3 root cause).
#
# gh35-test-tiers.sh section (4) pins ONE direction: every subsystem-registry suite must exist on
# disk and appear in validate.sh's TESTS, and a registry naming a missing suite fails the listing
# loudly. Nothing pinned the REVERSE direction — a runnable test/*.sh that exists on disk but is
# NOT in TESTS runs only when invoked by hand, and the gate is green either way. That is exactly
# how test/gh280-jog-marathon-adapter.sh shipped unregistered through PR #281 (review finding
# B3; registered reactively in #296 / 4d83fc40). This suite makes the gate fail instead, and at
# filing time it found TEN more green suites in the same hole (registered alongside it).
#
# WHAT THIS GUARD DOES NOT MATCH (GH-195: an audit that recognizes only one invocation shape
# stops covering the same operation reached a different way):
#   * suites under test/ SUBDIRECTORIES (synthetic/, fixtures/, lib/, baselines/) — a new
#     test/<subdir>/suite.sh is invisible here. gh141-synthetic-registry.sh pins the synthetic/
#     subset against the subsystem registry; the other subdirectories have no exists→registered
#     pin as of GH-306;
#   * executable NON-.sh files directly under test/ (a .py or extensionless runner);
#   * subsystem-registry membership itself (that is gh35 section (4)'s direction, not this one);
#   * exemption entries match by EXACT basename — renaming an exempt helper puts it back in the
#     drift set (deliberate: an exemption is a name plus a reason, not a pattern).
#
# NOTE on style: older suites assert through an eval-based ok() helper (baselined under GH-64).
# This suite deliberately uses plain if-blocks instead — new code adds no new eval surface, so
# there is nothing to baseline.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
V="$REPO/validate.sh"

pass=0; fail=0
ok(){ echo "  PASS: $1"; pass=$((pass+1)); }
no(){ echo "  FAIL: $1" >&2; fail=$((fail+1)); }

echo "== test: gh306-registry-bidirectional =="

# ── the exemption list — short by contract; every entry carries its reason ───────────────────────
# A suite goes here only when it CANNOT run in the gate, with the reason written down. A suite
# that merely lacks a registration is DRIFT, not an exemption — gh280 through #281 is what a
# silent gap looks like. An exempt name that no longer exists on disk is itself drift (stale
# exemptions are how this list rots into covering nothing), so the list is pinned in BOTH
# directions below, like the registry it carves holes into.
EXEMPT=(
  "_setup.sh"                    # sourced by ~150 suites (shared tick fixture setup) — never executed directly
  "_scratch-repo.sh"             # sourced hardened scratch-repo helper (GH-44) — never executed directly
  "test-agy-standalone-repo.sh"  # legacy manual mock from the initial public release; no assertions, prints git status only
  "test-agy-isolation.sh"        # pre-existing RED at GH-306 filing: stale expectation vs gh308-consult-guards.sh's Python-lane coverage of the same detector; needs its own fix lane, not a silent skip
)

# drift_of <test_dir> <tests_blob> — prints one basename per top-level *.sh directly inside
# <test_dir> that appears nowhere in <tests_blob> and is not exempt. Pure function: reads one
# directory and one string, prints names, touches nothing.
drift_of() {
  local tdir="$1" blob="$2" f name e ex
  for f in "$tdir"/*.sh; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    grep -qF "\"$name\"" <<<"$blob" && continue
    ex=0
    for e in "${EXEMPT[@]}"; do [ "$e" = "$name" ] && ex=1; done
    [ "$ex" = "1" ] && continue
    printf '%s\n' "$name"
  done
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh306-registry.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "${WORK:-}" ] && rm -rf "$WORK"; }
trap cleanup EXIT

# GH-177/GH-1: every fixture path this suite passes around is proven to live under $WORK.
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

# ── (1) the real check: no top-level suite ships unregistered ────────────────────────────────────
tests_blob="$(sed -n '/^TESTS=(/,/^)/p' "$V")"
if [ -n "$tests_blob" ]; then
  ok "the TESTS array was extracted from validate.sh (non-empty blob)"
else
  no "the TESTS array was extracted from validate.sh (non-empty blob)"
fi

_real_drift="$(drift_of "$REPO/test" "$tests_blob")"
if [ -z "$_real_drift" ]; then
  ok "every top-level test/*.sh is in validate.sh's TESTS or explicitly exempt (drift: none)"
else
  no "top-level suite(s) on disk but registered nowhere and not exempt (the B3 shape, GH-306):"
  printf '        %s\n' $_real_drift
fi

# The self-demonstration: THIS suite is itself a top-level test/*.sh, so it cannot be shipped
# unregistered without tripping its own check — the guard closes the hole it arrived through.
if grep -qF '"gh306-registry-bidirectional.sh"' <<<"$tests_blob"; then
  ok "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
else
  no "this suite itself is registered in TESTS (self-demonstrating — an unregistered guard is the exact failure it exists to catch)"
fi

# ── (2) the other half of bidirectional: a TESTS entry with no file behind it ────────────────────
# validate.sh's pool would fail at run time on a missing suite, but that red lands mid-gate and
# reads as a suite failure; this names it as a REGISTRY failure before anything runs. The sed is
# anchored to the LEADING quoted token of each line so quoted words inside entry comments
# ("flake", "no dispatch") are not mistaken for suite names (found on the first run).
_missing=""
while IFS= read -r t; do
  [ -n "$t" ] || continue
  [ -f "$HERE/$t" ] || _missing="$_missing $t"
done < <(sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$tests_blob")
if [ -z "$_missing" ]; then
  ok "every TESTS entry exists on disk (missing: none)"
else
  no "every TESTS entry exists on disk (missing:$_missing)"
fi

# ── (3) the exemption list is pinned in both directions too ──────────────────────────────────────
_stale=""
for e in "${EXEMPT[@]}"; do
  [ -f "$HERE/$e" ] || _stale="$_stale $e"
done
if [ -z "$_stale" ]; then
  ok "every exemption names a file that still exists on disk (stale: none)"
else
  no "exemption entries name files that no longer exist (stale:$_stale) — the list is rotting into covering nothing"
fi

_declared=""
for e in "${EXEMPT[@]}"; do
  grep -qF "\"$e\"" <<<"$tests_blob" && _declared="$_declared $e"
done
if [ -z "$_declared" ]; then
  ok "no exemption is ALSO registered in TESTS (double-listed: none — exempt means not in the gate)"
else
  no "exemption entries are ALSO registered in TESTS (double-listed:$_declared) — pick one: register the suite or keep the exemption"
fi

# ── (4) THE NEGATIVE CONTROL: the guard must fire on a ghost, and only on the ghost ───────────────
# Fixture 1 is the #281 B3 replay in miniature: a test/ dir holding one registered stub, one
# legitimately-exempt helper, and one ghost that exists on disk but is registered nowhere. The
# drift report must name the ghost and ONLY the ghost.
F1="$WORK/f1-ghost"; mkdir -p "$F1"
require_fixture "$F1" "ghost fixture dir"
printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/registered-stub.sh"
printf '# stub sourced by fixture suites — the _setup.sh exemption shape\n' > "$F1/_setup.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$F1/ghost-suite.sh"
f1_blob='TESTS=(
  "registered-stub.sh"
)'
_d="$(drift_of "$F1" "$f1_blob")"
if [ "$_d" = "ghost-suite.sh" ]; then
  ok "a ghost suite (on disk, unregistered, unexempted) is flagged BY NAME — the #281 B3 shape goes red"
else
  no "a ghost suite (on disk, unregistered, unexempted) is flagged BY NAME — the #281 B3 shape goes red (got: '${_d:-<empty>}')"
fi
if grep -qF 'registered-stub.sh' <<<"$_d"; then
  no "the registered stub in the same dir is NOT flagged (got it in the drift report)"
else
  ok "  and the registered stub in the same dir is NOT flagged"
fi
if grep -qF '_setup.sh' <<<"$_d"; then
  no "the exempt helper in the same dir is NOT flagged (got it in the drift report)"
else
  ok "  and the exempt helper in the same dir is NOT flagged"
fi

# Fixture 2 is the anti-trigger-happy control (GH-90's lesson: a guard that refuses everything
# satisfies any pin and protects nothing): a dir where every file is registered or exempt must
# produce an EMPTY drift report.
F2="$WORK/f2-clean"; mkdir -p "$F2"
require_fixture "$F2" "clean fixture dir"
printf '#!/usr/bin/env bash\nexit 0\n' > "$F2/one.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$F2/two.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$F2/_scratch-repo.sh"
f2_blob='TESTS=(
  "one.sh"
  "two.sh"
  "gh306-registry-bidirectional.sh"
)'
_d2="$(drift_of "$F2" "$f2_blob")"
if [ -z "$_d2" ]; then
  ok "a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy)"
else
  no "a fully-registered-or-exempt dir yields an EMPTY drift report (control: the guard is not trigger-happy) — got: $_d2"
fi

echo "  gh306-registry-bidirectional: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
