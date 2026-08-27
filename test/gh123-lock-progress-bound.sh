#!/usr/bin/env bash
# test/gh123-lock-progress-bound.sh — GH-123: XYZ_LOCK_WAIT_S bounds ONE holder, not the queue.
#
# The CI failure this pins is a race that does not reproduce on an idle dev box: on a shared,
# CPU-throttled runner the 16 concurrent appenders in test/xyz-completion.sh queue on one lock,
# each holder spawning python3 under it. The queue is long but MOVING, yet a single wall-clock
# deadline expires anyway and the writer exits 75 — reporting lock starvation for a system that
# is merely slow. test/gh358-lock-instrumentation.sh then fails, because its clobber control
# asserts the run is NOT mislabeled as starvation.
#
# Rather than chase the race, this drives the lock directly and deterministically:
#   A. a HELD lock whose holder never changes must still exit 75 at the bound (starvation stays loud)
#   B. a lock CHANGING HANDS past the bound must be waited out and acquired (progress re-arms it)
# B is the regression: before the fix it exits 75, because the deadline ignored the handovers.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WRITER="$ROOT/utils/telemetry/append-xyz-completion.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh123-lock-progress.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh123-lock-progress-bound =="

# ── A. Stuck holder: the bound must still fire, and fire as starvation (75) ──────────────────────
X_A="$WORK/a.json"; LOCK_A="$X_A.lock"
mkdir -p "$LOCK_A"
sleep 30 & stuck_pid=$!                      # a live holder that never lets go
printf '%s\n' "$stuck_pid" > "$LOCK_A/pid"

start=$(date +%s)
XYZ_JSON_PATH="$X_A" XYZ_LOCK_WAIT_S=2 bash "$WRITER" relay gh123-stuck green "T" "d" >/dev/null 2>&1
rc_a=$?
elapsed=$(( $(date +%s) - start ))
kill "$stuck_pid" 2>/dev/null || true; wait "$stuck_pid" 2>/dev/null || true

[ "$rc_a" -eq 75 ] \
  && pass "stuck holder still exits 75 (lock starvation stays loud), after ${elapsed}s" \
  || fail "stuck holder exited $rc_a, expected 75 — a genuinely stuck lock must fail loudly"
[ "$elapsed" -lt 10 ] \
  && pass "stuck holder failed promptly (${elapsed}s), it did not wait out the total cap" \
  || fail "stuck holder took ${elapsed}s — the per-holder bound is not firing"

# ── B. Lock changing hands past the bound: progress must re-arm it ───────────────────────────────
# Six handovers at ~1s each = ~6s of waiting under a 2s per-holder bound. The old single deadline
# expires at 2s and exits 75; the fixed bound re-arms on every handover and acquires the lock.
X_B="$WORK/b.json"; LOCK_B="$X_B.lock"
mkdir -p "$LOCK_B"
handover_done="$WORK/handover.done"
(
  for _ in 1 2 3 4 5 6; do
    sleep 5 & h=$!                            # a distinct, live pid each round
    printf '%s\n' "$h" > "$LOCK_B/pid" 2>/dev/null || true
    sleep 1
    kill "$h" 2>/dev/null || true; wait "$h" 2>/dev/null || true
  done
  rm -rf "$LOCK_B" 2>/dev/null || true         # queue drained — lock is free
  : > "$handover_done"
) &
handover_pid=$!

start=$(date +%s)
XYZ_JSON_PATH="$X_B" XYZ_LOCK_WAIT_S=2 bash "$WRITER" relay gh123-progress green "T" "d" >/dev/null 2>&1
rc_b=$?
elapsed_b=$(( $(date +%s) - start ))
wait "$handover_pid" 2>/dev/null || true

[ "$rc_b" -eq 0 ] \
  && pass "lock changing hands was waited out and acquired (rc=0) after ${elapsed_b}s" \
  || fail "a MOVING queue exited $rc_b after ${elapsed_b}s — progress did not re-arm the bound (this is the GH-123 regression)"
[ "$elapsed_b" -gt 2 ] \
  && pass "it waited ${elapsed_b}s — past the 2s per-holder bound, so re-arm fired rather than a lucky grab" \
  || fail "acquired in ${elapsed_b}s, within the 2s bound — the probe did not exercise re-arm"
[ -f "$X_B" ] \
  && pass "the record actually landed on disk (content, not just exit code)" \
  || fail "writer returned 0 but wrote no file"

# ── C. The defaults gh358 asserts verbatim are unchanged ─────────────────────────────────────────
grep -q 'XYZ_LOCK_WAIT_S:-30' "$WRITER" \
  || fail "the 30s default changed — test/xyz-completion.sh mirrors it and gh358 asserts '(default=30s)'"
grep -q 'WRITER_LOCK_WAIT_DEFAULT_S=30' "$ROOT/test/xyz-completion.sh" \
  || fail "test/xyz-completion.sh no longer mirrors the writer's 30s default"
pass "defaults unchanged — gh358's verbatim bound assertions still hold"

echo "  gh123-lock-progress-bound: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
