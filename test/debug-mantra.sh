#!/usr/bin/env bash
# debug-mantra.sh — GH-162: auto-on debug-mantra note after a phase's prior attempt did not reach
# Approved. Covers the read-only peek (debug_mantra_prior_attempts) + the note builder
# (debug_mantra_note) via marathon-drive.sh's real --dry-run render (fast: dry-run exits BEFORE
# lane_attempt_gate ever runs, so it can never mutate .tick/attempts/<lane> itself).
source "$(dirname "$0")/_setup.sh" debug-mantra
export TICK_BIN="$TICK"
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
MANTRA_FILE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/DEBUG-MANTRA.md"
tick_a init >/dev/null

printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "init"

BRIEF="$WORK/brief.md"
printf '## Implement a hello-world function\nWrite a function that returns "hello".\n' > "$BRIEF"

# GH-117: marathon-drive.sh probes builder/reviewer binaries before rendering — stub them so this
# test never depends on claude/agy actually being installed (mirrors test/marathon-drive.sh).
STUB_CLAUDE_BIN="$WORK/stub-claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE_BIN"; chmod +x "$STUB_CLAUDE_BIN"
STUB_AGY_BIN="$WORK/stub-agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY_BIN"; chmod +x "$STUB_AGY_BIN"

run_driver() {  # <extra-args…>
  # GH-232: pin --builder claude (mirrors test/marathon-drive.sh's GH-212 convention) — the actual
  # default builder is codex, which isn't stubbed here and isn't on PATH on ubuntu CI.
  MARATHON_ROOT="$A" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" \
    --phases-dir "$A/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --pre-advance-cmd "true" \
    --dry-run \
    --builder claude \
    "$@"
}

[ -f "$MANTRA_FILE" ] && pass "relay-automation/DEBUG-MANTRA.md exists" || fail "DEBUG-MANTRA.md missing"
grep -qi "reproduce reliably" "$MANTRA_FILE" 2>/dev/null \
  && grep -qi "know the fail path" "$MANTRA_FILE" \
  && grep -qi "question the hypothesis" "$MANTRA_FILE" \
  && grep -qi "breadcrumb" "$MANTRA_FILE" \
  && pass "DEBUG-MANTRA.md carries all four discipline steps" \
  || fail "DEBUG-MANTRA.md missing one of the four discipline steps"

# ── (1) first-ever fire (no .tick/attempts/p1 file yet): NO debug-mantra section ──────────────
run1_out="$(run_driver 2>&1)"; run1_rc=$?
if [ ! -f "$A/phases/p1/RELAY.md" ]; then echo "DEBUG driver output (rc=$run1_rc):" >&2; printf '%s\n' "$run1_out" >&2; fi
grep -q "## Debug mantra" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && fail "first fire should NOT carry a debug-mantra note (no prior attempts)" \
  || pass "first fire: relay file has no debug-mantra note"
grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "first fire: phase brief still rendered normally" \
  || fail "first fire: phase brief missing — render broke"
rm -rf "$A/phases" "$A/.tick"

# ── (2) one prior attempt recorded: debug-mantra note appears, points at DEBUG-MANTRA.md ──────
mkdir -p "$A/.tick/attempts"
printf 'fire\n' > "$A/.tick/attempts/p1"
run_driver >/dev/null 2>&1
grep -q "## Debug mantra" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "one prior attempt: debug-mantra note appears" \
  || fail "one prior attempt: debug-mantra note missing"
grep -q "relay-automation/DEBUG-MANTRA.md" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "note references the DEBUG-MANTRA.md file by absolute-anchored path" \
  || fail "note does not reference DEBUG-MANTRA.md"
grep -q "1 prior attempt" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "note states the prior-attempt count (1)" \
  || fail "note missing the prior-attempt count"
# read-only: dry-run must never mutate the attempts file itself
[ "$(wc -l < "$A/.tick/attempts/p1" | tr -d ' ')" = "1" ] \
  && pass "peek never mutated .tick/attempts/p1 (still 1 line — read-only)" \
  || fail "attempts file was mutated by a dry-run peek (should be read-only)"
rm -rf "$A/phases" "$A/.tick"

# ── (3) prior ESCALATION.md present: note cites the concrete recorded reason ───────────────────
mkdir -p "$A/.tick/attempts" "$A/phases/p1"
printf 'fire\n' > "$A/.tick/attempts/p1"
cat > "$A/phases/p1/ESCALATION.md" << 'ESC_EOF'
# ESCALATION — Marathon Phase p1

phase: p1
task: MARATHON-P1-TURN
relay-drive-exit: 0
reason: pre-advance-failed
relay-file: phases/p1/RELAY.md
ESC_EOF
run_driver >/dev/null 2>&1
grep -q "## Debug mantra" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "with ESCALATION.md: debug-mantra note appears" \
  || fail "with ESCALATION.md: debug-mantra note missing"
grep -q 'pre-advance-failed' "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "note cites the last recorded ESCALATION.md reason (pre-advance-failed)" \
  || fail "note does not cite the ESCALATION.md reason"
rm -rf "$A/phases" "$A/.tick"

# ── (4) two prior attempts: count reflects the real .tick/attempts/p1 line count ──────────────
mkdir -p "$A/.tick/attempts"
printf 'fire\nfire\n' > "$A/.tick/attempts/p1"
run_driver >/dev/null 2>&1
grep -q "2 prior attempt" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "two prior attempts: note states count (2)" \
  || fail "two prior attempts: count not reflected"
rm -rf "$A/phases" "$A/.tick"
git -C "$A" reset -q --hard >/dev/null 2>&1 || true

# ── (5) debug_mantra_prior_attempts / debug_mantra_note are functions, not inlined duplicate logic --
grep -q '^debug_mantra_prior_attempts()' "$DRIVER" && pass "debug_mantra_prior_attempts defined" || fail "debug_mantra_prior_attempts missing"
grep -q '^debug_mantra_note()' "$DRIVER" && pass "debug_mantra_note defined" || fail "debug_mantra_note missing"
# GH-45 byte-identical mirror contract (test/lane-attempt-cap.sh) must stay untouched: the new GH-162
# functions must sit OUTSIDE the _lane_key..lane_attempt_reset extraction range.
awk '/^_lane_key\(\)/{p=1} p{print} p&&/^lane_attempt_reset\(\)/{r=1} r&&/^\}/{exit}' "$DRIVER" \
  | grep -q 'debug_mantra' \
  && fail "GH-162 helpers leaked into the GH-45 byte-identical mirror block" \
  || pass "GH-162 helpers stay outside the GH-45 byte-identical mirror block"

echo "== debug-mantra: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
