#!/usr/bin/env bash
# GH-609: Address Edge-Case SDLC Gaps in Autonomous Agent Workflows
# Unified, shared contract validators and adversarial mutation controls for:
# - workhorse (durable identity, 4-state recovery, local/remote stale-writer fence, preservation split, semantic verification)
# - start-task (resume reconciliation, transport drop handling)
# - swe (expand-contract 6-stage lifecycle, continuous sync, convergence, 4-gate contraction)
# - recon (lane-scoped mapping of active readers/writers in B, async queues/delayed consumers in C, tripwires in D)
# - ci-optimize (Principle 13 bounded stress + active quarantine with UTC expiry, Principle 14 workload-scoped performance fences)
# - ci-debug (strictly ordered 4-tier containment ladder preserving worktree safety)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh609-sdlc-agent-gaps.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh609-sdlc-agent-gaps =="

# -----------------------------------------------------------------------------
# 1. Non-Empty File Size Guards
# -----------------------------------------------------------------------------
FILES=(
  "skills/workhorse/SKILL.md"
  "skills/start-task/SKILL.md"
  "skills/swe/SKILL.md"
  "skills/recon/SKILL.md"
  "skills/ci-optimize/SKILL.md"
  "skills/ci-debug/SKILL.md"
)

for f in "${FILES[@]}"; do
  full_path="$ROOT/$f"
  if [ ! -s "$full_path" ]; then
    fail "Target skill file is missing or empty (0 bytes): $f"
  else
    pass "File size non-empty guard: $f ($(wc -c < "$full_path" | tr -d ' ') bytes)"
  fi
done

# -----------------------------------------------------------------------------
# 2. Unified Parameterized Contract Checkers
# -----------------------------------------------------------------------------

check_workhorse_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  # Durable operation identity tuple
  grep -q "operation_id, target_arn_or_url, request_fingerprint, idempotency_key" "$target" || return 1
  
  # 4-state reconciliation evaluation & deadline cap
  grep -q "Confirmed Success" "$target" || return 1
  grep -q "Authoritative Non-Execution" "$target" || return 1
  grep -q "original idempotency key and unchanged request fingerprint" "$target" || return 1
  grep -q "Pending / In-Flight" "$target" || return 1
  grep -q "Unknown / Unavailable Lookup / Expired Deduplication / Deadline Exhausted" "$target" || return 1
  grep -q "STOP and escalate to human decision" "$target" || return 1
  grep -q "total reconciliation deadline / attempt cap" "$target" || return 1
  
  # Stale-writer fence: local PID scoping vs remote monotonic fencing tokens
  grep -q "Local process liveness checks" "$target" || return 1
  grep -q "whose complete write lifetime is demonstrably local" "$target" || return 1
  grep -q "target-enforced monotonic fencing tokens" "$target" || return 1
  grep -q "generation numbers that reject stale writers" "$target" || return 1
  
  # Preservation split: costly tested rollback vs one-way door permanent loss & confirmation
  grep -q "Costly Operations" "$target" || return 1
  grep -q "tested rollback and restoration procedure" "$target" || return 1
  grep -q "what intervening writes restoration would lose" "$target" || return 1
  grep -q "One-Way Doors" "$target" || return 1
  grep -q "exact permanent loss" "$target" || return 1
  grep -q "fresh, operation-specific operator confirmation" "$target" || return 1
  grep -q "Never claim impossible rollback proofs" "$target" || return 1
  
  # Semantic post-mutation verification
  grep -q "Verify (Semantic Post-Mutation Verification):" "$target" || return 1
  grep -q "Verify semantic data content, schema integrity, and state invariants, not merely process exit code" "$target" || return 1
  
  # Operational containment reference
  grep -q "ci-debug" "$target" || return 1
  grep -q "Provider-level Revocation/Rotation" "$target" || return 1
  return 0
}

