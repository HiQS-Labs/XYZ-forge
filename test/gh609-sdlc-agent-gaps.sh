#!/usr/bin/env bash
# GH-609: Address Edge-Case SDLC Gaps in Autonomous Agent Workflows
# Guards that core skill documents define durable operation identity, safe 4-state recovery,
# stale-writer fencing (local vs remote), costly vs one-way-door preservation split,
# zero-downtime expand-contract migrations, recon reader/writer/consumer mapping,
# bounded flake stress + active quarantine sinks with UTC expiry, workload-scoped
# performance fences, and operational credential containment ladders.
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
# 2. Positive Contract Assertions
# -----------------------------------------------------------------------------

# Workhorse: Durable Operation Identity & 4-State Reconciliation
WORKHORSE="$ROOT/skills/workhorse/SKILL.md"
if grep -q "operation_id, target_arn_or_url, request_fingerprint, idempotency_key" "$WORKHORSE" && \
   grep -q "Confirmed Success" "$WORKHORSE" && \
   grep -q "Authoritative Non-Execution" "$WORKHORSE" && \
   grep -q "Pending / In-Flight" "$WORKHORSE" && \
   grep -q "Unknown / Unavailable Lookup" "$WORKHORSE" && \
   grep -q "total reconciliation deadline / attempt cap" "$WORKHORSE"; then
  pass "workhorse: defines durable operation identity tuple, 4 reconciliation states, and deadline cap"
else
  fail "workhorse: missing durable operation identity or 4-state reconciliation contract"
fi

# Workhorse: Stale-Writer Fence (Local vs Remote Scoping)
if grep -q "Local process liveness checks" "$WORKHORSE" && \
   grep -q "target-enforced monotonic fencing tokens" "$WORKHORSE"; then
  pass "workhorse: stale-writer fence scopes local PID to local writes and requires remote fencing tokens"
else
  fail "workhorse: missing local vs remote stale-writer fence distinction"
fi

# Workhorse: Preservation Split (Costly vs One-Way Doors)
if grep -q "Costly Operations" "$WORKHORSE" && \
   grep -q "tested rollback and restoration procedure" "$WORKHORSE" && \
   grep -q "One-Way Doors" "$WORKHORSE" && \
   grep -q "exact permanent loss" "$WORKHORSE" && \
   grep -q "Never claim impossible rollback proofs" "$WORKHORSE"; then
  pass "workhorse: preserves Costly (tested rollback) vs One-Way Door (permanent loss + confirmation) split"
else
  fail "workhorse: missing costly vs one-way-door preservation split"
fi

# Workhorse: Semantic Post-Mutation Verification
if grep -q "Verify (Semantic Post-Mutation Verification):" "$WORKHORSE" && \
   grep -q "Verify semantic data content, schema integrity, and state invariants, not merely process exit code" "$WORKHORSE"; then
  pass "workhorse: mandates semantic data/state verification beyond process exit 0"
else
  fail "workhorse: missing semantic post-mutation verification in Rung 6"
fi

# Start-Task: Resume Reconciliation & Network Disconnection
START_TASK="$ROOT/skills/start-task/SKILL.md"
if grep -q "Resume Reconciliation Protocol:" "$START_TASK" && \
   grep -q "gh pr list --head <branch>" "$START_TASK" && \
   grep -q "ascertain remote execution state before re-dispatching" "$START_TASK"; then
  pass "start-task: Step 3 & 7 include resume reconciliation against remote PR and transport verification"
else
  fail "start-task: missing resume reconciliation or transport drop verification"
fi

# SWE: Zero-Downtime Expand-Contract Migration Rubric
SWE="$ROOT/skills/swe/SKILL.md"
if grep -q "Zero-Downtime Expand-Contract Schema & State Migration Rubric" "$SWE" && \
   grep -q "Stage 1 — Expand:" "$SWE" && \
   grep -q "Stage 2 — Backfill & Continuous Sync:" "$SWE" && \
   grep -q "Stage 3 — Convergence Gate:" "$SWE" && \
   grep -q "Stage 4 — Switch Reads:" "$SWE" && \
   grep -q "Stage 5 — Dual-Write & Mixed-Version Support:" "$SWE" && \
   grep -q "Stage 6 — Contract & Retire:" "$SWE" && \
   grep -q "Full retirement and migration of all legacy writers" "$SWE" && \
   grep -q "Full retirement of all legacy readers" "$SWE" && \
   grep -q "Full retirement of delayed, queued, or asynchronous consumers" "$SWE" && \
   grep -q "Closure of the application rollback window" "$SWE"; then
  pass "swe: defines 6-stage expand-contract lifecycle with 4-part contraction gating"
else
  fail "swe: missing 6-stage expand-contract rubric or contraction gates"
fi

