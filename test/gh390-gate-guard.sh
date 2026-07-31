#!/usr/bin/env bash
# GH-390 Phase 1: the pre-advance gate must not be able to take the host down.
#
# The gate executes code an LLM wrote seconds earlier, and the packet forbids the builder from
# running it first — so the gate is by construction the first execution of the builder's work.
# With no timeout and no resource bounds, a generated test that mocked a paging function against a
# `while True:` loop consumed all 30.75 GB of swap and kernel-panicked the host twice on one day
# (GH-382). This pins the guard that turns that into a failed phase.
#
# Properties pinned here:
#   (1) an honest gate is unaffected — same exit code, and peak-RSS telemetry is recorded
#   (2) a runaway ALLOCATOR is killed at the RSS cap (layer 3) and escalates as `gate-killed`
#   (3) a HANG is killed at the wall-clock cap (layer 1)
#   (4) a CPU SPIN is killed by the kernel-enforced ulimit -t (layer 2), and its 128+SIGXCPU
#       exit is reported as a guard kill rather than as the gate finding a defect
#   (5) a gate that genuinely FAILS still escalates `pre-advance-failed` — the guard must not
#       relabel real red gates
#   (6) MARATHON_GATE_GUARD=0 restores the exact unguarded behavior (the ship-day escape hatch)
#
# Every runaway fixture below is SELF-LIMITING: if the guard fails to kill it, the fixture exits
# on its own well short of any level that could affect the host, and the case fails loudly. This
# test must never be able to reproduce the panic it exists to prevent.
source "$(dirname "$0")/_setup.sh" gh390-gate-guard
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/relay-automation/marathon-drive.sh"

# ── fixture: a marathon root whose gate we swap per case ─────────────────────────────────
ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh390@t
git -C "$ROOT" config user.name gh390
printf '.tick/\n' > "$ROOT/.gitignore"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

# Stub relay-drive: marks the thread Approved so the driver proceeds straight to the gate,
# which is the only thing under test.
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
rf=""
while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
exit 0
STUB_EOF
chmod +x "$STUB_RD"
STUB_BIN="$WORK/stub-bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"
chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"
printf '## Do a thing\nBody.\n' > "$BRIEF"

# Self-limiting allocator: ~10 MB/50 ms, hard stop at 1 GB. Reaching the stop means the guard
# never fired; the fixture exits 0 so the case can report a clean, unambiguous failure.
HOG="$WORK/hog.py"
cat > "$HOG" << 'HOG_EOF'
import time
blocks = []
for _ in range(100):            # hard ceiling: 100 x 10 MB = 1 GB, then exit cleanly
    blocks.append(bytearray(10 * 1024 * 1024))
    time.sleep(0.05)
HOG_EOF

# Each case passes its OWN --phase-id: a lane whose token is already spent takes the
# "already terminal, re-run only the gate" path instead of the one under test. Note the ids are
# passed explicitly rather than from a counter — every call site here is inside "$( … )", which
# runs in a subshell, so a counter incremented in the function would never reach the next case.
run_driver() {  # <extra-args…>
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  bash "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder claude \
    "$@"
}

esc_reason() {  # <phase-id> — the reason recorded in that phase's ESCALATION.md
  sed -n 's/^reason: //p' "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null
}

# ── (1) an honest gate is unaffected, and telemetry is recorded ──────────────────────────
out="$(run_driver --phase-id p1 --pre-advance-cmd '/usr/bin/true' 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "an honest gate still passes under the guard (exit 0)"
else
  fail "guard broke an honest gate (rc=$rc): $(printf '%s' "$out" | tail -5)"
fi
case "$out" in
  *"peak group RSS"*) pass "peak-RSS telemetry is logged on a passing run (the Phase 3 trip condition)" ;;
  *) fail "no peak-RSS telemetry logged on a passing run: $(printf '%s' "$out" | tail -5)" ;;
esac

# ── (2) layer 3: a runaway allocator is killed at the RSS cap ────────────────────────────
start=$SECONDS
out="$(MARATHON_GATE_RSS_MB=256 run_driver --phase-id p2 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
elapsed=$((SECONDS - start))
if [ "$rc" -eq 5 ]; then
  pass "a runaway allocator halts the phase (exit 5) instead of the host"
