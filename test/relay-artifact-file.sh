#!/usr/bin/env bash
# relay-artifact-file.sh — GH-31 / #15: a READ-ONLY artifact (a cross-repo PR/diff) is seeded into the
# isolated worktree at .relay-artifacts/<basename> so a reviewer can READ it without it being committed
# into the target repo. Strict read-only: a reviewer that EDITS it fails the turn (off-lane, exit 6).
# Modeled on worktree-isolation.sh (real claude-turn.sh shim + a stub `claude`).
source "$(dirname "$0")/_setup.sh" relay-artifact-file
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
tick_a init >/dev/null

# Committed baseline. NEXT: Reviewer ⇒ rtl_init scopes the allowlist to the relay file only (the real
# artifact-review shape). The artifact lives OUTSIDE the repo (an external PR/diff file in $WORK).
printf 'STATUS: Open\nNEXT: Reviewer\n# relay body\n\n## Log\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed" >/dev/null 2>&1

ARTIFACT="$WORK/external-pr.diff"
printf 'diff --git a/x b/x\n+ARTIFACT_SENTINEL_42\n' >"$ARTIFACT"

# Stub `claude` (the reviewer). READ mode: read the artifact, echo a sentinel into the relay file (proof
# it could see it), no artifact edit. EDIT mode: also write to the artifact (must trip strict-fail).
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "relay.md" >/dev/null 2>&1
if [ -f ".relay-artifacts/external-pr.diff" ]; then
  sent="$(grep -o 'ARTIFACT_SENTINEL_42' .relay-artifacts/external-pr.diff | head -1)"
  printf '\n### Review · saw artifact: %s\nVERDICT: PASS\nBasis: verified artifact\n' "$sent" >> relay.md
else
  printf '\n### Review · ARTIFACT MISSING\nVERDICT: FAIL\nBasis: artifact missing\n' >> relay.md
fi
[ "${STUB_MODE:-read}" = edit ] && printf 'tampered\n' >> .relay-artifacts/external-pr.diff
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to producer >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ # <task> [paths]
  local task="$1" paths="${2:-relay.md}"
  tick_a log task.created "$task" --agent claude --paths "$paths" >/dev/null
  tick_a claim "$task" --agent claude --paths "$paths" >/dev/null 2>&1
  tick_a release "$task" --agent claude --to claude >/dev/null 2>&1
}

run_shim(){ # <task> <stub-mode> <artifact 0|1>
  local art=""; [ "$3" = 1 ] && art="$ARTIFACT"
  ( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$A/relay.md" RELAY_TASK="$1" \
      CLAUDE_AGENT=claude CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.$1.json" \
      ALLOW_PATHS="" CLAUDE_BLOCK_CMDS="" STUB_MODE="$2" RELAY_WORKTREE_ISOLATION=1 \
      RELAY_ARTIFACT_FILE="$art" \
      bash "$SHIM" >/dev/null 2>&1 )
}

# --- (1) read-only artifact: visible to the reviewer, NOT leaked into ROOT, turn succeeds ----------
seed_token RELAY-ART-read
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-ART-read read 1; rc=$?
[ "$rc" -eq 0 ] && pass "read-only artifact turn exits 0" || fail "expected 0, got $rc"
grep -q "saw artifact: ARTIFACT_SENTINEL_42" "$A/relay.md" && pass "reviewer could READ the seeded artifact" || fail "reviewer did not see the artifact"
[ ! -e "$A/.relay-artifacts" ] && pass "artifact NOT copied back to ROOT (no leak)" || fail ".relay-artifacts leaked into ROOT!"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "relay-file edit committed normally" || fail "expected a commit"
[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "worktree cleaned up" || fail "worktree leaked"

# --- (2) reviewer EDITS the artifact → strict-fail off-lane (exit 6), nothing copied back ----------
seed_token RELAY-ART-edit
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-ART-edit edit 1; rc=$?
[ "$rc" -eq 6 ] && pass "editing the read-only artifact fails the turn (exit 6)" || fail "expected exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "off-lane artifact edit made NO commit" || fail "off-lane edit should not commit"
[ ! -e "$A/.relay-artifacts" ] && pass "tampered artifact never reached ROOT" || fail ".relay-artifacts leaked into ROOT!"

# --- (3) default (no --artifact-file): unchanged, reviewer reports MISSING, no .relay-artifacts ----
seed_token RELAY-ART-none
run_shim RELAY-ART-none read 0; rc=$?
[ "$rc" -eq 0 ] && pass "no-artifact turn exits 0 (unchanged path)" || fail "expected 0, got $rc"
[ ! -e "$A/.relay-artifacts" ] && pass "no .relay-artifacts created when unset" || fail "unexpected .relay-artifacts"

# --- (4) GH-198: a missing Setup-referenced repo path fails fast before dispatch -------------------
MISSING_RELAY="$A/missing-setup-relay.md"
cat >"$MISSING_RELAY" <<'EOF'
STATUS: Open
NEXT: Reviewer
# relay body

## Setup
- Artifact under review: `missing/artifact.txt`
- Reviewer: claude   ·   Producer: producer
- Started: 2026-07-17

## Log
EOF
BLOCKED_AGENT="$WORK/blocked-agent.sh"
cat >"$BLOCKED_AGENT" <<'EOF'
#!/usr/bin/env bash
printf 'agent-ran\n' > "$WORK/blocked-agent-ran"
exit 0
EOF
chmod +x "$BLOCKED_AGENT"
rm -f "$WORK/blocked-agent-ran"
seed_token RELAY-ART-setup-missing "missing-setup-relay.md"
out="$(
  cd "$A" && \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  bash "$DRIVER" --target-root "$A" --relay-file "$MISSING_RELAY" \
    --relay-task RELAY-ART-setup-missing --agent-cmd "$BLOCKED_AGENT" 2>&1
)"; rc=$?
[ "$rc" -eq 2 ] && pass "missing Setup artifact path fails fast at dispatch time" || fail "expected exit 2, got $rc — $out"
grep -q "artifact path not found in worktree" <<<"$(printf '%s' "$out")" \
  && pass "missing Setup artifact path reports the clear GH-198 message" \
  || fail "missing Setup artifact message: $out"
[ ! -f "$WORK/blocked-agent-ran" ] \
  && pass "missing Setup artifact path blocks agent dispatch" \
  || fail "agent should not run when Setup artifact preflight fails"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
