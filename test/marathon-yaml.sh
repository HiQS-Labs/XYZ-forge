#!/usr/bin/env bash
# marathon-yaml test: the zero-dep MARATHON.yaml reader parses the constrained subset, resolves
# depends_on into execution order, and fails loudly on malformed/cyclic/incomplete plans (Phase 4 / M5).
source "$(dirname "$0")/_setup.sh" marathon-yaml
MARA="$(cd "$(dirname "$0")/.." && pwd)/bin/marathon-yaml"
run() { node "$MARA" "$@" 2>"$WORK/err"; }   # stdout to caller; stderr captured for assertions

# --- (1) linear 3-phase chain: execution order + field extraction ----------
cat > "$WORK/m1.yaml" <<'YAML'
name: trinity-sync-refactor
phases:
  - id: p1
    name: Event schema
    reviewer: codex
    max_review_rounds: 2
    brief: briefs/p1.md
    artifact: src/schema.js
  - id: p2
    name: single-writer lease
    reviewer: agy                  # agy for architecture
    depends_on: p1
    max_review_rounds: 3
  - id: p3
    name: claim-cap wiring
    reviewer: codex
    depends_on: p2
    max_review_rounds: 2
YAML
out="$(run "$WORK/m1.yaml")"; rc=$?
[ "$rc" -eq 0 ] && pass "linear chain parses (exit 0)" || fail "parse failed: $(cat "$WORK/err")"
[ "$(printf '%s\n' "$out" | cut -f1 | paste -sd, -)" = "p1,p2,p3" ] \
  && pass "execution order resolves to p1,p2,p3" || fail "order wrong: [$out]"
p2row="$(printf '%s\n' "$out" | awk -F'\t' '$1=="p2"{print $2"|"$3"|"$4}')"
[ "$p2row" = "agy|3|p1" ] \
  && pass "p2 fields parsed (reviewer|rounds|depends_on, inline comment stripped)" || fail "p2 fields wrong: [$p2row]"
p1ba="$(printf '%s\n' "$out" | awk -F'\t' '$1=="p1"{print $5"|"$6}')"
[ "$p1ba" = "briefs/p1.md|src/schema.js" ] \
  && pass "p1 brief + artifact columns parsed" || fail "p1 brief/artifact wrong: [$p1ba]"

# --- (2) depends_on reorders authored-out-of-order phases ------------------
cat > "$WORK/m2.yaml" <<'YAML'
name: reorder
phases:
  - id: b
    reviewer: codex
    depends_on: a
  - id: a
    reviewer: agy
YAML
out="$(run "$WORK/m2.yaml")"
[ "$(printf '%s\n' "$out" | cut -f1 | paste -sd, -)" = "a,b" ] \
  && pass "depends_on reorders out-of-order phases (a before b)" || fail "reorder wrong: [$out]"

# --- (3) missing reviewer -> loud error -----------------------------------
printf 'name: x\nphases:\n  - id: p1\n' > "$WORK/m3.yaml"
run "$WORK/m3.yaml" >/dev/null; rc=$?
{ [ "$rc" -ne 0 ] && grep -q "missing reviewer" "$WORK/err"; } \
  && pass "missing reviewer -> error" || fail "should error on missing reviewer (rc=$rc)"

# --- (4) unknown depends_on -> error --------------------------------------
printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n    depends_on: nope\n' > "$WORK/m4.yaml"
run "$WORK/m4.yaml" >/dev/null; rc=$?
{ [ "$rc" -ne 0 ] && grep -q "unknown phase" "$WORK/err"; } \
  && pass "unknown depends_on -> error" || fail "should error on unknown dep (rc=$rc)"

# --- (5) dependency cycle -> error ----------------------------------------
printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n    depends_on: p2\n  - id: p2\n    reviewer: codex\n    depends_on: p1\n' > "$WORK/m5.yaml"
run "$WORK/m5.yaml" >/dev/null; rc=$?
{ [ "$rc" -ne 0 ] && grep -q "cycle" "$WORK/err"; } \
  && pass "dependency cycle -> error" || fail "should detect cycle (rc=$rc)"

# --- (6) duplicate id -> error --------------------------------------------
printf 'name: x\nphases:\n  - id: p1\n    reviewer: codex\n  - id: p1\n    reviewer: agy\n' > "$WORK/m6.yaml"
run "$WORK/m6.yaml" >/dev/null; rc=$?
{ [ "$rc" -ne 0 ] && grep -q "duplicate" "$WORK/err"; } \
  && pass "duplicate phase id -> error" || fail "should error on duplicate id (rc=$rc)"

# --- (7) unsupported reviewer -> error ------------------------------------
# Checks rejection + the "must start with codex" hint substring, not the full message verbatim —
# src/marathon-yaml.js's accepted-prefix list (currently codex/gemini/agy) is untouched by this
# lane (GH-113/114 follow-up: this test previously hardcoded the pre-agy message text, which went
# stale the moment 'agy' was appended to it), so a hardcoded exact string here would drift again
# on the next legitimate prefix-list change.
printf 'name: x\nphases:\n  - id: p1\n    reviewer: claude\n' > "$WORK/m7.yaml"
run "$WORK/m7.yaml" >/dev/null; rc=$?
{ [ "$rc" -ne 0 ] && grep -q "must start with codex" "$WORK/err"; } \
  && pass "reviewer must be an accepted prefix -> error" || fail "should reject 'claude' reviewer (rc=$rc)"

# --- (8) json format emits the marathon name ------------------------------
run "$WORK/m1.yaml" --format json | grep -q '"name": "trinity-sync-refactor"' \
  && pass "--format json emits the marathon name" || fail "json format broken"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
