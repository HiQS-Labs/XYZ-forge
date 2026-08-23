#!/usr/bin/env bash
# GH-184: nothing under the sanctioned-disposable .relay-scratch/ lane is ever tracked, so its
# by-design discard (rtl non-worktree cleanup) can never dirty a clone. Derived guard: offenders
# come from `git ls-files .relay-scratch/` every run — no hand-maintained exception list.
# Pre-fix state: PR #160 had committed .relay-scratch/probe_telemetry.json (see
# test/baselines/GH-184-negative-control.md, soak evidence #177 §3.5).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh184-tracked-scratch.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh184-no-tracked-scratch =="

# 1. The real repo must track nothing under .relay-scratch/
TRACKED="$(git -C "$ROOT" ls-files .relay-scratch/)"
if [ -z "$TRACKED" ]; then
  pass "repo tracks nothing under .relay-scratch/"
else
  fail "tracked scratch artifacts present: $TRACKED"
fi

# 2. Negative control (hermetic): the guard's detection logic fires on a fixture repo that DID
#    commit a scratch file — proving the empty result above is enforcement, not vacuous.
FIX="$WORK/fixture-repo"
mkdir -p "$FIX/.relay-scratch"
require_fixture "$FIX" "fixture-repo"
git -C "$FIX" init -q
git -C "$FIX" config user.email t@t.local
git -C "$FIX" config user.name t
printf '{}' > "$FIX/.relay-scratch/probe.json"
git -C "$FIX" add .relay-scratch/probe.json
git -C "$FIX" commit -qm init
BAD="$(git -C "$FIX" ls-files .relay-scratch/)"
if [ -n "$BAD" ]; then
  pass "negative control: guard detects a tracked scratch artifact in a fixture repo ($BAD)"
else
  fail "negative control did not detect the fixture's tracked scratch file"
fi

echo "  gh184-no-tracked-scratch: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
