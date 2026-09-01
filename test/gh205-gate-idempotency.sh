#!/bin/bash
# test/gh205-gate-idempotency.sh — the gate must not mutate tracked telemetry artifacts.
# Pins the GH-205 fix: validate.sh exports XYZ_HARNESS_DB to a throwaway copy, so telemetry
# writes through harness_app.py land off-tree. Fixture-isolated: all writes here hit $WORK.
set -eu
source test/_setup.sh "GH-205" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

# Fixture "repo": a copy of the real ledger pair, standing in for the tracked root files.
F="$WORK/fixture"
mkdir -p "$F"
cp "$root/harnesses.db" "$F/harnesses.db"
cp "$root/harnesses.sql" "$F/harnesses.sql"
h() { shasum "$F/harnesses.db" "$F/harnesses.sql" | shasum; }

log_once() {  # one telemetry append via the real writer
  python3 "$root/utils/py/harness_app.py" log \
    --device-id test-host --harness-id commandcode --model-id "Qwen/Qwen3.8-Max" \
    --gateway openrouter --reasoning-effort xhigh --shim gh205-test --flags "[]" \
    --task-scope GH-205-idempotency --seconds 0.1 --exit-code 0 --tokens 0 \
    --cost 0 --diff-stat "0 files changed" >/dev/null
}

# 1. Negative control — the writer is real: pointed AT the fixture ledger, it mutates it.
H0="$(h)"
XYZ_HARNESS_DB="$F/harnesses.db" log_once || fail "harness_app.py log failed (control)"
[ "$(h)" != "$H0" ] || fail "control: telemetry write did not change the fixture ledger — probe is vacuous"

# 2. The GH-205 guard shape — with XYZ_HARNESS_DB at a throwaway copy (what validate.sh
#    exports), the same write leaves the fixture ledger untouched.
cp "$root/harnesses.db" "$F/harnesses.db"; cp "$root/harnesses.sql" "$F/harnesses.sql"
H1="$(h)"
SCRATCH="$WORK/scratch"; mkdir -p "$SCRATCH"
cp "$F/harnesses.db" "$SCRATCH/harnesses.db"; cp "$F/harnesses.sql" "$SCRATCH/harnesses.sql"
XYZ_HARNESS_DB="$SCRATCH/harnesses.db" log_once || fail "harness_app.py log failed (guarded)"
[ "$(h)" = "$H1" ] || fail "guarded write mutated the fixture ledger despite XYZ_HARNESS_DB"
grep -q "gh205-test" "$SCRATCH/harnesses.sql" || fail "guarded write did not land in the scratch copy"

# 3. The gate actually wires the guard — validate.sh exports the throwaway XYZ_HARNESS_DB.
#    GH-365 step 1 moved the export into the ONE shared helper (test/lib/runner-envelope.sh) that
#    validate.sh AND ci-local.sh source; the pin follows the contract, not the old line number:
#    both halves must hold or the throwaway envelope is unwired again.
grep -q 'runner-envelope.sh' "$root/validate.sh" \
  || fail "validate.sh no longer sources the shared envelope helper (GH-205/GH-365 regression)"
grep -q 'export XYZ_HARNESS_DB="$RUNNER_ENVELOPE_SCRATCH/harnesses.db"' "$root/test/lib/runner-envelope.sh" \
  || fail "the shared envelope helper no longer exports the throwaway XYZ_HARNESS_DB (GH-205 regression)"
grep -q 'runner-envelope.sh' "$root/ci-local.sh" \
  || fail "ci-local.sh (the qualifying runner) still bypasses the throwaway envelope (GH-365 regression)"

# 4. The known root-writer suite is fixture-isolated (its own XYZ_HARNESS_DB under \$WORK).
grep -q 'XYZ_HARNESS_DB="\$WORK' "$root/test/gh174-harness-registry.sh" \
  || fail "gh174 suite lost its fixture isolation"

echo "== GH-205 ALL PASSED =="
