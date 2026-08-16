#!/usr/bin/env bash
# test/gh378-gate-requires-green-suite.sh — GH-378 pre-advance gate baseline allowance test suite.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh378-gate-requires-green-suite.sh; assertions verify: (1) decision record exists at decisions/2026-08-10-marathon-gate-baseline-strategy.md; (2) positive case: phase advances on red suite matching baseline allowance (exit 1); (3) negative control: phase halts when regression worsens exit code (exit 2 > 1); (4) negative control: phase halts when baseline is unconfigured; (5) documentation in README.md and MARATHON.example.yaml"}

source "$(dirname "$0")/_setup.sh" gh378-gate-requires-green-suite
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/utils/py/marathon_drive.py"

ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh378@t
git -C "$ROOT" config user.name gh378
printf '.tick/\n' > "$ROOT/.gitignore"
git -C "$ROOT" add .gitignore >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"

RD_OK="$WORK/relay-drive-ok.sh"
cat > "$RD_OK" << 'STUB_EOF'
#!/usr/bin/env bash
rf=""
while (($#)); do case "$1" in --relay-file) rf="${2:-}"; shift 2 ;; *) shift ;; esac; done
[ -n "$rf" ] && printf 'STATUS: Approved\n' >> "$rf"
exit 0
STUB_EOF
chmod +x "$RD_OK"

run_driver() {  # <extra-args…>
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$RD_OK" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  python3 "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder codex \
    "$@"
}
esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }

# --- (1) Acceptance criterion 1: Decision record exists under decisions/ ---
[ -f "$ROOT_REPO/decisions/2026-08-10-marathon-gate-baseline-strategy.md" ] \
  && pass "decision record exists: decisions/2026-08-10-marathon-gate-baseline-strategy.md" \
  || fail "missing decisions/2026-08-10-marathon-gate-baseline-strategy.md"

# --- (2) Positive case: Phase advances when pre-existing failure matches baseline allowance ---
cat > "$ROOT/validate.sh" << 'SH_EOF'
#!/usr/bin/env bash
exit 1
SH_EOF
chmod +x "$ROOT/validate.sh"

run_driver --phase-id p1 --relay-task MARATHON-P1-TURN --pre-advance-baseline 1 > "$WORK/p1.log" 2>&1 \
  && pass "GH-378: phase advanced under baseline allowance matching pre-existing failure (exit 1)" \
  || fail "phase failed to advance under baseline allowance"

# --- (3) Negative control: Phase HALTS when a new regression worsens the exit code ---
cat > "$ROOT/validate.sh" << 'SH_EOF'
#!/usr/bin/env bash
exit 2
SH_EOF
chmod +x "$ROOT/validate.sh"

run_driver --phase-id p2 --relay-task MARATHON-P2-TURN --pre-advance-baseline 1 > "$WORK/p2.log" 2>&1 && rc=0 || rc=$?
[ "$rc" -ne 0 ] \
  && pass "control: phase HALTED when gate exit code exceeded baseline allowance (exit 2 > 1)" \
  || fail "control failed: phase unexpectedly passed on new regression"

reason="$(esc_field p2 reason)"
[ "$reason" = "pre-advance-failed" ] \
  && pass "control: ESCALATION.md recorded pre-advance-failed on regression" \
  || fail "expected reason pre-advance-failed, got '$reason'"

# --- (4) Negative control: Phase HALTS when baseline is unconfigured ---
cat > "$ROOT/validate.sh" << 'SH_EOF'
#!/usr/bin/env bash
exit 1
SH_EOF
chmod +x "$ROOT/validate.sh"

run_driver --phase-id p3 --relay-task MARATHON-P3-TURN > "$WORK/p3.log" 2>&1 && rc=0 || rc=$?
[ "$rc" -ne 0 ] \
  && pass "control: phase HALTED when baseline is unconfigured and suite is red (exit 1)" \
  || fail "control failed: unconfigured baseline unexpectedly passed on red suite"

# --- (5) Documentation assertions ---
grep -q "pre-advance-baseline" "$ROOT_REPO/README.md" \
  && pass "README.md documents pre-advance-baseline" \
  || fail "README.md missing pre-advance-baseline documentation"

grep -q "pre-advance-baseline" "$ROOT_REPO/relay-automation/MARATHON.example.yaml" \
  && pass "MARATHON.example.yaml documents pre-advance-baseline" \
  || fail "MARATHON.example.yaml missing pre-advance-baseline documentation"

exit 0
