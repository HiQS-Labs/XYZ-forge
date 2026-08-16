#!/usr/bin/env bash
# test/relay-target-root-relayfile.sh — GH-18 #2: --relay-file given repo-relative must resolve
# against --target-root (where the thread lives), not the harness CWD. Uses --dry-run so no
# turn-taker / codex / agy is needed; we only exercise relay-drive's argument resolution.
source "$(dirname "$0")/_setup.sh" relay-target-root-relayfile

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

tick_a init >/dev/null

# Thread lives ONLY in the foreign target repo ($B), under a repo-relative path. It does NOT exist
# under the harness root ($A) or the test CWD.
mkdir -p "$B/relay-system/2026-06-24"
REL="relay-system/2026-06-24/demo.md"
printf 'STATUS: In progress\n# relay body\n' >"$B/$REL"
git -C "$B" add "$REL" >/dev/null 2>&1
git -C "$B" commit -q -m "seed relay in B" >/dev/null 2>&1

# Seed a turn token with a live actor so --dry-run reaches the "WOULD drive" print (the no-actor
# guard runs before the dry-run check). Coordination state stays in the harness root ($A).
tick_a log task.created RELAY-TURN --agent claude-a --paths "$REL" >/dev/null 2>&1
tick_a claim   RELAY-TURN --agent claude-a --paths "$REL" >/dev/null 2>&1
tick_a release RELAY-TURN --agent claude-a --to codex     >/dev/null 2>&1

# Run relay-drive from a neutral CWD (the harness root $A), passing the repo-relative --relay-file
# plus --target-root $B. Before the fix this dies "relay file does not exist"; after, it resolves
# the file under $B and reaches the dry-run print.
cd "$A"
out="$(bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$REL" 2>&1)"; rc=$?

# 1. It must NOT die on relay-file resolution.
if printf '%s' "$out" | grep -q "relay file does not exist"; then
  fail "repo-relative --relay-file not resolved under --target-root (got: $out)"
else
  pass "repo-relative --relay-file resolved under --target-root"
fi

# 2. The dry-run path must be reached (exit 0, prints WOULD drive / a STATUS read).
[ "$rc" -eq 0 ] && pass "dry-run reached after target-root relay-file resolution (exit 0)" \
  || fail "expected exit 0 from dry-run, got $rc (out: $out)"

# 3. Regression guard: an absolute --relay-file is unchanged (resolves directly, no target rewrite).
out2="$(bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$B/$REL" 2>&1)"; rc2=$?
[ "$rc2" -eq 0 ] && pass "absolute --relay-file still resolves directly with --target-root" \
  || fail "absolute --relay-file regressed (rc=$rc2, out: $out2)"

# 4. Regression guard: a genuinely missing relay-file still dies, even under --target-root.
out3="$(bash "$DRIVE" --dry-run --target-root "$B" --relay-file "nope/missing.md" 2>&1)"; rc3=$?
if [ "$rc3" -ne 0 ] && printf '%s' "$out3" | grep -q "relay file does not exist"; then
  pass "missing relay-file still errors under --target-root"
else
  fail "missing relay-file should still error (rc=$rc3, out: $out3)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
