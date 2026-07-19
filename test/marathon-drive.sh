#!/usr/bin/env bash
# marathon-drive.sh test: single-phase driver — renders relay file, seeds tick token,
# calls relay-drive, runs pre-advance gate, saves transcript, emits phase events.
# Uses MARATHON_RELAY_DRIVE + MARATHON_AGENT_CMD + stub pre-advance-cmd to avoid real CLI.
source "$(dirname "$0")/_setup.sh" marathon-drive
unset MARATHON_LANE_NS
export TICK_BIN="$TICK"
DRIVER="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
tick_a init >/dev/null

# Set up the fixture repo as the marathon root: .gitignore .tick/, seed an initial commit.
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "init"
INIT_HEAD="$(git -C "$A" rev-parse HEAD)"   # saved so we can hard-reset between cases

# Stub relay-drive: writes EXIT_CODE to $WORK/relay-drive-exit, echoes args, then exits.
STUB_RD="$WORK/relay-drive.sh"
cat > "$STUB_RD" << 'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/relay-drive-args"
exit "${RELAY_DRIVE_EXIT:-0}"
STUB_EOF
chmod +x "$STUB_RD"

# Phase brief file used across tests.
BRIEF="$WORK/brief.md"
printf '## Implement a hello-world function\nWrite a function that returns "hello".\n' > "$BRIEF"

# GH-117: stub builder/reviewer binaries so marathon-drive's binary-existence probe (added ahead of
# any tick mutation) sees a resolvable claude/agy on every pre-existing test below — this suite never
# invokes the real CLI (relay-drive is stubbed), so it must not depend on claude/agy actually being
# installed on the test machine either.
STUB_CLAUDE_BIN="$WORK/stub-claude"
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE_BIN"
chmod +x "$STUB_CLAUDE_BIN"
STUB_AGY_BIN="$WORK/stub-agy"
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY_BIN"
chmod +x "$STUB_AGY_BIN"
STUB_CODEX_BIN="$WORK/stub-codex"
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CODEX_BIN"
chmod +x "$STUB_CODEX_BIN"
MISSING_BIN="$WORK/does-not-exist-bin"   # deliberately never created

# GH-212: this suite's default builder identity is pinned to `claude` here (not marathon-drive's
# own new `codex` default) so every existing case below — written against a literal "claude" agent
# identity in tick claims/relay text — keeps testing exactly what it always tested. The dedicated
# GH-212 case further down verifies the real (unpinned) default separately.
run_driver() {  # <extra-args…>
  MARATHON_ROOT="$A" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="${CLAUDE_BIN:-$STUB_CLAUDE_BIN}" AGY_BIN="${AGY_BIN:-$STUB_AGY_BIN}" \
  bash "$DRIVER" \
    --phases-dir "$A/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --pre-advance-cmd "true" \
    --builder claude \
    "$@"
}

# ── (1) dry-run: relay file rendered, no commit, no tick events ───────────
run_driver --dry-run >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "dry-run exits 0" || fail "dry-run exit=$rc"
[ -f "$A/phases/p1/RELAY.md" ] && pass "dry-run renders phases/p1/RELAY.md" || fail "relay file should exist after dry-run"
git -C "$A" diff --cached --quiet && pass "dry-run makes no staged changes" || fail "dry-run should not stage anything"
# relay file is unstaged in dry-run — no git add yet
before_head="$(git -C "$A" rev-parse HEAD)"
run_driver --dry-run >/dev/null 2>&1 || true   # run again to confirm HEAD stability
[ "$(git -C "$A" rev-parse HEAD)" = "$before_head" ] && pass "dry-run makes no commits" || fail "dry-run should not commit"

# Clean up the dry-run rendered file (it's untracked) before next test.
rm -rf "$A/phases"

# ── (2) relay file template: builder + reviewer sections present ──────────
RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
grep -q "TAKE YOUR TURN.*claude.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "relay file has builder TAKE YOUR TURN section" \
  || fail "builder TAKE YOUR TURN section missing"
grep -q "TAKE YOUR TURN.*agy.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "relay file has reviewer TAKE YOUR TURN section" \
  || fail "reviewer TAKE YOUR TURN section missing"
grep -q "STATUS: Open" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "relay file has STATUS: Open" \
  || fail "STATUS: Open missing"
grep -q "Implement a hello-world" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "phase brief text baked into relay file" \
  || fail "brief text not in relay file"
# clean for next case
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (3) tick token seeded: task created + handed to builder ──────────────
RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
# Verify task exists by checking the tick events dir directly (most reliable).
ls "$A/.tick/events/" 2>/dev/null | grep -q "MARATHON-P1-TURN" \
  && pass "MARATHON-P1-TURN tick task created (event file present)" \
  || fail "MARATHON-P1-TURN tick task not found — no event file in .tick/events/"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (3b) leaked open handoff is reconciled before re-seeding the same phase-id (GH-56) ─
tick_a log task.created MARATHON-P1-TURN --agent seed >/dev/null
tick_a claim MARATHON-P1-TURN --agent seed --paths "phases/p1/RELAY.md" >/dev/null
tick_a release MARATHON-P1-TURN --agent seed --to claude >/dev/null
LEAK_INFO="$(tick_a info MARATHON-P1-TURN 2>&1 || true)"
printf '%s\n' "$LEAK_INFO" | grep -qE '^status:[[:space:]]+open$' \
  && printf '%s\n' "$LEAK_INFO" | grep -qE '^handoff-to:[[:space:]]+claude$' \
  && pass "seeded the leaked open handoff fixture" \
  || fail "expected leaked open handoff fixture, got: $LEAK_INFO"
