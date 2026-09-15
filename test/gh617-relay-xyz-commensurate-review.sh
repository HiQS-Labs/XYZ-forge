#!/usr/bin/env bash
# GH-617: Enforce commensurate review scope and operational envelope in relay-xyz
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh617-relay.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh617-relay-xyz-commensurate-review =="
TARGET="$ROOT/skills/relay-xyz/SKILL.md"

[ -s "$TARGET" ] && pass "size non-empty guard ($(wc -c < "$TARGET" | tr -d " ") bytes)" || fail "missing/empty file"

check_relay_xyz_commensurate_contract() {
  local t="$1"
  [ -s "$t" ] || return 1
  grep -q "Review Scope & Commensurate Complexity Standard" "$t" || return 1
  grep -q "Surgical, DRY, Safe, Secure, and Stable within Reason" "$t" || return 1
  grep -q "Commensurate Machinery & Tests" "$t" || return 1
  grep -q "An 80-line sync script or local tool must not become entangled" "$t" || return 1
  grep -q "Operational Envelope Grounding" "$t" || return 1
  grep -q "Challenge Unwarranted Complexity" "$t" || return 1
  grep -q "Operational Envelope: Local CLI tool" "$t" || return 1
  return 0
}

check_relay_xyz_commensurate_contract "$TARGET" && pass "positive in-tree control" || fail "positive control failed"

cp "$TARGET" "$WORK/unmod.md"
check_relay_xyz_commensurate_contract "$WORK/unmod.md" && pass "unmodified fixture control" || fail "unmodified control failed"

run_mutation() {
  local desc="$1" base="$2" mut="$3" cmd="$4"
  cp "$base" "$mut"
  bash -c "$cmd"
  if cmp -s "$base" "$mut"; then fail "$desc: no change"; return 1; fi
  if ! check_relay_xyz_commensurate_contract "$mut"; then pass "$desc: properly rejected"; else fail "$desc: passed unexpectedly"; fi
}

run_mutation "mut1 (no commensurate standard heading)" "$TARGET" "$WORK/m1.md" "sed -i.bak '/Review Scope & Commensurate Complexity Standard/d' '$WORK/m1.md'"
run_mutation "mut2 (no commensurate machinery clause)" "$TARGET" "$WORK/m2.md" "sed -i.bak '/Commensurate Machinery & Tests/d' '$WORK/m2.md'"
run_mutation "mut3 (no operational envelope clause)" "$TARGET" "$WORK/m3.md" "sed -i.bak '/Operational Envelope Grounding/d' '$WORK/m3.md'"
run_mutation "mut4 (no challenge complexity clause)" "$TARGET" "$WORK/m4.md" "sed -i.bak '/Challenge Unwarranted Complexity/d' '$WORK/m4.md'"
run_mutation "mut5 (no template operational envelope)" "$TARGET" "$WORK/m5.md" "sed -i.bak '/Operational Envelope: Local CLI tool/d' '$WORK/m5.md'"

touch "$WORK/empty.md"
if ! check_relay_xyz_commensurate_contract "$WORK/empty.md"; then pass "mut6 (empty fixture): properly rejected"; else fail "empty fixture passed"; fi

echo "  gh617-relay-xyz-commensurate-review: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
