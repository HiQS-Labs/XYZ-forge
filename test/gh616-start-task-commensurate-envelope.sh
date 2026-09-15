#!/usr/bin/env bash
# GH-616: Enforce commensurate machinery and review-packet envelope in start-task
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh616-commensurate.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh616-start-task-commensurate-envelope =="
TARGET="$ROOT/skills/start-task/SKILL.md"

[ -s "$TARGET" ] && pass "size non-empty guard ($(wc -c < "$TARGET" | tr -d " ") bytes)" || fail "missing/empty file"

check_start_task_commensurate_contract() {
  local t="$1"
  [ -s "$t" ] || return 1
  grep -q "Commensurate Complexity Mantra" "$t" || return 1
  grep -q "Machinery, defensive handling, and test" "$t" || return 1
  grep -q "An 80-line sync script or local utility must not become entangled" "$t" || return 1
  grep -q "operational envelope in the review packet" "$t" || return 1
  grep -q "enterprise multi-tenant threat models" "$t" || return 1
  grep -q "Frame the final review packet with the same commensurate operational envelope" "$t" || return 1
  return 0
}

check_start_task_commensurate_contract "$TARGET" && pass "positive in-tree control" || fail "positive control failed"

cp "$TARGET" "$WORK/unmod.md"
check_start_task_commensurate_contract "$WORK/unmod.md" && pass "unmodified fixture control" || fail "unmodified control failed"

run_mutation() {
  local desc="$1" base="$2" mut="$3" cmd="$4"
  cp "$base" "$mut"
  bash -c "$cmd"
  if cmp -s "$base" "$mut"; then fail "$desc: no change"; return 1; fi
  if ! check_start_task_commensurate_contract "$mut"; then pass "$desc: properly rejected"; else fail "$desc: passed unexpectedly"; fi
}

run_mutation "mut1 (no commensurate mantra)" "$TARGET" "$WORK/m1.md" "sed -i.bak '/Commensurate Complexity Mantra/d' '$WORK/m1.md'"
run_mutation "mut2 (no step 6 review envelope)" "$TARGET" "$WORK/m2.md" "sed -i.bak '/operational envelope in the review packet/d' '$WORK/m2.md'"
run_mutation "mut3 (no step 8 review envelope)" "$TARGET" "$WORK/m3.md" "sed -i.bak '/Frame the final review packet/d' '$WORK/m3.md'"

touch "$WORK/empty.md"
if ! check_start_task_commensurate_contract "$WORK/empty.md"; then pass "mut4 (empty fixture): properly rejected"; else fail "empty fixture passed"; fi

echo "  gh616-start-task-commensurate-envelope: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
