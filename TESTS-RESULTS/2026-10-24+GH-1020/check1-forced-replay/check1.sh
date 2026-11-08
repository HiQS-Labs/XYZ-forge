#!/usr/bin/env bash
# GH-1020 manual check 1 — forced replay of the retained bad command against the guard (src/scope.js release).
# Usage: bash gh1020-check1-forced-replay.sh <verify-clone> <out-dir>
# Runs in the disposable verify clone's own .tick (TICK_REPO_ROOT=<clone>). Prints PASS/FAIL lines; exit 1 on any FAIL.
set -u
C="$1"; OUT="$2"; mkdir -p "$OUT"
export TICK_REPO_ROOT="$C"
TICK="$C/bin/tick"
PASS=0; FAIL=0
pass() { echo "PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
events() { cat "$C"/.tick/events/*.jsonl 2>/dev/null | grep -c . ; }
status_of() { "$TICK" info "$1" 2>/dev/null | sed -n 's/^status:[[:space:]]*//p' | head -n1; }
claimer_of() { "$TICK" info "$1" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1; }

T="RELAY-gh1020-check1-$(date +%H%M%S)"
echo "== guard present: $(git -C "$C" rev-parse --short HEAD)"
"$TICK" claim "$T" --agent codex --paths relay-system/2026-10-24/gh1020-close-mismatch-repro.md >/dev/null || { fail "seed claim"; exit 1; }

for word in done Approved Closed; do
  before=$(events)
  out="$("$TICK" release "$T" --agent codex --to "$word" 2>&1)"; rc=$?
  printf '%s\n' "$out" > "$OUT/guard-release-to-$word.txt"
  [ "$rc" -ne 0 ] && pass "release --to $word exits non-zero (rc=$rc)" || fail "release --to $word exited 0"
  printf '%s' "$out" | grep -q -F "tick done $T --agent codex" && pass "diagnostic names the right verb for --to $word" || fail "diagnostic for --to $word does not name tick done: $out"
  printf '%s' "$out" | grep -q -i "terminal status, not an agent" && pass "diagnostic explains --to $word" || fail "diagnostic text for --to $word"
  [ "$(events)" -eq "$before" ] && pass "no event written for --to $word ($before)" || fail "event count changed for --to $word"
  [ "$(status_of "$T")" = "claimed" ] && [ "$(claimer_of "$T")" = "codex" ] && pass "token still claimed by codex after --to $word" || fail "ownership changed after --to $word: $("$TICK" info "$T")"
done

# Controls: a real peer and a bare release still work (one task.released each).
before=$(events)
"$TICK" release "$T" --agent codex --to claude-a >/dev/null 2>&1 && pass "control: release --to claude-a succeeds" || fail "control: release --to claude-a failed"
[ "$(events)" -eq $((before+1)) ] && pass "control: exactly one event for --to claude-a" || fail "control: event count for --to claude-a"
"$TICK" claim "$T" --agent claude-a --paths relay-system/2026-10-24/gh1020-close-mismatch-repro.md >/dev/null 2>&1 || fail "control: peer reclaim"
before=$(events)
"$TICK" release "$T" --agent claude-a >/dev/null 2>&1 && pass "control: bare release (no --to) succeeds" || fail "control: bare release failed"
[ "$(events)" -eq $((before+1)) ] && pass "control: exactly one event for bare release" || fail "control: event count for bare release"

# Shim closure path on a terminal header: the existing rtl_enforce step 4 closes a token the agent still owns.
T2="RELAY-gh1020-check1b-$(date +%H%M%S)"
"$TICK" claim "$T2" --agent codex --paths relay-system/2026-10-24/gh1020-close-mismatch-repro.md >/dev/null
"$TICK" release "$T2" --agent codex --to done >/dev/null 2>&1   # the misfire, now refused
"$TICK" done "$T2" --agent codex >/dev/null 2>&1 && pass "after the refused misfire, tick done by the same agent succeeds (what rtl_enforce step 4 runs)" || fail "tick done after refused misfire failed"
[ "$(status_of "$T2")" = "done" ] && pass "token $T2 is done" || fail "token $T2 not done"

# Red control: guard hunk reverted → the misfire succeeds, ownership is lost, done fails (the before-fix state).
echo "== red control: src/scope.js from origin/development"
cp "$C/src/scope.js" "$OUT/scope.js.fixed"
git -C "$C" show origin/development:src/scope.js > "$C/src/scope.js"
T3="RELAY-gh1020-check1-red-$(date +%H%M%S)"
"$TICK" claim "$T3" --agent codex --paths relay-system/2026-10-24/gh1020-close-mismatch-repro.md >/dev/null
out="$("$TICK" release "$T3" --agent codex --to done 2>&1)"; rc=$?
printf '%s\n' "$out" > "$OUT/red-control-release-to-done.txt"
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q -F "released:" && pass "RED: without the guard, release --to done succeeds (rc=0, 'released:')" || fail "RED: expected the misfire to succeed without the guard (rc=$rc: $out)"
"$TICK" done "$T3" --agent codex >/dev/null 2>&1 && fail "RED: tick done unexpectedly succeeded after release --to done" || pass "RED: tick done fails after release --to done (ownership lost — the close-mismatch state)"
"$TICK" info "$T3" > "$OUT/red-control-tick-info.txt"
grep -q "^handoff-to: done" "$OUT/red-control-tick-info.txt" && pass "RED: tick info shows handoff-to: done" || fail "RED: tick info lacks handoff-to: done"
cp "$OUT/scope.js.fixed" "$C/src/scope.js"; rm -f "$OUT/scope.js.fixed"
git -C "$C" diff --quiet -- src/scope.js && pass "guard restored (tree clean)" || fail "src/scope.js not restored"

echo "== summary: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