# Recon: Lanes B, C, D Mapping
RECON="$ROOT/skills/recon/SKILL.md"
if grep -q "active readers and writers, schema, migrations" "$RECON" && \
   grep -q "background worker queues, delayed/asynchronous consumers" "$RECON" && \
   grep -q "operational tripwires, lock budgets, existing tests covering the subject, logs/metrics/traces, and the reverse-sync rollback path" "$RECON"; then
  pass "recon: maps active readers/writers to Lane B, async queues to Lane C, tripwires to Lane D"
else
  fail "recon: missing schema/consumer/tripwire mapping in Lanes B, C, D"
fi

# CI-Optimize: Principle 13 (Flake Stress & Active Quarantine Sink) & Principle 14 (Performance Budgets)
CI_OPT="$ROOT/skills/ci-optimize/SKILL.md"
if grep -q "Bounded Flake Stress Loops and Active Quarantine Sinks" "$CI_OPT" && \
   grep -q "100-iteration diagnostic stress loop" "$CI_OPT" && \
   grep -q "Principle 4 (matched base/candidate attribution)" "$CI_OPT" && \
   grep -q "quarantined test requires a named owner, linked tracked issue, explicit UTC expiry date" "$CI_OPT" && \
   grep -q "Workload-Scoped Performance and Resource Budget Fences" "$CI_OPT"; then
  pass "ci-optimize: Principles 13 (bounded flake stress + active quarantine) and 14 (performance fences) verified"
else
  fail "ci-optimize: missing Principle 13 or Principle 14 contract clauses"
fi

# CI-Debug: Operational Containment Protocol
CI_DEBUG="$ROOT/skills/ci-debug/SKILL.md"
if grep -q "Operational Containment Protocol (Secrets, Leakage & Incident Response)" "$CI_DEBUG" && \
   grep -q "Priority 1 — Provider Revocation & Rotation First:" "$CI_DEBUG" && \
   grep -q "Priority 2 — Blast Radius Audit in Access Logs:" "$CI_DEBUG" && \
   grep -q "Priority 3 — Preserve Sanitized Evidence:" "$CI_DEBUG" && \
   grep -q "Priority 4 — Explicitly Authorized History Scrubbing:" "$CI_DEBUG" && \
   grep -q "WORKTREE-SAFETY.md" "$CI_DEBUG"; then
  pass "ci-debug: defines 4-tier operational containment protocol preserving worktree safety"
else
  fail "ci-debug: missing 4-tier containment protocol"
fi

# -----------------------------------------------------------------------------
# 3. Hermetic Negative Controls & Falsification Mutations
# -----------------------------------------------------------------------------

validate_workhorse_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "operation_id, target_arn_or_url, request_fingerprint, idempotency_key" "$target" || return 1
  grep -q "Unknown / Unavailable Lookup / Expired Deduplication" "$target" || return 1
  grep -q "target-enforced monotonic fencing tokens" "$target" || return 1
  grep -q "Never claim impossible rollback proofs" "$target" || return 1
  grep -q "Verify semantic data content, schema integrity" "$target" || return 1
  return 0
}

validate_start_task_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "Resume Reconciliation Protocol:" "$target" || return 1
  grep -q "gh pr list --head <branch>" "$target" || return 1
  grep -q "ascertain remote execution state before re-dispatching" "$target" || return 1
  return 0
}

validate_swe_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "Stage 1 — Expand:" "$target" || return 1
  grep -q "Stage 5 — Dual-Write & Mixed-Version Support:" "$target" || return 1
  grep -q "Closure of the application rollback window" "$target" || return 1
  return 0
}

validate_recon_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "active readers and writers, schema, migrations" "$target" || return 1
  grep -q "background worker queues, delayed/asynchronous consumers" "$target" || return 1
  grep -q "operational tripwires, lock budgets" "$target" || return 1
  return 0
}

validate_ci_opt_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "explicit UTC expiry date" "$target" || return 1
  grep -q "Workload-Scoped Performance" "$target" || return 1
  return 0
}

validate_ci_debug_contract() {
  local target="$1"
  [ -s "$target" ] || return 1
  grep -q "Priority 1 — Provider Revocation & Rotation First:" "$target" || return 1
  grep -q "Priority 2 — Blast Radius Audit in Access Logs:" "$target" || return 1
  grep -q "Priority 3 — Preserve Sanitized Evidence:" "$target" || return 1
  grep -q "Priority 4 — Explicitly Authorized History Scrubbing:" "$target" || return 1
  return 0
}

# Mutation 1: Deleting 4th state (Unknown -> Stop) from workhorse fails validation
MUT1="$WORK/workhorse-mut1.md"
cp "$WORKHORSE" "$MUT1"
sed -i.bak '/Unknown \/ Unavailable Lookup/d' "$MUT1"
if ! validate_workhorse_contract "$MUT1"; then
  pass "negative control 1: deleting 4th reconciliation state makes validation FAIL as expected"
