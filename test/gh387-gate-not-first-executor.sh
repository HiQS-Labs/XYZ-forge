#!/usr/bin/env bash
# test/gh387-gate-not-first-executor.sh — GH-387.
#
# A builder turn killed at its wall-clock cap is still COMMITTED — deliberately, that is GH-432's
# shipped fix against orphaned tokens and lost work. The defect was what happened next: the driver's
# timeout recovery probed the pre-advance gate, which made the GATE the first thing ever to EXECUTE
# work that no human and no reviewer had seen.
#
# The fix deletes that probe. It is safe precisely because the probe decided nothing — every branch of
# recover_timeout_exit() is resolved by artifacts_exist(), file_status() and token_state(), and the
# tick token records the builder's handoff directly. The gate was a proxy for a question the token
# already answers.
#
# WHY A NEW TEST AND NOT JUST test/marathon.sh's GH-205 CASES:
# those cases construct a GREEN gate and assert the phase resumes. They still pass after this change —
# but they would ALSO pass if the probe were still there, so they cannot distinguish the fix from the
# defect. They are the non-regression CONTROL, not the pin. This file is the pin.
#
# Hermetic: stubbed relay-drive, stubbed agent binaries, a gate that records every invocation. No
# network, no real CLI, no paid turn.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
TICK="$REPO/bin/tick"
MD_BIN="$REPO/relay-automation/marathon-drive.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh387.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
A="$WORK/repo"
trap 'rm -rf "$WORK"' EXIT

# EXPORTED, not merely assigned: the relay-drive stub below is executed by marathon-drive as a child
# process and dereferences all three. Unexported they arrive empty, the stub runs `"" claim`, and the
# whole phase returns 127 — which reads exactly like a broken fix rather than a broken fixture.
# test/_setup.sh exports these for the suites that source it; this file stands alone, so it must too.
export WORK A TICK

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh387-gate-not-first-executor =="
echo "  workdir: $WORK"

mkdir -p "$A/briefs" "$A/src"
git -C "$A" init -q 2>/dev/null || { git init -q "$A"; }
git -C "$A" config user.email t@t.t; git -C "$A" config user.name t
printf '.tick/\n' > "$A/.gitignore"
printf 'gh387 brief\n' > "$A/briefs/gh387.md"
git -C "$A" add -A >/dev/null 2>&1; git -C "$A" commit -q -m init

CODEX_OK="$WORK/codex-ok"; AGY_OK="$WORK/agy-ok"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CODEX_OK"
printf '#!/usr/bin/env bash\nexit 0\n' > "$AGY_OK"
chmod +x "$CODEX_OK" "$AGY_OK"

# A gate that RECORDS EVERY INVOCATION. The recovery path's behaviour is only observable this way:
# a gate that merely returns a code cannot tell you WHEN, or how many times, it ran.
#
# It takes BOTH its log path and its exit code from files beside itself, and reads nothing from the
# environment. Two independent reasons, each of which alone would break an env-based design:
#   * GH-238 resolves the gate PROGRAM from the command's first token, so a command that begins with
#     `VAR=x ...` is rejected as unrunnable and the driver dies (exit 2) before any phase starts.
#   * GH-441 SCRUBS the gate's environment through utils/py/gate_env.py, so variables exported by the
#     caller are deliberately not visible to the gate anyway.
GATE="$WORK/gate.sh"
cat > "$GATE" <<'GEOF'
#!/usr/bin/env bash
here="$(cd "$(dirname "$0")" && pwd)"
printf 'ran\n' >> "$here/gate-log"
exit "$(cat "$here/gate-exit" 2>/dev/null || echo 0)"
GEOF
chmod +x "$GATE"

# relay-drive stub: first call times out (exit 7) AFTER writing the artifact and handing the token to
# the reviewer — the exact shape of a builder killed at its cap once its work had landed. Second call
# is the reviewer approving.
RD="$WORK/rd.sh"
cat > "$RD" <<'STUB'
#!/usr/bin/env bash
set -eu
relay=""; task=""
while (($#)); do
  case "$1" in
    --relay-file) relay="$2"; shift 2 ;;
    --relay-task) task="$2"; shift 2 ;;
    *) shift ;;
  esac
done
count=0
[ -f "$WORK/rd-count" ] && count="$(cat "$WORK/rd-count")"
count=$((count + 1))
printf '%s\n' "$count" > "$WORK/rd-count"
if [ "$count" -eq 1 ]; then
  printf 'partial artifact from a killed turn\n' > "$A/src/gh387.js"
  printf '\n### Round 1 · Builder · codex\nKilled at the wall-clock cap after the artifact landed.\n' >> "$relay"
  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "marathon-system/**,src/gh387.js" >/dev/null 2>&1 || true
  TICK_REPO_ROOT="$A" "$TICK" release "$task" --agent codex --to agy >/dev/null 2>&1 || true
  exit 7
fi
sed -i.bak 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$relay"; rm -f "$relay.bak"
printf '\n### Round 1 · Reviewer · agy\n**Verdict:** Approved\n' >> "$relay"
TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "marathon-system/**" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$A" "$TICK" done "$task" --agent agy >/dev/null 2>&1 || true
exit 0
STUB
chmod +x "$RD"

