#!/usr/bin/env bash
# GH-615: Reinforce start-task against relay-induced overbuilding and gate thrashing
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh615-start-task.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh615-start-task-reinforce =="
TARGET="$ROOT/skills/start-task/SKILL.md"

[ -s "$TARGET" ] && pass "size non-empty guard ($(wc -c < "$TARGET" | tr -d " ") bytes)" || fail "missing/empty file"

check_start_task_reinforce_contract() {
  local t="$1"
  [ -s "$t" ] || return 1
  grep -q "bounded test scope" "$t" || return 1
  grep -q "test non-scope: no speculative test frameworks" "$t" || return 1
  grep -q "test footprint must scale to implementation" "$t" || return 1
  grep -q "repo principles via \`/ponytail\`: reviewer findings are advisory evaluations" "$t" || return 1
  grep -q "NOT a mandate to accept scope expansion" "$t" || return 1
  grep -q "Disposition: Rejected (Out of Scope / Ponytail)" "$t" || return 1
  grep -q "Apply tiered verification discipline" "$t" || return 1
  grep -q "run ONLY the focused target test suite" "$t" || return 1
  grep -q "Do NOT re-run full qualifying test gates between" "$t" || return 1
  grep -q "Run the full qualifying gate" "$t" || return 1
  grep -q "EXACTLY ONCE on the final approved" "$t" || return 1
  grep -q "the 3-round cap is a binding budget; do not" "$t" || return 1
  grep -q "extend review cycles for speculative edge cases when core acceptance criteria" "$t" || return 1
  grep -q "are green" "$t" || return 1
  return 0
}

check_start_task_reinforce_contract "$TARGET" && pass "positive in-tree control" || fail "positive control failed"

cp "$TARGET" "$WORK/unmod.md"
check_start_task_reinforce_contract "$WORK/unmod.md" && pass "unmodified fixture control" || fail "unmodified control failed"

run_mutation() {
  local desc="$1" base="$2" mut="$3" cmd="$4"
  cp "$base" "$mut"
  bash -c "$cmd"
  if cmp -s "$base" "$mut"; then fail "$desc: no change"; return 1; fi
  if ! check_start_task_reinforce_contract "$mut"; then pass "$desc: properly rejected"; else fail "$desc: passed unexpectedly"; fi
}

run_mutation "mut1 (test non-scope)" "$TARGET" "$WORK/m1.md" "sed -i.bak '/test non-scope/d' '$WORK/m1.md'"
run_mutation "mut2 (ponytail rail)" "$TARGET" "$WORK/m2.md" "sed -i.bak '/NOT a mandate to accept scope expansion/d' '$WORK/m2.md'"
run_mutation "mut3 (tiered verification)" "$TARGET" "$WORK/m3.md" "sed -i.bak '/Do NOT re-run full qualifying test gates/d' '$WORK/m3.md'"
run_mutation "mut4 (anti-thrashing)" "$TARGET" "$WORK/m4.md" "sed -i.bak '/the 3-round cap is a binding budget/d' '$WORK/m4.md'"

touch "$WORK/empty.md"
if ! check_start_task_reinforce_contract "$WORK/empty.md"; then pass "mut5 (empty fixture): properly rejected"; else fail "empty fixture passed"; fi

echo "  gh615-start-task-reinforce: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
