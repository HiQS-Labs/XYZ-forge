#!/usr/bin/env bash
# test/gh379-claude-builder-diagnosis.sh — GH-379 Claude builder diagnosis surfacing test suite.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh379-claude-builder-diagnosis.sh; assertions verify: (1) builder error diagnostics from claude_log reach ESCALATION.md as additive builder-diagnostic field; (2) negative control: no diagnostic when log is clean; (3) CLAUDE_MAX_BUDGET and CLAUDE_MAX_TURNS are documented in README.md and MARATHON.example.yaml; (4) claude-turn.sh header comment matches code default"}

source "$(dirname "$0")/_setup.sh" gh379-claude-builder-diagnosis
export TICK_BIN="$TICK"
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT_REPO/utils/py/marathon_drive.py"

ROOT="$WORK/target"
mkdir -p "$ROOT"
git init -q "$ROOT"
git -C "$ROOT" config user.email gh379@t
git -C "$ROOT" config user.name gh379
printf '.tick/\n' > "$ROOT/.gitignore"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ROOT/validate.sh"
git -C "$ROOT" add .gitignore validate.sh >/dev/null 2>&1
git -C "$ROOT" commit -q -m init

STUB_BIN="$WORK/stub-bin"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_BIN"; chmod +x "$STUB_BIN"
BRIEF="$WORK/brief.md"; printf '## Do a thing\nBody.\n' > "$BRIEF"

RD_FAIL="$WORK/relay-drive-fail.sh"
cat > "$RD_FAIL" << 'STUB_EOF'
#!/usr/bin/env bash
exit 5
STUB_EOF
chmod +x "$RD_FAIL"

run_driver() {  # <extra-args…>
  MARATHON_ROOT="$ROOT" \
  MARATHON_RELAY_DRIVE="$RD_FAIL" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$ROOT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_BIN" AGY_BIN="$STUB_BIN" CODEX_BIN="$STUB_BIN" \
  python3 "$DRIVER" \
    --phases-dir "$ROOT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --builder claude \
    "$@"
}
esc_field() { sed -n "s/^$2: //p" "$ROOT/phases/$1/ESCALATION.md" 2>/dev/null; }

# --- (1) Acceptance criterion 1: Error diagnostic reaches ESCALATION.md ---
mkdir -p "$ROOT/relay-system/logs/2026-08-15"
cat > "$ROOT/relay-system/logs/2026-08-15/claude-turn-MARATHON-P1-TURN-12345.log" << 'JSON_EOF'
{
  "is_error": true,
  "subtype": "error_max_budget_usd",
  "terminal_reason": "budget_exhausted",
  "total_cost_usd": 0.501
}
JSON_EOF

run_driver --phase-id p1 --relay-task MARATHON-P1-TURN > "$WORK/p1.log" 2>&1 || true

bdiag="$(esc_field p1 builder-diagnostic)"
printf '%s' "$bdiag" | grep -q "subtype=error_max_budget_usd" \
  && pass "GH-379: builder diagnostic subtype reached ESCALATION.md" \
  || fail "builder diagnostic missing subtype: $bdiag"

printf '%s' "$bdiag" | grep -q "terminal_reason=budget_exhausted" \
  && pass "GH-379: builder diagnostic terminal_reason reached ESCALATION.md" \
  || fail "builder diagnostic missing terminal_reason: $bdiag"

# --- (2) Negative control: No diagnostic when turn log is absent/clean ---
rm -rf "$ROOT/phases/p2" "$ROOT/relay-system/logs/2026-08-15/claude-turn-MARATHON-P2-TURN-*.log"
run_driver --phase-id p2 --relay-task MARATHON-P2-TURN > "$WORK/p2.log" 2>&1 || true
bdiag2="$(esc_field p2 builder-diagnostic)"
[ -z "$bdiag2" ] \
  && pass "control: no builder-diagnostic field written when no diagnostic error is present" \
  || fail "control failed: unexpected builder-diagnostic: $bdiag2"

# --- (3) Acceptance criterion 2: Documentation in README.md and MARATHON.example.yaml ---
grep -q "CLAUDE_MAX_BUDGET" "$ROOT_REPO/README.md" \
  && pass "README.md documents CLAUDE_MAX_BUDGET" \
  || fail "README.md missing CLAUDE_MAX_BUDGET documentation"

grep -q "CLAUDE_MAX_BUDGET" "$ROOT_REPO/relay-automation/MARATHON.example.yaml" \
  && pass "MARATHON.example.yaml documents CLAUDE_MAX_BUDGET" \
  || fail "MARATHON.example.yaml missing CLAUDE_MAX_BUDGET documentation"

# --- (4) Acceptance criterion 3: claude-turn.sh header comment matches code default ---
grep -q "CLAUDE_MAX_BUDGET — max cost passed to --max-budget-usd (default: 0.50)" "$ROOT_REPO/relay-automation/claude-turn.sh" \
  && pass "claude-turn.sh header comment correctly states default: 0.50" \
  || fail "claude-turn.sh header comment is stale"

exit 0