check_start_task_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  # Step 3 resume reconciliation against remote PR and live HEAD
  grep -q "Resume Reconciliation Protocol:" "$target" || return 1
  grep -q "gh pr list --head <branch>" "$target" || return 1
  grep -q "live HEAD commit" "$target" || return 1
  
  # Step 7/9 transport drop handling
  grep -q "ascertain remote execution state before re-dispatching" "$target" || return 1
  grep -q "query \`gh pr list --head <branch>\` to verify whether the PR was registered" "$target" || return 1
  return 0
}

check_swe_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  grep -q "Zero-Downtime Expand-Contract Schema & State Migration Rubric" "$target" || return 1
  grep -q "Stage 1 — Expand:" "$target" || return 1
  grep -q "concurrent write synchronization" "$target" || return 1
  grep -q "Stage 2 — Backfill & Continuous Sync:" "$target" || return 1
  grep -q "conflict/ordering strategy" "$target" || return 1
  grep -q "Stage 3 — Convergence Gate:" "$target" || return 1
  grep -q "parity/reconciliation assertion verifying data convergence" "$target" || return 1
  grep -q "Stage 4 — Switch Reads:" "$target" || return 1
  grep -q "graceful fallback" "$target" || return 1
  grep -q "Stage 5 — Dual-Write & Mixed-Version Support:" "$target" || return 1
  grep -q "bidirectional synchronization" "$target" || return 1
  grep -q "throughout the entire mixed-version window" "$target" || return 1
  grep -q "Stage 6 — Contract & Retire:" "$target" || return 1
  grep -q "Full retirement and migration of all legacy writers" "$target" || return 1
  grep -q "Full retirement of all legacy readers" "$target" || return 1
  grep -q "Full retirement of delayed, queued, or asynchronous consumers" "$target" || return 1
  grep -q "Closure of the application rollback window" "$target" || return 1
  return 0
}

check_recon_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  # Scoped lane checks: verify that the mappings are in the respective Lane rows
  grep -E "^\| \*\*B\. State & data\*\*.*active readers and writers.*schema" "$target" >/dev/null || return 1
  grep -E "^\| \*\*C\. Contracts & boundaries\*\*.*background worker queues, delayed/asynchronous consumers" "$target" >/dev/null || return 1
  grep -E "^\| \*\*D\. Build, failure & operations\*\*.*operational tripwires.*reverse-sync rollback path" "$target" >/dev/null || return 1
  return 0
}

check_ci_optimize_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  # Principle 13: Bounded stress + active quarantine sink
  grep -q "13\. Bounded Flake Stress Loops and Active Quarantine Sinks" "$target" || return 1
  grep -q "100-iteration diagnostic stress loop" "$target" || return 1
  grep -q "capped by a total time/resource budget" "$target" || return 1
  grep -q "Principle 4 (matched base/candidate attribution)" "$target" || return 1
  grep -q "quarantined test requires a named owner, linked tracked issue, explicit UTC expiry date" "$target" || return 1
  grep -q "quarantine sink must continue running and reporting assertions" "$target" || return 1
  
  # Principle 14: Workload-scoped performance fences
  grep -q "14\. Workload-Scoped Performance and Resource Budget Fences" "$target" || return 1
  grep -q "heapsnapshot diffing, memory allocation profiling, and p99 latency thresholds" "$target" || return 1
  grep -q "scoped to representative workloads and critical paths" "$target" || return 1
  return 0
}

check_ci_debug_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  
  grep -q "Operational Containment Protocol (Secrets, Leakage & Incident Response)" "$target" || return 1
  
  # Strict priority order verification (P1 before P2 before P3 before P4)
  local line_p1 line_p2 line_p3 line_p4
  line_p1="$(grep -n "Priority 1 — Provider Revocation & Rotation First:" "$target" | cut -d: -f1 || echo 0)"
  line_p2="$(grep -n "Priority 2 — Blast Radius Audit in Access Logs:" "$target" | cut -d: -f1 || echo 0)"
  line_p3="$(grep -n "Priority 3 — Preserve Sanitized Evidence:" "$target" | cut -d: -f1 || echo 0)"
  line_p4="$(grep -n "Priority 4 — Explicitly Authorized History Scrubbing:" "$target" | cut -d: -f1 || echo 0)"
  
  [ "$line_p1" -gt 0 ] && [ "$line_p2" -gt "$line_p1" ] && [ "$line_p3" -gt "$line_p2" ] && [ "$line_p4" -gt "$line_p3" ] || return 1
  grep -q "WORKTREE-SAFETY.md" "$target" || return 1
  return 0
}

