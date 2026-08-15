#!/usr/bin/env bash
set -uo pipefail
#
# gh544-parallel-default.sh — GH-544: parallel is validate.sh's default, and every decline is stated.
#
# GH-528 shipped `--parallel N` as opt-in and left sequential the default pending its Phase 2 stress
# bar. GH-544 flipped it, because the local gate became the ONLY gate during the private phase and a
# 16-minute gate does not get run — it gets skipped, which is strictly worse than a 3-minute one.
#
# The risk that flip creates is NOT "parallel might be wrong". It is that the gate might quietly pick
# a mode nobody asked for, so a run believed to be N-wide was sequential (or the reverse) and no one
# learns which. Every assertion here is therefore about the DECISION and its ANNOUNCEMENT.
#
# HOW THIS SUITE STAYS CHEAP, and why that shape was necessary: the mode decision is made before any
# suite runs, so observing it used to mean starting the real gate and killing it. That is racy and it
# burns minutes inside a suite that is itself part of the gate. `validate.sh --print-mode` resolves
# the mode, prints it, and runs nothing — so every probe below costs milliseconds and this suite
# cannot recurse into the gate it belongs to.
#
# Two invariants are load-bearing and nothing else pins them:
#   1. ci-local.sh must never inherit the parallel default — it is the path that writes the gate
#      record, and "sequential is the only form that qualifies a claim" is what that record attests.
#   2. ci.yml's macOS boundary must pass --sequential EXPLICITLY, so a later change to validate.sh's
#      default cannot silently change what the promotion boundary promotes on.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
V="$REPO/validate.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh544-parallel-default =="

# --- (1) argument contract ------------------------------------------------------------------------
out="$(bash "$V" --parallel 2>&1)"; rc=$?
ok "--parallel with no value is a usage error (exit 2)" "[ $rc -eq 2 ]"
ok "  and says what it wanted" "printf '%s' \"\$out\" | grep -q 'integer >= 1'"

rc=0; out="$(bash "$V" --parallel 0 2>&1)" || rc=$?
ok "--parallel 0 is refused (exit 2)" "[ $rc -eq 2 ]"

rc=0; out="$(bash "$V" --parallel abc 2>&1)" || rc=$?
ok "--parallel with a non-integer is refused (exit 2)" "[ $rc -eq 2 ]"

rc=0; out="$(bash "$V" --bogus 2>&1)" || rc=$?
ok "an unknown flag is refused (exit 2)" "[ $rc -eq 2 ]"
ok "  usage names ALL THREE forms" \
   "printf '%s' \"\$out\" | grep -q -- '--parallel N | --sequential | --print-mode'"

rc=0; out="$(bash "$V" --sequential extra 2>&1)" || rc=$?
ok "--sequential takes no argument (exit 2)" "[ $rc -eq 2 ]"

rc=0; out="$(XYZ_VALIDATE_PARALLEL=abc bash "$V" --print-mode 2>&1)" || rc=$?
ok "a malformed XYZ_VALIDATE_PARALLEL is refused, not silently ignored" "[ $rc -eq 2 ]"
ok "  and names the variable so the operator can find it" \
   "printf '%s' \"\$out\" | grep -q 'XYZ_VALIDATE_PARALLEL'"

# --- (2) --print-mode itself runs nothing ---------------------------------------------------------
# If this regresses, every probe below silently becomes a full gate run.
out="$(bash "$V" --print-mode 2>&1)"
ok "--print-mode exits 0" "[ $? -eq 0 ]"
ok "--print-mode runs NO suite (no '== test:' banner in its output)" \
   "! printf '%s' \"\$out\" | grep -q '== test:'"
ok "--print-mode prints no per-suite result lines" \
   "! printf '%s' \"\$out\" | grep -qE '^(PASS|FAIL):'"

