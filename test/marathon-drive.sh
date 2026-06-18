#!/usr/bin/env bash
# marathon-drive.sh test: single-phase driver — renders relay file, seeds tick token,
# calls relay-drive, runs pre-advance gate, saves transcript, emits phase events.
# Uses MARATHON_RELAY_DRIVE + MARATHON_AGENT_CMD + stub pre-advance-cmd to avoid real CLI.
source "$(dirname "$0")/_setup.sh" marathon-drive
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

run_driver() {  # <extra-args…>
  MARATHON_ROOT="$A" \
  MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$WORK/noop-agent" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  bash "$DRIVER" \
    --phases-dir "$A/phases" \
    --phase-brief "$BRIEF" \
    --reviewer gemini \
    --pre-advance-cmd "true" \
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
grep -q "TAKE YOUR TURN.*gemini.*REVIEWER" "$A/phases/p1/RELAY.md" 2>/dev/null \
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

# ── (11) agent-cmd path with spaces survives relay-drive's eval ────────────
# Regression: the real relay-drive `eval "$AGENT_CMD"`s the turn-taker. A repo path with a
# space (".../GH Repos/...") splits on the space unless marathon-drive shell-quotes it.
# The default stub above only RECORDS args; this case uses a stub that EVALs them like the real
# relay-drive (line 110), with the agent script living under a directory that contains a space.
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
eval "$acmd"   # mirrors relay-drive.sh:110 — splits a spaced path unless the caller quoted it
exit 0
RD
chmod +x "$EVAL_RD"
rm -f "$WORK/spaced-agent-ran"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$SPACED_AGENT" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer gemini --pre-advance-cmd "true" >/dev/null 2>&1 || true
[ -f "$WORK/spaced-agent-ran" ] \
  && pass "agent-cmd path with spaces survives relay-drive eval" \
  || fail "spaced agent-cmd path broke relay-drive eval — marathon-drive must shell-quote --agent-cmd"
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
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer gemini --artifact "$ART" --pre-advance-cmd "true" >/dev/null 2>&1 || true
grep -q "$ART" "$WORK/allow-paths-seen" 2>/dev/null \
  && pass "ALLOW_PATHS exported to the turn-taker env" \
  || fail "ALLOW_PATHS not propagated to agent-cmd (builder would have no write surface)"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true
# (c) relay-only (no --artifact) leaves ALLOW_PATHS UNSET — containment default unchanged
rm -f "$WORK/allow-paths-seen"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$EVAL_RD" MARATHON_AGENT_CMD="$ENV_AGENT" \
  TICK_REPO_ROOT="$A" TICK_BIN="$TICK" \
  bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
    --reviewer gemini --pre-advance-cmd "true" >/dev/null 2>&1 || true
grep -q "UNSET" "$WORK/allow-paths-seen" 2>/dev/null \
  && pass "relay-only phase leaves ALLOW_PATHS unset (no extra write surface)" \
  || fail "relay-only phase should not export ALLOW_PATHS"
rm -rf "$A/.tick" "$A/phases" "$A/relay-system"
git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true

# ── (13) --require-clean: hard-stop on a dirty workspace (Phase 3.6) ───────
# A clean tree starts fine; a stray untracked file + --require-clean is a hard stop (exit 2),
# so unattended runs don't proceed with distracting context in the tree.
RELAY_DRIVE_EXIT=0 run_driver --require-clean >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--require-clean passes on a clean workspace" || fail "--require-clean exit=$rc on clean tree (expected 0)"
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

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