else
  fail "expected exit 5 for a killed gate, got $rc — the hog may have run to its own ceiling: $(printf '%s' "$out" | tail -5)"
fi
case "$out" in
  *"KILLING gate process group"*) pass "layer 3 killed the gate's whole process group" ;;
  *) fail "no group kill logged — the RSS watchdog did not fire: $(printf '%s' "$out" | tail -5)" ;;
esac
if [ "$(esc_reason p2)" = "gate-killed" ]; then
  pass "ESCALATION.md records reason: gate-killed (distinct from a red gate)"
else
  fail "expected reason gate-killed, got '$(esc_reason p2)'"
fi
if [ "$elapsed" -lt 30 ]; then
  pass "the kill landed promptly (${elapsed}s), well before the hog's own 1 GB ceiling"
else
  fail "kill took ${elapsed}s — too slow to be protecting anything"
fi

# ── (3) layer 1: a hang is killed at the wall-clock cap ──────────────────────────────────
start=$SECONDS
out="$(MARATHON_GATE_WALL_S=3 MARATHON_GATE_CPU_S=0 run_driver --phase-id p3 --pre-advance-cmd 'sleep 60' 2>&1)"; rc=$?
elapsed=$((SECONDS - start))
if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 40 ]; then
  pass "a hanging gate is killed at the wall-clock cap (${elapsed}s, exit 5)"
else
  fail "hanging gate not capped (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
fi
case "$out" in
  *"wall clock"*) pass "the kill reason names the wall-clock cap" ;;
  *) fail "wall-clock cap not named in the kill reason: $(printf '%s' "$out" | tail -5)" ;;
esac

# ── (4) layer 2: a CPU spin is killed by ulimit -t, and reads as a guard kill ────────────
# Wall and RSS are set out of reach so only the kernel-enforced cap can end this.
start=$SECONDS
out="$(MARATHON_GATE_CPU_S=2 MARATHON_GATE_WALL_S=120 MARATHON_GATE_RSS_MB=0 \
       run_driver --phase-id p4 --pre-advance-cmd 'python3 -c "while True: pass"' 2>&1)"; rc=$?
elapsed=$((SECONDS - start))
if [ "$rc" -eq 5 ] && [ "$elapsed" -lt 60 ]; then
  pass "a CPU spin is killed by the kernel-enforced cap (${elapsed}s, exit 5)"
else
  fail "CPU cap did not end the spin (rc=$rc, ${elapsed}s): $(printf '%s' "$out" | tail -5)"
fi
if [ "$(esc_reason p4)" = "gate-killed" ]; then
  pass "a SIGXCPU kill escalates as gate-killed, not as the gate finding a defect"
else
  fail "expected reason gate-killed for the CPU cap, got '$(esc_reason p4)'"
fi

# ── (5) a genuinely failing gate is still `pre-advance-failed` ───────────────────────────
out="$(run_driver --phase-id p5 --pre-advance-cmd '/usr/bin/false' 2>&1)"; rc=$?
if [ "$rc" -eq 5 ]; then
  pass "a red gate still halts the phase (exit 5)"
else
  fail "a red gate did not halt the phase (rc=$rc): $(printf '%s' "$out" | tail -5)"
fi
if [ "$(esc_reason p5)" = "pre-advance-failed" ]; then
  pass "a red gate keeps reason pre-advance-failed — the guard does not relabel real failures"
else
  fail "guard relabelled a real gate failure as '$(esc_reason p5)'"
fi

# ── (6) the escape hatch restores the unguarded path ─────────────────────────────────────
# The same allocator that case (2) killed must now run to its own 1 GB ceiling and pass,
# proving the switch removes the guard rather than merely loosening a cap.
out="$(MARATHON_GATE_GUARD=0 MARATHON_GATE_RSS_MB=256 run_driver --phase-id p6 --pre-advance-cmd "python3 $HOG" 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "MARATHON_GATE_GUARD=0 restores the unguarded gate (the hog completes, exit 0)"
else
  fail "escape hatch did not restore unguarded behavior (rc=$rc): $(printf '%s' "$out" | tail -5)"
fi
case "$out" in
  *"KILLING gate process group"*) fail "guard still killed the gate with MARATHON_GATE_GUARD=0" ;;
  *) pass "no kill occurred with the guard disabled" ;;
esac

echo "  gh390-gate-guard: $PASS pass, $FAIL fail"
exit 0