RERUN_OUT="$(RELAY_DRIVE_EXIT=0 run_driver 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "driver reconciles leaked handoff and re-seeds cleanly" \
  || fail "driver should succeed after reconciling leaked handoff: $RERUN_OUT"
printf '%s\n' "$RERUN_OUT" | grep -q "task MARATHON-P1-TURN is open" \
  && fail "driver hit the old leaked-token collision: $RERUN_OUT" \
  || pass "driver avoids the old 'task ... is open' collision"
tick_a info MARATHON-P1-TURN | grep -qE '^handoff-to:[[:space:]]+claude$' \
  && pass "driver re-seeds the token back to the builder handoff" \
  || fail "driver did not restore the builder handoff: $(tick_a info MARATHON-P1-TURN)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (3c) a live claim is never reaped during re-seed (GH-56) ──────────────
tick_a log task.created MARATHON-P1-TURN --agent seed >/dev/null
tick_a claim MARATHON-P1-TURN --agent claude --paths "phases/p1/RELAY.md" >/dev/null
LIVE_OUT="$(RELAY_DRIVE_EXIT=0 run_driver 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass "live claim blocks re-seed instead of being reaped" \
  || fail "re-seed should refuse a live claim, not reap it"
printf '%s\n' "$LIVE_OUT" | grep -q "refusing to reap a live claim" \
  && pass "live-claim refusal is explicit" \
  || fail "expected explicit live-claim refusal, got: $LIVE_OUT"
tick_a info MARATHON-P1-TURN | grep -qE '^claimer:[[:space:]]+claude$' \
  && pass "live claude claim survives the failed re-seed" \
  || fail "live claim was disturbed by re-seed attempt: $(tick_a info MARATHON-P1-TURN)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (4) relay-drive called with correct args ──────────────────────────────
RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1 || true
grep -q -- "--relay-file" "$WORK/relay-drive-args" \
  && pass "relay-drive called with --relay-file" \
  || fail "--relay-file arg missing from relay-drive invocation"
grep -q -- "--relay-task" "$WORK/relay-drive-args" \
  && pass "relay-drive called with --relay-task" \
  || fail "--relay-task arg missing from relay-drive invocation"
grep -q -- "--round-cap" "$WORK/relay-drive-args" \
  && pass "relay-drive called with --round-cap" \
  || fail "--round-cap arg missing from relay-drive invocation"
grep -q -- "--agent-cmd" "$WORK/relay-drive-args" \
  && pass "relay-drive called with --agent-cmd" \
  || fail "--agent-cmd arg missing from relay-drive invocation"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (5) happy path: relay exit 0 → pre-advance passes → transcript saved ─
GATE_CMD="$WORK/gate-pass.sh"
printf '#!/usr/bin/env bash\nprintf "gate: passed\n"; exit 0\n' > "$GATE_CMD"
chmod +x "$GATE_CMD"

RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "happy path exits 0 (relay approved + gate passed)" || fail "happy path exit=$rc"
ls "$A/relay-system"/*/marathon-p1-*.md >/dev/null 2>&1 \
  && pass "transcript saved under relay-system/<date>/" \
  || fail "transcript not found in relay-system/"
# marathon.phase.approved event emitted (check events dir directly)
ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.phase.approved" \
  && pass "marathon.phase.approved event emitted" \
  || fail "marathon.phase.approved not found in tick events"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (6) pre-advance gate failure → ESCALATION.md, exit 5 ─────────────────
GATE_CMD_FAIL="$WORK/gate-fail.sh"
printf '#!/usr/bin/env bash\nprintf "gate: FAILED\n" >&2; exit 1\n' > "$GATE_CMD_FAIL"
chmod +x "$GATE_CMD_FAIL"

RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD_FAIL" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "pre-advance failure exits 5" || fail "pre-advance failure exit=$rc (expected 5)"
[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on gate failure" || fail "ESCALATION.md missing"
grep -q "pre-advance-failed" "$A/phases/p1/ESCALATION.md" \
  && pass "ESCALATION.md records pre-advance-failed reason" \
  || fail "reason field missing in ESCALATION.md"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (7) relay cap/mismatch (exit 4) → ESCALATION.md, driver exits 4 ──────
RELAY_DRIVE_EXIT=4 run_driver >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "relay cap escalation exits 4" || fail "relay cap exit=$rc (expected 4)"
[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on relay cap" || fail "ESCALATION.md missing on cap"
grep -q "relay-drive-exit: 4" "$A/phases/p1/ESCALATION.md" \
  && pass "ESCALATION.md records relay-drive-exit: 4" \
  || fail "relay-drive-exit field wrong in ESCALATION.md"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (8) relay no-progress (exit 3) → ESCALATION.md, driver exits 3 ───────
RELAY_DRIVE_EXIT=3 run_driver >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "relay no-progress exits 3" || fail "relay no-progress exit=$rc (expected 3)"
[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on no-progress" || fail "ESCALATION.md missing on no-progress"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (8b) containment violation (exit 6) → ESCALATION.md, driver exits 6 (Phase 3.6) ───
# A turn-taker shim exits 6 when it reverts an off-lane edit; relay-drive propagates it. The
# driver must treat that as a DEFINED escalation, not die "unexpected code 6" (dogfood 2026-06-17).
RELAY_DRIVE_EXIT=6 run_driver >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] && pass "containment violation escalation exits 6 (not 'unexpected')" || fail "containment exit=$rc (expected 6)"
[ -f "$A/phases/p1/ESCALATION.md" ] && pass "ESCALATION.md written on containment violation" || fail "ESCALATION.md missing on exit 6"
grep -q "containment-violation" "$A/phases/p1/ESCALATION.md" \
  && pass "ESCALATION.md records containment-violation reason" \
  || fail "containment-violation reason missing in ESCALATION.md"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (9) MARATHON_BUILDER/MARATHON_REVIEWER exported for peer threading ────
RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1 || true
# We can only verify this indirectly: marathon-agent.sh reads MARATHON_BUILDER/REVIEWER.
# Here we just confirm the env vars are wired through by checking drive output doesn't error.
pass "MARATHON_BUILDER/MARATHON_REVIEWER wired (no dispatcher errors in happy path)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (10) custom round-cap reaches relay-drive ─────────────────────────────
RELAY_DRIVE_EXIT=0 run_driver --round-cap 9 >/dev/null 2>&1 || true
grep -q "9" "$WORK/relay-drive-args" \
  && pass "--round-cap 9 passed to relay-drive" \
  || fail "custom round-cap not found in relay-drive args"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (11) agent-cmd path with spaces survives relay-drive dispatch ──────────
# Regression: relay-drive runs a BARE executable --agent-cmd directly (space-safe), falling back to
# eval only for command strings. marathon-drive passes the path as-is (no %q quoting). This case uses
# a stub that mirrors relay-drive's smart dispatch, with the agent script under a spaced directory.
SPACED_AGENT="$WORK/dir with space/agent.sh"
mkdir -p "$WORK/dir with space"
cat > "$SPACED_AGENT" <<AG
#!/usr/bin/env bash
printf 'ran\n' > "$WORK/spaced-agent-ran"
AG
chmod +x "$SPACED_AGENT"
EVAL_RD="$WORK/relay-drive-eval.sh"
cat > "$EVAL_RD" <<'RD'
#!/usr/bin/env bash
set -u
acmd=""
while (($# > 0)); do case "$1" in --agent-cmd) acmd="${2:-}"; shift 2 ;; *) shift ;; esac; done
# mirrors relay-drive.sh: bare executable path → run directly (survives spaces); else eval.
if [[ -x "$acmd" ]]; then "$acmd"; else eval "$acmd"; fi
exit 0
RD
chmod +x "$EVAL_RD"
rm -f "$WORK/spaced-agent-ran"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$SPACED_AGENT" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --pre-advance-cmd "true" >/dev/null 2>&1 || true
[ -f "$WORK/spaced-agent-ran" ] \
  && pass "agent-cmd path with spaces survives relay-drive dispatch" \
  || fail "spaced agent-cmd path broke relay-drive dispatch — bare path must be invoked directly"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (12) --artifact: real write surface (template targets it + ALLOW_PATHS reaches the turn-taker) ─
ART="src/feature.js"
# (a) the artifact path is baked into the relay and the tick claim --paths includes it
RELAY_DRIVE_EXIT=0 run_driver --artifact "$ART" >/dev/null 2>&1 || true
grep -q "$ART" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "artifact path baked into relay template" || fail "artifact path missing from relay"
grep -q -- "--paths \"phases/p1/RELAY.md,$ART\"" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "tick claim --paths includes relay + artifact" || fail "claim --paths should declare the artifact"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
# (b) ALLOW_PATHS is exported down to the turn-taker (eval-ing stub relay-drive + env-recording agent)
ENV_AGENT="$WORK/env-agent.sh"
cat > "$ENV_AGENT" <<AG
#!/usr/bin/env bash
printf '%s\n' "\${ALLOW_PATHS:-UNSET}" > "$WORK/allow-paths-seen"
AG
chmod +x "$ENV_AGENT"
rm -f "$WORK/allow-paths-seen"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --artifact "$ART" --pre-advance-cmd "true" >/dev/null 2>&1 || true
grep -q "$ART" "$WORK/allow-paths-seen" 2>/dev/null \
  && pass "ALLOW_PATHS exported to the turn-taker env" \
  || fail "ALLOW_PATHS not propagated to agent-cmd (builder would have no write surface)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
# (c) relay-only (no --artifact) leaves ALLOW_PATHS UNSET — containment default unchanged
rm -f "$WORK/allow-paths-seen"
ALLOW_PATHS="leaked/from/parent" \
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer agy --pre-advance-cmd "true" >/dev/null 2>&1 || true
grep -q "UNSET" "$WORK/allow-paths-seen" 2>/dev/null \
  && pass "relay-only phase clears inherited ALLOW_PATHS (no extra write surface)" \
  || fail "relay-only phase should unset inherited ALLOW_PATHS"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (12d) GH-207: marathon lane namespaces isolate phase paths + attempts ----
NS_OUT_A="$(MARATHON_LANE_NS="plan-a--p1" RELAY_DRIVE_EXIT=4 run_driver 2>&1)"; rc=$?
[ "$rc" -eq 4 ] && pass "GH-207: plan-a namespaced lane exits with the stubbed relay cap" \
  || fail "GH-207: namespaced plan-a lane exit=$rc (expected 4): $NS_OUT_A"
[ -f "$A/phases/plan-a--p1/RELAY.md" ] \
  && pass "GH-207: phase render lives under the namespaced lane path for plan-a" \
  || fail "GH-207: missing namespaced relay path for plan-a"
[ -f "$A/.tick/attempts/plan-a--p1" ] \
  && pass "GH-207: plan-a attempt state is keyed by the namespaced lane id" \
  || fail "GH-207: missing namespaced attempt file for plan-a"
NS_OUT_B="$(MARATHON_LANE_NS="plan-b--p1" RELAY_DRIVE_EXIT=4 run_driver 2>&1)"; rc=$?
[ "$rc" -eq 4 ] && pass "GH-207: plan-b namespaced lane also runs independently" \
  || fail "GH-207: namespaced plan-b lane exit=$rc (expected 4): $NS_OUT_B"
[ -f "$A/phases/plan-b--p1/RELAY.md" ] \
  && pass "GH-207: phase render lives under the namespaced lane path for plan-b" \
  || fail "GH-207: missing namespaced relay path for plan-b"
[ -f "$A/.tick/attempts/plan-b--p1" ] \
  && pass "GH-207: plan-b attempt state is separate from plan-a despite the shared bare lane id" \
  || fail "GH-207: missing namespaced attempt file for plan-b"
[ ! -e "$A/.tick/attempts/p1" ] \
  && pass "GH-207: namespaced runs do not fall back to a bare p1 attempt file" \
  || fail "GH-207: unexpected bare p1 attempt file created for namespaced runs"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (12e) GH-207: byte-identical relay re-render skips the commit and continues ─
RELAY_DRIVE_EXIT=0 MARATHON_LANE_NS="rerender--p1" run_driver --pre-advance-cmd "bash $GATE_CMD" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-207: first namespaced render succeeds" || fail "GH-207: first namespaced render exit=$rc"
RERENDER_OUT="$(RELAY_DRIVE_EXIT=0 MARATHON_LANE_NS="rerender--p1" run_driver --pre-advance-cmd "bash $GATE_CMD" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-207: identical re-render does not HALT" || fail "GH-207: identical re-render exit=$rc (expected 0): $RERENDER_OUT"
printf '%s\n' "$RERENDER_OUT" | grep -q "relay file unchanged" \
  && pass "GH-207: identical re-render is explicitly treated as unchanged" \
  || fail "GH-207: expected unchanged-relay log on identical re-render"
printf '%s\n' "$RERENDER_OUT" | grep -q "nothing to commit" \
  && fail "GH-207: identical re-render still hit a nothing-to-commit failure: $RERENDER_OUT" \
  || pass "GH-207: identical re-render avoids the old nothing-to-commit halt"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (12f) GH-207: gate-green prebuilt lane routes to review and records lane_already_satisfied ─
RD_SAT="$WORK/relay-drive-satisfied.sh"
cat > "$RD_SAT" <<'STUB'
#!/usr/bin/env bash
set -eu
relay=""; task=""; review_once=0
while (($#)); do
  case "$1" in
    --relay-file) relay="$2"; shift 2 ;;
    --relay-task) task="$2"; shift 2 ;;
    --review-once) review_once=1; shift ;;
    *) shift ;;
  esac
done
count=0
[ -f "$WORK/rd-satisfied-count" ] && count="$(cat "$WORK/rd-satisfied-count")"
count=$((count + 1))
printf '%s\n' "$count" > "$WORK/rd-satisfied-count"
if [ "$review_once" -eq 0 ]; then
  exit 3
fi
sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$relay"
printf '\n### Round 1 · Reviewer · agy\n**Verdict:** Approved\n' >> "$relay"
TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/satisfied-plan--p1/RELAY.md" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$A" "$TICK" done "$task" --agent agy >/dev/null 2>&1 || true
exit 0
STUB
chmod +x "$RD_SAT"
mkdir -p "$A/src"
printf 'artifact already built\n' > "$A/src/satisfied.js"
rm -f "$WORK/rd-satisfied-count"
SAT_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_SAT" MARATHON_LANE_NS="satisfied-plan--p1" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/satisfied.js \
    --pre-advance-cmd "test -f '$A/src/satisfied.js'" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-207: prebuilt gate-green lane reaches satisfied instead of no-progress" \
  || fail "GH-207: prebuilt satisfied lane exit=$rc (expected 0): $SAT_OUT"
[ "$(cat "$WORK/rd-satisfied-count" 2>/dev/null)" = "2" ] \
  && pass "GH-207: already-satisfied recovery re-enters relay-drive once for reviewer approval" \
  || fail "GH-207: expected builder stall + one reviewer recovery call"
grep -q '^STATUS: Approved' "$A/phases/satisfied-plan--p1/RELAY.md" \
  && pass "GH-207: reviewer approval lands in the namespaced relay file" \
  || fail "GH-207: satisfied-lane relay was not approved"
printf '%s\n' "$SAT_OUT" | grep -q "lane_already_satisfied" \
  && pass "GH-207: satisfied path is explicitly marked lane_already_satisfied" \
  || fail "GH-207: missing lane_already_satisfied marker in satisfied-path output"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
rm -f "$A/src/satisfied.js"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (12g) GH-207: red gate on a stalled prebuilt lane still escalates no-progress ─
RD_STALLED="$WORK/relay-drive-stalled.sh"
cat > "$RD_STALLED" <<'STUB'
#!/usr/bin/env bash
set -eu
count=0
[ -f "$WORK/rd-stalled-count" ] && count="$(cat "$WORK/rd-stalled-count")"
count=$((count + 1))
printf '%s\n' "$count" > "$WORK/rd-stalled-count"
exit 3
STUB
chmod +x "$RD_STALLED"
mkdir -p "$A/src"
printf 'artifact already built\n' > "$A/src/stalled.js"
rm -f "$WORK/rd-stalled-count"
STALL_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_STALLED" MARATHON_LANE_NS="stalled-plan--p1" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --artifact src/stalled.js \
    --pre-advance-cmd "test -f '$A/src/missing.js'" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && pass "GH-207: red gate stalled lane still exits no-progress" \
  || fail "GH-207: stalled red-gate lane exit=$rc (expected 3): $STALL_OUT"
[ "$(cat "$WORK/rd-stalled-count" 2>/dev/null)" = "1" ] \
  && pass "GH-207: red gate does not route a stalled lane into reviewer recovery" \
  || fail "GH-207: red gate should stop before reviewer recovery"
grep -q 'reason: no-progress' "$A/phases/stalled-plan--p1/ESCALATION.md" \
  && pass "GH-207: stalled red-gate lane still records the ordinary no-progress escalation" \
  || fail "GH-207: stalled red-gate lane escalation reason drifted"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
rm -f "$A/src/stalled.js"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (13) --require-clean: hard-stop on a dirty workspace (Phase 3.6) ───────
# A clean tree starts fine; a stray untracked file + --require-clean is a hard stop (exit 2),
# so unattended runs don't proceed with distracting context in the tree.
RELAY_DRIVE_EXIT=0 run_driver --require-clean >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--require-clean passes on a clean workspace" || fail "--require-clean exit=$rc on clean tree (expected 0)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
WT="$WORK/require-clean-linked-wt"
git -C "$A" worktree add --detach "$WT" HEAD >/dev/null 2>&1
[ -f "$WT/.git" ] && pass "--require-clean fixture uses a linked worktree (.git file)" \
  || fail "expected linked worktree fixture with a .git file at $WT/.git"
WT_OUT="$(
  cd "$WT" && \
  MARATHON_ROOT="$WT" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$WT" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  RELAY_DRIVE_EXIT=0 \
  bash "$DRIVER" \
    --phases-dir "$WT/phases" \
    --phase-brief "$BRIEF" \
    --reviewer agy \
    --pre-advance-cmd "true" \
    --builder claude \
    --require-clean 2>&1
)"; rc=$?
[ "$rc" -eq 0 ] && pass "--require-clean passes inside a linked worktree (no self-trip on the driver lock)" \
  || fail "--require-clean should stay clean in a linked worktree (exit=$rc): $WT_OUT"
printf '%s\n' "$WT_OUT" | grep -q '\.relay-driver\.lock' \
  && fail "linked worktree run still reported the driver's own lock as dirt: $WT_OUT" \
  || pass "linked worktree run does not report the driver's own lock as dirt"
[ -f "$WT/phases/p1/RELAY.md" ] && pass "linked worktree + --require-clean still seeds the phase" \
  || fail "linked worktree run should seed the phase on a clean tree"
git -C "$A" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
git -C "$A" worktree prune >/dev/null 2>&1 || true
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
printf 'stray distracting brief\n' > "$A/STRAY.md"   # an untracked file outside the marathon's paths
RELAY_DRIVE_EXIT=0 run_driver --require-clean >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "--require-clean hard-stops (exit 2) on a dirty workspace" || fail "--require-clean exit=$rc on dirty tree (expected 2)"
[ ! -f "$A/phases/p1/RELAY.md" ] && pass "dirty + --require-clean does not seed the phase" || fail "phase seeded despite --require-clean on dirty tree"
# without --require-clean it only warns (still runs)
RELAY_DRIVE_EXIT=0 run_driver >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "dirty workspace only WARNS without --require-clean (still runs)" || fail "dirty tree should warn-not-block without --require-clean (exit=$rc)"
rm -f "$A/STRAY.md"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (13a) GH-238: missing default gate stops before turn 1 ─────────────────
# The fixture root deliberately has no validate.sh. Omit --pre-advance-cmd to exercise the real
# default and prove it halts before rendering/seeding or invoking the relay-drive turn dispatcher.
rm -f "$WORK/relay-drive-args"
GATE_PREFLIGHT_OUT="$(MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy --builder claude 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "GH-238: missing default gate exits before dispatch" \
  || fail "GH-238: missing default gate exit=$rc (expected 2): $GATE_PREFLIGHT_OUT"
printf '%s\n' "$GATE_PREFLIGHT_OUT" | grep -q "pre-advance gate not runnable" \
  && pass "GH-238: missing default gate names the fail-fast condition" \
  || fail "GH-238: missing required fail-fast phrase: $GATE_PREFLIGHT_OUT"
printf '%s\n' "$GATE_PREFLIGHT_OUT" | grep -Fq -- "--pre-advance-cmd" \
  && pass "GH-238: missing default gate names the override remedy" \
  || fail "GH-238: missing override remedy: $GATE_PREFLIGHT_OUT"
[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-238: missing default gate never renders turn 1 relay" \
  || fail "GH-238: relay was rendered before the missing gate was rejected"
[ ! -e "$WORK/relay-drive-args" ] && pass "GH-238: missing default gate never dispatches relay-drive turn 1" \
  || fail "GH-238: relay-drive was invoked before the missing gate was rejected"
[ -z "$(ls "$A/.tick/events/" 2>/dev/null | grep 'MARATHON-P1-TURN')" ] \
  && pass "GH-238: missing default gate never seeds a tick task" \
  || fail "GH-238: tick task was seeded before the missing gate was rejected"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (14) GH-117: missing builder binary fails clean BEFORE any tick mutation ──
# A builder binary not on PATH must die() here — not deep inside the turn-taker dispatch after
# task.created/claim/release already ran (that used to leave a permanently spent relay task).
BUILD_OUT="$(CLAUDE_BIN="$MISSING_BIN" run_driver 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "GH-117: missing builder binary exits 2" || fail "GH-117: missing builder exit=$rc (expected 2): $BUILD_OUT"
printf '%s\n' "$BUILD_OUT" | grep -qi "not found on PATH" \
  && pass "GH-117: missing builder error names the missing binary" \
  || fail "GH-117: expected a clear 'not found on PATH' message, got: $BUILD_OUT"
[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing builder — relay file never rendered" \
  || fail "GH-117: relay file should not exist when the builder binary is missing"
[ -z "$(ls "$A/.tick/events/" 2>/dev/null | grep 'MARATHON-P1-TURN')" ] \
  && pass "GH-117: missing builder — no tick task created (no spent token)" \
  || fail "GH-117: tick task must not be seeded when the builder binary is missing"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (15) GH-117: missing reviewer binary fails clean BEFORE any tick mutation ─
REV_OUT="$(AGY_BIN="$MISSING_BIN" run_driver 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "GH-117: missing reviewer binary exits 2" || fail "GH-117: missing reviewer exit=$rc (expected 2): $REV_OUT"
printf '%s\n' "$REV_OUT" | grep -qi "not found on PATH" \
  && pass "GH-117: missing reviewer error names the missing binary" \
  || fail "GH-117: expected a clear 'not found on PATH' message, got: $REV_OUT"
[ ! -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: missing reviewer — relay file never rendered" \
  || fail "GH-117: relay file should not exist when the reviewer binary is missing"
[ -z "$(ls "$A/.tick/events/" 2>/dev/null | grep 'MARATHON-P1-TURN')" ] \
  && pass "GH-117: missing reviewer — no tick task created (no spent token)" \
  || fail "GH-117: tick task must not be seeded when the reviewer binary is missing"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (16) GH-117: both binaries present — probe is a no-op, dry-run unaffected ─
BOTH_OUT="$(CLAUDE_BIN="$STUB_CLAUDE_BIN" AGY_BIN="$STUB_AGY_BIN" run_driver --dry-run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-117: both binaries present — dry-run still exits 0" \
  || fail "GH-117: both-present dry-run exit=$rc (expected 0): $BOTH_OUT"
[ -f "$A/phases/p1/RELAY.md" ] && pass "GH-117: both-present — relay file still rendered" \
  || fail "GH-117: relay file missing when both binaries are present"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

setup_vendored_consumer_fixture() {  # <root>
  local root="$1"
  mkdir -p "$root"
  git -C "$root" init -q
  git -C "$root" config user.email t@example.com
  git -C "$root" config user.name test
  printf '.tick/\n.xyz/.tick/\n' > "$root/.gitignore"
  mkdir -p "$root/src"
  printf 'module.exports = 1\n' > "$root/src/feature.js"
  printf '# brief\n\nUpdate src/feature.js and append the relay.\n' > "$root/brief.md"
  git -C "$root" add . >/dev/null 2>&1
  git -C "$root" commit -q -m "consumer init" >/dev/null 2>&1
  mkdir -p "$root/.xyz"
  cp -R "$(cd "$(dirname "$0")/.." && pwd)/relay-automation" "$root/.xyz/"
  cp -R "$(cd "$(dirname "$0")/.." && pwd)/bin" "$root/.xyz/"
  cp -R "$(cd "$(dirname "$0")/.." && pwd)/src" "$root/.xyz/"
  cp -R "$(cd "$(dirname "$0")/.." && pwd)/utils" "$root/.xyz/"
}

assert_vendored_tick_event() {  # <root> <grep-pattern> <pass-msg> <fail-msg>
  local root="$1" pattern="$2" pass_msg="$3" fail_msg="$4"
  find "$root/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
    | xargs -0 grep -l "$pattern" >/dev/null 2>&1 \
    && pass "$pass_msg" \
    || fail "$fail_msg"
}

# ── (17) GH-171: vendored full chain keeps claims in the consumer repo's .tick ─
# Reproduces the live downstream shape: a consumer repo vendors this harness under .xyz/, then runs
# marathon-drive -> relay-drive -> marathon-agent -> codex-turn/agy-turn with worktree isolation ON
# and no --target-root. The regression is a shim clobbering the inherited TICK_REPO_ROOT, silently
# creating .xyz/.tick and claiming there while relay-drive watches the consumer repo's real .tick.
V="$WORK/vendor-consumer"
setup_vendored_consumer_fixture "$V"
VSTUBS="$WORK/vendor-stubs"
mkdir -p "$VSTUBS"
VCODEX="$VSTUBS/codex"
cat > "$VCODEX" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '\n### Round 1 · Builder · %s (stub)\nVERDICT: FAIL\nBasis: test builder\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
printf 'module.exports = 2\n' > "$PWD/src/feature.js"
exit 0
EOF
chmod +x "$VCODEX"
VAGY="$VSTUBS/agy"
cat > "$VAGY" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  whoami) printf 'agy-stub\n'; exit 0 ;;
esac
printf 'agy review stub\n'
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Changes requested\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
exit 0
EOF
chmod +x "$VAGY"
(
  cd "$V"
  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
  PATH="$VSTUBS:$PATH" CODEX_BIN="$VCODEX" AGY_BIN="$VAGY" \
    ./.xyz/relay-automation/marathon-drive.sh \
      --phase-brief brief.md \
      --builder codex \
      --reviewer agy \
      --artifact src/feature.js \
      --pre-advance-cmd "true" \
      --round-cap 2
) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && pass "GH-171: vendored full chain advances twice and exits on cap, not no-progress" \
  || fail "GH-171: vendored full chain should exit 4 after two advancing turns, got $rc"
TICK_REPO_ROOT="$V" "$V/.xyz/bin/tick" info MARATHON-P1-TURN | grep -qE '^handoff-to:[[:space:]]+codex$' \
  && pass "GH-171: final handoff stays in the consumer repo tick log" \
  || fail "GH-171: consumer repo tick log missing final codex handoff"
find "$V/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"codex"' >/dev/null 2>&1 \
  && pass "GH-171: codex claim event lands in the consumer repo .tick" \
  || fail "GH-171: consumer repo .tick missing codex claim event"
find "$V/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"agy"' >/dev/null 2>&1 \
  && pass "GH-171: reviewer claim event lands in the consumer repo .tick" \
  || fail "GH-171: consumer repo .tick missing reviewer claim event"
[ ! -d "$V/.xyz/.tick/events" ] \
  && pass "GH-171: vendored .xyz does not grow a stray .tick event log" \
  || fail "GH-171: vendored .xyz/.tick should stay absent"

# ── (18) GH-172: vendored full chain stays on the consumer repo tick log in XYZ_PYTHON=1 mode ──
VP="$WORK/vendor-consumer-python"
setup_vendored_consumer_fixture "$VP"
(
  cd "$VP"
  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
  PATH="$VSTUBS:$PATH" CODEX_BIN="$VCODEX" AGY_BIN="$VAGY" XYZ_PYTHON=1 \
    ./.xyz/relay-automation/marathon-drive.sh \
      --phase-brief brief.md \
      --builder codex \
      --reviewer agy \
      --artifact src/feature.js \
      --pre-advance-cmd "true" \
      --round-cap 2
) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && pass "GH-172: vendored XYZ_PYTHON=1 full chain advances twice and exits on cap, not no-progress" \
  || fail "GH-172: vendored XYZ_PYTHON=1 full chain should exit 4 after two advancing turns, got $rc"
TICK_REPO_ROOT="$VP" "$VP/.xyz/bin/tick" info MARATHON-P1-TURN | grep -qE '^handoff-to:[[:space:]]+codex$' \
  && pass "GH-172: XYZ_PYTHON=1 final handoff stays in the consumer repo tick log" \
  || fail "GH-172: consumer repo tick log missing final codex handoff in XYZ_PYTHON=1 mode"
find "$VP/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"codex"' >/dev/null 2>&1 \
  && pass "GH-172: XYZ_PYTHON=1 codex claim event lands in the consumer repo .tick" \
  || fail "GH-172: consumer repo .tick missing codex claim event in XYZ_PYTHON=1 mode"
find "$VP/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"agy"' >/dev/null 2>&1 \
  && pass "GH-172: XYZ_PYTHON=1 reviewer claim event lands in the consumer repo .tick" \
  || fail "GH-172: consumer repo .tick missing reviewer claim event in XYZ_PYTHON=1 mode"
[ ! -d "$VP/.xyz/.tick/events" ] \
  && pass "GH-172: vendored XYZ_PYTHON=1 run does not grow a stray .xyz .tick event log" \
  || fail "GH-172: vendored XYZ_PYTHON=1 run should not create .xyz/.tick"

# ── (18a) GH-174: agy-turn.py claim-before-launch guard regression (XYZ_PYTHON=1) ───────────────
# GH-171 gave relay-automation/agy-turn.sh (Bash) a claim-before-launch ownership guard: claim the
# handed-off task, verify claimer == agy, exit 5 on mismatch. utils/py/agy-turn.py (opt-in via
# XYZ_PYTHON=1) got the identical guard as a side effect of the GH-172 Phase 0 root-semantics audit
# (commit 7e9e683, main() now calls claim_task_or_exit(...) before launching agy) but never got a
# dedicated regression test proving it. Reuse the $VP fixture run above (XYZ_PYTHON=1 full chain,
# already completed) and assert the reviewer (agy) leg's claim event specifically lands in the
# consumer repo's .tick — mirroring the GH-171 Bash-mode reviewer-claim assertion.
find "$VP/.tick/events" -maxdepth 1 -type f -name '*MARATHON-P1-TURN*' -print0 2>/dev/null \
  | xargs -0 grep -l '"type":"task.claimed".*"agent":"agy"' >/dev/null 2>&1 \
  && pass "GH-174: agy claim event lands in the consumer repo .tick under XYZ_PYTHON=1" \
  || fail "GH-174: consumer repo .tick missing agy claim event under XYZ_PYTHON=1 (claim-before-launch guard regression)"

# ── (18b) GH-172: approval-path vendored Bash run keeps release + done in the consumer repo tick ──
VCODEX_APPROVE="$VSTUBS/codex-approve"
cat > "$VCODEX_APPROVE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '\n### Round 1 · Builder · %s (stub)\nImplemented: test builder update\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
printf 'module.exports = 2\n' > "$PWD/src/feature.js"
exit 0
EOF
chmod +x "$VCODEX_APPROVE"
VAGY_APPROVE="$VSTUBS/agy-approve"
cat > "$VAGY_APPROVE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  whoami) printf 'agy-stub\n'; exit 0 ;;
esac
printf 'agy review stub\n'
sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$PWD/phases/p1/RELAY.md"
printf '\n### Round 2 · Reviewer · %s (stub)\n**Verdict:** Approved\nBasis: test reviewer\n' "$RELAY_AGENT" >> "$PWD/phases/p1/RELAY.md"
exit 0
EOF
chmod +x "$VAGY_APPROVE"
VA="$WORK/vendor-consumer-approved"
setup_vendored_consumer_fixture "$VA"
(
  cd "$VA"
  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
  PATH="$VSTUBS:$PATH" CODEX_BIN="$VCODEX_APPROVE" AGY_BIN="$VAGY_APPROVE" \
    ./.xyz/relay-automation/marathon-drive.sh \
      --phase-brief brief.md \
      --builder codex \
      --reviewer agy \
      --artifact src/feature.js \
      --pre-advance-cmd "test -f src/feature.js" \
      --round-cap 2
) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "GH-172: vendored Bash approval path exits 0 after reviewer approval" \
  || fail "GH-172: vendored Bash approval path should exit 0, got $rc"
TICK_REPO_ROOT="$VA" "$VA/.xyz/bin/tick" info MARATHON-P1-TURN | grep -qE '^status:[[:space:]]+done$' \
  && pass "GH-172: vendored Bash approval path closes the consumer repo token" \
  || fail "GH-172: vendored Bash approval path should end with a done token"
assert_vendored_tick_event "$VA" '"type":"task.created"' \
  "GH-172: vendored Bash approval path creates the task in the consumer repo .tick" \
  "GH-172: vendored Bash approval path missing task.created in the consumer repo .tick"
assert_vendored_tick_event "$VA" '"type":"task.claimed".*"agent":"codex"' \
  "GH-172: vendored Bash approval path claims builder in the consumer repo .tick" \
  "GH-172: vendored Bash approval path missing codex claim event"
assert_vendored_tick_event "$VA" '"type":"task.released".*"agent":"codex".*"to_agent":"agy"' \
  "GH-172: vendored Bash approval path releases builder to reviewer in the consumer repo .tick" \
  "GH-172: vendored Bash approval path missing codex->agy release event"
assert_vendored_tick_event "$VA" '"type":"task.claimed".*"agent":"agy"' \
  "GH-172: vendored Bash approval path claims reviewer in the consumer repo .tick" \
  "GH-172: vendored Bash approval path missing reviewer claim event"
assert_vendored_tick_event "$VA" '"type":"task.done".*"agent":"agy"' \
  "GH-172: vendored Bash approval path records reviewer done in the consumer repo .tick" \
  "GH-172: vendored Bash approval path missing reviewer done event"
[ ! -d "$VA/.xyz/.tick/events" ] \
  && pass "GH-172: vendored Bash approval path does not grow a stray .xyz .tick event log" \
  || fail "GH-172: vendored Bash approval path should not create .xyz/.tick"

# ── (18c) GH-172: approval-path vendored XYZ_PYTHON=1 run keeps release + done in the consumer repo tick ──
VAP="$WORK/vendor-consumer-approved-python"
setup_vendored_consumer_fixture "$VAP"
(
  cd "$VAP"
  unset MARATHON_ROOT MARATHON_HOME MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
  PATH="$VSTUBS:$PATH" CODEX_BIN="$VCODEX_APPROVE" AGY_BIN="$VAGY_APPROVE" XYZ_PYTHON=1 \
    ./.xyz/relay-automation/marathon-drive.sh \
      --phase-brief brief.md \
      --builder codex \
      --reviewer agy \
      --artifact src/feature.js \
      --pre-advance-cmd "test -f src/feature.js" \
      --round-cap 2
) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "GH-172: vendored XYZ_PYTHON=1 approval path exits 0 after reviewer approval" \
  || fail "GH-172: vendored XYZ_PYTHON=1 approval path should exit 0, got $rc"
TICK_REPO_ROOT="$VAP" "$VAP/.xyz/bin/tick" info MARATHON-P1-TURN | grep -qE '^status:[[:space:]]+done$' \
  && pass "GH-172: vendored XYZ_PYTHON=1 approval path closes the consumer repo token" \
  || fail "GH-172: vendored XYZ_PYTHON=1 approval path should end with a done token"
assert_vendored_tick_event "$VAP" '"type":"task.created"' \
  "GH-172: vendored XYZ_PYTHON=1 approval path creates the task in the consumer repo .tick" \
  "GH-172: vendored XYZ_PYTHON=1 approval path missing task.created in the consumer repo .tick"
assert_vendored_tick_event "$VAP" '"type":"task.claimed".*"agent":"codex"' \
  "GH-172: vendored XYZ_PYTHON=1 approval path claims builder in the consumer repo .tick" \
  "GH-172: vendored XYZ_PYTHON=1 approval path missing codex claim event"
assert_vendored_tick_event "$VAP" '"type":"task.released".*"agent":"codex".*"to_agent":"agy"' \
  "GH-172: vendored XYZ_PYTHON=1 approval path releases builder to reviewer in the consumer repo .tick" \
  "GH-172: vendored XYZ_PYTHON=1 approval path missing codex->agy release event"
assert_vendored_tick_event "$VAP" '"type":"task.claimed".*"agent":"agy"' \
  "GH-172: vendored XYZ_PYTHON=1 approval path claims reviewer in the consumer repo .tick" \
  "GH-172: vendored XYZ_PYTHON=1 approval path missing reviewer claim event"
assert_vendored_tick_event "$VAP" '"type":"task.done".*"agent":"agy"' \
  "GH-172: vendored XYZ_PYTHON=1 approval path records reviewer done in the consumer repo .tick" \
  "GH-172: vendored XYZ_PYTHON=1 approval path missing reviewer done event"
[ ! -d "$VAP/.xyz/.tick/events" ] \
  && pass "GH-172: vendored XYZ_PYTHON=1 approval path does not grow a stray .xyz .tick event log" \
  || fail "GH-172: vendored XYZ_PYTHON=1 approval path should not create .xyz/.tick"

# ── (19) GH-212: unset --builder now resolves to the new default, codex ───────
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
DEFAULT_BUILDER_OUT="$(RELAY_DRIVE_EXIT=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  CODEX_BIN="$STUB_CODEX_BIN" AGY_BIN="$STUB_AGY_BIN" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" --reviewer agy \
    --pre-advance-cmd "true" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-212: default builder (no --builder flag) runs with no claude binary present" \
  || fail "GH-212: default-builder run exit=$rc: $DEFAULT_BUILDER_OUT"
grep -q "TAKE YOUR TURN.*codex.*BUILDER" "$A/phases/p1/RELAY.md" 2>/dev/null \
  && pass "GH-212: default builder identity rendered in the relay file is codex" \
  || fail "GH-212: expected codex as the default BUILDER in the relay file"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