else
  fail "negative control 1: validator passed despite missing 4th reconciliation state"
fi

# Mutation 2: Removing remote fencing tokens from workhorse fails validation
MUT2="$WORK/workhorse-mut2.md"
cp "$WORKHORSE" "$MUT2"
sed -i.bak '/target-enforced monotonic fencing tokens/d' "$MUT2"
if ! validate_workhorse_contract "$MUT2"; then
  pass "negative control 2: omitting remote fencing tokens makes validation FAIL as expected"
else
  fail "negative control 2: validator passed despite missing remote fencing tokens"
fi

# Mutation 3: Removing impossible rollback disclaimer fails validation
MUT3="$WORK/workhorse-mut3.md"
cp "$WORKHORSE" "$MUT3"
sed -i.bak '/Never claim impossible rollback proofs/d' "$MUT3"
if ! validate_workhorse_contract "$MUT3"; then
  pass "negative control 3: removing impossible rollback disclaimer makes validation FAIL as expected"
else
  fail "negative control 3: validator passed despite missing rollback disclaimer"
fi

# Mutation 4: Removing semantic post-mutation verification from workhorse fails validation
MUT4="$WORK/workhorse-mut4.md"
cp "$WORKHORSE" "$MUT4"
sed -i.bak '/Verify semantic data content, schema integrity/d' "$MUT4"
if ! validate_workhorse_contract "$MUT4"; then
  pass "negative control 4: removing semantic verification from workhorse makes validation FAIL as expected"
else
  fail "negative control 4: validator passed despite missing semantic verification"
fi

# Mutation 5: Removing remote PR check from start-task fails validation
MUT5="$WORK/start-task-mut5.md"
cp "$START_TASK" "$MUT5"
sed -i.bak '/gh pr list --head/d' "$MUT5"
if ! validate_start_task_contract "$MUT5"; then
  pass "negative control 5: omitting remote PR verification from start-task makes validation FAIL as expected"
else
  fail "negative control 5: validator passed despite missing remote PR check"
fi

# Mutation 6: Removing dual-write mixed-version support from SWE fails validation
MUT6="$WORK/swe-mut6.md"
cp "$SWE" "$MUT6"
sed -i.bak '/Stage 5 — Dual-Write/d' "$MUT6"
if ! validate_swe_contract "$MUT6"; then
  pass "negative control 6: omitting mixed-version dual write from SWE makes validation FAIL as expected"
else
  fail "negative control 6: validator passed despite missing mixed-version dual write"
fi

# Mutation 7: Removing delayed consumers from recon fails validation
MUT7="$WORK/recon-mut7.md"
cp "$RECON" "$MUT7"
sed -i.bak '/background worker queues, delayed\/asynchronous consumers/d' "$MUT7"
if ! validate_recon_contract "$MUT7"; then
  pass "negative control 7: omitting delayed consumers from recon makes validation FAIL as expected"
else
  fail "negative control 7: validator passed despite missing delayed consumers in recon"
fi

# Mutation 8: Removing UTC expiry from quarantine sink fails validation
MUT8="$WORK/ci-opt-mut8.md"
cp "$CI_OPT" "$MUT8"
sed -i.bak '/explicit UTC expiry date/d' "$MUT8"
if ! validate_ci_opt_contract "$MUT8"; then
  pass "negative control 8: omitting UTC expiry date from quarantine sink makes validation FAIL as expected"
else
  fail "negative control 8: validator passed despite missing UTC expiry date"
fi

# Mutation 9: Removing workload-scoped performance budgets from ci-optimize fails validation
MUT9="$WORK/ci-opt-mut9.md"
cp "$CI_OPT" "$MUT9"
sed -i.bak '/Workload-Scoped Performance/d' "$MUT9"
if ! validate_ci_opt_contract "$MUT9"; then
  pass "negative control 9: omitting performance budgets from ci-optimize makes validation FAIL as expected"
else
  fail "negative control 9: validator passed despite missing performance budgets"
fi

# Mutation 10: Inverting containment priority ladder in ci-debug fails validation
MUT10="$WORK/ci-debug-mut10.md"
cp "$CI_DEBUG" "$MUT10"
sed -i.bak '/Priority 1 — Provider Revocation/d' "$MUT10"
if ! validate_ci_debug_contract "$MUT10"; then
  pass "negative control 10: omitting Priority 1 provider revocation from ci-debug makes validation FAIL as expected"
else
  fail "negative control 10: validator passed despite inverted containment ladder"
fi

# Mutation 11: Empty file fixture fails validation
MUT11="$WORK/empty.md"
touch "$MUT11"
if ! validate_workhorse_contract "$MUT11"; then
  pass "negative control 11: empty fixture (0 bytes) makes validation FAIL as expected"
else
  fail "negative control 11: empty fixture unexpectedly passed validation"
fi

echo "  gh609-sdlc-agent-gaps: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