# -----------------------------------------------------------------------------
# 3. Positive Contract Assertions Against In-Tree Documents
# -----------------------------------------------------------------------------

WORKHORSE="$ROOT/skills/workhorse/SKILL.md"
START_TASK="$ROOT/skills/start-task/SKILL.md"
SWE="$ROOT/skills/swe/SKILL.md"
RECON="$ROOT/skills/recon/SKILL.md"
CI_OPT="$ROOT/skills/ci-optimize/SKILL.md"
CI_DEBUG="$ROOT/skills/ci-debug/SKILL.md"

if check_workhorse_contract "$WORKHORSE"; then
  pass "workhorse: satisfies unified contract (durable identity, 4-state recovery, local/remote fence, preservation split, semantic verification)"
else
  fail "workhorse: failed unified contract check"
fi

if check_start_task_contract "$START_TASK"; then
  pass "start-task: satisfies unified contract (resume reconciliation against remote PR and live HEAD, transport drop handling)"
else
  fail "start-task: failed unified contract check"
fi

if check_swe_contract "$SWE"; then
  pass "swe: satisfies unified contract (6-stage expand-contract lifecycle, continuous sync, convergence gate, 4-gate contraction)"
else
  fail "swe: failed unified contract check"
fi

if check_recon_contract "$RECON"; then
  pass "recon: satisfies unified contract (Lane B readers/writers, Lane C async queues/delayed consumers, Lane D tripwires/rollback)"
else
  fail "recon: failed unified contract check"
fi

if check_ci_optimize_contract "$CI_OPT"; then
  pass "ci-optimize: satisfies unified contract (Principle 13 bounded stress + active quarantine with UTC expiry, Principle 14 workload performance fences)"
else
  fail "ci-optimize: failed unified contract check"
fi

if check_ci_debug_contract "$CI_DEBUG"; then
  pass "ci-debug: satisfies unified contract (strictly ordered 4-tier containment ladder preserving worktree safety)"
else
  fail "ci-debug: failed unified contract check"
fi

# -----------------------------------------------------------------------------
# 4. Unmodified Fixture Controls (Proves Validators Accept Valid Contracts)
# -----------------------------------------------------------------------------

cp "$WORKHORSE" "$WORK/workhorse-unmod.md"
cp "$START_TASK" "$WORK/start-task-unmod.md"
cp "$SWE" "$WORK/swe-unmod.md"
cp "$RECON" "$WORK/recon-unmod.md"
cp "$CI_OPT" "$WORK/ci-opt-unmod.md"
cp "$CI_DEBUG" "$WORK/ci-debug-unmod.md"

check_workhorse_contract "$WORK/workhorse-unmod.md" && pass "unmodified fixture control: workhorse validator accepts unmodified copy" || fail "unmodified workhorse fixture failed"
check_start_task_contract "$WORK/start-task-unmod.md" && pass "unmodified fixture control: start-task validator accepts unmodified copy" || fail "unmodified start-task fixture failed"
check_swe_contract "$WORK/swe-unmod.md" && pass "unmodified fixture control: swe validator accepts unmodified copy" || fail "unmodified swe fixture failed"
check_recon_contract "$WORK/recon-unmod.md" && pass "unmodified fixture control: recon validator accepts unmodified copy" || fail "unmodified recon fixture failed"
check_ci_optimize_contract "$WORK/ci-opt-unmod.md" && pass "unmodified fixture control: ci-optimize validator accepts unmodified copy" || fail "unmodified ci-optimize fixture failed"
check_ci_debug_contract "$WORK/ci-debug-unmod.md" && pass "unmodified fixture control: ci-debug validator accepts unmodified copy" || fail "unmodified ci-debug fixture failed"

# -----------------------------------------------------------------------------
# 5. Hermetic Adversarial Negative Controls & Falsification Mutations
# -----------------------------------------------------------------------------

