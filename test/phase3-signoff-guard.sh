#!/usr/bin/env bash
# phase3-signoff-guard.sh — GH-40 Phase 3 scaffolding guard (no loop required).
#
# Proves the two safety properties of the operator sign-off gate, standalone:
#  (1) proposals-sink appends a locatable checklist to its target and writes ONLY there — and REFUSES
#      to write into a rule/operator doc.
#  (2) the containment kernel scopes a Reviewer turn so the rule/operator docs are OFF its writable
#      allowlist — i.e. a headless reviewer cannot commit a change to its own rules ("nothing
#      self-applied"). This reuses the same reviewer-scoping the GH-40 reviewer-overstep canary proves.
source "$(dirname "$0")/_setup.sh" phase3-signoff-guard
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"
SINK="$ROOT/relay-automation/proposals-sink.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

# --- (1) sink appends a sign-off checklist to its target -------------------------------------------
TARGET="$A/relay.md"
printf 'STATUS: Open\n# relay body\n' >"$TARGET"
printf '%s\n' "Cap sequential handoffs at 2" "Make task.done terminal vs higher-epoch reclaim (GH-41)" \
  | bash "$SINK" "$TARGET" >/dev/null
grep -q 'Proposed rule changes — needs operator sign-off' "$TARGET" \
  && pass "sink appended the proposals block" || fail "sink did not append the proposals block"
[ "$(grep -c -- '^- \[ \] ' "$TARGET")" = "2" ] \
  && pass "both proposals rendered as un-ticked checkboxes" || fail "proposals not rendered as checkboxes"

# --- (1b) sink REFUSES to write into a rule/operator doc (trust boundary) ---------------------------
cp "$ROOT/ROUTER.md" "$A/ROUTER.md" 2>/dev/null || printf '# rules\n' >"$A/ROUTER.md"
before="$(cksum "$A/ROUTER.md")"
if printf 'sneak a rule edit\n' | bash "$SINK" "$A/ROUTER.md" 2>/dev/null; then
  fail "sink wrote into a rule/operator doc (ROUTER.md)"
else
  pass "sink refuses to write into a rule/operator doc (exit non-zero)"
fi
[ "$(cksum "$A/ROUTER.md")" = "$before" ] \
  && pass "ROUTER.md byte-unchanged after the refused write" || fail "ROUTER.md was modified"

# --- (2) a Reviewer turn scopes the rule/operator docs OFF its writable allowlist -------------------
printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$A/relay.md"
rtl_init "$A" "$A/relay.md" "ROUTER.md,AGENTS.md,GUIDING-PRINCIPLES.md,PDDA.md" 2>/dev/null
for doc in ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md PDDA.md; do
  if rtl_in_allow "$doc"; then
    fail "$doc is writable by a reviewer turn — a self-edit hole"
  else
    pass "$doc OFF a reviewer's allowlist (headless reviewer can't self-edit it)"
  fi
done
rtl_in_allow "relay.md" \
  && pass "reviewer can still write its own relay file (the proposals sink target)" \
  || fail "reviewer lost write access to its own relay file"

echo "  phase3-signoff-guard: $PASS pass, $FAIL fail"