run_phase() {  # <gate-exit> <phase-id>
  rm -f "$WORK/rd-count" "$WORK/gate-log"
  printf '%s\n' "$1" > "$WORK/gate-exit"
  rm -rf "$A/.tick" "$A/marathon-system" "$A/phases"; rm -f "$A/src/gh387.js"
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD" TICK_BIN="$TICK" \
  CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
    bash "$MD_BIN" --phase-id "$2" --builder codex --reviewer agy \
      --phase-brief "$A/briefs/gh387.md" --artifact src/gh387.js \
      --pre-advance-cmd "bash $GATE" >/dev/null 2>&1
  echo $?
}
gate_runs() { [ -f "$WORK/gate-log" ] && wc -l < "$WORK/gate-log" | tr -d ' ' || echo 0; }

# ── (1) THE PIN — the reviewer runs BEFORE any gate execution ────────────────────────────────────
# With a green gate the phase completes either way, so the OUTCOME cannot distinguish the fix. The
# observable that can is the relay-drive call count at the moment the gate first runs — which is why
# the gate logs. Post-fix the gate runs exactly ONCE, at the end of the phase, after the reviewer has
# approved. Pre-fix it ran an extra time inside recovery, BEFORE the reviewer was ever dispatched.
rc="$(run_phase 0 gh387a)"
runs="$(gate_runs)"
[ "$rc" -eq 0 ] \
  && pass "a timed-out-but-handed-off turn still completes the phase (GH-205 recovery preserved)" \
  || fail "expected exit 0, got $rc"
[ "$(cat "$WORK/rd-count" 2>/dev/null)" = "2" ] \
  && pass "the reviewer round was dispatched — recovery re-entered relay-drive" \
  || fail "expected 2 relay-drive calls, saw [$(cat "$WORK/rd-count" 2>/dev/null)]"
[ "$runs" = "1" ] \
  && pass "THE PIN: the gate executed exactly ONCE, after review — not as the timeout probe (runs=$runs)" \
  || fail "THE PIN FAILED: gate executed $runs time(s); a probe inside timeout recovery is back"

# ── (2) a RED gate no longer short-circuits recovery — the reviewer still gets to inspect ────────
# This is the behaviour that changed, stated as its own assertion rather than left implicit. Pre-fix
# this halted with exit 5 and `timeout-gate-failed`, and the gate had ALREADY executed the partial
# work to decide that. Post-fix the reviewer is dispatched first; the gate still fails the phase
# afterwards, so nothing unsafe advances — it simply is not the first thing to run the code.
rc="$(run_phase 1 gh387b)"
runs="$(gate_runs)"
[ "$rc" -ne 0 ] \
  && pass "a red gate still fails the phase (exit $rc) — the fix does not let bad work advance" \
  || fail "a red gate must not pass the phase, got exit $rc"
[ "$(cat "$WORK/rd-count" 2>/dev/null)" = "2" ] \
  && pass "the reviewer was dispatched BEFORE the gate ran, even though the gate was red" \
  || fail "expected the reviewer round to run first; relay-drive calls: [$(cat "$WORK/rd-count" 2>/dev/null)]"
[ "$runs" = "1" ] \
  && pass "the red gate ran once, after review — not twice, and not as the first executor (runs=$runs)" \
  || fail "expected 1 gate run after review, saw $runs"

# ── (3) CONTROL — a timeout with NO artifact must still halt without running the gate at all ─────
# Guards the other direction: if the fix had removed the artifacts_exist() guard along with the probe,
# a no-artifact hang would resume into a reviewer round for work that does not exist.
RD_NOART="$WORK/rd-noart.sh"
cat > "$RD_NOART" <<'STUB'
#!/usr/bin/env bash
set -eu
count=0
[ -f "$WORK/rd-count" ] && count="$(cat "$WORK/rd-count")"
printf '%s\n' "$((count + 1))" > "$WORK/rd-count"
exit 7
STUB
chmod +x "$RD_NOART"
rm -f "$WORK/rd-count" "$WORK/gate-log"
printf '0\n' > "$WORK/gate-exit"
rm -rf "$A/.tick" "$A/marathon-system" "$A/phases"; rm -f "$A/src/gh387.js"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_NOART" TICK_BIN="$TICK" \
CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
  bash "$MD_BIN" --phase-id gh387c --builder codex --reviewer agy \
    --phase-brief "$A/briefs/gh387.md" --artifact src/gh387.js \
    --pre-advance-cmd "bash $GATE" >/dev/null 2>&1
rc=$?
runs="$(gate_runs)"
[ "$rc" -eq 7 ] \
  && pass "CONTROL: a timeout with no artifact still halts (exit 7) — the artifact guard survived" \
  || fail "CONTROL: expected exit 7 for a no-artifact timeout, got $rc"
[ "$(cat "$WORK/rd-count" 2>/dev/null)" = "1" ] \
  && pass "CONTROL: a no-artifact timeout does not dispatch a reviewer round" \
  || fail "CONTROL: no-artifact timeout re-entered relay-drive [$(cat "$WORK/rd-count" 2>/dev/null)]"
[ "$runs" = "0" ] \
  && pass "CONTROL: the gate never ran for a hang that produced nothing (runs=$runs)" \
  || fail "CONTROL: the gate ran $runs time(s) on a no-artifact hang — it should never see that phase"

echo "  gh387-gate-not-first-executor: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