# --- (3) THE DECISION IS ANNOUNCED — the whole point of the flip ----------------------------------
out="$(XYZ_VALIDATE_PARALLEL=0 bash "$V" --print-mode 2>&1)"
ok "XYZ_VALIDATE_PARALLEL=0 selects sequential" "printf '%s' \"\$out\" | grep -q 'SEQUENTIAL mode'"
ok "  and names the env var as the reason (never a silent downgrade)" \
   "printf '%s' \"\$out\" | grep -q 'XYZ_VALIDATE_PARALLEL=0'"

out="$(bash "$V" --print-mode --sequential 2>&1)"
ok "--sequential selects sequential" "printf '%s' \"\$out\" | grep -q 'SEQUENTIAL mode'"
ok "  and names the flag as the reason" "printf '%s' \"\$out\" | grep -q 'explicit --sequential'"

out="$(XYZ_VALIDATE_PARALLEL=3 bash "$V" --print-mode 2>&1)"
ok "XYZ_VALIDATE_PARALLEL=N pins the width" "printf '%s' \"\$out\" | grep -q 'PARALLEL mode 3-wide'"
ok "  and names the env var as the reason" "printf '%s' \"\$out\" | grep -q 'XYZ_VALIDATE_PARALLEL=3'"

out="$(bash "$V" --print-mode --parallel 2 2>&1)"
ok "--parallel N pins the width" "printf '%s' \"\$out\" | grep -q 'PARALLEL mode 2-wide'"
ok "  and names the flag as the reason" "printf '%s' \"\$out\" | grep -q 'explicit --parallel 2'"

# A flag must beat the environment, or a stale export silently overrides an explicit request.
out="$(XYZ_VALIDATE_PARALLEL=0 bash "$V" --print-mode --parallel 2 2>&1)"
ok "an explicit flag OVERRIDES XYZ_VALIDATE_PARALLEL" \
   "printf '%s' \"\$out\" | grep -q 'PARALLEL mode 2-wide'"

# --- (4) the no-args default announces a mode AND a reason -----------------------------------------
# Deliberately not asserting WHICH mode: that is host-dependent, and a suite that demanded parallel
# would fail on exactly the low-core host the fallback exists to serve. What must always hold is that
# a mode was chosen and a reason was given.
out="$(bash "$V" --print-mode 2>&1)"
ok "no-args run announces a mode" "printf '%s' \"\$out\" | grep -qE '(PARALLEL|SEQUENTIAL) mode'"
ok "no-args run states a REASON for whichever mode it picked" \
   "printf '%s' \"\$out\" | grep -qE 'auto-detected [0-9]+ cores|core\(s\) detected|xargs does not support|could not detect a core count'"

# --- (5) a parallel run must not be mistakable for promotion evidence ------------------------------
out="$(bash "$V" --print-mode --parallel 2 2>&1)"
ok "a parallel run disclaims promotion evidence in its own header" \
   "printf '%s' \"\$out\" | grep -q 'NOT promotion evidence'"
out="$(bash "$V" --print-mode --sequential 2>&1)"
ok "the sequential header does NOT carry that disclaimer (it is the qualifying form)" \
   "! printf '%s' \"\$out\" | grep -q 'NOT promotion evidence'"

# --- (6) THE TWO INVARIANTS NOTHING ELSE PINS ------------------------------------------------------
ok "ci-local.sh does NOT invoke validate.sh (it runs TESTS itself, sequentially)" \
   "! grep -qE '^[[:space:]]*(bash )?\\./?validate\\.sh' '$REPO/ci-local.sh'"
ok "ci-local.sh still parses the TESTS array (one list, no drift)" \
   "grep -q 'TESTS=(' '$REPO/ci-local.sh'"
ok "ci.yml's macOS boundary pins --sequential explicitly" \
   "grep -qE 'run: \\./validate\\.sh --sequential' '$REPO/.github/workflows/ci.yml'"
ok "  and no CI step invokes a bare ./validate.sh" \
   "! grep -qE 'run: \\./validate\\.sh[[:space:]]*\$' '$REPO/.github/workflows/ci.yml'"

echo "  gh544-parallel-default: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