run_mutation_test() {
  local desc="$1"
  local checker="$2"
  local base_file="$3"
  local mut_file="$4"
  local mut_cmd="$5"

  cp "$base_file" "$mut_file"
  bash -c "$mut_cmd"
  
  # 1. Assert the mutation actually changed the file
  if cmp -s "$base_file" "$mut_file"; then
    fail "$desc: mutation command failed to alter fixture"
    return 1
  fi
  
  # 2. Assert the validator rejects the mutated file
  if ! $checker "$mut_file"; then
    pass "$desc: mutated fixture properly rejected (reported RED)"
  else
    fail "$desc: validator passed unexpectedly despite corrupted invariant"
  fi
}

# Mutation 1: Workhorse - Delete 4th state (Unknown/Stop)
run_mutation_test \
  "negative control 1 (workhorse)" \
  "check_workhorse_contract" \
  "$WORKHORSE" \
  "$WORK/mut1-workhorse-no-unknown.md" \
  "sed -i.bak '/Unknown \/ Unavailable Lookup/d' '$WORK/mut1-workhorse-no-unknown.md'"

# Mutation 2: Workhorse - Remove Authoritative Non-Execution idempotency key reuse
run_mutation_test \
  "negative control 2 (workhorse)" \
  "check_workhorse_contract" \
  "$WORKHORSE" \
  "$WORK/mut2-workhorse-no-key-reuse.md" \
  "sed -i.bak 's/original idempotency key and unchanged request fingerprint/a brand new token/g' '$WORK/mut2-workhorse-no-key-reuse.md'"

# Mutation 3: Workhorse - Allow PID check alone to authorize remote replay
run_mutation_test \
  "negative control 3 (workhorse)" \
  "check_workhorse_contract" \
  "$WORKHORSE" \
  "$WORK/mut3-workhorse-bad-pid-fence.md" \
  "sed -i.bak 's/demonstrably local/both local and remote/g' '$WORK/mut3-workhorse-bad-pid-fence.md'"

# Mutation 4: Workhorse - Remove impossible rollback disclaimer from One-Way Doors
run_mutation_test \
  "negative control 4 (workhorse)" \
  "check_workhorse_contract" \
  "$WORKHORSE" \
  "$WORK/mut4-workhorse-no-loss-disclaimer.md" \
  "sed -i.bak '/Never claim impossible rollback proofs/d' '$WORK/mut4-workhorse-no-loss-disclaimer.md'"

# Mutation 5: Workhorse - Remove semantic post-mutation verification in Rung 6
run_mutation_test \
  "negative control 5 (workhorse)" \
  "check_workhorse_contract" \
  "$WORKHORSE" \
  "$WORK/mut5-workhorse-no-semantic-verify.md" \
  "sed -i.bak '/Verify semantic data content, schema integrity/d' '$WORK/mut5-workhorse-no-semantic-verify.md'"

# Mutation 6: Start-Task - Remove remote PR inspection on resume
run_mutation_test \
  "negative control 6 (start-task)" \
  "check_start_task_contract" \
  "$START_TASK" \
  "$WORK/mut6-start-task-no-remote-pr.md" \
  "sed -i.bak 's/gh pr list --head <branch>/git branch/g' '$WORK/mut6-start-task-no-remote-pr.md'"

# Mutation 7: SWE - Remove Stage 5 dual-write / continuous sync during mixed-version window
run_mutation_test \
  "negative control 7 (swe)" \
  "check_swe_contract" \
  "$SWE" \
  "$WORK/mut7-swe-no-dual-write.md" \
  "sed -i.bak '/Stage 5 — Dual-Write/d' '$WORK/mut7-swe-no-dual-write.md'"

# Mutation 8: SWE - Remove rollback window closure gating from Stage 6 contraction
run_mutation_test \
  "negative control 8 (swe)" \
  "check_swe_contract" \
  "$SWE" \
  "$WORK/mut8-swe-no-rollback-closure.md" \
  "sed -i.bak '/Closure of the application rollback window/d' '$WORK/mut8-swe-no-rollback-closure.md'"

# Mutation 9: Recon - Misassign Lane B state/data mapping to Lane A
run_mutation_test \
  "negative control 9 (recon)" \
  "check_recon_contract" \
  "$RECON" \
  "$WORK/mut9-recon-misassigned-lane.md" \
  "sed -i.bak 's/\| \*\*B\. State & data\*\*/\| \*\*B\. Output only\*\*/g' '$WORK/mut9-recon-misassigned-lane.md'"

# Mutation 10: CI-Optimize - Remove UTC expiry date requirement from active quarantine sink (isolated clause)
run_mutation_test \
  "negative control 10 (ci-optimize)" \
  "check_ci_optimize_contract" \
  "$CI_OPT" \
  "$WORK/mut10-ci-opt-no-utc-expiry.md" \
  "sed -i.bak 's/, explicit UTC expiry date//g' '$WORK/mut10-ci-opt-no-utc-expiry.md'"

# Mutation 11: CI-Optimize - Remove total time/resource budget cap from stress loop (isolated clause)
run_mutation_test \
  "negative control 11 (ci-optimize)" \
  "check_ci_optimize_contract" \
  "$CI_OPT" \
  "$WORK/mut11-ci-opt-no-budget-cap.md" \
  "sed -i.bak 's/, capped by a total time\/resource budget (e.g. 5-minute timeout)//g' '$WORK/mut11-ci-opt-no-budget-cap.md'"

# Mutation 12: CI-Optimize - Remove active assertion execution requirement from quarantine sink (isolated clause)
run_mutation_test \
  "negative control 12 (ci-optimize)" \
  "check_ci_optimize_contract" \
  "$CI_OPT" \
  "$WORK/mut12-ci-opt-no-active-assertions.md" \
  "sed -i.bak 's/quarantine sink must continue running and reporting assertions/quarantine sink skips running assertions/g' '$WORK/mut12-ci-opt-no-active-assertions.md'"

# Mutation 13: CI-Optimize - Remove workload-scoped performance budget mechanisms (Principle 14)
run_mutation_test \
  "negative control 13 (ci-optimize)" \
  "check_ci_optimize_contract" \
  "$CI_OPT" \
  "$WORK/mut13-ci-opt-no-perf-budgets.md" \
  "sed -i.bak '/heapsnapshot diffing/d' '$WORK/mut13-ci-opt-no-perf-budgets.md'"

# Mutation 14: CI-Debug - Invert containment ladder by swapping Priority 1 and Priority 4 blocks intact
run_mutation_test \
  "negative control 14 (ci-debug)" \
  "check_ci_debug_contract" \
  "$CI_DEBUG" \
  "$WORK/mut14-ci-debug-inverted-ladder.md" \
  "python3 -c \"
with open('$WORK/mut14-ci-debug-inverted-ladder.md', 'r') as f:
    text = f.read()
p1_block = '''1. **Priority 1 — Provider Revocation & Rotation First:**\n   - Immediately revoke or rotate the compromised credential in the identity/cloud provider console or CLI before attempting git history manipulation.'''
p4_block = '''4. **Priority 4 — Explicitly Authorized History Scrubbing:**\n   - History rewriting tools (\x60git-filter-repo\x60 / BFG) require explicit operator confirmation.\n   - Strictly comply with \x60WORKTREE-SAFETY.md\x60: verify that no linked worktrees depend on the rewritten refs, take a full backup of \x60.git\x60 beforehand, and coordinate ref updates across active clones.'''
mut_text = text.replace(p1_block, 'TEMP_PLACEHOLDER').replace(p4_block, p1_block).replace('TEMP_PLACEHOLDER', p4_block)
with open('$WORK/mut14-ci-debug-inverted-ladder.md', 'w') as f:
    f.write(mut_text)
\""

# Mutation 15: Empty File Fixture
touch "$WORK/empty-fixture.md"
if ! check_workhorse_contract "$WORK/empty-fixture.md"; then
  pass "negative control 15: empty fixture (0 bytes) properly rejected by contract checker"
else
  fail "negative control 15: empty fixture unexpectedly passed validation"
fi

echo "  gh609-sdlc-agent-gaps: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
